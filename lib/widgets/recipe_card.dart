import 'package:flutter/material.dart';

import '../models/recipe.dart';
import '../theme/app_colors.dart';

/// White card for one recipe (DESIGN.md section 7): a tinted emoji
/// thumbnail, the name, a caption such as "24 g protein · ₱55", an
/// optional value [badge], and an optional [trailing] widget such as
/// edit and delete buttons.
class RecipeCard extends StatelessWidget {
  const RecipeCard({
    super.key,
    required this.recipe,
    required this.caption,
    this.badge,
    this.trailing,
    this.onTap,
  });

  final Recipe recipe;
  final String caption;
  final Widget? badge;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Container(
                width: 62,
                height: 62,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.tintFor(recipe.id),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(recipe.emoji, style: const TextStyle(fontSize: 30)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      caption,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    if (badge != null) ...[const SizedBox(height: 6), badge!],
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}
