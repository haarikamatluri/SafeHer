import 'dart:async';
import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../services/journey_service.dart';
import '../../widgets/shared_widgets.dart';

class CheckinPromptScreen extends StatefulWidget {
  const CheckinPromptScreen({super.key});

  @override
  State<CheckinPromptScreen> createState() => _CheckinPromptScreenState();
}

class _CheckinPromptScreenState extends State<CheckinPromptScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _pulseAnimation;
  Timer? _escalationTimer;
  int _secondsLeft = 45;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.15).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _startAutoEscalationCountdown();
  }

  void _startAutoEscalationCountdown() {
    _escalationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_secondsLeft > 1) {
            _secondsLeft--;
          } else {
            timer.cancel();
            Navigator.pushReplacementNamed(context, AppRoutes.missedCheckin);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _escalationTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _onSafe() async {
    _escalationTimer?.cancel();
    await JourneyService().confirmSafeCheckin();
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.journeyActive);
    }
  }

  Future<void> _onNeedMoreTime() async {
    _escalationTimer?.cancel();
    await JourneyService().extendCheckinTime(extensionMinutes: 15);
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.journeyActive);
    }
  }

  void _onSos() {
    _escalationTimer?.cancel();
    Navigator.pushNamed(context, AppRoutes.sosActivation);
  }

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Pulsing Bell Radar Graphic
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer glow ring
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: SafeHerColors.primaryRose.withValues(alpha: 0.15),
                            ),
                          ),
                          // Middle ring
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: SafeHerColors.primaryRose.withValues(alpha: 0.3),
                            ),
                          ),
                          // Inner circle with Bell
                          Container(
                            width: 80,
                            height: 80,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: SafeHerColors.primaryRose,
                              boxShadow: [
                                BoxShadow(
                                  color: SafeHerColors.primaryRose,
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.notifications_active_rounded,
                              color: Colors.white,
                              size: 42,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 36),

                // Headline
                const Text(
                  'Check-in Time',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),

                // Subtitle
                const Text(
                  'Are you safe?\nPlease confirm to continue\nyour journey.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFC7B8D6),
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Auto-escalating in $_secondsLeft s',
                  style: const TextStyle(
                    color: SafeHerColors.warningAmber,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const Spacer(flex: 3),

                // Button 1: Big Green "I'm Safe"
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SafeHerColors.successGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(27),
                      ),
                      elevation: 6,
                    ),
                    onPressed: _onSafe,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded, size: 22),
                        SizedBox(width: 8),
                        Text(
                          "I'm Safe",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Button 2: Purple "Need More Time (+ 15 minutes)"
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A2F63),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                        side: const BorderSide(
                          color: Color(0xFF7A4FA0),
                          width: 1,
                        ),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _onNeedMoreTime,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.alarm_add_rounded, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Need More Time (+ 15 minutes)',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Button 3: Pink "Send SOS Instead"
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: SafeHerColors.brightPink,
                      side: const BorderSide(
                        color: SafeHerColors.primaryRose,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    onPressed: _onSos,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Send SOS Instead',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
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
      ),
    );
  }
}
