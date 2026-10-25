import 'dart:convert';
import 'package:latlong2/latlong.dart';

enum JourneyStatus {
  planning,
  active,
  checkinDue,
  checkinMissed,
  completed,
  cancelled,
  escalated,
}

enum TravelMode {
  walking,
  bike,
  car,
  bus,
  other,
}

class Journey {
  final String id;
  final String userId;
  final String destinationName;
  final double destinationLat;
  final double destinationLng;
  final String? originName;
  final double? originLat;
  final double? originLng;
  final TravelMode travelMode;
  final DateTime expectedArrivalTime;
  final int checkinIntervalMinutes;
  final int gracePeriodMinutes;
  final List<String> notifyContactIds;
  final List<String> notifyContactNames;
  final List<String> notifyContactPhones;
  final JourneyStatus status;
  final DateTime startedAt;
  final DateTime? completedAt;
  final double totalDistanceKm;
  final int checkinsCompleted;
  final int totalCheckinsExpected;
  final double? lastKnownLat;
  final double? lastKnownLng;
  final DateTime? lastKnownLocationTime;
  final DateTime? lastCheckinPromptAt;
  final DateTime? nextCheckinDueAt;
  final DateTime? missedCheckinAt;
  final bool escalationTriggered;
  final List<List<double>>? routeCoordinates;
  final double? remainingDistanceKm;
  final int? remainingMinutes;
  final bool isOffRoute;
  final bool isRerouting;
  final String? routeSource;

  const Journey({
    required this.id,
    required this.userId,
    required this.destinationName,
    required this.destinationLat,
    required this.destinationLng,
    this.originName,
    this.originLat,
    this.originLng,
    this.travelMode = TravelMode.bike,
    required this.expectedArrivalTime,
    this.checkinIntervalMinutes = 15,
    this.gracePeriodMinutes = 5,
    this.notifyContactIds = const [],
    this.notifyContactNames = const [],
    this.notifyContactPhones = const [],
    this.status = JourneyStatus.planning,
    required this.startedAt,
    this.completedAt,
    this.totalDistanceKm = 22.0,
    this.checkinsCompleted = 0,
    this.totalCheckinsExpected = 6,
    this.lastKnownLat,
    this.lastKnownLng,
    this.lastKnownLocationTime,
    this.lastCheckinPromptAt,
    this.nextCheckinDueAt,
    this.missedCheckinAt,
    this.escalationTriggered = false,
    this.routeCoordinates,
    this.remainingDistanceKm,
    this.remainingMinutes,
    this.isOffRoute = false,
    this.isRerouting = false,
    this.routeSource,
  });

  bool get isActive =>
      status == JourneyStatus.active ||
      status == JourneyStatus.checkinDue ||
      status == JourneyStatus.checkinMissed;

  List<LatLng> get routeLatLngs {
    if (routeCoordinates == null || routeCoordinates!.isEmpty) return const [];
    return routeCoordinates!
        .map((coord) => LatLng(coord[0], coord[1]))
        .toList();
  }

  Journey copyWith({
    String? id,
    String? userId,
    String? destinationName,
    double? destinationLat,
    double? destinationLng,
    String? originName,
    double? originLat,
    double? originLng,
    TravelMode? travelMode,
    DateTime? expectedArrivalTime,
    int? checkinIntervalMinutes,
    int? gracePeriodMinutes,
    List<String>? notifyContactIds,
    List<String>? notifyContactNames,
    List<String>? notifyContactPhones,
    JourneyStatus? status,
    DateTime? startedAt,
    DateTime? completedAt,
    double? totalDistanceKm,
    int? checkinsCompleted,
    int? totalCheckinsExpected,
    double? lastKnownLat,
    double? lastKnownLng,
    DateTime? lastKnownLocationTime,
    DateTime? lastCheckinPromptAt,
    DateTime? nextCheckinDueAt,
    DateTime? missedCheckinAt,
    bool? escalationTriggered,
    List<List<double>>? routeCoordinates,
    double? remainingDistanceKm,
    int? remainingMinutes,
    bool? isOffRoute,
    bool? isRerouting,
    String? routeSource,
  }) {
    return Journey(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      destinationName: destinationName ?? this.destinationName,
      destinationLat: destinationLat ?? this.destinationLat,
      destinationLng: destinationLng ?? this.destinationLng,
      originName: originName ?? this.originName,
      originLat: originLat ?? this.originLat,
      originLng: originLng ?? this.originLng,
      travelMode: travelMode ?? this.travelMode,
      expectedArrivalTime: expectedArrivalTime ?? this.expectedArrivalTime,
      checkinIntervalMinutes:
          checkinIntervalMinutes ?? this.checkinIntervalMinutes,
      gracePeriodMinutes: gracePeriodMinutes ?? this.gracePeriodMinutes,
      notifyContactIds: notifyContactIds ?? this.notifyContactIds,
      notifyContactNames: notifyContactNames ?? this.notifyContactNames,
      notifyContactPhones: notifyContactPhones ?? this.notifyContactPhones,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      totalDistanceKm: totalDistanceKm ?? this.totalDistanceKm,
      checkinsCompleted: checkinsCompleted ?? this.checkinsCompleted,
      totalCheckinsExpected:
          totalCheckinsExpected ?? this.totalCheckinsExpected,
      lastKnownLat: lastKnownLat ?? this.lastKnownLat,
      lastKnownLng: lastKnownLng ?? this.lastKnownLng,
      lastKnownLocationTime:
          lastKnownLocationTime ?? this.lastKnownLocationTime,
      lastCheckinPromptAt: lastCheckinPromptAt ?? this.lastCheckinPromptAt,
      nextCheckinDueAt: nextCheckinDueAt ?? this.nextCheckinDueAt,
      missedCheckinAt: missedCheckinAt ?? this.missedCheckinAt,
      escalationTriggered: escalationTriggered ?? this.escalationTriggered,
      routeCoordinates: routeCoordinates ?? this.routeCoordinates,
      remainingDistanceKm: remainingDistanceKm ?? this.remainingDistanceKm,
      remainingMinutes: remainingMinutes ?? this.remainingMinutes,
      isOffRoute: isOffRoute ?? this.isOffRoute,
      isRerouting: isRerouting ?? this.isRerouting,
      routeSource: routeSource ?? this.routeSource,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'destinationName': destinationName,
      'destinationLat': destinationLat,
      'destinationLng': destinationLng,
      'originName': originName,
      'originLat': originLat,
      'originLng': originLng,
      'travelMode': travelMode.name,
      'expectedArrivalTime': expectedArrivalTime.toIso8601String(),
      'checkinIntervalMinutes': checkinIntervalMinutes,
      'gracePeriodMinutes': gracePeriodMinutes,
      'notifyContactIds': notifyContactIds,
      'notifyContactNames': notifyContactNames,
      'notifyContactPhones': notifyContactPhones,
      'status': status.name,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'totalDistanceKm': totalDistanceKm,
      'checkinsCompleted': checkinsCompleted,
      'totalCheckinsExpected': totalCheckinsExpected,
      'lastKnownLat': lastKnownLat,
      'lastKnownLng': lastKnownLng,
      'lastKnownLocationTime': lastKnownLocationTime?.toIso8601String(),
      'lastCheckinPromptAt': lastCheckinPromptAt?.toIso8601String(),
      'nextCheckinDueAt': nextCheckinDueAt?.toIso8601String(),
      'missedCheckinAt': missedCheckinAt?.toIso8601String(),
      'escalationTriggered': escalationTriggered,
      'routeCoordinates': routeCoordinates,
      'remainingDistanceKm': remainingDistanceKm,
      'remainingMinutes': remainingMinutes,
      'isOffRoute': isOffRoute,
      'isRerouting': isRerouting,
      'routeSource': routeSource,
    };
  }

