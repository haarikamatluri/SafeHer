import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app/routes.dart';
import '../app/theme.dart';
import '../models/incident.dart';
import '../services/alert_service.dart';
import '../services/contact_service.dart';
import '../services/incident_service.dart';
import '../services/live_tracking_service.dart';
import '../utils/constants.dart';
import '../widgets/shared_widgets.dart';

class SosSentScreen extends StatefulWidget {
  const SosSentScreen({super.key});

  @override
  State<SosSentScreen> createState() => _SosSentScreenState();
}

class _SosSentScreenState extends State<SosSentScreen> {
  bool _isRetrying = false;

  Future<void> _retryDispatch() async {
    final activeInc = IncidentService().activeIncident;
    if (activeInc == null) return;

    setState(() => _isRetrying = true);
    try {
      final result = await IncidentService().retryAlertDispatch();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.statusMessage),
            backgroundColor:
                result.status == AlertDeliveryStatus.deliveredConfirmed
                    ? SafeHerColors.successGreen
                    : SafeHerColors.warningAmber,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Retry error: $e'),
            backgroundColor: SafeHerColors.emergencyRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRetrying = false);
      }
    }
  }

  Future<void> _resolveIncident() async {
    final activeInc = IncidentService().activeIncident;
    if (activeInc == null) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.home,
        (route) => false,
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resolve Emergency?'),
        content: const Text(
          'Confirm that you are safe and out of danger. This will stop location sharing and update the incident status to "Resolved Safely".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('NOT YET'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: SafeHerColors.successGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('I AM SAFE'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await IncidentService().resolveIncident(activeInc.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Incident resolved safely. Location sharing stopped.'),
            backgroundColor: SafeHerColors.successGreen,
          ),
        );
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.home,
          (route) => false,
        );
      }
    }
  }

  Future<void> _cancelFalseAlarm() async {
    final activeInc = IncidentService().activeIncident;
    if (activeInc == null) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel False Alarm?'),
        content: const Text(
          'Was this an accidental activation? This will stop tracking and mark the incident as cancelled.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('NO, KEEP ACTIVE'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
            ),
            child: const Text('CANCEL SOS'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await IncidentService().cancelIncident(activeInc.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SOS cancelled. Marked as false alarm.'),
            backgroundColor: SafeHerColors.warningAmber,
          ),
        );
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Incident?>(
      stream: IncidentService().activeIncidentStream,
      initialData: IncidentService().activeIncident,
      builder: (context, snapshot) {
        final activeInc = snapshot.data ?? IncidentService().activeIncident;
        final contactsCount = ContactService().contacts
            .where((c) => c.isAuthorized)
            .length;
        final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
        final timeStr = activeInc != null
            ? dateFormat.format(activeInc.createdAt.toLocal())
            : dateFormat.format(DateTime.now());

        // Determine truthful location freshness description
        String locFreshnessText;
        Color locFreshnessColor;
        if (activeInc != null && activeInc.hasLocation) {
          final acc = activeInc.locationAccuracy != null
              ? '±${activeInc.locationAccuracy!.toStringAsFixed(1)}m'
              : '±?m';
          if (activeInc.locationSource == 'fresh_gps') {
            locFreshnessText = 'Fresh GPS fix ($acc)';
            locFreshnessColor = SafeHerColors.successGreen;
          } else if (activeInc.locationSource == 'cached') {
            final ageSec = activeInc.locationAgeSeconds ?? 0;
            final ageStr = ageSec < 60 ? '${ageSec}s ago' : '${ageSec ~/ 60}m ago';
            locFreshnessText = 'Last known cached position ($ageStr, $acc)';
            locFreshnessColor = const Color(0xFFFFA000);
          } else {
            locFreshnessText = 'Coordinates recorded ($acc)';
            locFreshnessColor = SafeHerColors.successGreen;
          }
        } else {
          locFreshnessText = 'Location unavailable (GPS off or denied)';
          locFreshnessColor = const Color(0xFFE53935);
        }

        final summary = activeInc?.deliverySummary;
        final recipientResults = activeInc?.recipientResults ?? [];
        final hasFailedRecipients = summary != null &&
            summary['failedCount'] is num &&
            (summary['failedCount'] as num) > 0;
        final isAllSucceeded = summary != null &&
            summary['sentToNetworkCount'] is num &&
            (summary['sentToNetworkCount'] as num) > 0 &&
            !hasFailedRecipients;

        return Scaffold(
          backgroundColor: SafeHerColors.surfaceWhite,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // Status Icon Badge
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: isAllSucceeded
                          ? SafeHerColors.successGreen
                          : const Color(0xFFFFA000),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isAllSucceeded
                                  ? SafeHerColors.successGreen
                                  : const Color(0xFFFFA000))
                              .withValues(alpha: 0.3),
                          blurRadius: 18,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: Icon(
                      isAllSucceeded
                          ? Icons.check_rounded
                          : Icons.priority_high_rounded,
                      color: Colors.white,
                      size: 44,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Heading
                  Text(
                    isAllSucceeded ? 'SOS Alert Dispatched' : 'SOS Alert Active',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: SafeHerColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 6),

                  Text(
                    isAllSucceeded
                        ? 'Automated emergency SMS accepted by mobile carrier radio.'
                        : (hasFailedRecipients
                            ? 'Partial alert dispatch failure. Review recipients below.'
                            : 'Emergency incident created. Tracking stream active.'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: SafeHerColors.secondaryText,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // "View Live Location" Button
                  SafeHerPrimaryButton(
                    text: 'View Live Location Sharing',
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.locationSharing);
                    },
                  ),
                  const SizedBox(height: 20),

                  // "Incident Details" Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: SafeHerColors.softPinkSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: SafeHerColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Incident Details',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: SafeHerColors.primaryText,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0x22E53935),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                activeInc?.shortId ?? 'INCIDENT',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFE53935),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        _buildDetailRow('Time', timeStr),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Location',
                              style: TextStyle(
                                fontSize: 13.5,
                                color: SafeHerColors.secondaryText,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                locFreshnessText,
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: locFreshnessColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Live Tracking Status Row
                        StreamBuilder<LiveTrackingState>(
                          stream: LiveTrackingService().stateStream,
                          initialData: LiveTrackingService().currentState,
                          builder: (context, trackSnap) {
                            final state = trackSnap.data ?? LiveTrackingService().currentState;
                            String trackLabel;
                            Color trackColor;

                            if (state.isTrackingActive) {
                              if (state.isStale) {
                                trackLabel = 'Stale signal (>35s)';
                                trackColor = const Color(0xFFFFA000);
                              } else {
                                trackLabel = 'Active (Live streaming)';
                                trackColor = SafeHerColors.successGreen;
                              }
                            } else if (state.isServiceDisabled) {
                              trackLabel = 'Failed (GPS disabled)';
                              trackColor = const Color(0xFFE53935);
                            } else if (state.isPermissionDenied) {
                              trackLabel = 'Failed (Permission denied)';
                              trackColor = const Color(0xFFE53935);
                            } else {
                              trackLabel = 'Starting service...';
                              trackColor = const Color(0xFF7E6F88);
                            }

                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Live Tracking',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    color: SafeHerColors.secondaryText,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: trackColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      trackLabel,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: trackColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        _buildDetailRow(
                          'Authorized Contacts',
                          contactsCount > 0
                              ? '$contactsCount contact(s)'
                              : '0 contacts (None configured)',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Per-Contact Delivery Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: SafeHerColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'SMS Recipients Status',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: SafeHerColors.primaryText,
                              ),
                            ),
                            if (summary != null)
                              Text(
                                '${summary['sentToNetworkCount'] ?? 0}/${summary['eligibleCount'] ?? 0} Accepted',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: (summary['sentToNetworkCount'] ?? 0) > 0
                                      ? SafeHerColors.successGreen
                                      : const Color(0xFFE53935),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (recipientResults.isNotEmpty) ...[
                          for (final item in recipientResults)
                            _buildRecipientRow(item),
                        ] else ...[
                          const Text(
                            'No recipient dispatch results recorded.',
                            style: TextStyle(
                              fontSize: 13,
                              color: SafeHerColors.secondaryText,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Emergency Call & Fallbacks
                  Column(
                    children: [
                      // Retry Button if any failed
                      if (hasFailedRecipients || !isAllSucceeded)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: _isRetrying ? null : _retryDispatch,
                              icon: _isRetrying
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.refresh_rounded, size: 20),
                              label: Text(
                                _isRetrying
                                    ? 'Retrying SMS Dispatch...'
                                    : 'Retry Sending SMS to Failed Contacts',
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: SafeHerColors.primaryRose,
                                side: const BorderSide(
                                  color: SafeHerColors.primaryRose,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Call Emergency Helpline (112)
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            AlertService().launchEmergencyCall(
                              AppConstants.defaultEmergencyNumber,
                            );
                          },
                          icon: const Icon(
                            Icons.phone_in_talk,
                            color: Colors.white,
                            size: 20,
                          ),
                          label: const Text(
                            'Direct Dial Emergency Helpline (112)',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD32F2F),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Manual SMS App Fallback
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            final phones = ContactService().contacts
                                .where((c) => c.isAuthorized)
                                .map((c) => c.phone)
                                .toList();
                            final link =
                                activeInc?.googleMapsUrl ?? 'Location unavailable';
                            AlertService().launchSmsApp(
                              phoneNumbers: phones,
                              message:
                                  'EMERGENCY SafeHer Alert! Live location: $link (Incident: ${activeInc?.shortId})',
                            );
                          },
                          icon: const Icon(Icons.sms_outlined, size: 20),
                          label: const Text('Open External SMS App (Manual Fallback)'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: SafeHerColors.secondaryText,
                            side: const BorderSide(color: SafeHerColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // "I Am Safe" Button
                      SafeHerPrimaryButton(
                        text: 'I Am Safe — Resolve Emergency',
                        onPressed: _resolveIncident,
                      ),
                      const SizedBox(height: 8),

                      // Cancel False Alarm Button
                      OutlinedButton(
                        onPressed: _cancelFalseAlarm,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFE53935),
                          side: const BorderSide(color: Color(0xFFE53935)),
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Cancel False Alarm',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 8),

                      SafeHerSecondaryButton(
                        text: 'Return to Home',
                        onPressed: () {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            AppRoutes.home,
                            (route) => false,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecipientRow(dynamic item) {
    if (item is! Map) return const SizedBox.shrink();
    final name = item['name']?.toString() ?? 'Contact';
    final phone = item['phone']?.toString() ?? '';
    final status = item['status']?.toString() ?? 'unknown';
    final error = item['error']?.toString();
    final isOk = status == 'sent_to_network' || status == 'sent_unacknowledged' || status == 'simulated_web';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isOk ? Icons.check_circle_rounded : Icons.error_outline_rounded,
            size: 20,
            color: isOk ? SafeHerColors.successGreen : const Color(0xFFE53935),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$name ($phone)',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: SafeHerColors.primaryText,
                  ),
                ),
                Text(
                  isOk
                      ? 'SMS accepted by cellular radio'
                      : (error ?? 'SMS dispatch failed ($status)'),
                  style: TextStyle(
                    fontSize: 12,
                    color: isOk ? SafeHerColors.successGreen : const Color(0xFFE53935),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13.5,
            color: SafeHerColors.secondaryText,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: SafeHerColors.primaryText,
          ),
        ),
      ],
    );
  }
}
