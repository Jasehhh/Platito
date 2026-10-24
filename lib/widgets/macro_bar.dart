import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// One nutrition row (DESIGN.md MacroBar): a label and bold value on the
/// left (118 wide), and a green bar on the right filled to [fraction].
class MacroBar extends StatelessWidget {
  const MacroBar({
    super.key,
    required this.label,
    required this.value,
    required this.fraction,
  });

  final String label;
  final String value;

  /// How full the bar is, from 0 (empty) to 1 (full).
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 118,
          child: Text.rich(
            TextSpan(
              text: '$label  ',
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fraction.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: const Color(0xFFE3EAE6),
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}
