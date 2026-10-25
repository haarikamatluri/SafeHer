import 'dart:async';

import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../models/incident.dart';
import '../services/alert_service.dart';
import '../services/contact_service.dart';
import '../services/incident_service.dart';
import '../utils/constants.dart';

class IncidentScreen extends StatefulWidget {
  const IncidentScreen({super.key});

  @override
  State<IncidentScreen> createState() => _IncidentScreenState();
}

class _IncidentScreenState extends State<IncidentScreen> {
  Timer? _elapsedTimer;
  Duration _elapsed = Duration.zero;
  StreamSubscription? _activeSub;
  Incident? _incident;

  @override
  void initState() {
    super.initState();
    _incident = IncidentService().activeIncident;
    _startTimer();

    _activeSub = IncidentService().activeIncidentStream.listen((inc) {
      if (mounted) {
        setState(() {
          _incident = inc;
        });
        if (inc == null || !inc.isActive) {
          _elapsedTimer?.cancel();
        }
      }
    });
  }

  void _startTimer() {
    if (_incident != null) {
      _elapsed = DateTime.now().difference(_incident!.createdAt);
    }
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_incident != null && _incident!.isActive) {
        setState(() {
          _elapsed = DateTime.now().difference(_incident!.createdAt);
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    _activeSub?.cancel();
    super.dispose();
  }

  String _formatElapsed(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _handleResolve() async {
    if (_incident == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resolve Emergency?'),
        content: const Text(
          'Confirm that you are safe and out of danger. This will mark the incident as resolved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('NOT YET'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: SafeHerTheme.safeGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('I AM SAFE'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await IncidentService().resolveIncident(_incident!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Incident resolved. Glad you are safe!'),
            backgroundColor: SafeHerTheme.safeGreen,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _handleCancel() async {
    if (_incident == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel False Alarm?'),
        content: const Text(
          'Mark this incident as an accidental false alarm? This will cancel active alerts.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('BACK'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: SafeHerTheme.emergencyRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('CANCEL INCIDENT'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await IncidentService().cancelIncident(_incident!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incident cancelled as false alarm.')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_incident == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Emergency Incident')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: SafeHerTheme.safeGreen,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'No Active Incident',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('All systems normal.'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Return to Home'),
              ),
            ],
          ),
        ),
      );
    }

    final primaryContact = ContactService().contacts.isNotEmpty
        ? ContactService().contacts.first
        : null;

