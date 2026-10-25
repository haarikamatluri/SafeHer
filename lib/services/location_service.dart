import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'diagnostic_logger.dart';

class LocationResult {
  final bool isSuccess;
  final double? latitude;
  final double? longitude;
  final double? accuracyMeters;
  final DateTime? capturedAt;
  final bool isFresh;
  final String source; // 'fresh_gps', 'cached', 'unavailable'
  final Duration? age;
  final String? failureReason; // 'service_disabled', 'permission_denied', 'permission_permanently_denied', 'timeout', 'no_fix', 'error'
  final String? errorMessage;
  final bool isPermissionDenied;
  final bool isPermissionPermanentlyDenied;
  final bool isServiceDisabled;

  LocationResult({
    required this.isSuccess,
    this.latitude,
    this.longitude,
    double? accuracy,
    double? accuracyMeters,
    DateTime? timestamp,
    DateTime? capturedAt,
    this.isFresh = false,
    this.source = 'unavailable',
    this.age,
    this.failureReason,
    this.errorMessage,
    this.isPermissionDenied = false,
    this.isPermissionPermanentlyDenied = false,
    this.isServiceDisabled = false,
  })  : accuracyMeters = accuracyMeters ?? accuracy,
        capturedAt = capturedAt ?? timestamp ?? (isSuccess ? DateTime.now() : null);

  double? get accuracy => accuracyMeters;
  DateTime get timestamp => capturedAt ?? DateTime.now();

  String? get mapsUrl {
    if (latitude != null && longitude != null) {
      return 'https://maps.google.com/?q=$latitude,$longitude';
    }
    return null;
  }

  String get ageDescription {
    if (isFresh) return 'Fresh (< 5s)';
    if (age == null) return 'Unknown age';
    if (age!.inSeconds < 60) return '${age!.inSeconds}s ago';
    if (age!.inMinutes < 60) return '${age!.inMinutes}m ago';
    return '${age!.inHours}h ago';
  }

