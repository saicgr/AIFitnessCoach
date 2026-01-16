import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import 'accent_color_provider.dart';

/// Theme-aware color accessor that simplifies getting the right color for current theme.
///
/// Usage:
/// ```dart
/// final colors = ThemeColors.of(context);
/// Container(color: colors.background)
/// Text('Hello', style: TextStyle(color: colors.textPrimary))
/// Container(color: colors.accent) // Automatically uses selected accent color!
/// ```
///
/// The accent color is automatically read from AccentColorScope if available.
/// Wrap your app with AccentColorScopeWrapper to enable dynamic accent colors.
class ThemeColors {
  final bool isDark;
  final AccentColor? _selectedAccent;

  const ThemeColors._({required this.isDark, AccentColor? selectedAccent})
      : _selectedAccent = selectedAccent;

  /// Get ThemeColors instance for the current context
  /// Automatically reads accent color from AccentColorScope if available
  static ThemeColors of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Try to get accent from AccentColorScope
    final accent = AccentColorScope.maybeOf(context);
    return ThemeColors._(isDark: isDark, selectedAccent: accent);
  }

  /// Get ThemeColors with a specific accent color (explicit override)
  static ThemeColors withAccent(BuildContext context, AccentColor accent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ThemeColors._(isDark: isDark, selectedAccent: accent);
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
  // Brand/Accent Colors (dynamic based on selected accent)
  // ─────────────────────────────────────────────────────────────────

  /// Primary accent color - uses selected accent if available, otherwise monochrome
  Color get accent {
    if (_selectedAccent != null) {
      return _selectedAccent.getColor(isDark);
    }
    return isDark ? AppColors.accent : AppColorsLight.accent;
  }

  /// Text color on accent backgrounds
  Color get accentContrast {
    if (_selectedAccent != null) {
      // For colored accents, use white or black based on color brightness
      if (_selectedAccent == AccentColor.black) {
        return isDark ? Colors.black : Colors.white;
      }
      // For colorful accents, use white text (better contrast)
      return Colors.white;
    }
    return isDark ? AppColors.accentContrast : AppColorsLight.accentContrast;
  }

  /// Accent gradient for buttons
  LinearGradient get accentGradient {
    if (_selectedAccent != null && _selectedAccent != AccentColor.black) {
      final baseColor = _selectedAccent.getColor(isDark);
      // Create a gradient from the accent color to a slightly darker version
      return LinearGradient(
        colors: [baseColor, HSLColor.fromColor(baseColor).withLightness(
          (HSLColor.fromColor(baseColor).lightness * 0.85).clamp(0.0, 1.0)
        ).toColor()],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    return isDark ? AppColors.accentGradient : AppColorsLight.accentGradient;
  }

  // Legacy color names - now map to theme-aware accent for monochrome design
  Color get cyan => isDark ? AppColors.accent : AppColorsLight.accent;
  Color get cyanDark => isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
  LinearGradient get cyanGradient => isDark ? AppColors.accentGradient : AppColorsLight.accentGradient;

  // ─────────────────────────────────────────────────────────────────
  // Semantic Colors (theme-aware)
  // ─────────────────────────────────────────────────────────────────

  Color get success => isDark ? AppColors.success : AppColorsLight.success;
  Color get warning => isDark ? AppColors.warning : AppColorsLight.warning;
  Color get error => isDark ? AppColors.error : AppColorsLight.error;
  Color get info => isDark ? AppColors.info : AppColorsLight.info;

  // ─────────────────────────────────────────────────────────────────
  // Workout Type Colors (theme-aware monochrome)
  // ─────────────────────────────────────────────────────────────────

  Color get strength => isDark ? AppColors.strength : AppColorsLight.strength;
  Color get cardio => isDark ? AppColors.cardio : AppColorsLight.cardio;
  Color get flexibility => isDark ? AppColors.flexibility : AppColorsLight.flexibility;
  Color get hiit => isDark ? AppColors.hiit : AppColorsLight.hiit;

  // ─────────────────────────────────────────────────────────────────
  // Accent Colors (theme-aware - all map to accent for monochrome)
  // ─────────────────────────────────────────────────────────────────

  Color get orange => isDark ? AppColors.accent : AppColorsLight.accent;
  Color get purple => isDark ? AppColors.accent : AppColorsLight.accent;
  Color get coral => isDark ? AppColors.accent : AppColorsLight.accent;
  Color get magenta => isDark ? AppColors.accent : AppColorsLight.accent;
  Color get electricBlue => isDark ? AppColors.accent : AppColorsLight.accent;
  Color get teal => isDark ? AppColors.accent : AppColorsLight.accent;
}

/// Extension on BuildContext for convenient access to theme colors
extension ThemeColorsExtension on BuildContext {
  /// Get theme-aware colors for the current context (monochrome accent)
  ThemeColors get colors => ThemeColors.of(this);

  /// Check if current theme is dark
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}

/// Extension on WidgetRef for convenient access to theme colors with dynamic accent
extension RefThemeColorsExtension on WidgetRef {
  /// Get theme-aware colors with the user's selected accent color
  ThemeColors colors(BuildContext context) {
    final selectedAccent = watch(accentColorProvider);
    return ThemeColors.withAccent(context, selectedAccent);
  }
}
