import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../services/safe_haven_service.dart';
import '../../widgets/shared_widgets.dart';

class EmergencyServicesScreen extends StatelessWidget {
  const EmergencyServicesScreen({super.key});

  Future<void> _dialNumber(BuildContext context, String number, String label) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SafeHerColors.midnightPurple,
        title: Text('Call $label ($number)?',
            style: const TextStyle(color: Colors.white)),
        content: Text(
          'This will initiate a direct phone call to $label ($number) using your mobile dialer.',
          style: const TextStyle(color: Color(0xFFC7B8D6), fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: SafeHerColors.primaryRose,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Call Now'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await SafeHavenService().callEmergencyNumber(number);
      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open phone dialer for $number')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = SafeHavenService().getEmergencyServices();

    final boxColors = [
      const Color(0xFFFF9800), // 112 Orange
      const Color(0xFF9C27B0), // 1091 Purple
      const Color(0xFF2196F3), // 100 Blue
      const Color(0xFF00BCD4), // 108 Cyan
      const Color(0xFFE91E63), // 181 Pink
    ];

    return Scaffold(
      backgroundColor: SafeHerColors.midnightPurple,
      appBar: const SafeHerAppBar(
        title: 'Emergency Services',
        showBack: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: SafeHerColors.darkBackgroundGradient,
        ),
        child: SafeArea(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            itemCount: services.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final service = services[index];
              final color = boxColors[index % boxColors.length];

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: SafeHerColors.plumCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: SafeHerColors.darkBorder),
                ),
                child: Row(
                  children: [
                    // Distinct Color Number Box
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: color.withValues(alpha: 0.6),
                          width: 1.2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          service.number,
                          style: TextStyle(
                            color: color,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            service.subtitle,
                            style: const TextStyle(
                              color: Color(0xFFB4A3C2),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Call Button
                    InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () =>
                          _dialNumber(context, service.number, service.subtitle),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: SafeHerColors.pinkButtonGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: SafeHerColors.primaryRose.withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.call_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
