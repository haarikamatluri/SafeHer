import 'package:flutter_test/flutter_test.dart';
import 'package:safeher/models/safe_haven.dart';
import 'package:safeher/models/resilience_status.dart';

void main() {
  group('SafeHaven Models and Filtering', () {
    test('SafeHavenCategory parses properly', () {
      expect(SafeHavenCategory.all.displayName, 'All');
      expect(SafeHavenCategory.police.displayName, 'Police');
      expect(SafeHavenCategory.hospital.displayName, 'Hospital');
      expect(SafeHavenCategory.pharmacy.displayName, 'Pharmacy');
      expect(SafeHavenCategory.womenCenter.displayName, 'Women Help Center');
      expect(SafeHavenCategory.verifiedPlace.displayName, 'Verified Safe Place');
    });

    test('SafeHavenPlace serialization and fields', () {
      const place = SafeHavenPlace(
        id: 'shp-1',
        name: 'Sri Padmavathi Hospital',
        category: SafeHavenCategory.hospital,
        address: 'Tiruchanur Road, Tirupati, AP',
        latitude: 13.6210,
        longitude: 79.4300,
        distanceKm: 2.4,
        phone: '+918772233455',
        operatingHours: 'Open 24 hours',
        isVerified: true,
        verificationSource: 'District Medical Health Office (DMHO)',
      );

      final map = place.toMap();
      expect(map['id'], 'shp-1');
      expect(map['name'], 'Sri Padmavathi Hospital');
      expect(map['category'], 'hospital');
      expect(map['isVerified'], true);
      expect(map['distanceKm'], 2.4);

      final jsonStr = place.toJson();
      final restored = SafeHavenPlace.fromJson(jsonStr);
      expect(restored.id, place.id);
      expect(restored.name, place.name);
      expect(restored.category, SafeHavenCategory.hospital);
      expect(restored.isVerified, true);
      expect(restored.phone, '+918772233455');
    });

    test('CommunityReport correctly handles verified and unverified statuses', () {
      final verifiedReport = CommunityReport(
        id: 'rep-1',
        userId: 'u1',
        title: 'Well lit and safe',
        locationName: 'Near Renigunta Road',
        latitude: 13.6300,
        longitude: 79.4200,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        isVerified: true,
        category: 'lighting',
      );

      final unverifiedReport = CommunityReport(
        id: 'rep-2',
        userId: 'u2',
        title: 'Poor lighting at night',
        locationName: 'SV University Road',
        latitude: 13.6280,
        longitude: 79.4180,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        isVerified: false,
        category: 'hazard',
      );

      expect(verifiedReport.isVerified, true);
      expect(unverifiedReport.isVerified, false);

      final jsonStr = verifiedReport.toJson();
      final restored = CommunityReport.fromJson(jsonStr);
      expect(restored.title, 'Well lit and safe');
      expect(restored.isVerified, true);
    });
  });

  group('SOS Resilience Status and Settings', () {
    test('DeviceStatusInfo reflects live hardware readings', () {
      const info = DeviceStatusInfo(
        gpsActive: true,
        gpsAccuracy: 'High accuracy (8 m)',
        mobileNetwork: 'Jio 4G',
        internetConnected: true,
        internetType: 'Wi-Fi / Mobile Data',
        batteryLevel: 68,
        batteryStatus: 'Good for tracking',
        simDetected: true,
      );

      expect(info.gpsActive, true);
      expect(info.internetConnected, true);
      expect(info.simDetected, true);
      expect(info.batteryLevel, 68);
    });

    test('AlertSettings loads defaults and serializes faithfully', () {
      const defaultSettings = AlertSettings();
      expect(defaultSettings.lowBatteryAlert, true);
      expect(defaultSettings.networkLostAlert, true);
      expect(defaultSettings.gpsSignalLostAlert, true);
      expect(defaultSettings.trackingStoppedAlert, true);
      expect(defaultSettings.appKilledAlert, true);
      expect(defaultSettings.showNotifications, true);

      const customSettings = AlertSettings(
        lowBatteryAlert: false,
        networkLostAlert: true,
        gpsSignalLostAlert: false,
        trackingStoppedAlert: true,
        appKilledAlert: false,
        showNotifications: true,
      );

      final map = customSettings.toMap();
      final restored = AlertSettings.fromMap(map);

      expect(restored.lowBatteryAlert, false);
      expect(restored.networkLostAlert, true);
      expect(restored.gpsSignalLostAlert, false);
      expect(restored.trackingStoppedAlert, true);
    });
  });
}
