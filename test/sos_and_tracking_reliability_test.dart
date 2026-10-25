import 'package:flutter_test/flutter_test.dart';
import 'package:safeher/models/incident.dart';
import 'package:safeher/models/trusted_contact.dart';
import 'package:safeher/services/alert_service.dart';
import 'package:safeher/services/location_service.dart';
import 'package:safeher/services/native_sms_service.dart';
import 'package:safeher/utils/constants.dart';
import 'package:safeher/utils/validators.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 2: Fast Accurate Location Model & Edge Cases', () {
    test('Fresh GPS fix returns correct freshness, source and zero age', () {
      final now = DateTime.now();
      final freshResult = LocationResult(
        isSuccess: true,
        latitude: 13.6288,
        longitude: 79.4192,
        accuracyMeters: 4.8,
        capturedAt: now,
        isFresh: true,
        source: 'fresh_gps',
        age: Duration.zero,
      );

      expect(freshResult.isSuccess, isTrue);
      expect(freshResult.isFresh, isTrue);
      expect(freshResult.source, 'fresh_gps');
      expect(freshResult.accuracy, 4.8);
      expect(freshResult.formattedAccuracy, '±4.8m');
      expect(freshResult.ageDescription, 'Fresh (< 5s)');
      expect(freshResult.mapsUrl, 'https://maps.google.com/?q=13.6288,79.4192');
    });

    test('Cached GPS fix explicitly records age and non-fresh status', () {
      final captured = DateTime.now().subtract(const Duration(minutes: 7));
      final cachedResult = LocationResult(
        isSuccess: true,
        latitude: 13.6330,
        longitude: 79.4000,
        accuracyMeters: 18.2,
        capturedAt: captured,
        isFresh: false,
        source: 'cached',
        age: const Duration(minutes: 7),
      );

      expect(cachedResult.isSuccess, isTrue);
      expect(cachedResult.isFresh, isFalse);
      expect(cachedResult.source, 'cached');
      expect(cachedResult.ageDescription, '7m ago');
      expect(cachedResult.formattedAccuracy, '±18.2m');
    });

    test('Location unavailable provides truthful failureReason and null mapsUrl', () {
      final unavailable = LocationResult(
        isSuccess: false,
        isFresh: false,
        source: 'unavailable',
        failureReason: 'timeout',
        errorMessage: 'Satellite fix timed out after 4 seconds',
      );

      expect(unavailable.isSuccess, isFalse);
      expect(unavailable.source, 'unavailable');
      expect(unavailable.failureReason, 'timeout');
      expect(unavailable.mapsUrl, isNull);
    });

    test('Permission denied provides explicit reason without crashing', () {
      final denied = LocationResult(
        isSuccess: false,
        isFresh: false,
        source: 'unavailable',
        isPermissionDenied: true,
        failureReason: 'permission_denied',
        errorMessage: 'Location permission was denied',
      );

      expect(denied.isPermissionDenied, isTrue);
      expect(denied.failureReason, 'permission_denied');
    });
  });

  group('Phase 3 & 4: Truthful SMS Templates and Formatting', () {
    test('Emergency SMS includes coordinates, accuracy, age, and Maps URL when location exists', () {
      final incident = Incident(
        id: 'test-inc-12345678',
        userId: 'user_alpha',
        status: IncidentStatus.active,
        source: 'sos_button',
        createdAt: DateTime(2026, 3, 20, 14, 30),
        latitude: 13.6288,
        longitude: 79.4192,
        locationAccuracy: 5.5,
        locationSource: 'fresh_gps',
      );

      final smsText = AlertService().buildEmergencySmsText(incident);

      expect(smsText.contains('SAFEHER SOS: Emergency alert activated'), isTrue);
      expect(smsText.contains('INC-TESTIN'), isTrue);
      expect(smsText.contains('https://maps.google.com/?q=13.6288,79.4192'), isTrue);
      expect(smsText.contains('±5.5m'), isTrue);
      expect(smsText.contains('Location age:'), isTrue);
    });

    test('Emergency SMS truthfully reports unavailable location when fix is missing', () {
      final incident = Incident(
        id: 'test-inc-87654321',
        userId: 'user_beta',
        status: IncidentStatus.active,
        source: 'sos_button',
        createdAt: DateTime(2026, 3, 20, 14, 30),
        latitude: null,
        longitude: null,
        locationSource: 'unavailable',
      );

      final smsText = AlertService().buildEmergencySmsText(incident);

      expect(smsText.contains('Location: Location unavailable'), isTrue);
      expect(smsText.contains('Please contact me immediately'), isTrue);
      expect(smsText.contains('https://maps.google.com'), isFalse);
    });

    test('normalizeForSms preserves valid international + prefix and strips whitespace/symbols', () {
      expect(AppValidators.normalizeForSms('+91 98765 43210'), '+919876543210');
      expect(AppValidators.normalizeForSms('+1 (555) 234-5678'), '+15552345678');
      expect(AppValidators.normalizeForSms('98765-43210'), '9876543210');
      expect(AppValidators.normalizeForSms('+44 20 7946 0958'), '+442079460958');
    });
  });

  group('Phase 4 & 5: Native SMS Batch and Independent Recipient Results', () {
    test('NativeSmsResult captures error codes and cellular status', () {
      final successResult = NativeSmsResult(
        success: true,
        recipient: '+919876543210',
        sentStatus: 'sent_to_network',
        partsCount: 2,
      );
      expect(successResult.isAccepted, isTrue);
      expect(successResult.sentStatus, 'sent_to_network');
      expect(successResult.partsCount, 2);

      final failResult = NativeSmsResult(
        success: false,
        recipient: '+919876543211',
        sentStatus: 'failed',
        errorCode: 'RADIO_OFF',
        error: 'Cellular radio is disabled',
      );
      expect(failResult.isAccepted, isFalse);
      expect(failResult.errorCode, 'RADIO_OFF');
    });

    test('AlertService gracefully handles empty authorized contacts', () async {
      final incident = Incident(
        id: 'no-contacts-inc',
        userId: 'user_test',
        status: IncidentStatus.active,
        source: 'sos_button',
        createdAt: DateTime.now(),
      );

      final result = await AlertService().dispatchEmergencyAlert(
        incident: incident,
        contacts: [],
      );

      expect(result.status, AlertDeliveryStatus.notConfigured);
      expect(result.isSentToProvider, isFalse);
      expect(result.statusMessage.contains('No authorized contacts'), isTrue);
    });

    test('AlertService filters unauthorized contacts and dispatches only to authorized', () async {
      final incident = Incident(
        id: 'auth-filter-inc',
        userId: 'user_test',
        status: IncidentStatus.active,
        source: 'sos_button',
        createdAt: DateTime.now(),
        latitude: 13.6288,
        longitude: 79.4192,
      );

      final contacts = [
        TrustedContact(
          id: 'c1',
          name: 'Authorized Mom',
          phone: '+919876543210',
          relationship: 'Mother',
          isAuthorized: true,
          smsEnabled: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        TrustedContact(
          id: 'c2',
          name: 'Unauthorized Stranger',
          phone: '+919999999999',
          relationship: 'None',
          isAuthorized: false, // NOT authorized!
          smsEnabled: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final result = await AlertService().dispatchEmergencyAlert(
        incident: incident,
        contacts: contacts,
      );

      // On non-Android test environment, runs web simulation for authorized contact only
      expect(result.deliverySummary?['totalRecipients'], 1);
      final recipients = result.recipientResults ?? [];
      expect(recipients.length, 1);
      expect(recipients.first['name'], 'Authorized Mom');
    });
  });

  group('Phase 6: Incident Model and Extended Properties', () {
    test('Incident copyWith and serialization preserve locationSource and age', () {
      final now = DateTime.now();
      final incident = Incident(
        id: 'inc-ext-test',
        userId: 'user_ext',
        status: IncidentStatus.active,
        source: 'sos_button',
        createdAt: now,
        latitude: 13.6288,
        longitude: 79.4192,
        locationAccuracy: 6.0,
        locationSource: 'cached',
        locationAgeSeconds: 45,
        locationCapturedAt: now.subtract(const Duration(seconds: 45)),
        recipientResults: [
          {'name': 'Mom', 'status': 'sent_to_network'},
        ],
      );

      final map = incident.toMap();
      final restored = Incident.fromMap(map);

      expect(restored.locationSource, 'cached');
      expect(restored.locationAgeSeconds, 45);
      expect(restored.recipientResults?.length, 1);
      expect(restored.hasLocation, isTrue);
    });
  });
}
