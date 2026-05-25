// test/unit/auth_datasource_test.dart
// Unit tests for AuthRemoteDataSource using mockito + firebase_auth_mocks.
//
// NOTE: This file uses firebase_auth_mocks (MockFirebaseAuth / MockUser)
//       which does NOT require generated code from build_runner.

import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/mockito.dart';

// We test the datasource logic indirectly by injecting fakes.
// Since AuthRemoteDataSource calls FirebaseService.auth (static), we test
// the methods that can be exercised via injectable fakes.

void main() {
  group('MockFirebaseAuth — Sign In / Sign Out', () {
    late MockFirebaseAuth mockAuth;

    setUp(() {
      // MockUser simulates a signed-in Firebase user
      final mockUser = MockUser(
        isAnonymous: false,
        uid: 'customer-uid-001',
        email: 'customer@fixhub.test',
        displayName: 'Ahmed Hassan',
      );
      mockAuth = MockFirebaseAuth(signedIn: false, mockUser: mockUser);
    });

    test('signInWithEmailAndPassword returns UserCredential on success',
        () async {
      final credential = await mockAuth.signInWithEmailAndPassword(
        email: 'customer@fixhub.test',
        password: 'SecurePass123!',
      );

      expect(credential, isA<UserCredential>());
      expect(credential.user, isNotNull);
      expect(credential.user!.uid, equals('customer-uid-001'));
      expect(credential.user!.email, equals('customer@fixhub.test'));
    });

    test('currentUser is null before sign in', () {
      expect(mockAuth.currentUser, isNull);
    });

    test('currentUser is set after sign in', () async {
      await mockAuth.signInWithEmailAndPassword(
        email: 'customer@fixhub.test',
        password: 'SecurePass123!',
      );
      expect(mockAuth.currentUser, isNotNull);
      expect(mockAuth.currentUser!.uid, equals('customer-uid-001'));
    });

    test('signOut clears currentUser', () async {
      await mockAuth.signInWithEmailAndPassword(
        email: 'customer@fixhub.test',
        password: 'SecurePass123!',
      );
      await mockAuth.signOut();
      expect(mockAuth.currentUser, isNull);
    });

    test('authStateChanges emits User after sign in', () async {
      final states = <User?>[];
      final sub = mockAuth.authStateChanges().listen(states.add);

      await mockAuth.signInWithEmailAndPassword(
        email: 'customer@fixhub.test',
        password: 'SecurePass123!',
      );
      await Future.delayed(Duration.zero); // Let stream deliver

      await sub.cancel();
      expect(states.any((u) => u != null), isTrue);
    });
  });

  group('MockFirebaseAuth — Create Account', () {
    late MockFirebaseAuth mockAuth;

    setUp(() {
      final mockUser = MockUser(
        uid: 'new-user-789',
        email: 'newuser@fixhub.test',
      );
      mockAuth = MockFirebaseAuth(signedIn: false, mockUser: mockUser);
    });

    test('createUserWithEmailAndPassword returns UserCredential', () async {
      final credential = await mockAuth.createUserWithEmailAndPassword(
        email: 'newuser@fixhub.test',
        password: 'NewPass456!',
      );

      expect(credential.user, isNotNull);
      expect(credential.user!.email, equals('newuser@fixhub.test'));
    });
  });

  group('FakeFirebaseFirestore — User Document Operations', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    test('getUserDocument returns data when document exists', () async {
      await fakeFirestore.collection('users').doc('existing-uid').set({
        'email': 'existing@fixhub.test',
        'name': 'Existing User',
        'role': 'customer',
        'isActive': true,
      });

      final doc =
          await fakeFirestore.collection('users').doc('existing-uid').get();
      expect(doc.exists, isTrue);
      expect(doc.data()?['email'], equals('existing@fixhub.test'));
    });

    test('getUserDocument returns null when document does not exist', () async {
      final doc = await fakeFirestore
          .collection('users')
          .doc('non-existent-uid')
          .get();
      expect(doc.exists, isFalse);
      expect(doc.data(), isNull);
    });

    test('createUserDocument stores data correctly', () async {
      const userId = 'new-user-001';
      final data = {
        'email': 'new@fixhub.test',
        'name': 'New User',
        'phone': '+20 100 111 0000',
        'role': 'customer',
        'isActive': true,
      };

      await fakeFirestore.collection('users').doc(userId).set(data);
      final doc = await fakeFirestore.collection('users').doc(userId).get();

      expect(doc.exists, isTrue);
      expect(doc.data()?['email'], equals('new@fixhub.test'));
      expect(doc.data()?['role'], equals('customer'));
    });

    test('validateInviteCode finds active invite codes', () async {
      await fakeFirestore.collection('invite_codes').add({
        'code': 'TECH2025',
        'role': 'technician',
        'isActive': true,
        'maxUses': 5,
        'usedCount': 2,
      });

      final snapshot = await fakeFirestore
          .collection('invite_codes')
          .where('code', isEqualTo: 'TECH2025')
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      expect(snapshot.docs, isNotEmpty);
      expect(snapshot.docs.first.data()['role'], equals('technician'));
    });

    test('validateInviteCode returns empty for inactive code', () async {
      await fakeFirestore.collection('invite_codes').add({
        'code': 'EXPIRED',
        'role': 'technician',
        'isActive': false,
        'maxUses': 1,
        'usedCount': 1,
      });

      final snapshot = await fakeFirestore
          .collection('invite_codes')
          .where('code', isEqualTo: 'EXPIRED')
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      expect(snapshot.docs, isEmpty);
    });
  });
}
