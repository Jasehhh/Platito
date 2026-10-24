import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/recipe.dart';
import '../providers/recipe_provider.dart';
import '../theme/app_colors.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state.dart';
import '../widgets/favorite_button.dart';
import '../widgets/recipe_image.dart';
import '../widgets/recipe_value_card.dart';

/// The user's favorites as a row of photo cards, then the recipes they
/// made with edit and delete buttons, and a "New recipe" button above
/// the dock.
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

  void _openDetail(BuildContext context, Recipe recipe) {
    Navigator.pushNamed(context, Routes.recipeDetail, arguments: recipe);
  }

  void _openForm(BuildContext context, [Recipe? recipe]) {
    Navigator.pushNamed(context, Routes.recipeForm, arguments: recipe);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecipeProvider>();
    final favorites = provider.favoriteRecipes;
    final myRecipes = provider.userRecipes;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          // Room at the bottom so the last card clears the New recipe button.
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 90),
          children: [
            const _LargeTitle(),
            _SectionHeader(title: 'Favorites', count: favorites.length),
            if (favorites.isEmpty)
              const _FavoritesHint()
            else
              SizedBox(
                height: 200,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  // Let the row run to the screen edge while the first card
                  // still lines up with the page padding.
                  clipBehavior: Clip.none,
                  itemCount: favorites.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) => _FavoriteCard(
                    recipe: favorites[index],
                    onTap: () => _openDetail(context, favorites[index]),
                  ),
                ),
              ),
            _SectionHeader(title: 'Made by you', count: myRecipes.length),
            if (myRecipes.isEmpty)
              EmptyState(
                icon: Icons.menu_book_outlined,
                title: 'No recipes yet',
                message:
                    'Add your own budget meal and see its protein per peso.',
                actionLabel: 'Create a recipe',
                onAction: () => _openForm(context),
              ),
            for (final recipe in myRecipes) ...[
              RecipeValueCard(
                recipe: recipe,
                onTap: () => _openDetail(context, recipe),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SmallActionButton(
                      icon: Icons.edit_outlined,
                      tooltip: 'Edit',
                      background: AppColors.background,
                      color: AppColors.textMuted,
                      onPressed: () => _openForm(context, recipe),
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
          onPressed: () => _openForm(context),
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
          'Meals you saved and meals you made',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

/// Small prompt shown when there are no favorites yet.
class _FavoritesHint extends StatelessWidget {
  const _FavoritesHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        children: [
          Icon(Icons.favorite_border, color: AppColors.iconInactive),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tap the heart on any recipe to keep it here.',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

/// A favorite as a tall photo card with its name and protein per peso.
class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({required this.recipe, required this.onTap});

  final Recipe recipe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final proteinPerPeso = context.watch<RecipeProvider>().proteinPerPesoFor(
      recipe,
    );

    return SizedBox(
      width: 156,
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 130,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    RecipeImage(recipe: recipe, emojiSize: 48),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: FavoriteButton(recipe: recipe, floating: true),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: Text(
                  recipe.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (proteinPerPeso != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 2, 12, 0),
                  child: Text(
                    formatProteinPerPeso(proteinPerPeso),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
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