  String get formattedAccuracy {
    if (accuracyMeters == null) return '±?m';
    return '±${accuracyMeters!.toStringAsFixed(1)}m';
  }
}

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  LocationResult? _lastKnownResult;
  LocationResult? get lastKnownResult => _lastKnownResult;

  /// Check whether GPS hardware service is turned on
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      debugPrint('[LocationService] isLocationServiceEnabled error: $e');
      return false;
    }
  }

  /// Check current permission status without prompting
  Future<LocationPermission> checkPermission() async {
    try {
      return await Geolocator.checkPermission();
    } catch (e) {
      debugPrint('[LocationService] checkPermission error: $e');
      return LocationPermission.denied;
    }
  }

  /// Request location permission
  Future<LocationPermission> requestPermission() async {
    try {
      return await Geolocator.requestPermission();
    } catch (e) {
      debugPrint('[LocationService] requestPermission error: $e');
      return LocationPermission.denied;
    }
  }

  /// Dedicated fast emergency location acquisition with bounded timeout.
  /// Races fresh GPS against cached position so SOS is never blocked indefinitely.
  Future<LocationResult> getEmergencyLocation({
    Duration timeout = const Duration(seconds: 4),
  }) async {
    DiagnosticLogger().logLocationRequested(timeout: timeout);

    try {
      // 1. Check GPS Hardware Service
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        final res = LocationResult(
          isSuccess: false,
          isServiceDisabled: true,
          failureReason: 'service_disabled',
          source: 'unavailable',
          errorMessage: 'Location services (GPS) are turned off on your device.',
        );
        _lastKnownResult = res;
        DiagnosticLogger().logLocationFixReceived(
          isFresh: false,
          source: 'unavailable',
        );
        return res;
      }

      // 2. Fast Permission Check & Pre-flight
      var permission = await checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await requestPermission();
        if (permission == LocationPermission.denied) {
          final res = LocationResult(
            isSuccess: false,
            isPermissionDenied: true,
            failureReason: 'permission_denied',
            source: 'unavailable',
            errorMessage: 'Location permission was denied.',
          );
          _lastKnownResult = res;
          DiagnosticLogger().logLocationFixReceived(
            isFresh: false,
            source: 'unavailable',
          );
          return res;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        final res = LocationResult(
          isSuccess: false,
          isPermissionPermanentlyDenied: true,
          failureReason: 'permission_permanently_denied',
          source: 'unavailable',
          errorMessage: 'Location permission is permanently denied. Please enable it in Android Settings.',
        );
        _lastKnownResult = res;
        DiagnosticLogger().logLocationFixReceived(
          isFresh: false,
          source: 'unavailable',
        );
        return res;
      }

      // 3. Inspect cached position in parallel while requesting fresh GPS
      final cachedFuture = Geolocator.getLastKnownPosition();
      final freshFuture = Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: timeout,
        ),
      );

      Position? freshPos;
      try {
        freshPos = await freshFuture;
      } catch (e) {
        debugPrint('[LocationService] Fresh GPS timed out or failed: $e');
      }

      // 4. Validate fresh position
      if (freshPos != null && _isValidCoordinates(freshPos.latitude, freshPos.longitude)) {
        final res = LocationResult(
          isSuccess: true,
          latitude: freshPos.latitude,
          longitude: freshPos.longitude,
          accuracyMeters: freshPos.accuracy,
          capturedAt: freshPos.timestamp,
          isFresh: true,
          source: 'fresh_gps',
          age: Duration.zero,
        );
        _lastKnownResult = res;
        DiagnosticLogger().logLocationFixReceived(
          isFresh: true,
          source: 'fresh_gps',
          latitude: res.latitude,
          longitude: res.longitude,
          accuracyMeters: res.accuracyMeters,
          age: Duration.zero,
        );
        return res;
      }

      // 5. Fallback to cached position if fresh GPS deadline exceeded
      Position? cachedPos;
      try {
        cachedPos = await cachedFuture;
      } catch (_) {}

      if (cachedPos != null && _isValidCoordinates(cachedPos.latitude, cachedPos.longitude)) {
        final age = DateTime.now().difference(cachedPos.timestamp);
        final res = LocationResult(
          isSuccess: true,
          latitude: cachedPos.latitude,
          longitude: cachedPos.longitude,
          accuracyMeters: cachedPos.accuracy,
          capturedAt: cachedPos.timestamp,
          isFresh: age.inSeconds < 10,
          source: 'cached',
          age: age,
        );
        _lastKnownResult = res;
        DiagnosticLogger().logLocationFixReceived(
          isFresh: res.isFresh,
          source: 'cached',
          latitude: res.latitude,
          longitude: res.longitude,
          accuracyMeters: res.accuracyMeters,
          age: age,
        );
        return res;
      }

      // 6. No usable fix available - do not block SOS!
      final res = LocationResult(
        isSuccess: false,
        isFresh: false,
        source: 'unavailable',
        failureReason: 'timeout',
        errorMessage: 'Unable to acquire GPS fix within emergency deadline.',
      );
      _lastKnownResult = res;
      DiagnosticLogger().logLocationFixReceived(
        isFresh: false,
        source: 'unavailable',
      );
      return res;
    } catch (e) {
      debugPrint('[LocationService] Emergency location error: $e');
      final res = LocationResult(
        isSuccess: false,
        isFresh: false,
        source: 'unavailable',
        failureReason: 'error',
        errorMessage: 'Location acquisition failed: $e',
      );
      _lastKnownResult = res;
      return res;
    }
  }

  /// Backward compatible wrapper
  Future<LocationResult> getCurrentLocation({
    Duration timeout = const Duration(seconds: 4),
  }) async {
    return getEmergencyLocation(timeout: timeout);
  }

  bool _isValidCoordinates(double lat, double lng) {
    if (lat < -90.0 || lat > 90.0) return false;
    if (lng < -180.0 || lng > 180.0) return false;
    // Discard exact 0.0, 0.0 unless verified (Null Island)
    if (lat == 0.0 && lng == 0.0) return false;
    return true;
  }

  /// Open Android app settings for permissions
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Open Android location settings
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }
}
