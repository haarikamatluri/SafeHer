import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../models/journey.dart';
import '../../services/journey_service.dart';
import '../../widgets/shared_widgets.dart';

class JourneyHomeScreen extends StatefulWidget {
  const JourneyHomeScreen({super.key});

  @override
  State<JourneyHomeScreen> createState() => _JourneyHomeScreenState();
}

class _JourneyHomeScreenState extends State<JourneyHomeScreen> {
  final JourneyService _journeyService = JourneyService();
  List<Journey> _pastJourneys = [];
  bool _isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final list = await _journeyService.getJourneyHistory();
    if (mounted) {
      setState(() {
        _pastJourneys = list;
        _isLoadingHistory = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SafeHerColors.midnightPurple,
      appBar: const SafeHerAppBar(
        title: 'AI Journey Guardian',
        showBack: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: SafeHerColors.darkBackgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Tagline Subtitle
                const Text(
                  'Plan, track and get automatic check-ins with AI monitoring',
                  style: TextStyle(
                    color: Color(0xFFB4A3C2),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 16),

                // Active Journey Alert if one is active
                ValueListenableBuilder<Journey?>(
                  valueListenable: _journeyService.journeyListenable,
                  builder: (context, activeJourney, _) {
                    if (activeJourney != null && activeJourney.isActive) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: SafeHerColors.plumCard,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: SafeHerColors.primaryRose,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: SafeHerColors.primaryRose.withValues(alpha: 0.25),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: SafeHerColors.primaryRose.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.navigation_rounded,
                                color: SafeHerColors.primaryRose,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Active Journey in Progress',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'To: ${activeJourney.destinationName}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFFC0B3CC),
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: SafeHerColors.primaryRose,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pushNamed(context, AppRoutes.journeyActive);
                              },
                              child: const Text(
                                'View',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                // Hero Graphic Banner matching Reference Image
                Container(
                  height: 190,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF5D2E55),
                        Color(0xFF331637),
                        SafeHerColors.midnightPurple,
                      ],
                    ),
                    border: Border.all(
                      color: SafeHerColors.darkBorder,
                      width: 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Sun and glowing mountains silhouette
                      Positioned(
                        top: 25,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFFFFB300),
                                  SafeHerColors.primaryRose.withValues(alpha: 0.8),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Temple/City backdrop silhouettes
                      Positioned(
                        bottom: 30,
                        left: 20,
                        right: 20,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Icon(
                              Icons.temple_hindu_rounded,
                              size: 42,
                              color: Colors.black.withValues(alpha: 0.28),
                            ),
                            Icon(
                              Icons.location_city_rounded,
                              size: 46,
                              color: Colors.black.withValues(alpha: 0.32),
                            ),
                            Icon(
                              Icons.account_balance_rounded,
                              size: 38,
                              color: Colors.black.withValues(alpha: 0.28),
                            ),
                          ],
                        ),
                      ),
                      // Silhouette traveler with backpack and glowing destination pin
                      Positioned(
                        bottom: 14,
                        left: 36,
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: SafeHerColors.primaryRose.withValues(alpha: 0.6),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.person_pin_circle_rounded,
                            color: Colors.white,
                            size: 34,
                          ),
                        ),
                      ),
                      // Destination Pin with glowing path
                      Positioned(
                        bottom: 35,
                        right: 48,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: SafeHerColors.primaryRose,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.pin_drop_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            Container(
                              width: 14,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Main Overview Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: SafeHerColors.plumCard,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: SafeHerColors.darkBorder, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI Journey Guardian',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Plan your journey, get real-time tracking, automatic check-ins and instant alerts if something goes wrong.',
                        style: TextStyle(
                          color: Color(0xFFC7B8D6),
                          fontSize: 13.5,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 4 Features with Pink Checkmarks
                      _buildFeatureBullet('AI powered journey monitoring'),
                      const SizedBox(height: 10),
                      _buildFeatureBullet('Automatic check-ins'),
                      const SizedBox(height: 10),
                      _buildFeatureBullet('Route safety insights'),
                      const SizedBox(height: 10),
                      _buildFeatureBullet('Alerts on missed check-ins'),
                      const SizedBox(height: 24),

                      // Start a Journey Primary Action Button
                      SafeHerPrimaryButton(
                        text: 'Start a Journey',
                        icon: Icons.navigation_rounded,
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.planJourney);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Recent Journeys Header
                if (_pastJourneys.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Journeys',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${_pastJourneys.length} completed',
                        style: const TextStyle(
                          color: Color(0xFFB4A3C2),
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_isLoadingHistory)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: SafeHerColors.primaryRose,
                        ),
                      ),
                    )
                  else
                    ..._pastJourneys.take(3).map((j) => _buildPastJourneyCard(j)),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureBullet(String text) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: SafeHerColors.primaryRose.withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(
              Icons.check_rounded,
              color: SafeHerColors.primaryRose,
              size: 14,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPastJourneyCard(Journey j) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: SafeHerColors.plumCard.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SafeHerColors.darkBorder.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: SafeHerColors.successGreen.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              color: SafeHerColors.successGreen,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  j.destinationName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${j.totalDistanceKm} km • ${j.checkinsCompleted}/${j.totalCheckinsExpected} check-ins',
                  style: const TextStyle(
                    color: Color(0xFF9E8F9B),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: Color(0xFF9E8F9B),
            size: 18,
          ),
        ],
      ),
    );
  }
}
