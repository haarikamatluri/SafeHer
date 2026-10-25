import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:safeher/utils/geo_math_utils.dart';
import 'package:safeher/services/routing_service.dart';
import 'package:safeher/services/navigation_intelligence.dart';
import 'package:safeher/models/journey.dart';
import 'package:safeher/models/safe_haven.dart';

void main() {
  group('GeoMathUtils Unit Tests', () {
    test('distanceMeters returns 0 for identical coordinates', () {
      const p = LatLng(12.9716, 77.5946);
      expect(GeoMathUtils.distanceMeters(p, p), 0.0);
    });

    test('distanceMeters calculates realistic geodesic distance', () {
      // Bangalore City Railway Station to MG Road (~4.5 km)
      const p1 = LatLng(12.9781, 77.5695);
      const p2 = LatLng(12.9756, 77.6066);
      final distMeters = GeoMathUtils.distanceMeters(p1, p2);

      // Distance should be ~4.0 - 4.5 km
      expect(distMeters, greaterThan(3800));
      expect(distMeters, lessThan(4400));
      expect(GeoMathUtils.distanceKm(p1, p2), closeTo(distMeters / 1000, 0.01));
    });

    test('distanceToSegmentMeters calculates perpendicular distance accurately', () {
      // Segment along equator: (0, 0) to (0, 1)
      const a = LatLng(0.0, 0.0);
      const b = LatLng(0.0, 1.0);
      // Point directly 0.001 degrees north of the midpoint (0, 0.5)
      const p = LatLng(0.001, 0.5);

      final perpDistance = GeoMathUtils.distanceToSegmentMeters(p, a, b);
      // 0.001 deg latitude is approximately 111 meters
      expect(perpDistance, closeTo(111.0, 2.0));
    });

    test('distanceToPolylineMeters finds shortest distance to polyline segments', () {
      final polyline = [
        const LatLng(12.9700, 77.5900),
        const LatLng(12.9710, 77.5910),
        const LatLng(12.9720, 77.5920),
      ];

      // Point right on the second waypoint
      final exactDist = GeoMathUtils.distanceToPolylineMeters(const LatLng(12.9710, 77.5910), polyline);
      expect(exactDist, closeTo(0.0, 0.1));

      // Point far away
      final farDist = GeoMathUtils.distanceToPolylineMeters(const LatLng(13.5, 78.5), polyline);
      expect(farDist, greaterThan(50000));
    });

    test('calculateBearing returns valid degrees (0 to 360)', () {
      // Heading directly north: (0, 0) to (1, 0) -> bearing should be ~0 or 360
      const start = LatLng(0.0, 0.0);
      const north = LatLng(1.0, 0.0);
      expect(GeoMathUtils.calculateBearing(start, north), closeTo(0.0, 0.5));

      // Heading directly east: (0, 0) to (0, 1) -> bearing should be ~90
      const east = LatLng(0.0, 1.0);
      expect(GeoMathUtils.calculateBearing(start, east), closeTo(90.0, 0.5));
    });

    test('calculateRemainingDistanceKm correctly decrements along route', () {
      final polyline = [
        const LatLng(12.9700, 77.5900),
        const LatLng(12.9750, 77.5900),
        const LatLng(12.9800, 77.5900),
      ];

      final totalDist = GeoMathUtils.totalPolylineDistanceKm(polyline);
      expect(totalDist, greaterThan(1.0));

      // At start point
      final remainingAtStart = GeoMathUtils.calculateRemainingDistanceKm(polyline[0], polyline);
      expect(remainingAtStart, closeTo(totalDist, 0.1));

      // Near end point
      final remainingAtEnd = GeoMathUtils.calculateRemainingDistanceKm(polyline[2], polyline);
      expect(remainingAtEnd, lessThan(0.05));
    });
  });

  group('RouteResult Model and Serialization', () {
    test('toMap and fromMap retain road geometry and metadata', () {
      final route = RouteResult(
        points: const [LatLng(12.97, 77.59), LatLng(12.98, 77.60)],
        distanceKm: 2.5,
        durationMinutes: 8,
        summary: 'Via Residency Rd',
        steps: const [
          RouteStep(
            instruction: 'Turn right on Residency Rd',
            distanceMeters: 500,
            durationSeconds: 120,
            startPoint: LatLng(12.97, 77.59),
          ),
        ],
        providerName: 'OSRM (OpenStreetMap)',
        retrievedAt: DateTime(2026, 10, 24, 12, 0),
        isTrafficAware: false,
        isFallback: false,
      );

      final map = route.toMap();
      final reconstructed = RouteResult.fromMap(map);

      expect(reconstructed.distanceKm, 2.5);
      expect(reconstructed.durationMinutes, 8);
      expect(reconstructed.summary, 'Via Residency Rd');
      expect(reconstructed.points.length, 2);
      expect(reconstructed.steps.length, 1);
      expect(reconstructed.steps.first.instruction, 'Turn right on Residency Rd');
      expect(reconstructed.isFallback, isFalse);
    });
  });

  group('NavigationIntelligence Engine', () {
    final nav = NavigationIntelligence();

    final testJourney = Journey(
      id: 'test-journey-01',
      userId: 'user-01',
      destinationName: 'Metro Station',
      destinationLat: 12.9750,
      destinationLng: 77.5950,
      originLat: 12.9700,
      originLng: 77.5900,
      travelMode: TravelMode.walking,
      status: JourneyStatus.active,
      startedAt: DateTime.now(),
      expectedArrivalTime: DateTime.now().add(const Duration(minutes: 15)),
      checkinIntervalMinutes: 5,
      notifyContactIds: const ['c1'],
      notifyContactNames: const ['Aunt May'],
      notifyContactPhones: const ['+919876543210'],
      totalDistanceKm: 1.0,
      routeCoordinates: const [
        [12.9700, 77.5900],
        [12.9725, 77.5925],
        [12.9750, 77.5950],
      ],
      routeSource: 'OSRM (OpenStreetMap)',
    );

    final routePoints = testJourney.routeLatLngs;

    test('suppresses false-positive deviation alert when GPS accuracy is poor (>35m)', () async {
      // Fix is 150 meters away, but accuracy is 45m (poor, e.g. indoor or dense buildings)
      final status = await nav.evaluatePosition(
        currentPos: const LatLng(12.9715, 77.5940),
        accuracyMeters: 45.0,
        speedKmh: 4.0,
        headingDegrees: 45.0,
        journey: testJourney,
        activeRoutePoints: routePoints,
        nearbyPlaces: const [],
        communityReports: const [],
      );

      // Should suppress off-route trigger due to high uncertainty
      expect(status.isOffRoute, isFalse);
      expect(status.alertMessage, isNull);
    });

    test('detects genuine off-route deviation with consecutive high-accuracy fixes', () async {
      // Fix 1: off route by >100m, accuracy is high (8m)
      final status1 = await nav.evaluatePosition(
        currentPos: const LatLng(12.9800, 77.6000), // ~700m away
        accuracyMeters: 8.0,
        speedKmh: 4.0,
        headingDegrees: 45.0,
        journey: testJourney,
        activeRoutePoints: routePoints,
        nearbyPlaces: const [],
        communityReports: const [],
      );

      // Needs 2 consecutive fixes to prevent single-spike false positives
      expect(status1.isOffRoute, isFalse);

      // Fix 2: still off route, accuracy is high (8m)
      final status2 = await nav.evaluatePosition(
        currentPos: const LatLng(12.9805, 77.6005),
        accuracyMeters: 8.0,
        speedKmh: 4.0,
        headingDegrees: 45.0,
        journey: testJourney,
        activeRoutePoints: routePoints,
        nearbyPlaces: const [],
        communityReports: const [],
      );

      // 2 consecutive fixes -> triggers deviation
      expect(status2.isOffRoute, isTrue);
      expect(status2.alertMessage, contains('Route deviation detected'));
      expect(status2.distanceToRouteMeters, greaterThan(50));
    });

    test('generates transparent explainable safety explanation without fake AI scores', () async {
      final safeHavens = <SafeHavenPlace>[
        const SafeHavenPlace(
          id: 'hosp-01',
          name: 'City Care Hospital',
          category: SafeHavenCategory.hospital,
          address: 'Main Ring Rd',
          latitude: 12.9710,
          longitude: 77.5910,
          isVerified: true,
          isOpen24Hours: true,
          phone: '108',
          distanceKm: 0.2,
        ),
        const SafeHavenPlace(
          id: 'pol-01',
          name: 'Central Police Station',
          category: SafeHavenCategory.police,
          address: 'Station Rd',
          latitude: 12.9720,
          longitude: 77.5920,
          isVerified: true,
          isOpen24Hours: true,
          phone: '100',
          distanceKm: 0.3,
        ),
      ];

      final status = await nav.evaluatePosition(
        currentPos: const LatLng(12.9705, 77.5905),
        accuracyMeters: 5.0,
        speedKmh: 4.0,
        headingDegrees: 0.0,
        journey: testJourney,
        activeRoutePoints: routePoints,
        nearbyPlaces: safeHavens,
        communityReports: const [],
      );

      expect(status.safetyExplanation, contains('Nearby Help Points:'));
      expect(status.safetyExplanation, contains('City Care Hospital'));
      expect(status.safetyExplanation, contains('Central Police Station'));
    });
  });
}
