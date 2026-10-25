import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../app/theme.dart';
import '../models/safe_haven.dart';

/// Real geographic interactive map widget using FlutterMap and OpenStreetMap/CartoDB Dark tiles.
class RealInteractiveMapView extends StatefulWidget {
  final LatLng initialCenter;
  final double initialZoom;
  final List<LatLng> primaryRoute;
  final List<LatLng>? alternativeRoute;
  final LatLng? userPosition;
  final double? userHeading;
  final double? accuracyMeters;
  final LatLng? origin;
  final LatLng? destination;
  final String? destinationName;
  final List<SafeHavenPlace> safeHavens;
  final void Function(SafeHavenPlace)? onSafeHavenSelected;
  final bool isInteractive;
  final bool isRerouting;
  final bool isOffRoute;
  final String? alertBannerMessage;
  final VoidCallback? onRecenter;

  const RealInteractiveMapView({
    super.key,
    required this.initialCenter,
    this.initialZoom = 14.5,
    this.primaryRoute = const [],
    this.alternativeRoute,
    this.userPosition,
    this.userHeading,
    this.accuracyMeters,
    this.origin,
    this.destination,
    this.destinationName,
    this.safeHavens = const [],
    this.onSafeHavenSelected,
    this.isInteractive = true,
    this.isRerouting = false,
    this.isOffRoute = false,
    this.alertBannerMessage,
    this.onRecenter,
  });

  @override
  State<RealInteractiveMapView> createState() => _RealInteractiveMapViewState();
}

enum SafeHerMapStyle {
  darkCanvas,
  streets,
}

class _RealInteractiveMapViewState extends State<RealInteractiveMapView> {
  late final MapController _mapController;
  bool _tileLoadError = false;
  SafeHerMapStyle _mapStyle = SafeHerMapStyle.darkCanvas;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void didUpdateWidget(covariant RealInteractiveMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-fit route bounds on initial load if route changed
    if (widget.primaryRoute.isNotEmpty &&
        oldWidget.primaryRoute.length != widget.primaryRoute.length) {
      _fitRouteBounds();
    }
  }

