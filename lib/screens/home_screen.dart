import 'package:flutter/material.dart';

import '../widgets/home_header.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Column(
        children: [
          HomeHeader(),
          Expanded(child: Center(child: Text('Recipes coming soon'))),
        ],
      ),
    );
  }
}
