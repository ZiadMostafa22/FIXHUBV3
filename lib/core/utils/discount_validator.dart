import 'package:car_maintenance_system_new/core/models/offer_model.dart';
import 'package:car_maintenance_system_new/core/services/firebase_service.dart';

class DiscountValidator {
  /// Validates a discount code and returns the offer if valid
  static Future<Map<String, dynamic>> validateDiscountCode(String code) async {
    try {
      print('🔍 Validating discount code: $code');
      
      if (code.trim().isEmpty) {
        return {
          'valid': false,
          'message': 'Please enter a discount code',
          'offer': null,
        };
      }

      final searchCode = code.trim().toUpperCase();
      print('🔍 Searching for code: $searchCode');

      // Query Firestore for offers with matching code
      final querySnapshot = await FirebaseService.firestore
          .collection('offers')
          .where('code', isEqualTo: searchCode)
          .where('isActive', isEqualTo: true)
          .get();

      print('🔍 Found ${querySnapshot.docs.length} matching offers');

      if (querySnapshot.docs.isEmpty) {
        return {
          'valid': false,
          'message': 'Invalid discount code. Please check and try again.',
          'offer': null,
        };
      }

      // Get the first matching offer
      final offerDoc = querySnapshot.docs.first;
      print('🔍 Offer data: ${offerDoc.data()}');
      
      final offer = OfferModel.fromFirestore(
        offerDoc.data(),
        offerDoc.id,
      );

      print('🔍 Offer parsed: ${offer.title}, discount: ${offer.discountPercentage}%');

      // Check if offer is still active (date range)
      final now = DateTime.now();
      
      if (offer.startDate.isAfter(now)) {
        print('🔍 Offer not started yet');
        return {
          'valid': false,
          'message': 'This offer has not started yet',
          'offer': null,
        };
      }

      if (offer.endDate != null && offer.endDate!.isBefore(now)) {
        print('🔍 Offer expired');
        return {
          'valid': false,
          'message': 'This offer has expired',
          'offer': null,
        };
      }

      // Check if offer has a discount percentage
      if (offer.discountPercentage == null || offer.discountPercentage! <= 0) {
        print('🔍 No discount percentage');
        return {
          'valid': false,
          'message': 'This code is not valid for discounts',
          'offer': null,
        };
      }

      // Offer is valid
      print('Discount code valid! ${offer.discountPercentage}% off');
      return {
        'valid': true,
        'message': 'Discount code applied successfully! ${offer.discountPercentage}% off',
        'offer': offer,
      };
    } catch (e) {
      print('Error validating code: $e');
      return {
        'valid': false,
        'message': 'Error: ${e.toString()}',
        'offer': null,
      };
    }
  }

  /// Calculates the discount amount based on the offer and subtotal
  static double calculateDiscountAmount(OfferModel offer, double subtotal) {
    if (offer.discountPercentage == null || offer.discountPercentage! <= 0) {
      return 0.0;
    }
    return subtotal * (offer.discountPercentage! / 100.0);
  }
}

