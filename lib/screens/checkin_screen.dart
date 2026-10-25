import 'package:flutter/material.dart';

import '../app/routes.dart';
import '../app/theme.dart';
import '../models/checkin.dart';
import '../services/checkin_service.dart';
import '../services/incident_service.dart';
import '../utils/constants.dart';
import '../widgets/shared_widgets.dart';

class CheckinScreen extends StatefulWidget {
  const CheckinScreen({super.key});

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  int _selectedMinutes = 15;
  final List<int> _presetMinutes = [5, 15, 30, 60];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SafeHerColors.surfaceWhite,
      appBar: const SafeHerAppBar(title: 'Safety Check-in', isDark: true),
      body: StreamBuilder<SafetyCheckin?>(
        stream: CheckinService().checkinStream,
        initialData: CheckinService().activeCheckin,
        builder: (context, snapshot) {
          final checkin = snapshot.data;
          final hasActive = checkin != null && checkin.isActive;
          final isMissed =
              checkin != null && checkin.status == CheckinStatus.missed;

          if (isMissed) {
            return _buildMissedView(context, checkin);
          }

          return _buildCheckinContent(context, checkin, hasActive);
        },
      ),
    );
  }

  Widget _buildCheckinContent(
    BuildContext context,
    SafetyCheckin? checkin,
    bool hasActive,
  ) {
    final rem =
        checkin?.remainingDuration ?? Duration(minutes: _selectedMinutes);
    final minutes = rem.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = rem.inSeconds.remainder(60).toString().padLeft(2, '0');
    final timeStr = '$minutes:$seconds';
    final totalMinutes = checkin?.durationMinutes ?? _selectedMinutes;
    final progress = hasActive ? checkin!.progressFraction : 0.0;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            const Spacer(),

            // Circular Countdown Ring matching Screen 11
            SizedBox(
              width: 230,
              height: 230,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background gray track
                  SizedBox(
                    width: 230,
                    height: 230,
                    child: CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 8,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFF3EAF0),
                      ),
                    ),
                  ),

                  // Active Pink Progress Stroke
                  SizedBox(
                    width: 230,
                    height: 230,
                    child: CircularProgressIndicator(
                      value: hasActive ? (1.0 - progress) : 0.75,
                      strokeWidth: 8,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        SafeHerColors.primaryRose,
                      ),
                      backgroundColor: Colors.transparent,
                    ),
                  ),

                  // Inside display
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Time Left',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: SafeHerColors.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeStr,
                        style: const TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                          color: SafeHerColors.primaryText,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'of $totalMinutes minutes',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: SafeHerColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Preset Buttons: 5 min, 15 min, 30 min, 60 min matching Screen 11
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _presetMinutes.map((mins) {
                final isSelected = !hasActive
                    ? _selectedMinutes == mins
                    : totalMinutes == mins;

                return GestureDetector(
                  onTap: hasActive
                      ? null
                      : () {
                          setState(() {
                            _selectedMinutes = mins;
                          });
                        },
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: isSelected ? SafeHerColors.palePink : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? SafeHerColors.primaryRose
                            : SafeHerColors.border,
                        width: isSelected ? 1.8 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$mins',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isSelected
                                ? SafeHerColors.primaryRose
                                : SafeHerColors.primaryText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'min',
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected
                                ? SafeHerColors.primaryRose
                                : SafeHerColors.secondaryText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Explanatory Card with Clock Icon matching Screen 11
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: SafeHerColors.softPinkSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: SafeHerColors.border),
              ),
              child: Row(
                children: const [
                  Icon(
                    Icons.schedule_rounded,
                    color: SafeHerColors.primaryRose,
                    size: 22,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'We\'ll notify your contacts if you don\'t check in on time.',
                      style: TextStyle(
                        fontSize: 13,
                        color: SafeHerColors.primaryText,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // End Check-in or Start Check-in Action
            SafeHerPrimaryButton(
              text: hasActive ? 'End Check-in' : 'Start Check-in',
              onPressed: () async {
                if (hasActive) {
                  await CheckinService().markSafe();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Check-in ended. Marked safe!'),
                        backgroundColor: SafeHerColors.successGreen,
                      ),
                    );
                  }
                } else {
                  await CheckinService().startCheckin(
                    title: 'Journey Check-in',
                    durationMinutes: _selectedMinutes,
                  );
                }
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildMissedView(BuildContext context, SafetyCheckin checkin) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: SafeHerColors.emergencyRedLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.timer_off_outlined,
              size: 56,
              color: SafeHerColors.emergencyRed,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Check-in Expired',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: SafeHerColors.emergencyRed,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your safety timer finished without confirmation. Would you like to activate Emergency SOS or confirm your safety?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: SafeHerColors.secondaryText),
          ),
          const SizedBox(height: 28),
          SafeHerPrimaryButton(
            text: 'ACTIVATE SOS NOW',
            onPressed: () async {
              await IncidentService().triggerSos(
                source: 'checkin_missed',
                requestLocation: true,
              );
              await CheckinService().cancelCheckin();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.sosSent);
              }
            },
          ),
          const SizedBox(height: 12),
          SafeHerSecondaryButton(
            text: 'I Am Safe (Dismiss)',
            onPressed: () async {
              await CheckinService().markSafe();
            },
          ),
        ],
      ),
    );
  }
}
