import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/recipe.dart';
import '../providers/recipe_provider.dart';
import '../theme/app_colors.dart';

/// Heart button that adds [recipe] to favorites or removes it.
/// [floating] gives it the 92% white circle with a shadow used over the
/// Recipe Detail photo; otherwise it is a plain icon for recipe cards.
class FavoriteButton extends StatelessWidget {
  const FavoriteButton({
    super.key,
    required this.recipe,
    this.floating = false,
  });

  final Recipe recipe;
  final bool floating;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecipeProvider>();
    final isFavorite = provider.isFavorite(recipe);

    final button = IconButton(
      tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
      onPressed: () => provider.toggleFavorite(recipe),
      padding: EdgeInsets.zero,
      icon: Icon(
        isFavorite ? Icons.favorite : Icons.favorite_border,
        size: 22,
        color: isFavorite ? AppColors.error : AppColors.iconInactive,
      ),
    );
    if (!floating) return button;

    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x1F000000), // rgba(0, 0, 0, 0.12)
            offset: Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Material(
        color: Colors.white.withValues(alpha: 0.92),
        shape: const CircleBorder(),
        child: button,
      ),
    );
  }
}
