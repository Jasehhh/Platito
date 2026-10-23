import '../models/food.dart';
import '../models/recipe.dart';

/// Protein, calories, carbs, and fat for a whole recipe or one serving.
class NutritionTotals {
  const NutritionTotals({
    required this.protein,
    required this.calories,
    required this.carbs,
    required this.fat,
  });

  final double protein;
  final double calories;
  final double carbs;
  final double fat;
}

/// Plain Dart math for recipe nutrition and cost. It has no Flutter
/// imports, so it only depends on the models.
class NutritionCalculator {
  /// USDA values are per 100 g, so scale them to the grams used.
  /// Example: egg has 12.56 g protein per 100 g, so 150 g gives 18.84 g.
  static double amountFor(double valuePer100g, double grams) {
    return valuePer100g / 100 * grams;
  }

  /// Adds up the nutrients of every ingredient in [recipe].
  /// [foods] maps an fdcId to its USDA food. An ingredient whose food is
  /// missing from [foods] adds nothing.
  static NutritionTotals totals(Recipe recipe, Map<int, Food> foods) {
    var protein = 0.0;
    var calories = 0.0;
    var carbs = 0.0;
    var fat = 0.0;

    for (final ingredient in recipe.ingredients) {
      final food = foods[ingredient.fdcId];
      if (food == null) continue;
      protein += amountFor(food.protein, ingredient.grams);
      calories += amountFor(food.calories, ingredient.grams);
      carbs += amountFor(food.carbs, ingredient.grams);
      fat += amountFor(food.fat, ingredient.grams);
    }

    return NutritionTotals(
      protein: protein,
      calories: calories,
      carbs: carbs,
      fat: fat,
    );
  }

  /// Divides [totals] by [servings]. A servings value below 1 is treated
  /// as 1 so the result is never divided by zero.
  static NutritionTotals perServing(NutritionTotals totals, int servings) {
    final count = servings < 1 ? 1 : servings;
    return NutritionTotals(
      protein: totals.protein / count,
      calories: totals.calories / count,
      carbs: totals.carbs / count,
      fat: totals.fat / count,
    );
  }

  /// Total cost in pesos of all ingredients in [recipe].
  static double totalCost(Recipe recipe) {
    var cost = 0.0;
    for (final ingredient in recipe.ingredients) {
      cost += ingredient.price;
    }
    return cost;
  }

  /// Grams of protein for every peso spent. Returns 0 if [cost] is 0.
  static double proteinPerPeso(double protein, double cost) {
    if (cost == 0) return 0.0;
    return protein / cost;
  }
}
