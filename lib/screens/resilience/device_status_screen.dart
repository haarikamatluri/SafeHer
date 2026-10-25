import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../models/resilience_status.dart';
import '../../services/resilience_service.dart';
import '../../widgets/shared_widgets.dart';

class DeviceStatusScreen extends StatefulWidget {
  const DeviceStatusScreen({super.key});

  @override
  State<DeviceStatusScreen> createState() => _DeviceStatusScreenState();
}

class _DeviceStatusScreenState extends State<DeviceStatusScreen> {
  final ResilienceService _resilienceService = ResilienceService();
  bool _isRefreshing = false;

  Future<void> _refresh() async {
    setState(() => _isRefreshing = true);
    await _resilienceService.refreshDeviceStatus();
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SafeHerColors.midnightPurple,
      appBar: SafeHerAppBar(
        title: 'Device Status',
        showBack: true,
        trailing: IconButton(
          icon: _isRefreshing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: _isRefreshing ? null : _refresh,
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: SafeHerColors.darkBackgroundGradient,
        ),
        child: SafeArea(
          child: ValueListenableBuilder<DeviceStatusInfo>(
            valueListenable: _resilienceService.statusListenable,
            builder: (context, status, _) {
              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                children: [
                  const Text(
                    'Real-time Hardware & Network Diagnostics',
                    style: TextStyle(
                      color: Color(0xFFB4A3C2),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 1. Location (GPS)
                  _buildDiagnosticCard(
                    icon: Icons.location_on_rounded,
                    title: 'Location (GPS)',
                    statusText: status.gpsActive ? 'Active' : 'Unavailable',
                    subtext: status.gpsAccuracy,
                    isReady: status.gpsActive,
                  ),
                  const SizedBox(height: 12),

                  // 2. Mobile Network (SIM)
                  _buildDiagnosticCard(
                    icon: Icons.signal_cellular_alt_rounded,
                    title: 'Mobile Network (SIM)',
                    statusText: status.simDetected ? 'Jio 4G' : 'No SIM',
                    subtext: status.mobileNetwork,
                    isReady: status.simDetected,
                  ),
                  const SizedBox(height: 12),

                  // 3. Internet
                  _buildDiagnosticCard(
                    icon: Icons.wifi_rounded,
                    title: 'Internet',
                    statusText: status.internetConnected ? 'Connected' : 'Offline',
                    subtext: status.internetType,
                    isReady: status.internetConnected,
                  ),
                  const SizedBox(height: 12),

                  // 4. Battery
                  _buildDiagnosticCard(
                    icon: Icons.battery_charging_full_rounded,
                    title: 'Battery',
                    statusText: '${status.batteryLevel}%',
                    subtext: status.batteryStatus,
                    isReady: status.batteryLevel >= 20,
                  ),
                  const SizedBox(height: 12),

                  // 5. SIM Status
                  _buildDiagnosticCard(
                    icon: Icons.sim_card_rounded,
                    title: 'SIM Status',
                    statusText: status.smsPermissionGranted ? 'Available' : 'Permission Required',
                    subtext: status.smsPermissionGranted
                        ? 'Ready for SMS dispatch'
                        : 'Tap to grant SEND_SMS permission',
                    isReady: status.smsPermissionGranted,
                  ),
                  const SizedBox(height: 24),

                  // Re-run Diagnostics Button
                  SafeHerPrimaryButton(
                    text: 'Refresh Device Status',
                    icon: Icons.refresh_rounded,
                    isLoading: _isRefreshing,
                    onPressed: _refresh,
                  ),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDiagnosticCard({
    required IconData icon,
    required String title,
    required String statusText,
    required String subtext,
    required bool isReady,
  }) {
    final statusColor =
        isReady ? SafeHerColors.successGreen : SafeHerColors.warningAmber;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SafeHerColors.plumCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SafeHerColors.darkBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: statusColor, size: 22),
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
                Row(
                  children: [
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '• $subtext',
                      style: const TextStyle(
                        color: Color(0xFFB4A3C2),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isReady ? Icons.check : Icons.priority_high,
              color: statusColor,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
}
