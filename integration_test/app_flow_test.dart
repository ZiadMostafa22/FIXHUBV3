// integration_test/app_flow_test.dart
// Integration tests simulating real user flows through the FixHub app.
// Run with: flutter test integration_test/app_flow_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Fake Services ─────────────────────────────────────────────────────────────

class FakeAuthService {
  final MockFirebaseAuth _auth;
  FakeAuthService(this._auth);

  Future<String?> signIn(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
      return cred.user?.uid;
    } catch (_) { return null; }
  }

  Future<void> signOut() => _auth.signOut();
  String? get currentUserId => _auth.currentUser?.uid;
  bool get isSignedIn => _auth.currentUser != null;
}

class FakeBookingService {
  final FakeFirebaseFirestore _db;
  FakeBookingService(this._db);

  Future<String> createBooking({
    required String userId, required String carId,
    required String serviceId, required String maintenanceType,
    required DateTime scheduledDate, required String timeSlot,
    String? description,
  }) async {
    final now = Timestamp.fromDate(DateTime.now());
    final ref = await _db.collection('bookings').add({
      'userId': userId, 'carId': carId, 'serviceId': serviceId,
      'maintenanceType': maintenanceType,
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'timeSlot': timeSlot, 'status': 'pending',
      'description': description, 'isPaid': false,
      'createdAt': now, 'updatedAt': now,
    });
    return ref.id;
  }

