import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Haptic feedback intensity levels
enum HapticLevel {
  off,
  light,
  medium,
  strong,
}

/// Extension to get display names for haptic levels
extension HapticLevelExtension on HapticLevel {
  String get displayName {
    switch (this) {
      case HapticLevel.off:
        return 'Off';
      case HapticLevel.light:
        return 'Light';
      case HapticLevel.medium:
        return 'Medium';
      case HapticLevel.strong:
        return 'Strong';
    }
  }

  String get description {
    switch (this) {
      case HapticLevel.off:
        return 'No haptic feedback';
      case HapticLevel.light:
        return 'Subtle vibrations';
      case HapticLevel.medium:
        return 'Balanced feedback';
      case HapticLevel.strong:
        return 'Maximum intensity';
    }
  }
}

/// Global haptic service for consistent feedback throughout the app
class HapticService {
  static const String _prefsKey = 'haptic_level';
  static HapticLevel _currentLevel = HapticLevel.medium;

  /// Initialize the service and load saved preference
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLevel = prefs.getInt(_prefsKey);
    if (savedLevel != null && savedLevel < HapticLevel.values.length) {
      _currentLevel = HapticLevel.values[savedLevel];
    }
  }

  /// Get current haptic level
  static HapticLevel get level => _currentLevel;

  /// Set haptic level and persist
  static Future<void> setLevel(HapticLevel level) async {
    _currentLevel = level;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKey, level.index);
    // Provide feedback for the new level
    if (level != HapticLevel.off) {
      selection();
    }
  }

  /// Light impact - for selections, toggles, subtle feedback
  static void light() {
    if (_currentLevel == HapticLevel.off) return;
    HapticFeedback.lightImpact();
  }

  /// Medium impact - for confirmations, button presses
  static void medium() {
    if (_currentLevel == HapticLevel.off) return;
    switch (_currentLevel) {
      case HapticLevel.light:
        HapticFeedback.lightImpact();
        break;
      case HapticLevel.medium:
      case HapticLevel.strong:
        HapticFeedback.mediumImpact();
        break;
      default:
        break;
    }
  }

  /// Heavy impact - for important actions, completions
  static void heavy() {
    if (_currentLevel == HapticLevel.off) return;
    switch (_currentLevel) {
      case HapticLevel.light:
        HapticFeedback.lightImpact();
        break;
      case HapticLevel.medium:
        HapticFeedback.mediumImpact();
        break;
      case HapticLevel.strong:
        HapticFeedback.heavyImpact();
        break;
      default:
        break;
    }
  }

  /// Selection click - for list selections, tab changes
  static void selection() {
    if (_currentLevel == HapticLevel.off) return;
    HapticFeedback.selectionClick();
  }

  /// Success pattern - for completing tasks, achievements
  static void success() {
    if (_currentLevel == HapticLevel.off) return;
    switch (_currentLevel) {
      case HapticLevel.light:
        HapticFeedback.lightImpact();
        break;
      case HapticLevel.medium:
        HapticFeedback.mediumImpact();
        Future.delayed(const Duration(milliseconds: 80), () {
          HapticFeedback.lightImpact();
        });
        break;
      case HapticLevel.strong:
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 60), () {
          HapticFeedback.mediumImpact();
        });
        Future.delayed(const Duration(milliseconds: 120), () {
          HapticFeedback.lightImpact();
        });
        break;
      default:
        break;
    }
  }

  /// Error/Warning pattern - for errors, warnings
  static void error() {
    if (_currentLevel == HapticLevel.off) return;
    switch (_currentLevel) {
      case HapticLevel.light:
        HapticFeedback.lightImpact();
        break;
      case HapticLevel.medium:
      case HapticLevel.strong:
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 100), () {
          HapticFeedback.heavyImpact();
        });
        break;
      default:
        break;
    }
  }

  /// Notification pattern - for alerts, notifications
  static void notification() {
    if (_currentLevel == HapticLevel.off) return;
    HapticFeedback.mediumImpact();
    Future.delayed(const Duration(milliseconds: 150), () {
      HapticFeedback.lightImpact();
    });
  }

  /// Button press down - for press states
  static void buttonDown() {
    if (_currentLevel == HapticLevel.off) return;
    if (_currentLevel == HapticLevel.strong) {
      HapticFeedback.selectionClick();
    }
  }

  /// Swipe threshold reached - for dismissible actions
  static void swipeThreshold() {
    if (_currentLevel == HapticLevel.off) return;
    HapticFeedback.mediumImpact();
  }

  /// Scroll snap - for page views, carousels
  static void scrollSnap() {
    if (_currentLevel == HapticLevel.off) return;
    if (_currentLevel != HapticLevel.light) {
      HapticFeedback.selectionClick();
    }
  }

  /// Increment/Decrement - for +/- buttons
  static void increment() {
    if (_currentLevel == HapticLevel.off) return;
    switch (_currentLevel) {
      case HapticLevel.light:
        HapticFeedback.selectionClick();
        break;
      case HapticLevel.medium:
      case HapticLevel.strong:
        HapticFeedback.mediumImpact();
        break;
      default:
        break;
    }
  }
}

/// Riverpod provider for haptic level state
final hapticLevelProvider = StateNotifierProvider<HapticLevelNotifier, HapticLevel>((ref) {
  return HapticLevelNotifier();
});

class HapticLevelNotifier extends StateNotifier<HapticLevel> {
  HapticLevelNotifier() : super(HapticService.level);

  Future<void> setLevel(HapticLevel level) async {
    await HapticService.setLevel(level);
    state = level;
  }
}
