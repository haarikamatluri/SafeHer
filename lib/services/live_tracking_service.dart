import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/incident.dart';
import '../models/trusted_contact.dart';
import 'auth_service.dart';
import 'diagnostic_logger.dart';
import 'incident_service.dart';

class LiveTrackingState {
  final bool isTrackingActive;
  final String? incidentId;
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final double? speed;
  final double? altitude;
  final DateTime? lastFixTime;
  final DateTime? lastSyncTime;
  final bool isStale;
  final bool isServiceDisabled;
  final bool isPermissionDenied;
  final String? statusMessage;
  final List<Map<String, dynamic>> breadcrumbs;

  const LiveTrackingState({
    this.isTrackingActive = false,
    this.incidentId,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.speed,
    this.altitude,
    this.lastFixTime,
    this.lastSyncTime,
    this.isStale = false,
    this.isServiceDisabled = false,
    this.isPermissionDenied = false,
    this.statusMessage,
    this.breadcrumbs = const [],
  });

  String? get googleMapsUrl {
    if (latitude != null && longitude != null) {
      return 'https://maps.google.com/?q=$latitude,$longitude';
    }
    return null;
  }
}

class LiveTrackingService {
  static final LiveTrackingService _instance = LiveTrackingService._internal();
  factory LiveTrackingService() => _instance;
  LiveTrackingService._internal() {
    _loadPersistedOfflineQueue();
  }

  StreamSubscription<Position>? _positionSubscription;
  Timer? _staleCheckTimer;
  Timer? _heartbeatTimer;

  String? _activeIncidentId;
  Position? _lastPosition;
  DateTime? _lastSyncTime;
  final List<Map<String, dynamic>> _breadcrumbs = [];
  final List<Map<String, dynamic>> _offlineQueue = [];

  final _stateController = StreamController<LiveTrackingState>.broadcast();
  Stream<LiveTrackingState> get stateStream => _stateController.stream;

  LiveTrackingState _currentState = const LiveTrackingState();
  LiveTrackingState get currentState => _currentState;

