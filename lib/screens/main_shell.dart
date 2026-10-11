import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'ingredient_lookup_screen.dart';
import 'my_recipes_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const List<Widget> _tabs = [
    HomeScreen(),
    IngredientLookupScreen(),
    MyRecipesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Lookup'),
          NavigationDestination(icon: Icon(Icons.book_outlined), selectedIcon: Icon(Icons.book), label: 'My Recipes'),
        ],
      ),
    );
  }
}
