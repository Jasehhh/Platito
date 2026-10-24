import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/recipe.dart';
import '../providers/recipe_provider.dart';
import '../utils/constants.dart';
import '../widgets/circle_icon_button.dart';
import '../widgets/empty_state.dart';
import '../widgets/recipe_value_card.dart';

/// Recipes in one category, or all recipes when the route argument is null.
/// Opened from Home with:
/// Navigator.pushNamed(context, Routes.recipeList, arguments: category).
class RecipeListScreen extends StatefulWidget {
  const RecipeListScreen({super.key});

  @override
  State<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen> {
  RecipeSort _sort = RecipeSort.proteinPerPeso;

  static const _sortLabels = {
    RecipeSort.proteinPerPeso: 'Best value',
    RecipeSort.protein: 'Protein',
    RecipeSort.cost: 'Cheapest',
  };

  @override
  Widget build(BuildContext context) {
    final category = ModalRoute.of(context)?.settings.arguments as String?;
    final provider = context.watch<RecipeProvider>();
    final recipes = provider.sortRecipes(
      category == null
          ? provider.recipes
          : provider.recipesByCategory(category),
      _sort,
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context, category ?? 'All recipes', recipes.length),
            _buildSortChips(),
            Expanded(child: _buildBody(context, provider, recipes)),
          ],
        ),
      ),
    );
  }

  /// DESIGN.md 6.3 centered bar: back button, title with a count, and an
  /// empty 40 px space on the right so the title stays centered.
  Widget _buildTopBar(BuildContext context, String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 6),
      child: Row(
        children: [
          CircleIconButton(
            icon: Icons.chevron_left,
            tooltip: 'Back',
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  count == 1 ? '1 recipe' : '$count recipes',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildSortChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Row(
        children: [
          for (final entry in _sortLabels.entries) ...[
            ChoiceChip(
              label: Text(entry.value),
              selected: _sort == entry.key,
              onSelected: (_) => setState(() => _sort = entry.key),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    RecipeProvider provider,
    List<Recipe> recipes,
  ) {
    if (provider.isLoading && provider.recipes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (recipes.isEmpty) {
      return const SingleChildScrollView(
        padding: EdgeInsets.all(18),
        child: EmptyState(
          icon: Icons.restaurant_menu,
          title: 'No recipes here yet',
          message: 'Add your own budget meal from My Recipes.',
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      itemCount: recipes.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) => RecipeValueCard(
        recipe: recipes[index],
        onTap: () => Navigator.pushNamed(
          context,
          Routes.recipeDetail,
          arguments: recipes[index],
        ),
      ),
    );
  }
}
