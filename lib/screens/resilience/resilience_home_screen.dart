import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../widgets/shared_widgets.dart';

class ResilienceHomeScreen extends StatelessWidget {
  const ResilienceHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: SafeHerColors.midnightPurple,
      appBar: const SafeHerAppBar(
        title: 'SOS Resilience Mode',
        showBack: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: SafeHerColors.darkBackgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Tagline Subtitle
                const Text(
                  'Works in low network, offline and critical situations',
                  style: TextStyle(
                    color: Color(0xFFB4A3C2),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 16),

                // Cell Tower Illustration Graphic matching Reference
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF471A42),
                        Color(0xFF261233),
                        SafeHerColors.midnightPurple,
                      ],
                    ),
                    border: Border.all(
                      color: SafeHerColors.darkBorder,
                      width: 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Glowing Signal Waves
                      Positioned(
                        top: 20,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Icon(
                            Icons.wifi_tethering_rounded,
                            size: 68,
                            color: SafeHerColors.primaryRose.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                      // Cell Towers / Pylons silhouette
                      Positioned(
                        bottom: 15,
                        left: 25,
                        child: Icon(
                          Icons.cell_tower_rounded,
                          size: 74,
                          color: Colors.white.withValues(alpha: 0.22),
                        ),
                      ),
                      Positioned(
                        bottom: 15,
                        right: 25,
                        child: Icon(
                          Icons.cell_tower_rounded,
                          size: 74,
                          color: Colors.white.withValues(alpha: 0.22),
                        ),
                      ),
                      // Central Shield Icon
                      Center(
                        child: Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: SafeHerColors.plumCard,
                            border: Border.all(
                              color: SafeHerColors.primaryRose,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: SafeHerColors.primaryRose.withValues(alpha: 0.4),
                                blurRadius: 18,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.security_rounded,
                            color: SafeHerColors.primaryRose,
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Main Resilience Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: SafeHerColors.plumCard,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: SafeHerColors.darkBorder, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SOS Resilience Mode',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Stays with you even in low network. Automatically uses SIM SMS, local backup and smart sync.',
                        style: TextStyle(
                          color: Color(0xFFC7B8D6),
                          fontSize: 13.5,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 5 Checkmark Bullets
                      _buildBullet('Works offline or with weak network'),
                      const SizedBox(height: 10),
                      _buildBullet('Auto SMS via SIM'),
                      const SizedBox(height: 10),
                      _buildBullet('Local incident backup'),
                      const SizedBox(height: 10),
                      _buildBullet('Auto sync when online'),
                      const SizedBox(height: 10),
                      _buildBullet('Battery & network alerts'),
                      const SizedBox(height: 22),

                      // Resilience Mode Enabled Pill Action
                      InkWell(
                        borderRadius: BorderRadius.circular(25),
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.deviceStatus);
                        },
                        child: Container(
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          decoration: BoxDecoration(
                            color: SafeHerColors.midnightPurple,
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(
                              color: SafeHerColors.successGreen,
                              width: 1.5,
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                color: SafeHerColors.successGreen,
                                size: 22,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Resilience Mode Enabled',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Spacer(),
                              Icon(
                                Icons.chevron_right,
                                color: Colors.white70,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Diagnostic Quick Action Cards Grid
                const Text(
                  'Resilience Tools',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: _buildToolCard(
                        context,
                        icon: Icons.phonelink_setup_rounded,
                        title: 'Device Status',
                        subtitle: 'Live diagnostic check',
                        route: AppRoutes.deviceStatus,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildToolCard(
                        context,
                        icon: Icons.wifi_off_rounded,
                        title: 'Offline Mode',
                        subtitle: 'Zero connection readiness',
                        route: AppRoutes.offlineMode,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildToolCard(
                        context,
                        icon: Icons.sms_rounded,
                        title: 'Auto SMS (SIM)',
                        subtitle: 'Hardware SMS test',
                        route: AppRoutes.autoSms,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildToolCard(
                        context,
                        icon: Icons.storage_rounded,
                        title: 'Local Backup',
                        subtitle: 'Offline incident store',
                        route: AppRoutes.localBackup,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildToolCard(
                        context,
                        icon: Icons.sync_rounded,
                        title: 'Auto Sync',
                        subtitle: 'Cloud restore engine',
                        route: AppRoutes.autoSync,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildToolCard(
                        context,
                        icon: Icons.battery_alert_rounded,
                        title: 'Battery Alerts',
                        subtitle: 'Power & network alerts',
                        route: AppRoutes.batteryAlerts,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: SafeHerColors.primaryRose.withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(
              Icons.check_rounded,
              color: SafeHerColors.primaryRose,
              size: 14,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToolCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String route,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.pushNamed(context, route),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: SafeHerColors.plumCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SafeHerColors.darkBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: SafeHerColors.primaryRose, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                color: Color(0xFFB4A3C2),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
