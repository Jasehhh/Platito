import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/recipe.dart';
import '../providers/recipe_provider.dart';
import '../theme/app_colors.dart';
import '../utils/constants.dart';
import '../widgets/empty_state.dart';
import '../widgets/recipe_value_card.dart';

/// The user's own recipes, with edit and delete buttons and a
/// "New recipe" button above the dock.
class MyRecipesScreen extends StatelessWidget {
  const MyRecipesScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    final recipes = context.watch<RecipeProvider>().userRecipes;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          // Room at the bottom so the last card clears the New recipe button.
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 90),
          children: [
            const _LargeTitle(),
            const SizedBox(height: 16),
            if (recipes.isEmpty)
              const EmptyState(
                icon: Icons.menu_book_outlined,
                title: 'No recipes yet',
                message: 'Tap + to add your own budget meal.',
              ),
            for (final recipe in recipes) ...[
              RecipeValueCard(
                recipe: recipe,
                onTap: () => Navigator.pushNamed(
                  context,
                  Routes.recipeDetail,
                  arguments: recipe,
                ),
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
          'Your own budget meals',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
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
