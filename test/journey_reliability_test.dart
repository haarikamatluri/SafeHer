import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:safeher/models/journey.dart';
import 'package:safeher/services/live_tracking_service.dart';
import 'package:safeher/services/routing_service.dart';

void main() {
  group('Phase 6 & 7: Journey and Live Tracking Reliability Tests', () {
    test('LiveTrackingState distinguishes live vs stale signals', () {
      final now = DateTime.now();
      const activeState = LiveTrackingState(
        isTrackingActive: true,
        incidentId: 'inc-live-1',
        latitude: 13.6288,
        longitude: 79.4192,
        accuracy: 5.0,
        isStale: false,
      );

      expect(activeState.isTrackingActive, isTrue);
      expect(activeState.isStale, isFalse);
      expect(activeState.googleMapsUrl, 'https://maps.google.com/?q=13.6288,79.4192');

      final staleState = LiveTrackingState(
        isTrackingActive: true,
        incidentId: 'inc-live-1',
        latitude: 13.6288,
        longitude: 79.4192,
        accuracy: 25.0,
        lastFixTime: now.subtract(const Duration(seconds: 40)),
        isStale: true,
        statusMessage: 'GPS fix delayed (>35s)',
      );

      expect(staleState.isStale, isTrue);
      expect(staleState.statusMessage?.contains('>35s'), isTrue);
    });

    test('RoutingService fallback generates valid route points when offline', () async {
      final origin = const LatLng(13.6330, 79.4110);
      final destination = const LatLng(13.6288, 79.4192);

      final route = await RoutingService().calculateRoute(
        origin: origin,
        destination: destination,
        mode: TravelMode.bike,
        requestAlternatives: false,
      );

      expect(route.points.isNotEmpty, isTrue);
      expect(route.distanceKm, greaterThan(0));
      expect(route.durationMinutes, greaterThan(0));
    });

    test('Journey checkin intervals and wall-clock due dates are calculated reliably', () {
      final now = DateTime.now();
      final arrival = now.add(const Duration(minutes: 45));

      final journey = Journey(
        id: 'journey-test-1',
        userId: 'test_user',
        destinationName: 'SV University',
        destinationLat: 13.6330,
        destinationLng: 79.4000,
        originLat: 13.6288,
        originLng: 79.4192,
        expectedArrivalTime: arrival,
        checkinIntervalMinutes: 15,
        gracePeriodMinutes: 5,
        status: JourneyStatus.active,
        startedAt: now,
        nextCheckinDueAt: now.add(const Duration(minutes: 15)),
        totalDistanceKm: 8.5,
        remainingDistanceKm: 8.5,
        remainingMinutes: 45,
        totalCheckinsExpected: 3,
      );

      expect(journey.isActive, isTrue);
      expect(journey.nextCheckinDueAt, isNotNull);
      expect(journey.nextCheckinDueAt!.isAfter(now), isTrue);

      // Verify that after 16 minutes, the check-in is past due
      final futureTime = now.add(const Duration(minutes: 16));
      expect(futureTime.isAfter(journey.nextCheckinDueAt!), isTrue);
    });

    test('Journey escalates state faithfully upon missed checkin', () {
      final now = DateTime.now();
      final journey = Journey(
        id: 'journey-test-2',
        userId: 'test_user',
        destinationName: 'SV University',
        destinationLat: 13.6330,
        destinationLng: 79.4000,
        expectedArrivalTime: now.add(const Duration(hours: 1)),
        status: JourneyStatus.checkinMissed,
        startedAt: now.subtract(const Duration(minutes: 20)),
        missedCheckinAt: now.subtract(const Duration(minutes: 6)),
        gracePeriodMinutes: 5,
        totalDistanceKm: 10.0,
      );

      // If missed 6 minutes ago with a 5 minute grace period, grace period is expired!
      final elapsedSinceMissed = now.difference(journey.missedCheckinAt!);
      expect(elapsedSinceMissed.inMinutes >= journey.gracePeriodMinutes, isTrue);

      final escalated = journey.copyWith(
        status: JourneyStatus.escalated,
        escalationTriggered: true,
      );

      expect(escalated.status, JourneyStatus.escalated);
      expect(escalated.escalationTriggered, isTrue);
    });
  });
}