    return Scaffold(
      backgroundColor: SafeHerTheme.offWhite,
      appBar: AppBar(
        backgroundColor: SafeHerTheme.emergencyRed,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              'ACTIVE SOS: ${_incident!.shortId}',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status and timer banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: SafeHerTheme.emergencyRedLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: SafeHerTheme.emergencyRed.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'EMERGENCY IN PROGRESS',
                        style: TextStyle(
                          color: SafeHerTheme.emergencyRedDark,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: SafeHerTheme.emergencyRed,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _formatElapsed(_elapsed),
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Incident triggered at ${_incident!.createdAt.toLocal().toString().substring(11, 16)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: SafeHerTheme.textDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Location Box
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(
                          Icons.location_on,
                          color: SafeHerTheme.plumPrimary,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Captured Incident Location',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: SafeHerTheme.plumPrimary,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 18),
                    if (_incident!.hasLocation) ...[
                      Text(
                        'Coordinates: ${_incident!.latitude?.toStringAsFixed(5)}, ${_incident!.longitude?.toStringAsFixed(5)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontFamily: 'monospace',
                        ),
                      ),
                      if (_incident!.locationAccuracy != null)
                        Text(
                          'GPS Accuracy: ±${_incident!.locationAccuracy?.toStringAsFixed(1)} meters',
                          style: const TextStyle(
                            fontSize: 12,
                            color: SafeHerTheme.textMuted,
                          ),
                        ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () {
                          if (_incident!.googleMapsUrl != null) {
                            AlertService().openMapLink(
                              _incident!.googleMapsUrl!,
                            );
                          }
                        },
                        icon: const Icon(Icons.map_outlined, size: 16),
                        label: const Text('Open in Google Maps'),
                      ),
                    ] else ...[
                      const Row(
                        children: [
                          Icon(
                            Icons.location_off,
                            color: SafeHerTheme.warningAmber,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Location was unavailable or permission denied during SOS activation.',
                              style: TextStyle(
                                fontSize: 13,
                                color: SafeHerTheme.warningAmber,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Honest Alert Dispatch Status Audit
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(
                          Icons.notifications_active_outlined,
                          color: SafeHerTheme.plumPrimary,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Alert Delivery Pipeline (Honest Audit)',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: SafeHerTheme.plumPrimary,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 18),
                    _buildStepRow(
                      step: '1',
                      title: 'Incident Record Created',
                      description: _incident!.isSyncedToRemote
                          ? 'Synchronized to Cloud Firestore'
                          : 'Recorded locally in offline storage',
                      isCompleted: true,
                    ),
                    const SizedBox(height: 10),
                    _buildStepRow(
                      step: '2',
                      title: 'Alert Payload Prepared',
                      description:
                          'Map link and emergency text generated for ${ContactService().contacts.length} trusted contacts',
                      isCompleted: true,
                    ),
                    const SizedBox(height: 10),
                    _buildStepRow(
                      step: '3',
                      title: 'Backend SMS Gateway Dispatch',
                      description: 'Simulated / Demo Mode (No paid SMS gateway credentials loaded)',
                      isCompleted: true,
                      isWarning: true,
                    ),
                    const SizedBox(height: 10),
                    _buildStepRow(
                      step: '4',
                      title: 'Carrier Delivery Confirmation',
                      description: 'Unconfirmed (Direct phone call or SMS fallback recommended below)',
                      isCompleted: false,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Immediate Direct Action Buttons
            ElevatedButton.icon(
              onPressed: () => AlertService().launchEmergencyCall(
                AppConstants.defaultEmergencyNumber,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: SafeHerTheme.emergencyRed,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
              icon: const Icon(Icons.call),
              label: const Text('CALL POLICE DISPATCH (112 / 911)'),
            ),
            const SizedBox(height: 10),

            if (primaryContact != null) ...[
              OutlinedButton.icon(
                onPressed: () =>
                    AlertService().launchEmergencyCall(primaryContact.phone),
                icon: const Icon(Icons.phone_in_talk),
                label: Text(
                  'Call ${primaryContact.name} (${primaryContact.relationship})',
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                ),
              ),
              const SizedBox(height: 10),
            ],

            OutlinedButton.icon(
              onPressed: () {
                final phones = ContactService().contacts
                    .map((c) => c.phone)
                    .toList();
                final map = _incident?.googleMapsUrl ?? 'Location unavailable';
                AlertService().launchSmsApp(
                  phoneNumbers: phones,
                  message:
                      'EMERGENCY: SafeHer SOS activated. I need urgent help! My location: $map',
                );
              },
              icon: const Icon(Icons.sms_outlined),
              label: const Text('Open Messaging App with Location Link'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
              ),
            ),
            const SizedBox(height: 24),

            // Resolution Controls
            ElevatedButton(
              onPressed: _handleResolve,
              style: ElevatedButton.styleFrom(
                backgroundColor: SafeHerTheme.safeGreen,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('I AM SAFE — RESOLVE INCIDENT'),
            ),
            const SizedBox(height: 8),

            TextButton(
              onPressed: _handleCancel,
              style: TextButton.styleFrom(
                foregroundColor: SafeHerTheme.emergencyRedDark,
              ),
              child: const Text('CANCEL INCIDENT (False Alarm)'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStepRow({
    required String step,
    required String title,
    required String description,
    required bool isCompleted,
    bool isWarning = false,
  }) {
    Color badgeColor = isCompleted
        ? (isWarning ? SafeHerTheme.warningAmber : SafeHerTheme.safeGreen)
        : Colors.grey;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: badgeColor),
          ),
          child: Center(
            child: Text(
              step,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: badgeColor,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: SafeHerTheme.textDark,
                ),
              ),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: SafeHerTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
