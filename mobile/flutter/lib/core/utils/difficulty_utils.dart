import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Utility class for difficulty-related display and formatting.
///
/// This class provides user-friendly display names and descriptions
/// for difficulty levels while maintaining backward compatibility
/// with internal values (easy, medium, hard, hell).
class DifficultyUtils {
  DifficultyUtils._();

  /// Internal difficulty values for backward compatibility
  static const List<String> internalValues = ['easy', 'medium', 'hard', 'hell'];

  /// User-friendly display names for each difficulty level
  static const Map<String, String> _displayNames = {
    'easy': 'Beginner',
    'medium': 'Moderate',
    'hard': 'Challenging',
    'hell': 'Hell',
  };

  /// Descriptions for each difficulty level (shown in tooltips)
  static const Map<String, String> _descriptions = {
    'easy': 'Perfect for starting out or recovery days',
    'medium': 'A balanced workout for consistent progress',
    'hard': 'Push your limits and build serious strength',
    'hell': 'Maximum intensity for experienced athletes',
  };

  /// Get the user-friendly display name for a difficulty level.
  ///
  /// [internal] - The internal difficulty value (e.g., 'easy', 'hell')
  /// Returns the friendly display name (e.g., 'Beginner', 'Elite')
  static String getDisplayName(String internal) {
    return _displayNames[internal.toLowerCase()] ??
           internal[0].toUpperCase() + internal.substring(1);
  }

  /// Get the description for a difficulty level.
  ///
  /// [internal] - The internal difficulty value
  /// Returns a helpful description of what that difficulty level means
  static String getDescription(String internal) {
    return _descriptions[internal.toLowerCase()] ?? '';
  }

  /// Get the color associated with a difficulty level.
  ///
  /// [internal] - The internal difficulty value
  /// [isDark] - Whether the app is in dark mode
  /// Returns the appropriate monochrome color for the difficulty
  static Color getColor(String internal, {bool isDark = true}) {
    // Use monochrome grayscale tones for difficulty levels
    switch (internal.toLowerCase()) {
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

  /// Get the icon for a difficulty level.
  ///
  /// [internal] - The internal difficulty value
  /// Returns the appropriate icon for the difficulty
  static IconData getIcon(String internal) {
    switch (internal.toLowerCase()) {
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

  /// Get internal value from display name.
  ///
  /// [displayName] - The friendly display name (e.g., 'Beginner')
  /// Returns the internal value (e.g., 'easy')
  static String getInternalValue(String displayName) {
    for (final entry in _displayNames.entries) {
      if (entry.value.toLowerCase() == displayName.toLowerCase()) {
        return entry.key;
      }
    }
    // Return as-is if not found (for backward compatibility)
    return displayName.toLowerCase();
  }

  /// Check if a difficulty level is considered high intensity.
  ///
  /// [internal] - The internal difficulty value
  /// Returns true if the difficulty is 'hard' or 'hell'
  static bool isHighIntensity(String internal) {
    final level = internal.toLowerCase();
    return level == 'hard' || level == 'hell';
  }
}
