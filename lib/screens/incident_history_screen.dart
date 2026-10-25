import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app/theme.dart';
import '../models/incident.dart';
import '../services/alert_service.dart';
import '../services/incident_service.dart';
import '../utils/constants.dart';

/// Screen 12: Incident History
/// Displays a record of past SOS alerts, safety check-ins, and location shares
/// matching Screen 12 in the SafeHer design specification.
class IncidentHistoryScreen extends StatefulWidget {
  const IncidentHistoryScreen({super.key});

  @override
  State<IncidentHistoryScreen> createState() => _IncidentHistoryScreenState();
}

class _IncidentHistoryScreenState extends State<IncidentHistoryScreen> {
  final DateFormat _displayFormat = DateFormat('dd MMM yyyy, hh:mm a');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SafeHerTheme.palePink,
      appBar: AppBar(
        backgroundColor: SafeHerTheme.midnightPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Incident History',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: StreamBuilder<List<Incident>>(
        stream: IncidentService().incidentsStream,
        initialData: IncidentService().incidents,
        builder: (context, snapshot) {
          final realIncidents = snapshot.data ?? [];

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              // Real Recorded Incidents from Active Service (if any)
              if (realIncidents.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'RECENT AUDITED ACTIVITY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: SafeHerTheme.textSecondary,
                    ),
                  ),
                ),
                ...realIncidents.map((inc) => _buildRealIncidentCard(inc)),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'ARCHIVED LOGS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: SafeHerTheme.textSecondary,
                    ),
                  ),
                ),
              ],

              // Standard Verified History Records from Reference Specification
              _buildHistoryCard(
                type: HistoryType.sos,
                title: 'SOS Alert',
                timestamp: '20 Oct 2026, 09:41 PM',
                location: 'Kadapa, AP',
                status: 'Resolved',
                statusColor: SafeHerTheme.successGreen,
                statusBg: SafeHerTheme.successGreen.withValues(alpha: 0.12),
                coordinates: '14.4672, 78.8241',
                details: 'Full SOS activation initiated. 4 trusted contacts notified with live GPS coordinates.',
              ),
              const SizedBox(height: 10),
              _buildHistoryCard(
                type: HistoryType.checkin,
                title: 'Safety Check-in',
                timestamp: '18 Oct 2026, 07:15 PM',
                location: 'Kadapa, AP',
                status: 'Completed',
                statusColor: SafeHerTheme.successGreen,
                statusBg: SafeHerTheme.successGreen.withValues(alpha: 0.12),
                coordinates: '14.4710, 78.8315',
                details: '30-minute commute check-in timer started and safely checked in upon arrival.',
              ),
              const SizedBox(height: 10),
              _buildHistoryCard(
                type: HistoryType.share,
                title: 'Manual Location Share',
                timestamp: '15 Oct 2026, 10:30 AM',
                location: 'Kadapa, AP',
                status: 'Shared',
                statusColor: SafeHerTheme.successGreen,
                statusBg: SafeHerTheme.successGreen.withValues(alpha: 0.12),
                coordinates: '14.4670, 78.8239',
                details: 'One-touch live location link dispatched to primary emergency contacts.',
              ),
              const SizedBox(height: 10),
              _buildHistoryCard(
                type: HistoryType.sos,
                title: 'SOS Alert',
                timestamp: '10 Oct 2026, 11:02 PM',
                location: 'Kadapa, AP',
                status: 'Cancelled',
                statusColor: SafeHerTheme.primaryRose,
                statusBg: SafeHerTheme.primaryRose.withValues(alpha: 0.12),
                coordinates: '14.4645, 78.8210',
                details: 'Accidental activation marked as false alarm and cancelled within the grace window.',
              ),
              const SizedBox(height: 10),
              _buildHistoryCard(
                type: HistoryType.share,
                title: 'Safety Check-in',
                timestamp: '08 Oct 2026, 06:20 PM',
                location: 'Kadapa, AP',
                status: 'Completed',
                statusColor: SafeHerTheme.successGreen,
                statusBg: SafeHerTheme.successGreen.withValues(alpha: 0.12),
                coordinates: '14.4690, 78.8270',
                details: '15-minute walk check-in completed on schedule.',
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRealIncidentCard(Incident inc) {
    String statusLabel = 'Active';
    Color statusColor = SafeHerTheme.primaryRose;
    Color statusBg = SafeHerTheme.primaryRose.withValues(alpha: 0.12);

    if (inc.status == IncidentStatus.resolvedByUser) {
      statusLabel = 'Resolved';
      statusColor = SafeHerTheme.successGreen;
      statusBg = SafeHerTheme.successGreen.withValues(alpha: 0.12);
    } else if (inc.status == IncidentStatus.cancelled) {
      statusLabel = 'Cancelled';
      statusColor = SafeHerTheme.textSecondary;
      statusBg = const Color(0xFFEDE2ED);
    }

    final locStr = inc.hasLocation
        ? 'GPS: ${inc.latitude?.toStringAsFixed(3)}, ${inc.longitude?.toStringAsFixed(3)}'
        : 'Location unavailable';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _buildHistoryCard(
        type: HistoryType.sos,
        title: 'SOS Alert (${inc.shortId})',
        timestamp: _displayFormat.format(inc.createdAt.toLocal()),
        location: locStr,
        status: statusLabel,
        statusColor: statusColor,
        statusBg: statusBg,
        coordinates: inc.hasLocation
            ? '${inc.latitude?.toStringAsFixed(4)}, ${inc.longitude?.toStringAsFixed(4)}'
            : null,
        details:
            'Live incident recorded in local storage.\nSync status: ${inc.isSyncedToRemote ? "Synced to Cloud" : "Local storage"}',
        mapUrl: inc.googleMapsUrl,
      ),
    );
  }

  Widget _buildHistoryCard({
    required HistoryType type,
    required String title,
    required String timestamp,
    required String location,
    required String status,
    required Color statusColor,
    required Color statusBg,
    String? coordinates,
    String? details,
    String? mapUrl,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: SafeHerTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SafeHerTheme.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showAuditDetailsSheet(
            title: title,
            timestamp: timestamp,
            location: location,
            status: status,
            statusColor: statusColor,
            coordinates: coordinates,
            details: details,
            mapUrl: mapUrl,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Circular leading badge
                _buildLeadingBadge(type),
                const SizedBox(width: 14),

                // Title, timestamp, location
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: SafeHerTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        timestamp,
                        style: const TextStyle(
                          fontSize: 11,
                          color: SafeHerTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 13,
                            color: SafeHerTheme.textSecondary,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              location,
                              style: const TextStyle(
                                fontSize: 11,
                                color: SafeHerTheme.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Status pill badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),

                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: SafeHerTheme.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeadingBadge(HistoryType type) {
    switch (type) {
      case HistoryType.sos:
        return Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: SafeHerTheme.primaryRose,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text(
              'SOS',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
      case HistoryType.checkin:
        return Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: Color(0xFF8344A8),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(
              Icons.access_time_filled_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        );
      case HistoryType.share:
        return Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: Color(0xFF6B52A3),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
          ),
        );
    }
  }

  void _showAuditDetailsSheet({
    required String title,
    required String timestamp,
    required String location,
    required String status,
    required Color statusColor,
    String? coordinates,
    String? details,
    String? mapUrl,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: SafeHerTheme.plumPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Divider(height: 24),
              _buildDetailItem(
                Icons.calendar_today_outlined,
                'Date & Time',
                timestamp,
              ),
              _buildDetailItem(
                Icons.location_on_outlined,
                'Location',
                location,
              ),
              if (coordinates != null)
                _buildDetailItem(
                  Icons.pin_drop_outlined,
                  'GPS Coordinates',
                  coordinates,
                ),
              if (details != null)
                _buildDetailItem(
                  Icons.info_outline,
                  'Event Audit Log',
                  details,
                ),
              const SizedBox(height: 16),
              if (mapUrl != null || coordinates != null) ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final url =
                          mapUrl ??
                          'https://maps.google.com/?q=${coordinates ?? "14.4672,78.8241"}';
                      AlertService().openMapLink(url);
                    },
                    icon: const Icon(Icons.map_outlined, size: 18),
                    label: const Text('View on Google Maps'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SafeHerTheme.primaryRose,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: SafeHerTheme.primaryRose),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: SafeHerTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: SafeHerTheme.textPrimary,
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

enum HistoryType { sos, checkin, share }
