import '../utils/constants.dart';

class SafetyCheckin {
  final String id;
  final String userId;
  final String title;
  final int durationMinutes;
  final DateTime deadline;
  final DateTime createdAt;
  final CheckinStatus status;
  final bool isSyncedToRemote;

  const SafetyCheckin({
    required this.id,
    required this.userId,
    required this.title,
    required this.durationMinutes,
    required this.deadline,
    required this.createdAt,
    this.status = CheckinStatus.active,
    this.isSyncedToRemote = false,
  });

  bool get isActive => status == CheckinStatus.active;

  bool get isExpired => isActive && DateTime.now().isAfter(deadline);

  Duration get remainingDuration {
    final diff = deadline.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  double get progressFraction {
    final totalSeconds = durationMinutes * 60;
    if (totalSeconds <= 0) return 1.0;
    final remainingSecs = remainingDuration.inSeconds;
    final elapsedSecs = totalSeconds - remainingSecs;
    final frac = elapsedSecs / totalSeconds;
    return frac.clamp(0.0, 1.0);
  }

  SafetyCheckin copyWith({
    String? id,
    String? userId,
    String? title,
    int? durationMinutes,
    DateTime? deadline,
    DateTime? createdAt,
    CheckinStatus? status,
    bool? isSyncedToRemote,
  }) {
    return SafetyCheckin(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      deadline: deadline ?? this.deadline,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      isSyncedToRemote: isSyncedToRemote ?? this.isSyncedToRemote,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'durationMinutes': durationMinutes,
      'deadline': deadline.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'status': status.value,
      'isSyncedToRemote': isSyncedToRemote,
    };
  }

  factory SafetyCheckin.fromMap(Map<String, dynamic> map, [String? docId]) {
    return SafetyCheckin(
      id: docId ?? map['id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? 'Safety Check-in',
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 15,
      deadline: map['deadline'] != null
          ? DateTime.tryParse(map['deadline'].toString()) ??
                DateTime.now().add(const Duration(minutes: 15))
          : DateTime.now().add(const Duration(minutes: 15)),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      status: CheckinStatus.fromString(map['status']),
      isSyncedToRemote: map['isSyncedToRemote'] ?? false,
    );
  }
}
