import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/recipe.dart';
import '../providers/recipe_provider.dart';
import '../utils/formatters.dart';
import 'cost_badge.dart';
import 'favorite_button.dart';
import 'recipe_card.dart';

/// A [RecipeCard] filled in from [RecipeProvider]: protein and cost per
/// serving in the caption, a protein-per-peso badge, and a heart button
/// unless [trailing] replaces it. Home, Recipe List, and My Recipes all
/// use it, so the numbers match on every screen.
class RecipeValueCard extends StatelessWidget {
  const RecipeValueCard({
    super.key,
    required this.recipe,
    this.trailing,
    this.onTap,
  });

  final Recipe recipe;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecipeProvider>();
    final proteinPerPeso = provider.proteinPerPesoFor(recipe);

    return RecipeCard(
      recipe: recipe,
      caption: recipeCaption(
        provider.perServingFor(recipe)?.protein,
        provider.costPerServingFor(recipe),
      ),
      badge: proteinPerPeso == null
          ? null
          : CostBadge(label: formatProteinPerPeso(proteinPerPeso)),
      trailing: trailing ?? FavoriteButton(recipe: recipe),
      onTap: onTap,
    );
  }
}
