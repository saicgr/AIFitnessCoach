import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// A compact badge displaying a stat with an icon
/// Used in the home screen header for workout counts
class StatBadge extends StatelessWidget {
  /// Icon to display
  final IconData icon;

  /// Value to display
  final String value;

  /// Badge color
  final Color color;

  /// Optional tooltip message
  final String? tooltip;

  const StatBadge({
    super.key,
    required this.icon,
    required this.value,
    required this.color,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        preferBelow: true,
        decoration: BoxDecoration(
          color: isDark ? AppColors.elevated : AppColorsLight.elevated,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        textStyle: TextStyle(
          color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
          fontSize: 13,
        ),
        child: badge,
      );
    }

    return badge;
  }
}

/// A pill-shaped stat indicator with icon and value
/// Used in workout cards for duration and exercise count
class StatPill extends StatelessWidget {
  /// Icon to display
  final IconData icon;

  /// Value text
  final String value;

  const StatPill({
    super.key,
    required this.icon,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassSurface =
        isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: glassSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textSecondary),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
