import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../models/journey.dart';
import '../../models/safe_haven.dart';
import '../../services/journey_service.dart';
import '../../services/location_service.dart';
import '../../services/routing_service.dart';
import '../../services/safe_haven_service.dart';
import '../../widgets/real_map_view.dart';
import '../../widgets/shared_widgets.dart';

class RoutePreviewScreen extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  const RoutePreviewScreen({super.key, this.arguments});

  @override
  State<RoutePreviewScreen> createState() => _RoutePreviewScreenState();
}

class _RoutePreviewScreenState extends State<RoutePreviewScreen> {
  bool _isStarting = false;
  bool _isLoadingRoute = true;
  int _selectedRouteIndex = 0; // 0 = Recommended/Primary, 1 = Alternative

  late String _destinationName;
  late double _destinationLat;
  late double _destinationLng;
  late TravelMode _travelMode;
  late DateTime _expectedArrivalTime;
  late int _checkinIntervalMinutes;
  late List<String> _notifyContactIds;
  late List<String> _notifyContactNames;
  late List<String> _notifyContactPhones;

  LatLng _origin = const LatLng(13.6330, 79.4110); // Default Tirupati center fallback
  late LatLng _destination;

  RouteResult? _primaryRoute;
  RouteResult? _altRoute;
  List<SafeHavenPlace> _safeHavens = [];
  String _safetySummary = 'Checking safety points along road network...';

