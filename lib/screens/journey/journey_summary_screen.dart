import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../models/journey.dart';
import '../../widgets/shared_widgets.dart';

class JourneySummaryScreen extends StatelessWidget {
  final Map<String, dynamic>? arguments;

  const JourneySummaryScreen({super.key, this.arguments});

  @override
  Widget build(BuildContext context) {
    Journey journey;
    if (arguments != null && arguments!.isNotEmpty) {
      journey = Journey.fromMap(arguments!);
    } else {
      final now = DateTime.now();
      journey = Journey(
        id: 'completed_mock',
        userId: 'u',
        destinationName: 'Sri Venkateswara University',
        destinationLat: 13.6288,
        destinationLng: 79.4192,
        expectedArrivalTime: now,
        startedAt: now.subtract(const Duration(hours: 1, minutes: 42)),
        completedAt: now,
        totalDistanceKm: 22.0,
        checkinsCompleted: 6,
        totalCheckinsExpected: 6,
      );
    }

    final startFormatted = DateFormat('hh:mm a').format(journey.startedAt);
    final finishFormatted = DateFormat('hh:mm a').format(
      journey.completedAt ?? DateTime.now(),
    );

    final duration = (journey.completedAt ?? DateTime.now())
        .difference(journey.startedAt);
    final hours = duration.inHours;
    final mins = duration.inMinutes % 60;
    final durationText = hours > 0 ? '$hours hr $mins min' : '$mins min';

    return Scaffold(
      backgroundColor: SafeHerColors.midnightPurple,
      appBar: const SafeHerAppBar(
        title: '',
        showBack: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: SafeHerColors.darkBackgroundGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            child: Column(
              children: [
                const Spacer(flex: 1),

                // Green Success Checkmark Badge
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: SafeHerColors.successGreen.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: const BoxDecoration(
                        color: SafeHerColors.successGreen,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: SafeHerColors.successGreen,
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Headline
                const Text(
                  'Journey Completed\nSuccessfully!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 28),

                // Metrics List Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                  decoration: BoxDecoration(
                    color: SafeHerColors.plumCard,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: SafeHerColors.darkBorder),
                  ),
                  child: Column(
                    children: [
                      _buildSummaryRow(
                        icon: Icons.location_on_outlined,
                        label: 'Destination',
                        value: journey.destinationName,
                      ),
                      const Divider(color: SafeHerColors.darkBorder, height: 24),
                      _buildSummaryRow(
                        icon: Icons.alt_route_rounded,
                        label: 'Total Distance',
                        value: '${journey.totalDistanceKm} km',
                      ),
                      const Divider(color: SafeHerColors.darkBorder, height: 24),
                      _buildSummaryRow(
                        icon: Icons.timer_outlined,
                        label: 'Total Time',
                        value: durationText,
                      ),
                      const Divider(color: SafeHerColors.darkBorder, height: 24),
                      _buildSummaryRow(
                        icon: Icons.verified_user_outlined,
                        label: 'Check-ins Completed',
                        value:
                            '${journey.checkinsCompleted}/${journey.totalCheckinsExpected}',
                        valueColor: SafeHerColors.successGreen,
                      ),
                      const Divider(color: SafeHerColors.darkBorder, height: 24),
                      _buildSummaryRow(
                        icon: Icons.play_circle_outline_rounded,
                        label: 'Started At',
                        value: startFormatted,
                      ),
                      const Divider(color: SafeHerColors.darkBorder, height: 24),
                      _buildSummaryRow(
                        icon: Icons.flag_outlined,
                        label: 'Completed At',
                        value: finishFormatted,
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // Primary Bottom Action Button
                SafeHerPrimaryButton(
                  text: 'View Journey Summary',
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.home,
                      (route) => false,
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: SafeHerColors.primaryRose, size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFC7B8D6),
            fontSize: 13.5,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
