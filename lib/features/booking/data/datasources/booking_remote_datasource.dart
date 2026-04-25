import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:car_maintenance_system_new/core/services/firebase_service.dart';

/// Remote data source for booking operations
class BookingRemoteDataSource {
  /// Load bookings from Firestore
  Future<List<Map<String, dynamic>>> loadBookings({
    required String userId,
    String? role,
  }) async {
    try {
      Query query;
      if (role == 'admin' || role == 'technician' || role == 'cashier') {
        query = FirebaseService.bookingsCollection
            .orderBy('createdAt', descending: true);
      } else {
        query = FirebaseService.bookingsCollection
            .where('userId', isEqualTo: userId);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading bookings: $e');
      }
      rethrow;
    }
  }

  /// Watch bookings in real-time
  Stream<List<Map<String, dynamic>>> watchBookings({
    required String userId,
    String? role,
  }) {
    Query query;
    if (role == 'admin' || role == 'technician' || role == 'cashier') {
      query = FirebaseService.bookingsCollection
          .orderBy('createdAt', descending: true);
    } else {
      query = FirebaseService.bookingsCollection
          .where('userId', isEqualTo: userId);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      }).toList();
    });
  }

  /// Create a new booking
  Future<String> createBooking(Map<String, dynamic> data) async {
    try {
      final docRef = await FirebaseService.bookingsCollection.add(data);
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error creating booking: $e');
      }
      rethrow;
    }
  }

  /// Update a booking
  Future<void> updateBooking(
    String bookingId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await FirebaseService.bookingsCollection
          .doc(bookingId)
          .update(updates);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating booking: $e');
      }
      rethrow;
    }
  }

  /// Get a single booking by ID
  Future<Map<String, dynamic>?> getBookingById(String bookingId) async {
    try {
      final doc = await FirebaseService.bookingsCollection.doc(bookingId).get();
      if (doc.exists) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting booking: $e');
      }
      rethrow;
    }
  }

  /// Rate a booking
  Future<void> rateBooking({
    required String bookingId,
    required double rating,
    required String comment,
  }) async {
    try {
      await FirebaseService.bookingsCollection.doc(bookingId).update({
        'rating': rating,
        'ratingComment': comment.trim(),
        'ratedAt': Timestamp.now(),
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error rating booking: $e');
      }
      rethrow;
    }
  }

  /// Process payment for a booking
  Future<void> processPayment({
    required String bookingId,
    required String cashierId,
    required String paymentMethod,
    double? totalCost, // Add total cost to save for reports
  }) async {
    try {
      final updateData = {
        'status': 'completed',
        'isPaid': true,
        'paidAt': Timestamp.now(),
        'cashierId': cashierId,
        'paymentMethod': paymentMethod,
        'updatedAt': Timestamp.now(),
      };
      
      // Add totalCost if provided
      if (totalCost != null) {
        updateData['totalCost'] = totalCost;
      }
      
      await FirebaseService.bookingsCollection.doc(bookingId).update(updateData);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error processing payment: $e');
      }
      rethrow;
    }
  }
}


