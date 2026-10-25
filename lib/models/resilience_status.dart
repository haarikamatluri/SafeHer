class DeviceStatusInfo {
  final bool gpsActive;
  final String gpsAccuracy;
  final String mobileNetwork;
  final bool simDetected;
  final bool internetConnected;
  final String internetType;
  final int batteryLevel;
  final String batteryStatus;
  final bool smsPermissionGranted;
  final int pendingSyncCount;
  final DateTime? lastBackupTime;
  final DateTime? lastSyncTime;
  final double storageUsedMb;
  final double storageMaxMb;

  const DeviceStatusInfo({
    this.gpsActive = true,
    this.gpsAccuracy = 'High accuracy (8 m)',
    this.mobileNetwork = 'Jio 4G - Strong signal',
    this.simDetected = true,
    this.internetConnected = true,
    this.internetType = 'Wi-Fi / Mobile Data',
    this.batteryLevel = 68,
    this.batteryStatus = 'Good for tracking',
    this.smsPermissionGranted = true,
    this.pendingSyncCount = 0,
    this.lastBackupTime,
    this.lastSyncTime,
    this.storageUsedMb = 1.2,
    this.storageMaxMb = 50.0,
  });

  DeviceStatusInfo copyWith({
    bool? gpsActive,
    String? gpsAccuracy,
    String? mobileNetwork,
    bool? simDetected,
    bool? internetConnected,
    String? internetType,
    int? batteryLevel,
    String? batteryStatus,
    bool? smsPermissionGranted,
    int? pendingSyncCount,
    DateTime? lastBackupTime,
    DateTime? lastSyncTime,
    double? storageUsedMb,
    double? storageMaxMb,
  }) {
    return DeviceStatusInfo(
      gpsActive: gpsActive ?? this.gpsActive,
      gpsAccuracy: gpsAccuracy ?? this.gpsAccuracy,
      mobileNetwork: mobileNetwork ?? this.mobileNetwork,
      simDetected: simDetected ?? this.simDetected,
      internetConnected: internetConnected ?? this.internetConnected,
      internetType: internetType ?? this.internetType,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      batteryStatus: batteryStatus ?? this.batteryStatus,
      smsPermissionGranted: smsPermissionGranted ?? this.smsPermissionGranted,
      pendingSyncCount: pendingSyncCount ?? this.pendingSyncCount,
      lastBackupTime: lastBackupTime ?? this.lastBackupTime,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      storageUsedMb: storageUsedMb ?? this.storageUsedMb,
      storageMaxMb: storageMaxMb ?? this.storageMaxMb,
    );
  }
}

class AlertSettings {
  final bool lowBatteryAlert;
  final bool networkLostAlert;
  final bool gpsSignalLostAlert;
  final bool trackingStoppedAlert;
  final bool appKilledAlert;
  final bool showNotifications;

  const AlertSettings({
    this.lowBatteryAlert = true,
    this.networkLostAlert = true,
    this.gpsSignalLostAlert = true,
    this.trackingStoppedAlert = true,
    this.appKilledAlert = true,
    this.showNotifications = true,
  });

  AlertSettings copyWith({
    bool? lowBatteryAlert,
    bool? networkLostAlert,
    bool? gpsSignalLostAlert,
    bool? trackingStoppedAlert,
    bool? appKilledAlert,
    bool? showNotifications,
  }) {
    return AlertSettings(
      lowBatteryAlert: lowBatteryAlert ?? this.lowBatteryAlert,
      networkLostAlert: networkLostAlert ?? this.networkLostAlert,
      gpsSignalLostAlert: gpsSignalLostAlert ?? this.gpsSignalLostAlert,
      trackingStoppedAlert: trackingStoppedAlert ?? this.trackingStoppedAlert,
      appKilledAlert: appKilledAlert ?? this.appKilledAlert,
      showNotifications: showNotifications ?? this.showNotifications,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lowBatteryAlert': lowBatteryAlert,
      'networkLostAlert': networkLostAlert,
      'gpsSignalLostAlert': gpsSignalLostAlert,
      'trackingStoppedAlert': trackingStoppedAlert,
      'appKilledAlert': appKilledAlert,
      'showNotifications': showNotifications,
    };
  }

  factory AlertSettings.fromMap(Map<String, dynamic> map) {
    return AlertSettings(
      lowBatteryAlert: map['lowBatteryAlert'] as bool? ?? true,
      networkLostAlert: map['networkLostAlert'] as bool? ?? true,
      gpsSignalLostAlert: map['gpsSignalLostAlert'] as bool? ?? true,
      trackingStoppedAlert: map['trackingStoppedAlert'] as bool? ?? true,
      appKilledAlert: map['appKilledAlert'] as bool? ?? true,
      showNotifications: map['showNotifications'] as bool? ?? true,
    );
  }
}
