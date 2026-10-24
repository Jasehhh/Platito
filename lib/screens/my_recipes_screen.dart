import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/recipe.dart';
import '../providers/recipe_provider.dart';
import '../theme/app_colors.dart';
import '../utils/constants.dart';
import '../widgets/empty_state.dart';
import '../widgets/recipe_value_card.dart';

/// The user's own recipes (with edit and delete) and their favorites,
/// switched with a segmented toggle, plus a "New recipe" button above
/// the dock.
class MyRecipesScreen extends StatefulWidget {
  const MyRecipesScreen({super.key});

  @override
  State<MyRecipesScreen> createState() => _MyRecipesScreenState();
}

class _MyRecipesScreenState extends State<MyRecipesScreen> {
  /// false shows My Recipes, true shows Favorites.
  bool _showFavorites = false;

  Future<void> _confirmDelete(BuildContext context, Recipe recipe) async {
    final provider = context.read<RecipeProvider>();
    // showDialog returns true for Delete, and false or null otherwise.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete recipe?'),
        content: Text('"${recipe.name}" will be removed from My Recipes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) await provider.deleteRecipe(recipe.id);
  }

  void _openDetail(Recipe recipe) {
    Navigator.pushNamed(context, Routes.recipeDetail, arguments: recipe);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecipeProvider>();
    final myRecipes = provider.userRecipes;
    final favorites = provider.favoriteRecipes;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          // Room at the bottom so the last card clears the New recipe button.
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 90),
          children: [
            const _LargeTitle(),
            const SizedBox(height: 16),
            _SegmentedToggle(
              labels: [
                'My Recipes · ${myRecipes.length}',
                'Favorites · ${favorites.length}',
              ],
              selectedIndex: _showFavorites ? 1 : 0,
              onChanged: (index) => setState(() => _showFavorites = index == 1),
            ),
            const SizedBox(height: 16),
            if (_showFavorites)
              ..._buildFavorites(favorites)
            else
              ..._buildMyRecipes(context, myRecipes),
          ],
        ),
      ),
      // MainShell's bottom padding includes the floating dock, so lifting
      // the button by it places the button just above the dock.
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
        child: FloatingActionButton.extended(
          onPressed: () => Navigator.pushNamed(context, Routes.recipeForm),
          icon: const Icon(Icons.add),
          label: const Text(
            'New recipe',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMyRecipes(BuildContext context, List<Recipe> recipes) {
    if (recipes.isEmpty) {
      return const [
        EmptyState(
          icon: Icons.menu_book_outlined,
          title: 'No recipes yet',
          message: 'Tap + to add your own budget meal.',
        ),
      ];
    }
    return [
      for (final recipe in recipes) ...[
        RecipeValueCard(
          recipe: recipe,
          onTap: () => _openDetail(recipe),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SmallActionButton(
                icon: Icons.edit_outlined,
                tooltip: 'Edit',
                background: AppColors.background,
                color: AppColors.textMuted,
                onPressed: () => Navigator.pushNamed(
                  context,
                  Routes.recipeForm,
                  arguments: recipe,
                ),
              ),
              const SizedBox(width: 6),
              _SmallActionButton(
                icon: Icons.delete_outline,
                tooltip: 'Delete',
                background: AppColors.errorLight,
                color: AppColors.error,
                onPressed: () => _confirmDelete(context, recipe),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    ];
  }

  /// Favorite cards keep their heart, so tapping it removes the recipe
  /// from this list.
  List<Widget> _buildFavorites(List<Recipe> recipes) {
    if (recipes.isEmpty) {
      return const [
        EmptyState(
          icon: Icons.favorite_border,
          title: 'No favorites yet',
          message: 'Tap the heart on any recipe to save it here.',
        ),
      ];
    }
    return [
      for (final recipe in recipes) ...[
        RecipeValueCard(recipe: recipe, onTap: () => _openDetail(recipe)),
        const SizedBox(height: 10),
      ],
    ];
  }
}

/// DESIGN.md 6.2 large title with a caption below.
class _LargeTitle extends StatelessWidget {
  const _LargeTitle();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Recipes',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 2),
        Text(
          'Your own meals and favorites',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

/// DESIGN.md segmented toggle: a light track with the selected segment
/// shown as a white pill.
class _SegmentedToggle extends StatelessWidget {
  const _SegmentedToggle({
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE7EEEA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == selectedIndex ? AppColors.surface : null,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: i == selectedIndex
                        ? const [
                            BoxShadow(
                              color: Color(0x14000000),
                              offset: Offset(0, 2),
                              blurRadius: 6,
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: i == selectedIndex
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: i == selectedIndex
                          ? AppColors.primaryDark
                          : AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 34 x 34 round edit or delete button (DESIGN.md small action buttons).
class _SmallActionButton extends StatelessWidget {
  const _SmallActionButton({
    required this.icon,
    required this.tooltip,
    required this.background,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final Color background;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: Material(
        color: background,
        shape: const CircleBorder(),
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          padding: EdgeInsets.zero,
          iconSize: 18,
          icon: Icon(icon, color: color),
        ),
      ),
    );
  }
}
