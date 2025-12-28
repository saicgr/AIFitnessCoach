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

/// Utility function to get difficulty color
Color getDifficultyColor(String difficulty) {
  switch (difficulty.toLowerCase()) {
    case 'easy':
      return AppColors.success;
    case 'medium':
      return AppColors.orange;
    case 'hard':
      return AppColors.purple; // Purple for hard
    case 'hell':
      return AppColors.error; // Red for hell (most intense)
    default:
      return AppColors.cyan;
  }
}

/// Utility function to get workout type color
Color getWorkoutTypeColor(String type) {
  switch (type.toLowerCase()) {
    case 'hiit':
      return AppColors.error;
    case 'cardio':
      return AppColors.orange;
    case 'flexibility':
      return AppColors.purple;
    case 'strength':
    default:
      return AppColors.cyan;
  }
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
