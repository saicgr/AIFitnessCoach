import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Theme colors interface for bottom sheets
/// Provides consistent theming across all customization sheets
abstract class SheetColors {
  Color get elevated;
  Color get textPrimary;
  Color get textSecondary;
  Color get textMuted;
  Color get cardBorder;
  Color get glassSurface;
  Color get cyan;
  Color get purple;
  Color get orange;
  Color get success;
  Color get error;
}

/// Dark theme colors for sheets
class DarkSheetColors implements SheetColors {
  const DarkSheetColors();

  @override
  Color get elevated => AppColors.elevated;
  @override
  Color get textPrimary => AppColors.textPrimary;
  @override
  Color get textSecondary => AppColors.textSecondary;
  @override
  Color get textMuted => AppColors.textMuted;
  @override
  Color get cardBorder => AppColors.cardBorder;
  @override
  Color get glassSurface => AppColors.glassSurface;
  @override
  Color get cyan => AppColors.cyan;
  @override
  Color get purple => AppColors.purple;
  @override
  Color get orange => AppColors.orange;
  @override
  Color get success => AppColors.success;
  @override
  Color get error => AppColors.error;
}

/// Light theme colors for sheets
class LightSheetColors implements SheetColors {
  const LightSheetColors();

  @override
  Color get elevated => AppColorsLight.elevated;
  @override
  Color get textPrimary => AppColorsLight.textPrimary;
  @override
  Color get textSecondary => AppColorsLight.textSecondary;
  @override
  Color get textMuted => AppColorsLight.textMuted;
  @override
  Color get cardBorder => AppColorsLight.cardBorder;
  @override
  Color get glassSurface => AppColorsLight.glassSurface;
  @override
  Color get cyan => AppColorsLight.cyan;
  @override
  Color get purple => AppColors.purple;
  @override
  Color get orange => AppColors.orange;
  @override
  Color get success => AppColorsLight.success;
  @override
  Color get error => AppColorsLight.error;
}

/// Extension to get appropriate sheet colors based on brightness
extension SheetColorsExtension on BuildContext {
  /// Returns the appropriate SheetColors based on current theme brightness
  SheetColors get sheetColors {
    final isDark = Theme.of(this).brightness == Brightness.dark;
    return isDark ? const DarkSheetColors() : const LightSheetColors();
  }
}

/// Utility function to get difficulty color (monochrome)
Color getDifficultyColor(String difficulty, {bool isDark = true}) {
  switch (difficulty.toLowerCase()) {
    case 'easy':
      return isDark ? const Color(0xFF808080) : const Color(0xFF808080);
    case 'medium':
      return isDark ? const Color(0xFFA0A0A0) : const Color(0xFF606060);
    case 'hard':
      return isDark ? const Color(0xFFC0C0C0) : const Color(0xFF404040);
    case 'hell':
      return isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    default:
      return isDark ? const Color(0xFFA0A0A0) : const Color(0xFF606060);
  }
}

/// Utility function to get workout type color (monochrome)
Color getWorkoutTypeColor(String type, {bool isDark = true}) {
  // All workout types use the same monochrome accent
  return isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
}

/// Utility function to get difficulty icon
IconData getDifficultyIcon(String difficulty) {
  switch (difficulty.toLowerCase()) {
    case 'easy':
      return Icons.check_circle_outline;
    case 'medium':
      return Icons.change_history;
    case 'hard':
      return Icons.star_outline;
    case 'hell':
      return Icons.local_fire_department;
    default:
      return Icons.circle_outlined;
  }
}
