import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../models/journey.dart';
import '../models/safe_haven.dart';
import '../utils/geo_math_utils.dart';
import 'routing_service.dart';

/// Navigation status snapshot during an active journey
class NavigationStatus {
  final LatLng currentPosition;
  final double accuracyMeters;
  final double currentSpeedKmh;
  final double headingDegrees;
  final double distanceTravelledKm;
  final double distanceRemainingKm;
  final int etaMinutesRemaining;
  final DateTime estimatedArrivalTime;
  final bool isOffRoute;
  final double distanceToRouteMeters;
  final bool isRerouting;
  final String safetyExplanation;
  final String? alertMessage;

  const NavigationStatus({
    required this.currentPosition,
    required this.accuracyMeters,
    required this.currentSpeedKmh,
    required this.headingDegrees,
    required this.distanceTravelledKm,
    required this.distanceRemainingKm,
    required this.etaMinutesRemaining,
    required this.estimatedArrivalTime,
    required this.isOffRoute,
    required this.distanceToRouteMeters,
    required this.isRerouting,
    required this.safetyExplanation,
    this.alertMessage,
  });
}

/// Navigation intelligence engine handling off-route detection, rerouting,
/// real progress, and explainable safety signals.
class NavigationIntelligence {
  static final NavigationIntelligence _instance = NavigationIntelligence._internal();
  factory NavigationIntelligence() => _instance;
  NavigationIntelligence._internal();

  final RoutingService _routingService = RoutingService();

  // Deviation detection state
  int _consecutiveOffRouteFixes = 0;
  DateTime? _lastRerouteRequestAt;
  bool _isRerouting = false;

  /// Process a live GPS fix against the journey and safe havens.
  Future<NavigationStatus> evaluatePosition({
    required LatLng currentPos,
    required double accuracyMeters,
    required double speedKmh,
    required double headingDegrees,
    required Journey journey,
    required List<LatLng> activeRoutePoints,
    required List<SafeHavenPlace> nearbyPlaces,
    required List<CommunityReport> communityReports,
  }) async {
    final now = DateTime.now();

    // 1. Calculate distance from user's current GPS to active polyline
    final distanceToRouteMeters = activeRoutePoints.isNotEmpty
        ? GeoMathUtils.distanceToPolylineMeters(currentPos, activeRoutePoints)
        : 0.0;

    // 2. Off-route detection with false-positive suppression:
    // Ignore deviations if GPS accuracy is poor (> 35m) to prevent false alerts from building shadows.
    bool offRoute = false;
    final deviationThresholdMeters = (accuracyMeters * 1.5).clamp(40.0, 90.0);

    if (accuracyMeters <= 35.0 && distanceToRouteMeters > deviationThresholdMeters) {
      _consecutiveOffRouteFixes++;
      if (_consecutiveOffRouteFixes >= 2) {
        offRoute = true;
      }
    } else if (distanceToRouteMeters < 25.0) {
      _consecutiveOffRouteFixes = 0;
      offRoute = false;
    } else {
      // Retain previous state if in transition band
      offRoute = _consecutiveOffRouteFixes >= 2;
    }

    // 3. Dynamic remaining distance
    double remainingKm = 0.0;
    if (activeRoutePoints.isNotEmpty) {
      remainingKm = GeoMathUtils.calculateRemainingDistanceKm(currentPos, activeRoutePoints);
    } else {
      remainingKm = GeoMathUtils.distanceKm(
        currentPos,
        LatLng(journey.destinationLat, journey.destinationLng),
      );
    }
    remainingKm = double.parse(remainingKm.toStringAsFixed(1));

    // Distance travelled so far
    final initialTotalKm = journey.totalDistanceKm > 0 ? journey.totalDistanceKm : remainingKm;
    final travelledKm = (initialTotalKm - remainingKm).clamp(0.0, initialTotalKm);

    // 4. Dynamic ETA Calculation
    // Use actual current speed if moving steadily (> 5 km/h), else mode default speed
    double effectiveSpeedKmh = speedKmh;
    if (effectiveSpeedKmh < 5.0) {
      switch (journey.travelMode) {
        case TravelMode.walking:
          effectiveSpeedKmh = 4.5;
          break;
        case TravelMode.bike:
          effectiveSpeedKmh = 16.0;
          break;
        case TravelMode.car:
        case TravelMode.bus:
        case TravelMode.other:
          effectiveSpeedKmh = 35.0;
          break;
      }
    }

    final etaMinutes = ((remainingKm / effectiveSpeedKmh) * 60).round().clamp(1, 999);
    final dynamicEtaTime = now.add(Duration(minutes: etaMinutes));

    // 5. Evaluate explainable safety signals
    final safetyExplanation = _generateSafetyExplanation(
      currentPos: currentPos,
      activeRoute: activeRoutePoints,
      places: nearbyPlaces,
      reports: communityReports,
    );

    String? alertMsg;
    if (offRoute) {
      alertMsg = 'Route deviation detected (${distanceToRouteMeters.round()} m off route).';
    }

    return NavigationStatus(
      currentPosition: currentPos,
      accuracyMeters: accuracyMeters,
      currentSpeedKmh: speedKmh,
      headingDegrees: headingDegrees,
      distanceTravelledKm: double.parse(travelledKm.toStringAsFixed(1)),
      distanceRemainingKm: remainingKm,
      etaMinutesRemaining: etaMinutes,
      estimatedArrivalTime: dynamicEtaTime,
      isOffRoute: offRoute,
      distanceToRouteMeters: distanceToRouteMeters,
      isRerouting: _isRerouting,
      safetyExplanation: safetyExplanation,
      alertMessage: alertMsg,
    );
  }

