import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/journey.dart';
import '../utils/geo_math_utils.dart';

/// Single step / maneuver along a route
class RouteStep {
  final String instruction;
  final double distanceMeters;
  final int durationSeconds;
  final LatLng startPoint;

  const RouteStep({
    required this.instruction,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.startPoint,
  });

  Map<String, dynamic> toMap() {
    return {
      'instruction': instruction,
      'distanceMeters': distanceMeters,
      'durationSeconds': durationSeconds,
      'lat': startPoint.latitude,
      'lng': startPoint.longitude,
    };
  }

  factory RouteStep.fromMap(Map<String, dynamic> map) {
    return RouteStep(
      instruction: map['instruction'] as String? ?? 'Continue on route',
      distanceMeters: (map['distanceMeters'] as num?)?.toDouble() ?? 0.0,
      durationSeconds: (map['durationSeconds'] as num?)?.toInt() ?? 0,
      startPoint: LatLng(
        (map['lat'] as num?)?.toDouble() ?? 0.0,
        (map['lng'] as num?)?.toDouble() ?? 0.0,
      ),
    );
  }
}

/// Complete routing response with actual road geometry, distance, and duration
class RouteResult {
  final List<LatLng> points;
  final double distanceKm;
  final int durationMinutes;
  final String summary;
  final List<RouteStep> steps;
  final List<RouteResult> alternatives;
  final String providerName;
  final DateTime retrievedAt;
  final bool isTrafficAware;
  final bool isFallback;
  final String? warningMessage;

  const RouteResult({
    required this.points,
    required this.distanceKm,
    required this.durationMinutes,
    required this.summary,
    this.steps = const [],
    this.alternatives = const [],
    required this.providerName,
    required this.retrievedAt,
    this.isTrafficAware = false,
    this.isFallback = false,
    this.warningMessage,
  });

  Map<String, dynamic> toMap() {
    return {
      'points': points.map((p) => [p.latitude, p.longitude]).toList(),
      'distanceKm': distanceKm,
      'durationMinutes': durationMinutes,
      'summary': summary,
      'steps': steps.map((s) => s.toMap()).toList(),
      'providerName': providerName,
      'retrievedAt': retrievedAt.toIso8601String(),
      'isTrafficAware': isTrafficAware,
      'isFallback': isFallback,
      'warningMessage': warningMessage,
    };
  }

  factory RouteResult.fromMap(Map<String, dynamic> map) {
    final rawPoints = map['points'] as List<dynamic>? ?? [];
    final pts = rawPoints.map((item) {
      final list = item as List<dynamic>;
      return LatLng(
        (list[0] as num).toDouble(),
        (list[1] as num).toDouble(),
      );
    }).toList();

    final rawSteps = map['steps'] as List<dynamic>? ?? [];
    final stepList = rawSteps
        .map((s) => RouteStep.fromMap(s as Map<String, dynamic>))
        .toList();

    return RouteResult(
      points: pts,
      distanceKm: (map['distanceKm'] as num?)?.toDouble() ?? 0.0,
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 0,
      summary: map['summary'] as String? ?? 'Route',
      steps: stepList,
      providerName: map['providerName'] as String? ?? 'Cached Route',
      retrievedAt: DateTime.tryParse(map['retrievedAt'] as String? ?? '') ??
          DateTime.now(),
      isTrafficAware: map['isTrafficAware'] as bool? ?? false,
      isFallback: map['isFallback'] as bool? ?? false,
      warningMessage: map['warningMessage'] as String?,
    );
  }
}

/// Routing service abstraction for road network calculation.
class RoutingService {
  static final RoutingService _instance = RoutingService._internal();
  factory RoutingService() => _instance;
  RoutingService._internal();

  final Map<String, RouteResult> _memoryCache = {};
  static const Duration _cacheDuration = Duration(minutes: 20);

