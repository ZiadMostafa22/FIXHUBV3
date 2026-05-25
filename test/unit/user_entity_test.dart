// test/unit/user_entity_test.dart
// Unit tests for UserEntity and UserDto conversion logic.

import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:car_maintenance_system_new/features/auth/domain/entities/user_entity.dart';
import 'package:car_maintenance_system_new/features/auth/data/models/user_dto.dart';
import '../helpers/test_fixtures.dart';

void main() {
  group('UserEntity — copyWith', () {
    test('copyWith creates updated entity and leaves original unchanged', () {
      final original = TestFixtures.customerUser();
      final updated = original.copyWith(name: 'New Name', isActive: false);

      expect(updated.name, equals('New Name'));
      expect(updated.isActive, isFalse);
      expect(original.name, equals('Ahmed Hassan'));
      expect(original.isActive, isTrue);
    });

    test('copyWith preserves all unchanged fields', () {
      final original = TestFixtures.technicianUser();
      final updated = original.copyWith(phone: '+20 999 999 9999');

      expect(updated.id, equals(original.id));
      expect(updated.email, equals(original.email));
      expect(updated.role, equals(UserRole.technician));
    });
  });

  group('UserEntity — Roles', () {
    test('customer role is correct', () {
      expect(TestFixtures.customerUser().role, equals(UserRole.customer));
    });

    test('technician role is correct', () {
      expect(TestFixtures.technicianUser().role, equals(UserRole.technician));
    });

    test('admin role is correct', () {
      expect(TestFixtures.adminUser().role, equals(UserRole.admin));
    });

    test('cashier role is correct', () {
      expect(TestFixtures.cashierUser().role, equals(UserRole.cashier));
    });
  });

  group('UserDto — Firestore Serialization', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    test('UserDto.fromFirestore correctly parses Firestore data', () async {
      final now = DateTime(2025, 1, 1, 12, 0);

      // Write a user document using FakeFirestore
      await fakeFirestore.collection('users').doc('test-uid').set({
        'email': 'test@fixhub.test',
        'name': 'Test User',
        'phone': '+20 100 000 0000',
        'role': 'customer',
        'isActive': true,
        'profileImageUrl': null,
        'inviteCodeId': null,
        'inviteCode': null,
        'preferences': null,
        'createdAt': now,
        'updatedAt': now,
      });

      final snap = await fakeFirestore.collection('users').doc('test-uid').get();
      final data = snap.data()!;

      final dto = UserDto.fromFirestore(data, 'test-uid');

      expect(dto.id, equals('test-uid'));
      expect(dto.email, equals('test@fixhub.test'));
      expect(dto.name, equals('Test User'));
      expect(dto.role, equals(UserRole.customer));
      expect(dto.isActive, isTrue);
    });

    test('UserDto.toEntity produces correct UserEntity', () async {
      final now = DateTime(2025, 1, 1, 12, 0);

      await fakeFirestore.collection('users').doc('dto-uid').set({
        'email': 'dto@fixhub.test',
        'name': 'DTO User',
        'phone': '+20 100 111 2222',
        'role': 'technician',
        'isActive': true,
        'profileImageUrl': null,
        'inviteCodeId': null,
        'inviteCode': null,
        'preferences': null,
        'createdAt': now,
        'updatedAt': now,
      });

      final snap = await fakeFirestore.collection('users').doc('dto-uid').get();
      final dto = UserDto.fromFirestore(snap.data()!, 'dto-uid');
      final entity = dto.toEntity();

      expect(entity, isA<UserEntity>());
      expect(entity.id, equals('dto-uid'));
      expect(entity.role, equals(UserRole.technician));
    });

    test('UserDto.fromEntity serializes domain entity correctly', () {
      final entity = TestFixtures.adminUser();
      final dto = UserDto.fromEntity(entity);

      expect(dto.id, equals(entity.id));
      expect(dto.email, equals(entity.email));
      expect(dto.role, equals(entity.role));
      expect(dto.isActive, equals(entity.isActive));
    });

    test('UserDto.toFirestore produces correct map', () {
      final entity = TestFixtures.customerUser();
      final dto = UserDto.fromEntity(entity);
      final map = dto.toFirestore();

      expect(map['email'], equals('customer@fixhub.test'));
      expect(map['name'], equals('Ahmed Hassan'));
      expect(map['role'], equals('customer'));
      expect(map['isActive'], isTrue);
      // id must NOT be included in toFirestore (Firestore doc id is separate)
      expect(map.containsKey('id'), isFalse);
    });

    test('Unknown role defaults to customer during fromFirestore', () async {
      final now = DateTime(2025, 1, 1);

      await fakeFirestore.collection('users').doc('unknown-role').set({
        'email': 'x@fixhub.test',
        'name': 'X',
        'phone': '+00',
        'role': 'unknown_role_xyz', // not a valid enum
        'isActive': true,
        'profileImageUrl': null,
        'inviteCodeId': null,
        'inviteCode': null,
        'preferences': null,
        'createdAt': now,
        'updatedAt': now,
      });

      final snap = await fakeFirestore
          .collection('users')
          .doc('unknown-role')
          .get();
      final dto = UserDto.fromFirestore(snap.data()!, 'unknown-role');
      expect(dto.role, equals(UserRole.customer));
    });
  });
}