  Future<void> _loadPersistedOfflineQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString('safeher_tracking_offline_queue');
      if (str != null) {
        final list = jsonDecode(str) as List<dynamic>;
        _offlineQueue.clear();
        for (final item in list) {
          if (item is Map) {
            _offlineQueue.add(Map<String, dynamic>.from(item));
          }
        }
      }
    } catch (_) {}
  }

  /// Starts live location tracking session for an active incident
  Future<void> startTracking({
    required Incident incident,
    required List<TrustedContact> authorizedContacts,
  }) async {
    // 1. Guard against duplicate stream starts
    if (_currentState.isTrackingActive && _activeIncidentId == incident.id) {
      debugPrint('[LiveTrackingService] Session already active for ${incident.id}');
      return;
    }

    _activeIncidentId = incident.id;
    _breadcrumbs.clear();

    // 2. Check GPS Service
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      DiagnosticLogger().logTrackingStarted(
        incidentId: incident.id,
        isServiceEnabled: false,
      );
      _updateState(
        _currentState.copyWith(
          isTrackingActive: false,
          isServiceDisabled: true,
          statusMessage: 'GPS is disabled on this device. Turn on location services.',
        ),
      );
      return;
    }

    // 3. Check Location Permissions
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _updateState(
          _currentState.copyWith(
            isTrackingActive: false,
            isPermissionDenied: true,
            statusMessage: 'Location permission denied by user.',
          ),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _updateState(
        _currentState.copyWith(
          isTrackingActive: false,
          isPermissionDenied: true,
          statusMessage: 'Location permission permanently denied. Enable in Settings.',
        ),
      );
      return;
    }

    // 4. Initial state
    final initialLat = incident.latitude;
    final initialLng = incident.longitude;
    final initialAcc = incident.locationAccuracy;
    final now = DateTime.now();

    if (initialLat != null && initialLng != null) {
      _breadcrumbs.add({
        'lat': initialLat,
        'lng': initialLng,
        'acc': initialAcc,
        'time': now.toIso8601String(),
      });
    }

    _updateState(
      LiveTrackingState(
        isTrackingActive: true,
        incidentId: incident.id,
        latitude: initialLat,
        longitude: initialLng,
        accuracy: initialAcc,
        lastFixTime: now,
        lastSyncTime: now,
        isStale: false,
        statusMessage: 'Live emergency location tracking active',
        breadcrumbs: List.unmodifiable(_breadcrumbs),
      ),
    );

    DiagnosticLogger().logTrackingStarted(
      incidentId: incident.id,
      isServiceEnabled: true,
    );

    // 5. Initialize Firestore Tracking Session Document asynchronously
    unawaited(_initFirestoreSession(incident, authorizedContacts));

    // 6. Configure Location Settings (Android Foreground Service)
    LocationSettings locationSettings;
    if (defaultTargetPlatform == TargetPlatform.android && !kIsWeb) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update after moving 10 meters
        intervalDuration: const Duration(seconds: 10), // Or 10s interval
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'SafeHer SOS Active: Live Location Tracking',
          notificationText: 'Sharing real-time emergency coordinates with authorized trusted contacts.',
          enableWakeLock: true,
        ),
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );
    }

    // 7. Subscribe to Position Stream
    await _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) => _onPositionUpdate(position),
      onError: (err) {
        debugPrint('[LiveTrackingService] Location stream error: $err');
        _updateState(
          _currentState.copyWith(
            isStale: true,
            statusMessage: 'GPS signal lost or interrupted: $err',
          ),
        );
      },
    );

    // 8. Stale Signal Checker (flags stale if no update in 35s)
    _staleCheckTimer?.cancel();
    _staleCheckTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (!_currentState.isTrackingActive) {
        timer.cancel();
        return;
      }
      final lastFix = _currentState.lastFixTime;
      if (lastFix != null && DateTime.now().difference(lastFix).inSeconds > 35) {
        if (!_currentState.isStale) {
          _updateState(
            _currentState.copyWith(
              isStale: true,
              statusMessage: 'GPS fix delayed (>35s). Waiting for satellite signal.',
            ),
          );
        }
      }
    });

    // 9. Periodic Heartbeat to sync offline queue
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      _flushOfflineQueue();
    });
  }

  /// Handles incoming GPS position update
  void _onPositionUpdate(Position position) {
    if (!_currentState.isTrackingActive) return;

    final now = DateTime.now();
    _lastPosition = position;

    // Append breadcrumb
    final crumb = {
      'lat': position.latitude,
      'lng': position.longitude,
      'acc': position.accuracy,
      'speed': position.speed,
      'alt': position.altitude,
      'capturedAt': position.timestamp.toIso8601String(),
      'time': now.toIso8601String(),
    };
    _breadcrumbs.add(crumb);
    if (_breadcrumbs.length > 50) {
      _breadcrumbs.removeAt(0); // keep recent 50 positions to bound memory
    }

    _updateState(
      LiveTrackingState(
        isTrackingActive: true,
        incidentId: _activeIncidentId,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        speed: position.speed,
        altitude: position.altitude,
        lastFixTime: now,
        lastSyncTime: _lastSyncTime,
        isStale: false,
        statusMessage: 'Live emergency coordinates updating in real-time',
        breadcrumbs: List.unmodifiable(_breadcrumbs),
      ),
    );

    // Update active incident with fresh GPS fix
    if (_activeIncidentId != null) {
      IncidentService().updateActiveLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMeters: position.accuracy,
      );
    }

    // Throttle Firestore write (protects Spark free quota: at most 1 write per 10s)
    final lastSync = _lastSyncTime;
    if (lastSync == null || now.difference(lastSync).inSeconds >= 10) {
      _syncPositionToFirestore(position, now);
    }
  }

  /// Synchronizes position update to Firestore tracking document
  Future<void> _syncPositionToFirestore(
    Position position,
    DateTime timestamp,
  ) async {
    final incidentId = _activeIncidentId;
    if (incidentId == null) return;

    final updatePayload = {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'accuracy': position.accuracy,
      'speed': position.speed,
      'altitude': position.altitude,
      'capturedAt': position.timestamp.toIso8601String(),
      'syncedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedAtClient': timestamp.toIso8601String(),
    };

    try {
      await FirebaseFirestore.instance
          .collection('trackingSessions')
          .doc(incidentId)
          .set(updatePayload, SetOptions(merge: true));

      _lastSyncTime = DateTime.now();
      _updateState(_currentState.copyWith(lastSyncTime: _lastSyncTime));
      _flushOfflineQueue();
    } catch (e) {
      debugPrint('[LiveTrackingService] Firestore sync failed (caching locally): $e');
      _offlineQueue.add({
        'incidentId': incidentId,
        'payload': {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
          'speed': position.speed,
          'altitude': position.altitude,
          'capturedAt': position.timestamp.toIso8601String(),
          'updatedAtClient': timestamp.toIso8601String(),
        },
      });
      _persistOfflineQueue();
    }
  }

  /// Flushes any locally queued offline coordinates
  Future<void> _flushOfflineQueue() async {
    if (_offlineQueue.isEmpty) return;

    final items = List<Map<String, dynamic>>.from(_offlineQueue);
    _offlineQueue.clear();

    for (final item in items) {
      try {
        final id = item['incidentId'] as String;
        final payload = Map<String, dynamic>.from(item['payload'] as Map);
        payload['syncedAt'] = FieldValue.serverTimestamp();
        payload['updatedAt'] = FieldValue.serverTimestamp();

        await FirebaseFirestore.instance
            .collection('trackingSessions')
            .doc(id)
            .set(payload, SetOptions(merge: true));
      } catch (_) {
        _offlineQueue.add(item);
        break;
      }
    }
    _persistOfflineQueue();
  }

  Future<void> _persistOfflineQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'safeher_tracking_offline_queue',
        jsonEncode(_offlineQueue),
      );
    } catch (_) {}
  }

  /// Initializes the Firestore tracking session document
  Future<void> _initFirestoreSession(
    Incident incident,
    List<TrustedContact> authorizedContacts,
  ) async {
    final currentUid = SafeHerAuthService().currentUserId;
    if (currentUid == null || SafeHerAuthService().isUsingFallbackLocalAuth) {
      return;
    }

    try {
      final sessionDoc = {
        'incidentId': incident.id,
        'ownerUid': currentUid,
        'isActive': true,
        'startedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'latitude': incident.latitude,
        'longitude': incident.longitude,
        'accuracy': incident.locationAccuracy,
        'authorizedPhones': authorizedContacts.map((c) => c.phone).toList(),
        'authorizedUids': authorizedContacts
            .where((c) => c.linkedUserId != null && c.linkedUserId!.isNotEmpty)
            .map((c) => c.linkedUserId!)
            .toList(),
      };

      await FirebaseFirestore.instance
          .collection('trackingSessions')
          .doc(incident.id)
          .set(sessionDoc, SetOptions(merge: true));

      _lastSyncTime = DateTime.now();
    } catch (e) {
      debugPrint('[LiveTrackingService] Failed to init Firestore tracking doc: $e');
    }
  }

  /// Stops tracking when user ends SOS or marks themselves safe
  Future<void> stopTracking(String incidentId) async {
    debugPrint('[LiveTrackingService] Stopping tracking session for $incidentId');

    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _staleCheckTimer?.cancel();
    _staleCheckTimer = null;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    final now = DateTime.now();

    // Mark Firestore document as inactive
    try {
      await FirebaseFirestore.instance
          .collection('trackingSessions')
          .doc(incidentId)
          .set({
            'isActive': false,
            'endedAt': FieldValue.serverTimestamp(),
            'endedAtClient': now.toIso8601String(),
          }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[LiveTrackingService] Failed to mark trackingSession inactive in Firestore: $e');
    }

    _updateState(
      LiveTrackingState(
        isTrackingActive: false,
        incidentId: incidentId,
        latitude: _lastPosition?.latitude ?? _currentState.latitude,
        longitude: _lastPosition?.longitude ?? _currentState.longitude,
        accuracy: _lastPosition?.accuracy ?? _currentState.accuracy,
        lastFixTime: _currentState.lastFixTime,
        lastSyncTime: now,
        isStale: false,
        statusMessage: 'Location tracking ended. User has marked safe.',
        breadcrumbs: List.unmodifiable(_breadcrumbs),
      ),
    );

    _activeIncidentId = null;
  }

  /// Real-time stream of a tracking session document (for trusted contacts or viewer)
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamTrackingSession(
    String incidentId,
  ) {
    return FirebaseFirestore.instance
        .collection('trackingSessions')
        .doc(incidentId)
        .snapshots();
  }

  void _updateState(LiveTrackingState newState) {
    _currentState = newState;
    if (!_stateController.isClosed) {
      _stateController.add(newState);
    }
  }

  Future<void> startSession({
    required String label,
    String? sessionId,
    double? destinationLat,
    double? destinationLng,
  }) async {
    final now = DateTime.now();
    _activeIncidentId = sessionId ?? 'journey_${now.millisecondsSinceEpoch}';
    _breadcrumbs.clear();

    LocationSettings locationSettings;
    if (defaultTargetPlatform == TargetPlatform.android && !kIsWeb) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
        intervalDuration: const Duration(seconds: 10),
        foregroundNotificationConfig: ForegroundNotificationConfig(
          notificationTitle: 'SafeHer: $label',
          notificationText: 'Journey Guardian is actively monitoring your route.',
          enableWakeLock: true,
        ),
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );
    }

    await _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) => _onPositionUpdate(position),
      onError: (err) => debugPrint('[LiveTrackingService] Stream error: $err'),
    );

    _updateState(
      LiveTrackingState(
        isTrackingActive: true,
        incidentId: _activeIncidentId,
        lastFixTime: now,
        statusMessage: label,
      ),
    );
  }

  Future<void> stopSession() async {
    final currentId = _activeIncidentId ?? 'session';
    await stopTracking(currentId);
  }

  int getUnsyncedPointsCount() => _offlineQueue.length;

  Future<void> flushPointsToCloud() async {
    await _flushOfflineQueue();
  }

  void dispose() {
    _positionSubscription?.cancel();
    _staleCheckTimer?.cancel();
    _heartbeatTimer?.cancel();
    _stateController.close();
  }
}

extension on LiveTrackingState {
  LiveTrackingState copyWith({
    bool? isTrackingActive,
    String? incidentId,
    double? latitude,
    double? longitude,
    double? accuracy,
    double? speed,
    double? altitude,
    DateTime? lastFixTime,
    DateTime? lastSyncTime,
    bool? isStale,
    bool? isServiceDisabled,
    bool? isPermissionDenied,
    String? statusMessage,
    List<Map<String, dynamic>>? breadcrumbs,
  }) {
    return LiveTrackingState(
      isTrackingActive: isTrackingActive ?? this.isTrackingActive,
      incidentId: incidentId ?? this.incidentId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      speed: speed ?? this.speed,
      altitude: altitude ?? this.altitude,
      lastFixTime: lastFixTime ?? this.lastFixTime,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      isStale: isStale ?? this.isStale,
      isServiceDisabled: isServiceDisabled ?? this.isServiceDisabled,
      isPermissionDenied: isPermissionDenied ?? this.isPermissionDenied,
      statusMessage: statusMessage ?? this.statusMessage,
      breadcrumbs: breadcrumbs ?? this.breadcrumbs,
    );
  }
}
