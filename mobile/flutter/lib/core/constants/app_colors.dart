import 'package:flutter/material.dart';

/// App color palette - Professional monochrome theme
class AppColors {
  AppColors._();

  // Brand Colors - Monochrome
  static const Color cyan = Color(0xFFE0E0E0); // Light gray accent
  static const Color cyanDark = Color(0xFFBDBDBD);
  static const Color electricBlue = Color(0xFFB0B0B0);
  static const Color teal = Color(0xFFC0C0C0);

  // Dark Theme (OLED Optimized)
  static const Color pureBlack = Color(0xFF000000);
  static const Color nearBlack = Color(0xFF0A0A0A);
  static const Color elevated = Color(0xFF141414);
  static const Color glassSurface = Color(0xFF1A1A1A);
  static const Color cardBorder = Color(0xFF262626);

  // Text Colors
  static const Color textPrimary = Color(0xFFFAFAFA);
  static const Color textSecondary = Color(0xFFA1A1AA);
  static const Color textMuted = Color(0xFF71717A);

  // Monochrome Accent - For buttons, selected states, borders
  // White in dark mode for high contrast
  static const Color accent = Color(0xFFFFFFFF);
  static const Color accentContrast = Color(0xFF000000); // Text on accent buttons

  // Workout Type Colors - Monochrome grayscale
  static const Color strength = Color(0xFFE0E0E0);
  static const Color cardio = Color(0xFFD0D0D0);
  static const Color flexibility = Color(0xFFC0C0C0);
  static const Color hiit = Color(0xFFB0B0B0);

  // Accent Colors - Monochrome (white/gray tones)
  static const Color orange = Color(0xFFE0E0E0);
  static const Color purple = Color(0xFFD0D0D0);
  static const Color coral = Color(0xFFC0C0C0);
  static const Color magenta = Color(0xFFB0B0B0);
  static const Color limeGreen = Color(0xFFFAFAFA);
  static const Color green = Color(0xFFE0E0E0);
  static const Color yellow = Color(0xFFE8E8E8);
  static const Color red = Color(0xFFD0D0D0);
  static const Color pink = Color(0xFFC0C0C0);

  // Surface colors
  static const Color surface = Color(0xFF121212);
  static const Color background = Color(0xFF000000);

  // Semantic Colors - Keep subtle distinction
  static const Color success = Color(0xFFE0E0E0);
  static const Color warning = Color(0xFFD0D0D0);
  static const Color error = Color(0xFFC0C0C0);
  static const Color info = Color(0xFFB0B0B0);

  // ═══════════════════════════════════════════════════════════════
  // RIR (Reps in Reserve) Badge Colors - Monochrome
  // ═══════════════════════════════════════════════════════════════
  static const Color rir1 = Color(0xFFFFFFFF); // White - 1 RIR (hardest)
  static const Color rir2 = Color(0xFFE0E0E0); // Light gray - 2 RIR
  static const Color rir3 = Color(0xFFC0C0C0); // Medium gray - 3 RIR
  static const Color rir4 = Color(0xFFA0A0A0); // Dark gray - 4+ RIR (easiest)

  // AI/Smart Progression Accent
  static const Color aiAccent = Color(0xFFFFFFFF); // White for AI features

  /// Get RIR badge color based on RIR value
  static Color getRirColor(int rir) {
    switch (rir) {
      case 1:
        return rir1;
      case 2:
        return rir2;
      case 3:
        return rir3;
      default:
        return rir4;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // Glow Colors - Monochrome (subtle white glows)
  // ═══════════════════════════════════════════════════════════════

  // Subtle white/gray glows
  static const Color glowCyan = Color(0xFFFFFFFF);
  static const Color glowPurple = Color(0xFFE0E0E0);
  static const Color glowGreen = Color(0xFFFAFAFA);
  static const Color glowOrange = Color(0xFFE8E8E8);

  // Glassmorphic backgrounds
  static const Color glassDark = Color(0x40000000); // 25% black
  static const Color glassBorder = Color(0x20FFFFFF); // 12% white
  static const Color glassHighlight = Color(0x10FFFFFF); // 6% white

  // Gradients - Monochrome
  static const LinearGradient cyanGradient = LinearGradient(
    colors: [Color(0xFFE0E0E0), Color(0xFFBDBDBD)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [
      Color(0x1AFFFFFF),
      Color(0x0DFFFFFF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Monochrome gradients
  static const LinearGradient glowCyanGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFE0E0E0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glowSuccessGradient = LinearGradient(
    colors: [Color(0xFFFAFAFA), Color(0xFFE0E0E0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glowPurpleGradient = LinearGradient(
    colors: [Color(0xFFE0E0E0), Color(0xFFD0D0D0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Accent gradient for buttons and selections (monochrome - white to light gray in dark mode)
  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFE8E8E8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Get color for workout type - all return monochrome
  static Color getWorkoutTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'strength':
        return strength;
      case 'cardio':
        return cardio;
      case 'flexibility':
      case 'stretching':
        return flexibility;
      case 'hiit':
        return hiit;
      default:
        return cyan;
    }
  }

  /// Get color for difficulty - monochrome with subtle variation
  static Color getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
      case 'beginner':
        return const Color(0xFFA0A0A0);
      case 'medium':
      case 'intermediate':
        return const Color(0xFFC0C0C0);
      case 'hard':
      case 'advanced':
        return const Color(0xFFE0E0E0);
      case 'hell':
        return const Color(0xFFFFFFFF);
      default:
        return textSecondary;
    }
  }
}

/// Light theme colors - Professional monochrome
class AppColorsLight {
  AppColorsLight._();

  // Brand Colors - Monochrome (darker for light theme)
  static const Color cyan = Color(0xFF424242);
  static const Color cyanDark = Color(0xFF303030);
  static const Color electricBlue = Color(0xFF505050);
  static const Color teal = Color(0xFF404040);

  // Light Theme Colors
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color nearWhite = Color(0xFFFAFAFA);
  static const Color elevated = Color(0xFFF4F4F5);
  static const Color glassSurface = Color(0xFFF8F8FA);
  static const Color cardBorder = Color(0xFFE4E4E7);
  static const Color surface = Color(0xFFF9FAFB);
  static const Color background = Color(0xFFFFFFFF);

  // Text Colors
  static const Color textPrimary = Color(0xFF18181B);
  static const Color textSecondary = Color(0xFF52525B);
  static const Color textMuted = Color(0xFF71717A);

  // Monochrome Accent - For buttons, selected states, borders
  // Black in light mode for high contrast
  static const Color accent = Color(0xFF000000);
  static const Color accentContrast = Color(0xFFFFFFFF); // Text on accent buttons

  // Accent gradient for buttons and selections (monochrome - black to dark gray in light mode)
  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF000000), Color(0xFF303030)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Workout Type Colors - Monochrome (dark grays for light theme)
  static const Color strength = Color(0xFF424242);
  static const Color cardio = Color(0xFF505050);
  static const Color flexibility = Color(0xFF606060);
  static const Color hiit = Color(0xFF707070);

  // Accent Colors - Monochrome (black/dark gray tones)
  static const Color orange = Color(0xFF424242);
  static const Color purple = Color(0xFF505050);
  static const Color coral = Color(0xFF606060);
  static const Color magenta = Color(0xFF707070);
  static const Color green = Color(0xFF303030);

  // Semantic Colors - Keep subtle distinction
  static const Color success = Color(0xFF303030);
  static const Color warning = Color(0xFF424242);
  static const Color error = Color(0xFF505050);
  static const Color info = Color(0xFF606060);
}
