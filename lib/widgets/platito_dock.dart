import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// One tab in the [PlatitoDock].
class PlatitoDockItem {
  const PlatitoDockItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// Floating dark-green navigation pill (DESIGN.md section 5).
/// The active tab shows a light pill with a filled icon and label;
/// inactive tabs show only an icon.
class PlatitoDock extends StatelessWidget {
  const PlatitoDock({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<PlatitoDockItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
        child: Container(
          height: 66,
          padding: const EdgeInsets.symmetric(horizontal: 9),
          decoration: BoxDecoration(
            color: AppColors.dock,
            borderRadius: BorderRadius.circular(33),
            boxShadow: const [
              BoxShadow(
                color: Color(0x590A281E), // rgba(10, 40, 30, 0.35)
                offset: Offset(0, 12),
                blurRadius: 28,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < items.length; i++)
                _DockButton(
                  item: items[i],
                  isActive: i == currentIndex,
                  onTap: () => onTap(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DockButton extends StatelessWidget {
  const _DockButton({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final PlatitoDockItem item;
  final bool isActive;
  final VoidCallback onTap;

  static const _duration = Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context) {
    final iconColor = isActive
        ? AppColors.primaryDark
        : Colors.white.withValues(alpha: 0.62);

    return Semantics(
      button: true,
      selected: isActive,
      label: item.label,
      child: Tooltip(
        message: item.label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: _duration,
            curve: Curves.easeOut,
            height: 48,
            constraints: const BoxConstraints(minWidth: 72),
            padding: EdgeInsets.symmetric(horizontal: isActive ? 18 : 0),
            decoration: BoxDecoration(
              // Fading from a transparent version of the same color keeps
              // the animation from flashing gray.
              color: isActive
                  ? AppColors.dockActive
                  : AppColors.dockActive.withValues(alpha: 0),
              borderRadius: BorderRadius.circular(24),
            ),
            child: AnimatedSize(
              duration: _duration,
              curve: Curves.easeOut,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isActive ? item.activeIcon : item.icon,
                    color: iconColor,
                  ),
                  if (isActive) ...[
                    const SizedBox(width: 8),
                    Text(
                      item.label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
