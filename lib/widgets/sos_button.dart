import 'package:flutter/material.dart';

import '../app/theme.dart';

class SafeHerSosButton extends StatefulWidget {
  final VoidCallback onTrigger;
  final bool isLoading;

  const SafeHerSosButton({
    super.key,
    required this.onTrigger,
    this.isLoading = false,
  });

  @override
  State<SafeHerSosButton> createState() => _SafeHerSosButtonState();
}

class _SafeHerSosButtonState extends State<SafeHerSosButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _glowAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 8.0, end: 24.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: widget.onTrigger,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // Outer glow layer
                    boxShadow: [
                      BoxShadow(
                        color: SafeHerColors.primaryRose.withValues(
                          alpha: 0.35,
                        ),
                        blurRadius: _glowAnimation.value,
                        spreadRadius: 4,
                      ),
                      BoxShadow(
                        color: SafeHerColors.brightPink.withValues(alpha: 0.2),
                        blurRadius: _glowAnimation.value * 1.5,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outermost thin vibrant ring
                      Container(
                        width: 190,
                        height: 190,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: SafeHerColors.primaryRose.withValues(
                              alpha: 0.8,
                            ),
                            width: 3.5,
                          ),
                        ),
                      ),
                      // Inner dark core with gradient
                      Container(
                        width: 168,
                        height: 168,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const RadialGradient(
                            center: Alignment(-0.2, -0.2),
                            radius: 0.85,
                            colors: [
                              SafeHerColors.brightPink,
                              SafeHerColors.primaryRose,
                              Color(0xFF8B1240),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: SafeHerColors.primaryRose.withValues(
                                alpha: 0.6,
                              ),
                              blurRadius: 16,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Center(
                          child: widget.isLoading
                              ? const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                )
                              : const Text(
                                  'SOS',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 38,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Press and hold for 1 second\nto activate',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFFBCAFC8),
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

/// Backward compatibility alias
typedef SosButton = SafeHerSosButton;
