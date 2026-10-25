import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app/routes.dart';
import '../app/theme.dart';
import '../services/alert_service.dart';
import '../services/contact_service.dart';
import '../services/incident_service.dart';
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
      final contacts = ContactService().contacts;
      final result = await AlertService().dispatchEmergencyAlert(
        incident: activeInc,
        contacts: contacts,
      );

      // Update in memory and cache
      IncidentService().cancelIncident(activeInc.id); // Reset state
      await IncidentService().triggerSos(
        source: 'sos_retry',
        requestLocation: false,
      );

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
          'Confirm that you are safe and out of danger. This will update the incident status to "Resolved Safely". All audit attempt history is preserved.',
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
            content: Text('Incident resolved safely. Glad you are safe!'),
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

  @override
  Widget build(BuildContext context) {
    final activeInc = IncidentService().activeIncident;
    final contactsCount = ContactService().contacts
        .where((c) => c.isAuthorized)
        .length;
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final timeStr = activeInc != null
        ? dateFormat.format(activeInc.createdAt.toLocal())
        : dateFormat.format(DateTime.now());

    final locStr = activeInc != null && activeInc.hasLocation
        ? 'Lat: ${activeInc.latitude?.toStringAsFixed(4)}, Lng: ${activeInc.longitude?.toStringAsFixed(4)} (±${activeInc.locationAccuracy?.toStringAsFixed(1) ?? '10'}m)'
        : 'Location unavailable (GPS denied/disabled)';

    final isDelivered =
        activeInc?.alertStatus == AlertDeliveryStatus.deliveredConfirmed;
    final summary = activeInc?.deliverySummary;

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
                  color: isDelivered
                      ? SafeHerColors.successGreen
                      : const Color(0xFFFFA000),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color:
                          (isDelivered
                                  ? SafeHerColors.successGreen
                                  : const Color(0xFFFFA000))
                              .withValues(alpha: 0.3),
                      blurRadius: 18,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Icon(
                  isDelivered
                      ? Icons.check_rounded
                      : Icons.priority_high_rounded,
                  color: Colors.white,
                  size: 44,
                ),
              ),
              const SizedBox(height: 16),

              // Heading
              Text(
                isDelivered ? 'SOS Dispatched!' : 'SOS Alert Active',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: SafeHerColors.primaryText,
                ),
              ),
              const SizedBox(height: 6),

              Text(
                isDelivered
                    ? 'Automated delivery was acknowledged by backend gateway.'
                    : 'Emergency incident created. Server-side carrier dispatch status below.',
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
                text: 'View Live Location',
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.locationSharing);
                },
              ),
              const SizedBox(height: 20),

              // "Alert Details" Card
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
                    _buildDetailRow('Location', locStr),
                    const SizedBox(height: 10),
                    _buildDetailRow(
                      'Authorized Contacts',
                      contactsCount > 0
                          ? '$contactsCount contact(s)'
                          : '0 contacts (None configured)',
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Incident State',
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
                              decoration: const BoxDecoration(
                                color: SafeHerColors.successGreen,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Active Emergency',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: SafeHerColors.successGreen,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Multi-Channel Delivery Status Card
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
                    const Text(
                      'Delivery Channels Breakdown',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: SafeHerColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildChannelRow(
                      icon: Icons.sms_outlined,
                      channel:
                          summary != null &&
                              summary['sms'] is Map &&
                              summary['sms']['provider'] != null
                          ? summary['sms']['provider'].toString()
                          : 'Device SIM (100% Free SMS)',
                      statusText: summary != null && summary['sms'] is Map
                          ? 'Succeeded: ${summary['sms']['succeeded']}, Failed: ${summary['sms']['failed']}'
                          : (isDelivered
                                ? 'Dispatched'
                                : 'Awaiting SMS dispatch'),
                      isOk:
                          (summary != null &&
                              summary['sms'] is Map &&
                              (summary['sms']['succeeded'] as num? ?? 0) > 0) ||
                          isDelivered,
                    ),
                    const SizedBox(height: 10),
                    _buildChannelRow(
                      icon: Icons.notifications_active_outlined,
                      channel: 'FCM Push Notification',
                      statusText:
                          summary != null &&
                              summary['push'] is Map &&
                              (summary['push']['succeeded'] as num? ?? 0) > 0
                          ? 'Sent to: ${summary['push']['succeeded']} device(s)'
                          : 'Zero-cost Free Mode (Direct SIM active)',
                      isOk:
                          summary != null &&
                          summary['push'] is Map &&
                          (summary['push']['succeeded'] as num? ?? 0) > 0,
                    ),
                    const SizedBox(height: 10),
                    _buildChannelRow(
                      icon: Icons.chat_bubble_outline_rounded,
                      channel: 'WhatsApp Business API',
                      statusText:
                          summary != null &&
                              summary['whatsapp'] is Map &&
                              (summary['whatsapp']['succeeded'] as num? ?? 0) >
                                  0
                          ? 'Succeeded: ${summary['whatsapp']['succeeded']}, Failed: ${summary['whatsapp']['failed']}'
                          : 'Zero-cost Free Mode (Direct SIM active)',
                      isOk:
                          summary != null &&
                          summary['whatsapp'] is Map &&
                          (summary['whatsapp']['succeeded'] as num? ?? 0) > 0,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Emergency Call & Native Fallbacks
              Column(
                children: [
                  // Retry Button
                  if (!isDelivered)
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
                                ? 'Retrying Dispatch...'
                                : 'Retry Backend Dispatch',
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

                  // Call Emergency Number (112)
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
                        'Direct Dial Helpline 112 (Manual Fallback)',
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

                  // Send Native SMS to Contacts
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
                              'EMERGENCY SafeHer Alert! Live location: $link (Incident ${activeInc?.shortId})',
                        );
                      },
                      icon: const Icon(Icons.sms_outlined, size: 20),
                      label: const Text('Send Native SMS to Trusted Contacts'),
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
                    text: 'I Am Safe — Resolve Alert',
                    onPressed: _resolveIncident,
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
  }

  Widget _buildChannelRow({
    required IconData icon,
    required String channel,
    required String statusText,
    required bool isOk,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: isOk ? SafeHerColors.successGreen : const Color(0xFF7E6F88),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                channel,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: SafeHerColors.primaryText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 12,
                  color: isOk
                      ? SafeHerColors.successGreen
                      : const Color(0xFF9E8EAA),
                ),
              ),
            ],
          ),
        ),
      ],
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
