import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../services/location_service.dart';

class SafetyStatusCard extends StatelessWidget {
  final bool isEmergencyActive;
  final bool hasActiveCheckin;
  final bool isCheckinMissed;
  final VoidCallback? onEmergencyTap;
  final VoidCallback? onCheckinTap;

  const SafetyStatusCard({
    super.key,
    required this.isEmergencyActive,
    this.hasActiveCheckin = false,
    this.isCheckinMissed = false,
    this.onEmergencyTap,
    this.onCheckinTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isEmergencyActive) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SafeHerTheme.emergencyRedLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: SafeHerTheme.emergencyRed.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: SafeHerTheme.emergencyRed,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'EMERGENCY ACTIVE',
                    style: TextStyle(
                      color: SafeHerTheme.emergencyRedDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Incident in progress. Tap to manage or resolve.',
                    style: TextStyle(
                      color: SafeHerTheme.textDark,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (onEmergencyTap != null)
              TextButton(
                onPressed: onEmergencyTap,
                style: TextButton.styleFrom(
                  foregroundColor: SafeHerTheme.emergencyRedDark,
                ),
                child: const Text(
                  'VIEW',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
      );
    }

    if (isCheckinMissed) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SafeHerTheme.warningAmberLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SafeHerTheme.warningAmber),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: SafeHerTheme.warningAmber,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.timer_off_outlined,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'CHECK-IN DEADLINE MISSED',
                    style: TextStyle(
                      color: SafeHerTheme.warningAmber,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Your safety timer expired. Confirm your safety.',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
            if (onCheckinTap != null)
              TextButton(
                onPressed: onCheckinTap,
                child: const Text(
                  'RESPOND',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SafeHerTheme.safeGreenLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: SafeHerTheme.safeGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: SafeHerTheme.safeGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_user_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'STATUS: SAFE',
                  style: TextStyle(
                    color: SafeHerTheme.safeGreen,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasActiveCheckin
                      ? 'Journey timer active in background'
                      : 'SafeHer ready on standby',
                  style: const TextStyle(
                    color: SafeHerTheme.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LocationStatusCard extends StatelessWidget {
  final LocationResult? location;
  final bool isLoading;
  final VoidCallback onRefresh;
  final VoidCallback? onOpenMaps;

  const LocationStatusCard({
    super.key,
    required this.location,
    required this.isLoading,
    required this.onRefresh,
    this.onOpenMaps,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: SafeHerTheme.plumPrimary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'GPS Location Status',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: SafeHerTheme.plumPrimary,
                  ),
                ),
                const Spacer(),
                if (isLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Refresh Location',
                    onPressed: onRefresh,
                  ),
              ],
            ),
            const Divider(height: 18),
            if (location == null) ...[
              const Text(
                'Location has not been checked yet. SafeHer requests GPS coordinates only when needed.',
                style: TextStyle(fontSize: 13, color: SafeHerTheme.textMuted),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.my_location, size: 16),
                label: const Text('Check Current Coordinates'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(38),
                ),
              ),
            ] else if (!location!.isSuccess) ...[
              Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: SafeHerTheme.warningAmber,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      location!.errorMessage ?? 'Location unavailable',
                      style: const TextStyle(
                        fontSize: 13,
                        color: SafeHerTheme.warningAmber,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              if (location!.isPermissionPermanentlyDenied) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => LocationService().openAppSettings(),
                  child: const Text('Open App Settings'),
                ),
              ],
            ] else ...[
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: SafeHerTheme.safeGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'GPS Available (±${location!.accuracy?.toStringAsFixed(1)}m)',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: SafeHerTheme.safeGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Lat: ${location!.latitude?.toStringAsFixed(5)}, Lng: ${location!.longitude?.toStringAsFixed(5)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontFamily: 'monospace',
                  color: SafeHerTheme.textDark,
                ),
              ),
              const SizedBox(height: 10),
              if (onOpenMaps != null && location!.mapsUrl != null)
                InkWell(
                  onTap: onOpenMaps,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.map_outlined,
                          size: 16,
                          color: SafeHerTheme.plumPrimary,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Preview on Google Maps',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: SafeHerTheme.plumPrimary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
