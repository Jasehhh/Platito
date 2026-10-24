import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/recipe.dart';

/// Saves the user's own recipes and favorites on the device with
/// shared_preferences. All recipes are stored as one JSON string under
/// [_recipesKey]; favorites are a list of recipe ids under [_favoritesKey].
class StorageService {
  static const _recipesKey = 'user_recipes';
  static const _favoritesKey = 'favorite_recipe_ids';

  /// Returns the saved recipes, or an empty list if there are none or the
  /// saved data can't be read.
  Future<List<Recipe>> loadRecipes() async {
    final prefs = await SharedPreferences.getInstance();
    final text = prefs.getString(_recipesKey);
    if (text == null) return [];

    try {
      final items = jsonDecode(text) as List<dynamic>;
      return items
          .map((item) => Recipe.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Corrupt or outdated data: start fresh instead of crashing.
      return [];
    }
  }

  /// Replaces the saved list with [recipes].
  Future<void> saveRecipes(List<Recipe> recipes) async {
    final prefs = await SharedPreferences.getInstance();
    final text = jsonEncode(recipes.map((recipe) => recipe.toJson()).toList());
    await prefs.setString(_recipesKey, text);
  }

  /// Returns the ids of the user's favorite recipes.
  Future<Set<String>> loadFavoriteIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_favoritesKey) ?? []).toSet();
  }

  /// Replaces the saved favorites with [ids].
  Future<void> saveFavoriteIds(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoritesKey, ids.toList());
  }
}
