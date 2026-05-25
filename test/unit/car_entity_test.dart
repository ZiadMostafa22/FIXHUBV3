// test/unit/car_entity_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:car_maintenance_system_new/core/models/car_model.dart' as core;
import 'package:car_maintenance_system_new/features/car/domain/entities/car_entity.dart';

void main() {
  final now = DateTime(2025, 6, 1);

  // ─── Domain Entity Tests ─────────────────────────────────────────────────

  group('CarEntity — Construction', () {
    test('creates car entity with all required fields', () {
      final car = CarEntity(
        id: 'car-001', userId: 'user-001', make: 'Toyota',
        model: 'Corolla', year: 2023, color: 'White',
        licensePlate: 'ABC 1234', type: CarType.sedan,
        createdAt: now, updatedAt: now,
      );
      expect(car.id, equals('car-001'));
      expect(car.make, equals('Toyota'));
      expect(car.type, equals(CarType.sedan));
    });

    test('creates car entity with optional fields', () {
      final car = CarEntity(
        id: 'car-002', userId: 'user-001', make: 'BMW',
        model: 'X5', year: 2024, color: 'Black',
        licensePlate: 'XYZ 5678', type: CarType.suv,
        vin: 'WBAPH5C55BA123456', engineType: 'V6',
        mileage: 15000, images: ['img1.jpg', 'img2.jpg'],
        createdAt: now, updatedAt: now,
      );
      expect(car.vin, equals('WBAPH5C55BA123456'));
      expect(car.engineType, equals('V6'));
      expect(car.mileage, equals(15000));
      expect(car.images!.length, equals(2));
    });

    test('optional fields default to null', () {
      final car = CarEntity(
        id: 'car-003', userId: 'user-001', make: 'Kia',
        model: 'Cerato', year: 2022, color: 'Silver',
        licensePlate: 'DEF 9012', type: CarType.sedan,
        createdAt: now, updatedAt: now,
      );
      expect(car.vin, isNull);
      expect(car.engineType, isNull);
      expect(car.mileage, isNull);
      expect(car.images, isNull);
    });
  });

  group('CarEntity — displayName & fullInfo', () {
    test('displayName returns year make model', () {
      final car = CarEntity(
        id: 'car-001', userId: 'user-001', make: 'Toyota',
        model: 'Corolla', year: 2023, color: 'White',
        licensePlate: 'ABC 1234', type: CarType.sedan,
        createdAt: now, updatedAt: now,
      );
      expect(car.displayName, equals('2023 Toyota Corolla'));
    });

    test('fullInfo returns complete description', () {
      final car = CarEntity(
        id: 'car-001', userId: 'user-001', make: 'Hyundai',
        model: 'Tucson', year: 2024, color: 'Red',
        licensePlate: 'GHI 5678', type: CarType.suv,
        createdAt: now, updatedAt: now,
      );
      expect(car.fullInfo, equals('2024 Hyundai Tucson - Red - GHI 5678'));
    });
  });

  group('CarEntity — copyWith', () {
    test('copyWith updates specified fields', () {
      final original = CarEntity(
        id: 'car-001', userId: 'user-001', make: 'Toyota',
        model: 'Corolla', year: 2023, color: 'White',
        licensePlate: 'ABC 1234', type: CarType.sedan,
        createdAt: now, updatedAt: now,
      );
      final updated = original.copyWith(color: 'Black', mileage: 5000);
      expect(updated.color, equals('Black'));
      expect(updated.mileage, equals(5000));
      expect(updated.make, equals('Toyota'));
    });

    test('copyWith preserves all unchanged fields', () {
      final original = CarEntity(
        id: 'car-001', userId: 'user-001', make: 'BMW',
        model: 'X3', year: 2024, color: 'Blue',
        licensePlate: 'JKL 9012', type: CarType.suv,
        vin: 'VIN123', createdAt: now, updatedAt: now,
      );
      final updated = original.copyWith(year: 2025);
      expect(updated.id, equals(original.id));
      expect(updated.vin, equals('VIN123'));
      expect(updated.type, equals(CarType.suv));
    });
  });

  group('CarEntity — CarType enum', () {
    test('all car types are valid', () {
      expect(CarType.values.length, equals(7));
      expect(CarType.values, contains(CarType.sedan));
      expect(CarType.values, contains(CarType.suv));
      expect(CarType.values, contains(CarType.hatchback));
      expect(CarType.values, contains(CarType.truck));
    });
  });

  // ─── Core Model Serialization Tests ──────────────────────────────────────

  group('core.CarEntity — fromMap', () {
    test('fromMap creates entity from map', () {
      final map = {
        'id': 'car-001', 'userId': 'user-001', 'make': 'Toyota',
        'model': 'Camry', 'year': 2023, 'color': 'Silver',
        'licensePlate': 'MNO 3456', 'type': 'sedan',
        'vin': null, 'engineType': null, 'mileage': null, 'images': null,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };
      final car = core.CarEntity.fromMap(map);
      expect(car.make, equals('Toyota'));
      expect(car.model, equals('Camry'));
      expect(car.type, equals(core.CarType.sedan));
    });

    test('unknown car type defaults to sedan', () {
      final map = {
        'id': 'car-x', 'userId': 'u', 'make': 'X', 'model': 'Y',
        'year': 2020, 'color': 'W', 'licensePlate': 'P',
        'type': 'spaceship',
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };
      final car = core.CarEntity.fromMap(map);
      expect(car.type, equals(core.CarType.sedan));
    });
  });

  group('core.CarEntity — fromFirestore', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() { fakeFirestore = FakeFirebaseFirestore(); });

    test('fromFirestore parses Firestore document correctly', () async {
      await fakeFirestore.collection('cars').doc('car-fs-001').set({
        'userId': 'user-001', 'make': 'Nissan', 'model': 'Sunny',
        'year': 2022, 'color': 'Gray', 'licensePlate': 'QRS 7890',
        'type': 'sedan', 'vin': null, 'engineType': null,
        'mileage': null, 'images': null,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });
      final snap = await fakeFirestore.collection('cars').doc('car-fs-001').get();
      final car = core.CarEntity.fromFirestore(snap.data()!, 'car-fs-001');
      expect(car.id, equals('car-fs-001'));
      expect(car.make, equals('Nissan'));
    });
  });

  group('core.CarEntity — toMap', () {
    test('toMap includes id and all fields', () {
      final car = core.CarEntity(
        id: 'car-001', userId: 'user-001', make: 'Honda',
        model: 'Civic', year: 2023, color: 'Red',
        licensePlate: 'TUV 1234', type: core.CarType.sedan,
        createdAt: now, updatedAt: now,
      );
      final map = car.toMap();
      expect(map['id'], equals('car-001'));
      expect(map['make'], equals('Honda'));
      expect(map['type'], equals('sedan'));
    });
  });

  group('core.CarEntity — toFirestore', () {
    test('toFirestore excludes id', () {
      final car = core.CarEntity(
        id: 'car-001', userId: 'user-001', make: 'Honda',
        model: 'Civic', year: 2023, color: 'Red',
        licensePlate: 'TUV 1234', type: core.CarType.sedan,
        createdAt: now, updatedAt: now,
      );
      final map = car.toFirestore();
      expect(map.containsKey('id'), isFalse);
      expect(map['make'], equals('Honda'));
    });
  });
}
