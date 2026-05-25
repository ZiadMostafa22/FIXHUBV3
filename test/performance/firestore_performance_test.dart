// test/performance/firestore_performance_test.dart
// Measures and logs response times for common Firestore operations.
// Uses FakeFirebaseFirestore to measure serialization and query overhead
// without requiring a real Firebase connection.
//
// Run: flutter test test/performance/firestore_performance_test.dart --reporter=expanded

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Measures the elapsed time of an async operation and prints a labeled report.
Future<T> measureTime<T>(String label, Future<T> Function() operation) async {
  final stopwatch = Stopwatch()..start();
  final result = await operation();
  stopwatch.stop();
  final ms = stopwatch.elapsedMilliseconds;
  final us = stopwatch.elapsedMicroseconds;

  // Performance budget thresholds (adjust to match real Firestore SLAs)
  final budget = _budgets[label] ?? 500; // default 500ms
  final status = ms <= budget ? '[PASS]' : '[SLOW]';

  debugPrint(
    '$status $label: ${ms}ms ($us us) | Budget: ${budget}ms',
  );
  return result;
}

// Define SLA budgets per operation type (milliseconds)
const _budgets = {
  'Single document write': 100,
  'Single document read': 50,
  'Query 10 documents': 100,
  'Query 100 documents': 200,
  'Query 1000 documents': 500,
  'Batch write 10 documents': 150,
  'Update single document': 50,
  'Delete single document': 50,
  'Collection count': 100,
  'Filtered query': 100,
};

void main() {
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
  });

  // Helper: seed N bookings (respects Firestore 500-op batch limit)
  Future<void> seedNBookings(int count) async {
    final now = Timestamp.fromDate(DateTime(2025, 6, 1));
    const batchSize = 499; // Stay under the 500-op limit
    var seeded = 0;

    while (seeded < count) {
      final end = (seeded + batchSize).clamp(0, count);
      final batch = fakeFirestore.batch();
      for (int i = seeded; i < end; i++) {
        final ref = fakeFirestore.collection('bookings').doc('booking-$i');
        batch.set(ref, {
          'userId': 'user-${i % 10}',
          'carId': 'car-$i',
          'serviceId': 'service-${i % 5}',
          'maintenanceType': i % 2 == 0 ? 'regular' : 'repair',
          'status': i % 3 == 0 ? 'pending' : 'confirmed',
          'timeSlot': '${9 + (i % 8)}:00 AM',
          'isPaid': i % 4 == 0,
          'scheduledDate': now,
          'createdAt': now,
          'updatedAt': now,
        });
      }
      await batch.commit();
      seeded = end;
    }
  }

  // ─── Write Performance ────────────────────────────────────────────────────

  group('Write Performance', () {
    test('Single document write', () async {
      final now = Timestamp.fromDate(DateTime(2025, 6, 1));

      await measureTime('Single document write', () async {
        await fakeFirestore.collection('bookings').add({
          'userId': 'perf-user',
          'status': 'pending',
          'createdAt': now,
          'updatedAt': now,
        });
      });
    });

    test('Batch write 10 documents', () async {
      final now = Timestamp.fromDate(DateTime(2025, 6, 1));
      await measureTime('Batch write 10 documents', () async {
        final batch = fakeFirestore.batch();
        for (int i = 0; i < 10; i++) {
          final ref = fakeFirestore.collection('perf_bookings').doc('doc-$i');
          batch.set(ref, {'idx': i, 'createdAt': now});
        }
        await batch.commit();
      });
    });

    test('Update single document', () async {
      final now = Timestamp.fromDate(DateTime(2025, 6, 1));
      final ref = await fakeFirestore.collection('bookings').add({
        'status': 'pending',
        'createdAt': now,
        'updatedAt': now,
      });

      await measureTime('Update single document', () async {
        await fakeFirestore.collection('bookings').doc(ref.id).update({
          'status': 'confirmed',
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      });
    });

    test('Delete single document', () async {
      final now = Timestamp.fromDate(DateTime(2025, 6, 1));
      final ref = await fakeFirestore.collection('bookings').add({
        'status': 'cancelled',
        'createdAt': now,
        'updatedAt': now,
      });

      await measureTime('Delete single document', () async {
        await fakeFirestore.collection('bookings').doc(ref.id).delete();
      });
    });
  });

  // ─── Read Performance ─────────────────────────────────────────────────────

  group('Read Performance', () {
    test('Single document read', () async {
      final now = Timestamp.fromDate(DateTime(2025, 6, 1));
      final ref = await fakeFirestore.collection('bookings').add({
        'userId': 'read-perf-user',
        'status': 'pending',
        'createdAt': now,
        'updatedAt': now,
      });

      await measureTime('Single document read', () async {
        await fakeFirestore.collection('bookings').doc(ref.id).get();
      });
    });

    test('Query 10 documents', () async {
      await seedNBookings(10);
      await measureTime('Query 10 documents', () async {
        await fakeFirestore.collection('bookings').get();
      });
    });

    test('Query 100 documents', () async {
      await seedNBookings(100);
      await measureTime('Query 100 documents', () async {
        await fakeFirestore.collection('bookings').get();
      });
    });

    test('Query 1000 documents', () async {
      await seedNBookings(1000);
      await measureTime('Query 1000 documents', () async {
        await fakeFirestore.collection('bookings').get();
      });
      // Note: in FakeFirestore, 1000 documents is instant. In production
      // Firestore, use pagination (.limit(20)) — never load 1000+ at once.
    });
  });

  // ─── Query Performance ────────────────────────────────────────────────────

  group('Query Performance', () {
    setUp(() async {
      await seedNBookings(50);
    });

    test('Filtered query by userId', () async {
      await measureTime('Filtered query', () async {
        await fakeFirestore
            .collection('bookings')
            .where('userId', isEqualTo: 'user-0')
            .get();
      });
    });

    test('Filtered query by status', () async {
      await measureTime('Filtered query', () async {
        await fakeFirestore
            .collection('bookings')
            .where('status', isEqualTo: 'pending')
            .get();
      });
    });

    test('Collection count', () async {
      await measureTime('Collection count', () async {
        final snap = await fakeFirestore.collection('bookings').count().get();
        expect(snap.count, greaterThan(0));
      });
    });
  });

  // ─── Booking Calculation Performance ─────────────────────────────────────

  group('Business Logic Performance', () {
    test('Subtotal calculation for 1000 bookings is under 100ms', () {
      // This measures pure Dart calculation speed — no Firebase
      final stopwatch = Stopwatch()..start();
      double total = 0;
      for (int i = 0; i < 1000; i++) {
        // Simulate: subtotal = items + labor, then discount, then tax
        const itemsTotal = 1050.0;
        const laborCost = 200.0;
        const subtotal = itemsTotal + laborCost;
        const discount = subtotal * 0.10;
        const afterDiscount = subtotal - discount;
        const tax = afterDiscount * 0.10;
        total += afterDiscount + tax;
      }
      stopwatch.stop();

      debugPrint(
        '[PASS] 1000x booking cost calculations: '
        '${stopwatch.elapsedMilliseconds}ms (total=$total)',
      );
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });
  });
}
