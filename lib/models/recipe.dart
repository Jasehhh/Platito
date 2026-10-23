/// One ingredient line in a recipe, for example "150 g egg, ₱27".
/// [fdcId] links the ingredient to its USDA food, which gives the
/// nutrient values per 100 g.
class RecipeIngredient {
  const RecipeIngredient({
    required this.name,
    required this.fdcId,
    required this.grams,
    required this.price,
  });

  final String name;
  final int fdcId;
  final double grams;

  /// Cost in pesos for the amount in [grams], not per kilo.
  final double price;

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      name: json['name'] as String,
      fdcId: (json['fdcId'] as num).toInt(),
      // JSON numbers like 150 come in as int, so read them as num first.
      grams: (json['grams'] as num).toDouble(),
      price: (json['price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'fdcId': fdcId, 'grams': grams, 'price': price};
  }
}

/// A recipe from assets/recipes.json, or one the user creates.
/// [category] is one of recipeCategories in utils/constants.dart.
class Recipe {
  const Recipe({
    required this.id,
    required this.name,
    required this.category,
    required this.servings,
    required this.emoji,
    required this.ingredients,
    required this.steps,
  });

  final String id;
  final String name;
  final String category;
  final int servings;

  /// Shown on the tinted recipe thumbnail (see DESIGN.md).
  final String emoji;
  final List<RecipeIngredient> ingredients;
  final List<String> steps;

  factory Recipe.fromJson(Map<String, dynamic> json) {
    final rawIngredients = json['ingredients'] as List<dynamic>? ?? [];
    final rawSteps = json['steps'] as List<dynamic>? ?? [];
    return Recipe(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      servings: (json['servings'] as num?)?.toInt() ?? 1,
      emoji: json['emoji'] as String? ?? '🍽️',
      ingredients: rawIngredients
          .map(
            (item) => RecipeIngredient.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      steps: rawSteps.map((step) => step as String).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'servings': servings,
      'emoji': emoji,
      'ingredients': ingredients.map((item) => item.toJson()).toList(),
      'steps': steps,
    };
  }
}
