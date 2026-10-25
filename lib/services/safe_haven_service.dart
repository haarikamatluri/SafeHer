import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../models/safe_haven.dart';
import '../services/auth_service.dart';

class EmergencyServiceEntry {
  final String number;
  final String title;
  final String subtitle;
  final String iconCode;

  const EmergencyServiceEntry({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.iconCode,
  });
}

class SafeHavenService {
  static final SafeHavenService _instance = SafeHavenService._internal();
  factory SafeHavenService() => _instance;
  SafeHavenService._internal() {
    _initReports();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<SafeHavenPlace> _seedPlaces = const [
    SafeHavenPlace(
      id: 'place_hospital_1',
      name: 'Sri Padmavathi Hospital',
      category: SafeHavenCategory.hospital,
      address: 'Tiruchanur Road, Tirupati, AP',
      phone: '+91 87722 33455',
      latitude: 13.6180,
      longitude: 79.4320,
      isVerified: true,
      isOpen24Hours: true,
      operatingHours: 'Open 24 hours',
      distanceKm: 2.4,
      rating: 4.8,
      verificationSource: 'AP Health Dept & Police Verified',
    ),
    SafeHavenPlace(
      id: 'place_police_1',
      name: 'Tirupati Central Police Station',
      category: SafeHavenCategory.police,
      address: 'Railway Station Road, Tirupati, AP',
      phone: '+91 87722 89100',
      latitude: 13.6290,
      longitude: 79.4230,
      isVerified: true,
      isOpen24Hours: true,
      operatingHours: 'Open 24 hours',
      distanceKm: 1.2,
      rating: 4.9,
      verificationSource: 'Tirupati Urban Police Verified',
    ),
    SafeHavenPlace(
      id: 'place_pharmacy_1',
      name: 'Apollo 24/7 Pharmacy',
      category: SafeHavenCategory.pharmacy,
      address: 'Gandhi Road, Near Clock Tower, Tirupati, AP',
      phone: '+91 87722 25555',
      latitude: 13.6315,
      longitude: 79.4180,
      isVerified: true,
      isOpen24Hours: true,
      operatingHours: 'Open 24 hours',
      distanceKm: 0.8,
      rating: 4.7,
      verificationSource: 'Verified 24/7 Chemist Network',
    ),
    SafeHavenPlace(
      id: 'place_women_center_1',
      name: 'Women Protection & Help Centre',
      category: SafeHavenCategory.womenCenter,
      address: 'Collectorate Complex, Tirupati, AP',
      phone: '+91 87722 56100',
      latitude: 13.6350,
      longitude: 79.4120,
      isVerified: true,
      isOpen24Hours: true,
      operatingHours: 'Open 24 hours',
      distanceKm: 1.8,
      rating: 4.9,
      verificationSource: 'Department of Women & Child Welfare',
    ),
    SafeHavenPlace(
      id: 'place_safe_spot_1',
      name: 'SV University Security Zone',
      category: SafeHavenCategory.verifiedPlace,
      address: 'Main Campus Gate, SVU, Tirupati, AP',
      phone: '+91 87722 89555',
      latitude: 13.6385,
      longitude: 79.4050,
      isVerified: true,
      isOpen24Hours: true,
      operatingHours: 'Open 24 hours',
      distanceKm: 3.5,
      rating: 4.6,
      verificationSource: 'Campus Security & CCTV Monitored',
    ),
    SafeHavenPlace(
      id: 'place_hospital_2',
      name: 'SVIMS Super Speciality Hospital',
      category: SafeHavenCategory.hospital,
      address: 'Alipiri Road, Tirupati, AP',
      phone: '+91 87722 87777',
      latitude: 13.6420,
      longitude: 79.4080,
      isVerified: true,
      isOpen24Hours: true,
      operatingHours: 'Open 24 hours',
      distanceKm: 3.1,
      rating: 4.9,
      verificationSource: 'Government Tertiary Medical Center',
    ),
  ];

  final List<CommunityReport> _reports = [];

  void _initReports() {
    final now = DateTime.now();
    _reports.addAll([
      CommunityReport(
        id: 'rep_1',
        userId: 'community_member',
        title: 'Well lit and safe',
        locationName: 'Near Renigunta Road',
        latitude: 13.6250,
        longitude: 79.4400,
        createdAt: now.subtract(const Duration(hours: 2)),
        isVerified: true,
        category: 'lighting',
        notes: 'Bright LED streetlights and police patrol booth present.',
      ),
      CommunityReport(
        id: 'rep_2',
        userId: 'community_member',
        title: 'Poor lighting at night',
        locationName: 'SV University Road',
        latitude: 13.6360,
        longitude: 79.4090,
        createdAt: now.subtract(const Duration(days: 1)),
        isVerified: false,
        category: 'lighting',
        notes: 'Section between gate 2 and faculty quarters has flickering lights.',
      ),
      CommunityReport(
        id: 'rep_3',
        userId: 'community_member',
        title: 'Safe during daytime',
        locationName: 'Tirupati Bus Stand',
        latitude: 13.6275,
        longitude: 79.4210,
        createdAt: now.subtract(const Duration(days: 2)),
        isVerified: true,
        category: 'crowded_safe',
        notes: 'High pedestrian movement, auto stands, and 24/7 security.',
      ),
      CommunityReport(
        id: 'rep_4',
        userId: 'community_member',
        title: 'Street light not working',
        locationName: 'Air Bypass Road',
        latitude: 13.6210,
        longitude: 79.4150,
        createdAt: now.subtract(const Duration(days: 3)),
        isVerified: false,
        category: 'hazard',
        notes: 'Reported to municipal corporation. Take main road after 9 PM.',
      ),
    ]);
  }

  List<SafeHavenPlace> _livePlacesCache = [];
  DateTime? _lastLiveFetchTime;
  double? _lastLiveLat;
  double? _lastLiveLng;
  String _currentDataSource = 'SafeHer Verified Safe Haven Network (Local Cache)';

  String get currentDataSource => _currentDataSource;
  bool get isLivePlacesOnline => _lastLiveFetchTime != null &&
      DateTime.now().difference(_lastLiveFetchTime!) < const Duration(minutes: 30);

  /// Synchronous retrieval with live cache or seed places
  List<SafeHavenPlace> getPlaces({
    SafeHavenCategory category = SafeHavenCategory.all,
    Position? userPosition,
  }) {
    List<SafeHavenPlace> list = _livePlacesCache.isNotEmpty ? _livePlacesCache : _seedPlaces;
    if (category != SafeHavenCategory.all) {
      list = list.where((p) => p.category == category).toList();
    }

    if (userPosition != null) {
      return list.map((place) {
        final distMeters = Geolocator.distanceBetween(
          userPosition.latitude,
          userPosition.longitude,
          place.latitude,
          place.longitude,
        );
        final distKm = double.parse((distMeters / 1000).toStringAsFixed(1));
        return place.copyWith(distanceKm: distKm);
      }).toList()
        ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    }

    return list;
  }

  /// Live discovery from OpenStreetMap Overpass API
  Future<List<SafeHavenPlace>> fetchNearbyPlacesLive({
    required double latitude,
    required double longitude,
    double radiusMeters = 5000,
    SafeHavenCategory category = SafeHavenCategory.all,
  }) async {
    final now = DateTime.now();

    // Check if we have recent live cache within 500m and 15 mins
    if (_lastLiveFetchTime != null &&
        _lastLiveLat != null &&
        _lastLiveLng != null &&
        now.difference(_lastLiveFetchTime!) < const Duration(minutes: 15)) {
      final cachedDist = Geolocator.distanceBetween(
        latitude,
        longitude,
        _lastLiveLat!,
        _lastLiveLng!,
      );
      if (cachedDist < 500 && _livePlacesCache.isNotEmpty) {
        return getPlaces(
          category: category,
          userPosition: Position(
            latitude: latitude,
            longitude: longitude,
            timestamp: now,
            accuracy: 5.0,
            altitude: 0.0,
            altitudeAccuracy: 0.0,
            heading: 0.0,
            headingAccuracy: 0.0,
            speed: 0.0,
            speedAccuracy: 0.0,
          ),
        );
      }
    }

    // Overpass QL Query for real police, hospital, pharmacy, and social centers
    final query = '''
[out:json][timeout:10];
(
  node["amenity"="police"](around:${radiusMeters.toInt()},$latitude,$longitude);
  node["amenity"="hospital"](around:${radiusMeters.toInt()},$latitude,$longitude);
  node["amenity"="pharmacy"](around:${radiusMeters.toInt()},$latitude,$longitude);
  node["social_facility"](around:${radiusMeters.toInt()},$latitude,$longitude);
);
out body 25;
''';

    try {
      final response = await http
          .post(
            Uri.parse('https://overpass-api.de/api/interpreter'),
            headers: {
              'User-Agent': 'SafeHer-WomenSafetyApp/1.0 (https://github.com/haarikamatluri/SafeHer)',
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {'data': query},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        final elements = decoded['elements'] as List<dynamic>? ?? [];

        final List<SafeHavenPlace> liveResults = [];

        for (final elem in elements) {
          final elMap = elem as Map<String, dynamic>;
          final tags = elMap['tags'] as Map<String, dynamic>? ?? {};
          final name = tags['name'] as String? ?? tags['operator'] as String?;
          if (name == null || name.trim().isEmpty) continue;

          final elLat = (elMap['lat'] as num).toDouble();
          final elLng = (elMap['lon'] as num).toDouble();
          final amenity = tags['amenity'] as String?;

          SafeHavenCategory cat = SafeHavenCategory.verifiedPlace;
          if (amenity == 'police') {
            cat = SafeHavenCategory.police;
          } else if (amenity == 'hospital') {
            cat = SafeHavenCategory.hospital;
          } else if (amenity == 'pharmacy') {
            cat = SafeHavenCategory.pharmacy;
          } else if (tags['social_facility'] != null || amenity == 'social_facility') {
            cat = SafeHavenCategory.womenCenter;
          }

          final phone = tags['phone'] as String? ?? tags['contact:phone'] as String? ?? 'Not listed';
          final street = tags['addr:street'] as String? ?? '';
          final city = tags['addr:city'] as String? ?? '';
          final address = [street, city].where((s) => s.isNotEmpty).join(', ');

          final distMeters = Geolocator.distanceBetween(latitude, longitude, elLat, elLng);
          final distKm = double.parse((distMeters / 1000).toStringAsFixed(1));

          liveResults.add(
            SafeHavenPlace(
              id: 'osm_${elMap['id']}',
              name: name,
              category: cat,
              address: address.isNotEmpty ? address : 'Near current location',
              phone: phone,
              latitude: elLat,
              longitude: elLng,
              isVerified: false, // Community OSM data is unverified by official safe haven audit
              isOpen24Hours: tags['opening_hours'] == '24/7',
              operatingHours: tags['opening_hours'] as String? ?? 'Standard hours',
              distanceKm: distKm,
              rating: 4.5,
              verificationSource: 'OpenStreetMap Community Database (Overpass API)',
            ),
          );
        }

        // Merge with verified seed places (which have verified status)
        for (final seed in _seedPlaces) {
          final distMeters = Geolocator.distanceBetween(latitude, longitude, seed.latitude, seed.longitude);
          final distKm = double.parse((distMeters / 1000).toStringAsFixed(1));
          liveResults.add(seed.copyWith(distanceKm: distKm));
        }

        // Deduplicate by name and coordinates
        final Map<String, SafeHavenPlace> unique = {};
        for (final p in liveResults) {
          unique['${p.name}_${p.latitude.toStringAsFixed(3)}'] = p;
        }

        final sorted = unique.values.toList()
          ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

        _livePlacesCache = sorted;
        _lastLiveFetchTime = now;
        _lastLiveLat = latitude;
        _lastLiveLng = longitude;
        _currentDataSource = 'OpenStreetMap (Live Overpass API)';

        if (category != SafeHavenCategory.all) {
          return sorted.where((p) => p.category == category).toList();
        }
        return sorted;
      }
    } catch (e) {
      debugPrint('[SafeHavenService] Overpass live discovery error: $e');
    }

    // Fallback: Use seed places with real calculated distances
    _currentDataSource = 'Verified Safe Haven Network (Offline Mode)';
    return getPlaces(
      category: category,
      userPosition: Position(
        latitude: latitude,
        longitude: longitude,
        timestamp: now,
        accuracy: 10.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      ),
    );
  }

  List<CommunityReport> getCommunityReports() => List.unmodifiable(_reports);

  Future<void> addCommunityReport({
    required String title,
    required String locationName,
    required String category,
    String? notes,
    required double latitude,
    required double longitude,
  }) async {
    final userId = SafeHerAuthService().currentUserId ?? 'anon_user';
    final report = CommunityReport(
      id: const Uuid().v4(),
      userId: userId,
      title: title,
      locationName: locationName,
      latitude: latitude,
      longitude: longitude,
      createdAt: DateTime.now(),
      isVerified: false,
      category: category,
      notes: notes,
    );

    _reports.insert(0, report);

    try {
      await _firestore
          .collection('communityReports')
          .doc(report.id)
          .set(report.toMap());
    } catch (e) {
      debugPrint('Firestore community report sync error/offline: $e');
    }
  }

  List<EmergencyServiceEntry> getEmergencyServices() {
    return const [
      EmergencyServiceEntry(
        number: '112',
        title: '112',
        subtitle: 'National Emergency',
        iconCode: 'emergency',
      ),
      EmergencyServiceEntry(
        number: '1091',
        title: '1091',
        subtitle: 'Women Helpline',
        iconCode: 'women',
      ),
      EmergencyServiceEntry(
        number: '100',
        title: '100',
        subtitle: 'Police',
        iconCode: 'police',
      ),
      EmergencyServiceEntry(
        number: '108',
        title: '108',
        subtitle: 'Ambulance',
        iconCode: 'ambulance',
      ),
      EmergencyServiceEntry(
        number: '181',
        title: '181',
        subtitle: 'Women Help Line',
        iconCode: 'help_line',
      ),
    ];
  }

  Future<bool> callEmergencyNumber(String number) async {
    final uri = Uri.parse('tel:$number');
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('Dialer launch error: $e');
    }
    return false;
  }

  Future<bool> openGoogleMapsDirections({
    required double destinationLat,
    required double destinationLng,
    String? destinationLabel,
  }) async {
    final label = Uri.encodeComponent(destinationLabel ?? 'Safe Destination');
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$destinationLat,$destinationLng&destination_place_id=$label',
    );
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Google Maps directions error: $e');
    }
    return false;
  }
}
