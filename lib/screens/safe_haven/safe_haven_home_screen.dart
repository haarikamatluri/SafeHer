import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../widgets/shared_widgets.dart';

class SafeHavenHomeScreen extends StatelessWidget {
  const SafeHavenHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SafeHerColors.midnightPurple,
      appBar: const SafeHerAppBar(
        title: 'Safe Haven Network',
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
                  'Nearby safe places, help points and emergency services',
                  style: TextStyle(
                    color: Color(0xFFB4A3C2),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 16),

                // City Night Illuminated Street Graphic matching Reference
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF4A1E3E),
                        Color(0xFF261233),
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
                      // Warm Lamppost & Buildings silhouette
                      Positioned(
                        top: 25,
                        right: 40,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFFFD54F).withValues(alpha: 0.15),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFD54F).withValues(alpha: 0.35),
                                blurRadius: 30,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.lightbulb_rounded,
                            color: Color(0xFFFFD54F),
                            size: 26,
                          ),
                        ),
                      ),
                      // Cityscape
                      Positioned(
                        bottom: 12,
                        left: 20,
                        right: 20,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(
                              Icons.apartment_rounded,
                              size: 70,
                              color: Colors.white.withValues(alpha: 0.22),
                            ),
                            Icon(
                              Icons.local_hospital_rounded,
                              size: 55,
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                            Icon(
                              Icons.local_police_rounded,
                              size: 60,
                              color: Colors.white.withValues(alpha: 0.22),
                            ),
                          ],
                        ),
                      ),
                      // Traveler silhouette
                      Positioned(
                        bottom: 15,
                        left: 35,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: SafeHerColors.primaryRose.withValues(alpha: 0.2),
                            border: Border.all(
                              color: SafeHerColors.primaryRose,
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.person_pin_circle_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
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
                        'Safe Haven Network',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Verified safe places near you when you need help.',
                        style: TextStyle(
                          color: Color(0xFFC7B8D6),
                          fontSize: 13.5,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),

                      _buildBullet('Nearby police stations'),
                      const SizedBox(height: 10),
                      _buildBullet('Hospitals & pharmacies'),
                      const SizedBox(height: 10),
                      _buildBullet('Women help centers'),
                      const SizedBox(height: 10),
                      _buildBullet('Verified safe places'),
                      const SizedBox(height: 10),
                      _buildBullet('Community reported locations'),
                      const SizedBox(height: 24),

                      // Find Nearby Places Action Button
                      SafeHerPrimaryButton(
                        text: 'Find Nearby Places',
                        icon: Icons.near_me_rounded,
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.nearbyPlaces);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Quick Navigation Hub
                const Text(
                  'Quick Access Directory',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: _buildHubCard(
                        context,
                        icon: Icons.map_rounded,
                        title: 'Nearby Places Map',
                        subtitle: 'Radar safe zones',
                        route: AppRoutes.nearbyPlaces,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildHubCard(
                        context,
                        icon: Icons.phone_in_talk_rounded,
                        title: 'Emergency Services',
                        subtitle: 'Speed dial 112, 1091',
                        route: AppRoutes.emergencyServices,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildHubCard(
                        context,
                        icon: Icons.rate_review_rounded,
                        title: 'Community Reports',
                        subtitle: 'Lighting & safety alerts',
                        route: AppRoutes.communityReports,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildHubCard(
                        context,
                        icon: Icons.tune_rounded,
                        title: 'Filters & Settings',
                        subtitle: 'Category display',
                        route: AppRoutes.safeHavenFilters,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBullet(String text) {
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

  Widget _buildHubCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String route,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.pushNamed(context, route),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: SafeHerColors.plumCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SafeHerColors.darkBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: SafeHerColors.primaryRose, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                color: Color(0xFFB4A3C2),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
