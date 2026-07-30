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

  /// The single resolved accent, read from the ambient [AccentColorScope].
  ///
  /// There is no override channel any more (register row 15): [ResolvedAccent]
  /// carries only the user's chosen [AccentColor], so every getter below
  /// resolves to the same colour no matter when it is read.
  final ResolvedAccent? _selectedAccent;

  const ThemeColors._({required this.isDark, ResolvedAccent? selectedAccent})
      : _selectedAccent = selectedAccent;

  /// Get ThemeColors instance for the current context
  /// Automatically reads accent color from AccentColorScope if available
  static ThemeColors of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolved = AccentColorScope.maybeOf(context);
    return ThemeColors._(isDark: isDark, selectedAccent: resolved);
  }

  /// Get ThemeColors for an explicitly named accent.
  ///
  /// Use ONLY for previews (the accent picker's swatches) — never to paint a
  /// live surface, or that surface becomes a second accent source.
  static ThemeColors withAccent(BuildContext context, AccentColor accent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ThemeColors._(
      isDark: isDark,
      selectedAccent: ResolvedAccent(accent: accent),
    );
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
      // Black-mono accent → flip with theme. Otherwise pick dark text on light
      // accents and white text on dark/colorful ones.
      if (_selectedAccent.accent == AccentColor.black) {
        return isDark ? Colors.black : Colors.white;
      }
      return _selectedAccent.isLightFor(isDark) ? Colors.black : Colors.white;
    }
    return isDark ? AppColors.accentContrast : AppColorsLight.accentContrast;
  }

  /// Accent gradient for buttons
  LinearGradient get accentGradient {
    if (_selectedAccent != null &&
        _selectedAccent.accent != AccentColor.black) {
      final baseColor = _selectedAccent.getColor(isDark);
      // Create a gradient from the accent color to a slightly darker version
      return LinearGradient(
        colors: [baseColor, HSLColor.fromColor(baseColor).withLightness(
          (HSLColor.fromColor(baseColor).lightness * 0.85).clamp(0.0, 1.0)
        ).toColor()],
        begin: AlignmentDirectional.topStart,
        end: AlignmentDirectional.bottomEnd,
      );
    }
    return isDark ? AppColors.accentGradient : AppColorsLight.accentGradient;
  }

  // ── Legacy colour-name aliases ───────────────────────────────────────────
  // These are named after colours but every caller means "the accent". They
  // used to return the STATIC `AppColors.accent` (pure white in dark, pure
  // black in light), which ignored the user's chosen accent entirely — so a
  // screen built from `colors.cyan` and a screen built from `colors.accent`
  // rendered two different colours for the same intent (register row 15).
  // They now all route through the single [accent] getter.
  Color get cyan => accent;
  Color get cyanDark => isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
  LinearGradient get cyanGradient => accentGradient;

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
  // Accent Colors — every one of these IS the single accent.
  // ─────────────────────────────────────────────────────────────────

  Color get orange => accent;
  Color get purple => accent;
  Color get coral => accent;
  Color get magenta => accent;
  Color get electricBlue => accent;
  Color get teal => accent;

  // ─────────────────────────────────────────────────────────────────
  // Metadata pill role (register row 51)
  // ─────────────────────────────────────────────────────────────────
  //
  // Workout/exercise metadata chips (duration · difficulty · exercise count ·
  // equipment) were each given their OWN colour, which reads as a legend the
  // app never defines — the user hunts for a meaning that does not exist.
  // Metadata is not a status, so it gets ONE quiet neutral treatment. Use the
  // semantic getters ([success] / [warning] / [error]) only where the pill
  // really does encode state.

  /// Fill behind a metadata pill.
  Color get metaPillFill => isDark
      ? AppColors.textPrimary.withValues(alpha: 0.06)
      : AppColorsLight.textPrimary.withValues(alpha: 0.05);

  /// Hairline border of a metadata pill.
  Color get metaPillBorder => cardBorder;

  /// Label + icon colour inside a metadata pill.
  Color get metaPillText => textSecondary;

  /// The one metadata pill per group that is allowed to carry the accent
  /// (e.g. the pill naming the workout's primary focus). Everything else in
  /// the row must use [metaPillText] — one accent per group, never three.
  Color get metaPillLeadText => accent;
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
