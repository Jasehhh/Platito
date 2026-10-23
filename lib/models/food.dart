/// USDA nutrient IDs that Platito uses.
class NutrientIds {
  static const protein = 1003;
  static const fat = 1004;
  static const carbs = 1005;
  static const energyKcal = 1008;

  /// Some Foundation foods report calories under these IDs instead of 1008.
  static const energyAtwaterGeneral = 2047;
  static const energyAtwaterSpecific = 2048;
}

/// One nutrient value from the USDA API, for example "Protein 12.6 G".
class Nutrient {
  const Nutrient({
    required this.id,
    required this.name,
    required this.unit,
    required this.value,
  });

  final int id;
  final String name;
  final String unit;
  final double value;

  /// Builds a Nutrient from one item of the "foodNutrients" list.
  factory Nutrient.fromJson(Map<String, dynamic> json) {
    return Nutrient(
      id: (json['nutrientId'] as num?)?.toInt() ?? 0,
      name: json['nutrientName'] as String? ?? '',
      unit: json['unitName'] as String? ?? '',
      // The API sends value as an int (513) or a double (6.41),
      // so read it as num and convert it to double.
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Builds a Nutrient from one item of "foodNutrients" in a
  /// /fdc/v1/foods response. There the ID, name, and unit sit inside a
  /// nested "nutrient" object, and the value is called "amount".
  factory Nutrient.fromDetailJson(Map<String, dynamic> json) {
    final info = json['nutrient'] as Map<String, dynamic>? ?? {};
    return Nutrient(
      id: (info['id'] as num?)?.toInt() ?? 0,
      name: info['name'] as String? ?? '',
      unit: info['unitName'] as String? ?? '',
      value: (json['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// One food from a USDA search result. Nutrient values are per 100 g.
class Food {
  const Food({
    required this.fdcId,
    required this.name,
    required this.dataType,
    required this.nutrients,
  });

  final int fdcId;
  final String name;
  final String dataType;
  final List<Nutrient> nutrients;

  /// Builds a Food from one item of the "foods" list in a search response.
  factory Food.fromJson(Map<String, dynamic> json) {
    final rawNutrients = json['foodNutrients'] as List<dynamic>? ?? [];
    return Food(
      fdcId: (json['fdcId'] as num).toInt(),
      name: json['description'] as String? ?? 'Unknown food',
      dataType: json['dataType'] as String? ?? '',
      nutrients: rawNutrients
          .map((item) => Nutrient.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Builds a Food from one item of a /fdc/v1/foods (lookup by ID)
  /// response. Its nutrients use a different shape than search results.
  factory Food.fromDetailJson(Map<String, dynamic> json) {
    final rawNutrients = json['foodNutrients'] as List<dynamic>? ?? [];
    return Food(
      fdcId: (json['fdcId'] as num).toInt(),
      name: json['description'] as String? ?? 'Unknown food',
      dataType: json['dataType'] as String? ?? '',
      nutrients: rawNutrients
          .map((item) => Nutrient.fromDetailJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Returns the value of the nutrient with [nutrientId], or 0 if missing.
  double valueOf(int nutrientId) {
    for (final nutrient in nutrients) {
      if (nutrient.id == nutrientId) return nutrient.value;
    }
    return 0.0;
  }

  double get protein => valueOf(NutrientIds.protein);
  double get fat => valueOf(NutrientIds.fat);
  double get carbs => valueOf(NutrientIds.carbs);

  /// Calories per 100 g. Falls back to the Atwater energy IDs that some
  /// Foundation foods use instead of 1008.
  double get calories {
    for (final id in [
      NutrientIds.energyKcal,
      NutrientIds.energyAtwaterGeneral,
      NutrientIds.energyAtwaterSpecific,
    ]) {
      final value = valueOf(id);
      if (value > 0) return value;
    }
    return 0.0;
  }
}