  factory Journey.fromMap(Map<String, dynamic> map) {
    final rawCoords = map['routeCoordinates'] as List<dynamic>?;
    List<List<double>>? parsedCoords;
    if (rawCoords != null) {
      parsedCoords = rawCoords.map((item) {
        final list = item as List<dynamic>;
        return [(list[0] as num).toDouble(), (list[1] as num).toDouble()];
      }).toList();
    }

    return Journey(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      destinationName: map['destinationName'] as String? ?? '',
      destinationLat: (map['destinationLat'] as num?)?.toDouble() ?? 13.6288,
      destinationLng: (map['destinationLng'] as num?)?.toDouble() ?? 79.4192,
      originName: map['originName'] as String?,
      originLat: (map['originLat'] as num?)?.toDouble(),
      originLng: (map['originLng'] as num?)?.toDouble(),
      travelMode: TravelMode.values.firstWhere(
        (e) => e.name == map['travelMode'],
        orElse: () => TravelMode.bike,
      ),
      expectedArrivalTime: map['expectedArrivalTime'] != null
          ? DateTime.tryParse(map['expectedArrivalTime'] as String) ??
              DateTime.now().add(const Duration(hours: 1))
          : DateTime.now().add(const Duration(hours: 1)),
      checkinIntervalMinutes:
          (map['checkinIntervalMinutes'] as num?)?.toInt() ?? 15,
      gracePeriodMinutes: (map['gracePeriodMinutes'] as num?)?.toInt() ?? 5,
      notifyContactIds: (map['notifyContactIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      notifyContactNames: (map['notifyContactNames'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      notifyContactPhones: (map['notifyContactPhones'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      status: JourneyStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => JourneyStatus.planning,
      ),
      startedAt: map['startedAt'] != null
          ? DateTime.tryParse(map['startedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      completedAt: map['completedAt'] != null
          ? DateTime.tryParse(map['completedAt'] as String)
          : null,
      totalDistanceKm: (map['totalDistanceKm'] as num?)?.toDouble() ?? 22.0,
      checkinsCompleted: (map['checkinsCompleted'] as num?)?.toInt() ?? 0,
      totalCheckinsExpected:
          (map['totalCheckinsExpected'] as num?)?.toInt() ?? 6,
      lastKnownLat: (map['lastKnownLat'] as num?)?.toDouble(),
      lastKnownLng: (map['lastKnownLng'] as num?)?.toDouble(),
      lastKnownLocationTime: map['lastKnownLocationTime'] != null
          ? DateTime.tryParse(map['lastKnownLocationTime'] as String)
          : null,
      lastCheckinPromptAt: map['lastCheckinPromptAt'] != null
          ? DateTime.tryParse(map['lastCheckinPromptAt'] as String)
          : null,
      nextCheckinDueAt: map['nextCheckinDueAt'] != null
          ? DateTime.tryParse(map['nextCheckinDueAt'] as String)
          : null,
      missedCheckinAt: map['missedCheckinAt'] != null
          ? DateTime.tryParse(map['missedCheckinAt'] as String)
          : null,
      escalationTriggered: map['escalationTriggered'] as bool? ?? false,
      routeCoordinates: parsedCoords,
      remainingDistanceKm: (map['remainingDistanceKm'] as num?)?.toDouble(),
      remainingMinutes: (map['remainingMinutes'] as num?)?.toInt(),
      isOffRoute: map['isOffRoute'] as bool? ?? false,
      isRerouting: map['isRerouting'] as bool? ?? false,
      routeSource: map['routeSource'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory Journey.fromJson(String source) =>
      Journey.fromMap(json.decode(source) as Map<String, dynamic>);
}
