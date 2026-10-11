import 'package:flutter/material.dart';

import 'screens/main_shell.dart';
import 'screens/recipe_detail_screen.dart';
import 'screens/recipe_form_screen.dart';
import 'screens/recipe_list_screen.dart';
import 'theme/app_theme.dart';
import 'utils/constants.dart';

void main() {
  runApp(const PlatitoApp());
}

class PlatitoApp extends StatelessWidget {
  const PlatitoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Platito',
      theme: AppTheme.light,
      initialRoute: Routes.shell,
      routes: {
        Routes.shell: (context) => const MainShell(),
        Routes.recipeList: (context) => const RecipeListScreen(),
        Routes.recipeDetail: (context) => const RecipeDetailScreen(),
        Routes.recipeForm: (context) => const RecipeFormScreen(),
      },
    );
  }
}
