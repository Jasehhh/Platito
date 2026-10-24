import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

/// Green gradient header shared by the tab screens (DESIGN.md 6.1): it
/// draws behind the status bar, has rounded bottom corners, and can hold
/// an [overlap] widget, such as a search bar, that sits half on the
/// header's bottom edge and half below it.
class GradientHeader extends StatelessWidget {
  const GradientHeader({
    super.key,
    required this.child,
    this.overlap,
    this.overlapHeight = 52,
  });

  /// Content inside the green area.
  final Widget child;
  final Widget? overlap;
  final double overlapHeight;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final overlapWidget = overlap;
    final half = overlapWidget == null ? 0.0 : overlapHeight / 2;

    // Light status bar icons on the dark green header.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Stack(
        children: [
          // The gradient stops half an overlap above the bottom, so the
          // overlap widget sits half on the header and half off it.
          Padding(
            padding: EdgeInsets.only(bottom: half),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(18, topInset + 16, 18, half + 22),
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
              child: child,
            ),
          ),
          if (overlapWidget != null)
            Positioned(
              left: 18,
              right: 18,
              bottom: 0,
              height: overlapHeight,
              child: overlapWidget,
            ),
        ],
      ),
    );
  }
}

/// Large white title with a caption, for the Lookup and My Recipes
/// headers.
class GradientHeaderTitle extends StatelessWidget {
  const GradientHeaderTitle({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }
}

/// White bar that sits on a [GradientHeader] edge, with the soft green
/// shadow from DESIGN.md. Used for the search bars and the add bar.
class HeaderBar extends StatelessWidget {
  const HeaderBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: child,
    );
  }
}
