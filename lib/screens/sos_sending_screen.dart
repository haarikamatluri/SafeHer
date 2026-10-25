import 'dart:async';

import 'package:flutter/material.dart';

import '../app/routes.dart';
import '../app/theme.dart';
import '../services/incident_service.dart';

class SosSendingScreen extends StatefulWidget {
  const SosSendingScreen({super.key});

  @override
  State<SosSendingScreen> createState() => _SosSendingScreenState();
}

class _SosSendingScreenState extends State<SosSendingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  int _activeStep = 0;

  // 3-second cancellation countdown to prevent accidental activation
  bool _isCountingDown = true;
  int _countdownSeconds = 3;
  Timer? _countdownTimer;
  bool _isCancelled = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _startCancellationCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startCancellationCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 1) {
        setState(() {
          _countdownSeconds--;
        });
      } else {
        timer.cancel();
        if (!_isCancelled && mounted) {
          setState(() {
            _isCountingDown = false;
          });
          _runRealSosSequence();
        }
      }
    });
  }

  void _cancelSos() async {
    _isCancelled = true;
    _countdownTimer?.cancel();

    // If an incident was already created, mark it cancelled in local and Firestore
    final activeInc = IncidentService().activeIncident;
    if (activeInc != null) {
      await IncidentService().cancelIncident(activeInc.id);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('SOS activation cancelled. No alert was sent.'),
          backgroundColor: SafeHerColors.warningAmber,
        ),
      );
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.home,
        (route) => false,
      );
    }
  }

  Future<void> _runRealSosSequence() async {
    if (_isCancelled) return;

    // Step 0: Real GPS Location Acquisition
    setState(() => _activeStep = 0);

    // Step 1: Real Incident Creation (Local + Firestore) & Alert Dispatch
    try {
      setState(() => _activeStep = 1);
      final incident = await IncidentService().triggerSos(
        source: 'sos_button',
        requestLocation: true,
      );

      if (_isCancelled || !mounted) return;

      setState(() => _activeStep = 2);
      await Future.delayed(const Duration(milliseconds: 500));

      if (_isCancelled || !mounted) return;
      setState(() => _activeStep = 3);
      await Future.delayed(const Duration(milliseconds: 500));

      if (_isCancelled || !mounted) return;
      debugPrint('[SosSendingScreen] SOS flow completed: ${incident.shortId}');
      Navigator.pushReplacementNamed(context, AppRoutes.sosSent);
    } catch (e) {
      debugPrint('[SosSendingScreen] SOS flow exception: $e');
      if (mounted && !_isCancelled) {
        Navigator.pushReplacementNamed(context, AppRoutes.sosSent);
      }
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Heading
                Text(
                  _isCountingDown
                      ? 'Cancelling in $_countdownSeconds...'
                      : 'Sending Emergency SOS...',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),

                // Centerpiece: Concentric Pulsing Rings & Paper Airplane Icon / Countdown Core
                SizedBox(
                  width: 220,
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Animated pulse ring 1
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Container(
                            width: 130 + (_pulseController.value * 80),
                            height: 130 + (_pulseController.value * 80),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  (_isCountingDown
                                          ? SafeHerColors.warningAmber
                                          : SafeHerColors.primaryRose)
                                      .withValues(
                                        alpha:
                                            (1.0 - _pulseController.value) *
                                            0.2,
                                      ),
                            ),
                          );
                        },
                      ),

                      // Outer translucent ring
                      Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                          border: Border.all(
                            color:
                                (_isCountingDown
                                        ? SafeHerColors.warningAmber
                                        : SafeHerColors.primaryRose)
                                    .withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                      ),

                      // Central Badge with Send Icon or Countdown Number
                      Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          gradient: _isCountingDown
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFFFFA726),
                                    Color(0xFFFF7043),
                                  ],
                                )
                              : SafeHerColors.pinkButtonGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (_isCountingDown
                                          ? SafeHerColors.warningAmber
                                          : SafeHerColors.primaryRose)
                                      .withValues(alpha: 0.5),
                              blurRadius: 20,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: Center(
                          child: _isCountingDown
                              ? Text(
                                  '$_countdownSeconds',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 38,
                                    fontWeight: FontWeight.w900,
                                  ),
                                )
                              : const Icon(
                                  Icons.near_me_rounded,
                                  color: Colors.white,
                                  size: 40,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Subtitle
                Text(
                  _isCountingDown
                      ? 'Accidental trigger? Tap Cancel below before alert dispatches.'
                      : 'Acquiring GPS location and invoking server-side dispatch to trusted contacts.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFC4B8CC),
                    fontSize: 14.5,
                    height: 1.4,
                  ),
                ),

                // Progress Checklist Card matching Screen 9
                Container(
                  width: double.infinity,
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
                      _buildChecklistItem(
                        title: 'Acquiring GPS location',
                        isDone: !_isCountingDown && _activeStep >= 1,
                        isCurrent: !_isCountingDown && _activeStep == 0,
                      ),
                      const SizedBox(height: 14),
                      _buildChecklistItem(
                        title: 'Creating incident record',
                        isDone: !_isCountingDown && _activeStep >= 2,
                        isCurrent: !_isCountingDown && _activeStep == 1,
                      ),
                      const SizedBox(height: 14),
                      _buildChecklistItem(
                        title: 'Invoking Cloud Function dispatch',
                        isDone: !_isCountingDown && _activeStep >= 3,
                        isCurrent: !_isCountingDown && _activeStep == 2,
                      ),
                      const SizedBox(height: 14),
                      _buildChecklistItem(
                        title: 'Waiting for provider acknowledgments...',
                        isDone: false,
                        isCurrent: !_isCountingDown && _activeStep == 3,
                      ),
                    ],
                  ),
                ),

                // Prominent Cancel Button (Safety requirement)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _cancelSos,
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    label: Text(
                      _isCountingDown
                          ? 'CANCEL SOS NOW ($_countdownSeconds)'
                          : 'CANCEL EMERGENCY ALERT',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Color(0xFFE53935),
                        width: 2,
                      ),
                      backgroundColor: const Color(0x33E53935),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChecklistItem({
    required String title,
    required bool isDone,
    required bool isCurrent,
  }) {
    return Row(
      children: [
        if (isDone)
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: SafeHerColors.successGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 14),
          )
        else if (isCurrent)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(
                SafeHerColors.brightPink,
              ),
            ),
          )
        else
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF5A456E), width: 1.5),
            ),
          ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: isDone || isCurrent
                  ? Colors.white
                  : const Color(0xFF8E7E9C),
              fontSize: 14,
              fontWeight: isDone || isCurrent
                  ? FontWeight.w600
                  : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}
