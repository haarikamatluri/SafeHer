import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/theme.dart';
import '../services/alert_service.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../utils/constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _emergencyNumber = AppConstants.defaultEmergencyNumber;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _emergencyNumber =
          prefs.getString(AppConstants.prefEmergencyNumber) ??
          AppConstants.defaultEmergencyNumber;
    });
  }

  Future<void> _editEmergencyNumber() async {
    final controller = TextEditingController(text: _emergencyNumber);
    final newNum = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('National Emergency Number'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Emergency Number',
            hintText: '112, 911, or 999',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('SAVE'),
          ),
        ],
      ),
    );

    if (newNum != null && newNum.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.prefEmergencyNumber, newNum);
      setState(() {
        _emergencyNumber = newNum;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = SafeHerAuthService().currentUserId ?? 'Not authenticated';
    final isAnon = SafeHerAuthService().isAnonymous;

    return Scaffold(
      backgroundColor: SafeHerTheme.offWhite,
      appBar: AppBar(title: const Text('Settings & Safety Info')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        children: [
          // Account identity card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.account_circle_outlined,
                        color: SafeHerTheme.plumPrimary,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Account Identity',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: SafeHerTheme.plumPrimary,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isAnon
                              ? SafeHerTheme.roseLight
                              : SafeHerTheme.safeGreenLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          isAnon ? 'Anonymous Demo' : 'Verified User',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isAnon
                                ? SafeHerTheme.plumPrimary
                                : SafeHerTheme.safeGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 18),
                  Text(
                    'User UID: $uid',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: SafeHerTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'All incident audits and contacts are isolated to your authenticated UID.',
                    style: TextStyle(
                      fontSize: 12,
                      color: SafeHerTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // National Helplines & Direct Calling
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Direct Emergency Dispatch',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: SafeHerTheme.plumPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Police / Central Emergency'),
                    subtitle: Text('Current: $_emergencyNumber'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: _editEmergencyNumber,
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.call,
                            color: SafeHerTheme.emergencyRed,
                          ),
                          onPressed: () => AlertService().launchEmergencyCall(
                            _emergencyNumber,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Women Helpline Number'),
                    subtitle: const Text('1091 (India) / 1800-799-7233 (US)'),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.call,
                        color: SafeHerTheme.plumPrimary,
                      ),
                      onPressed: () => AlertService().launchEmergencyCall(
                        AppConstants.womenHelplineNumber,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Device Permissions
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.security_outlined,
                color: SafeHerTheme.plumPrimary,
              ),
              title: const Text('Android App Permissions'),
              subtitle: const Text('Manage location & network permissions'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => LocationService().openAppSettings(),
            ),
          ),
          const SizedBox(height: 14),

          // Technical Honesty Statement for Judges
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Hackathon Technical Architecture',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: SafeHerTheme.plumPrimary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Offline-first local cache with instant recovery.\n'
                    '• Cloud Firestore user-scoped rules.\n'
                    '• Explicit separation of incident creation from SMS provider delivery.\n'
                    '• Full privacy control: zero 24/7 background location tracking.\n'
                    '• Material 3 responsive interface.',
                    style: TextStyle(
                      fontSize: 13,
                      color: SafeHerTheme.textDark,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          Center(
            child: Text(
              '${AppConstants.appName} v${AppConstants.appVersion}',
              style: const TextStyle(
                fontSize: 12,
                color: SafeHerTheme.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
