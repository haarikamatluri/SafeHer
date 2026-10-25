import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationResult {
  final bool isSuccess;
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final String? errorMessage;
  final bool isPermissionDenied;
  final bool isPermissionPermanentlyDenied;
  final bool isServiceDisabled;
  final DateTime timestamp;

  LocationResult({
    required this.isSuccess,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.errorMessage,
    this.isPermissionDenied = false,
    this.isPermissionPermanentlyDenied = false,
    this.isServiceDisabled = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  String? get mapsUrl {
    if (latitude != null && longitude != null) {
      return 'https://maps.google.com/?q=$latitude,$longitude';
    }
    return null;
  }
}

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  LocationResult? _lastKnownResult;
  LocationResult? get lastKnownResult => _lastKnownResult;

  /// Check whether GPS service is turned on
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

  /// Obtain device location with timeout and fallback to last known position
  Future<LocationResult> getCurrentLocation({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    try {
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        final res = LocationResult(
          isSuccess: false,
          isServiceDisabled: true,
          errorMessage:
              'Location services (GPS) are turned off on your device.',
        );
        _lastKnownResult = res;
        return res;
      }

      var permission = await checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await requestPermission();
        if (permission == LocationPermission.denied) {
          final res = LocationResult(
            isSuccess: false,
            isPermissionDenied: true,
            errorMessage: 'Location permission was denied.',
          );
          _lastKnownResult = res;
          return res;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        final res = LocationResult(
          isSuccess: false,
          isPermissionPermanentlyDenied: true,
          errorMessage: 'Location permission is permanently denied. Please enable it in Android Settings.',
        );
        _lastKnownResult = res;
        return res;
      }

      // Try current position with timeout
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: timeout,
          ),
        );
      } catch (timeoutErr) {
        debugPrint(
          '[LocationService] Timeout fetching fresh GPS, falling back: $timeoutErr',
        );
        // Fallback to last known position
        position = await Geolocator.getLastKnownPosition();
      }

      if (position != null) {
        final res = LocationResult(
          isSuccess: true,
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
          timestamp: position.timestamp,
        );
        _lastKnownResult = res;
        return res;
      } else {
        final res = LocationResult(
          isSuccess: false,
          errorMessage:
              'Unable to acquire GPS coordinates within the timeout period.',
        );
        _lastKnownResult = res;
        return res;
      }
    } catch (e) {
      debugPrint('[LocationService] Unexpected error: $e');
      final res = LocationResult(
        isSuccess: false,
        errorMessage: 'Location error: $e',
      );
      _lastKnownResult = res;
      return res;
    }
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
