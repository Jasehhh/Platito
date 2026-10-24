import 'package:flutter/material.dart';

import '../models/recipe.dart';
import '../theme/app_colors.dart';
import 'recipe_image.dart';

/// Photo tile for one recipe category on Home: a dish from the category
/// fills the tile, and the name and a short fact sit on a dark fade at
/// the bottom so they stay readable on any photo.
class CategoryTile extends StatelessWidget {
  const CategoryTile({
    super.key,
    required this.title,
    required this.caption,
    this.coverRecipe,
    this.onTap,
  });

  final String title;
  final String caption;

  /// The recipe whose photo fills the tile, or null for a plain green tile.
  final Recipe? coverRecipe;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cover = coverRecipe;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Material(
        color: AppColors.primary,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (cover != null) RecipeImage(recipe: cover),
              // Dark at the bottom, clear at the top.
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.3, 1],
                    colors: [Color(0x00000000), Color(0xE60B241B)],
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [Shadow(blurRadius: 6)],
                      ),
                    ),
                    Text(
                      caption,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
