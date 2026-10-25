import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

/// Accurate mathematical and geometric utilities for geographic navigation.
class GeoMathUtils {
  static const double earthRadiusMeters = 6371000.0;

  /// Calculates geodesic distance between two coordinates in meters using the Haversine formula.
  static double distanceMeters(LatLng p1, LatLng p2) {
    final dLat = _deg2rad(p2.latitude - p1.latitude);
    final dLon = _deg2rad(p2.longitude - p1.longitude);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(p1.latitude)) *
            math.cos(_deg2rad(p2.latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  /// Calculates geodesic distance in kilometers.
  static double distanceKm(LatLng p1, LatLng p2) {
    return distanceMeters(p1, p2) / 1000.0;
  }

  /// Calculates total distance of a polyline in kilometers.
  static double totalPolylineDistanceKm(List<LatLng> polyline) {
    if (polyline.length < 2) return 0.0;
    double totalMeters = 0.0;
    for (int i = 0; i < polyline.length - 1; i++) {
      totalMeters += distanceMeters(polyline[i], polyline[i + 1]);
    }
    return totalMeters / 1000.0;
  }

  /// Calculates the shortest perpendicular distance (cross-track distance) in meters
  /// from point [p] to a line segment defined by [a] and [b].
  static double distanceToSegmentMeters(LatLng p, LatLng a, LatLng b) {
    final segmentLengthMeters = distanceMeters(a, b);
    if (segmentLengthMeters < 1.0) {
      return distanceMeters(p, a);
    }

    // Convert to planar projection relative to point A for localized high precision
    final dLat = _deg2rad(b.latitude - a.latitude);
    final dLon = _deg2rad(b.longitude - a.longitude);
    final cosLat = math.cos(_deg2rad(a.latitude));

    final dx = dLon * cosLat * earthRadiusMeters;
    final dy = dLat * earthRadiusMeters;

    final pLat = _deg2rad(p.latitude - a.latitude);
    final pLon = _deg2rad(p.longitude - a.longitude);
    final px = pLon * cosLat * earthRadiusMeters;
    final py = pLat * earthRadiusMeters;

    // Vector projection factor t along segment AB
    final dot = px * dx + py * dy;
    final lenSq = dx * dx + dy * dy;
    final t = (lenSq > 0) ? (dot / lenSq).clamp(0.0, 1.0) : 0.0;

    // Closest point coordinates on segment
    final projX = t * dx;
    final projY = t * dy;

    final distSq = (px - projX) * (px - projX) + (py - projY) * (py - projY);
    return math.sqrt(distSq);
  }

  /// Calculates the shortest distance in meters from point [p] to any segment of [polyline].
  static double distanceToPolylineMeters(LatLng p, List<LatLng> polyline) {
    if (polyline.isEmpty) return double.infinity;
    if (polyline.length == 1) return distanceMeters(p, polyline.first);

    double minDistance = double.infinity;
    for (int i = 0; i < polyline.length - 1; i++) {
      final d = distanceToSegmentMeters(p, polyline[i], polyline[i + 1]);
      if (d < minDistance) {
        minDistance = d;
      }
    }
    return minDistance;
  }

  /// Finds the index of the closest segment along [polyline] to point [p].
  static int findClosestSegmentIndex(LatLng p, List<LatLng> polyline) {
    if (polyline.length < 2) return 0;
    int closestIdx = 0;
    double minDistance = double.infinity;

    for (int i = 0; i < polyline.length - 1; i++) {
      final d = distanceToSegmentMeters(p, polyline[i], polyline[i + 1]);
      if (d < minDistance) {
        minDistance = d;
        closestIdx = i;
      }
    }
    return closestIdx;
  }

  /// Calculates remaining route distance in kilometers from current location [currentPos]
  /// to the end of the polyline.
  static double calculateRemainingDistanceKm(
    LatLng currentPos,
    List<LatLng> polyline,
  ) {
    if (polyline.isEmpty) return 0.0;
    if (polyline.length == 1) return distanceKm(currentPos, polyline.first);

    final closestIdx = findClosestSegmentIndex(currentPos, polyline);
    
    // Distance from current position to the start of the next segment point
    double remainingMeters = distanceMeters(currentPos, polyline[closestIdx + 1]);

    // Sum all subsequent segments to the end of the route
    for (int i = closestIdx + 1; i < polyline.length - 1; i++) {
      remainingMeters += distanceMeters(polyline[i], polyline[i + 1]);
    }

    return remainingMeters / 1000.0;
  }

  /// Calculates the initial bearing (compass heading) from [start] to [end] in degrees (0 - 360).
  static double calculateBearing(LatLng start, LatLng end) {
    final startLat = _deg2rad(start.latitude);
    final startLon = _deg2rad(start.longitude);
    final endLat = _deg2rad(end.latitude);
    final endLon = _deg2rad(end.longitude);

    final dLon = endLon - startLon;

    final y = math.sin(dLon) * math.cos(endLat);
    final x = math.cos(startLat) * math.sin(endLat) -
        math.sin(startLat) * math.cos(endLat) * math.cos(dLon);

    final radians = math.atan2(y, x);
    return (_rad2deg(radians) + 360.0) % 360.0;
  }

  static double _deg2rad(double deg) => deg * (math.pi / 180.0);
  static double _rad2deg(double rad) => rad * (180.0 / math.pi);
}