  Future<void> updateStatus(String id, String status, {DateTime? completedAt}) async {
    final data = <String, dynamic>{
      'status': status,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
    if (completedAt != null) data['completedAt'] = Timestamp.fromDate(completedAt);
    await _db.collection('bookings').doc(id).update(data);
  }

  Future<Map<String, dynamic>?> getBooking(String id) async {
    final snap = await _db.collection('bookings').doc(id).get();
    if (!snap.exists) return null;
    return {'id': snap.id, ...snap.data()!};
  }

  Future<List<Map<String, dynamic>>> getUserBookings(String userId) async {
    final snap = await _db.collection('bookings')
        .where('userId', isEqualTo: userId).get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  Future<List<Map<String, dynamic>>> getBookingsByStatus(String status) async {
    final snap = await _db.collection('bookings')
        .where('status', isEqualTo: status).get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  Future<void> rateBooking({
    required String bookingId, required double rating, required String comment,
  }) async {
    await _db.collection('bookings').doc(bookingId).update({
      'rating': rating, 'ratingComment': comment,
      'ratedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> processPayment({
    required String bookingId, required String cashierId,
    required String paymentMethod, double? totalCost,
  }) async {
    await _db.collection('bookings').doc(bookingId).update({
      'isPaid': true, 'status': 'completed',
      'cashierId': cashierId, 'paymentMethod': paymentMethod,
      'totalCost': totalCost, 'paidAt': Timestamp.fromDate(DateTime.now()),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> cancelBooking(String bookingId, String reason) async {
    await _db.collection('bookings').doc(bookingId).update({
      'status': 'cancelled', 'cancellationReason': reason,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> deleteBooking(String bookingId) async {
    await _db.collection('bookings').doc(bookingId).delete();
  }
}

class FakeUserService {
  final FakeFirebaseFirestore _db;
  FakeUserService(this._db);

  Future<void> createUser({
    required String uid, required String email,
    required String name, required String phone, required String role,
  }) async {
    final now = Timestamp.fromDate(DateTime.now());
    await _db.collection('users').doc(uid).set({
      'email': email, 'name': name, 'phone': phone,
      'role': role, 'isActive': true,
      'createdAt': now, 'updatedAt': now,
    });
  }

  Future<Map<String, dynamic>?> getUser(String uid) async {
    final snap = await _db.collection('users').doc(uid).get();
    if (!snap.exists) return null;
    return {'id': snap.id, ...snap.data()!};
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update(data);
  }

  Future<void> deactivateUser(String uid) async {
    await _db.collection('users').doc(uid).update({'isActive': false});
  }
}

// ─── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late MockFirebaseAuth mockAuth;
  late FakeFirebaseFirestore fakeDb;
  late FakeAuthService authService;
  late FakeBookingService bookingService;
  late FakeUserService userService;

  setUp(() async {
    final mockUser = MockUser(
      uid: 'customer-001',
      email: 'customer@fixhub.test',
      displayName: 'Ahmed Hassan',
    );
    mockAuth = MockFirebaseAuth(signedIn: false, mockUser: mockUser);
    fakeDb = FakeFirebaseFirestore();
    authService = FakeAuthService(mockAuth);
    bookingService = FakeBookingService(fakeDb);
    userService = FakeUserService(fakeDb);

    // Seed users
    await userService.createUser(
      uid: 'customer-001', email: 'customer@fixhub.test',
      name: 'Ahmed Hassan', phone: '+20 100 000 0001', role: 'customer',
    );
    await userService.createUser(
      uid: 'tech-001', email: 'tech@fixhub.test',
      name: 'Mohamed Ali', phone: '+20 100 000 0002', role: 'technician',
    );
    await userService.createUser(
      uid: 'cashier-001', email: 'cashier@fixhub.test',
      name: 'Sara Khaled', phone: '+20 100 000 0003', role: 'cashier',
    );
    await userService.createUser(
      uid: 'admin-001', email: 'admin@fixhub.test',
      name: 'Admin User', phone: '+20 100 000 0004', role: 'admin',
    );
  });

  tearDown(() async {
    if (authService.isSignedIn) await authService.signOut();
  });

  // ─── Flow 1: Authentication ────────────────────────────────────────────────

  group('Flow 1: Authentication', () {
    testWidgets('customer signs in with valid credentials', (tester) async {
      final uid = await authService.signIn('customer@fixhub.test', 'Pass123!');
      expect(uid, isNotNull);
      expect(authService.isSignedIn, isTrue);
    });

    testWidgets('auth state is preserved after sign in', (tester) async {
      await authService.signIn('customer@fixhub.test', 'Pass123!');
      expect(mockAuth.currentUser?.email, equals('customer@fixhub.test'));
    });

    testWidgets('sign out clears auth state', (tester) async {
      await authService.signIn('customer@fixhub.test', 'Pass123!');
      await authService.signOut();
      expect(authService.isSignedIn, isFalse);
    });

    testWidgets('unauthenticated user has no userId', (tester) async {
      expect(authService.currentUserId, isNull);
      expect(authService.isSignedIn, isFalse);
    });
  });

  // ─── Flow 2: User Management ───────────────────────────────────────────────

  group('Flow 2: User Management', () {
    testWidgets('admin can read any user document', (tester) async {
      final user = await userService.getUser('customer-001');
      expect(user, isNotNull);
      expect(user!['role'], equals('customer'));
    });

    testWidgets('user document contains correct role', (tester) async {
      final tech = await userService.getUser('tech-001');
      expect(tech!['role'], equals('technician'));
      final cashier = await userService.getUser('cashier-001');
      expect(cashier!['role'], equals('cashier'));
    });

    testWidgets('admin can deactivate a user', (tester) async {
      await userService.deactivateUser('customer-001');
      final user = await userService.getUser('customer-001');
      expect(user!['isActive'], isFalse);
    });

    testWidgets('user profile can be updated', (tester) async {
      await userService.updateUser('customer-001', {'phone': '+20 111 222 3333'});
      final user = await userService.getUser('customer-001');
      expect(user!['phone'], equals('+20 111 222 3333'));
    });
  });

  // ─── Flow 3: Create Booking ────────────────────────────────────────────────

  group('Flow 3: Create Booking (Customer)', () {
    late String userId;

    setUp(() async {
      final uid = await authService.signIn('customer@fixhub.test', 'Pass123!');
      userId = uid!;
    });

    testWidgets('customer creates a regular maintenance booking', (tester) async {
      final id = await bookingService.createBooking(
        userId: userId, carId: 'car-001', serviceId: 'svc-oil',
        maintenanceType: 'regular', scheduledDate: DateTime(2025, 7, 10),
        timeSlot: '09:00 AM', description: 'Oil change',
      );
      expect(id, isNotEmpty);
      final b = await bookingService.getBooking(id);
      expect(b!['status'], equals('pending'));
      expect(b['isPaid'], isFalse);
    });

    testWidgets('customer creates a repair booking', (tester) async {
      final id = await bookingService.createBooking(
        userId: userId, carId: 'car-001', serviceId: 'svc-brake',
        maintenanceType: 'repair', scheduledDate: DateTime(2025, 7, 15),
        timeSlot: '11:00 AM',
      );
      final b = await bookingService.getBooking(id);
      expect(b!['maintenanceType'], equals('repair'));
    });

    testWidgets('booking appears in user booking list', (tester) async {
      await bookingService.createBooking(
        userId: userId, carId: 'car-001', serviceId: 'svc-1',
        maintenanceType: 'regular', scheduledDate: DateTime(2025, 7, 10),
        timeSlot: '09:00 AM',
      );
      await bookingService.createBooking(
        userId: userId, carId: 'car-001', serviceId: 'svc-2',
        maintenanceType: 'inspection', scheduledDate: DateTime(2025, 7, 20),
        timeSlot: '02:00 PM',
      );
      final list = await bookingService.getUserBookings(userId);
      expect(list.length, equals(2));
    });

    testWidgets('bookings are isolated between users', (tester) async {
      await bookingService.createBooking(
        userId: userId, carId: 'car-001', serviceId: 'svc-1',
        maintenanceType: 'regular', scheduledDate: DateTime(2025, 7, 10),
        timeSlot: '09:00 AM',
      );
      await bookingService.createBooking(
        userId: 'other-999', carId: 'car-999', serviceId: 'svc-1',
        maintenanceType: 'regular', scheduledDate: DateTime(2025, 7, 11),
        timeSlot: '10:00 AM',
      );
      final myList = await bookingService.getUserBookings(userId);
      expect(myList.length, equals(1));
      expect(myList.first['userId'], equals(userId));
    });

    testWidgets('customer can cancel a pending booking', (tester) async {
      final id = await bookingService.createBooking(
        userId: userId, carId: 'car-001', serviceId: 'svc-1',
        maintenanceType: 'regular', scheduledDate: DateTime(2025, 8, 1),
        timeSlot: '09:00 AM',
      );
      await bookingService.cancelBooking(id, 'Changed my mind');
      final b = await bookingService.getBooking(id);
      expect(b!['status'], equals('cancelled'));
      expect(b['cancellationReason'], equals('Changed my mind'));
    });
  });

  // ─── Flow 4: Technician Job Management ────────────────────────────────────

  group('Flow 4: Technician Job Management', () {
    late String bookingId;

    setUp(() async {
      final uid = await authService.signIn('customer@fixhub.test', 'Pass123!');
      bookingId = await bookingService.createBooking(
        userId: uid!, carId: 'car-001', serviceId: 'svc-brake',
        maintenanceType: 'repair', scheduledDate: DateTime(2025, 7, 10),
        timeSlot: '09:00 AM', description: 'Brake pad replacement',
      );
    });

    testWidgets('admin confirms a pending booking', (tester) async {
      await bookingService.updateStatus(bookingId, 'confirmed');
      final b = await bookingService.getBooking(bookingId);
      expect(b!['status'], equals('confirmed'));
    });

    testWidgets('technician starts work — status becomes inProgress', (tester) async {
      await bookingService.updateStatus(bookingId, 'confirmed');
      await bookingService.updateStatus(bookingId, 'inProgress');
      final b = await bookingService.getBooking(bookingId);
      expect(b!['status'], equals('inProgress'));
    });

    testWidgets('technician completes job with completedAt timestamp', (tester) async {
      await bookingService.updateStatus(bookingId, 'inProgress');
      await bookingService.updateStatus(
        bookingId, 'completedPendingPayment',
        completedAt: DateTime(2025, 7, 10, 12, 30),
      );
      final b = await bookingService.getBooking(bookingId);
      expect(b!['status'], equals('completedPendingPayment'));
      expect(b['completedAt'], isNotNull);
    });

    testWidgets('pending bookings filter returns correct results', (tester) async {
      await bookingService.createBooking(
        userId: 'customer-001', carId: 'car-002', serviceId: 'svc-1',
        maintenanceType: 'regular', scheduledDate: DateTime(2025, 8, 1),
        timeSlot: '10:00 AM',
      );
      await bookingService.updateStatus(bookingId, 'confirmed');
      final pending = await bookingService.getBookingsByStatus('pending');
      for (final b in pending) {
        expect(b['status'], equals('pending'));
      }
    });

    testWidgets('admin can delete a booking', (tester) async {
      await bookingService.deleteBooking(bookingId);
      final b = await bookingService.getBooking(bookingId);
      expect(b, isNull);
    });
  });

  // ─── Flow 5: Payment Processing ───────────────────────────────────────────

  group('Flow 5: Cashier Payment Processing', () {
    late String bookingId;

    setUp(() async {
      final uid = await authService.signIn('customer@fixhub.test', 'Pass123!');
      bookingId = await bookingService.createBooking(
        userId: uid!, carId: 'car-001', serviceId: 'svc-full',
        maintenanceType: 'inspection', scheduledDate: DateTime(2025, 7, 10),
        timeSlot: '09:00 AM',
      );
      await bookingService.updateStatus(bookingId, 'confirmed');
      await bookingService.updateStatus(bookingId, 'inProgress');
      await bookingService.updateStatus(
        bookingId, 'completedPendingPayment',
        completedAt: DateTime(2025, 7, 10, 11, 0),
      );
    });

    testWidgets('cashier processes cash payment successfully', (tester) async {
      await bookingService.processPayment(
        bookingId: bookingId, cashierId: 'cashier-001',
        paymentMethod: 'cash', totalCost: 850.0,
      );
      final b = await bookingService.getBooking(bookingId);
      expect(b!['status'], equals('completed'));
      expect(b['isPaid'], isTrue);
      expect(b['paymentMethod'], equals('cash'));
      expect(b['totalCost'], equals(850.0));
    });

    testWidgets('cashier processes card payment successfully', (tester) async {
      await bookingService.processPayment(
        bookingId: bookingId, cashierId: 'cashier-001',
        paymentMethod: 'card', totalCost: 1200.0,
      );
      final b = await bookingService.getBooking(bookingId);
      expect(b!['isPaid'], isTrue);
      expect(b['paymentMethod'], equals('card'));
      expect(b['cashierId'], equals('cashier-001'));
    });

    testWidgets('payment records cashier ID correctly', (tester) async {
      await bookingService.processPayment(
        bookingId: bookingId, cashierId: 'cashier-001',
        paymentMethod: 'cash', totalCost: 500.0,
      );
      final b = await bookingService.getBooking(bookingId);
      expect(b!['cashierId'], equals('cashier-001'));
    });
  });

  // ─── Flow 6: Rating & Feedback ─────────────────────────────────────────────

  group('Flow 6: Customer Rating & Feedback', () {
    late String bookingId;

    setUp(() async {
      final uid = await authService.signIn('customer@fixhub.test', 'Pass123!');
      bookingId = await bookingService.createBooking(
        userId: uid!, carId: 'car-001', serviceId: 'svc-1',
        maintenanceType: 'regular', scheduledDate: DateTime(2025, 7, 10),
        timeSlot: '09:00 AM',
      );
      await bookingService.updateStatus(bookingId, 'inProgress');
      await bookingService.updateStatus(
        bookingId, 'completedPendingPayment',
        completedAt: DateTime(2025, 7, 10, 12, 0),
      );
      await bookingService.processPayment(
        bookingId: bookingId, cashierId: 'cashier-001',
        paymentMethod: 'cash', totalCost: 450.0,
      );
    });

    testWidgets('customer submits 5-star rating', (tester) async {
      await bookingService.rateBooking(
        bookingId: bookingId, rating: 5.0,
        comment: 'Excellent service!',
      );
      final b = await bookingService.getBooking(bookingId);
      expect(b!['rating'], equals(5.0));
      expect(b['ratingComment'], equals('Excellent service!'));
    });

    testWidgets('customer submits 3-star rating with comment', (tester) async {
      await bookingService.rateBooking(
        bookingId: bookingId, rating: 3.0,
        comment: 'Average, could be better.',
      );
      final b = await bookingService.getBooking(bookingId);
      expect(b!['rating'], equals(3.0));
      expect(b['ratedAt'], isNotNull);
    });

    testWidgets('rating timestamp is recorded', (tester) async {
      await bookingService.rateBooking(
        bookingId: bookingId, rating: 4.5, comment: 'Great job!',
      );
      final b = await bookingService.getBooking(bookingId);
      expect(b!['ratedAt'], isNotNull);
    });
  });

  // ─── Flow 7: Full End-to-End Lifecycle ────────────────────────────────────

  group('Flow 7: Complete Booking Lifecycle (E2E)', () {
    testWidgets('full booking lifecycle: login → book → confirm → pay → rate', (tester) async {
      // 1. Login
      final uid = await authService.signIn('customer@fixhub.test', 'Pass123!');
      expect(uid, isNotNull);

      // 2. Create booking
      final bookingId = await bookingService.createBooking(
        userId: uid!, carId: 'car-lifecycle-001', serviceId: 'svc-full-check',
        maintenanceType: 'inspection', scheduledDate: DateTime(2025, 8, 1),
        timeSlot: '10:00 AM', description: 'Full vehicle inspection',
      );
      var b = await bookingService.getBooking(bookingId);
      expect(b!['status'], equals('pending'));

      // 3. Admin confirms
      await bookingService.updateStatus(bookingId, 'confirmed');
      b = await bookingService.getBooking(bookingId);
      expect(b!['status'], equals('confirmed'));

      // 4. Technician starts
      await bookingService.updateStatus(bookingId, 'inProgress');
      b = await bookingService.getBooking(bookingId);
      expect(b!['status'], equals('inProgress'));

      // 5. Technician completes
      await bookingService.updateStatus(
        bookingId, 'completedPendingPayment',
        completedAt: DateTime(2025, 8, 1, 12, 0),
      );
      b = await bookingService.getBooking(bookingId);
      expect(b!['completedAt'], isNotNull);

      // 6. Cashier pays
      await bookingService.processPayment(
        bookingId: bookingId, cashierId: 'cashier-001',
        paymentMethod: 'digital', totalCost: 600.0,
      );
      b = await bookingService.getBooking(bookingId);
      expect(b!['isPaid'], isTrue);
      expect(b['status'], equals('completed'));

      // 7. Customer rates
      await bookingService.rateBooking(
        bookingId: bookingId, rating: 5.0,
        comment: 'Excellent! Very thorough.',
      );
      b = await bookingService.getBooking(bookingId);
      expect(b!['rating'], equals(5.0));

      // 8. Sign out
      await authService.signOut();
      expect(authService.isSignedIn, isFalse);
    });

    testWidgets('lifecycle with cancellation after confirmation', (tester) async {
      final uid = await authService.signIn('customer@fixhub.test', 'Pass123!');
      final bookingId = await bookingService.createBooking(
        userId: uid!, carId: 'car-002', serviceId: 'svc-oil',
        maintenanceType: 'regular', scheduledDate: DateTime(2025, 8, 5),
        timeSlot: '09:00 AM',
      );
      await bookingService.updateStatus(bookingId, 'confirmed');
      await bookingService.cancelBooking(bookingId, 'Customer request');
      final b = await bookingService.getBooking(bookingId);
      expect(b!['status'], equals('cancelled'));
    });
  });
}
