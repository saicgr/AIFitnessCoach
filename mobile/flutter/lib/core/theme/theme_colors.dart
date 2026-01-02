import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Theme-aware color accessor that simplifies getting the right color for current theme.
///
/// Usage:
/// ```dart
/// final colors = ThemeColors.of(context);
/// Container(color: colors.background)
/// Text('Hello', style: TextStyle(color: colors.textPrimary))
/// ```
class ThemeColors {
  final bool isDark;

  const ThemeColors._({required this.isDark});

  /// Get ThemeColors instance for the current context
  static ThemeColors of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ThemeColors._(isDark: isDark);
  }

  // ─────────────────────────────────────────────────────────────────
  // Background Colors
  // ─────────────────────────────────────────────────────────────────

  Color get background => isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
  Color get surface => isDark ? AppColors.surface : AppColorsLight.surface;
  Color get elevated => isDark ? AppColors.elevated : AppColorsLight.elevated;
  Color get glassSurface => isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;

  // ─────────────────────────────────────────────────────────────────
  // Border Colors
  // ─────────────────────────────────────────────────────────────────

  Color get cardBorder => isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

  // ─────────────────────────────────────────────────────────────────
  // Text Colors
  // ─────────────────────────────────────────────────────────────────

  Color get textPrimary => isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
  Color get textSecondary => isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
  Color get textMuted => isDark ? AppColors.textMuted : AppColorsLight.textMuted;

  // ─────────────────────────────────────────────────────────────────
  // Brand Colors (same in both themes)
  // ─────────────────────────────────────────────────────────────────

  Color get cyan => AppColors.cyan;
  Color get cyanDark => AppColors.cyanDark;
  LinearGradient get cyanGradient => AppColors.cyanGradient;

  // ─────────────────────────────────────────────────────────────────
  // Semantic Colors (same in both themes)
  // ─────────────────────────────────────────────────────────────────

  Color get success => isDark ? AppColors.success : AppColorsLight.success;
  Color get warning => isDark ? AppColors.warning : AppColorsLight.warning;
  Color get error => isDark ? AppColors.error : AppColorsLight.error;
  Color get info => isDark ? AppColors.info : AppColorsLight.info;

  // ─────────────────────────────────────────────────────────────────
  // Workout Type Colors (same in both themes)
  // ─────────────────────────────────────────────────────────────────

  Color get strength => AppColors.strength;
  Color get cardio => AppColors.cardio;
  Color get flexibility => AppColors.flexibility;
  Color get hiit => AppColors.hiit;

  // ─────────────────────────────────────────────────────────────────
  // Accent Colors (same in both themes)
  // ─────────────────────────────────────────────────────────────────

  Color get orange => AppColors.orange;
  Color get purple => AppColors.purple;
  Color get coral => AppColors.coral;
  Color get magenta => AppColors.magenta;
}

/// Extension on BuildContext for convenient access to theme colors
extension ThemeColorsExtension on BuildContext {
  /// Get theme-aware colors for the current context
  ThemeColors get colors => ThemeColors.of(this);

  /// Check if current theme is dark
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
