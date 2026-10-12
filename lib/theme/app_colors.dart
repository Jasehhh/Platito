import 'package:flutter/material.dart';

/// Color tokens from DESIGN.md section 2. Use these names instead of raw
/// hex values so every screen stays consistent.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF1F6F50);
  static const Color primaryDark = Color(0xFF0F4D36);
  static const Color primaryLight = Color(0xFFE3F1EA);
  static const Color dock = Color(0xFF15362B);
  static const Color dockActive = Color(0xFFD4EEDF);
  static const Color background = Color(0xFFF4F7F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE6EBE8);
  static const Color textPrimary = Color(0xFF1B1F1D);
  static const Color textMuted = Color(0xFF5F6B66);
  static const Color iconInactive = Color(0xFF9AA6A1);
  static const Color error = Color(0xFFC2412D);
  static const Color errorLight = Color(0xFFFCEDEA);

  /// Home header gradient, top-left to bottom-right.
  static const List<Color> headerGradient = [
    Color(0xFF2A8763),
    Color(0xFF1F6F50),
    Color(0xFF175A41),
  ];

  // Recipe thumbnail tints (soft backgrounds behind food images).
  static const Color tintEgg = Color(0xFFFFF1DB);
  static const Color tintLeaf = Color(0xFFE9F5E1);
  static const Color tintSea = Color(0xFFE4EEF9);
  static const Color tintButter = Color(0xFFFFF6D6);
  static const Color tintClay = Color(0xFFF6E7DD);
}
