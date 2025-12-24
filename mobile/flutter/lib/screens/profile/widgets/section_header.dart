import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Section header with title and optional action widget.
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;

  const SectionHeader({
    super.key,
    required this.title,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textMuted,
            letterSpacing: 1.5,
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}
