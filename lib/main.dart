import 'package:flutter/material.dart';

import 'theme/app_theme.dart';

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
      home: const Scaffold(body: Center(child: Text('Platito'))),
    );
  }
}
