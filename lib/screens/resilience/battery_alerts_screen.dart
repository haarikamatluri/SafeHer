import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../models/resilience_status.dart';
import '../../services/resilience_service.dart';
import '../../widgets/shared_widgets.dart';

class BatteryAlertsScreen extends StatelessWidget {
  const BatteryAlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final resilienceService = ResilienceService();

    return Scaffold(
      backgroundColor: SafeHerColors.midnightPurple,
      appBar: const SafeHerAppBar(
        title: 'Battery & Network Alerts',
        showBack: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: SafeHerColors.darkBackgroundGradient,
        ),
        child: SafeArea(
          child: ValueListenableBuilder<AlertSettings>(
            valueListenable: resilienceService.alertSettingsListenable,
            builder: (context, settings, _) {
              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                children: [
                  const Text(
                    'Configure Proactive System & Resilience Notifications',
                    style: TextStyle(
                      color: Color(0xFFB4A3C2),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildSwitchTile(
                    icon: Icons.battery_alert_rounded,
                    title: 'Low Battery Alert',
                    subtitle: 'Notify when battery < 20%',
                    value: settings.lowBatteryAlert,
                    onChanged: (val) {
                      resilienceService.updateAlertSettings(
                        settings.copyWith(lowBatteryAlert: val),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  _buildSwitchTile(
                    icon: Icons.signal_wifi_bad_rounded,
                    title: 'Network Lost Alert',
                    subtitle: 'Notify on no internet',
                    value: settings.networkLostAlert,
                    onChanged: (val) {
                      resilienceService.updateAlertSettings(
                        settings.copyWith(networkLostAlert: val),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  _buildSwitchTile(
                    icon: Icons.location_disabled_rounded,
                    title: 'GPS Signal Lost Alert',
                    subtitle: 'Notify if no location for 5 min',
                    value: settings.gpsSignalLostAlert,
                    onChanged: (val) {
                      resilienceService.updateAlertSettings(
                        settings.copyWith(gpsSignalLostAlert: val),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  _buildSwitchTile(
                    icon: Icons.pause_circle_outline_rounded,
                    title: 'Tracking Stopped Alert',
                    subtitle: 'Notify if live tracking stops',
                    value: settings.trackingStoppedAlert,
                    onChanged: (val) {
                      resilienceService.updateAlertSettings(
                        settings.copyWith(trackingStoppedAlert: val),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  _buildSwitchTile(
                    icon: Icons.warning_amber_rounded,
                    title: 'App Killed Alert',
                    subtitle: 'Remind to keep app active',
                    value: settings.appKilledAlert,
                    onChanged: (val) {
                      resilienceService.updateAlertSettings(
                        settings.copyWith(appKilledAlert: val),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  _buildSwitchTile(
                    icon: Icons.notifications_active_rounded,
                    title: 'Show Notifications',
                    subtitle: 'Show system notifications',
                    value: settings.showNotifications,
                    onChanged: (val) {
                      resilienceService.updateAlertSettings(
                        settings.copyWith(showNotifications: val),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: SafeHerColors.plumCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SafeHerColors.darkBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: SafeHerColors.primaryRose.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: SafeHerColors.primaryRose, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFFB4A3C2),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: SafeHerColors.primaryRose,
            activeTrackColor: SafeHerColors.primaryRose.withValues(alpha: 0.35),
            inactiveThumbColor: const Color(0xFF8E7E9C),
            inactiveTrackColor: SafeHerColors.midnightPurple,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
