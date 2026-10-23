import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/food.dart';
import '../models/recipe.dart';
import '../services/usda_service.dart';
import '../utils/nutrition_calculator.dart';

/// The ways the recipe list can be sorted.
enum RecipeSort { protein, cost, proteinPerPeso }

/// Holds every recipe and the USDA nutrition for their ingredients.
/// Screens read from it with context.watch and call load() or retry().
///
/// Recipes and nutrition load separately. If USDA cannot be reached,
/// the recipes still show and their nutrition is reported as missing.
class RecipeProvider extends ChangeNotifier {
  /// [usdaService] can be replaced with a fake in tests.
  RecipeProvider({UsdaService? usdaService})
    : _usdaService = usdaService ?? UsdaService();

  final UsdaService _usdaService;

  /// One list for built-in recipes now and user recipes later.
  final List<Recipe> _recipes = [];

  /// USDA food for each ingredient fdcId that has been fetched.
  final Map<int, Food> _foods = {};

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Recipe> get recipes => List.unmodifiable(_recipes);

  /// Loads assets/recipes.json, then fetches nutrition for its ingredients.
  Future<void> load() async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final text = await rootBundle.loadString('assets/recipes.json');
      final items = jsonDecode(text) as List<dynamic>;
      _recipes
        ..clear()
        ..addAll(
          items.map((item) => Recipe.fromJson(item as Map<String, dynamic>)),
        );
      // Show the recipes now, before the nutrition request finishes.
      notifyListeners();
    } catch (_) {
      _errorMessage = "Couldn't load recipes.";
      _isLoading = false;
      notifyListeners();
      return;
    }

    await _fetchNutrition();
    _isLoading = false;
    notifyListeners();
  }

  /// Fetches nutrition again, for example after the user goes back online.
  Future<void> retry() async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await _fetchNutrition();
    _isLoading = false;
    notifyListeners();
  }

  /// Requests every ingredient fdcId that is not in [_foods] yet, in one
  /// call to getFoodsByIds. Sets [errorMessage] if the request fails.
  Future<void> _fetchNutrition() async {
    final missingIds = <int>{
      for (final recipe in _recipes)
        for (final ingredient in recipe.ingredients)
          if (!_foods.containsKey(ingredient.fdcId)) ingredient.fdcId,
    };
    if (missingIds.isEmpty) return;

    try {
      final foods = await _usdaService.getFoodsByIds(missingIds.toList());
      for (final food in foods) {
        _foods[food.fdcId] = food;
      }
    } on UsdaException catch (e) {
      _errorMessage = 'Nutrition unavailable. ${e.message}';
    } catch (_) {
      // For example, USDA sent JSON in a shape the parser did not expect.
      _errorMessage = 'Nutrition unavailable. Please try again.';
    }
  }

  List<Recipe> recipesByCategory(String category) {
    return _recipes.where((recipe) => recipe.category == category).toList();
  }

  /// True when USDA data exists for every ingredient in [recipe].
  bool hasNutrition(Recipe recipe) {
    return recipe.ingredients.every(
      (ingredient) => _foods.containsKey(ingredient.fdcId),
    );
  }

  /// Nutrition for the whole recipe, or null if it is unavailable.
  NutritionTotals? totalsFor(Recipe recipe) {
    if (!hasNutrition(recipe)) return null;
    return NutritionCalculator.totals(recipe, _foods);
  }

  /// Nutrition for one serving, or null if it is unavailable.
  NutritionTotals? perServingFor(Recipe recipe) {
    final totals = totalsFor(recipe);
    if (totals == null) return null;
    return NutritionCalculator.perServing(totals, recipe.servings);
  }

  /// Cost in pesos does not need USDA, so it is always available.
  double costFor(Recipe recipe) => NutritionCalculator.totalCost(recipe);

  double costPerServingFor(Recipe recipe) {
    final servings = recipe.servings < 1 ? 1 : recipe.servings;
    return costFor(recipe) / servings;
  }

  /// Grams of protein per peso, or null if nutrition is unavailable.
  double? proteinPerPesoFor(Recipe recipe) {
    final totals = totalsFor(recipe);
    if (totals == null) return null;
    return NutritionCalculator.proteinPerPeso(totals.protein, costFor(recipe));
  }

  /// Returns a sorted copy of [list]. Protein and protein per peso sort
  /// from highest to lowest, cost from cheapest. Protein and cost compare
  /// per serving, so recipes with different servings are fair to compare.
  /// Recipes without nutrition go last when sorting by protein.
  List<Recipe> sortRecipes(List<Recipe> list, RecipeSort sort) {
    final sorted = [...list];
    switch (sort) {
      case RecipeSort.protein:
        sorted.sort(
          (a, b) => (perServingFor(b)?.protein ?? -1).compareTo(
            perServingFor(a)?.protein ?? -1,
          ),
        );
      case RecipeSort.cost:
        sorted.sort(
          (a, b) => costPerServingFor(a).compareTo(costPerServingFor(b)),
        );
      case RecipeSort.proteinPerPeso:
        sorted.sort(
          (a, b) => (proteinPerPesoFor(b) ?? -1).compareTo(
            proteinPerPesoFor(a) ?? -1,
          ),
        );
    }
    return sorted;
  }
}