  /// Computes a real road route from [origin] to [destination] using OSRM.
  Future<RouteResult> calculateRoute({
    required LatLng origin,
    required LatLng destination,
    TravelMode mode = TravelMode.bike,
    bool requestAlternatives = true,
  }) async {
    final cacheKey =
        '${origin.latitude.toStringAsFixed(4)},${origin.longitude.toStringAsFixed(4)}->'
        '${destination.latitude.toStringAsFixed(4)},${destination.longitude.toStringAsFixed(4)}_${mode.name}';

    // 1. Check in-memory cache
    final cached = _memoryCache[cacheKey];
    if (cached != null) {
      if (DateTime.now().difference(cached.retrievedAt) < _cacheDuration) {
        return cached;
      }
    }

    // 2. Map mode to profile
    String profile = 'driving';
    switch (mode) {
      case TravelMode.walking:
        profile = 'walking';
        break;
      case TravelMode.bike:
        // Try bike profile, fallback to driving if public server doesn't host bike
        profile = 'bike';
        break;
      case TravelMode.car:
      case TravelMode.bus:
      case TravelMode.other:
        profile = 'driving';
        break;
    }

    try {
      final result = await _fetchFromOsrm(
        origin: origin,
        destination: destination,
        profile: profile,
        requestAlternatives: requestAlternatives,
      );

      if (result != null) {
        _memoryCache[cacheKey] = result;
        return result;
      }

      // If bike profile failed, attempt driving profile as realistic road backup
      if (profile == 'bike') {
        final fallbackDriving = await _fetchFromOsrm(
          origin: origin,
          destination: destination,
          profile: 'driving',
          requestAlternatives: requestAlternatives,
        );
        if (fallbackDriving != null) {
          // Adjust duration estimate for bike speed (~16 km/h)
          final adjustedMinutes = ((fallbackDriving.distanceKm / 16.0) * 60).round().clamp(1, 480);
          final adjusted = RouteResult(
            points: fallbackDriving.points,
            distanceKm: fallbackDriving.distanceKm,
            durationMinutes: adjustedMinutes,
            summary: fallbackDriving.summary,
            steps: fallbackDriving.steps,
            alternatives: fallbackDriving.alternatives,
            providerName: 'OSRM (OpenStreetMap - Road Network)',
            retrievedAt: DateTime.now(),
            isTrafficAware: false,
            isFallback: false,
          );
          _memoryCache[cacheKey] = adjusted;
          return adjusted;
        }
      }
    } catch (e) {
      debugPrint('[RoutingService] OSRM live routing error: $e');
    }

    // 3. Fallback: Geodesic straight-line road estimation when offline
    final fallback = _createOfflineFallbackRoute(
      origin: origin,
      destination: destination,
      mode: mode,
    );
    return fallback;
  }

  Future<RouteResult?> _fetchFromOsrm({
    required LatLng origin,
    required LatLng destination,
    required String profile,
    required bool requestAlternatives,
  }) async {
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/$profile/'
      '${origin.longitude},${origin.latitude};'
      '${destination.longitude},${destination.latitude}'
      '?overview=full&geometries=geojson&steps=true'
      '${requestAlternatives ? "&alternatives=true" : ""}',
    );

    final response = await http
        .get(
          url,
          headers: {
            'User-Agent': 'SafeHer-WomenSafetyApp/1.0 (https://github.com/haarikamatluri/SafeHer)',
            'Accept': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 9));

    if (response.statusCode != 200) {
      debugPrint('[RoutingService] OSRM status code ${response.statusCode}');
      return null;
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    if (data['code'] != 'Ok') {
      return null;
    }

    final routes = data['routes'] as List<dynamic>?;
    if (routes == null || routes.isEmpty) return null;

    final primaryRouteData = routes.first as Map<String, dynamic>;
    final primaryResult = _parseSingleOsrmRoute(
      primaryRouteData,
      providerName: 'OSRM (OpenStreetMap Road Network)',
    );

    // Parse alternative routes if available
    final List<RouteResult> altResults = [];
    if (routes.length > 1) {
      for (int i = 1; i < routes.length; i++) {
        final altData = routes[i] as Map<String, dynamic>;
        altResults.add(
          _parseSingleOsrmRoute(
            altData,
            providerName: 'OSRM Alternative Route #$i',
          ),
        );
      }
    }

    return RouteResult(
      points: primaryResult.points,
      distanceKm: primaryResult.distanceKm,
      durationMinutes: primaryResult.durationMinutes,
      summary: primaryResult.summary,
      steps: primaryResult.steps,
      alternatives: altResults,
      providerName: 'OSRM (OpenStreetMap)',
      retrievedAt: DateTime.now(),
      isTrafficAware: false, // OSRM free public API is not real-time traffic aware
      isFallback: false,
    );
  }