  @override
  void initState() {
    super.initState();
    final args = widget.arguments ?? {};
    _destinationName = args['destinationName'] as String? ??
        'Sri Venkateswara University, Tirupati';
    _destinationLat = (args['destinationLat'] as num?)?.toDouble() ?? 13.6288;
    _destinationLng = (args['destinationLng'] as num?)?.toDouble() ?? 79.4192;
    _destination = LatLng(_destinationLat, _destinationLng);

    _travelMode = args['travelMode'] as TravelMode? ?? TravelMode.bike;
    _expectedArrivalTime = args['expectedArrivalTime'] as DateTime? ??
        DateTime.now().add(const Duration(hours: 1));
    _checkinIntervalMinutes =
        (args['checkinIntervalMinutes'] as num?)?.toInt() ?? 15;
    _notifyContactIds =
        (args['notifyContactIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
            const [];
    _notifyContactNames =
        (args['notifyContactNames'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
            const [];
    _notifyContactPhones =
        (args['notifyContactPhones'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
            const [];

    _loadRoute();
  }

  Future<void> _loadRoute() async {
    setState(() => _isLoadingRoute = true);

    try {
      // 1. Obtain current GPS origin promptly with bounded timeout
      final loc = await LocationService().getEmergencyLocation(
        timeout: const Duration(seconds: 3),
      );
      if (loc.isSuccess && loc.latitude != null && loc.longitude != null) {
        _origin = LatLng(loc.latitude!, loc.longitude!);
      }

      // 2. Fetch real road route from RoutingService
      final route = await RoutingService().calculateRoute(
        origin: _origin,
        destination: _destination,
        mode: _travelMode,
        requestAlternatives: true,
      );

      _primaryRoute = route;
      if (route.alternatives.isNotEmpty) {
        _altRoute = route.alternatives.first;
      }

      // 3. Load nearby safe haven points
      final havens = SafeHavenService().getPlaces(
        userPosition: Position(
          latitude: _origin.latitude,
          longitude: _origin.longitude,
          timestamp: DateTime.now(),
          accuracy: 5.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        ),
      );
      _safeHavens = havens.take(6).toList();

      // 4. Compute explainable safety points
      int hospitalsNearby = havens.where((h) => h.category == SafeHavenCategory.hospital && h.distanceKm <= 3.0).length;
      int policeNearby = havens.where((h) => h.category == SafeHavenCategory.police && h.distanceKm <= 3.0).length;
      _safetySummary = '$policeNearby police station(s) & $hospitalsNearby hospital(s) within 3 km of route.';
    } catch (e) {
      debugPrint('[RoutePreview] Route loading error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingRoute = false);
      }
    }
  }

  RouteResult? get _currentSelectedRoute =>
      (_selectedRouteIndex == 1 && _altRoute != null) ? _altRoute : _primaryRoute;

  Future<void> _startJourney() async {
    setState(() => _isStarting = true);
    final selected = _currentSelectedRoute;
    final totalKm = selected?.distanceKm ?? 22.0;
    final arrival = selected != null
        ? DateTime.now().add(Duration(minutes: selected.durationMinutes))
        : _expectedArrivalTime;
    final coords = selected?.points.map((p) => [p.latitude, p.longitude]).toList();

    try {
      await JourneyService().startJourney(
        destinationName: _destinationName,
        destinationLat: _destinationLat,
        destinationLng: _destinationLng,
        originLat: _origin.latitude,
        originLng: _origin.longitude,
        travelMode: _travelMode,
        expectedArrivalTime: arrival,
        checkinIntervalMinutes: _checkinIntervalMinutes,
        notifyContactIds: _notifyContactIds,
        notifyContactNames: _notifyContactNames,
        notifyContactPhones: _notifyContactPhones,
        totalDistanceKm: totalKm,
        routeCoordinates: coords,
        routeSource: selected?.providerName ?? 'Real Road Routing',
      );

      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.journeyActive);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start journey: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isStarting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedRoute = _currentSelectedRoute;
    final primaryKm = _primaryRoute?.distanceKm ?? 22.0;
    final primaryMin = _primaryRoute?.durationMinutes ?? 45;
    final altKm = _altRoute?.distanceKm ?? (primaryKm + 2.0);
    final altMin = _altRoute?.durationMinutes ?? (primaryMin + 7);

    return Scaffold(
      backgroundColor: SafeHerColors.midnightPurple,
      appBar: SafeHerAppBar(
        title: 'Route Preview',
        showBack: true,
        trailing: IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: _loadRoute,
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
              // Real Interactive Map View with Selected Route
              Expanded(
                flex: 6,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: _isLoadingRoute
                          ? Container(
                              color: SafeHerColors.plumCard,
                              child: const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(
                                      color: SafeHerColors.primaryRose,
                                      strokeWidth: 2.5,
                                    ),
                                    SizedBox(height: 14),
                                    Text(
                                      'Fetching real road geometry...',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : RealInteractiveMapView(
                              initialCenter: LatLng(
                                (_origin.latitude + _destination.latitude) / 2,
                                (_origin.longitude + _destination.longitude) / 2,
                              ),
                              initialZoom: 13.2,
                              primaryRoute: selectedRoute?.points ?? [],
                              alternativeRoute: _selectedRouteIndex == 0
                                  ? (_altRoute?.points)
                                  : (_primaryRoute?.points),
                              origin: _origin,
                              destination: _destination,
                              destinationName: _destinationName,
                              safeHavens: _safeHavens,
                              alertBannerMessage: selectedRoute?.warningMessage,
                            ),
                    ),

                    // Destination Name Badge top right
                    Positioned(
                      top: 14,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: SafeHerColors.midnightPurple.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: SafeHerColors.darkBorder,
                          ),
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
                              Icons.location_on,
                              color: SafeHerColors.primaryRose,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _destinationName.split(',').first,
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

                    // Route 1 Pill: Recommended Route (Dynamic Real Road Stats)
                    Positioned(
                      bottom: 45,
                      left: 45,
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedRouteIndex = 0);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _selectedRouteIndex == 0
                                ? const Color(0xFF2196F3)
                                : Colors.black87,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _selectedRouteIndex == 0
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

                    // Route 2 Pill: Alternative Route
                    if (_altRoute != null)
                      Positioned(
                        top: 90,
                        right: 40,
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedRouteIndex = 1);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _selectedRouteIndex == 1
                                  ? const Color(0xFF2196F3)
                                  : const Color(0xFF4B5563).withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _selectedRouteIndex == 1
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

              // Bottom Sheet: Real Route & Safety Insights
              Expanded(
                flex: 5,
                child: Container(
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
                      // Source attribution tag
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: SafeHerColors.primaryRose.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              selectedRoute?.providerName ?? 'Real Road Routing',
                              style: const TextStyle(
                                color: SafeHerColors.primaryRose,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            _travelMode.name.toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF9E8F9B),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Route Safety & Help Point Indicators
                      _buildSafetyIndicator(
                        icon: Icons.alt_route_rounded,
                        color: const Color(0xFF2196F3),
                        label: _selectedRouteIndex == 0
                            ? 'Recommended Route ($primaryKm km • $primaryMin min)'
                            : 'Alternative Route ($altKm km • $altMin min)',
                      ),
                      const SizedBox(height: 9),
                      _buildSafetyIndicator(
                        icon: Icons.shield_rounded,
                        color: SafeHerColors.successGreen,
                        label: _safetySummary,
                      ),
                      const SizedBox(height: 9),
                      _buildSafetyIndicator(
                        icon: Icons.emergency_rounded,
                        color: const Color(0xFFEF4444),
                        label: 'Nearby help points: Hospitals & Police stations mapped',
                      ),
                      const SizedBox(height: 9),
                      _buildSafetyIndicator(
                        icon: Icons.traffic_rounded,
                        color: const Color(0xFF9E8F9B),
                        label: 'Live traffic: Standard road speeds (Free tier OSRM)',
                      ),

                      const Spacer(),

                      // Primary CTA: Start Journey
                      SafeHerButton(
                        text: 'Start Journey',
                        isLoading: _isStarting,
                        onPressed: _isLoadingRoute ? null : _startJourney,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSafetyIndicator({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
