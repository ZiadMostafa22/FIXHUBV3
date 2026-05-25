// test/unit/booking_entity_test.dart
// Unit tests for BookingEntity domain logic — no Firebase, no mocks needed.

import 'package:flutter_test/flutter_test.dart';
import 'package:car_maintenance_system_new/features/booking/domain/entities/booking_entity.dart';
import 'package:car_maintenance_system_new/features/booking/domain/entities/service_item_entity.dart';
import '../helpers/test_fixtures.dart';

void main() {
  group('BookingEntity — Cost Calculations', () {
    test('subtotal returns laborCost when no service items', () {
      final booking = TestFixtures.pendingBooking();
      // No serviceItems, no laborCost → subtotal should be 0
      expect(booking.subtotal, equals(0.0));
    });

    test('subtotal sums service items + laborCost', () {
      final booking = TestFixtures.completedBooking();
      // oilChangeItem: 250 * 1 = 250. laborCost = 150. subtotal = 400.
      expect(booking.subtotal, equals(400.0));
    });

    test('discountAmount is 0 when no discount', () {
      final booking = TestFixtures.completedBooking();
      expect(booking.discountAmount, equals(0.0));
    });

    test('discountAmount calculates correctly with percentage', () {
      final booking = TestFixtures.bookingWithDiscount();
      // serviceItems: oilChange(250) + brakepad(400*2=800). Total items = 1050.
      // laborCost = 200. subtotal = 1250.
      // discountPercentage = 10 → discountAmount = 125.
      expect(booking.subtotal, equals(1250.0));
      expect(booking.discountAmount, closeTo(125.0, 0.001));
    });

    test('subtotalAfterDiscount deducts discount correctly', () {
      final booking = TestFixtures.bookingWithDiscount();
      // 1250 - 125 = 1125
      expect(booking.subtotalAfterDiscount, closeTo(1125.0, 0.001));
    });

    test('totalCost applies 10% default tax when tax field is null', () {
      final booking = TestFixtures.bookingWithDiscount();
      // subtotalAfterDiscount = 1125. tax = 1125 * 0.10 = 112.5. total = 1237.5
      expect(booking.totalCost, closeTo(1237.5, 0.001));
    });

    test('totalCost uses explicit tax when provided', () {
      final booking = TestFixtures.completedBooking();
      // subtotal = 400, subtotalAfterDiscount = 400, tax = 40 (explicit). total = 440.
      expect(booking.totalCost, closeTo(440.0, 0.001));
    });

    test('hoursWorked returns 0 when startedAt or completedAt is null', () {
      final booking = TestFixtures.pendingBooking();
      expect(booking.hoursWorked, equals(0.0));
    });

    test('hoursWorked calculates correctly for 2.5 hours', () {
      final booking = TestFixtures.completedBooking();
      // startedAt = 09:00, completedAt = 11:30 → 150 min / 60 = 2.5
      expect(booking.hoursWorked, closeTo(2.5, 0.001));
    });
  });

  group('BookingEntity — copyWith', () {
    test('copyWith produces a new instance with updated fields', () {
      final original = TestFixtures.pendingBooking();
      final updated = original.copyWith(
        status: BookingStatus.confirmed,
        notes: 'Customer requested early slot',
      );

      expect(updated.id, equals(original.id));
      expect(updated.status, equals(BookingStatus.confirmed));
      expect(updated.notes, equals('Customer requested early slot'));
      // Original should be unchanged (immutability)
      expect(original.status, equals(BookingStatus.pending));
      expect(original.notes, isNull);
    });

    test('copyWith preserves unspecified fields', () {
      final original = TestFixtures.completedBooking();
      final updated = original.copyWith(notes: 'Updated note');

      expect(updated.userId, equals(original.userId));
      expect(updated.carId, equals(original.carId));
      expect(updated.rating, equals(original.rating));
      expect(updated.isPaid, equals(original.isPaid));
    });
  });

  group('BookingEntity — Status Transitions', () {
    test('booking starts as pending', () {
      final booking = TestFixtures.pendingBooking();
      expect(booking.status, equals(BookingStatus.pending));
    });

    test('isPaid defaults to false for new bookings', () {
      final booking = TestFixtures.pendingBooking();
      expect(booking.isPaid, isFalse);
    });

    test('completed booking has payment details', () {
      final booking = TestFixtures.completedBooking();
      expect(booking.isPaid, isTrue);
      expect(booking.cashierId, isNotNull);
      expect(booking.paymentMethod, equals(PaymentMethod.cash));
    });

    test('booking with rating has all rating fields', () {
      final booking = TestFixtures.completedBooking();
      expect(booking.rating, equals(4.5));
      expect(booking.ratingComment, isNotNull);
      expect(booking.ratedAt, isNotNull);
    });
  });

  group('ServiceItemEntity — totalPrice', () {
    test('totalPrice = price * quantity for parts', () {
      final item = TestFixtures.brakepadItem();
      expect(item.totalPrice, equals(800.0)); // 400 * 2
    });

    test('totalPrice = price for quantity 1', () {
      final item = TestFixtures.oilChangeItem();
      expect(item.totalPrice, equals(250.0)); // 250 * 1
    });

    test('ServiceItemEntity copyWith updates correctly', () {
      final item = ServiceItemEntity(
        id: 'svc-001',
        name: 'Test Part',
        type: ServiceItemType.part,
        price: 100.0,
        quantity: 1,
      );
      final updated = item.copyWith(quantity: 5);
      expect(updated.quantity, equals(5));
      expect(updated.totalPrice, equals(500.0));
    });
  });
}
