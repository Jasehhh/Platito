import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

/// Green gradient header for the Home screen (DESIGN.md section 6.1):
/// logo row, a Filipino greeting, and a search bar that overlaps the
/// header's bottom edge by half its height.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, this.onSearchTap, this.onFilterTap});

  /// Called when the search bar is tapped. The search bar is a button that
  /// opens a search screen, not a text field.
  final VoidCallback? onSearchTap;
  final VoidCallback? onFilterTap;

  static const _searchBarHeight = 52.0;

  /// "Good morning / afternoon / evening" in Filipino, based on the hour.
  static String greetingFor(DateTime time) {
    if (time.hour < 12) return 'Magandang umaga!';
    if (time.hour < 18) return 'Magandang hapon!';
    return 'Magandang gabi!';
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    // Light status bar icons on the dark green header.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Stack(
        children: [
          // The gradient stops half a search bar above the bottom, so the
          // search bar below sits half on the header and half off it.
          Padding(
            padding: const EdgeInsets.only(bottom: _searchBarHeight / 2),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                18,
                topInset + 16,
                18,
                _searchBarHeight / 2 + 22,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: AppColors.headerGradient,
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _LogoRow(),
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
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 0,
            child: _SearchBar(
              height: _searchBarHeight,
              onTap: onSearchTap,
              onFilterTap: onFilterTap,
            ),
          ),
        ],
      ),
    );
  }
}

/// Logo mark + "Platito" on the left, a glass bell button on the right.
class _LogoRow extends StatelessWidget {
  const _LogoRow();

  @override
  Widget build(BuildContext context) {
    final glass = Colors.white.withValues(alpha: 0.18);
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: glass,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.rice_bowl, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 10),
        const Text(
          'Platito',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const Spacer(),
        // Glass circle button (40 x 40). Notifications are not built yet.
        Material(
          color: glass,
          shape: const CircleBorder(),
          child: IconButton(
            tooltip: 'Notifications',
            onPressed: () {},
            constraints: const BoxConstraints.tightFor(width: 40, height: 40),
            padding: EdgeInsets.zero,
            icon: const Icon(
              Icons.notifications_none,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }
}

/// White search bar with a soft green shadow and a filter button.
class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.height, this.onTap, this.onFilterTap});

  final double height;
  final VoidCallback? onTap;
  final VoidCallback? onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x290F4D36), // rgba(15, 77, 54, 0.16)
            offset: Offset(0, 8),
            blurRadius: 20,
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.only(left: 14, right: 7),
            child: Row(
              children: [
                const Icon(Icons.search, color: AppColors.textMuted),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Search budget meals',
                    style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                  ),
                ),
                Material(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: onFilterTap,
                    child: const SizedBox(
                      width: 38,
                      height: 38,
                      child: Tooltip(
                        message: 'Filter',
                        child: Icon(
                          Icons.tune,
                          color: AppColors.primaryDark,
                          size: 20,
                        ),
                      ),
                    ),
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
