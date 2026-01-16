/// Workout Design System
///
/// Design tokens for the active workout screen, inspired by MacroFactor Workouts 2026.
/// Provides colors, typography, spacing, and component styles for a clean,
/// professional "sleek interface with serious power" aesthetic.
library;

import 'package:flutter/material.dart';

/// Core design tokens for workout screens
class WorkoutDesign {
  WorkoutDesign._();

  // ============================================================================
  // COLORS
  // ============================================================================

  /// Background colors
  static const Color background = Color(0xFF0F0F10);
  static const Color backgroundLight = Color(0xFFFAFAFB);

  /// Surface/card colors
  static const Color surface = Color(0xFF18181B);
  static const Color surfaceLight = Color(0xFFFFFFFF);

  /// Input field colors
  static const Color inputField = Color(0xFF27272A);
  static const Color inputFieldLight = Color(0xFFF4F4F5);
  static const Color inputFieldFocused = Color(0xFF3F3F46);

  /// Border colors
  static const Color border = Color(0xFF3F3F46);
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color borderSubtle = Color(0xFF27272A);

  /// RIR (Reps in Reserve) pill colors - colored for quick scanning
  /// Red (MAX/0) → Orange (1) → Yellow (2) → Green (3+)
  static const Color rirMax = Color(0xFFEF4444); // Red - MAX effort (RIR 0)
  static const Color rir1 = Color(0xFFF97316); // Orange - RIR 1 (challenging)
  static const Color rir2 = Color(0xFFEAB308); // Yellow/Amber - RIR 2 (moderate)
  static const Color rir3 = Color(0xFF22C55E); // Green - RIR 3+ (easy/warmup)
  static const Color rir4 = Color(0xFF22C55E); // Green - RIR 4+ (easy/warmup)
  static const Color rir5 = Color(0xFF22C55E); // Green - RIR 5 (warmup)

  /// Accent colors - monochrome
  static const Color accent = Color(0xFFE0E0E0); // Light gray for AI features
  static const Color accentBlue = Color(0xFF909090); // Neutral gray for selections
  static const Color success = Color(0xFF808080); // Gray for completion
  static const Color warning = Color(0xFF606060); // Dark gray for warnings

  /// Text colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA1A1AA);
  static const Color textMuted = Color(0xFF71717A);
  static const Color textPrimaryLight = Color(0xFF18181B);
  static const Color textSecondaryLight = Color(0xFF71717A);

  // ============================================================================
  // TYPOGRAPHY
  // ============================================================================

