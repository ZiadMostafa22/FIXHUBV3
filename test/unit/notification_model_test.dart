// test/unit/notification_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:car_maintenance_system_new/core/models/notification_model.dart';

void main() {
  final now = DateTime(2025, 6, 1);

  group('NotificationModel — fromFirestore', () {
    test('parses booking notification correctly', () {
      final map = {
        'userId': 'user-001', 'type': 'push', 'category': 'booking',
        'title': 'Booking Confirmed', 'message': 'Your booking has been confirmed',
        'read': false, 'sentAt': Timestamp.fromDate(now),
        'bookingId': 'bk-001', 'carId': null, 'metadata': null,
      };
      final n = NotificationModel.fromFirestore(map, 'notif-001');
      expect(n.id, equals('notif-001'));
      expect(n.type, equals(NotificationType.push));
      expect(n.category, equals(NotificationCategory.booking));
      expect(n.read, isFalse);
      expect(n.bookingId, equals('bk-001'));
    });

    test('parses payment notification', () {
      final map = {
        'userId': 'user-001', 'type': 'inApp', 'category': 'payment',
        'title': 'Payment Received', 'message': 'EGP 850 received',
        'read': true, 'sentAt': Timestamp.fromDate(now),
      };
      final n = NotificationModel.fromFirestore(map, 'notif-002');
      expect(n.type, equals(NotificationType.inApp));
      expect(n.category, equals(NotificationCategory.payment));
      expect(n.read, isTrue);
    });

    test('unknown type defaults to inApp', () {
      final map = {
        'userId': 'u', 'type': 'unknown_xyz', 'category': 'system',
        'title': 'T', 'message': 'M', 'sentAt': Timestamp.fromDate(now),
      };
      final n = NotificationModel.fromFirestore(map, 'notif-003');
      expect(n.type, equals(NotificationType.inApp));
    });

    test('unknown category defaults to system', () {
      final map = {
        'userId': 'u', 'type': 'push', 'category': 'unknown_abc',
        'title': 'T', 'message': 'M', 'sentAt': Timestamp.fromDate(now),
      };
      final n = NotificationModel.fromFirestore(map, 'notif-004');
      expect(n.category, equals(NotificationCategory.system));
    });
  });

  group('NotificationModel — toFirestore', () {
    test('serializes all fields correctly', () {
      final n = NotificationModel(
        id: 'notif-001', userId: 'user-001', type: NotificationType.push,
        category: NotificationCategory.booking, title: 'Test',
        message: 'Test message', read: false, sentAt: now,
        bookingId: 'bk-001',
      );
      final map = n.toFirestore();
      expect(map['userId'], equals('user-001'));
      expect(map['type'], equals('push'));
      expect(map['category'], equals('booking'));
      expect(map['read'], isFalse);
      expect(map['bookingId'], equals('bk-001'));
      expect(map.containsKey('id'), isFalse);
    });

    test('toFirestore handles null optional fields', () {
      final n = NotificationModel(
        id: 'notif-002', userId: 'user-001', type: NotificationType.inApp,
        category: NotificationCategory.system, title: 'System',
        message: 'Maintenance', sentAt: now,
      );
      final map = n.toFirestore();
      expect(map['bookingId'], isNull);
      expect(map['carId'], isNull);
      expect(map['metadata'], isNull);
    });
  });

  group('NotificationModel — copyWith', () {
    test('copyWith marks notification as read', () {
      final original = NotificationModel(
        id: 'notif-001', userId: 'user-001', type: NotificationType.push,
        category: NotificationCategory.booking, title: 'New Booking',
        message: 'You have a new booking', sentAt: now,
      );
      expect(original.read, isFalse);
      final read = original.copyWith(read: true);
      expect(read.read, isTrue);
      expect(original.read, isFalse);
    });

    test('copyWith preserves all other fields', () {
      final original = NotificationModel(
        id: 'notif-001', userId: 'user-001', type: NotificationType.push,
        category: NotificationCategory.payment, title: 'Payment',
        message: 'Msg', sentAt: now, bookingId: 'bk-001',
      );
      final updated = original.copyWith(read: true);
      expect(updated.id, equals(original.id));
      expect(updated.title, equals(original.title));
      expect(updated.bookingId, equals(original.bookingId));
      expect(updated.category, equals(NotificationCategory.payment));
    });
  });

  group('Enums — NotificationType', () {
    test('all notification types exist', () {
      expect(NotificationType.values.length, equals(2));
    });
  });

  group('Enums — NotificationCategory', () {
    test('all categories exist', () {
      expect(NotificationCategory.values.length, equals(4));
      expect(NotificationCategory.values, contains(NotificationCategory.booking));
      expect(NotificationCategory.values, contains(NotificationCategory.payment));
      expect(NotificationCategory.values, contains(NotificationCategory.reminder));
      expect(NotificationCategory.values, contains(NotificationCategory.system));
    });
  });
}
