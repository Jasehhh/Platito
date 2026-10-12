import 'package:flutter_test/flutter_test.dart';
import 'package:platito/models/food.dart';

void main() {
  // Trimmed from a real USDA search response for "egg".
  // Energy is an int (148) on purpose, to check it still parses as a double.
  final sampleJson = <String, dynamic>{
    'fdcId': 748967,
    'description': 'Eggs, Grade A, Large, egg whole',
    'dataType': 'Foundation',
    'foodNutrients': [
      {
        'nutrientId': 1003,
        'nutrientName': 'Protein',
        'unitName': 'G',
        'value': 12.4,
      },
      {
        'nutrientId': 1008,
        'nutrientName': 'Energy',
        'unitName': 'KCAL',
        'value': 148,
      },
    ],
  };

  group('Food.fromJson', () {
    test('reads fdcId, name, and dataType', () {
      final food = Food.fromJson(sampleJson);

      expect(food.fdcId, 748967);
      expect(food.name, 'Eggs, Grade A, Large, egg whole');
      expect(food.dataType, 'Foundation');
    });

    test('reads protein and calories', () {
      final food = Food.fromJson(sampleJson);

      expect(food.protein, 12.4);
      expect(food.calories, 148.0);
    });

    test('parses an int value as a double', () {
      final food = Food.fromJson(sampleJson);
      final energy = food.nutrients.firstWhere((n) => n.id == 1008);

      expect(energy.value, isA<double>());
      expect(energy.value, 148.0);
    });

    test('uses defaults when nutrients are missing', () {
      final food = Food.fromJson({'fdcId': 1, 'description': 'Water'});

      expect(food.nutrients, isEmpty);
      expect(food.protein, 0.0);
      expect(food.calories, 0.0);
    });
  });
}
