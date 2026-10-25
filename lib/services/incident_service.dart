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
import 'diagnostic_logger.dart';
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
        _incidents.sort((a, b) => b.createdAt.compareTo(a.createdAt));

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

  /// Triggers emergency SOS immediately without blocking SMS on Firestore or long GPS timeouts
  Future<Incident> triggerSos({
    String source = 'sos_button',
    bool requestLocation = true,
  }) async {
    DiagnosticLogger().logSosTapped(source: source);

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

      // 2. Initialize local incident instance immediately
      var incident = Incident(
        id: incidentId,
        userId: userId,
        status: IncidentStatus.active,
        source: source,
        createdAt: createdAt,
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

      DiagnosticLogger().logIncidentCreated(
        incidentId: incidentId,
        userId: userId,
        isSynced: false,
      );

      // 3. Obtain location concurrently with bounded timeout (3-4s max)
      LocationResult? locResult;
      if (requestLocation) {
        locResult = await LocationService().getEmergencyLocation(
          timeout: const Duration(seconds: 4),
        );

        if (locResult.isSuccess && locResult.latitude != null && locResult.longitude != null) {
          incident = incident.copyWith(
            latitude: locResult.latitude,
            longitude: locResult.longitude,
            locationAccuracy: locResult.accuracyMeters,
            locationSource: locResult.source,
            locationAgeSeconds: locResult.age?.inSeconds,
            locationCapturedAt: locResult.capturedAt,
          );
        } else {
          incident = incident.copyWith(
            locationSource: locResult.source,
          );
        }
        _updateIncidentInMemory(incident);
        await _saveToLocalCache();
      }

      // 4. Start Live Location Tracking independently (does not block SMS)
      final contacts = ContactService().contacts;
      final authorizedContacts = contacts.where((c) => c.isAuthorized).toList();
      unawaited(
        LiveTrackingService().startTracking(
          incident: incident,
          authorizedContacts: authorizedContacts,
        ),
      );

      // 5. Asynchronous Firestore sync (never blocks SMS dispatch)
      unawaited(_syncIncidentToFirestore(incident));

      // 6. Dispatch Native SMS alert to authorized contacts immediately
      final alertResult = await AlertService().dispatchEmergencyAlert(
        incident: incident,
        contacts: contacts,
      );

      // 7. Update incident record with final send results
      incident = incident.copyWith(
        alertStatus: alertResult.status,
        deliverySummary: alertResult.deliverySummary,
        recipientResults: alertResult.recipientResults,
      );
      _updateIncidentInMemory(incident);
      await _saveToLocalCache();

      // Push final delivery status to Firestore asynchronously
      unawaited(_syncIncidentToFirestore(incident));

      return incident;
    } catch (e) {
      DiagnosticLogger().logFailure(
        stage: 'TRIGGER_SOS',
        reason: e.toString(),
      );
      rethrow;
    } finally {
      _isActivating = false;
    }
  }

  /// Retries SMS dispatch for the active incident without creating a duplicate incident
  Future<AlertDeliveryResult> retryAlertDispatch() async {
    final active = _activeIncident;
    if (active == null) {
      throw Exception('No active incident to retry.');
    }

    final contacts = ContactService().contacts;
    final alertResult = await AlertService().dispatchEmergencyAlert(
      incident: active,
      contacts: contacts,
    );

    final updated = active.copyWith(
      alertStatus: alertResult.status,
      alertAttemptCount: active.alertAttemptCount + 1,
      deliverySummary: alertResult.deliverySummary,
      recipientResults: alertResult.recipientResults,
    );

    _updateIncidentInMemory(updated);
    await _saveToLocalCache();
    unawaited(_syncIncidentToFirestore(updated));

    return alertResult;
  }

  /// Updates incident location when a newer fresh GPS fix arrives during active SOS
  void updateActiveLocation({
    required double latitude,
    required double longitude,
    double? accuracyMeters,
  }) {
    final active = _activeIncident;
    if (active == null) return;

    final updated = active.copyWith(
      latitude: latitude,
      longitude: longitude,
      locationAccuracy: accuracyMeters,
      locationSource: 'fresh_gps',
      locationAgeSeconds: 0,
      locationCapturedAt: DateTime.now(),
    );

    _updateIncidentInMemory(updated);
    _saveToLocalCache();
    unawaited(_syncIncidentToFirestore(updated));
  }

  /// Synchronizes incident document to Firestore asynchronously
  Future<void> _syncIncidentToFirestore(Incident incident) async {
    final userId = SafeHerAuthService().currentUserId;
    if (userId == null || SafeHerAuthService().isUsingFallbackLocalAuth) {
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.incidentsSubcollection)
          .doc(incident.id)
          .set(incident.toMap(), SetOptions(merge: true));

      DiagnosticLogger().logFirestoreSynced(
        collection: 'incidents',
        docId: incident.id,
        success: true,
      );

      if (!incident.isSyncedToRemote) {
        final synced = incident.copyWith(isSyncedToRemote: true);
        _updateIncidentInMemory(synced);
        await _saveToLocalCache();
      }
    } catch (e) {
      debugPrint('[IncidentService] Async Firestore sync error: $e');
      DiagnosticLogger().logFirestoreSynced(
        collection: 'incidents',
        docId: incident.id,
        success: false,
        error: e.toString(),
      );
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
