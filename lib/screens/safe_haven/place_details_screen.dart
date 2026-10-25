import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../models/safe_haven.dart';
import '../../services/safe_haven_service.dart';
import '../../widgets/shared_widgets.dart';

class PlaceDetailsScreen extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  const PlaceDetailsScreen({super.key, this.arguments});

  @override
  State<PlaceDetailsScreen> createState() => _PlaceDetailsScreenState();
}

class _PlaceDetailsScreenState extends State<PlaceDetailsScreen> {
  final SafeHavenService _safeHavenService = SafeHavenService();
  bool _isFavorite = false;
  late SafeHavenPlace _place;

  @override
  void initState() {
    super.initState();
    if (widget.arguments != null && widget.arguments!.isNotEmpty) {
      _place = SafeHavenPlace.fromMap(widget.arguments!);
    } else {
      _place = const SafeHavenPlace(
        id: 'place_hospital_1',
        name: 'Sri Padmavathi Hospital',
        category: SafeHavenCategory.hospital,
        address: 'Tiruchanur Road, Tirupati, AP',
        phone: '+91 87722 33455',
        latitude: 13.6180,
        longitude: 79.4320,
        isVerified: true,
        isOpen24Hours: true,
        operatingHours: 'Open 24 hours',
        distanceKm: 2.4,
        rating: 4.8,
      );
    }
  }

  Future<void> _callNow() async {
    final success = await _safeHavenService.callEmergencyNumber(_place.phone);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open phone dialer for ${_place.phone}')),
      );
    }
  }

  void _getDirections() {
    Navigator.pushNamed(
      context,
      AppRoutes.routeToSafePlace,
      arguments: _place.toMap(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SafeHerColors.midnightPurple,
      appBar: SafeHerAppBar(
        title: 'Place Details',
        showBack: true,
        trailing: IconButton(
          icon: Icon(
            _isFavorite ? Icons.favorite : Icons.favorite_border,
            color: _isFavorite ? SafeHerColors.primaryRose : Colors.white,
          ),
          onPressed: () {
            setState(() => _isFavorite = !_isFavorite);
          },
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: SafeHerColors.darkBackgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header Image / Building Graphic
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B1D45), Color(0xFF1D1026)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  border: Border(
                    bottom: BorderSide(color: SafeHerColors.darkBorder),
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      _place.category == SafeHavenCategory.hospital
                          ? Icons.local_hospital_rounded
                          : _place.category == SafeHavenCategory.police
                              ? Icons.local_police_rounded
                              : Icons.health_and_safety_rounded,
                      size: 90,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    Positioned(
                      bottom: 12,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${_place.rating}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Details Card Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name and Verified Badge Row
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _place.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (_place.isVerified)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: SafeHerColors.successGreen.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: SafeHerColors.successGreen,
                                  width: 1,
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.verified_rounded,
                                    color: SafeHerColors.successGreen,
                                    size: 13,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Verified',
                                    style: TextStyle(
                                      color: SafeHerColors.successGreen,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_place.category.displayName} • ${_place.distanceKm} km',
                        style: const TextStyle(
                          color: Color(0xFFC7B8D6),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Information Container
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: SafeHerColors.plumCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: SafeHerColors.darkBorder),
                        ),
                        child: Column(
                          children: [
                            _buildInfoItem(
                              icon: Icons.support_agent_rounded,
                              text: '24/7 Emergency Services',
                            ),
                            const Divider(color: SafeHerColors.darkBorder, height: 24),
                            _buildInfoItem(
                              icon: Icons.phone_in_talk_rounded,
                              text: _place.phone,
                            ),
                            const Divider(color: SafeHerColors.darkBorder, height: 24),
                            _buildInfoItem(
                              icon: Icons.location_on_outlined,
                              text: _place.address,
                            ),
                            const Divider(color: SafeHerColors.darkBorder, height: 24),
                            _buildInfoItem(
                              icon: Icons.access_time_rounded,
                              text: _place.operatingHours,
                              textColor: SafeHerColors.successGreen,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Verification Authority Note
                      if (_place.verificationSource != null)
                        Text(
                          'Source: ${_place.verificationSource}',
                          style: const TextStyle(
                            color: Color(0xFF8E7E9C),
                            fontSize: 11.5,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Bottom Actions: Get Directions & Call Now
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: SafeHerColors.primaryRose,
                            side: const BorderSide(
                              color: SafeHerColors.primaryRose,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26),
                            ),
                          ),
                          onPressed: _getDirections,
                          child: const Text(
                            'Get Directions',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: SafeHerPrimaryButton(
                        text: 'Call Now',
                        icon: Icons.phone_forwarded_rounded,
                        onPressed: _callNow,
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

  Widget _buildInfoItem({
    required IconData icon,
    required String text,
    Color? textColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: SafeHerColors.primaryRose, size: 20),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: textColor ?? Colors.white,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
