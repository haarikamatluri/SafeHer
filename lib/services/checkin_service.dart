import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/checkin.dart';
import '../utils/constants.dart';
import 'auth_service.dart';

class CheckinService {
  static final CheckinService _instance = CheckinService._internal();
  factory CheckinService() => _instance;
  CheckinService._internal();

  final _checkinStreamController = StreamController<SafetyCheckin?>.broadcast();
  SafetyCheckin? _activeCheckin;
  Timer? _tickerTimer;
  bool _initialized = false;

  SafetyCheckin? get activeCheckin => _activeCheckin;
  bool get hasActiveCheckin =>
      _activeCheckin != null && _activeCheckin!.isActive;
  Stream<SafetyCheckin?> get checkinStream => _checkinStreamController.stream;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _restoreActiveCheckin();
  }

  Future<void> _restoreActiveCheckin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(AppConstants.prefActiveCheckin);
      if (jsonStr != null) {
        final map = jsonDecode(jsonStr);
        final checkin = SafetyCheckin.fromMap(Map<String, dynamic>.from(map));

        // Evaluate deadline from timestamp
        if (checkin.isActive) {
          if (DateTime.now().isAfter(checkin.deadline)) {
            // It expired while app was closed
            _activeCheckin = checkin.copyWith(status: CheckinStatus.missed);
            await _saveCheckinState(_activeCheckin!);
          } else {
            _activeCheckin = checkin;
            _startTicker();
          }
        } else {
          _activeCheckin = checkin;
        }

        _checkinStreamController.add(_activeCheckin);
      }
    } catch (e) {
      debugPrint('[CheckinService] Error restoring check-in state: $e');
    }
  }

  Future<void> _saveCheckinState(SafetyCheckin checkin) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        AppConstants.prefActiveCheckin,
        jsonEncode(checkin.toMap()),
      );
    } catch (e) {
      debugPrint('[CheckinService] Error saving checkin state: $e');
    }
  }

  void _startTicker() {
    _tickerTimer?.cancel();
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_activeCheckin == null || !_activeCheckin!.isActive) {
        timer.cancel();
        return;
      }

      if (DateTime.now().isAfter(_activeCheckin!.deadline)) {
        // Deadline reached! Mark missed
        _activeCheckin = _activeCheckin!.copyWith(status: CheckinStatus.missed);
        _saveCheckinState(_activeCheckin!);
        _checkinStreamController.add(_activeCheckin);
        timer.cancel();
      } else {
        // Emit tick update
        _checkinStreamController.add(_activeCheckin);
      }
    });
  }

  /// Starts a new safety check-in timer
  Future<SafetyCheckin> startCheckin({
    required String title,
    required int durationMinutes,
  }) async {
    _tickerTimer?.cancel();

    final userId = SafeHerAuthService().currentUserId ?? 'unknown_user';
    final id = const Uuid().v4();
    final now = DateTime.now();
    final deadline = now.add(Duration(minutes: durationMinutes));

    final checkin = SafetyCheckin(
      id: id,
      userId: userId,
      title: title.trim().isEmpty ? 'Safety Check-in' : title.trim(),
      durationMinutes: durationMinutes,
      deadline: deadline,
      createdAt: now,
      status: CheckinStatus.active,
      isSyncedToRemote: false,
    );

    _activeCheckin = checkin;
    _checkinStreamController.add(_activeCheckin);
    await _saveCheckinState(checkin);
    _startTicker();

    // Sync to Firestore if authenticated
    if (!SafeHerAuthService().isUsingFallbackLocalAuth) {
      try {
        await FirebaseFirestore.instance
            .collection(AppConstants.usersCollection)
            .doc(userId)
            .collection(AppConstants.checkinsSubcollection)
            .doc(id)
            .set(checkin.toMap());
      } catch (e) {
        debugPrint('[CheckinService] Firestore checkin create error: $e');
      }
    }

    return checkin;
  }

  /// User confirms safety before deadline
  Future<void> markSafe() async {
    if (_activeCheckin == null) return;
    _tickerTimer?.cancel();

    final completed = _activeCheckin!.copyWith(
      status: CheckinStatus.completedSafe,
    );
    _activeCheckin = completed;
    _checkinStreamController.add(_activeCheckin);
    await _saveCheckinState(completed);

    final userId = SafeHerAuthService().currentUserId;
    if (userId != null && !SafeHerAuthService().isUsingFallbackLocalAuth) {
      try {
        await FirebaseFirestore.instance
            .collection(AppConstants.usersCollection)
            .doc(userId)
            .collection(AppConstants.checkinsSubcollection)
            .doc(completed.id)
            .update({'status': CheckinStatus.completedSafe.value});
      } catch (e) {
        debugPrint('[CheckinService] Firestore markSafe error: $e');
      }
    }
  }

  /// User cancels the check-in
  Future<void> cancelCheckin() async {
    if (_activeCheckin == null) return;
    _tickerTimer?.cancel();

    final cancelled = _activeCheckin!.copyWith(status: CheckinStatus.cancelled);
    _activeCheckin = cancelled;
    _checkinStreamController.add(_activeCheckin);
    await _saveCheckinState(cancelled);

    final userId = SafeHerAuthService().currentUserId;
    if (userId != null && !SafeHerAuthService().isUsingFallbackLocalAuth) {
      try {
        await FirebaseFirestore.instance
            .collection(AppConstants.usersCollection)
            .doc(userId)
            .collection(AppConstants.checkinsSubcollection)
            .doc(cancelled.id)
            .update({'status': CheckinStatus.cancelled.value});
      } catch (e) {
        debugPrint('[CheckinService] Firestore cancel error: $e');
      }
    }
  }
}
