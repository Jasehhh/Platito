import 'package:flutter/material.dart';

import '../widgets/platito_dock.dart';

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
      // Lets tab content scroll behind the floating dock. Scaffold also adds
      // the dock's height to the bottom padding, so SafeArea in each tab
      // keeps the last item above the dock.
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: PlatitoDock(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          PlatitoDockItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: 'Home',
          ),
          PlatitoDockItem(
            icon: Icons.search,
            activeIcon: Icons.search,
            label: 'Lookup',
          ),
          PlatitoDockItem(
            icon: Icons.book_outlined,
            activeIcon: Icons.book,
            label: 'My Recipes',
          ),
        ],
      ),
    );
  }
}
