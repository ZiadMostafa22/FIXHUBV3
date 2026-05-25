// test/unit/refund_entity_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:car_maintenance_system_new/features/refunds/domain/entities/refund_entity.dart';

void main() {
  final now = DateTime(2025, 6, 1);

  group('RefundEntity — fromFirestore', () {
    test('parses requested refund correctly', () {
      final map = {
        'bookingId': 'bk-001', 'originalAmount': 850.0,
        'refundAmount': 850.0, 'reason': 'Service not completed',
        'customerNotes': 'Car still has issues', 'status': 'requested',
        'requestedBy': 'customer-001',
        'requestedAt': Timestamp.fromDate(now),
        'originalPaymentMethod': 'cash',
      };
      final r = RefundEntity.fromFirestore(map, 'refund-001');
      expect(r.id, equals('refund-001'));
      expect(r.status, equals(RefundStatus.requested));
      expect(r.originalAmount, equals(850.0));
      expect(r.reason, equals('Service not completed'));
      expect(r.approvedBy, isNull);
      expect(r.processedAt, isNull);
    });

    test('parses approved refund with approval details', () {
      final map = {
        'bookingId': 'bk-002', 'originalAmount': 500.0,
        'refundAmount': 400.0, 'reason': 'Partial service',
        'status': 'approved', 'requestedBy': 'customer-002',
        'requestedAt': Timestamp.fromDate(now),
        'approvedBy': 'admin-001',
        'approvedAt': Timestamp.fromDate(now.add(const Duration(hours: 2))),
      };
      final r = RefundEntity.fromFirestore(map, 'refund-002');
      expect(r.status, equals(RefundStatus.approved));
      expect(r.approvedBy, equals('admin-001'));
      expect(r.approvedAt, isNotNull);
    });

    test('parses processed refund with all timestamps', () {
      final map = {
        'bookingId': 'bk-003', 'originalAmount': 1200.0,
        'refundAmount': 1200.0, 'reason': 'Cancelled by admin',
        'status': 'processed', 'requestedBy': 'customer-003',
        'requestedAt': Timestamp.fromDate(now),
        'approvedBy': 'admin-001',
        'approvedAt': Timestamp.fromDate(now),
        'processedAt': Timestamp.fromDate(now.add(const Duration(days: 1))),
        'originalPaymentMethod': 'card', 'refundMethod': 'card',
      };
      final r = RefundEntity.fromFirestore(map, 'refund-003');
      expect(r.status, equals(RefundStatus.processed));
      expect(r.processedAt, isNotNull);
      expect(r.refundMethod, equals('card'));
    });

    test('rejected refund status parsed correctly', () {
      final map = {
        'bookingId': 'bk-004', 'originalAmount': 300.0,
        'refundAmount': 0.0, 'reason': 'Customer request',
        'status': 'rejected', 'requestedBy': 'customer-004',
        'requestedAt': Timestamp.fromDate(now),
      };
      final r = RefundEntity.fromFirestore(map, 'refund-004');
      expect(r.status, equals(RefundStatus.rejected));
    });

    test('unknown status defaults to requested', () {
      final map = {
        'bookingId': 'bk-005', 'originalAmount': 100.0,
        'refundAmount': 100.0, 'reason': 'Test', 'status': 'unknown_xyz',
        'requestedBy': 'c', 'requestedAt': Timestamp.fromDate(now),
      };
      final r = RefundEntity.fromFirestore(map, 'refund-005');
      expect(r.status, equals(RefundStatus.requested));
    });
  });

  group('RefundEntity — toFirestore', () {
    test('serializes requested refund correctly', () {
      final r = RefundEntity(
        id: 'refund-001', bookingId: 'bk-001',
        originalAmount: 850.0, refundAmount: 850.0,
        reason: 'Not satisfied', status: RefundStatus.requested,
        requestedBy: 'customer-001', requestedAt: now,
        originalPaymentMethod: 'cash',
      );
      final map = r.toFirestore();
      expect(map['bookingId'], equals('bk-001'));
      expect(map['status'], equals('requested'));
      expect(map['originalAmount'], equals(850.0));
      expect(map['approvedBy'], isNull);
      expect(map['approvedAt'], isNull);
      expect(map['processedAt'], isNull);
      expect(map.containsKey('id'), isFalse);
    });

    test('serializes processed refund with all dates', () {
      final r = RefundEntity(
        id: 'refund-002', bookingId: 'bk-002',
        originalAmount: 500.0, refundAmount: 500.0,
        reason: 'Cancelled', status: RefundStatus.processed,
        requestedBy: 'customer-002', requestedAt: now,
        approvedBy: 'admin-001', approvedAt: now,
        processedAt: now.add(const Duration(days: 1)),
        refundMethod: 'card',
      );
      final map = r.toFirestore();
      expect(map['status'], equals('processed'));
      expect(map['approvedBy'], equals('admin-001'));
      expect(map['approvedAt'], isNotNull);
      expect(map['processedAt'], isNotNull);
      expect(map['refundMethod'], equals('card'));
    });
  });

  group('Enums — RefundStatus', () {
    test('all refund statuses exist', () {
      expect(RefundStatus.values.length, equals(4));
      expect(RefundStatus.values, contains(RefundStatus.requested));
      expect(RefundStatus.values, contains(RefundStatus.approved));
      expect(RefundStatus.values, contains(RefundStatus.rejected));
      expect(RefundStatus.values, contains(RefundStatus.processed));
    });
  });
}
