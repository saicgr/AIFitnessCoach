import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// A styled bullet point for use in dialogs.
///
/// Displays a colored dot followed by text content.
class DialogBulletPoint extends StatelessWidget {
  /// The text to display.
  final String text;

  /// The color of the bullet point.
  final Color color;

  /// Whether the current theme is dark mode.
  final bool isDark;

  const DialogBulletPoint({
    super.key,
    required this.text,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6, right: 10),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
