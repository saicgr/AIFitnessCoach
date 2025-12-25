import 'package:flutter/material.dart';

/// App color palette - OLED-optimized dark theme
class AppColors {
  AppColors._();

  // Brand Colors
  static const Color cyan = Color(0xFF06B6D4);
  static const Color cyanDark = Color(0xFF0891B2);
  static const Color electricBlue = Color(0xFF3B82F6);
  static const Color teal = Color(0xFF14B8A6);

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

  // Workout Type Colors
  static const Color strength = Color(0xFF6366F1);
  static const Color cardio = Color(0xFFEF4444);
  static const Color flexibility = Color(0xFF14B8A6);
  static const Color hiit = Color(0xFFEC4899);

  // Accent Colors
  static const Color orange = Color(0xFFF97316);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color coral = Color(0xFFF43F5E);
  static const Color magenta = Color(0xFFEC4899);
  static const Color limeGreen = Color(0xFFD4FF00);
  static const Color green = Color(0xFF22C55E);
  static const Color yellow = Color(0xFFFACC15);
  static const Color red = Color(0xFFEF4444);
  static const Color pink = Color(0xFFEC4899);

  // Surface colors
  static const Color surface = Color(0xFF121212);
  static const Color background = Color(0xFF000000);

  // Semantic Colors
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Gradients
  static const LinearGradient cyanGradient = LinearGradient(
    colors: [cyan, cyanDark],
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

  /// Get color for workout type
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

  /// Get color for difficulty
  static Color getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
      case 'beginner':
        return success;
      case 'medium':
      case 'intermediate':
        return warning;
      case 'hard':
      case 'advanced':
        return error;
      default:
        return textSecondary;
    }
  }
}

/// Light theme colors
class AppColorsLight {
  AppColorsLight._();

  // Brand Colors (same as dark)
  static const Color cyan = Color(0xFF0891B2);
  static const Color cyanDark = Color(0xFF0E7490);
  static const Color electricBlue = Color(0xFF2563EB);
  static const Color teal = Color(0xFF0D9488);

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

  // Workout Type Colors (same as dark)
  static const Color strength = Color(0xFF6366F1);
  static const Color cardio = Color(0xFFEF4444);
  static const Color flexibility = Color(0xFF14B8A6);
  static const Color hiit = Color(0xFFEC4899);

  // Accent Colors (same as dark)
  static const Color orange = Color(0xFFF97316);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color coral = Color(0xFFF43F5E);
  static const Color magenta = Color(0xFFEC4899);

  // Semantic Colors
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF2563EB);
}
