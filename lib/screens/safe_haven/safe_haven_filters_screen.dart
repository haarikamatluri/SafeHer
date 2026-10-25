import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../widgets/shared_widgets.dart';

class SafeHavenFiltersScreen extends StatefulWidget {
  const SafeHavenFiltersScreen({super.key});

  @override
  State<SafeHavenFiltersScreen> createState() => _SafeHavenFiltersScreenState();
}

class _SafeHavenFiltersScreenState extends State<SafeHavenFiltersScreen> {
  bool _showPolice = true;
  bool _showHospitals = true;
  bool _showPharmacies = true;
  bool _showWomenCenters = true;
  bool _showVerifiedPlaces = true;
  bool _showCommunityReports = true;

  int _selectedView = 0; // 0 = Map, 1 = List

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SafeHerColors.midnightPurple,
      appBar: const SafeHerAppBar(
        title: 'Filters & Settings',
        showBack: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: SafeHerColors.darkBackgroundGradient,
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              const Text(
                'Show on Map',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),

              _buildFilterSwitch(
                icon: Icons.local_police_rounded,
                title: 'Police Stations',
                value: _showPolice,
                onChanged: (val) => setState(() => _showPolice = val),
              ),
              const SizedBox(height: 10),

              _buildFilterSwitch(
                icon: Icons.local_hospital_rounded,
                title: 'Hospitals',
                value: _showHospitals,
                onChanged: (val) => setState(() => _showHospitals = val),
              ),
              const SizedBox(height: 10),

              _buildFilterSwitch(
                icon: Icons.local_pharmacy_rounded,
                title: 'Pharmacies',
                value: _showPharmacies,
                onChanged: (val) => setState(() => _showPharmacies = val),
              ),
              const SizedBox(height: 10),

              _buildFilterSwitch(
                icon: Icons.shield_rounded,
                title: 'Women Help Centers',
                value: _showWomenCenters,
                onChanged: (val) => setState(() => _showWomenCenters = val),
              ),
              const SizedBox(height: 10),

              _buildFilterSwitch(
                icon: Icons.verified_user_rounded,
                title: 'Verified Safe Places',
                value: _showVerifiedPlaces,
                onChanged: (val) => setState(() => _showVerifiedPlaces = val),
              ),
              const SizedBox(height: 10),

              _buildFilterSwitch(
                icon: Icons.rate_review_rounded,
                title: 'Community Reports',
                value: _showCommunityReports,
                onChanged: (val) => setState(() => _showCommunityReports = val),
              ),
              const SizedBox(height: 28),

              const Text(
                'Map View',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),

              // Segmented Toggle: [ Map | List ]
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: SafeHerColors.plumCard,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: SafeHerColors.darkBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedView = 0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _selectedView == 0
                                ? SafeHerColors.primaryRose
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Map',
                            style: TextStyle(
                              color: _selectedView == 0
                                  ? Colors.white
                                  : const Color(0xFFB4A3C2),
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedView = 1),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _selectedView == 1
                                ? SafeHerColors.primaryRose
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'List',
                            style: TextStyle(
                              color: _selectedView == 1
                                  ? Colors.white
                                  : const Color(0xFFB4A3C2),
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              SafeHerPrimaryButton(
                text: 'Apply Filters',
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSwitch({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: SafeHerColors.plumCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SafeHerColors.darkBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: SafeHerColors.primaryRose, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: SafeHerColors.primaryRose,
            activeTrackColor: SafeHerColors.primaryRose.withValues(alpha: 0.35),
            inactiveThumbColor: const Color(0xFF8E7E9C),
            inactiveTrackColor: SafeHerColors.midnightPurple,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
