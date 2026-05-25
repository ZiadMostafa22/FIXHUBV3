// test/unit/service_item_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:car_maintenance_system_new/core/models/service_item_model.dart';

void main() {
  group('ServiceItemEntity — Construction', () {
    test('creates service item with defaults', () {
      final item = ServiceItemEntity(
        id: 'svc-001', name: 'Oil Change', type: ServiceItemType.service,
        price: 250.0,
      );
      expect(item.quantity, equals(1));
      expect(item.isActive, isTrue);
      expect(item.description, isNull);
      expect(item.category, isNull);
    });

    test('creates part with quantity', () {
      final item = ServiceItemEntity(
        id: 'svc-002', name: 'Brake Pad', type: ServiceItemType.part,
        price: 400.0, quantity: 2, category: 'repair',
      );
      expect(item.quantity, equals(2));
      expect(item.category, equals('repair'));
    });
  });

  group('ServiceItemEntity — totalPrice', () {
    test('totalPrice = price * quantity', () {
      final item = ServiceItemEntity(
        id: 's1', name: 'Part', type: ServiceItemType.part,
        price: 100.0, quantity: 3,
      );
      expect(item.totalPrice, equals(300.0));
    });

    test('totalPrice for single quantity', () {
      final item = ServiceItemEntity(
        id: 's2', name: 'Labor', type: ServiceItemType.labor,
        price: 200.0,
      );
      expect(item.totalPrice, equals(200.0));
    });
  });

  group('ServiceItemEntity — fromMap', () {
    test('fromMap parses correctly', () {
      final map = {
        'id': 'svc-001', 'name': 'Engine Tune-up',
        'type': 'service', 'price': 500, 'quantity': 1,
        'description': 'Full engine tune-up', 'category': 'regular',
        'isActive': true,
      };
      final item = ServiceItemEntity.fromMap(map);
      expect(item.name, equals('Engine Tune-up'));
      expect(item.type, equals(ServiceItemType.service));
      expect(item.price, equals(500.0));
      expect(item.category, equals('regular'));
    });

    test('unknown type defaults to service', () {
      final map = {
        'id': 'x', 'name': 'X', 'type': 'unknown_abc', 'price': 10,
      };
      final item = ServiceItemEntity.fromMap(map);
      expect(item.type, equals(ServiceItemType.service));
    });

    test('missing fields use defaults', () {
      final map = <String, dynamic>{};
      final item = ServiceItemEntity.fromMap(map);
      expect(item.id, equals(''));
      expect(item.name, equals(''));
      expect(item.price, equals(0.0));
      expect(item.quantity, equals(1));
      expect(item.isActive, isTrue);
    });
  });

  group('ServiceItemEntity — fromFirestore', () {
    late FakeFirebaseFirestore fakeFirestore;
    setUp(() { fakeFirestore = FakeFirebaseFirestore(); });

    test('fromFirestore uses doc id as entity id', () async {
      await fakeFirestore.collection('services').doc('svc-fs-001').set({
        'name': 'Tire Rotation', 'type': 'service', 'price': 150,
        'description': 'Rotate all 4 tires', 'category': 'regular',
        'isActive': true,
      });
      final snap = await fakeFirestore.collection('services').doc('svc-fs-001').get();
      final item = ServiceItemEntity.fromFirestore(snap.data()!, 'svc-fs-001');
      expect(item.id, equals('svc-fs-001'));
      expect(item.name, equals('Tire Rotation'));
    });
  });

  group('ServiceItemEntity — toMap', () {
    test('toMap includes id', () {
      final item = ServiceItemEntity(
        id: 'svc-001', name: 'Filter', type: ServiceItemType.part,
        price: 80.0, quantity: 1, isActive: true,
      );
      final map = item.toMap();
      expect(map['id'], equals('svc-001'));
      expect(map['type'], equals('part'));
    });
  });

  group('ServiceItemEntity — toFirestore', () {
    test('toFirestore excludes id and quantity', () {
      final item = ServiceItemEntity(
        id: 'svc-001', name: 'Filter', type: ServiceItemType.part,
        price: 80.0, quantity: 2, isActive: true,
      );
      final map = item.toFirestore();
      expect(map.containsKey('id'), isFalse);
      expect(map['name'], equals('Filter'));
      expect(map['type'], equals('part'));
    });
  });

  group('ServiceItemEntity — copyWith', () {
    test('copyWith updates price and quantity', () {
      final original = ServiceItemEntity(
        id: 'svc-001', name: 'Oil', type: ServiceItemType.service,
        price: 250.0, quantity: 1,
      );
      final updated = original.copyWith(price: 300.0, quantity: 2);
      expect(updated.price, equals(300.0));
      expect(updated.quantity, equals(2));
      expect(updated.totalPrice, equals(600.0));
      expect(original.price, equals(250.0));
    });

    test('copyWith deactivates item', () {
      final original = ServiceItemEntity(
        id: 'svc-001', name: 'Oil', type: ServiceItemType.service,
        price: 250.0, isActive: true,
      );
      final deactivated = original.copyWith(isActive: false);
      expect(deactivated.isActive, isFalse);
      expect(original.isActive, isTrue);
    });
  });

  group('Enums — ServiceItemType', () {
    test('all service item types exist', () {
      expect(ServiceItemType.values.length, equals(3));
      expect(ServiceItemType.values, contains(ServiceItemType.part));
      expect(ServiceItemType.values, contains(ServiceItemType.labor));
      expect(ServiceItemType.values, contains(ServiceItemType.service));
    });
  });
}