  RouteResult _parseSingleOsrmRoute(
    Map<String, dynamic> routeMap, {
    required String providerName,
  }) {
    // 1. Geometry
    final geom = routeMap['geometry'] as Map<String, dynamic>;
    final coordinates = geom['coordinates'] as List<dynamic>;
    final points = coordinates.map((coord) {
      final list = coord as List<dynamic>;
      final lon = (list[0] as num).toDouble();
      final lat = (list[1] as num).toDouble();
      return LatLng(lat, lon);
    }).toList();

    // 2. Distance in meters -> km
    final meters = (routeMap['distance'] as num?)?.toDouble() ?? 0.0;
    final distanceKm = double.parse((meters / 1000.0).toStringAsFixed(1));

    // 3. Duration in seconds -> minutes
    final seconds = (routeMap['duration'] as num?)?.toDouble() ?? 0.0;
    final durationMinutes = (seconds / 60.0).round().clamp(1, 9999);

    // 4. Legs and Steps
    final List<RouteStep> steps = [];
    final legs = routeMap['legs'] as List<dynamic>? ?? [];
    String summary = 'Main Route';

    if (legs.isNotEmpty) {
      final leg = legs.first as Map<String, dynamic>;
      summary = (leg['summary'] as String?)?.isNotEmpty == true
          ? leg['summary'] as String
          : 'Via primary road';

      final rawSteps = leg['steps'] as List<dynamic>? ?? [];
      for (final s in rawSteps) {
        final stepMap = s as Map<String, dynamic>;
        final maneuver = stepMap['maneuver'] as Map<String, dynamic>? ?? {};
        final instruction = (maneuver['type'] as String? ?? 'continue') +
            ((maneuver['modifier'] != null)
                ? ' ${maneuver['modifier']}'
                : '') +
            ((stepMap['name'] != null && (stepMap['name'] as String).isNotEmpty)
                ? ' on ${stepMap['name']}'
                : '');

        final loc = maneuver['location'] as List<dynamic>?;
        LatLng stepPoint = points.isNotEmpty ? points.first : const LatLng(0, 0);
        if (loc != null && loc.length >= 2) {
          stepPoint = LatLng((loc[1] as num).toDouble(), (loc[0] as num).toDouble());
        }

        steps.add(
          RouteStep(
            instruction: instruction.trim(),
            distanceMeters: (stepMap['distance'] as num?)?.toDouble() ?? 0.0,
            durationSeconds: (stepMap['duration'] as num?)?.toInt() ?? 0,
            startPoint: stepPoint,
          ),
        );
      }
    }

    return RouteResult(
      points: points,
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
      summary: summary,
      steps: steps,
      providerName: providerName,
      retrievedAt: DateTime.now(),
      isTrafficAware: false,
      isFallback: false,
    );
  }

  RouteResult _createOfflineFallbackRoute({
    required LatLng origin,
    required LatLng destination,
    required TravelMode mode,
  }) {
    // Generate an interpolated multi-point geodesic path for offline display
    final List<LatLng> points = [];
    const int segments = 8;
    for (int i = 0; i <= segments; i++) {
      final t = i / segments;
      final lat = origin.latitude + (destination.latitude - origin.latitude) * t;
      final lng = origin.longitude + (destination.longitude - origin.longitude) * t;
      points.add(LatLng(lat, lng));
    }

    final directDistanceKm = GeoMathUtils.distanceKm(origin, destination);
    // Road factor heuristic: roads are typically 1.25x longer than direct Euclidean distance
    final estimatedDistanceKm = double.parse((directDistanceKm * 1.25).toStringAsFixed(1));

    // Approximate speeds
    double speedKmH = 20.0;
    if (mode == TravelMode.walking) speedKmH = 4.5;
    if (mode == TravelMode.bike) speedKmH = 15.0;
    if (mode == TravelMode.car) speedKmH = 35.0;

    final estimatedMinutes = ((estimatedDistanceKm / speedKmH) * 60).round().clamp(2, 600);

    return RouteResult(
      points: points,
      distanceKm: estimatedDistanceKm,
      durationMinutes: estimatedMinutes,
      summary: 'Direct geodesic path (Offline mode)',
      steps: [
        RouteStep(
          instruction: 'Proceed toward destination',
          distanceMeters: estimatedDistanceKm * 1000,
          durationSeconds: estimatedMinutes * 60,
          startPoint: origin,
        ),
      ],
      providerName: 'Offline Estimation (Geodesic fallback)',
      retrievedAt: DateTime.now(),
      isTrafficAware: false,
      isFallback: true,
      warningMessage: 'Live routing server unreachable. Showing approximate straight-line route.',
    );
  }
}
