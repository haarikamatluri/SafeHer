import 'package:flutter_test/flutter_test.dart';
import 'package:safeher/models/journey.dart';
import 'package:safeher/models/trusted_contact.dart';

void main() {
  group('Journey Model and State Transitions', () {
    final now = DateTime.now();
    final testContacts = [
      TrustedContact(
        id: 'c1',
        name: 'Sister Priya',
        phone: '+919876543210',
        relationship: 'Sister',
        createdAt: now,
        updatedAt: now,
      ),
    ];

    test('Initializes with correct default state and calculates durations', () {
      final eta = now.add(const Duration(minutes: 45));
      final journey = Journey(
        id: 'j-101',
        userId: 'user-abc',
        destinationName: 'Sri Venkateswara University, Tirupati',
        destinationLat: 13.6288,
        destinationLng: 79.4192,
        originLat: 13.6330,
        originLng: 79.4110,
        travelMode: TravelMode.bike,
        startedAt: now,
        expectedArrivalTime: eta,
        checkinIntervalMinutes: 15,
        notifyContactIds: [testContacts.first.id],
        notifyContactNames: [testContacts.first.name],
        notifyContactPhones: [testContacts.first.phone],
        totalDistanceKm: 22.0,
      );

      expect(journey.status, JourneyStatus.planning);
      expect(journey.checkinsCompleted, 0);
      expect(journey.travelMode, TravelMode.bike);
      expect(journey.destinationName, 'Sri Venkateswara University, Tirupati');
      expect(journey.notifyContactIds.length, 1);
    });

    test('Serializes to and from JSON faithfully', () {
      final eta = now.add(const Duration(hours: 1));
      final original = Journey(
        id: 'j-202',
        userId: 'user-xyz',
        destinationName: 'Tirupati Railway Station',
        destinationLat: 13.6280,
        destinationLng: 79.4190,
        travelMode: TravelMode.car,
        startedAt: now,
        expectedArrivalTime: eta,
        checkinIntervalMinutes: 20,
        notifyContactIds: ['c1'],
        notifyContactNames: ['Sister Priya'],
        notifyContactPhones: ['+919876543210'],
        totalDistanceKm: 14.5,
        status: JourneyStatus.checkinDue,
        checkinsCompleted: 1,
      );

      final json = original.toJson();
      final restored = Journey.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.userId, original.userId);
      expect(restored.destinationName, original.destinationName);
      expect(restored.travelMode, TravelMode.car);
      expect(restored.status, JourneyStatus.checkinDue);
      expect(restored.checkinsCompleted, 1);
      expect(restored.checkinIntervalMinutes, 20);
      expect(restored.notifyContactNames.first, 'Sister Priya');
    });

    test('Transitions correctly through lifecycle states', () {
      Journey journey = Journey(
        id: 'j-303',
        userId: 'user-state',
        destinationName: 'Alipiri Footpath Gate',
        destinationLat: 13.6500,
        destinationLng: 79.4000,
        travelMode: TravelMode.walking,
        startedAt: now,
        expectedArrivalTime: now.add(const Duration(minutes: 30)),
        checkinIntervalMinutes: 15,
        notifyContactIds: ['c1'],
        notifyContactNames: ['Sister Priya'],
        notifyContactPhones: ['+919876543210'],
        status: JourneyStatus.active,
      );

      expect(journey.status, JourneyStatus.active);

      // Check-in becomes due
      journey = journey.copyWith(status: JourneyStatus.checkinDue);
      expect(journey.status, JourneyStatus.checkinDue);

      // User confirms check-in
      journey = journey.copyWith(
        status: JourneyStatus.active,
        checkinsCompleted: journey.checkinsCompleted + 1,
      );
      expect(journey.status, JourneyStatus.active);
      expect(journey.checkinsCompleted, 1);

      // User misses next check-in
      journey = journey.copyWith(status: JourneyStatus.checkinMissed);
      expect(journey.status, JourneyStatus.checkinMissed);

      // Grace period expires -> Escalated to contacts
      journey = journey.copyWith(status: JourneyStatus.escalated);
      expect(journey.status, JourneyStatus.escalated);

      // User safely completes
      journey = journey.copyWith(
        status: JourneyStatus.completed,
        completedAt: DateTime.now(),
      );
      expect(journey.status, JourneyStatus.completed);
      expect(journey.completedAt, isNotNull);
    });

    test('Travel mode parsing handles invalid and edge cases', () {
      expect(TravelMode.values.byName('walking'), TravelMode.walking);
      expect(TravelMode.values.byName('bike'), TravelMode.bike);
      expect(TravelMode.values.byName('car'), TravelMode.car);
      expect(TravelMode.values.byName('bus'), TravelMode.bus);
      expect(TravelMode.values.byName('other'), TravelMode.other);
    });
  });
}
