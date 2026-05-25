// test/helpers/test_fixtures.dart
// Centralized test data factories used across all unit tests.

import 'package:car_maintenance_system_new/features/auth/domain/entities/user_entity.dart';
import 'package:car_maintenance_system_new/features/booking/domain/entities/booking_entity.dart';
import 'package:car_maintenance_system_new/features/booking/domain/entities/service_item_entity.dart';
import 'package:car_maintenance_system_new/core/models/service_item_model.dart' as core_model;

class TestFixtures {
  // ─── Users ──────────────────────────────────────────────────────────────────

  static UserEntity customerUser() => UserEntity(
        id: 'customer-uid-001',
        email: 'customer@fixhub.test',
        name: 'Ahmed Hassan',
        phone: '+20 100 000 0001',
        role: UserRole.customer,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
        isActive: true,
      );

  static UserEntity technicianUser() => UserEntity(
        id: 'tech-uid-001',
        email: 'tech@fixhub.test',
        name: 'Mohamed Ali',
        phone: '+20 100 000 0002',
        role: UserRole.technician,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
        isActive: true,
      );

  static UserEntity adminUser() => UserEntity(
        id: 'admin-uid-001',
        email: 'admin@fixhub.test',
        name: 'Sara Admin',
        phone: '+20 100 000 0003',
        role: UserRole.admin,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
        isActive: true,
      );

  static UserEntity cashierUser() => UserEntity(
        id: 'cashier-uid-001',
        email: 'cashier@fixhub.test',
        name: 'Omar Cashier',
        phone: '+20 100 000 0004',
        role: UserRole.cashier,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
        isActive: true,
      );

  // ─── Service Items ───────────────────────────────────────────────────────────

  // ─── Domain Service Items (no category field) ───────────────────────────────

  static ServiceItemEntity oilChangeItem() => ServiceItemEntity(
        id: 'service-item-001',
        name: 'Engine Oil Change',
        type: ServiceItemType.service,
        price: 250.0,
        quantity: 1,
        description: 'Full synthetic oil change',
      );

  static ServiceItemEntity brakepadItem() => ServiceItemEntity(
        id: 'service-item-002',
        name: 'Front Brake Pads',
        type: ServiceItemType.part,
        price: 400.0,
        quantity: 2,
        description: 'OEM brake pad replacement',
      );

  // ─── Core Model Service Items (has category field) ───────────────────────────

  static core_model.ServiceItemEntity coreOilChangeItem() =>
      core_model.ServiceItemEntity(
        id: 'service-item-001',
        name: 'Engine Oil Change',
        type: core_model.ServiceItemType.service,
        price: 250.0,
        quantity: 1,
        description: 'Full synthetic oil change',
        category: 'regular',
      );

  static core_model.ServiceItemEntity coreBrakepadItem() =>
      core_model.ServiceItemEntity(
        id: 'service-item-002',
        name: 'Front Brake Pads',
        type: core_model.ServiceItemType.part,
        price: 400.0,
        quantity: 2,
        description: 'OEM brake pad replacement',
        category: 'repair',
      );

  // ─── Bookings ────────────────────────────────────────────────────────────────

  static BookingEntity pendingBooking() => BookingEntity(
        id: 'booking-001',
        userId: 'customer-uid-001',
        carId: 'car-001',
        serviceId: 'service-001',
        maintenanceType: MaintenanceType.regular,
        scheduledDate: DateTime(2025, 6, 15),
        timeSlot: '10:00 AM',
        status: BookingStatus.pending,
        description: 'Regular oil change and tire rotation',
        createdAt: DateTime(2025, 6, 1),
        updatedAt: DateTime(2025, 6, 1),
        isPaid: false,
      );

  static BookingEntity confirmedBooking() => BookingEntity(
        id: 'booking-002',
        userId: 'customer-uid-001',
        carId: 'car-001',
        serviceId: 'service-002',
        maintenanceType: MaintenanceType.repair,
        scheduledDate: DateTime(2025, 6, 20),
        timeSlot: '02:00 PM',
        status: BookingStatus.confirmed,
        description: 'Brake pad replacement',
        assignedTechnicians: ['tech-uid-001'],
        createdAt: DateTime(2025, 6, 5),
        updatedAt: DateTime(2025, 6, 6),
        isPaid: false,
      );

  static BookingEntity completedBooking() => BookingEntity(
        id: 'booking-003',
        userId: 'customer-uid-001',
        carId: 'car-001',
        serviceId: 'service-001',
        maintenanceType: MaintenanceType.regular,
        scheduledDate: DateTime(2025, 5, 10),
        timeSlot: '09:00 AM',
        status: BookingStatus.completed,
        serviceItems: [oilChangeItem()],
        laborCost: 150.0,
        tax: 40.0,
        createdAt: DateTime(2025, 5, 1),
        updatedAt: DateTime(2025, 5, 10),
        completedAt: DateTime(2025, 5, 10, 11, 30),
        startedAt: DateTime(2025, 5, 10, 9, 0),
        isPaid: true,
        paidAt: DateTime(2025, 5, 10, 12, 0),
        cashierId: 'cashier-uid-001',
        paymentMethod: PaymentMethod.cash,
        rating: 4.5,
        ratingComment: 'Great service!',
        ratedAt: DateTime(2025, 5, 11),
      );

  static BookingEntity bookingWithDiscount() => BookingEntity(
        id: 'booking-004',
        userId: 'customer-uid-001',
        carId: 'car-001',
        serviceId: 'service-003',
        maintenanceType: MaintenanceType.inspection,
        scheduledDate: DateTime(2025, 7, 1),
        timeSlot: '11:00 AM',
        status: BookingStatus.completedPendingPayment,
        serviceItems: [oilChangeItem(), brakepadItem()],
        laborCost: 200.0,
        discountPercentage: 10,
        offerCode: 'SUMMER10',
        offerTitle: 'Summer Discount',
        createdAt: DateTime(2025, 6, 20),
        updatedAt: DateTime(2025, 7, 1),
        isPaid: false,
      );

  // ─── Firestore-Compatible Maps ───────────────────────────────────────────────

  static Map<String, dynamic> userFirestoreMap() => {
        'email': 'customer@fixhub.test',
        'name': 'Ahmed Hassan',
        'phone': '+20 100 000 0001',
        'role': 'customer',
        'isActive': true,
        'profileImageUrl': null,
        'inviteCodeId': null,
        'inviteCode': null,
        'preferences': null,
      };

  static Map<String, dynamic> bookingFirestoreMap() => {
        'userId': 'customer-uid-001',
        'carId': 'car-001',
        'serviceId': 'service-001',
        'maintenanceType': 'regular',
        'timeSlot': '10:00 AM',
        'status': 'pending',
        'description': 'Regular oil change',
        'assignedTechnicians': null,
        'notes': null,
        'serviceItems': null,
        'laborCost': null,
        'tax': null,
        'technicianNotes': null,
        'offerCode': null,
        'offerTitle': null,
        'discountPercentage': null,
        'rating': null,
        'ratingComment': null,
        'ratedAt': null,
        'isPaid': false,
        'paidAt': null,
        'cashierId': null,
        'paymentMethod': null,
        'completedAt': null,
        'startedAt': null,
      };
}