  /// Timer display (large, bold)
  static const TextStyle timerStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    color: textPrimary,
  );

  /// Large timer (rest countdown)
  static const TextStyle timerLargeStyle = TextStyle(
    fontSize: 64,
    fontWeight: FontWeight.w700,
    letterSpacing: -2,
    height: 1.0,
    color: textPrimary,
  );

  /// Exercise title
  static const TextStyle titleStyle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: textPrimary,
  );

  /// Subtitle (Set X of Y)
  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );

  /// Table header labels
  static const TextStyle tableHeaderStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: textMuted,
  );

  /// Auto column (target weight/reps)
  static const TextStyle autoTargetStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: textSecondary,
  );

  /// Auto column RIR label
  static const TextStyle autoRirStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: textMuted,
  );

  /// Input field text
  static const TextStyle inputStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  /// Chip label
  static const TextStyle chipStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );

  /// Section label (small caps style)
  static const TextStyle labelStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
    color: textMuted,
  );

  // ============================================================================
  // SPACING
  // ============================================================================

  /// Base unit (8px grid)
  static const double unit = 8.0;

  /// Component padding
  static const double paddingSmall = 8.0; // 1 unit
  static const double paddingMedium = 16.0; // 2 units
  static const double paddingLarge = 24.0; // 3 units

  /// Row heights
  static const double setRowHeight = 56.0;
  static const double thumbnailHeight = 60.0;
  static const double thumbnailWidth = 80.0;
  static const double chipHeight = 36.0;

  /// Input field dimensions
  static const double inputFieldWidth = 72.0;
  static const double inputFieldHeight = 44.0;

  /// Touch targets
  static const double touchTargetMin = 48.0;

  // ============================================================================
  // RADII
  // ============================================================================

  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusRound = 100.0;

  // ============================================================================
  // DECORATIONS
  // ============================================================================

  /// Dark input field decoration
  static InputDecoration inputDecoration({
    String? hintText,
    bool enabled = true,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: enabled ? inputField : inputField.withOpacity(0.5),
      hintText: hintText,
      hintStyle: inputStyle.copyWith(color: textMuted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSmall),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSmall),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSmall),
        borderSide: const BorderSide(color: accentBlue, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
      isDense: true,
    );
  }

  /// Card decoration
  static BoxDecoration cardDecoration({bool isDark = true}) {
    return BoxDecoration(
      color: isDark ? surface : surfaceLight,
      borderRadius: BorderRadius.circular(radiusMedium),
      border: Border.all(
        color: isDark ? borderSubtle : borderLight,
        width: 1,
      ),
    );
  }

  /// Chip decoration (unselected)
  static BoxDecoration chipDecoration({bool isSelected = false, bool isDark = true}) {
    return BoxDecoration(
      color: isSelected
          ? (isDark ? textPrimary : textPrimaryLight)
          : (isDark ? surface : surfaceLight),
      borderRadius: BorderRadius.circular(radiusRound),
      border: Border.all(
        color: isDark ? border : borderLight,
        width: 1,
      ),
    );
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  /// Get RIR pill color based on RIR value
  /// Red (MAX/0) → Orange (1) → Yellow (2) → Green (3+)
  static Color getRirColor(int rir) {
    switch (rir) {
      case 0:
        return rirMax; // Red - MAX effort
      case 1:
        return rir1; // Orange - challenging
      case 2:
        return rir2; // Yellow - moderate
      case 3:
        return rir3; // Green - easy
      default:
        return rir4; // Green - warmup (4+)
    }
  }

  /// Get text color for RIR pill (ensures contrast)
  static Color getRirTextColor(int rir) {
    // Use white text for all colored pills for consistency
    switch (rir) {
      case 0:
      case 1:
        return const Color(0xFFFFFFFF); // White text on red/orange
      case 2:
        return const Color(0xFF18181B); // Dark text on yellow (better contrast)
      default:
        return const Color(0xFFFFFFFF); // White text on green
    }
  }

  /// Get RIR label text (user-friendly format)
  static String getRirLabel(int rir) {
    switch (rir) {
      case 0:
        return 'MAX · RIR 0';
      case 1:
        return '1 in tank · RIR 1';
      case 2:
        return '2 in tank · RIR 2';
      case 3:
        return '3 in tank · RIR 3';
      default:
        return '${rir}+ in tank · RIR $rir';
    }
  }

  /// Check if theme is dark
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  /// Get appropriate color for current theme
  static Color adaptive(BuildContext context, Color dark, Color light) {
    return isDarkMode(context) ? dark : light;
  }
}

/// Extension for easy access to workout colors in widgets
extension WorkoutDesignContext on BuildContext {
  /// Get workout design colors adapted to current theme
  WorkoutDesignTheme get workoutDesign {
    final isDark = Theme.of(this).brightness == Brightness.dark;
    return WorkoutDesignTheme(isDark: isDark);
  }
}

/// Theme-aware workout design colors
class WorkoutDesignTheme {
  final bool isDark;

  const WorkoutDesignTheme({required this.isDark});

  Color get background =>
      isDark ? WorkoutDesign.background : WorkoutDesign.backgroundLight;
  Color get surface =>
      isDark ? WorkoutDesign.surface : WorkoutDesign.surfaceLight;
  Color get inputField =>
      isDark ? WorkoutDesign.inputField : WorkoutDesign.inputFieldLight;
  Color get border => isDark ? WorkoutDesign.border : WorkoutDesign.borderLight;
  Color get textPrimary =>
      isDark ? WorkoutDesign.textPrimary : WorkoutDesign.textPrimaryLight;
  Color get textSecondary =>
      isDark ? WorkoutDesign.textSecondary : WorkoutDesign.textSecondaryLight;
}
