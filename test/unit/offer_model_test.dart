// test/unit/offer_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:car_maintenance_system_new/core/models/offer_model.dart';

void main() {
  final now = DateTime(2025, 6, 1);

  group('OfferModel — fromFirestore', () {
    test('parses discount offer correctly', () {
      final map = {
        'title': 'Summer Sale', 'description': '20% off all services',
        'type': 'discount', 'imageUrl': 'https://img.test/sale.jpg',
        'startDate': Timestamp.fromDate(now),
        'endDate': Timestamp.fromDate(now.add(const Duration(days: 30))),
        'isActive': true, 'createdBy': 'admin-001',
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'discountPercentage': 20, 'code': 'SUMMER20', 'terms': 'Min 500 EGP',
      };
      final offer = OfferModel.fromFirestore(map, 'offer-001');
      expect(offer.id, equals('offer-001'));
      expect(offer.type, equals(OfferType.discount));
      expect(offer.discountPercentage, equals(20));
      expect(offer.code, equals('SUMMER20'));
      expect(offer.isActive, isTrue);
    });

    test('parses announcement without discount', () {
      final map = {
        'title': 'New Branch', 'description': 'Opening soon',
        'type': 'announcement', 'isActive': true, 'createdBy': 'admin-001',
        'startDate': Timestamp.fromDate(now),
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };
      final offer = OfferModel.fromFirestore(map, 'offer-002');
      expect(offer.type, equals(OfferType.announcement));
      expect(offer.discountPercentage, isNull);
      expect(offer.endDate, isNull);
    });

    test('unknown type defaults to announcement', () {
      final map = {
        'title': 'X', 'description': 'Y', 'type': 'unknown_type',
        'isActive': true, 'createdBy': 'admin',
        'startDate': Timestamp.fromDate(now),
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };
      final offer = OfferModel.fromFirestore(map, 'offer-003');
      expect(offer.type, equals(OfferType.announcement));
    });
  });

  group('OfferModel — toFirestore', () {
    test('serializes all fields correctly', () {
      final offer = OfferModel(
        id: 'offer-001', title: 'Flash Sale', description: '15% off',
        type: OfferType.promotion, isActive: true, createdBy: 'admin-001',
        startDate: now, endDate: now.add(const Duration(days: 7)),
        createdAt: now, updatedAt: now, discountPercentage: 15,
        code: 'FLASH15',
      );
      final map = offer.toFirestore();
      expect(map['title'], equals('Flash Sale'));
      expect(map['type'], equals('promotion'));
      expect(map['discountPercentage'], equals(15));
      expect(map['code'], equals('FLASH15'));
      expect(map.containsKey('id'), isFalse);
    });

    test('null endDate serializes as null', () {
      final offer = OfferModel(
        id: 'o', title: 'T', description: 'D', type: OfferType.news,
        isActive: true, createdBy: 'a', startDate: now,
        createdAt: now, updatedAt: now,
      );
      final map = offer.toFirestore();
      expect(map['endDate'], isNull);
    });
  });

  group('OfferModel — copyWith', () {
    test('copyWith deactivates offer', () {
      final original = OfferModel(
        id: 'offer-001', title: 'Sale', description: 'D',
        type: OfferType.discount, isActive: true, createdBy: 'admin',
        startDate: now, createdAt: now, updatedAt: now,
        discountPercentage: 10,
      );
      final deactivated = original.copyWith(isActive: false);
      expect(deactivated.isActive, isFalse);
      expect(original.isActive, isTrue);
    });

    test('copyWith updates discount percentage', () {
      final original = OfferModel(
        id: 'offer-001', title: 'Sale', description: 'D',
        type: OfferType.discount, isActive: true, createdBy: 'admin',
        startDate: now, createdAt: now, updatedAt: now,
        discountPercentage: 10,
      );
      final updated = original.copyWith(discountPercentage: 25);
      expect(updated.discountPercentage, equals(25));
      expect(updated.title, equals('Sale'));
    });
  });

  group('Enums — OfferType', () {
    test('all offer types exist', () {
      expect(OfferType.values.length, equals(4));
      expect(OfferType.values, contains(OfferType.announcement));
      expect(OfferType.values, contains(OfferType.discount));
      expect(OfferType.values, contains(OfferType.promotion));
      expect(OfferType.values, contains(OfferType.news));
    });
  });
}
