import 'package:flutter_test/flutter_test.dart';
import 'package:safeher/models/incident.dart';
import 'package:safeher/utils/constants.dart';

void main() {
  group('Incident Model Tests', () {
    test(
      'Incident creates valid Google Maps URL when coordinates are present',
      () {
        final incident = Incident(
          id: '12345678-abcd-ef01-2345-6789abcdef01',
          userId: 'test_user_1',
          status: IncidentStatus.active,
          source: 'sos_button',
          createdAt: DateTime(2026, 1, 1, 12, 0, 0),
          latitude: 28.6139,
          longitude: 77.2090,
        );

        expect(incident.hasLocation, isTrue);
        expect(
          incident.googleMapsUrl,
          'https://maps.google.com/?q=28.6139,77.209',
        );
        expect(incident.shortId, 'INC-123456');
      },
    );

    test(
      'Incident returns null Google Maps URL when coordinates are absent',
      () {
        final incident = Incident(
          id: 'incident-without-loc',
          userId: 'test_user_2',
          status: IncidentStatus.active,
          source: 'checkin_missed',
          createdAt: DateTime.now(),
        );

        expect(incident.hasLocation, isFalse);
        expect(incident.googleMapsUrl, isNull);
      },
    );

    test('Incident status state machine allows valid transitions and forbids invalid', () {
      final activeIncident = Incident(
        id: 'inc-state-test',
        userId: 'user_state',
        status: IncidentStatus.active,
        source: 'sos_button',
        createdAt: DateTime.now(),
      );

      // From active -> can transition to resolved or cancelled
      expect(
        activeIncident.canTransitionTo(IncidentStatus.resolvedByUser),
        isTrue,
      );
      expect(activeIncident.canTransitionTo(IncidentStatus.cancelled), isTrue);
      expect(activeIncident.canTransitionTo(IncidentStatus.active), isFalse);

      final resolvedIncident = activeIncident.copyWith(
        status: IncidentStatus.resolvedByUser,
        resolvedAt: DateTime.now(),
      );

      // Once resolved -> cannot transition back to active or cancelled
      expect(resolvedIncident.canTransitionTo(IncidentStatus.active), isFalse);
      expect(
        resolvedIncident.canTransitionTo(IncidentStatus.cancelled),
        isFalse,
      );

      final cancelledIncident = activeIncident.copyWith(
        status: IncidentStatus.cancelled,
        resolvedAt: DateTime.now(),
      );

      // Once cancelled -> cannot transition to active or resolved
      expect(cancelledIncident.canTransitionTo(IncidentStatus.active), isFalse);
      expect(
        cancelledIncident.canTransitionTo(IncidentStatus.resolvedByUser),
        isFalse,
      );
    });

    test('Incident serialization toMap and fromMap preserves all fields', () {
      final original = Incident(
        id: 'ser-test-id-123456',
        userId: 'ser_user_99',
        status: IncidentStatus.resolvedByUser,
        source: 'sos_button',
        createdAt: DateTime.parse('2026-05-15T10:30:00.000Z'),
        resolvedAt: DateTime.parse('2026-05-15T10:45:00.000Z'),
        latitude: 37.7749,
        longitude: -122.4194,
        locationAccuracy: 12.5,
        locationSharingEnabled: true,
        alertStatus: AlertDeliveryStatus.simulatedSent,
        alertAttemptCount: 1,
        isSyncedToRemote: true,
      );

      final map = original.toMap();
      final restored = Incident.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.userId, original.userId);
      expect(restored.status, original.status);
      expect(restored.source, original.source);
      expect(restored.latitude, original.latitude);
      expect(restored.longitude, original.longitude);
      expect(restored.locationAccuracy, original.locationAccuracy);
      expect(restored.alertStatus, original.alertStatus);
      expect(restored.isSyncedToRemote, original.isSyncedToRemote);
    });
  });
}
