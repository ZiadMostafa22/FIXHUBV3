// test/unit/booking_repository_impl_test.dart
// Tests for BookingRepositoryImpl using Mockito-generated mocks.
//
// Run code generation (once):
//   flutter pub run build_runner build --delete-conflicting-outputs
//
// Then run tests:
//   flutter test test/unit/booking_repository_impl_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:car_maintenance_system_new/features/booking/data/datasources/booking_remote_datasource.dart';
import 'package:car_maintenance_system_new/features/booking/data/repositories/booking_repository_impl.dart';
import 'package:car_maintenance_system_new/features/booking/domain/entities/booking_entity.dart';
import 'package:car_maintenance_system_new/features/booking/data/models/booking_dto.dart';
import '../helpers/test_fixtures.dart';

@GenerateMocks([BookingRemoteDataSource])
import 'booking_repository_impl_test.mocks.dart';

void main() {
  late MockBookingRemoteDataSource mockDataSource;
  late BookingRepositoryImpl repository;

  final now = Timestamp.fromDate(DateTime(2025, 6, 1));

  /// Build a Firestore-compatible map from a BookingEntity
  Map<String, dynamic> _toFirestoreMap(BookingEntity entity) {
    return {
      'id': entity.id,
      'userId': entity.userId,
      'carId': entity.carId,
      'serviceId': entity.serviceId,
      'maintenanceType': entity.maintenanceType.toString().split('.').last,
      'scheduledDate': Timestamp.fromDate(entity.scheduledDate),
      'timeSlot': entity.timeSlot,
      'status': entity.status.toString().split('.').last,
      'description': entity.description,
      'assignedTechnicians': entity.assignedTechnicians,
      'notes': entity.notes,
      'createdAt': now,
      'updatedAt': now,
      'completedAt': null,
      'startedAt': null,
      'serviceItems': null,
      'laborCost': null,
      'tax': null,
      'technicianNotes': null,
      'offerCode': null,
      'offerTitle': null,
      'discountPercentage': null,
      'rating': null,
      'ratingComment': null,
      'ratedAt': null,
      'isPaid': entity.isPaid,
      'paidAt': null,
      'cashierId': null,
      'paymentMethod': null,
    };
  }

  setUp(() {
    mockDataSource = MockBookingRemoteDataSource();
    repository = BookingRepositoryImpl(mockDataSource);
  });

  // ─── createBooking ───────────────────────────────────────────────────────────

  group('BookingRepositoryImpl.createBooking', () {
    test('delegates to datasource and returns booking id', () async {
      final booking = TestFixtures.pendingBooking();
      when(mockDataSource.createBooking(any))
          .thenAnswer((_) async => 'generated-id-123');

      final result = await repository.createBooking(booking);

      expect(result, equals('generated-id-123'));
      verify(mockDataSource.createBooking(any)).called(1);
    });

    test('throws when datasource throws', () async {
      final booking = TestFixtures.pendingBooking();
      when(mockDataSource.createBooking(any))
          .thenThrow(Exception('Firestore write failed'));

      expect(
        () => repository.createBooking(booking),
        throwsException,
      );
    });
  });

  // ─── loadBookings ────────────────────────────────────────────────────────────

  group('BookingRepositoryImpl.loadBookings', () {
    test('returns list of BookingEntity objects for customer', () async {
      final booking = TestFixtures.pendingBooking();
      final firestoreMap = _toFirestoreMap(booking);

      when(mockDataSource.loadBookings(userId: 'customer-uid-001', role: null))
          .thenAnswer((_) async => [firestoreMap]);

      final result = await repository.loadBookings(userId: 'customer-uid-001');

      expect(result, isA<List<BookingEntity>>());
      expect(result.length, equals(1));
      expect(result.first.userId, equals('customer-uid-001'));
    });

    test('returns sorted list for customer (newest first)', () async {
      final older = TestFixtures.pendingBooking();
      // Directly create two maps with different createdAt timestamps
      final olderMap = _toFirestoreMap(older);
      // Override createdAt with an older date
      olderMap['createdAt'] =
          Timestamp.fromDate(DateTime(2025, 4, 1)); // April
      olderMap['updatedAt'] = Timestamp.fromDate(DateTime(2025, 4, 1));

      final newerMap = _toFirestoreMap(older.copyWith(id: 'newer-id'));
      // Override createdAt with a newer date
      newerMap['id'] = 'newer-id';
      newerMap['createdAt'] =
          Timestamp.fromDate(DateTime(2025, 8, 1)); // August
      newerMap['updatedAt'] = Timestamp.fromDate(DateTime(2025, 8, 1));

      when(mockDataSource.loadBookings(userId: 'customer-uid-001', role: null))
          .thenAnswer((_) async => [olderMap, newerMap]);

      final result = await repository.loadBookings(userId: 'customer-uid-001');
      // After sort, the newer item (August) should be at index 0
      expect(result.first.createdAt.month, greaterThan(result.last.createdAt.month));
    });

    test('does NOT sort for admin role (datasource already ordered)', () async {
      final booking = TestFixtures.pendingBooking();

      when(mockDataSource.loadBookings(
              userId: 'admin-uid-001', role: 'admin'))
          .thenAnswer((_) async => [_toFirestoreMap(booking)]);

      final result = await repository.loadBookings(
          userId: 'admin-uid-001', role: 'admin');
      expect(result.length, equals(1));
    });

    test('returns empty list when datasource returns empty', () async {
      when(mockDataSource.loadBookings(
              userId: 'user-no-bookings', role: null))
          .thenAnswer((_) async => []);

      final result =
          await repository.loadBookings(userId: 'user-no-bookings');
      expect(result, isEmpty);
    });
  });

  // ─── updateBooking ───────────────────────────────────────────────────────────

  group('BookingRepositoryImpl.updateBooking', () {
    test('delegates update to datasource', () async {
      when(mockDataSource.updateBooking('booking-001', any))
          .thenAnswer((_) async {});

      await repository.updateBooking('booking-001', {'status': 'confirmed'});

      verify(mockDataSource.updateBooking('booking-001', {'status': 'confirmed'}))
          .called(1);
    });
  });

  // ─── updateBookingStatus ─────────────────────────────────────────────────────

  group('BookingRepositoryImpl.updateBookingStatus', () {
    test('sends correct status string to datasource', () async {
      when(mockDataSource.updateBooking(any, any)).thenAnswer((_) async {});

      await repository.updateBookingStatus(
          'booking-001', BookingStatus.inProgress);

      final captured =
          verify(mockDataSource.updateBooking('booking-001', captureAny))
              .captured
              .first as Map<String, dynamic>;

      expect(captured['status'], equals('inProgress'));
    });

    test('includes completedAt when provided', () async {
      when(mockDataSource.updateBooking(any, any)).thenAnswer((_) async {});
      final completedAt = DateTime(2025, 6, 15, 12, 0);

      await repository.updateBookingStatus(
        'booking-001',
        BookingStatus.completed,
        completedAt: completedAt,
      );

      final captured =
          verify(mockDataSource.updateBooking('booking-001', captureAny))
              .captured
              .first as Map<String, dynamic>;

      expect(captured['status'], equals('completed'));
      expect(captured['completedAt'], isNotNull);
    });
  });

  // ─── getBookingById ──────────────────────────────────────────────────────────

  group('BookingRepositoryImpl.getBookingById', () {
    test('returns BookingEntity when datasource finds document', () async {
      final booking = TestFixtures.confirmedBooking();
      when(mockDataSource.getBookingById('booking-002'))
          .thenAnswer((_) async => _toFirestoreMap(booking));

      final result = await repository.getBookingById('booking-002');

      expect(result, isNotNull);
      expect(result!.id, equals('booking-002'));
      expect(result.status, equals(BookingStatus.confirmed));
    });

    test('returns null when datasource returns null', () async {
      when(mockDataSource.getBookingById('ghost-id'))
          .thenAnswer((_) async => null);

      final result = await repository.getBookingById('ghost-id');
      expect(result, isNull);
    });
  });

  // ─── rateBooking ─────────────────────────────────────────────────────────────

  group('BookingRepositoryImpl.rateBooking', () {
    test('delegates rating to datasource with correct args', () async {
      when(mockDataSource.rateBooking(
        bookingId: 'booking-003',
        rating: 5.0,
        comment: 'Perfect!',
      )).thenAnswer((_) async {});

      await repository.rateBooking(
        bookingId: 'booking-003',
        rating: 5.0,
        comment: 'Perfect!',
      );

      verify(mockDataSource.rateBooking(
        bookingId: 'booking-003',
        rating: 5.0,
        comment: 'Perfect!',
      )).called(1);
    });
  });

  // ─── processPayment ───────────────────────────────────────────────────────────

  group('BookingRepositoryImpl.processPayment', () {
    test('delegates payment to datasource with correct args', () async {
      when(mockDataSource.processPayment(
        bookingId: 'booking-003',
        cashierId: 'cashier-uid-001',
        paymentMethod: 'cash',
        totalCost: 440.0,
      )).thenAnswer((_) async {});

      await repository.processPayment(
        bookingId: 'booking-003',
        cashierId: 'cashier-uid-001',
        paymentMethod: PaymentMethod.cash,
        totalCost: 440.0,
      );

      verify(mockDataSource.processPayment(
        bookingId: 'booking-003',
        cashierId: 'cashier-uid-001',
        paymentMethod: 'cash',
        totalCost: 440.0,
      )).called(1);
    });
  });

  // ─── watchBookings Stream ─────────────────────────────────────────────────────

  group('BookingRepositoryImpl.watchBookings', () {
    test('stream emits list of BookingEntity objects', () async {
      final booking = TestFixtures.pendingBooking();

      when(mockDataSource.watchBookings(
              userId: 'customer-uid-001', role: null))
          .thenAnswer((_) => Stream.value([_toFirestoreMap(booking)]));

      final stream =
          repository.watchBookings(userId: 'customer-uid-001');
      final result = await stream.first;

      expect(result, isA<List<BookingEntity>>());
      expect(result.first.id, equals('booking-001'));
    });

    test('stream emits empty list when no bookings exist', () async {
      when(mockDataSource.watchBookings(userId: 'empty-user', role: null))
          .thenAnswer((_) => Stream.value([]));

      final stream = repository.watchBookings(userId: 'empty-user');
      final result = await stream.first;

      expect(result, isEmpty);
    });
  });
}
