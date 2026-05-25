// test/unit/egyptian_cars_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:car_maintenance_system_new/core/constants/egyptian_cars.dart';

void main() {
  group('EgyptianCars — makes', () {
    test('makes list is not empty', () {
      expect(EgyptianCars.makes, isNotEmpty);
    });

    test('contains popular Egyptian market brands', () {
      expect(EgyptianCars.makes, contains('Toyota'));
      expect(EgyptianCars.makes, contains('Hyundai'));
      expect(EgyptianCars.makes, contains('Kia'));
      expect(EgyptianCars.makes, contains('Nissan'));
      expect(EgyptianCars.makes, contains('Chevrolet'));
      expect(EgyptianCars.makes, contains('BMW'));
      expect(EgyptianCars.makes, contains('Mercedes-Benz'));
    });

    test('contains Chinese brands available in Egypt', () {
      expect(EgyptianCars.makes, contains('MG'));
      expect(EgyptianCars.makes, contains('Chery'));
      expect(EgyptianCars.makes, contains('BYD'));
    });
  });

  group('EgyptianCars — modelsByMake', () {
    test('Toyota has models', () {
      expect(EgyptianCars.modelsByMake['Toyota'], isNotEmpty);
      expect(EgyptianCars.modelsByMake['Toyota'], contains('Corolla'));
      expect(EgyptianCars.modelsByMake['Toyota'], contains('Camry'));
    });

    test('Hyundai has models', () {
      expect(EgyptianCars.modelsByMake['Hyundai'], contains('Elantra'));
      expect(EgyptianCars.modelsByMake['Hyundai'], contains('Tucson'));
    });

    test('every make in makes list has models', () {
      for (final make in EgyptianCars.makes) {
        expect(EgyptianCars.modelsByMake.containsKey(make), isTrue,
            reason: '$make should have models');
        expect(EgyptianCars.modelsByMake[make], isNotEmpty,
            reason: '$make should have at least one model');
      }
    });
  });

  group('EgyptianCars — modelsFor', () {
    test('modelsFor returns correct models for known make', () {
      final models = EgyptianCars.modelsFor('Kia');
      expect(models, contains('Cerato'));
      expect(models, contains('Sportage'));
    });

    test('modelsFor returns empty list for unknown make', () {
      final models = EgyptianCars.modelsFor('UnknownBrand');
      expect(models, isEmpty);
    });
  });

  group('EgyptianCars — colors', () {
    test('colors list is not empty', () {
      expect(EgyptianCars.colors, isNotEmpty);
    });

    test('contains common colors', () {
      expect(EgyptianCars.colors, contains('White'));
      expect(EgyptianCars.colors, contains('Black'));
      expect(EgyptianCars.colors, contains('Silver'));
      expect(EgyptianCars.colors, contains('Red'));
    });
  });

  group('EgyptianCars — years', () {
    test('years list is not empty', () {
      expect(EgyptianCars.years, isNotEmpty);
    });

    test('years start from next year descending', () {
      final years = EgyptianCars.years;
      final currentYear = DateTime.now().year;
      expect(years.first, equals(currentYear + 1));
    });

    test('years go back to 1990', () {
      final years = EgyptianCars.years;
      expect(years.last, equals(1991));
    });

    test('years are in descending order', () {
      final years = EgyptianCars.years;
      for (int i = 0; i < years.length - 1; i++) {
        expect(years[i], greaterThan(years[i + 1]));
      }
    });
  });
}
