import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../models/safe_haven.dart';
import '../../services/safe_haven_service.dart';
import '../../widgets/real_map_view.dart';
import '../../widgets/shared_widgets.dart';

class NearbyPlacesScreen extends StatefulWidget {
  const NearbyPlacesScreen({super.key});

  @override
  State<NearbyPlacesScreen> createState() => _NearbyPlacesScreenState();
}

class _NearbyPlacesScreenState extends State<NearbyPlacesScreen> {
  final SafeHavenService _safeHavenService = SafeHavenService();
  SafeHavenCategory _selectedCategory = SafeHavenCategory.all;
  List<SafeHavenPlace> _places = [];
  int _selectedPlaceIndex = 0;
  bool _isLoading = true;

  LatLng _userPosition = const LatLng(13.6288, 79.4192); // Tirupati default fallback
  double _gpsAccuracy = 8.0;

  @override
  void initState() {
    super.initState();
    _places = _safeHavenService.getPlaces(category: _selectedCategory);
    _loadLivePlaces();
  }

  Future<void> _loadLivePlaces() async {
    setState(() => _isLoading = true);

    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.always || perm == LocationPermission.whileInUse) {
        try {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(timeLimit: Duration(seconds: 4)),
          );
          _userPosition = LatLng(pos.latitude, pos.longitude);
          _gpsAccuracy = pos.accuracy;
        } catch (_) {
          final last = await Geolocator.getLastKnownPosition();
          if (last != null) {
            _userPosition = LatLng(last.latitude, last.longitude);
            _gpsAccuracy = last.accuracy;
          }
        }
      }

      final liveResults = await _safeHavenService.fetchNearbyPlacesLive(
        latitude: _userPosition.latitude,
        longitude: _userPosition.longitude,
        category: _selectedCategory,
      );

      if (mounted) {
        setState(() {
          _places = liveResults;
          _selectedPlaceIndex = 0;
        });
      }
    } catch (e) {
      debugPrint('[NearbyPlaces] Error loading places: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onCategoryChanged(SafeHavenCategory category) {
    setState(() {
      _selectedCategory = category;
      _selectedPlaceIndex = 0;
    });
    _loadLivePlaces();
  }

  @override
  Widget build(BuildContext context) {
    final currentPlace = _places.isNotEmpty && _selectedPlaceIndex < _places.length
        ? _places[_selectedPlaceIndex]
        : null;

    return Scaffold(
      backgroundColor: SafeHerColors.midnightPurple,
      appBar: SafeHerAppBar(
        title: 'Nearby Safe Places',
        showBack: true,
        trailing: IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: _loadLivePlaces,
          tooltip: 'Refresh nearby places',
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
              // Category Filter Pills Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: SafeHavenCategory.values.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          cat.displayName,
                          style: TextStyle(
                            color: isSelected ? Colors.white : const Color(0xFFC7B8D6),
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: SafeHerColors.primaryRose,
                        backgroundColor: SafeHerColors.plumCard,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(
                            color: isSelected
                                ? SafeHerColors.primaryRose
                                : SafeHerColors.darkBorder,
                          ),
                        ),
                        showCheckmark: false,
                        onSelected: (_) => _onCategoryChanged(cat),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Source attribution banner
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _safeHavenService.currentDataSource,
                      style: const TextStyle(
                        color: Color(0xFF9E8F9B),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${_places.length} found',
                      style: const TextStyle(
                        color: SafeHerColors.primaryRose,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              // Real Interactive Map View with Safe Haven Markers
              Expanded(
                flex: 6,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: _isLoading
                          ? Container(
                              color: SafeHerColors.plumCard,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: SafeHerColors.primaryRose,
                                  strokeWidth: 2.5,
                                ),
                              ),
                            )
                          : RealInteractiveMapView(
                              initialCenter: currentPlace != null
                                  ? LatLng(currentPlace.latitude, currentPlace.longitude)
                                  : _userPosition,
                              initialZoom: 14.5,
                              userPosition: _userPosition,
                              accuracyMeters: _gpsAccuracy,
                              safeHavens: _places,
                              onSafeHavenSelected: (haven) {
                                final idx = _places.indexWhere((p) => p.id == haven.id);
                                if (idx != -1) {
                                  setState(() => _selectedPlaceIndex = idx);
                                }
                              },
                            ),
                    ),
                  ],
                ),
              ),

              // Selected Place Preview Bottom Card
              if (currentPlace != null)
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.placeDetails,
                      arguments: currentPlace,
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: SafeHerColors.plumCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: SafeHerColors.darkBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Category Icon Thumbnail
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: SafeHerColors.midnightPurple,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: SafeHerColors.darkBorder),
                          ),
                          child: Center(
                            child: Icon(
                              _getCategoryIcon(currentPlace.category),
                              color: SafeHerColors.primaryRose,
                              size: 26,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      currentPlace.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  if (currentPlace.isVerified)
                                    Container(
                                      margin: const EdgeInsets.only(left: 6),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: SafeHerColors.successGreen.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Verified',
                                        style: TextStyle(
                                          color: SafeHerColors.successGreen,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${currentPlace.category.displayName} • ${currentPlace.distanceKm} km away',
                                style: const TextStyle(
                                  color: Color(0xFFB4A3C2),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                currentPlace.operatingHours,
                                style: const TextStyle(
                                  color: SafeHerColors.successGreen,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFFC7B8D6),
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                )
              else if (!_isLoading)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: SafeHerColors.plumCard,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text(
                      'No safe places found for this category nearby.',
                      style: TextStyle(color: Color(0xFFC7B8D6), fontSize: 13),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(SafeHavenCategory cat) {
    switch (cat) {
      case SafeHavenCategory.police:
        return Icons.local_police_rounded;
      case SafeHavenCategory.hospital:
        return Icons.local_hospital_rounded;
      case SafeHavenCategory.pharmacy:
        return Icons.medication_rounded;
      case SafeHavenCategory.womenCenter:
        return Icons.female_rounded;
      case SafeHavenCategory.verifiedPlace:
      case SafeHavenCategory.all:
        return Icons.shield_rounded;
    }
  }
}
