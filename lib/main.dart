import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/recipe_provider.dart';
import 'screens/main_shell.dart';
import 'screens/recipe_detail_screen.dart';
import 'screens/recipe_form_screen.dart';
import 'screens/recipe_list_screen.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'utils/constants.dart';

void main() {
  runApp(const PlatitoApp());
}

class PlatitoApp extends StatelessWidget {
  const PlatitoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // lazy: false creates the provider at startup instead of on first
        // use, so recipes and nutrition start loading right away.
        ChangeNotifierProvider(
          create: (context) => RecipeProvider()..load(),
          lazy: false,
        ),
      ],
      child: MaterialApp(
        title: 'Platito',
        theme: AppTheme.light,
        // builder wraps the Navigator, so every screen, bottom sheet, and
        // dialog stays inside a phone-width column on wide screens (web,
        // desktop, tablet). Phones narrower than 480 px are unchanged.
        builder: (context, child) => ColoredBox(
          color: AppColors.border,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: child,
            ),
          ),
        ),
        initialRoute: Routes.shell,
        routes: {
          Routes.shell: (context) => const MainShell(),
          Routes.recipeList: (context) => const RecipeListScreen(),
          Routes.recipeDetail: (context) => const RecipeDetailScreen(),
          Routes.recipeForm: (context) => const RecipeFormScreen(),
        },
      ),
    );
  }
}
