import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:latlong2/latlong.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../models/journey.dart';
import '../../services/journey_service.dart';
import '../../services/safe_haven_service.dart';
import '../../widgets/real_map_view.dart';
import '../../widgets/shared_widgets.dart';

class JourneyActiveScreen extends StatefulWidget {
  const JourneyActiveScreen({super.key});

  @override
  State<JourneyActiveScreen> createState() => _JourneyActiveScreenState();
}

class _JourneyActiveScreenState extends State<JourneyActiveScreen> {
  final JourneyService _journeyService = JourneyService();
  Timer? _liveTicker;
  Duration _timeUntilCheckin = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTicker();
  }

  void _startTicker() {
    _updateRemainingTime();
    _liveTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        _updateRemainingTime();
      }
    });
  }

  void _updateRemainingTime() {
    final journey = _journeyService.activeJourney;
    if (journey != null && journey.nextCheckinDueAt != null) {
      final diff = journey.nextCheckinDueAt!.difference(DateTime.now());
      setState(() {
        _timeUntilCheckin = diff.isNegative ? Duration.zero : diff;
      });

      // If check-in due or missed, open the prompt
      if (journey.status == JourneyStatus.checkinDue) {
        Navigator.pushReplacementNamed(context, AppRoutes.checkinPrompt);
      } else if (journey.status == JourneyStatus.checkinMissed) {
        Navigator.pushReplacementNamed(context, AppRoutes.missedCheckin);
      }
    }
  }

  @override
  void dispose() {
    _liveTicker?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  Future<void> _onSafePressed() async {
    await _journeyService.confirmSafeCheckin();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Check-in confirmed! You are safe.'),
          backgroundColor: SafeHerColors.successGreen,
        ),
      );
    }
  }

  Future<void> _onExtendTimePressed() async {
    await _journeyService.extendCheckinTime(extensionMinutes: 15);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Check-in time extended by 15 minutes.'),
        ),
      );
    }
  }

  void _onSosPressed() {
    Navigator.pushNamed(context, AppRoutes.sosActivation);
  }

  Future<void> _showEndJourneyDialog(Journey journey) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SafeHerColors.midnightPurple,
        title: const Text('End Journey?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Have you reached your destination safely?',
          style: TextStyle(color: Color(0xFFC7B8D6)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continue Journey'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: SafeHerColors.successGreen,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, I Arrived Safe'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      final summary = await _journeyService.completeJourney();
      if (mounted && summary != null) {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.journeySummary,
          arguments: summary.toMap(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Journey?>(
      valueListenable: _journeyService.journeyListenable,
      builder: (context, journey, _) {
        final activeJourney = journey ??
            Journey(
              id: 'temp',
              userId: 'u',
              destinationName: 'Sri Venkateswara University',
              destinationLat: 13.6288,
              destinationLng: 79.4192,
              expectedArrivalTime: DateTime.now().add(const Duration(minutes: 45)),
              startedAt: DateTime.now().subtract(const Duration(minutes: 15)),
              totalDistanceKm: 22.0,
            );

        final etaFormatted =
            DateFormat('hh:mm a').format(activeJourney.expectedArrivalTime);

        return Scaffold(
          backgroundColor: SafeHerColors.midnightPurple,
          appBar: SafeHerAppBar(
            title: 'Journey Active',
            showBack: true,
            trailing: IconButton(
              icon: const Icon(Icons.notifications_active_rounded, color: Colors.white),
              onPressed: () => Navigator.pushNamed(context, AppRoutes.checkinPrompt),
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
                  // Subtitle Information Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'To: ${activeJourney.destinationName}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'ETA: $etaFormatted • ${activeJourney.remainingMinutes ?? activeJourney.expectedArrivalTime.difference(DateTime.now()).inMinutes.clamp(1, 999)} min remaining',
                                style: const TextStyle(
                                  color: Color(0xFFC7B8D6),
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.flag_rounded, color: Colors.white70),
                          tooltip: 'End Journey',
                          onPressed: () => _showEndJourneyDialog(activeJourney),
                        ),
                      ],
                    ),
                  ),

                  // Real Interactive Map Canvas with Live Marker
                  Expanded(
                    flex: 6,
                    child: RealInteractiveMapView(
                      initialCenter: LatLng(
                        activeJourney.lastKnownLat ?? activeJourney.destinationLat,
                        activeJourney.lastKnownLng ?? activeJourney.destinationLng,
                      ),
                      initialZoom: 15.0,
                      primaryRoute: activeJourney.routeLatLngs,
                      userPosition: (activeJourney.lastKnownLat != null && activeJourney.lastKnownLng != null)
                          ? LatLng(activeJourney.lastKnownLat!, activeJourney.lastKnownLng!)
                          : null,
                      destination: LatLng(activeJourney.destinationLat, activeJourney.destinationLng),
                      destinationName: activeJourney.destinationName,
                      safeHavens: SafeHavenService().getPlaces(),
                      isOffRoute: activeJourney.isOffRoute,
                      isRerouting: activeJourney.isRerouting,
                      alertBannerMessage: activeJourney.isOffRoute
                          ? 'Route deviation detected — recalculating...'
                          : null,
                    ),
                  ),

                  // Bottom Metrics & 3 Big Action Buttons
                  Expanded(
                    flex: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      decoration: const BoxDecoration(
                        color: SafeHerColors.plumCard,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(26),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // 3 Metrics cards
                          Row(
                            children: [
                              _buildMetricCard(
                                title: 'Distance',
                                value: '${(activeJourney.remainingDistanceKm != null ? (activeJourney.totalDistanceKm - activeJourney.remainingDistanceKm!).clamp(0.0, activeJourney.totalDistanceKm) : activeJourney.totalDistanceKm * 0.4).toStringAsFixed(1)} km',
                                subtitle: '/ ${activeJourney.totalDistanceKm.toStringAsFixed(1)}km',
                              ),
                              const SizedBox(width: 10),
                              _buildMetricCard(
                                title: 'GPS Status',
                                value: activeJourney.isOffRoute ? 'Off-Route' : 'On-Route',
                                subtitle: activeJourney.routeSource != null ? 'Road Matched' : 'Live Fix',
                              ),
                              const SizedBox(width: 10),
                              _buildMetricCard(
                                title: 'Next Check-in',
                                value: _formatDuration(_timeUntilCheckin),
                                isCountdown: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // 3 Big Action Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              // 1. I'm Safe (Green)
                              _buildCircleAction(
                                label: "I'm Safe",
                                color: SafeHerColors.successGreen,
                                icon: Icons.check_rounded,
                                onTap: _onSafePressed,
                              ),
                              // 2. Extend Time (Purple)
                              _buildCircleAction(
                                label: 'Extend Time',
                                color: const Color(0xFF6A3EA1),
                                icon: Icons.access_time_filled_rounded,
                                onTap: _onExtendTimePressed,
                              ),
                              // 3. SOS (Hot Pink/Red)
                              _buildCircleAction(
                                label: 'SOS',
                                color: SafeHerColors.primaryRose,
                                icon: Icons.warning_rounded,
                                isSos: true,
                                onTap: _onSosPressed,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    String? subtitle,
    bool isCountdown = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: SafeHerColors.midnightPurple,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SafeHerColors.darkBorder),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFFB4A3C2),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: isCountdown ? SafeHerColors.brightPink : Colors.white,
                    fontSize: isCountdown ? 13 : 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(width: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFFB4A3C2),
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleAction({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
    bool isSos = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: isSos
                  ? const Text(
                      'SOS',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    )
                  : Icon(icon, color: Colors.white, size: 28),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
