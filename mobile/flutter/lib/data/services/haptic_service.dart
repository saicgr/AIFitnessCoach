import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

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

  // Android vibrator capabilities
  static bool _hasVibrator = false;
  static bool _hasAmplitudeControl = false;

  /// Initialize the service and load saved preference
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLevel = prefs.getInt(_prefsKey);
    if (savedLevel != null && savedLevel < HapticLevel.values.length) {
      _currentLevel = HapticLevel.values[savedLevel];
    }

    if (Platform.isAndroid) {
      _hasVibrator = await Vibration.hasVibrator();
      _hasAmplitudeControl = await Vibration.hasAmplitudeControl();
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

  /// Android vibration via Vibrator service (bypasses system haptic setting)
  static void _androidVibrate({int duration = 20, int amplitude = -1}) {
    if (!_hasVibrator) return;
    if (_hasAmplitudeControl && amplitude > 0) {
      Vibration.vibrate(duration: duration, amplitude: amplitude);
    } else {
      Vibration.vibrate(duration: duration);
    }
  }

  /// Light impact - for selections, toggles, subtle feedback
  static void light() {
    if (_currentLevel == HapticLevel.off) return;
    if (Platform.isAndroid) {
      _androidVibrate(duration: 15, amplitude: 40);
    } else {
      HapticFeedback.lightImpact();
    }
  }

  /// Medium impact - for confirmations, button presses
  static void medium() {
    if (_currentLevel == HapticLevel.off) return;
    if (Platform.isAndroid) {
      switch (_currentLevel) {
        case HapticLevel.light:
          _androidVibrate(duration: 15, amplitude: 40);
          break;
        case HapticLevel.medium:
        case HapticLevel.strong:
          _androidVibrate(duration: 25, amplitude: 120);
          break;
        default:
          break;
      }
    } else {
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
  }

  /// Heavy impact - for important actions, completions
  static void heavy() {
    if (_currentLevel == HapticLevel.off) return;
    if (Platform.isAndroid) {
      switch (_currentLevel) {
        case HapticLevel.light:
          _androidVibrate(duration: 15, amplitude: 40);
          break;
        case HapticLevel.medium:
          _androidVibrate(duration: 25, amplitude: 120);
          break;
        case HapticLevel.strong:
          _androidVibrate(duration: 35, amplitude: 255);
          break;
        default:
          break;
      }
    } else {
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
  }

  /// Selection click - for list selections, tab changes
  static void selection() {
    if (_currentLevel == HapticLevel.off) return;
    if (Platform.isAndroid) {
      _androidVibrate(duration: 10, amplitude: 30);
    } else {
      HapticFeedback.selectionClick();
    }
  }

  /// Success pattern - for completing tasks, achievements
  static void success() {
    if (_currentLevel == HapticLevel.off) return;
    if (Platform.isAndroid) {
      switch (_currentLevel) {
        case HapticLevel.light:
          _androidVibrate(duration: 15, amplitude: 40);
          break;
        case HapticLevel.medium:
          _androidVibrate(duration: 25, amplitude: 120);
          Future.delayed(const Duration(milliseconds: 80), () {
            _androidVibrate(duration: 15, amplitude: 40);
          });
          break;
        case HapticLevel.strong:
          _androidVibrate(duration: 35, amplitude: 255);
          Future.delayed(const Duration(milliseconds: 60), () {
            _androidVibrate(duration: 25, amplitude: 120);
          });
          Future.delayed(const Duration(milliseconds: 120), () {
            _androidVibrate(duration: 15, amplitude: 40);
          });
          break;
        default:
          break;
      }
    } else {
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
  }

  /// Error/Warning pattern - for errors, warnings
  static void error() {
    if (_currentLevel == HapticLevel.off) return;
    if (Platform.isAndroid) {
      switch (_currentLevel) {
        case HapticLevel.light:
          _androidVibrate(duration: 15, amplitude: 40);
          break;
        case HapticLevel.medium:
        case HapticLevel.strong:
          _androidVibrate(duration: 35, amplitude: 255);
          Future.delayed(const Duration(milliseconds: 100), () {
            _androidVibrate(duration: 35, amplitude: 255);
          });
          break;
        default:
          break;
      }
    } else {
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
  }

  /// Notification pattern - for alerts, notifications
  static void notification() {
    if (_currentLevel == HapticLevel.off) return;
    if (Platform.isAndroid) {
      _androidVibrate(duration: 25, amplitude: 120);
      Future.delayed(const Duration(milliseconds: 150), () {
        _androidVibrate(duration: 15, amplitude: 40);
      });
    } else {
      HapticFeedback.mediumImpact();
      Future.delayed(const Duration(milliseconds: 150), () {
        HapticFeedback.lightImpact();
      });
    }
  }

  /// Button press down - for press states
  static void buttonDown() {
    if (_currentLevel == HapticLevel.off) return;
    if (_currentLevel == HapticLevel.strong) {
      if (Platform.isAndroid) {
        _androidVibrate(duration: 10, amplitude: 30);
      } else {
        HapticFeedback.selectionClick();
      }
    }
  }

  /// Swipe threshold reached - for dismissible actions
  static void swipeThreshold() {
    if (_currentLevel == HapticLevel.off) return;
    if (Platform.isAndroid) {
      _androidVibrate(duration: 25, amplitude: 120);
    } else {
      HapticFeedback.mediumImpact();
    }
  }

  /// Scroll snap - for page views, carousels
  static void scrollSnap() {
    if (_currentLevel == HapticLevel.off) return;
    if (_currentLevel != HapticLevel.light) {
      if (Platform.isAndroid) {
        _androidVibrate(duration: 10, amplitude: 30);
      } else {
        HapticFeedback.selectionClick();
      }
    }
  }

  /// Increment/Decrement - for +/- buttons
  static void increment() {
    if (_currentLevel == HapticLevel.off) return;
    if (Platform.isAndroid) {
      switch (_currentLevel) {
        case HapticLevel.light:
          _androidVibrate(duration: 10, amplitude: 30);
          break;
        case HapticLevel.medium:
        case HapticLevel.strong:
          _androidVibrate(duration: 25, amplitude: 120);
          break;
        default:
          break;
      }
    } else {
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

  /// PR Achievement - Triumphant cascade for personal records
  static void prAchievement() {
    if (_currentLevel == HapticLevel.off) return;
    if (Platform.isAndroid) {
      _androidVibrate(duration: 35, amplitude: 255);
      Future.delayed(const Duration(milliseconds: 80), () {
        _androidVibrate(duration: 35, amplitude: 255);
      });
      Future.delayed(const Duration(milliseconds: 160), () {
        _androidVibrate(duration: 25, amplitude: 120);
      });
      Future.delayed(const Duration(milliseconds: 220), () {
        _androidVibrate(duration: 15, amplitude: 40);
      });
    } else {
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 80), () {
        HapticFeedback.heavyImpact();
      });
      Future.delayed(const Duration(milliseconds: 160), () {
        HapticFeedback.mediumImpact();
      });
      Future.delayed(const Duration(milliseconds: 220), () {
        HapticFeedback.lightImpact();
      });
    }
  }

  /// Multi-PR Achievement - "da-da-DUM" pattern for multiple PRs
  static void multiPrAchievement() {
    if (_currentLevel == HapticLevel.off) return;
    if (Platform.isAndroid) {
      _androidVibrate(duration: 25, amplitude: 120);
      Future.delayed(const Duration(milliseconds: 100), () {
        _androidVibrate(duration: 25, amplitude: 120);
      });
      Future.delayed(const Duration(milliseconds: 200), () {
        _androidVibrate(duration: 35, amplitude: 255);
      });
      Future.delayed(const Duration(milliseconds: 280), () {
        _androidVibrate(duration: 25, amplitude: 120);
      });
      Future.delayed(const Duration(milliseconds: 340), () {
        _androidVibrate(duration: 15, amplitude: 40);
      });
    } else {
      HapticFeedback.mediumImpact();
      Future.delayed(const Duration(milliseconds: 100), () {
        HapticFeedback.mediumImpact();
      });
      Future.delayed(const Duration(milliseconds: 200), () {
        HapticFeedback.heavyImpact();
      });
      Future.delayed(const Duration(milliseconds: 280), () {
        HapticFeedback.mediumImpact();
      });
      Future.delayed(const Duration(milliseconds: 340), () {
        HapticFeedback.lightImpact();
      });
    }
  }

  /// Rest timer tick - for countdown beats
  static void restTimerTick() {
    if (_currentLevel == HapticLevel.off) return;
    if (Platform.isAndroid) {
      _androidVibrate(duration: 10, amplitude: 30);
    } else {
      HapticFeedback.selectionClick();
    }
  }

  /// Rest timer complete - for when rest is over
  static void restTimerComplete() {
    if (_currentLevel == HapticLevel.off) return;
    if (Platform.isAndroid) {
      _androidVibrate(duration: 25, amplitude: 120);
      Future.delayed(const Duration(milliseconds: 100), () {
        _androidVibrate(duration: 15, amplitude: 40);
      });
    } else {
      HapticFeedback.mediumImpact();
      Future.delayed(const Duration(milliseconds: 100), () {
        HapticFeedback.lightImpact();
      });
    }
  }

  /// Set completion - for completing a set during workout
  static void setCompletion() {
    if (_currentLevel == HapticLevel.off) return;
    if (Platform.isAndroid) {
      switch (_currentLevel) {
        case HapticLevel.light:
          _androidVibrate(duration: 15, amplitude: 40);
          break;
        case HapticLevel.medium:
          _androidVibrate(duration: 25, amplitude: 120);
          Future.delayed(const Duration(milliseconds: 60), () {
            _androidVibrate(duration: 15, amplitude: 40);
          });
          break;
        case HapticLevel.strong:
          _androidVibrate(duration: 35, amplitude: 255);
          Future.delayed(const Duration(milliseconds: 50), () {
            _androidVibrate(duration: 25, amplitude: 120);
          });
          Future.delayed(const Duration(milliseconds: 100), () {
            _androidVibrate(duration: 15, amplitude: 40);
          });
          break;
        default:
          break;
      }
    } else {
      switch (_currentLevel) {
        case HapticLevel.light:
          HapticFeedback.lightImpact();
          break;
        case HapticLevel.medium:
          HapticFeedback.mediumImpact();
          Future.delayed(const Duration(milliseconds: 60), () {
            HapticFeedback.lightImpact();
          });
          break;
        case HapticLevel.strong:
          HapticFeedback.heavyImpact();
          Future.delayed(const Duration(milliseconds: 50), () {
            HapticFeedback.mediumImpact();
          });
          Future.delayed(const Duration(milliseconds: 100), () {
            HapticFeedback.lightImpact();
          });
          break;
        default:
          break;
      }
    }
  }

  /// Exercise transition - when moving to next exercise
  static void exerciseTransition() {
    if (_currentLevel == HapticLevel.off) return;
    if (Platform.isAndroid) {
      _androidVibrate(duration: 25, amplitude: 120);
      Future.delayed(const Duration(milliseconds: 120), () {
        _androidVibrate(duration: 15, amplitude: 40);
      });
    } else {
      HapticFeedback.mediumImpact();
      Future.delayed(const Duration(milliseconds: 120), () {
        HapticFeedback.lightImpact();
      });
    }
  }

  /// Workout complete - celebratory pattern for finishing workout
  static void workoutComplete() {
    if (_currentLevel == HapticLevel.off) return;
    if (Platform.isAndroid) {
      _androidVibrate(duration: 35, amplitude: 255);
      Future.delayed(const Duration(milliseconds: 150), () {
        _androidVibrate(duration: 35, amplitude: 255);
      });
      Future.delayed(const Duration(milliseconds: 300), () {
        _androidVibrate(duration: 35, amplitude: 255);
      });
      Future.delayed(const Duration(milliseconds: 450), () {
        _androidVibrate(duration: 25, amplitude: 120);
      });
      Future.delayed(const Duration(milliseconds: 550), () {
        _androidVibrate(duration: 15, amplitude: 40);
      });
    } else {
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 150), () {
        HapticFeedback.heavyImpact();
      });
      Future.delayed(const Duration(milliseconds: 300), () {
        HapticFeedback.heavyImpact();
      });
      Future.delayed(const Duration(milliseconds: 450), () {
        HapticFeedback.mediumImpact();
      });
      Future.delayed(const Duration(milliseconds: 550), () {
        HapticFeedback.lightImpact();
      });
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
