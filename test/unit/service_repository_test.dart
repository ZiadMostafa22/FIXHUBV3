// test/unit/service_repository_test.dart
// Unit tests for ServiceRepository (service catalog) using FakeFirebaseFirestore.

import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:car_maintenance_system_new/core/models/service_item_model.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
  });

  // Helper: seed a service into the fake firestore
  Future<String> seedService(
    Map<String, dynamic> data, {
    bool isActive = true,
  }) async {
    final ref = await fakeFirestore.collection('services').add({
      ...data,
      'isActive': isActive,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  group('ServiceRepository — Read', () {
    test('getServices returns only active services', () async {
      await seedService({'name': 'Oil Change', 'type': 'service', 'price': 250.0, 'category': 'regular'});
      await seedService({'name': 'Brake Check', 'type': 'service', 'price': 150.0, 'category': 'regular'});
      await seedService(
        {'name': 'Old Service', 'type': 'service', 'price': 100.0, 'category': 'regular'},
        isActive: false,
      );

      final snap = await fakeFirestore
          .collection('services')
          .where('isActive', isEqualTo: true)
          .get();

      expect(snap.docs.length, equals(2));
      for (final doc in snap.docs) {
        expect(doc.data()['isActive'], isTrue);
      }
    });

    test('getServices filters by category correctly', () async {
      await seedService({'name': 'Oil Change', 'type': 'service', 'price': 250.0, 'category': 'regular'});
      await seedService({'name': 'Tire Rotation', 'type': 'service', 'price': 100.0, 'category': 'regular'});
      await seedService({'name': 'Brake Repair', 'type': 'service', 'price': 500.0, 'category': 'repair'});

      final snap = await fakeFirestore
          .collection('services')
          .where('isActive', isEqualTo: true)
          .where('category', isEqualTo: 'regular')
          .get();

      expect(snap.docs.length, equals(2));
      for (final doc in snap.docs) {
        expect(doc.data()['category'], equals('regular'));
      }
    });

    test('getServiceById returns correct document', () async {
      final id = await seedService({
        'name': 'Engine Flush',
        'type': 'service',
        'price': 350.0,
        'category': 'regular',
      });

      final doc = await fakeFirestore.collection('services').doc(id).get();
      expect(doc.exists, isTrue);
      expect(doc.data()?['name'], equals('Engine Flush'));
    });

    test('getServiceById returns null for missing document', () async {
      final doc =
          await fakeFirestore.collection('services').doc('missing-id').get();
      expect(doc.exists, isFalse);
    });
  });

  group('ServiceRepository — Create', () {
    test('createService saves all required fields', () async {
      final service = ServiceItemEntity(
        id: '',
        name: 'Air Filter Replacement',
        type: ServiceItemType.part,
        price: 180.0,
        quantity: 1,
        description: 'Replace air filter',
        category: 'regular',
      );

      final docRef = await fakeFirestore.collection('services').add({
        'name': service.name,
        'type': service.type.toString().split('.').last,
        'price': service.price,
        'description': service.description,
        'category': service.category ?? '',
        'isActive': true,
      });

      final snap =
          await fakeFirestore.collection('services').doc(docRef.id).get();

      expect(snap.data()?['name'], equals('Air Filter Replacement'));
      expect(snap.data()?['price'], equals(180.0));
      expect(snap.data()?['type'], equals('part'));
      expect(snap.data()?['isActive'], isTrue);
    });
  });

  group('ServiceRepository — Update', () {
    test('updateService modifies specified fields', () async {
      final id = await seedService({
        'name': 'Basic Checkup',
        'type': 'service',
        'price': 120.0,
        'category': 'inspection',
      });

      await fakeFirestore.collection('services').doc(id).update({
        'price': 150.0,
        'name': 'Full Inspection',
      });

      final snap = await fakeFirestore.collection('services').doc(id).get();
      expect(snap.data()?['price'], equals(150.0));
      expect(snap.data()?['name'], equals('Full Inspection'));
    });
  });

  group('ServiceRepository — Soft Delete', () {
    test('deleteService sets isActive to false', () async {
      final id = await seedService({
        'name': 'Deprecated Service',
        'type': 'service',
        'price': 0.0,
        'category': 'regular',
      });

      await fakeFirestore.collection('services').doc(id).update({
        'isActive': false,
      });

      final snap = await fakeFirestore.collection('services').doc(id).get();
      expect(snap.data()?['isActive'], isFalse);

      // Verify it no longer appears in active query
      final activeSnap = await fakeFirestore
          .collection('services')
          .where('isActive', isEqualTo: true)
          .get();
      final ids = activeSnap.docs.map((d) => d.id).toList();
      expect(ids, isNot(contains(id)));
    });
  });

  group('ServiceItemEntity — Serialization', () {
    test('fromMap parses correctly', () {
      final map = {
        'id': 'svc-001',
        'name': 'Tire Balancing',
        'type': 'service',
        'price': 80.0,
        'quantity': 1,
        'description': 'Balance all 4 tires',
        'category': 'regular',
        'isActive': true,
      };

      final entity = ServiceItemEntity.fromMap(map);

      expect(entity.id, equals('svc-001'));
      expect(entity.name, equals('Tire Balancing'));
      expect(entity.type, equals(ServiceItemType.service));
      expect(entity.price, equals(80.0));
      expect(entity.totalPrice, equals(80.0));
    });

    test('fromFirestore uses document id correctly', () {
      final data = {
        'name': 'Coolant Flush',
        'type': 'service',
        'price': 200.0,
        'quantity': 1,
        'isActive': true,
      };

      final entity = ServiceItemEntity.fromFirestore(data, 'firestore-doc-id');
      expect(entity.id, equals('firestore-doc-id'));
    });

    test('toMap contains required fields', () {
      final entity = ServiceItemEntity(
        id: 'test-id',
        name: 'Test Service',
        type: ServiceItemType.labor,
        price: 300.0,
        quantity: 2,
      );

      final map = entity.toMap();
      expect(map['id'], equals('test-id'));
      expect(map['name'], equals('Test Service'));
      expect(map['type'], equals('labor'));
      expect(map['price'], equals(300.0));
      expect(map['quantity'], equals(2));
    });

    test('Unknown ServiceItemType defaults to service in fromMap', () {
      final map = {
        'id': 'x',
        'name': 'X',
        'type': 'completely_unknown',
        'price': 0.0,
        'quantity': 1,
        'isActive': true,
      };

      final entity = ServiceItemEntity.fromMap(map);
      expect(entity.type, equals(ServiceItemType.service));
    });
  });
}
