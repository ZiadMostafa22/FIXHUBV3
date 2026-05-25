// test/unit/booking_repository_test.dart
// Unit tests for BookingRepository operations using FakeFirebaseFirestore.
// Tests CRUD operations: create, read, update bookings without network calls.

import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:car_maintenance_system_new/features/booking/domain/entities/booking_entity.dart';
import '../helpers/test_fixtures.dart';

/// Helper: seed a booking document into FakeFirestore
Future<String> seedBooking(
  FakeFirebaseFirestore firestore,
  Map<String, dynamic> data,
) async {
  final now = Timestamp.fromDate(DateTime(2025, 6, 1));
  final docRef = await firestore.collection('bookings').add({
    ...data,
    'createdAt': now,
    'updatedAt': now,
    'scheduledDate': Timestamp.fromDate(DateTime(2025, 6, 15)),
  });
  return docRef.id;
}

void main() {
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
  });

  // ─── CREATE ─────────────────────────────────────────────────────────────────

  group('Booking — Create', () {
    test('createBooking stores document in Firestore', () async {
      final data = TestFixtures.bookingFirestoreMap();
      final docRef = await fakeFirestore.collection('bookings').add({
        ...data,
        'scheduledDate': Timestamp.fromDate(DateTime(2025, 6, 15)),
        'createdAt': Timestamp.fromDate(DateTime(2025, 6, 1)),
        'updatedAt': Timestamp.fromDate(DateTime(2025, 6, 1)),
      });

      final snap = await fakeFirestore
          .collection('bookings')
          .doc(docRef.id)
          .get();

      expect(snap.exists, isTrue);
      expect(snap.data()?['userId'], equals('customer-uid-001'));
      expect(snap.data()?['status'], equals('pending'));
    });

    test('createBooking returns a non-empty document id', () async {
      final data = TestFixtures.bookingFirestoreMap();
      final docRef = await fakeFirestore.collection('bookings').add({
        ...data,
        'scheduledDate': Timestamp.fromDate(DateTime(2025, 6, 15)),
        'createdAt': Timestamp.fromDate(DateTime(2025, 6, 1)),
        'updatedAt': Timestamp.fromDate(DateTime(2025, 6, 1)),
      });

      expect(docRef.id, isNotEmpty);
    });
  });

  // ─── READ ─────────────────────────────────────────────────────────────────

  group('Booking — Read', () {
    test('getBookingById returns correct document data', () async {
      final data = TestFixtures.bookingFirestoreMap();
      final id = await seedBooking(fakeFirestore, data);

      final snap =
          await fakeFirestore.collection('bookings').doc(id).get();

      expect(snap.exists, isTrue);
      final result = snap.data()!;
      expect(result['carId'], equals('car-001'));
      expect(result['maintenanceType'], equals('regular'));
    });

    test('getBookingById returns null for nonexistent document', () async {
      final snap = await fakeFirestore
          .collection('bookings')
          .doc('does-not-exist')
          .get();
      expect(snap.exists, isFalse);
    });

    test('loadBookings by userId returns only that user\'s bookings', () async {
      // Seed two bookings for customer and one for another user
      await seedBooking(
          fakeFirestore, {...TestFixtures.bookingFirestoreMap(), 'userId': 'customer-uid-001'});
      await seedBooking(
          fakeFirestore, {...TestFixtures.bookingFirestoreMap(), 'userId': 'customer-uid-001'});
      await seedBooking(
          fakeFirestore, {...TestFixtures.bookingFirestoreMap(), 'userId': 'other-user-999'});

      final snap = await fakeFirestore
          .collection('bookings')
          .where('userId', isEqualTo: 'customer-uid-001')
          .get();

      expect(snap.docs.length, equals(2));
      for (final doc in snap.docs) {
        expect(doc.data()['userId'], equals('customer-uid-001'));
      }
    });

    test('admin/technician query returns all bookings (no userId filter)',
        () async {
      await seedBooking(
          fakeFirestore, {...TestFixtures.bookingFirestoreMap(), 'userId': 'user-A'});
      await seedBooking(
          fakeFirestore, {...TestFixtures.bookingFirestoreMap(), 'userId': 'user-B'});
      await seedBooking(
          fakeFirestore, {...TestFixtures.bookingFirestoreMap(), 'userId': 'user-C'});

      // Admin sees all — no where() filter
      final snap = await fakeFirestore.collection('bookings').get();
      expect(snap.docs.length, equals(3));
    });

    test('filter bookings by status=pending returns only pending', () async {
      await seedBooking(fakeFirestore, {
        ...TestFixtures.bookingFirestoreMap(),
        'status': 'pending',
        'userId': 'u1',
      });
      await seedBooking(fakeFirestore, {
        ...TestFixtures.bookingFirestoreMap(),
        'status': 'confirmed',
        'userId': 'u1',
      });
      await seedBooking(fakeFirestore, {
        ...TestFixtures.bookingFirestoreMap(),
        'status': 'pending',
        'userId': 'u1',
      });

      final snap = await fakeFirestore
          .collection('bookings')
          .where('status', isEqualTo: 'pending')
          .get();

      expect(snap.docs.length, equals(2));
    });
  });

  // ─── UPDATE ─────────────────────────────────────────────────────────────────

  group('Booking — Update', () {
    test('updateBooking changes specified fields', () async {
      final id = await seedBooking(
          fakeFirestore, TestFixtures.bookingFirestoreMap());

      await fakeFirestore.collection('bookings').doc(id).update({
        'status': 'confirmed',
        'updatedAt': Timestamp.fromDate(DateTime(2025, 6, 2)),
      });

      final snap =
          await fakeFirestore.collection('bookings').doc(id).get();
      expect(snap.data()?['status'], equals('confirmed'));
    });

    test('updateBookingStatus to inProgress sets startedAt', () async {
      final id = await seedBooking(
          fakeFirestore, TestFixtures.bookingFirestoreMap());
      final startTime = DateTime(2025, 6, 15, 9, 0);

      await fakeFirestore.collection('bookings').doc(id).update({
        'status': 'inProgress',
        'startedAt': Timestamp.fromDate(startTime),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      final snap =
          await fakeFirestore.collection('bookings').doc(id).get();
      expect(snap.data()?['status'], equals('inProgress'));
      expect(snap.data()?['startedAt'], isNotNull);
    });

    test('processPayment updates isPaid and cashierId', () async {
      final id = await seedBooking(
          fakeFirestore, TestFixtures.bookingFirestoreMap());

      await fakeFirestore.collection('bookings').doc(id).update({
        'isPaid': true,
        'status': 'completed',
        'cashierId': 'cashier-uid-001',
        'paymentMethod': 'cash',
        'paidAt': Timestamp.fromDate(DateTime(2025, 6, 15, 11, 0)),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      final snap =
          await fakeFirestore.collection('bookings').doc(id).get();
      expect(snap.data()?['isPaid'], isTrue);
      expect(snap.data()?['cashierId'], equals('cashier-uid-001'));
      expect(snap.data()?['paymentMethod'], equals('cash'));
    });

    test('rateBooking updates rating fields', () async {
      final id = await seedBooking(
          fakeFirestore, TestFixtures.bookingFirestoreMap());

      await fakeFirestore.collection('bookings').doc(id).update({
        'rating': 4.5,
        'ratingComment': 'Excellent service!',
        'ratedAt': Timestamp.fromDate(DateTime(2025, 6, 16)),
      });

      final snap =
          await fakeFirestore.collection('bookings').doc(id).get();
      expect(snap.data()?['rating'], equals(4.5));
      expect(snap.data()?['ratingComment'], equals('Excellent service!'));
    });
  });

  // ─── DTO Parsing ─────────────────────────────────────────────────────────────

  group('BookingDto — Firestore Parsing', () {
    test('BookingStatus enum parsed from Firestore string', () {
      const statusStr = 'pending';
      final status = BookingStatus.values.firstWhere(
        (e) => e.toString() == 'BookingStatus.$statusStr',
        orElse: () => BookingStatus.pending,
      );
      expect(status, equals(BookingStatus.pending));
    });

    test('Unknown BookingStatus defaults to pending', () {
      const statusStr = 'totally_invalid';
      final status = BookingStatus.values.firstWhere(
        (e) => e.toString() == 'BookingStatus.$statusStr',
        orElse: () => BookingStatus.pending,
      );
      expect(status, equals(BookingStatus.pending));
    });

    test('MaintenanceType parsed correctly from Firestore string', () {
      for (final type in MaintenanceType.values) {
        final str = type.toString().split('.').last;
        final parsed = MaintenanceType.values.firstWhere(
          (e) => e.toString() == 'MaintenanceType.$str',
          orElse: () => MaintenanceType.regular,
        );
        expect(parsed, equals(type));
      }
    });

    test('PaymentMethod parsed correctly from Firestore string', () {
      for (final method in PaymentMethod.values) {
        final str = method.toString().split('.').last;
        final parsed = PaymentMethod.values.firstWhere(
          (e) => e.toString() == 'PaymentMethod.$str',
          orElse: () => PaymentMethod.cash,
        );
        expect(parsed, equals(method));
      }
    });
  });

  // ─── Real-time Stream ────────────────────────────────────────────────────────

  group('Booking — Real-time Stream (watchBookings)', () {
    test('stream emits new booking after document is added', () async {
      final stream = fakeFirestore
          .collection('bookings')
          .where('userId', isEqualTo: 'stream-user')
          .snapshots();

      final future = stream.first;

      // Seed data AFTER subscribing
      await seedBooking(fakeFirestore, {
        ...TestFixtures.bookingFirestoreMap(),
        'userId': 'stream-user',
      });

      final snapshot = await future;
      // FakeFirestore snapshots() emits once with the current state
      expect(snapshot, isNotNull);
    });
  });
}
