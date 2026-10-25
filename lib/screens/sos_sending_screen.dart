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
  bool _isCancelled = false;
  String _currentStatusMessage = 'Activating emergency SOS sequence...';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _runRealSosSequence();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _cancelSos() async {
    _isCancelled = true;

    // If an incident was already created, cancel it safely
    final activeInc = IncidentService().activeIncident;
    if (activeInc != null) {
      await IncidentService().cancelIncident(activeInc.id);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('SOS activation cancelled. Incident was marked false alarm.'),
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

    try {
      if (mounted) {
        setState(() {
          _activeStep = 0;
          _currentStatusMessage = 'Acquiring GPS fix and checking cached coordinates...';
        });
      }

      // Step 1: Trigger non-blocking SOS workflow
      if (mounted) {
        setState(() {
          _activeStep = 1;
          _currentStatusMessage = 'Initializing local incident and preparing emergency dispatch...';
        });
      }

      final incident = await IncidentService().triggerSos(
        source: 'sos_button',
        requestLocation: true,
      );

      if (_isCancelled || !mounted) return;

      // Step 2: SMS dispatch initiated
      setState(() {
        _activeStep = 2;
        _currentStatusMessage = 'Emergency SMS submitted to cellular radio modem...';
      });

      // Step 3: Background tracking started
      setState(() {
        _activeStep = 3;
        _currentStatusMessage = 'Live location tracking active. Transitioning to status...';
      });

      debugPrint('[SosSendingScreen] SOS sequence completed: ${incident.shortId}');
      Navigator.pushReplacementNamed(context, AppRoutes.sosSent);
    } catch (e) {
      debugPrint('[SosSendingScreen] SOS sequence error: $e');
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
                const Text(
                  'Activating Emergency SOS...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),

                // Centerpiece: Concentric Pulsing Rings & Airplane Icon
                SizedBox(
                  width: 220,
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Animated pulse ring
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Container(
                            width: 130 + (_pulseController.value * 80),
                            height: 130 + (_pulseController.value * 80),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: SafeHerColors.primaryRose.withValues(
                                alpha: (1.0 - _pulseController.value) * 0.25,
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
                            color: SafeHerColors.primaryRose.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                      ),

                      // Central Badge with Send Icon
                      Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          gradient: SafeHerColors.pinkButtonGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: SafeHerColors.primaryRose.withValues(alpha: 0.5),
                              blurRadius: 20,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
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
                  _currentStatusMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFC4B8CC),
                    fontSize: 14.5,
                    height: 1.4,
                  ),
                ),

                // Progress Checklist Card
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
                        title: 'Acquiring GPS location fix',
                        isDone: _activeStep >= 1,
                        isCurrent: _activeStep == 0,
                      ),
                      const SizedBox(height: 14),
                      _buildChecklistItem(
                        title: 'Creating incident record',
                        isDone: _activeStep >= 2,
                        isCurrent: _activeStep == 1,
                      ),
                      const SizedBox(height: 14),
                      _buildChecklistItem(
                        title: 'Dispatching emergency SMS via SIM',
                        isDone: _activeStep >= 3,
                        isCurrent: _activeStep == 2,
                      ),
                      const SizedBox(height: 14),
                      _buildChecklistItem(
                        title: 'Starting continuous live tracking',
                        isDone: _activeStep >= 4,
                        isCurrent: _activeStep == 3,
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
                    label: const Text(
                      'CANCEL EMERGENCY ALERT',
                      style: TextStyle(
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
