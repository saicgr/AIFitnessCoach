import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// A styled section header for the settings screen.
///
/// Displays a muted, uppercase label to group related settings.
class SectionHeader extends StatelessWidget {
  /// The title text to display (will be shown in uppercase).
  final String title;

  const SectionHeader({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textMuted,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
