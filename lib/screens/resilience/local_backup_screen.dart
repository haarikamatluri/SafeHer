import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../models/resilience_status.dart';
import '../../services/resilience_service.dart';
import '../../widgets/shared_widgets.dart';

class LocalBackupScreen extends StatelessWidget {
  const LocalBackupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final resilienceService = ResilienceService();

    return Scaffold(
      backgroundColor: SafeHerColors.midnightPurple,
      appBar: const SafeHerAppBar(
        title: 'Local Backup',
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ValueListenableBuilder<DeviceStatusInfo>(
              valueListenable: resilienceService.statusListenable,
              builder: (context, status, _) {
                return Column(
                  children: [
                    const Spacer(flex: 1),

                    // Database / Storage Icon Badge
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: SafeHerColors.primaryRose.withValues(alpha: 0.15),
                        border: Border.all(
                          color: SafeHerColors.primaryRose.withValues(alpha: 0.4),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: SafeHerColors.primaryRose.withValues(alpha: 0.3),
                            blurRadius: 24,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.dns_rounded,
                          color: SafeHerColors.primaryRose,
                          size: 46,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Headline & Description
                    const Text(
                      'Local Storage Backup',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Incidents are saved locally when offline\nand synced automatically when online.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFC7B8D6),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Backup Metrics Card
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        color: SafeHerColors.plumCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: SafeHerColors.darkBorder),
                      ),
                      child: Column(
                        children: [
                          _buildBackupRow(
                            icon: Icons.sync_problem_rounded,
                            label: 'Pending sync',
                            value: '${status.pendingSyncCount} Incidents',
                            highlightColor: status.pendingSyncCount > 0
                                ? SafeHerColors.brightPink
                                : Colors.white,
                          ),
                          const Divider(
                            color: SafeHerColors.darkBorder,
                            height: 26,
                          ),
                          _buildBackupRow(
                            icon: Icons.history_rounded,
                            label: 'Last backup',
                            value: '5 minutes ago',
                          ),
                          const Divider(
                            color: SafeHerColors.darkBorder,
                            height: 26,
                          ),
                          _buildBackupRow(
                            icon: Icons.pie_chart_outline_rounded,
                            label: 'Storage used',
                            value:
                                '${status.storageUsedMb} MB / ${status.storageMaxMb.toInt()} MB',
                          ),
                        ],
                      ),
                    ),

                    const Spacer(flex: 2),

                    // View Local Incidents Button
                    SafeHerPrimaryButton(
                      text: 'View Local Incidents',
                      icon: Icons.history_edu_rounded,
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.incidentHistory);
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackupRow({
    required IconData icon,
    required String label,
    required String value,
    Color? highlightColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: SafeHerColors.primaryRose, size: 22),
        const SizedBox(width: 14),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFC7B8D6),
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: highlightColor ?? Colors.white,
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
