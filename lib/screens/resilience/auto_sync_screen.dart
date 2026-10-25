import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../models/resilience_status.dart';
import '../../services/resilience_service.dart';
import '../../widgets/shared_widgets.dart';

class AutoSyncScreen extends StatefulWidget {
  const AutoSyncScreen({super.key});

  @override
  State<AutoSyncScreen> createState() => _AutoSyncScreenState();
}

class _AutoSyncScreenState extends State<AutoSyncScreen> {
  final ResilienceService _resilienceService = ResilienceService();
  bool _isSyncing = false;

  Future<void> _onSyncNow() async {
    setState(() => _isSyncing = true);
    final count = await _resilienceService.syncNow();
    if (mounted) {
      setState(() => _isSyncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            count > 0
                ? 'Successfully synced $count pending records to cloud.'
                : 'All offline records are already synchronized.',
          ),
          backgroundColor: SafeHerColors.successGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SafeHerColors.midnightPurple,
      appBar: const SafeHerAppBar(
        title: 'Auto Sync',
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
              valueListenable: _resilienceService.statusListenable,
              builder: (context, status, _) {
                return Column(
                  children: [
                    const Spacer(flex: 1),

                    // Cloud Sync Icon Badge
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
                          Icons.sync_rounded,
                          color: SafeHerColors.primaryRose,
                          size: 48,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Headline & Description
                    const Text(
                      'Smart Cloud Sync',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Automatically syncs your data\nwhen internet is available.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFC7B8D6),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Sync Status Details Card
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
                          _buildSyncRow(
                            icon: Icons.check_circle_outline_rounded,
                            label: 'Auto sync',
                            value: 'Enabled',
                            valueColor: SafeHerColors.successGreen,
                          ),
                          const Divider(
                            color: SafeHerColors.darkBorder,
                            height: 26,
                          ),
                          _buildSyncRow(
                            icon: Icons.access_time_rounded,
                            label: 'Last sync',
                            value: '5 minutes ago',
                          ),
                          const Divider(
                            color: SafeHerColors.darkBorder,
                            height: 26,
                          ),
                          _buildSyncRow(
                            icon: Icons.cloud_queue_rounded,
                            label: 'Pending items',
                            value: '${status.pendingSyncCount}',
                            valueColor: status.pendingSyncCount > 0
                                ? SafeHerColors.brightPink
                                : Colors.white,
                          ),
                        ],
                      ),
                    ),

                    const Spacer(flex: 2),

                    // Sync Now Bottom Button
                    SafeHerPrimaryButton(
                      text: 'Sync Now',
                      icon: Icons.sync_rounded,
                      isLoading: _isSyncing,
                      onPressed: _onSyncNow,
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

  Widget _buildSyncRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
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
            color: valueColor ?? Colors.white,
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
