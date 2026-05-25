import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:car_maintenance_system_new/features/refunds/domain/entities/refund_entity.dart';

class RefundRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'refunds';

  // Get all refunds stream
  Stream<List<RefundEntity>> getRefundsStream({RefundStatus? status}) {
    Query query = _firestore.collection(_collection)
        .orderBy('requestedAt', descending: true);
    
    if (status != null) {
      query = query.where('status', isEqualTo: status.toString().split('.').last);
    }
    
    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) =>
            RefundEntity.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)
        ).toList());
  }

  // Get pending refunds for admin
  Stream<List<RefundEntity>> getPendingRefunds() {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: 'requested')
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RefundEntity.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  // Create refund request
  Future<String> createRefundRequest({
    required String bookingId,
    required double originalAmount,
    required double refundAmount,
    required String reason,
    String? customerNotes,
    required String requestedBy,
    String? originalPaymentMethod,
  }) async {
    try {
      final refund = RefundEntity(
        id: '',
        bookingId: bookingId,
        originalAmount: originalAmount,
        refundAmount: refundAmount,
        reason: reason,
        customerNotes: customerNotes,
        status: RefundStatus.requested,
        requestedBy: requestedBy,
        requestedAt: DateTime.now(),
        originalPaymentMethod: originalPaymentMethod,
      );

      final doc = await _firestore.collection(_collection).add(refund.toFirestore());
      debugPrint('Refund request created: ${doc.id}');
      return doc.id;
    } catch (e) {
      debugPrint('Error creating refund request: $e');
      rethrow;
    }
  }

  // Approve refund (admin only)
  Future<void> approveRefund({
    required String refundId,
    required String approvedBy,
    String? refundMethod,
  }) async {
    try {
      await _firestore.collection(_collection).doc(refundId).update({
        'status': 'approved',
        'approvedBy': approvedBy,
        'approvedAt': FieldValue.serverTimestamp(),
        'refundMethod': refundMethod,
      });
      debugPrint('Refund approved: $refundId');
    } catch (e) {
      debugPrint('Error approving refund: $e');
      rethrow;
    }
  }

  // Reject refund (admin only)
  Future<void> rejectRefund({
    required String refundId,
    required String rejectedBy,
    String? rejectionReason,
  }) async {
    try {
      await _firestore.collection(_collection).doc(refundId).update({
        'status': 'rejected',
        'approvedBy': rejectedBy,
        'approvedAt': FieldValue.serverTimestamp(),
        'customerNotes': rejectionReason,
      });
      debugPrint('Refund rejected: $refundId');
    } catch (e) {
      debugPrint('Error rejecting refund: $e');
      rethrow;
    }
  }

  // Process refund (mark as completed)
  Future<void> processRefund(String refundId) async {
    try {
      await _firestore.collection(_collection).doc(refundId).update({
        'status': 'processed',
        'processedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Refund processed: $refundId');
    } catch (e) {
      debugPrint('Error processing refund: $e');
      rethrow;
    }
  }

  // Get refund by booking ID
  Future<RefundEntity?> getRefundByBookingId(String bookingId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('bookingId', isEqualTo: bookingId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return RefundEntity.fromFirestore(
          snapshot.docs.first.data(), snapshot.docs.first.id);
    } catch (e) {
      debugPrint('Error getting refund: $e');
      return null;
    }
  }
}