  void _fitRouteBounds() {
    if (widget.primaryRoute.isEmpty) return;
    try {
      final bounds = LatLngBounds.fromPoints(widget.primaryRoute);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(48),
        ),
      );
    } catch (e) {
      // Fallback
    }
  }

  void _recenterOnUser() {
    if (widget.userPosition != null) {
      _mapController.move(widget.userPosition!, 16.0);
    } else if (widget.origin != null) {
      _mapController.move(widget.origin!, 15.0);
    } else {
      _fitRouteBounds();
    }
    widget.onRecenter?.call();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialCenter,
              initialZoom: widget.initialZoom,
              minZoom: 4,
              maxZoom: 18.5,
              interactionOptions: InteractionOptions(
                flags: widget.isInteractive ? InteractiveFlag.all : InteractiveFlag.none,
              ),
            ),
            children: [
              // 1. Map Tiles (100% free, zero API key required, zero watermarks)
              if (_mapStyle == SafeHerMapStyle.darkCanvas) ...[
                // Dark Canvas base layer (roads, boundaries, land, water)
                TileLayer(
                  urlTemplate:
                      'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Base/MapServer/tile/{z}/{y}/{x}',
                  userAgentPackageName: 'safeher.app',
                  maxZoom: 18,
                  errorTileCallback: (tile, error, stackTrace) {
                    if (!_tileLoadError && mounted) {
                      setState(() {
                        _tileLoadError = true;
                      });
                    }
                  },
                ),
                // Dark Canvas reference overlay (labels, city names, street tags)
                TileLayer(
                  urlTemplate:
                      'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Reference/MapServer/tile/{z}/{y}/{x}',
                  userAgentPackageName: 'safeher.app',
                  maxZoom: 18,
                ),
              ] else ...[
                // Standard OpenStreetMap street tiles
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'safeher.app',
                  maxZoom: 19,
                  errorTileCallback: (tile, error, stackTrace) {
                    if (!_tileLoadError && mounted) {
                      setState(() {
                        _tileLoadError = true;
                      });
                    }
                  },
                ),
              ],

              // 2. Accuracy halo around user position
              if (widget.userPosition != null && widget.accuracyMeters != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: widget.userPosition!,
                      radius: widget.accuracyMeters!.clamp(15.0, 80.0),
                      useRadiusInMeter: true,
                      color: SafeHerColors.primaryRose.withValues(alpha: 0.15),
                      borderColor: SafeHerColors.primaryRose.withValues(alpha: 0.5),
                      borderStrokeWidth: 1.5,
                    ),
                  ],
                ),

              // 3. Alternative route polyline (if any)
              if (widget.alternativeRoute != null && widget.alternativeRoute!.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: widget.alternativeRoute!,
                      strokeWidth: 3.5,
                      color: const Color(0xFF6B7280).withValues(alpha: 0.7),
                    ),
                  ],
                ),

              // 4. Primary route polyline
              if (widget.primaryRoute.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    // Outer glow
                    Polyline(
                      points: widget.primaryRoute,
                      strokeWidth: 7.0,
                      color: SafeHerColors.primaryRose.withValues(alpha: 0.35),
                    ),
                    // Core hot-pink line
                    Polyline(
                      points: widget.primaryRoute,
                      strokeWidth: 4.5,
                      color: widget.isOffRoute
                          ? const Color(0xFFF59E0B) // Amber if off-route
                          : SafeHerColors.primaryRose,
                    ),
                  ],
                ),

              // 5. Markers Layer: Safe Havens, Origin, Destination, Traveler
              MarkerLayer(
                markers: [
                  // Safe Haven points
                  ...widget.safeHavens.map((haven) {
                    return Marker(
                      point: LatLng(haven.latitude, haven.longitude),
                      width: 32,
                      height: 32,
                      child: GestureDetector(
                        onTap: () => widget.onSafeHavenSelected?.call(haven),
                        child: _buildSafeHavenPin(haven),
                      ),
                    );
                  }),

                  // Origin Pin
                  if (widget.origin != null)
                    Marker(
                      point: widget.origin!,
                      width: 28,
                      height: 28,
                      child: _buildOriginPin(),
                    ),

                  // Destination Pin
                  if (widget.destination != null)
                    Marker(
                      point: widget.destination!,
                      width: 36,
                      height: 44,
                      child: _buildDestinationPin(widget.destinationName),
                    ),

                  // Live User Position / Traveler Avatar
                  if (widget.userPosition != null)
                    Marker(
                      point: widget.userPosition!,
                      width: 44,
                      height: 44,
                      child: _buildTravelerMarker(widget.userHeading),
                    ),
                ],
              ),
            ],
          ),

          // Top Floating Status / Alert Banner
          if (widget.isRerouting || widget.isOffRoute || widget.alertBannerMessage != null)
            Positioned(
              top: 14,
              left: 14,
              right: 14,
              child: _buildAlertBanner(),
            ),

          // Offline / Tile Error warning pill
          if (_tileLoadError)
            Positioned(
              top: 14,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF59E0B), width: 1),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wifi_off_rounded, color: Color(0xFFF59E0B), size: 14),
                    SizedBox(width: 6),
                    Text(
                      'Offline Map Cache',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),

          // Right-side floating map action controls
          if (widget.isInteractive)
            Positioned(
              right: 12,
              bottom: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMapFloatingBtn(
                    icon: _mapStyle == SafeHerMapStyle.darkCanvas
                        ? Icons.map_rounded
                        : Icons.dark_mode_rounded,
                    onTap: () {
                      setState(() {
                        _mapStyle = _mapStyle == SafeHerMapStyle.darkCanvas
                            ? SafeHerMapStyle.streets
                            : SafeHerMapStyle.darkCanvas;
                      });
                    },
                    tooltip: _mapStyle == SafeHerMapStyle.darkCanvas
                        ? 'Switch to Street Map'
                        : 'Switch to Dark Canvas',
                  ),
                  const SizedBox(height: 8),
                  _buildMapFloatingBtn(
                    icon: Icons.my_location_rounded,
                    onTap: _recenterOnUser,
                    tooltip: 'Recenter on me',
                  ),
                  const SizedBox(height: 8),
                  _buildMapFloatingBtn(
                    icon: Icons.add_rounded,
                    onTap: () {
                      _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1.0);
                    },
                    tooltip: 'Zoom in',
                  ),
                  const SizedBox(height: 8),
                  _buildMapFloatingBtn(
                    icon: Icons.remove_rounded,
                    onTap: () {
                      _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1.0);
                    },
                    tooltip: 'Zoom out',
                  ),
                ],
              ),
            ),

          // Bottom-left attribution badge
          Positioned(
            left: 10,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _mapStyle == SafeHerMapStyle.darkCanvas
                    ? '© Esri, HERE, Garmin, © OpenStreetMap'
                    : '© OpenStreetMap contributors',
                style: const TextStyle(color: Color(0xFF9E8F9B), fontSize: 9.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafeHavenPin(SafeHavenPlace haven) {
    Color color = SafeHerColors.primaryRose;
    IconData icon = Icons.shield_rounded;

    switch (haven.category) {
      case SafeHavenCategory.police:
        color = const Color(0xFF3B82F6);
        icon = Icons.local_police_rounded;
        break;
      case SafeHavenCategory.hospital:
        color = const Color(0xFFEF4444);
        icon = Icons.local_hospital_rounded;
        break;
      case SafeHavenCategory.pharmacy:
        color = const Color(0xFF10B981);
        icon = Icons.medication_rounded;
        break;
      case SafeHavenCategory.womenCenter:
        color = const Color(0xFFA855F7);
        icon = Icons.female_rounded;
        break;
      case SafeHavenCategory.verifiedPlace:
      case SafeHavenCategory.all:
        color = SafeHerColors.primaryRose;
        icon = Icons.verified_user_rounded;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }

  Widget _buildOriginPin() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF10B981),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.6),
            blurRadius: 8,
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.circle, color: Colors.white, size: 8),
      ),
    );
  }

  Widget _buildDestinationPin(String? name) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: SafeHerColors.primaryRose,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: SafeHerColors.primaryRose.withValues(alpha: 0.6),
                blurRadius: 10,
              ),
            ],
          ),
          child: const Icon(
            Icons.pin_drop_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
        Container(
          width: 8,
          height: 3,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildTravelerMarker(double? heading) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Direction arrow if heading available
        if (heading != null)
          Transform.rotate(
            angle: heading * (math.pi / 180.0),
            child: const Icon(
              Icons.navigation_rounded,
              color: SafeHerColors.primaryRose,
              size: 40,
            ),
          ),
        // Central user avatar
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: SafeHerColors.primaryRose, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: SafeHerColors.primaryRose.withValues(alpha: 0.7),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.person_rounded,
              color: SafeHerColors.midnightPurple,
              size: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAlertBanner() {
    final isReroute = widget.isRerouting;
    final text = isReroute
        ? 'Recalculating route...'
        : (widget.alertBannerMessage ?? 'Route deviation detected');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isReroute ? const Color(0xFF3B82F6) : const Color(0xFFF59E0B),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          if (isReroute)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          else
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapFloatingBtn({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: SafeHerColors.plumCard.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: SafeHerColors.darkBorder, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 6,
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
