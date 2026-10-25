import 'dart:async';

import 'package:flutter/material.dart';

import '../app/routes.dart';
import '../app/theme.dart';

class SosActivationScreen extends StatefulWidget {
  const SosActivationScreen({super.key});

  @override
  State<SosActivationScreen> createState() => _SosActivationScreenState();
}

class _SosActivationScreenState extends State<SosActivationScreen> {
  Timer? _countdownTimer;
  double _remainingSeconds = 1.0;
  bool _isHolding = false;
  bool _isTriggered = false;

  void _startHolding() {
    if (_isTriggered) return;
    setState(() {
      _isHolding = true;
      _remainingSeconds = 1.0;
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!_isHolding) {
        timer.cancel();
        return;
      }

      setState(() {
        _remainingSeconds -= 0.05;
      });

      if (_remainingSeconds <= 0.0) {
        timer.cancel();
        _remainingSeconds = 0.0;
        _isTriggered = true;
        _activateSos();
      }
    });
  }

  void _stopHolding() {
    if (_isTriggered) return;
    _countdownTimer?.cancel();
    setState(() {
      _isHolding = false;
      _remainingSeconds = 1.0;
    });
  }

  void _activateSos() {
    // Navigate to Screen 9 (SOS Sending) which coordinates real GPS, Incident, and Alert creation
    Navigator.pushReplacementNamed(context, AppRoutes.sosSending);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progressFraction = 1.0 - (_remainingSeconds / 1.0).clamp(0.0, 1.0);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: SafeHerColors.darkBackgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: 30),

              // Title Header matching Screen 8
              const Text(
                'Hold to activate SOS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),

              // Central Countdown Ring & Hold Button
              GestureDetector(
                onTapDown: (_) => _startHolding(),
                onTapUp: (_) => _stopHolding(),
                onTapCancel: () => _stopHolding(),
                child: SizedBox(
                  width: 220,
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background circular track
                      Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.04),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 2,
                          ),
                        ),
                      ),

                      // Animated Circular Progress Ring
                      SizedBox(
                        width: 216,
                        height: 216,
                        child: CircularProgressIndicator(
                          value: _isHolding ? progressFraction : 0.05,
                          strokeWidth: 7,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            SafeHerColors.brightPink,
                          ),
                          backgroundColor: Colors.transparent,
                        ),
                      ),

                      // Inner Core Display
                      Container(
                        width: 175,
                        height: 175,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: SafeHerColors.midnightPurple,
                          boxShadow: [
                            BoxShadow(
                              color: SafeHerColors.primaryRose.withValues(
                                alpha: _isHolding ? 0.4 : 0.1,
                              ),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '${_remainingSeconds.toStringAsFixed(1)}s',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // "Keep holding..." hint text
              Text(
                _isHolding ? 'Keep holding...' : 'Press and hold circle above',
                style: const TextStyle(
                  color: Color(0xFFC4B8CC),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),

              // Cancel button with circular X icon matching Screen 8
              Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
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
    );
  }
}
