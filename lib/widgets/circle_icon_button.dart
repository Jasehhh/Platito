import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 40 x 40 round icon button used in top bars (DESIGN.md section 7).
/// [floating] switches from the soft style (white with a border) to the
/// float style (92% white with a shadow) used over the Recipe Detail image.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.floating = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool floating;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: floating
            ? const [
                BoxShadow(
                  color: Color(0x1F000000), // rgba(0, 0, 0, 0.12)
                  offset: Offset(0, 4),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      child: Material(
        color: floating
            ? Colors.white.withValues(alpha: 0.92)
            : AppColors.surface,
        shape: CircleBorder(
          side: floating
              ? BorderSide.none
              : const BorderSide(color: AppColors.border),
        ),
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          padding: EdgeInsets.zero,
          icon: Icon(icon, size: 20, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
