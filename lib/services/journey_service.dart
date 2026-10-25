import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/journey.dart';
import '../services/auth_service.dart';
import '../services/incident_service.dart';
import '../services/live_tracking_service.dart';
import '../services/native_sms_service.dart';
import '../services/navigation_intelligence.dart';
import '../services/safe_haven_service.dart';
import '../utils/validators.dart';

class JourneyService {
  static final JourneyService _instance = JourneyService._internal();
  factory JourneyService() => _instance;
  JourneyService._internal() {
    _init();
  }

  final _journeyNotifier = ValueNotifier<Journey?>(null);
  ValueListenable<Journey?> get journeyListenable => _journeyNotifier;
  Journey? get activeJourney => _journeyNotifier.value;

  Timer? _countdownTimer;
  Timer? _gracePeriodTimer;
  StreamSubscription<Position>? _positionSub;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NativeSmsService _smsService = NativeSmsService();
  static const String _activeJourneyKey = 'safeher_active_journey_v1';
  static const String _journeyHistoryKey = 'safeher_journey_history_v1';

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_activeJourneyKey);
      if (saved != null) {
        final journey = Journey.fromJson(saved);
        if (journey.isActive) {
          _journeyNotifier.value = journey;
          _resumeTimers(journey);
        }
      }
    } catch (e) {
      debugPrint('Error restoring journey: $e');
    }
  }

  Future<Journey> startJourney({
    required String destinationName,
    required double destinationLat,
    required double destinationLng,
    String? originName,
    double? originLat,
    double? originLng,
    TravelMode travelMode = TravelMode.bike,
    required DateTime expectedArrivalTime,
    int checkinIntervalMinutes = 15,
    int gracePeriodMinutes = 5,
    List<String> notifyContactIds = const [],
    List<String> notifyContactNames = const [],
    List<String> notifyContactPhones = const [],
    double totalDistanceKm = 22.0,
    List<List<double>>? routeCoordinates,
    String? routeSource,
  }) async {
    final userId = SafeHerAuthService().currentUserId ?? 'local_user';
    final now = DateTime.now();

    final diffMinutes = expectedArrivalTime.difference(now).inMinutes;
    final totalExpected = (diffMinutes > 0 && checkinIntervalMinutes > 0)
        ? (diffMinutes / checkinIntervalMinutes).ceil().clamp(1, 20)
        : 6;

    final nextDue = now.add(Duration(minutes: checkinIntervalMinutes));
    final journeyId = const Uuid().v4();

    final journey = Journey(
      id: journeyId,
      userId: userId,
      destinationName: destinationName,
      destinationLat: destinationLat,
      destinationLng: destinationLng,
      originName: originName ?? 'Current Location',
      originLat: originLat,
      originLng: originLng,
      travelMode: travelMode,
      expectedArrivalTime: expectedArrivalTime,
      checkinIntervalMinutes: checkinIntervalMinutes,
      gracePeriodMinutes: gracePeriodMinutes,
      notifyContactIds: notifyContactIds,
      notifyContactNames: notifyContactNames,
      notifyContactPhones: notifyContactPhones,
      status: JourneyStatus.active,
      startedAt: now,
      totalDistanceKm: totalDistanceKm,
      remainingDistanceKm: totalDistanceKm,
      remainingMinutes: diffMinutes > 0 ? diffMinutes : 15,
      totalCheckinsExpected: totalExpected,
      nextCheckinDueAt: nextDue,
      routeCoordinates: routeCoordinates,
      routeSource: routeSource,
    );

    _journeyNotifier.value = journey;
    await _persistActiveJourney(journey);
    unawaited(_syncToFirestore(journey));

    // Start Foreground Service Live Tracking session using the journey's ID
    try {
      await LiveTrackingService().startSession(
        label: 'Journey to $destinationName',
        sessionId: journeyId,
        destinationLat: destinationLat,
        destinationLng: destinationLng,
      );
    } catch (e) {
      debugPrint('LiveTracking start warning: $e');
    }

    _startLocationUpdates();
    _startCheckinCountdown();

    return journey;
  }

  void _startLocationUpdates() {
    _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen(
      (position) async {
        final current = _journeyNotifier.value;
        if (current != null && current.isActive) {
          final pos = LatLng(position.latitude, position.longitude);
          final route = current.routeLatLngs;
          final nearbyPlaces = SafeHavenService().getPlaces();
          final reports = SafeHavenService().getCommunityReports();

          final navStatus = await NavigationIntelligence().evaluatePosition(
            currentPos: pos,
            accuracyMeters: position.accuracy,
            speedKmh: position.speed * 3.6,
            headingDegrees: position.heading,
            journey: current,
            activeRoutePoints: route,
            nearbyPlaces: nearbyPlaces,
            communityReports: reports,
          );

          Journey updated = current.copyWith(
            lastKnownLat: position.latitude,
            lastKnownLng: position.longitude,
            lastKnownLocationTime: DateTime.now(),
            remainingDistanceKm: navStatus.distanceRemainingKm,
            remainingMinutes: navStatus.etaMinutesRemaining,
            expectedArrivalTime: navStatus.estimatedArrivalTime,
            isOffRoute: navStatus.isOffRoute,
            isRerouting: navStatus.isRerouting,
          );

          // If sustained off-route detected, trigger background rerouting
          if (navStatus.isOffRoute && !current.isRerouting) {
            final newRoute = await NavigationIntelligence().attemptReroute(
              currentPos: pos,
              destinationLat: current.destinationLat,
              destinationLng: current.destinationLng,
              travelMode: current.travelMode,
            );
            if (newRoute != null) {
              updated = updated.copyWith(
                routeCoordinates: newRoute.points
                    .map((p) => [p.latitude, p.longitude])
                    .toList(),
                totalDistanceKm: newRoute.distanceKm,
                remainingDistanceKm: newRoute.distanceKm,
                remainingMinutes: newRoute.durationMinutes,
                isOffRoute: false,
                isRerouting: false,
                routeSource: newRoute.providerName,
              );
            }
          }

          _journeyNotifier.value = updated;
          _persistActiveJourney(updated);
        }
      },
      onError: (err) => debugPrint('Journey location error: $err'),
    );
  }

  void _startCheckinCountdown() {
    _countdownTimer?.cancel();
    _gracePeriodTimer?.cancel();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final current = _journeyNotifier.value;
      if (current == null || !current.isActive) {
        timer.cancel();
        return;
      }

      final nextDue = current.nextCheckinDueAt;
      if (nextDue != null && DateTime.now().isAfter(nextDue)) {
        timer.cancel();
        _onCheckinDue(current);
      }
    });
  }

  void _resumeTimers(Journey journey) {
    final now = DateTime.now();

    if (journey.status == JourneyStatus.checkinMissed) {
      // Check if wall-clock grace period has already passed
      final missedAt = journey.missedCheckinAt ?? now;
      final elapsed = now.difference(missedAt);
      final remainingGrace = Duration(minutes: journey.gracePeriodMinutes) - elapsed;

      if (remainingGrace.isNegative) {
        // Grace period already expired while app was sleeping/killed -> escalate immediately!
        if (!journey.escalationTriggered) {
          escalateMissedCheckin();
        }
      } else {
        _startGracePeriodTimer(journey, delay: remainingGrace);
      }
    } else if (journey.status == JourneyStatus.checkinDue) {
      _triggerMissedCheckin(journey);
    } else if (journey.status == JourneyStatus.active) {
      final nextDue = journey.nextCheckinDueAt;
      if (nextDue != null && now.isAfter(nextDue)) {
        _onCheckinDue(journey);
      } else {
        _startCheckinCountdown();
      }
    }
    _startLocationUpdates();
  }

  void _onCheckinDue(Journey current) {
    final updated = current.copyWith(
      status: JourneyStatus.checkinDue,
      lastCheckinPromptAt: DateTime.now(),
    );
    _journeyNotifier.value = updated;
    _persistActiveJourney(updated);

    // Give 45 seconds prompt before turning into Missed Check-in
    Future.delayed(const Duration(seconds: 45), () {
      final nowState = _journeyNotifier.value;
      if (nowState != null && nowState.status == JourneyStatus.checkinDue) {
        _triggerMissedCheckin(nowState);
      }
    });
  }

  void _triggerMissedCheckin(Journey current) {
    final updated = current.copyWith(
      status: JourneyStatus.checkinMissed,
      missedCheckinAt: DateTime.now(),
    );
    _journeyNotifier.value = updated;
    _persistActiveJourney(updated);
    _startGracePeriodTimer(updated);
  }

  void _startGracePeriodTimer(Journey current, {Duration? delay}) {
    _gracePeriodTimer?.cancel();
    final duration = delay ?? Duration(minutes: current.gracePeriodMinutes);
    _gracePeriodTimer = Timer(
      duration,
      () {
        final nowState = _journeyNotifier.value;
        if (nowState != null &&
            nowState.status == JourneyStatus.checkinMissed &&
            !nowState.escalationTriggered) {
          escalateMissedCheckin();
        }
      },
    );
  }

  Future<void> confirmSafeCheckin() async {
    final current = _journeyNotifier.value;
    if (current == null) return;

    _gracePeriodTimer?.cancel();
    _countdownTimer?.cancel();

    final nextDue = DateTime.now().add(
      Duration(minutes: current.checkinIntervalMinutes),
    );

    final updated = current.copyWith(
      status: JourneyStatus.active,
      checkinsCompleted: current.checkinsCompleted + 1,
      nextCheckinDueAt: nextDue,
      missedCheckinAt: null,
      lastCheckinPromptAt: null,
    );

    _journeyNotifier.value = updated;
    await _persistActiveJourney(updated);
    unawaited(_syncToFirestore(updated));

    _startCheckinCountdown();
  }

  Future<void> extendCheckinTime({int extensionMinutes = 15}) async {
    final current = _journeyNotifier.value;
    if (current == null) return;

    _gracePeriodTimer?.cancel();
    _countdownTimer?.cancel();

    final nextDue = DateTime.now().add(Duration(minutes: extensionMinutes));
    final updated = current.copyWith(
      status: JourneyStatus.active,
      nextCheckinDueAt: nextDue,
      missedCheckinAt: null,
      lastCheckinPromptAt: null,
    );

    _journeyNotifier.value = updated;
    await _persistActiveJourney(updated);
    unawaited(_syncToFirestore(updated));

    _startCheckinCountdown();
  }

  Future<void> escalateMissedCheckin() async {
    final current = _journeyNotifier.value;
    if (current == null) return;

    _gracePeriodTimer?.cancel();
    _countdownTimer?.cancel();

    final updated = current.copyWith(
      status: JourneyStatus.escalated,
      escalationTriggered: true,
    );
    _journeyNotifier.value = updated;
    await _persistActiveJourney(updated);
    unawaited(_syncToFirestore(updated));

    // Send native SIM SMS alert to authorized contacts
    final mapsUrl = (current.lastKnownLat != null && current.lastKnownLng != null)
        ? 'https://maps.google.com/?q=${current.lastKnownLat},${current.lastKnownLng}'
        : 'Location unavailable';

    final message =
        'SAFEHER MISSED CHECK-IN ALERT: I have missed my scheduled safety check-in while traveling to ${current.destinationName}. '
        'My last reported location: $mapsUrl. Please verify my safety.';

    final phones = current.notifyContactPhones
        .map((p) => AppValidators.normalizeForSms(p))
        .where((p) => p.isNotEmpty)
        .toList();

    for (final phone in phones) {
      try {
        await _smsService.sendDirectSms(
          phoneNumber: phone,
          message: message,
          incidentId: current.id,
        );
      } catch (e) {
        debugPrint('Escalation SMS error for $phone: $e');
      }
    }

    // Record escalation event in Incident history
    try {
      await IncidentService().triggerSosAlert(
        notes: 'Automated Journey Escalation: Missed check-in to ${current.destinationName}',
      );
    } catch (e) {
      debugPrint('Incident escalation record error: $e');
    }
  }

  Future<Journey?> completeJourney() async {
    final current = _journeyNotifier.value;
    if (current == null) return null;

    _stopAllTracking();

    final completed = current.copyWith(
      status: JourneyStatus.completed,
      completedAt: DateTime.now(),
      checkinsCompleted: current.totalCheckinsExpected,
    );

    _journeyNotifier.value = null;
    await _saveToHistory(completed);
    await _clearActiveJourney();
    unawaited(_syncToFirestore(completed));

    return completed;
  }

  Future<void> cancelJourney() async {
    final current = _journeyNotifier.value;
    _stopAllTracking();

    if (current != null) {
      final cancelled = current.copyWith(
        status: JourneyStatus.cancelled,
        completedAt: DateTime.now(),
      );
      await _saveToHistory(cancelled);
      await _clearActiveJourney();
      unawaited(_syncToFirestore(cancelled));
    }
    _journeyNotifier.value = null;
  }

  void _stopAllTracking() {
    _countdownTimer?.cancel();
    _gracePeriodTimer?.cancel();
    _positionSub?.cancel();
    try {
      LiveTrackingService().stopSession();
    } catch (e) {
      debugPrint('LiveTracking stop error: $e');
    }
  }

  Future<void> _persistActiveJourney(Journey journey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_activeJourneyKey, journey.toJson());
    } catch (e) {
      debugPrint('Error caching journey: $e');
    }
  }

  Future<void> _clearActiveJourney() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_activeJourneyKey);
    } catch (e) {
      debugPrint('Error clearing journey: $e');
    }
  }

  Future<void> _saveToHistory(Journey journey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_journeyHistoryKey) ?? [];
      list.insert(0, journey.toJson());
      if (list.length > 20) {
        list.removeRange(20, list.length);
      }
      await prefs.setStringList(_journeyHistoryKey, list);
    } catch (e) {
      debugPrint('Error saving journey history: $e');
    }
  }

  Future<List<Journey>> getJourneyHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_journeyHistoryKey) ?? [];
      return list.map((e) => Journey.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error reading journey history: $e');
      return [];
    }
  }

  Future<void> _syncToFirestore(Journey journey) async {
    try {
      final userId = SafeHerAuthService().currentUserId;
      if (userId == null) return;
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('journeys')
          .doc(journey.id)
          .set(journey.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore journey sync skipped/offline: $e');
    }
  }
}
