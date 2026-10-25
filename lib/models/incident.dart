import 'dart:math';

import '../utils/constants.dart';

class Incident {
  final String id;
  final String userId;
  final IncidentStatus status;
  final String source; // 'sos_button', 'checkin_missed', etc.
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final double? latitude;
  final double? longitude;
  final String? locationAddress;
  final double? locationAccuracy;
  final bool locationSharingEnabled;
  final AlertDeliveryStatus alertStatus;
  final int alertAttemptCount;
  final bool isSyncedToRemote;
  final Map<String, dynamic>? deliverySummary;

  const Incident({
    required this.id,
    required this.userId,
    required this.status,
    required this.source,
    required this.createdAt,
    this.resolvedAt,
    this.latitude,
    this.longitude,
    this.locationAddress,
    this.locationAccuracy,
    this.locationSharingEnabled = true,
    this.alertStatus = AlertDeliveryStatus.notConfigured,
    this.alertAttemptCount = 0,
    this.isSyncedToRemote = false,
    this.deliverySummary,
  });

  bool get isActive => status == IncidentStatus.active;

  bool get hasLocation => latitude != null && longitude != null;

  String? get googleMapsUrl {
    if (!hasLocation) return null;
    return 'https://maps.google.com/?q=$latitude,$longitude';
  }

  String get shortId {
    final clean = id.replaceAll('-', '');
    final len = min(6, clean.length);
    return 'INC-${clean.substring(0, len).toUpperCase()}';
  }

  /// Verifies state machine transitions:
  /// active -> resolvedByUser (valid)
  /// active -> cancelled (valid)
  /// resolvedByUser -> anything (invalid)
  /// cancelled -> anything (invalid)
  bool canTransitionTo(IncidentStatus newStatus) {
    if (status == IncidentStatus.active) {
      return newStatus == IncidentStatus.resolvedByUser ||
          newStatus == IncidentStatus.cancelled;
    }
    return false;
  }

  Incident copyWith({
    String? id,
    String? userId,
    IncidentStatus? status,
    String? source,
    DateTime? createdAt,
    DateTime? resolvedAt,
    double? latitude,
    double? longitude,
    String? locationAddress,
    double? locationAccuracy,
    bool? locationSharingEnabled,
    AlertDeliveryStatus? alertStatus,
    int? alertAttemptCount,
    bool? isSyncedToRemote,
    Map<String, dynamic>? deliverySummary,
  }) {
    return Incident(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationAddress: locationAddress ?? this.locationAddress,
      locationAccuracy: locationAccuracy ?? this.locationAccuracy,
      locationSharingEnabled:
          locationSharingEnabled ?? this.locationSharingEnabled,
      alertStatus: alertStatus ?? this.alertStatus,
      alertAttemptCount: alertAttemptCount ?? this.alertAttemptCount,
      isSyncedToRemote: isSyncedToRemote ?? this.isSyncedToRemote,
      deliverySummary: deliverySummary ?? this.deliverySummary,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'status': status.value,
      'source': source,
      'createdAt': createdAt.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'locationAddress': locationAddress,
      'locationAccuracy': locationAccuracy,
      'locationSharingEnabled': locationSharingEnabled,
      'alertStatus': alertStatus.value,
      'alertAttemptCount': alertAttemptCount,
      'isSyncedToRemote': isSyncedToRemote,
      'deliverySummary': deliverySummary,
    };
  }

  factory Incident.fromMap(Map<String, dynamic> map, [String? docId]) {
    return Incident(
      id: docId ?? map['id'] ?? '',
      userId: map['userId'] ?? '',
      status: IncidentStatus.fromString(map['status']),
      source: map['source'] ?? 'sos_button',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      resolvedAt: map['resolvedAt'] != null
          ? DateTime.tryParse(map['resolvedAt'].toString())
          : null,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      locationAddress: map['locationAddress'],
      locationAccuracy: (map['locationAccuracy'] as num?)?.toDouble(),
      locationSharingEnabled: map['locationSharingEnabled'] ?? true,
      alertStatus: AlertDeliveryStatus.fromString(map['alertStatus']),
      alertAttemptCount: (map['alertAttemptCount'] as num?)?.toInt() ?? 0,
      isSyncedToRemote: map['isSyncedToRemote'] ?? false,
      deliverySummary: map['deliverySummary'] is Map
          ? Map<String, dynamic>.from(map['deliverySummary'] as Map)
          : null,
    );
  }
}
