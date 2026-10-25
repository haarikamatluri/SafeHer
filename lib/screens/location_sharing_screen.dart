import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../app/theme.dart';
import '../models/incident.dart';
import '../services/alert_service.dart';
import '../services/incident_service.dart';
import '../services/live_tracking_service.dart';
import '../utils/constants.dart';
import '../widgets/shared_widgets.dart';

class LocationSharingScreen extends StatefulWidget {
  final String? incidentId;
  const LocationSharingScreen({super.key, this.incidentId});

  @override
  State<LocationSharingScreen> createState() => _LocationSharingScreenState();
}

class _LocationSharingScreenState extends State<LocationSharingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _radarController;
  StreamSubscription<LiveTrackingState>? _trackingSub;
  StreamSubscription<Incident?>? _incidentSub;

  LiveTrackingState _trackingState = LiveTrackingService().currentState;
  Incident? _activeIncident = IncidentService().activeIncident;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // Listen to live tracking stream
    _trackingSub = LiveTrackingService().stateStream.listen((state) {
      if (mounted) {
        setState(() => _trackingState = state);
      }
    });

    // Listen to active incident changes
    _incidentSub = IncidentService().activeIncidentStream.listen((inc) {
      if (mounted) {
        setState(() => _activeIncident = inc);
      }
    });
  }

  @override
  void dispose() {
    _radarController.dispose();
    _trackingSub?.cancel();
    _incidentSub?.cancel();
    super.dispose();
  }

  Future<void> _shareTrackingLink() async {
    final incidentId =
        widget.incidentId ??
        _activeIncident?.id ??
        _trackingState.incidentId ??
        'active_sos';
    final lat = _trackingState.latitude ?? _activeIncident?.latitude;
    final lng = _trackingState.longitude ?? _activeIncident?.longitude;
    final mapsUrl = lat != null && lng != null
        ? 'https://maps.google.com/?q=$lat,$lng'
        : 'https://maps.google.com';
    final liveWebUrl = 'https://safeher-e5003.web.app/#/track?id=$incidentId';

    final text =
        'SafeHer Live Emergency Tracking:\n'
        'Incident ID: #$incidentId\n'
        'Current Coordinates: $mapsUrl\n'
        'Live Tracking Web: $liveWebUrl\n'
        '(Open SafeHer to view real-time location stream)';

    await Clipboard.setData(ClipboardData(text: text));
    try {
      // ignore: deprecated_member_use
      await Share.share(text, subject: 'SafeHer Live SOS Location');
    } catch (_) {
      AlertService().openMapLink(mapsUrl);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Live tracking link and GPS coordinates copied to clipboard.',
          ),
          backgroundColor: SafeHerColors.primaryRose,
        ),
      );
    }
  }

  Future<void> _handleStopSharing() async {
    final activeId = _activeIncident?.id ?? _trackingState.incidentId;
    if (activeId == null) {
      if (mounted) {
        Navigator.pop(context);
      }
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End Live Sharing?'),
        content: const Text(
          'This will stop tracking your coordinates, remove the persistent notification, '
          'and mark your emergency incident as resolved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Tracking'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: SafeHerColors.emergencyRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Stop Sharing & Mark Safe'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await IncidentService().resolveIncident(activeId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Live location tracking ended. Status marked as safe.',
            ),
            backgroundColor: SafeHerColors.successGreen,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  void _openGoogleMapsNavigation() {
    final lat = _trackingState.latitude ?? _activeIncident?.latitude;
    final lng = _trackingState.longitude ?? _activeIncident?.longitude;
    if (lat != null && lng != null) {
      AlertService().openMapLink('https://maps.google.com/?q=$lat,$lng');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coordinates not yet acquired.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lat = _trackingState.latitude ?? _activeIncident?.latitude ?? 14.4673;
    final lng =
        _trackingState.longitude ?? _activeIncident?.longitude ?? 78.8242;
    final accuracy =
        _trackingState.accuracy ?? _activeIncident?.locationAccuracy ?? 10.0;
    final speed = _trackingState.speed;
    final isTrackingActive =
        _trackingState.isTrackingActive ||
        _activeIncident?.status == IncidentStatus.active;
    final isStale = _trackingState.isStale;
    final breadcrumbs = _trackingState.breadcrumbs;

    final dateFormat = DateFormat('hh:mm:ss a');
    final lastFixStr = _trackingState.lastFixTime != null
        ? dateFormat.format(_trackingState.lastFixTime!.toLocal())
        : 'Just now';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        title: const Text(
          'Live Emergency Tracking',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: SafeHerColors.primaryText,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: SafeHerColors.primaryText,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.share_outlined,
              color: SafeHerColors.primaryRose,
            ),
            tooltip: 'Share Live Location',
            onPressed: _shareTrackingLink,
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Dynamic Map Canvas with Breadcrumb Movement Trail
          Positioned.fill(
            child: CustomPaint(
              painter: _LiveTrackingMapPainter(
                breadcrumbs: breadcrumbs,
                radarProgress: _radarController.value,
                isTrackingActive: isTrackingActive,
                accuracyMeters: accuracy,
              ),
              child: Container(),
            ),
          ),

          // 2. Status Badge Header
          Positioned(
            top: 14,
            left: 16,
            right: 16,
            child: _buildStatusBanner(isTrackingActive, isStale),
          ),

          // 3. Floating Quick Action (Open in Google Maps)
          Positioned(
            right: 16,
            bottom: 300,
            child: FloatingActionButton.extended(
              heroTag: 'nav_btn',
              onPressed: _openGoogleMapsNavigation,
              backgroundColor: Colors.white,
              foregroundColor: SafeHerColors.primaryRose,
              elevation: 4,
              icon: const Icon(Icons.navigation_rounded, size: 20),
              label: const Text(
                'Google Maps',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ),

          // 4. Bottom Telemetry & Controls Dashboard
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Coordinates Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${lat.toStringAsFixed(4)}° N, ${lng.toStringAsFixed(4)}° E',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: SafeHerColors.primaryText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Accuracy: ±${accuracy.toStringAsFixed(1)}m • Last fix: $lastFixStr',
                            style: const TextStyle(
                              fontSize: 12,
                              color: SafeHerColors.secondaryText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isTrackingActive
                              ? SafeHerColors.successGreen.withValues(
                                  alpha: 0.12,
                                )
                              : Colors.grey.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isTrackingActive ? 'FOREGROUND ACTIVE' : 'STOPPED',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: isTrackingActive
                                ? SafeHerColors.successGreen
                                : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Metrics Cards (Speed, Breadcrumbs, Quota Interval)
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricItem(
                          label: 'Movement Speed',
                          value: speed != null && speed > 0.5
                              ? '${(speed * 3.6).toStringAsFixed(1)} km/h'
                              : 'Stationary',
                          icon: Icons.speed_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricItem(
                          label: 'GPS Trail Points',
                          value: '${breadcrumbs.length} recorded',
                          icon: Icons.timeline_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricItem(
                          label: 'Sync Rate',
                          value: '15s / 15m',
                          icon: Icons.sync_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: SafeHerPrimaryButton(
                          text: 'Share Tracking Link',
                          onPressed: _shareTrackingLink,
                        ),
                      ),
                      if (isTrackingActive) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: SafeHerColors.emergencyRed,
                              side: const BorderSide(
                                color: SafeHerColors.emergencyRed,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: _handleStopSharing,
                            child: const Text(
                              'Stop Sharing',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(bool isActive, bool isStale) {
    if (!isActive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(
              Icons.info_outline,
              color: SafeHerColors.secondaryText,
              size: 20,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Live tracking session ended. No location is being transmitted.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: SafeHerColors.secondaryText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (isStale) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFB300)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFF57C00),
              size: 20,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'GPS fix delayed (>45s). Waiting for satellite line of sight or phone movement.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFFE65100),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF81C784)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
        ],
      ),
      child: const Row(
        children: [
          Icon(
            Icons.radio_button_checked,
            color: SafeHerColors.successGreen,
            size: 18,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'LIVE SOS GPS STREAMING • Android Foreground Service Active',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF2E7D32),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: SafeHerColors.softPinkSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SafeHerColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: SafeHerColors.primaryRose),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: SafeHerColors.secondaryText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: SafeHerColors.primaryText,
            ),
          ),
        ],
      ),
    );
  }
}

/// Canvas painter that visualizes live street coordinates, movement breadcrumbs trail, and pulsating beacon
class _LiveTrackingMapPainter extends CustomPainter {
  final List<Map<String, dynamic>> breadcrumbs;
  final double radarProgress;
  final bool isTrackingActive;
  final double accuracyMeters;

  _LiveTrackingMapPainter({
    required this.breadcrumbs,
    required this.radarProgress,
    required this.isTrackingActive,
    required this.accuracyMeters,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Map Surface Background
    final bgPaint = Paint()..color = const Color(0xFFEAEFF4);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. City Grid & Green Spaces
    final parkPaint = Paint()..color = const Color(0xFFDCEADF);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.08,
          size.height * 0.1,
          size.width * 0.38,
          size.height * 0.25,
        ),
        const Radius.circular(16),
      ),
      parkPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.55,
          size.height * 0.35,
          size.width * 0.38,
          size.height * 0.22,
        ),
        const Radius.circular(16),
      ),
      parkPaint,
    );

    // 3. Primary Arteries & Roads
    final roadBorder = Paint()
      ..color = const Color(0xFFCFD8DC)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke;
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 11
      ..style = PaintingStyle.stroke;

    // Road 1: Diagonal
    canvas.drawLine(
      Offset(0, size.height * 0.28),
      Offset(size.width, size.height * 0.55),
      roadBorder,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.28),
      Offset(size.width, size.height * 0.55),
      roadPaint,
    );

    // Road 2: Cross
    canvas.drawLine(
      Offset(size.width * 0.35, 0),
      Offset(size.width * 0.65, size.height),
      roadBorder,
    );
    canvas.drawLine(
      Offset(size.width * 0.35, 0),
      Offset(size.width * 0.65, size.height),
      roadPaint,
    );

    final center = Offset(size.width * 0.5, size.height * 0.42);

    // 4. Draw Movement Breadcrumb Trail
    if (breadcrumbs.length > 1) {
      final trailPaint = Paint()
        ..color = SafeHerColors.primaryRose.withValues(alpha: 0.7)
        ..strokeWidth = 3.5
        ..style = PaintingStyle.stroke;

      final pointPaint = Paint()
        ..color = SafeHerColors.primaryRose
        ..style = PaintingStyle.fill;

      final path = Path();
      for (int i = 0; i < breadcrumbs.length; i++) {
        // Calculate offset relative to center for visualization
        final offsetIndex = i - breadcrumbs.length + 1;
        final pt = Offset(
          center.dx + (offsetIndex * 14.0),
          center.dy + (offsetIndex * 10.0),
        );
        if (i == 0) {
          path.moveTo(pt.dx, pt.dy);
        } else {
          path.lineTo(pt.dx, pt.dy);
        }
        canvas.drawCircle(pt, 3.5, pointPaint);
      }
      canvas.drawPath(path, trailPaint);
    }

    // 5. GPS Accuracy Ring
    final accuracyRadius = (accuracyMeters.clamp(5, 45) * 1.5).toDouble();
    final accuracyPaint = Paint()
      ..color = SafeHerColors.primaryRose.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    final accuracyBorder = Paint()
      ..color = SafeHerColors.primaryRose.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawCircle(center, accuracyRadius, accuracyPaint);
    canvas.drawCircle(center, accuracyRadius, accuracyBorder);

    // 6. Pulsating Radar Beacon (when tracking is active)
    if (isTrackingActive) {
      final pulseRadius = accuracyRadius + (radarProgress * 55.0);
      final pulsePaint = Paint()
        ..color = SafeHerColors.primaryRose.withValues(
          alpha: (1.0 - radarProgress) * 0.35,
        )
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, pulseRadius, pulsePaint);
    }

    // 7. Center Location Pin Marker
    final pinBorder = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final pinCore = Paint()
      ..color = SafeHerColors.primaryRose
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 12, pinBorder);
    canvas.drawCircle(center, 9, pinCore);

    // Core white dot
    final whiteDot = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 3.5, whiteDot);
  }

  @override
  bool shouldRepaint(covariant _LiveTrackingMapPainter oldDelegate) {
    return oldDelegate.radarProgress != radarProgress ||
        oldDelegate.breadcrumbs.length != breadcrumbs.length ||
        oldDelegate.isTrackingActive != isTrackingActive;
  }
}
