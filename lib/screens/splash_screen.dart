import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/routes.dart';
import '../app/theme.dart';
import '../services/auth_service.dart';
import '../services/checkin_service.dart';
import '../services/contact_service.dart';
import '../services/incident_service.dart';
import '../services/push_notification_service.dart';
import '../utils/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  double _loadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();

    _bootstrap();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    // Simulate smooth progress bar while initializing services
    for (int i = 1; i <= 8; i++) {
      await Future.delayed(const Duration(milliseconds: 80));
      if (!mounted) return;
      setState(() {
        _loadProgress = i / 10.0;
      });
    }

    // Initialize core services safely
    try {
      await Future.wait([
        SafeHerAuthService().initialize(),
        ContactService().initialize(),
        IncidentService().initialize(),
        CheckinService().initialize(),
        PushNotificationService().initialize(),
      ]);
    } catch (e) {
      debugPrint('[SplashScreen] Initialization warning: $e');
    }

    if (mounted) {
      setState(() {
        _loadProgress = 1.0;
      });
    }

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final onboardingDone =
        prefs.getBool(AppConstants.prefOnboardingCompleted) ?? false;
    final hasActiveIncident = IncidentService().hasActiveIncident;

    if (!mounted) return;

    if (hasActiveIncident) {
      Navigator.pushReplacementNamed(context, AppRoutes.sosSent);
    } else if (onboardingDone) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: SafeHerColors.darkBackgroundGradient,
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(height: 40),

                // Centerpiece: SafeHer Logo & Branding
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Shield with leaf icon
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            SafeHerColors.brightPink,
                            SafeHerColors.primaryRose,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: SafeHerColors.primaryRose.withValues(
                              alpha: 0.45,
                            ),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.shield_rounded,
                          size: 52,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Title
                    const Text(
                      'SafeHer',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Tagline
                    const Text(
                      'Safer Today,\nStronger Tomorrow',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFC6B9D0),
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),

                // Bottom: Subtle progress indicator & footer note
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 32,
                  ),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _loadProgress,
                          backgroundColor: Colors.white12,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            SafeHerColors.primaryRose,
                          ),
                          minHeight: 3.5,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Your Safety. Our Priority.',
                        style: TextStyle(
                          color: Color(0xFF9F92AA),
                          fontSize: 12,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
