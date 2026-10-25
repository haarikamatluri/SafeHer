import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../models/safe_haven.dart';
import '../../services/safe_haven_service.dart';
import '../../widgets/shared_widgets.dart';

class CommunityReportsScreen extends StatefulWidget {
  const CommunityReportsScreen({super.key});

  @override
  State<CommunityReportsScreen> createState() => _CommunityReportsScreenState();
}

class _CommunityReportsScreenState extends State<CommunityReportsScreen> {
  final SafeHavenService _safeHavenService = SafeHavenService();
  late List<CommunityReport> _reports;

  @override
  void initState() {
    super.initState();
    _reports = _safeHavenService.getCommunityReports();
  }

  void _showAddReportDialog() {
    final titleController = TextEditingController();
    final locationController = TextEditingController();
    final notesController = TextEditingController();
    String selectedCategory = 'lighting';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: SafeHerColors.midnightPurple,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Community Safety Report',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Report Title',
                  hintText: 'e.g. Well lit road, Dark stretch',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locationController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Location / Landmark',
                  hintText: 'e.g. Near Clock Tower, SVU Gate',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'Describe conditions or recommendations...',
                ),
              ),
              const SizedBox(height: 20),
              SafeHerPrimaryButton(
                text: 'Submit Report',
                onPressed: () async {
                  if (titleController.text.trim().isEmpty ||
                      locationController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill all required fields')),
                    );
                    return;
                  }

                  await _safeHavenService.addCommunityReport(
                    title: titleController.text.trim(),
                    locationName: locationController.text.trim(),
                    category: selectedCategory,
                    notes: notesController.text.trim(),
                    latitude: 13.6288,
                    longitude: 79.4192,
                  );

                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                  }
                  if (mounted) {
                    setState(() {
                      _reports = _safeHavenService.getCommunityReports();
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Report submitted for community verification.'),
                        backgroundColor: SafeHerColors.successGreen,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SafeHerColors.midnightPurple,
      appBar: const SafeHerAppBar(
        title: 'Community Reports',
        showBack: true,
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
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  itemCount: _reports.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final report = _reports[index];
                    return _buildReportCard(report);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: SafeHerPrimaryButton(
                  text: 'Add a Report',
                  icon: Icons.add_circle_outline_rounded,
                  onPressed: _showAddReportDialog,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportCard(CommunityReport report) {
    final isVerified = report.isVerified;
    final badgeColor = isVerified
        ? SafeHerColors.successGreen
        : SafeHerColors.warningAmber;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SafeHerColors.plumCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SafeHerColors.darkBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isVerified ? Icons.shield_rounded : Icons.warning_amber_rounded,
              color: badgeColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${report.locationName} • ${_formatTimeAgo(report.createdAt)}',
                  style: const TextStyle(
                    color: Color(0xFFB4A3C2),
                    fontSize: 12,
                  ),
                ),
                if (report.notes != null && report.notes!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    report.notes!,
                    style: const TextStyle(
                      color: Color(0xFFC7B8D6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: badgeColor, width: 0.8),
            ),
            child: Text(
              isVerified ? 'Verified' : 'Unverified',
              style: TextStyle(
                color: badgeColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inHours < 1) return 'Just now';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays == 1) return '1 day ago';
    return '${diff.inDays} days ago';
  }
}
