// test/unit/invoice_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:car_maintenance_system_new/core/models/invoice_model.dart';

void main() {
  final now = DateTime(2025, 6, 1);

  // ─── InvoiceItem Tests ───────────────────────────────────────────────────

  group('InvoiceItem — Construction & totalPrice', () {
    test('totalPrice = price * quantity', () {
      final item = InvoiceItem(
        id: 'item-001', name: 'Oil Filter', description: 'Engine oil filter',
        price: 150.0, quantity: 2,
      );
      expect(item.totalPrice, equals(300.0));
    });

    test('totalPrice for single quantity', () {
      final item = InvoiceItem(
        id: 'item-002', name: 'Labor', description: 'Installation',
        price: 200.0, quantity: 1,
      );
      expect(item.totalPrice, equals(200.0));
    });

    test('partNumber is optional', () {
      final item = InvoiceItem(
        id: 'item-003', name: 'Brake Pad', description: 'Front brake pads',
        price: 400.0, quantity: 1, partNumber: 'BP-2023-A',
      );
      expect(item.partNumber, equals('BP-2023-A'));
    });
  });

  group('InvoiceItem — fromMap', () {
    test('fromMap creates item correctly', () {
      final map = {
        'id': 'item-001', 'name': 'Oil', 'description': 'Engine oil',
        'price': 250, 'quantity': 3, 'partNumber': 'OIL-5W30',
      };
      final item = InvoiceItem.fromMap(map);
      expect(item.name, equals('Oil'));
      expect(item.price, equals(250.0));
      expect(item.quantity, equals(3));
      expect(item.partNumber, equals('OIL-5W30'));
    });

    test('fromMap handles missing fields with defaults', () {
      final map = <String, dynamic>{};
      final item = InvoiceItem.fromMap(map);
      expect(item.id, equals(''));
      expect(item.name, equals(''));
      expect(item.price, equals(0.0));
      expect(item.quantity, equals(1));
    });
  });

  group('InvoiceItem — toMap', () {
    test('toMap serializes all fields', () {
      final item = InvoiceItem(
        id: 'item-001', name: 'Filter', description: 'Air filter',
        price: 100.0, quantity: 1, partNumber: 'AF-001',
      );
      final map = item.toMap();
      expect(map['id'], equals('item-001'));
      expect(map['name'], equals('Filter'));
      expect(map['price'], equals(100.0));
      expect(map['partNumber'], equals('AF-001'));
    });
  });

  // ─── InvoiceModel Tests ──────────────────────────────────────────────────

  group('InvoiceModel — fromMap', () {
    test('fromMap parses complete invoice', () {
      final map = {
        'id': 'inv-001', 'bookingId': 'bk-001', 'userId': 'user-001',
        'items': [
          {'id': 'i1', 'name': 'Oil', 'description': 'd', 'price': 250, 'quantity': 1},
          {'id': 'i2', 'name': 'Labor', 'description': 'd', 'price': 150, 'quantity': 1},
        ],
        'subtotal': 400.0, 'taxRate': 0.14, 'taxAmount': 56.0,
        'totalAmount': 456.0, 'paymentStatus': 'paid',
        'paymentMethod': 'cash', 'paymentId': 'pay-001',
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'paidAt': Timestamp.fromDate(now),
        'notes': 'Paid in full',
      };
      final invoice = InvoiceModel.fromMap(map);
      expect(invoice.id, equals('inv-001'));
      expect(invoice.items.length, equals(2));
      expect(invoice.paymentStatus, equals(PaymentStatus.paid));
      expect(invoice.paymentMethod, equals(PaymentMethod.cash));
      expect(invoice.totalAmount, equals(456.0));
      expect(invoice.notes, equals('Paid in full'));
    });

    test('fromMap handles pending payment without paidAt', () {
      final map = {
        'id': 'inv-002', 'bookingId': 'bk-002', 'userId': 'user-001',
        'items': [], 'subtotal': 0.0, 'taxRate': 0.0, 'taxAmount': 0.0,
        'totalAmount': 0.0, 'paymentStatus': 'pending',
        'paymentMethod': null, 'paymentId': null,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'paidAt': null, 'notes': null,
      };
      final invoice = InvoiceModel.fromMap(map);
      expect(invoice.paymentStatus, equals(PaymentStatus.pending));
      expect(invoice.paymentMethod, isNull);
      expect(invoice.paidAt, isNull);
    });

    test('unknown paymentStatus defaults to pending', () {
      final map = {
        'id': 'inv-003', 'bookingId': 'bk-003', 'userId': 'user-001',
        'items': [], 'subtotal': 0, 'taxRate': 0, 'taxAmount': 0,
        'totalAmount': 0, 'paymentStatus': 'unknown_xyz',
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };
      final invoice = InvoiceModel.fromMap(map);
      expect(invoice.paymentStatus, equals(PaymentStatus.pending));
    });

    test('refunded payment status is parsed correctly', () {
      final map = {
        'id': 'inv-004', 'bookingId': 'bk-004', 'userId': 'user-001',
        'items': [], 'subtotal': 500, 'taxRate': 0.14, 'taxAmount': 70,
        'totalAmount': 570, 'paymentStatus': 'refunded',
        'paymentMethod': 'card',
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };
      final invoice = InvoiceModel.fromMap(map);
      expect(invoice.paymentStatus, equals(PaymentStatus.refunded));
    });
  });

  group('InvoiceModel — toMap', () {
    test('toMap serializes complete invoice', () {
      final invoice = InvoiceModel(
        id: 'inv-001', bookingId: 'bk-001', userId: 'user-001',
        items: [
          InvoiceItem(id: 'i1', name: 'Oil', description: 'd', price: 250, quantity: 1),
        ],
        subtotal: 250.0, taxRate: 0.14, taxAmount: 35.0,
        totalAmount: 285.0, paymentStatus: PaymentStatus.paid,
        paymentMethod: PaymentMethod.cash,
        createdAt: now, updatedAt: now, paidAt: now,
      );
      final map = invoice.toMap();
      expect(map['id'], equals('inv-001'));
      expect(map['paymentStatus'], equals('paid'));
      expect(map['paymentMethod'], equals('cash'));
      expect(map['items'], isA<List>());
      expect((map['items'] as List).length, equals(1));
    });

    test('toMap handles null optional fields', () {
      final invoice = InvoiceModel(
        id: 'inv-002', bookingId: 'bk-002', userId: 'user-001',
        items: [], subtotal: 0, taxRate: 0, taxAmount: 0,
        totalAmount: 0, paymentStatus: PaymentStatus.pending,
        createdAt: now, updatedAt: now,
      );
      final map = invoice.toMap();
      expect(map['paymentMethod'], isNull);
      expect(map['paidAt'], isNull);
      expect(map['notes'], isNull);
    });
  });

  // ─── PaymentStatus & PaymentMethod enum ──────────────────────────────────

  group('Enums — PaymentStatus', () {
    test('all payment statuses exist', () {
      expect(PaymentStatus.values.length, equals(4));
      expect(PaymentStatus.values, contains(PaymentStatus.pending));
      expect(PaymentStatus.values, contains(PaymentStatus.paid));
      expect(PaymentStatus.values, contains(PaymentStatus.failed));
      expect(PaymentStatus.values, contains(PaymentStatus.refunded));
    });
  });

  group('Enums — PaymentMethod', () {
    test('all payment methods exist', () {
      expect(PaymentMethod.values.length, equals(3));
      expect(PaymentMethod.values, contains(PaymentMethod.cash));
      expect(PaymentMethod.values, contains(PaymentMethod.card));
      expect(PaymentMethod.values, contains(PaymentMethod.online));
    });
  });
}
