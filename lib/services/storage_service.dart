import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/recipe.dart';

/// Saves the user's own recipes on the device with shared_preferences.
/// All recipes are stored as one JSON string under [_recipesKey].
class StorageService {
  static const _recipesKey = 'user_recipes';

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
}
