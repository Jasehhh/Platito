import 'package:flutter/material.dart';

import '../models/recipe.dart';
import '../theme/app_colors.dart';

/// The picture for a recipe: its food photo when it has one, otherwise
/// its emoji on a tinted background. It fills whatever size its parent
/// gives it, so RecipeCard and Recipe Detail can share it.
class RecipeImage extends StatelessWidget {
  const RecipeImage({super.key, required this.recipe, this.emojiSize = 30});

  final Recipe recipe;
  final double emojiSize;

  @override
  Widget build(BuildContext context) {
    final image = recipe.image;
    if (image == null) return _emoji();

    return Image.asset(
      image,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      // If the photo is missing from the assets, fall back to the emoji.
      errorBuilder: (context, error, stackTrace) => _emoji(),
    );
  }

  Widget _emoji() {
    final tint = AppColors.tintFor(recipe.id);
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [tint, Color.lerp(tint, AppColors.tintClay, 0.6)!],
        ),
      ),
      child: Text(recipe.emoji, style: TextStyle(fontSize: emojiSize)),
    );
  }
}
