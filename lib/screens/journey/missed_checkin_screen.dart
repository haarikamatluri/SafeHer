import 'dart:async';
import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../services/journey_service.dart';
import '../../widgets/shared_widgets.dart';

class MissedCheckinScreen extends StatefulWidget {
  const MissedCheckinScreen({super.key});

  @override
  State<MissedCheckinScreen> createState() => _MissedCheckinScreenState();
}

class _MissedCheckinScreenState extends State<MissedCheckinScreen> {
  final JourneyService _journeyService = JourneyService();
  Timer? _countdownTimer;
  int _secondsLeft = 298; // 04:58 default
  bool _isEscalating = false;

  @override
  void initState() {
    super.initState();
    _startGraceCountdown();
  }

  void _startGraceCountdown() {
    final journey = _journeyService.activeJourney;
    if (journey != null && journey.missedCheckinAt != null) {
      final elapsed = DateTime.now().difference(journey.missedCheckinAt!).inSeconds;
      final graceSeconds = journey.gracePeriodMinutes * 60;
      final remaining = (graceSeconds - elapsed).clamp(0, graceSeconds);
      _secondsLeft = remaining;
    }

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_secondsLeft > 1) {
            _secondsLeft--;
          } else {
            _secondsLeft = 0;
            timer.cancel();
            _escalate();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatTimer(int totalSecs) {
    final mins = (totalSecs ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSecs % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  Future<void> _onSafeNow() async {
    _countdownTimer?.cancel();
    await _journeyService.confirmSafeCheckin();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escalation cancelled. You are safe!'),
          backgroundColor: SafeHerColors.successGreen,
        ),
      );
      Navigator.pushReplacementNamed(context, AppRoutes.journeyActive);
    }
  }

  Future<void> _escalate() async {
    if (_isEscalating) return;
    setState(() => _isEscalating = true);
    _countdownTimer?.cancel();

    await _journeyService.escalateMissedCheckin();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Emergency SMS alerts dispatched to trusted contacts.'),
          backgroundColor: SafeHerColors.emergencyRed,
        ),
      );
      Navigator.pushReplacementNamed(context, AppRoutes.sosSent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final journey = _journeyService.activeJourney;
    final contactCount = journey?.notifyContactPhones.length ?? 3;

    return Scaffold(
      backgroundColor: SafeHerColors.midnightPurple,
      appBar: const SafeHerAppBar(
        title: 'Missed Check-in',
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
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            child: Column(
              children: [
                const Spacer(flex: 1),

                // Exclamation / Warning Badge
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: SafeHerColors.emergencyRed.withValues(alpha: 0.15),
                    border: Border.all(
                      color: SafeHerColors.emergencyRed.withValues(alpha: 0.6),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: SafeHerColors.emergencyRed.withValues(alpha: 0.35),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.priority_high_rounded,
                      color: SafeHerColors.emergencyRed,
                      size: 46,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Headline
                const Text(
                  'Missed Check-in',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),

                // Subtitle
                const Text(
                  'We haven\'t received your check-in.\nYour trusted contacts will be notified in:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFC7B8D6),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),

                // Big Glowing Timer
                Text(
                  _formatTimer(_secondsLeft),
                  style: const TextStyle(
                    color: SafeHerColors.brightPink,
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const Text(
                  'Grace period remaining',
                  style: TextStyle(
                    color: Color(0xFF9E8F9B),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 28),

                // Detail Information Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: SafeHerColors.plumCard,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: SafeHerColors.darkBorder),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow(
                        icon: Icons.location_on_outlined,
                        title: 'Last known location',
                        subtitle: 'Tirupati, AP (5 minutes ago)',
                      ),
                      const Divider(color: SafeHerColors.darkBorder, height: 22),
                      _buildDetailRow(
                        icon: Icons.access_time_rounded,
                        title: 'Expected arrival time',
                        subtitle: '08:30 PM',
                      ),
                      const Divider(color: SafeHerColors.darkBorder, height: 22),
                      _buildDetailRow(
                        icon: Icons.people_outline_rounded,
                        title: 'Authorized escalation',
                        subtitle: 'We will notify $contactCount contacts via SIM SMS',
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // Button 1: Green "I'm Safe Now"
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SafeHerColors.successGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    onPressed: _onSafeNow,
                    child: const Text(
                      "I'm Safe Now",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Button 2: Red "Notify Contacts Now"
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SafeHerColors.primaryRose,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    onPressed: _isEscalating ? null : _escalate,
                    child: _isEscalating
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Notify Contacts Now',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
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

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Icon(icon, color: SafeHerColors.primaryRose, size: 20),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF9E8F9B),
                  fontSize: 11.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
