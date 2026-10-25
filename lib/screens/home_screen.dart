import 'package:flutter/material.dart';

import '../app/routes.dart';
import '../app/theme.dart';
import '../models/incident.dart';
import '../services/incident_service.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/sos_button.dart';
import 'ai_safety_screen.dart';
import 'incident_history_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  void _onSosTriggered() {
    Navigator.pushNamed(context, AppRoutes.sosActivation);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildHomeContent(),
      const IncidentHistoryScreen(),
      const AiSafetyScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: SafeHerColors.midnightPurple,
      body: pages[_currentNavIndex],
      bottomNavigationBar: SafeHerBottomNavigation(
        currentIndex: _currentNavIndex,
        onTap: (index) {
          setState(() {
            _currentNavIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildHomeContent() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: SafeHerColors.darkBackgroundGradient,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top App Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(
                        Icons.shield_rounded,
                        color: SafeHerColors.primaryRose,
                        size: 26,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'SafeHer',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.notifications_none,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No new notifications'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Greeting
              Text(
                '${_getGreeting()}\nStay Safe!',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 16),

              // Safety Status Card
              StreamBuilder<Incident?>(
                stream: IncidentService().activeIncidentStream,
                initialData: IncidentService().activeIncident,
                builder: (context, snapshot) {
                  final activeIncident = snapshot.data;
                  final isEmergency =
                      activeIncident != null && activeIncident.isActive;

                  return GestureDetector(
                    onTap: () {
                      if (isEmergency) {
                        Navigator.pushNamed(context, AppRoutes.sosSent);
                      } else {
                        Navigator.pushNamed(context, AppRoutes.locationSharing);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: SafeHerColors.plumCard,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isEmergency
                              ? SafeHerColors.primaryRose
                              : SafeHerColors.darkBorder,
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isEmergency
                                  ? SafeHerColors.primaryRose
                                  : SafeHerColors.successGreen,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isEmergency
                                  ? Icons.warning_amber_rounded
                                  : Icons.shield_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEmergency
                                      ? 'Emergency Active'
                                      : 'You are safe',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isEmergency
                                      ? 'Tap to manage active incident'
                                      : 'No active alerts',
                                  style: const TextStyle(
                                    color: Color(0xFF9E8F9B),
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: Color(0xFF9E8F9B),
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Large Central Circular Glowing SOS Button
              Center(child: SafeHerSosButton(onTrigger: _onSosTriggered)),
              const SizedBox(height: 28),

              // 3 Quick Action Cards: Check-in, Contacts, AI Assistant
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      icon: Icons.access_time_rounded,
                      label: 'Check-in',
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.checkin),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickActionCard(
                      icon: Icons.people_outline_rounded,
                      label: 'Contacts',
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.contacts),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickActionCard(
                      icon: Icons.auto_awesome,
                      label: 'AI Assistant',
                      onTap: () {
                        setState(() {
                          _currentNavIndex = 2;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Showcase Section: AI Journey Guardian + Resilience Mode + Safe Haven Network
              const Text(
                'Safety Guardian Suite',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),

              // Feature A Entry Card
              _buildFeatureShowcaseCard(
                icon: Icons.navigation_rounded,
                iconColor: SafeHerColors.primaryRose,
                title: 'AI Journey Guardian',
                subtitle: 'Real-time route tracking & auto check-ins',
                actionText: 'Start Journey',
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.journeyHome),
              ),
              const SizedBox(height: 12),

              // Feature B Entry Card
              _buildFeatureShowcaseCard(
                icon: Icons.cell_tower_rounded,
                iconColor: const Color(0xFF6A3EA1),
                title: 'SOS Resilience Mode',
                subtitle: 'Offline SIM SMS dispatch & hardware check',
                actionText: 'View Status',
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.resilienceHome),
              ),
              const SizedBox(height: 12),

              // Feature C Entry Card
              _buildFeatureShowcaseCard(
                icon: Icons.local_police_rounded,
                iconColor: SafeHerColors.successGreen,
                title: 'Verified Safe Haven Network',
                subtitle: 'Find nearby police stations, hospitals & help points',
                actionText: 'Find Places',
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.safeHavenHome),
              ),
              const SizedBox(height: 20),

              // Live Location Quick Banner
              GestureDetector(
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.locationSharing),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    children: const [
                      Icon(
                        Icons.location_on_outlined,
                        color: SafeHerColors.primaryRose,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'View Live Location & Map Sharing',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white38,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 94,
        decoration: BoxDecoration(
          color: SafeHerColors.plumCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: SafeHerColors.darkBorder, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureShowcaseCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String actionText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SafeHerColors.plumCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: SafeHerColors.darkBorder, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: iconColor.withValues(alpha: 0.4)),
              ),
              child: Icon(icon, color: iconColor, size: 24),
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
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
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
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: SafeHerColors.midnightPurple,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: SafeHerColors.darkBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white70,
                    size: 11,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
