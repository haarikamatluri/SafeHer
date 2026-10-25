import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../widgets/shared_widgets.dart';

class OfflineModeScreen extends StatelessWidget {
  const OfflineModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SafeHerColors.midnightPurple,
      appBar: const SafeHerAppBar(
        title: 'Offline Mode',
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
            child: Column(
              children: [
                const Spacer(flex: 1),

                // Wi-Fi Disconnected / Offline Badge
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
                      Icons.wifi_off_rounded,
                      color: SafeHerColors.primaryRose,
                      size: 46,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Headline & Subtitle
                const Text(
                  'No Internet Connection',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'You are still protected!',
                  style: TextStyle(
                    color: SafeHerColors.successGreen,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 32),

                // Protection Highlights Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: SafeHerColors.plumCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: SafeHerColors.darkBorder),
                  ),
                  child: Column(
                    children: [
                      _buildCheckItem('GPS tracking continues'),
                      const SizedBox(height: 14),
                      _buildCheckItem('SOS SMS will be sent via SIM'),
                      const SizedBox(height: 14),
                      _buildCheckItem('Incidents saved locally'),
                      const SizedBox(height: 14),
                      _buildCheckItem('Will sync when online'),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // Button 1: Hot Pink "Go to SOS"
                SafeHerPrimaryButton(
                  text: 'Go to SOS',
                  icon: Icons.warning_rounded,
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.sosActivation);
                  },
                ),
                const SizedBox(height: 14),

                // Button 2: Deep Plum Outline "View Offline Data"
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(
                        color: SafeHerColors.darkBorder,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.localBackup);
                    },
                    child: const Text(
                      'View Offline Data',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckItem(String text) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: SafeHerColors.successGreen.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(
              Icons.check_rounded,
              color: SafeHerColors.successGreen,
              size: 15,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