  /// Attempts automatic rerouting from current position to destination.
  Future<RouteResult?> attemptReroute({
    required LatLng currentPos,
    required double destinationLat,
    required double destinationLng,
    required TravelMode travelMode,
  }) async {
    final now = DateTime.now();

    // Throttling: Do not request reroutes more frequently than once every 20s
    if (_lastRerouteRequestAt != null &&
        now.difference(_lastRerouteRequestAt!) < const Duration(seconds: 20)) {
      return null;
    }

    _lastRerouteRequestAt = now;
    _isRerouting = true;

    try {
      final newRoute = await _routingService.calculateRoute(
        origin: currentPos,
        destination: LatLng(destinationLat, destinationLng),
        mode: travelMode,
        requestAlternatives: false,
      );

      _consecutiveOffRouteFixes = 0;
      _isRerouting = false;
      return newRoute;
    } catch (e) {
      debugPrint('[NavigationIntelligence] Rerouting error: $e');
      _isRerouting = false;
      return null;
    }
  }

  /// Generates real, explainable safety context based on actual nearby facilities and reports.
  String _generateSafetyExplanation({
    required LatLng currentPos,
    required List<LatLng> activeRoute,
    required List<SafeHavenPlace> places,
    required List<CommunityReport> reports,
  }) {
    // Find closest hospital & police station
    SafeHavenPlace? closestHospital;
    SafeHavenPlace? closestPolice;
    double minHospDist = double.infinity;
    double minPoliceDist = double.infinity;

    for (final p in places) {
      final dist = GeoMathUtils.distanceMeters(currentPos, LatLng(p.latitude, p.longitude));
      if (p.category == SafeHavenCategory.hospital && dist < minHospDist) {
        minHospDist = dist;
        closestHospital = p;
      } else if (p.category == SafeHavenCategory.police && dist < minPoliceDist) {
        minPoliceDist = dist;
        closestPolice = p;
      }
    }

    // Count community reports within 500m of user
    int nearbyReportCount = 0;
    for (final rep in reports) {
      final dist = GeoMathUtils.distanceMeters(currentPos, LatLng(rep.latitude, rep.longitude));
      if (dist <= 500) {
        nearbyReportCount++;
      }
    }

    final List<String> signals = [];
    if (closestHospital != null && minHospDist < 3000) {
      final km = (minHospDist / 1000).toStringAsFixed(1);
      signals.add('${closestHospital.name} ($km km)');
    }
    if (closestPolice != null && minPoliceDist < 3000) {
      final km = (minPoliceDist / 1000).toStringAsFixed(1);
      signals.add('${closestPolice.name} ($km km)');
    }

    if (signals.isEmpty && nearbyReportCount == 0) {
      return 'Standard public road network. No emergency shelters within 3 km.';
    }

    final buffer = StringBuffer('Nearby Help Points: ');
    buffer.write(signals.join(' • '));
    if (nearbyReportCount > 0) {
      buffer.write(' • $nearbyReportCount local community report(s) nearby');
    }
    return buffer.toString();
  }
}
