import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'gradient_header.dart';

/// Home's version of [GradientHeader] (DESIGN.md section 6.1): app name,
/// a Filipino greeting, and a search bar on the header's bottom edge.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, this.onSearchTap});

  /// Called when the search bar is tapped. The search bar is a button that
  /// opens a search screen, not a text field.
  final VoidCallback? onSearchTap;

  /// "Good morning / afternoon / evening" in Filipino, based on the hour.
  static String greetingFor(DateTime time) {
    if (time.hour < 12) return 'Magandang umaga!';
    if (time.hour < 18) return 'Magandang hapon!';
    return 'Magandang gabi!';
  }

  @override
  Widget build(BuildContext context) {
    return GradientHeader(
      overlap: _SearchBar(onTap: onSearchTap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Platito',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            greetingFor(DateTime.now()),
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'What are we eating for gains today?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// White search bar button.
class _SearchBar extends StatelessWidget {
  const _SearchBar({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return HeaderBar(
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Icon(Icons.search, color: AppColors.textMuted),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Search budget meals',
                    style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
