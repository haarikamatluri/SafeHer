import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../app/theme.dart';
import '../../models/journey.dart';
import '../../models/safe_haven.dart';
import '../../services/routing_service.dart';
import '../../services/safe_haven_service.dart';
import '../../widgets/real_map_view.dart';
import '../../widgets/shared_widgets.dart';

class RouteToSafePlaceScreen extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  const RouteToSafePlaceScreen({super.key, this.arguments});

  @override
  State<RouteToSafePlaceScreen> createState() => _RouteToSafePlaceScreenState();
}

class _RouteToSafePlaceScreenState extends State<RouteToSafePlaceScreen> {
  final SafeHavenService _safeHavenService = SafeHavenService();
  int _selectedRoute = 0; // 0 = Primary, 1 = Alternative
  late SafeHavenPlace _place;
  bool _isLoading = true;

  LatLng _userPosition = const LatLng(13.6288, 79.4192); // Default fallback
  RouteResult? _primaryRoute;
  RouteResult? _altRoute;

  @override
  void initState() {
    super.initState();
    if (widget.arguments != null && widget.arguments!.isNotEmpty) {
      _place = SafeHavenPlace.fromMap(widget.arguments!);
    } else {
      _place = const SafeHavenPlace(
        id: 'place_hospital_1',
        name: 'Sri Padmavathi Hospital',
        category: SafeHavenCategory.hospital,
        address: 'Tiruchanur Road, Tirupati, AP',
        phone: '+91 87722 33455',
        latitude: 13.6180,
        longitude: 79.4320,
        distanceKm: 2.4,
      );
    }
    _loadRealRoute();
  }

  Future<void> _loadRealRoute() async {
    setState(() => _isLoading = true);

    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.always || perm == LocationPermission.whileInUse) {
        try {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(timeLimit: Duration(seconds: 4)),
          );
          _userPosition = LatLng(pos.latitude, pos.longitude);
        } catch (_) {
          final last = await Geolocator.getLastKnownPosition();
          if (last != null) {
            _userPosition = LatLng(last.latitude, last.longitude);
          }
        }
      }

      final route = await RoutingService().calculateRoute(
        origin: _userPosition,
        destination: LatLng(_place.latitude, _place.longitude),
        mode: TravelMode.car,
        requestAlternatives: true,
      );

      _primaryRoute = route;
      if (route.alternatives.isNotEmpty) {
        _altRoute = route.alternatives.first;
      }
    } catch (e) {
      debugPrint('[RouteToSafePlace] Route calculation error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  RouteResult? get _currentRoute =>
      (_selectedRoute == 1 && _altRoute != null) ? _altRoute : _primaryRoute;

  Future<void> _startNavigation() async {
    await _safeHavenService.openGoogleMapsDirections(
      destinationLat: _place.latitude,
      destinationLng: _place.longitude,
      destinationLabel: _place.name,
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeRoute = _currentRoute;
    final primaryKm = _primaryRoute?.distanceKm ?? _place.distanceKm;
    final primaryMin = _primaryRoute?.durationMinutes ?? ((primaryKm / 30.0) * 60).round().clamp(5, 120);
    final altKm = _altRoute?.distanceKm ?? (primaryKm + 1.3);
    final altMin = _altRoute?.durationMinutes ?? (primaryMin + 6);

    return Scaffold(
      backgroundColor: SafeHerColors.midnightPurple,
      appBar: SafeHerAppBar(
        title: 'Route to Safe Place',
        showBack: true,
        trailing: IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: _loadRealRoute,
          tooltip: 'Recalculate route',
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: SafeHerColors.darkBackgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Real Interactive Map View with Route to Safe Haven
              Expanded(
                flex: 6,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: _isLoading
                          ? Container(
                              color: SafeHerColors.plumCard,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: SafeHerColors.primaryRose,
                                  strokeWidth: 2.5,
                                ),
                              ),
                            )
                          : RealInteractiveMapView(
                              initialCenter: LatLng(
                                (_userPosition.latitude + _place.latitude) / 2,
                                (_userPosition.longitude + _place.longitude) / 2,
                              ),
                              initialZoom: 13.5,
                              primaryRoute: activeRoute?.points ?? [],
                              alternativeRoute: _selectedRoute == 0
                                  ? (_altRoute?.points)
                                  : (_primaryRoute?.points),
                              origin: _userPosition,
                              destination: LatLng(_place.latitude, _place.longitude),
                              destinationName: _place.name,
                              safeHavens: [_place],
                              alertBannerMessage: activeRoute?.warningMessage,
                            ),
                    ),

                    // Destination Marker Label Top Right
                    Positioned(
                      top: 14,
                      right: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: SafeHerColors.midnightPurple.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: SafeHerColors.darkBorder),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.local_hospital_rounded,
                              color: Color(0xFFEF4444),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _place.name.split(' ').take(2).join(' '),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Route 1 Pill: Primary
                    Positioned(
                      bottom: 45,
                      left: 60,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedRoute = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _selectedRoute == 0
                                ? const Color(0xFF2196F3)
                                : Colors.black87,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _selectedRoute == 0
                                  ? Colors.white
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$primaryMin min',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '($primaryKm km)',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Route 2 Pill: Alternative
                    if (_altRoute != null)
                      Positioned(
                        top: 90,
                        right: 40,
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedRoute = 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _selectedRoute == 1
                                  ? const Color(0xFF2196F3)
                                  : const Color(0xFF4B5563).withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _selectedRoute == 1
                                    ? Colors.white
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$altMin min',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  '($altKm km)',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Bottom Destination Details Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: const BoxDecoration(
                  color: SafeHerColors.midnightPurple,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 16,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: SafeHerColors.successGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'To ${_place.name}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_selectedRoute == 0 ? primaryMin : altMin} min (${_selectedRoute == 0 ? primaryKm : altKm} km)',
                      style: const TextStyle(
                        color: SafeHerColors.primaryRose,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Road Source: ${activeRoute?.providerName ?? "OSRM (OpenStreetMap)"}',
                      style: const TextStyle(
                        color: Color(0xFFC7B8D6),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Primary CTA: Start Navigation
                    SafeHerButton(
                      text: 'Start Navigation',
                      onPressed: _startNavigation,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
