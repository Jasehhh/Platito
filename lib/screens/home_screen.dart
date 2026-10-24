import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/recipe.dart';
import '../providers/recipe_provider.dart';
import '../theme/app_colors.dart';
import '../utils/constants.dart';
import '../widgets/category_tile.dart';
import '../widgets/empty_state.dart';
import '../widgets/home_header.dart';
import '../widgets/recipe_value_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// How many recipes "Popular this week" shows.
  static const _popularCount = 3;

  /// Icon and tint for each category tile, in recipeCategories order.
  static const _categoryIcons = {
    'Budget Meals': (Icons.savings_outlined, AppColors.tintEgg),
    'High Protein': (Icons.fitness_center, AppColors.tintLeaf),
    'Bulking': (Icons.trending_up, AppColors.tintClay),
    'Cutting': (Icons.eco_outlined, AppColors.tintSea),
  };

  /// Opens Recipe List. A null [category] shows every recipe.
  void _openList(BuildContext context, String? category) {
    Navigator.pushNamed(context, Routes.recipeList, arguments: category);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecipeProvider>();
    final popular = provider
        .sortRecipes(provider.recipes, RecipeSort.proteinPerPeso)
        .take(_popularCount)
        .toList();

    return Scaffold(
      body: ListView(
        // The header draws behind the status bar, so only pad the bottom,
        // which already includes the dock's height.
        padding: EdgeInsets.only(
          bottom: MediaQuery.paddingOf(context).bottom + 16,
        ),
        children: [
          HomeHeader(onSearchTap: () => _openList(context, null)),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCategoryGrid(context, provider),
                const SizedBox(height: 20),
                _buildSectionHeader(context),
                const SizedBox(height: 10),
                ..._buildPopular(context, provider, popular),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(BuildContext context, RecipeProvider provider) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      mainAxisExtent: 92,
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (final category in recipeCategories)
          CategoryTile(
            title: category,
            caption: '${provider.recipesByCategory(category).length} recipes',
            icon: _categoryIcons[category]!.$1,
            tint: _categoryIcons[category]!.$2,
            onTap: () => _openList(context, category),
          ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Popular this week',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        TextButton(
          onPressed: () => _openList(context, null),
          child: const Text('See all'),
        ),
      ],
    );
  }

  List<Widget> _buildPopular(
    BuildContext context,
    RecipeProvider provider,
    List<Recipe> popular,
  ) {
    if (provider.recipes.isEmpty && provider.isLoading) {
      return const [
        Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (provider.recipes.isEmpty) {
      return [
        EmptyState(
          icon: Icons.restaurant_menu,
          title: provider.errorMessage ?? 'No recipes yet',
        ),
      ];
    }

    return [
      for (final recipe in popular) ...[
        RecipeValueCard(
          recipe: recipe,
          onTap: () => Navigator.pushNamed(
            context,
            Routes.recipeDetail,
            arguments: recipe,
          ),
        ),
        const SizedBox(height: 10),
      ],
    ];
  }
}
