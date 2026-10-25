import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/incident.dart';
import '../utils/constants.dart';
import 'alert_service.dart';
import 'auth_service.dart';
import 'contact_service.dart';
import 'live_tracking_service.dart';
import 'location_service.dart';

class IncidentService {
  static final IncidentService _instance = IncidentService._internal();
  factory IncidentService() => _instance;
  IncidentService._internal();

  final _incidentsStreamController =
      StreamController<List<Incident>>.broadcast();
  final _activeIncidentController = StreamController<Incident?>.broadcast();

  List<Incident> _incidents = [];
  Incident? _activeIncident;
  bool _isActivating = false;
  bool _initialized = false;

  List<Incident> get incidents => List.unmodifiable(_incidents);
  Incident? get activeIncident => _activeIncident;
  bool get isActivating => _isActivating;
  bool get hasActiveIncident => _activeIncident != null;

  Stream<List<Incident>> get incidentsStream =>
      _incidentsStreamController.stream;
  Stream<Incident?> get activeIncidentStream =>
      _activeIncidentController.stream;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _loadFromLocalCache();

    SafeHerAuthService().authStateChanges.listen((userId) {
      if (userId != null) {
        _syncFromFirestore(userId);
      }
    });

    final currentUid = SafeHerAuthService().currentUserId;
    if (currentUid != null) {
      _syncFromFirestore(currentUid);
    }
  }

  Future<void> _loadFromLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(AppConstants.prefLocalIncidents);
      if (jsonStr != null) {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        _incidents = decoded
            .map((e) => Incident.fromMap(Map<String, dynamic>.from(e)))
            .toList();
        // Sort descending by creation date
        _incidents.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        // Find active incident if any
        final activeList = _incidents.where((i) => i.status == IncidentStatus.active);
        _activeIncident = activeList.isNotEmpty ? activeList.first : null;

        _incidentsStreamController.add(_incidents);
        _activeIncidentController.add(_activeIncident);
      }
    } catch (e) {
      debugPrint('[IncidentService] Error loading local incident cache: $e');
    }
  }

  Future<void> _saveToLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listMap = _incidents.map((i) => i.toMap()).toList();
      await prefs.setString(
        AppConstants.prefLocalIncidents,
        jsonEncode(listMap),
      );
    } catch (e) {
      debugPrint('[IncidentService] Error saving local incident cache: $e');
    }
  }

  void _syncFromFirestore(String userId) {
    if (SafeHerAuthService().isUsingFallbackLocalAuth) return;

    try {
      FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.incidentsSubcollection)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen(
            (snapshot) {
              final remoteIncidents = snapshot.docs.map((doc) {
                return Incident.fromMap(doc.data(), doc.id);
              }).toList();

              _incidents = remoteIncidents;
              final activeList = _incidents.where((i) => i.status == IncidentStatus.active);
              _activeIncident = activeList.isNotEmpty ? activeList.first : null;

              _incidentsStreamController.add(_incidents);
              _activeIncidentController.add(_activeIncident);
              _saveToLocalCache();
            },
            onError: (err) {
              debugPrint('[IncidentService] Firestore sync error: $err');
            },
          );
    } catch (e) {
      debugPrint('[IncidentService] Firestore subscription error: $e');
    }
  }

  /// Triggers emergency SOS with debounce lock to prevent duplicate activation
  Future<Incident> triggerSos({
    String source = 'sos_button',
    bool requestLocation = true,
  }) async {
    // 1. Debounce protection: prevent double execution from rapid taps
    if (_isActivating) {
      throw Exception('SOS activation is already in progress.');
    }
    if (_activeIncident != null) {
      return _activeIncident!;
    }

    _isActivating = true;
    try {
      final userId = SafeHerAuthService().currentUserId ?? 'unknown_user';
      final incidentId = const Uuid().v4();
      final createdAt = DateTime.now();

      // 2. Fetch location if requested
      double? lat;
      double? lng;
      double? accuracy;
      if (requestLocation) {
        final locResult = await LocationService().getCurrentLocation(
          timeout: const Duration(seconds: 6),
        );
        if (locResult.isSuccess) {
          lat = locResult.latitude;
          lng = locResult.longitude;
          accuracy = locResult.accuracy;
        }
      }

      // 3. Create incident instance
      var incident = Incident(
        id: incidentId,
        userId: userId,
        status: IncidentStatus.active,
        source: source,
        createdAt: createdAt,
        latitude: lat,
        longitude: lng,
        locationAccuracy: accuracy,
        locationSharingEnabled: requestLocation,
        alertStatus: AlertDeliveryStatus.preparing,
        alertAttemptCount: 1,
        isSyncedToRemote: false,
      );

      // Save locally immediately
      _activeIncident = incident;
      _incidents = [incident, ..._incidents];
      _activeIncidentController.add(_activeIncident);
      _incidentsStreamController.add(_incidents);
      await _saveToLocalCache();

      // 4. Save to Firestore if connected
      bool synced = false;
      if (!SafeHerAuthService().isUsingFallbackLocalAuth) {
        try {
          await FirebaseFirestore.instance
              .collection(AppConstants.usersCollection)
              .doc(userId)
              .collection(AppConstants.incidentsSubcollection)
              .doc(incidentId)
              .set(incident.toMap());
          synced = true;
        } catch (e) {
          debugPrint('[IncidentService] Remote Firestore save failed: $e');
        }
      }

      if (synced) {
        incident = incident.copyWith(isSyncedToRemote: true);
        _updateIncidentInMemory(incident);
      }

      // 5. Dispatch Alert Pipeline through AlertService
      final contacts = ContactService().contacts;
      final alertResult = await AlertService().dispatchEmergencyAlert(
        incident: incident,
        contacts: contacts,
      );

      incident = incident.copyWith(
        alertStatus: alertResult.status,
        deliverySummary: alertResult.deliverySummary,
      );
      _updateIncidentInMemory(incident);
      await _saveToLocalCache();

      // Update Firestore with final alert status and summary if synced
      if (synced) {
        try {
          await FirebaseFirestore.instance
              .collection(AppConstants.usersCollection)
              .doc(userId)
              .collection(AppConstants.incidentsSubcollection)
              .doc(incidentId)
              .update({
                'alertStatus': incident.alertStatus.value,
                'deliverySummary': alertResult.deliverySummary,
              });
        } catch (_) {}
      }

      // 6. Start Live Location Tracking Session
      final authorizedContacts = contacts.where((c) => c.isAuthorized).toList();
      unawaited(
        LiveTrackingService().startTracking(
          incident: incident,
          authorizedContacts: authorizedContacts,
        ),
      );

      return incident;
    } finally {
      _isActivating = false;
    }
  }

  /// Resolves an active incident safely
  Future<void> resolveIncident(String incidentId) async {
    final index = _incidents.indexWhere((i) => i.id == incidentId);
    if (index == -1) return;

    final target = _incidents[index];
    if (!target.canTransitionTo(IncidentStatus.resolvedByUser)) {
      throw Exception('Incident cannot transition to resolved state.');
    }

    final resolved = target.copyWith(
      status: IncidentStatus.resolvedByUser,
      resolvedAt: DateTime.now(),
    );

    _updateIncidentInMemory(resolved);
    if (_activeIncident?.id == incidentId) {
      _activeIncident = null;
      _activeIncidentController.add(null);
    }
    await _saveToLocalCache();
    unawaited(LiveTrackingService().stopTracking(incidentId));

    final userId = SafeHerAuthService().currentUserId;
    if (userId != null && !SafeHerAuthService().isUsingFallbackLocalAuth) {
      try {
        await FirebaseFirestore.instance
            .collection(AppConstants.usersCollection)
            .doc(userId)
            .collection(AppConstants.incidentsSubcollection)
            .doc(incidentId)
            .update({
              'status': IncidentStatus.resolvedByUser.value,
              'resolvedAt': resolved.resolvedAt?.toIso8601String(),
            });
      } catch (e) {
        debugPrint(
          '[IncidentService] Error updating resolved incident in Firestore: $e',
        );
      }
    }
  }

  /// Cancels an incident (e.g. accidental trigger / false alarm)
  Future<void> cancelIncident(String incidentId) async {
    final index = _incidents.indexWhere((i) => i.id == incidentId);
    if (index == -1) return;

    final target = _incidents[index];
    if (!target.canTransitionTo(IncidentStatus.cancelled)) {
      throw Exception('Incident cannot transition to cancelled state.');
    }

    final cancelled = target.copyWith(
      status: IncidentStatus.cancelled,
      resolvedAt: DateTime.now(),
    );

    _updateIncidentInMemory(cancelled);
    if (_activeIncident?.id == incidentId) {
      _activeIncident = null;
      _activeIncidentController.add(null);
    }
    await _saveToLocalCache();
    unawaited(LiveTrackingService().stopTracking(incidentId));

    final userId = SafeHerAuthService().currentUserId;
    if (userId != null && !SafeHerAuthService().isUsingFallbackLocalAuth) {
      try {
        await FirebaseFirestore.instance
            .collection(AppConstants.usersCollection)
            .doc(userId)
            .collection(AppConstants.incidentsSubcollection)
            .doc(incidentId)
            .update({
              'status': IncidentStatus.cancelled.value,
              'resolvedAt': cancelled.resolvedAt?.toIso8601String(),
            });
      } catch (e) {
        debugPrint('[IncidentService] Error updating cancelled incident: $e');
      }
    }
  }

  void _updateIncidentInMemory(Incident updated) {
    final index = _incidents.indexWhere((i) => i.id == updated.id);
    if (index != -1) {
      final list = List<Incident>.from(_incidents);
      list[index] = updated;
      _incidents = list;
    } else {
      _incidents = [updated, ..._incidents];
    }

    if (updated.status == IncidentStatus.active) {
      _activeIncident = updated;
    } else if (_activeIncident?.id == updated.id) {
      _activeIncident = null;
    }

    _incidentsStreamController.add(_incidents);
    _activeIncidentController.add(_activeIncident);
  }

  Future<Incident> triggerSosAlert({String? notes}) async {
    return triggerSos(source: notes ?? 'journey_escalation');
  }

  Future<List<Incident>> getQueuedIncidents() async {
    return _incidents.where((i) => !i.isSyncedToRemote).toList();
  }

  Future<int> syncQueuedIncidents() async {
    final unsynced = _incidents.where((i) => !i.isSyncedToRemote).toList();
    if (unsynced.isEmpty) return 0;
    int syncedCount = 0;
    final userId = SafeHerAuthService().currentUserId;
    if (userId == null || SafeHerAuthService().isUsingFallbackLocalAuth) {
      return 0;
    }

    for (final inc in unsynced) {
      try {
        await FirebaseFirestore.instance
            .collection(AppConstants.usersCollection)
            .doc(userId)
            .collection(AppConstants.incidentsSubcollection)
            .doc(inc.id)
            .set(inc.toMap());
        final updated = inc.copyWith(isSyncedToRemote: true);
        _updateIncidentInMemory(updated);
        syncedCount++;
      } catch (e) {
        debugPrint('[IncidentService] Sync queued incident error: $e');
      }
    }
    await _saveToLocalCache();
    return syncedCount;
  }
}
