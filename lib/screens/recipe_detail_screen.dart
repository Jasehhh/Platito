import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/recipe.dart';
import '../providers/recipe_provider.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../utils/nutrition_calculator.dart';
import '../widgets/circle_icon_button.dart';
import '../widgets/cost_badge.dart';
import '../widgets/empty_state.dart';
import '../widgets/favorite_button.dart';
import '../widgets/macro_bar.dart';

/// One recipe with its cost, USDA nutrition per serving, ingredients, and
/// steps. Opened with
/// Navigator.pushNamed(context, Routes.recipeDetail, arguments: recipe).
class RecipeDetailScreen extends StatelessWidget {
  const RecipeDetailScreen({super.key});

  static const _headerHeight = 290.0;

  /// The content sheet slides up over the image by this much.
  static const _sheetOverlap = 26.0;

  @override
  Widget build(BuildContext context) {
    final argument = ModalRoute.of(context)!.settings.arguments as Recipe;
    final provider = context.watch<RecipeProvider>();
    // Use the latest version, so an edited user recipe updates here too.
    final recipe = provider.recipeById(argument.id) ?? argument;
    final proteinPerPeso = provider.proteinPerPesoFor(recipe);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: Stack(
          children: [
            ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildImageHeader(recipe),
                Transform.translate(
                  offset: const Offset(0, -_sheetOverlap),
                  child: _Sheet(
                    children: [
                      Text(
                        recipe.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${recipe.category} · Serves ${recipe.servings}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          CostBadge(
                            icon: Icons.account_balance_wallet_outlined,
                            label:
                                '${formatPesos(provider.costFor(recipe))} total',
                          ),
                          if (proteinPerPeso != null)
                            CostBadge(
                              icon: Icons.bolt,
                              label: formatProteinPerPeso(proteinPerPeso),
                            ),
                        ],
                      ),
                      const _SectionTitle('Nutrition per serving'),
                      _buildNutrition(provider, recipe),
                      const _SectionTitle('Ingredients'),
                      _Panel(
                        children: [
                          for (final ingredient in recipe.ingredients)
                            _IngredientRow(
                              name: ingredient.name,
                              grams: ingredient.grams,
                              price: ingredient.price,
                            ),
                        ],
                      ),
                      const _SectionTitle('Steps'),
                      for (var i = 0; i < recipe.steps.length; i++)
                        _StepRow(number: i + 1, text: recipe.steps[i]),
                    ],
                  ),
                ),
              ],
            ),
            // Floating back and favorite buttons stay put while content scrolls.
            Positioned(
              top: MediaQuery.paddingOf(context).top + 10,
              left: 18,
              child: CircleIconButton(
                icon: Icons.chevron_left,
                tooltip: 'Back',
                floating: true,
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Positioned(
              top: MediaQuery.paddingOf(context).top + 10,
              right: 18,
              child: FavoriteButton(recipe: recipe, floating: true),
            ),
          ],
        ),
      ),
    );
  }

  /// DESIGN.md 6.4: tinted gradient with the recipe emoji in place of a
  /// food photo.
  Widget _buildImageHeader(Recipe recipe) {
    final tint = AppColors.tintFor(recipe.id);
    return Container(
      height: _headerHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [tint, Color.lerp(tint, AppColors.tintClay, 0.6)!],
        ),
      ),
      child: Text(recipe.emoji, style: const TextStyle(fontSize: 96)),
    );
  }

  Widget _buildNutrition(RecipeProvider provider, Recipe recipe) {
    final perServing = provider.perServingFor(recipe);

    if (perServing == null && provider.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (perServing == null) {
      return EmptyState(
        icon: Icons.wifi_off,
        title: 'Nutrition unavailable',
        message: provider.errorMessage ?? 'Could not load USDA data.',
        actionLabel: 'Retry',
        onAction: provider.retry,
      );
    }

    return _Panel(
      children: [
        Text.rich(
          TextSpan(
            text: '${perServing.calories.round()} kcal',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            children: const [
              TextSpan(
                text: '  per serving · USDA FoodData Central',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.normal,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        ..._macroBars(perServing),
      ],
    );
  }

  /// Each bar shows how much of the serving's calories come from that
  /// macro: protein and carbs have 4 kcal per gram, fat has 9.
  List<Widget> _macroBars(NutritionTotals perServing) {
    final macroKcal =
        perServing.protein * 4 + perServing.carbs * 4 + perServing.fat * 9;
    double share(double kcal) => macroKcal == 0 ? 0 : kcal / macroKcal;

    return [
      MacroBar(
        label: 'Protein',
        value: '${perServing.protein.toStringAsFixed(1)} g',
        fraction: share(perServing.protein * 4),
      ),
      MacroBar(
        label: 'Carbs',
        value: '${perServing.carbs.toStringAsFixed(1)} g',
        fraction: share(perServing.carbs * 4),
      ),
      MacroBar(
        label: 'Fat',
        value: '${perServing.fat.toStringAsFixed(1)} g',
        fraction: share(perServing.fat * 9),
      ),
    ];
  }
}

/// White rounded sheet with a grab handle that holds the recipe content.
class _Sheet extends StatelessWidget {
  const _Sheet({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 32),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFD3DCD7),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// DESIGN.md Panel: white box with a border that groups related rows.
class _Panel extends StatelessWidget {
  const _Panel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({
    required this.name,
    required this.grams,
    required this.price,
  });

  final String name;
  final double grams;
  final double price;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(name, style: const TextStyle(fontSize: 14))),
        Text(
          '${grams.round()} g',
          style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        SizedBox(
          width: 56,
          child: Text(
            formatPesos(price),
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

/// A numbered step: a light-green circle with the number, then the text.
class _StepRow extends StatelessWidget {
  const _StepRow({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(text, style: const TextStyle(fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}
