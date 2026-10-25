import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../models/journey.dart';
import '../../models/trusted_contact.dart';
import '../../services/contact_service.dart';
import '../../widgets/shared_widgets.dart';

class PlanJourneyScreen extends StatefulWidget {
  const PlanJourneyScreen({super.key});

  @override
  State<PlanJourneyScreen> createState() => _PlanJourneyScreenState();
}

class _PlanJourneyScreenState extends State<PlanJourneyScreen> {
  final TextEditingController _destinationController = TextEditingController(
    text: 'Sri Venkateswara University, Tirupati',
  );

  TravelMode _selectedMode = TravelMode.bike;
  TimeOfDay _arrivalTime = const TimeOfDay(hour: 20, minute: 30);
  int _checkinInterval = 15;

  List<TrustedContact> _allContacts = [];
  final Set<String> _selectedContactIds = {};
  bool _isLoadingContacts = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final contacts = await ContactService().getContacts();
    if (mounted) {
      setState(() {
        _allContacts = contacts;
        if (_allContacts.isEmpty) {
          // Pre-populate with typical default contacts matching reference showcase
          final now = DateTime.now();
          _allContacts = [
            TrustedContact(
              id: 'c1',
              name: 'Mom',
              phone: '+91 98765 43210',
              relationship: 'Mother',
              createdAt: now,
              updatedAt: now,
            ),
            TrustedContact(
              id: 'c2',
              name: 'Sister',
              phone: '+91 98765 43211',
              relationship: 'Sister',
              createdAt: now,
              updatedAt: now,
            ),
            TrustedContact(
              id: 'c3',
              name: 'Best Friend',
              phone: '+91 98765 43212',
              relationship: 'Friend',
              createdAt: now,
              updatedAt: now,
            ),
          ];
        }
        for (final c in _allContacts) {
          _selectedContactIds.add(c.id);
        }
        _isLoadingContacts = false;
      });
    }
  }

  @override
  void dispose() {
    _destinationController.dispose();
    super.dispose();
  }

  DateTime _computeArrivalDateTime() {
    final now = DateTime.now();
    var dt = DateTime(
      now.year,
      now.month,
      now.day,
      _arrivalTime.hour,
      _arrivalTime.minute,
    );
    if (dt.isBefore(now)) {
      dt = dt.add(const Duration(days: 1));
    }
    return dt;
  }

  Future<void> _onProceedToRoutePreview() async {
    final dest = _destinationController.text.trim();
    if (dest.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a destination')),
      );
      return;
    }

    double destLat = 13.6288;
    double destLng = 79.4192;

    // Check regional landmarks first
    final lower = dest.toLowerCase();
    if (lower.contains('sv university') || lower.contains('venkateswara university')) {
      destLat = 13.6330;
      destLng = 79.4000;
    } else if (lower.contains('railway') || lower.contains('station')) {
      destLat = 13.6280;
      destLng = 79.4190;
    } else if (lower.contains('hospital') || lower.contains('padmavathi')) {
      destLat = 13.6210;
      destLng = 79.4300;
    } else if (lower.contains('alipiri')) {
      destLat = 13.6500;
      destLng = 79.4050;
    } else if (lower.contains('chandragiri')) {
      destLat = 13.5850;
      destLng = 79.3180;
    } else if (lower.contains('renigunta')) {
      destLat = 13.6450;
      destLng = 79.5150;
    } else {
      // Attempt live geocoding via Nominatim with 2s timeout
      try {
        final url = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(dest)}&format=json&limit=1',
        );
        final res = await http.get(
          url,
          headers: {'User-Agent': 'SafeHer-WomenSafetyApp/1.0'},
        ).timeout(const Duration(seconds: 2));

        if (res.statusCode == 200) {
          final list = json.decode(res.body) as List<dynamic>;
          if (list.isNotEmpty) {
            final item = list.first as Map<String, dynamic>;
            destLat = double.parse(item['lat'] as String);
            destLng = double.parse(item['lon'] as String);
          }
        }
      } catch (_) {
        // Fallback to regional center
      }
    }

    final selectedContacts = _allContacts
        .where((c) => _selectedContactIds.contains(c.id))
        .toList();

    if (!mounted) return;

    Navigator.pushNamed(
      context,
      AppRoutes.routePreview,
      arguments: {
        'destinationName': dest,
        'destinationLat': destLat,
        'destinationLng': destLng,
        'travelMode': _selectedMode,
        'expectedArrivalTime': _computeArrivalDateTime(),
        'checkinIntervalMinutes': _checkinInterval,
        'notifyContactIds': selectedContacts.map((c) => c.id).toList(),
        'notifyContactNames': selectedContacts.map((c) => c.name).toList(),
        'notifyContactPhones': selectedContacts.map((c) => c.phone).toList(),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedTime = _arrivalTime.format(context);

    return Scaffold(
      backgroundColor: SafeHerColors.midnightPurple,
      appBar: SafeHerAppBar(
        title: 'Plan Your Journey',
        showBack: true,
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: SafeHerColors.primaryRose.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on, color: SafeHerColors.primaryRose, size: 14),
              SizedBox(width: 4),
              Text(
                'Tirupati',
                style: TextStyle(
                  color: SafeHerColors.primaryRose,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: SafeHerColors.darkBackgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Destination Section
                const Text(
                  'Destination',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: SafeHerColors.plumCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: SafeHerColors.darkBorder),
                  ),
                  child: TextField(
                    controller: _destinationController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFFC7B8D6),
                        size: 20,
                      ),
                      suffixIcon: const Icon(
                        Icons.location_on,
                        color: SafeHerColors.primaryRose,
                        size: 20,
                      ),
                      hintText: 'Enter destination address',
                      hintStyle: const TextStyle(color: Color(0xFF8E7E9C)),
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                // Mode of Travel Section
                const Text(
                  'Mode of Travel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildModePill(TravelMode.walking, 'Walking', Icons.directions_walk_rounded),
                    _buildModePill(TravelMode.bike, 'Bike', Icons.pedal_bike_rounded),
                    _buildModePill(TravelMode.car, 'Car', Icons.directions_car_rounded),
                    _buildModePill(TravelMode.bus, 'Bus', Icons.directions_bus_rounded),
                    _buildModePill(TravelMode.other, 'Other', Icons.more_horiz_rounded),
                  ],
                ),
                const SizedBox(height: 22),

                // Expected Arrival Time
                const Text(
                  'Expected Arrival Time',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _arrivalTime,
                    );
                    if (picked != null) {
                      setState(() {
                        _arrivalTime = picked;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: SafeHerColors.plumCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: SafeHerColors.darkBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          color: SafeHerColors.primaryRose,
                          size: 19,
                        ),
                        const SizedBox(width: 14),
                        Text(
                          'Today, $formattedTime',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.arrow_drop_down,
                          color: Color(0xFFB4A3C2),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                // Check-in Interval
                const Text(
                  'Check-in Interval',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _showIntervalPicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: SafeHerColors.plumCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: SafeHerColors.darkBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          color: SafeHerColors.primaryRose,
                          size: 20,
                        ),
                        const SizedBox(width: 14),
                        Text(
                          '$_checkinInterval minutes',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.chevron_right,
                          color: Color(0xFFB4A3C2),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                // Notify These Contacts
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Notify These Contacts',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${_selectedContactIds.length} selected',
                      style: const TextStyle(
                        color: Color(0xFFB4A3C2),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 84,
                  child: _isLoadingContacts
                      ? const Center(child: CircularProgressIndicator())
                      : ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            ..._allContacts.map((contact) {
                              final isSelected =
                                  _selectedContactIds.contains(contact.id);
                              return _buildContactAvatar(contact, isSelected);
                            }),
                            _buildAddContactButton(),
                          ],
                        ),
                ),
                const SizedBox(height: 32),

                // Start Journey Bottom Button
                SafeHerPrimaryButton(
                  text: 'Start Journey',
                  icon: Icons.navigation_rounded,
                  onPressed: _onProceedToRoutePreview,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModePill(TravelMode mode, String label, IconData icon) {
    final isSelected = _selectedMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMode = mode;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? SafeHerColors.primaryRose : SafeHerColors.plumCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? SafeHerColors.primaryRose : SafeHerColors.darkBorder,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : const Color(0xFFB4A3C2),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFFB4A3C2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactAvatar(TrustedContact contact, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedContactIds.remove(contact.id);
          } else {
            _selectedContactIds.add(contact.id);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: SafeHerColors.deepPlum,
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: isSelected
                        ? SafeHerColors.primaryRose.withValues(alpha: 0.3)
                        : Colors.white12,
                    child: Text(
                      contact.name.isNotEmpty ? contact.name[0] : 'C',
                      style: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFFB4A3C2),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                if (isSelected)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: SafeHerColors.primaryRose,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              contact.name,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFFB4A3C2),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddContactButton() {
    return GestureDetector(
      onTap: () async {
        await Navigator.pushNamed(context, AppRoutes.contacts);
        _loadContacts();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Add',
              style: TextStyle(
                color: Color(0xFFB4A3C2),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showIntervalPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: SafeHerColors.midnightPurple,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final options = [5, 10, 15, 20, 30, 45, 60];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Check-in Interval',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                ...options.map(
                  (mins) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '$mins minutes',
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),
                    trailing: _checkinInterval == mins
                        ? const Icon(Icons.check, color: SafeHerColors.primaryRose)
                        : null,
                    onTap: () {
                      setState(() {
                        _checkinInterval = mins;
                      });
                      Navigator.pop(ctx);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
