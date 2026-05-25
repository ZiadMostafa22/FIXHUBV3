import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:car_maintenance_system_new/core/models/service_item_model.dart';

class ServiceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'services';

  // Get all active services
  Stream<List<ServiceItemEntity>> getServices({String? category}) {
    Query query = _firestore.collection(_collection)
        .where('isActive', isEqualTo: true);
    
    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }
    
    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) =>
            ServiceItemEntity.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)
        ).toList());
  }

  // Get service by ID
  Future<ServiceItemEntity?> getServiceById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return ServiceItemEntity.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting service by ID: $e');
      return null;
    }
  }

  // Create service (admin only)
  Future<String> createService(ServiceItemEntity service) async {
    try {
      final doc = await _firestore.collection(_collection).add({
        'name': service.name,
        'type': service.type.toString().split('.').last,
        'price': service.price,
        'description': service.description,
        'category': service.category,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Service created: ${doc.id}');
      return doc.id;
    } catch (e) {
      debugPrint('Error creating service: $e');
      rethrow;
    }
  }

  // Update service
  Future<void> updateService(String id, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Service updated: $id');
    } catch (e) {
      debugPrint('Error updating service: $e');
      rethrow;
    }
  }

  // Delete (soft delete - set isActive to false)
  Future<void> deleteService(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Service deactivated: $id');
    } catch (e) {
      debugPrint('Error deleting service: $e');
      rethrow;
    }
  }

  // Bulk create services (for initial migration)
  Future<void> bulkCreateServices(List<ServiceItemEntity> services) async {
    try {
      final batch = _firestore.batch();
      
      for (var service in services) {
        final docRef = _firestore.collection(_collection).doc();
        batch.set(docRef, {
          'name': service.name,
          'type': service.type.toString().split('.').last,
          'price': service.price,
          'description': service.description,
          'category': service.category ?? '',
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
      debugPrint('Bulk created ${services.length} services');
    } catch (e) {
      debugPrint('Error bulk creating services: $e');
      rethrow;
    }
  }
}
