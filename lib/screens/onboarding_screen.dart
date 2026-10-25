import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/routes.dart';
import '../app/theme.dart';
import '../utils/constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'Feel Safer Everywhere',
      'description': 'Real-time location sharing, trusted contacts and instant help when you need it.',
      'type': 'walking',
    },
    {
      'title': 'One Tap for Help',
      'description':
          'Quickly alert your trusted contacts with your live location.',
      'type': 'sos',
    },
    {
      'title': 'Stay Connected',
      'description':
          'Add trusted contacts who will be notified in an emergency.',
      'type': 'contacts',
    },
  ];

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefOnboardingCompleted, true);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SafeHerColors.surfaceWhite,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Skip Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _finishOnboarding,
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: SafeHerColors.secondaryText,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // PageView Content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Illustration Area
                        _buildIllustration(page['type']),
                        const SizedBox(height: 36),

                        // Title
                        Text(
                          page['title'],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: SafeHerColors.primaryText,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Description
                        Text(
                          page['description'],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            color: SafeHerColors.secondaryText,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Navigation Area (Indicators + Circular Next Button)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page Indicator Dots
                  Row(
                    children: List.generate(_pages.length, (index) {
                      final isSelected = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 6),
                        width: isSelected ? 22 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? SafeHerColors.primaryRose
                              : const Color(0xFFE2D6E2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),

                  // Circular Pink Next Button
                  GestureDetector(
                    onTap: _nextPage,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: SafeHerColors.pinkButtonGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: SafeHerColors.primaryRose.withValues(
                              alpha: 0.4,
                            ),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIllustration(String type) {
    switch (type) {
      case 'walking':
        // Screen 2: Woman walking in city with location pin
        return Container(
          height: 250,
          width: double.infinity,
          decoration: BoxDecoration(
            color: SafeHerColors.palePink,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Subtle background skyline & rings
              Positioned(
                top: 30,
                right: 40,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: SafeHerColors.primaryRose.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // City beacon pin
              Positioned(
                top: 45,
                right: 50,
                child: const Icon(
                  Icons.location_on,
                  color: SafeHerColors.primaryRose,
                  size: 38,
                ),
              ),
              // Woman avatar / walking figure
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: SafeHerColors.midnightPurple,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: SafeHerColors.primaryRose,
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      Icons.person_pin_circle_outlined,
                      size: 52,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.shield,
                          size: 14,
                          color: SafeHerColors.successGreen,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Real-time Protection',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: SafeHerColors.primaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );

      case 'sos':
        // Screen 3: Phone with SOS button
        return Container(
          height: 250,
          width: double.infinity,
          decoration: BoxDecoration(
            color: SafeHerColors.palePink,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Center(
            child: Container(
              width: 140,
              height: 210,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SafeHerColors.midnightPurple,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: SafeHerColors.darkBorder, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: SafeHerColors.pinkButtonGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: SafeHerColors.primaryRose.withValues(
                            alpha: 0.5,
                          ),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'SOS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Instant Alert',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

      case 'contacts':
      default:
        // Screen 4: Trusted Contacts network
        return Container(
          height: 250,
          width: double.infinity,
          decoration: BoxDecoration(
            color: SafeHerColors.palePink,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Central Shield
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: SafeHerColors.pinkButtonGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: SafeHerColors.primaryRose.withValues(alpha: 0.3),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),

              // Network node 1: Top
              Positioned(top: 24, child: _buildContactAvatar('M', 'Mom')),
              // Network node 2: Left
              Positioned(
                left: 36,
                top: 100,
                child: _buildContactAvatar('S', 'Sister'),
              ),
              // Network node 3: Right
              Positioned(
                right: 36,
                top: 100,
                child: _buildContactAvatar('F', 'Friend'),
              ),
              // Network node 4: Bottom
              Positioned(
                bottom: 24,
                child: _buildContactAvatar('P', 'Partner'),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildContactAvatar(String initial, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: SafeHerColors.midnightPurple,
          child: Text(
            initial,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: SafeHerColors.primaryText,
          ),
        ),
      ],
    );
  }
}
