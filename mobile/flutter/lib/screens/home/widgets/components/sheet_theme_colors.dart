import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/accent_color_provider.dart';
import '../../../../core/theme/theme_colors.dart';

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
  final Color accent;
  const DarkSheetColors(this.accent);

  // This class IS a theme mapping (mirrors ThemeColors for bottom sheets) --
  // SheetColorsExtension.sheetColors below picks DarkSheetColors vs
  // LightSheetColors from the real Theme.of(context).brightness, so these
  // getters resolve correctly per-theme even though they can't take context.
  @override
  Color get elevated => AppColors.elevated;  // accent-allowlist: sheet theme mapping -- see class doc above
  @override
  Color get textPrimary => AppColors.textPrimary;  // accent-allowlist: sheet theme mapping -- see class doc above
  @override
  Color get textSecondary => AppColors.textSecondary;  // accent-allowlist: sheet theme mapping -- see class doc above
  @override
  Color get textMuted => AppColors.textMuted;  // accent-allowlist: sheet theme mapping -- see class doc above
  @override
  Color get cardBorder => AppColors.cardBorder;  // accent-allowlist: sheet theme mapping -- see class doc above
  @override
  Color get glassSurface => AppColors.glassSurface;  // accent-allowlist: sheet theme mapping -- see class doc above
  @override
  Color get cyan => accent;
  @override
  Color get purple => accent;
  @override
  Color get orange => accent;
  @override
  Color get success => AppColors.success;  // accent-allowlist: success/positive state -- must stay green regardless of accent
  @override
  Color get error => AppColors.error;  // accent-allowlist: error/destructive -- must stay red
}

/// Light theme colors for sheets
class LightSheetColors implements SheetColors {
  final Color accent;
  const LightSheetColors(this.accent);

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
  Color get purple => accent;
  @override
  Color get orange => accent;
  @override
  Color get success => AppColorsLight.success;  // accent-allowlist: success/positive state -- must stay green regardless of accent
  @override
  Color get error => AppColorsLight.error;  // accent-allowlist: error/destructive -- must stay red
}

/// Extension to get appropriate sheet colors based on brightness
extension SheetColorsExtension on BuildContext {
  /// Returns the appropriate SheetColors based on current theme brightness
  SheetColors get sheetColors {
    final isDark = Theme.of(this).brightness == Brightness.dark;
    final accent = accentColor;
    return isDark ? DarkSheetColors(accent) : LightSheetColors(accent);
  }
}

/// Utility function to get difficulty color (monochrome)
Color getDifficultyColor(BuildContext context, String difficulty) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  switch (difficulty.toLowerCase()) {
    case 'easy':
      return isDark ? const Color(0xFF808080) : const Color(0xFF808080);
    case 'medium':
      return isDark ? const Color(0xFFA0A0A0) : const Color(0xFF606060);
    case 'hard':
      return isDark ? const Color(0xFFC0C0C0) : const Color(0xFF404040);
    case 'hell':
      return ThemeColors.of(context).textPrimary;
    default:
      return isDark ? const Color(0xFFA0A0A0) : const Color(0xFF606060);
  }
}

/// Utility function to get workout type color (monochrome)
Color getWorkoutTypeColor(BuildContext context, String type) {
  // All workout types use the same monochrome accent
  return ThemeColors.of(context).textSecondary;
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
