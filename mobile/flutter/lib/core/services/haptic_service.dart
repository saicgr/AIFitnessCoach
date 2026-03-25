import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// Centralized haptic feedback service with calibrated intensity levels.
///
/// Provides named methods for different interaction contexts:
/// - [tick] — Picker scrolls, slider snaps
/// - [tap] — Button presses, toggles, checkboxes
/// - [impact] — Card expansion, sheet open, navigation
/// - [success] — Workout complete, streak increment
/// - [error] — Validation fail, API error
/// - [timerDone] — Rest timer countdown complete
/// - [heavyImpact] — Set complete, PR achieved, level up
///
/// Respects device accessibility settings (reduce motion).
class HapticService {
  HapticService._();
  static final HapticService instance = HapticService._();

  bool _enabled = true;
  bool? _hasVibrator;

  /// Disable haptics globally (e.g., when accessibility reduce-motion is on).
  void setEnabled(bool enabled) => _enabled = enabled;

  Future<bool> _canVibrate() async {
    _hasVibrator ??= (await Vibration.hasVibrator()) == true;
    return _enabled && _hasVibrator!;
  }

  /// Light selection tick — picker wheels, slider notch snaps.
  Future<void> tick() async {
    if (!_enabled) return;
    await HapticFeedback.selectionClick();
  }

  /// Light tap — button press, toggle, checkbox.
  Future<void> tap() async {
    if (!_enabled) return;
    await HapticFeedback.lightImpact();
  }

  /// Medium impact — card expansion, sheet open, navigation transition.
  Future<void> impact() async {
    if (!_enabled) return;
    await HapticFeedback.mediumImpact();
  }

  /// Heavy impact — set complete, PR achieved, level up.
  Future<void> heavyImpact() async {
    if (!_enabled) return;
    await HapticFeedback.heavyImpact();
  }

  /// Success pattern — workout complete, streak increment.
  /// Two quick light taps with a short gap.
  Future<void> success() async {
    if (!await _canVibrate()) return;
    await Vibration.vibrate(pattern: [0, 40, 80, 40], intensities: [0, 180, 0, 120]);
  }

  /// Error buzz — validation fail, API error.
  /// Three rapid taps for a "nope" feel.
  Future<void> error() async {
    if (!await _canVibrate()) return;
    await Vibration.vibrate(pattern: [0, 30, 50, 30, 50, 30], intensities: [0, 200, 0, 200, 0, 200]);
  }

  /// Timer done — rest timer hit zero.
  /// Double heavy tap with deliberate pause.
  Future<void> timerDone() async {
    if (!_enabled) return;
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    if (!_enabled) return;
    await HapticFeedback.heavyImpact();
  }

  /// Countdown tick — rest timer last 5 seconds.
  /// Gets progressively stronger as time decreases.
  Future<void> countdownTick(int secondsRemaining) async {
    if (!_enabled) return;
    if (secondsRemaining > 3) {
      await HapticFeedback.selectionClick();
    } else if (secondsRemaining > 1) {
      await HapticFeedback.lightImpact();
    } else {
      await HapticFeedback.mediumImpact();
    }
  }

  /// Celebration — layered haptic for major achievements.
  /// Heavy impact followed by a success pattern.
  Future<void> celebration() async {
    if (!_enabled) return;
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 150));
    await success();
  }

  /// Log haptic events in debug mode.
  @visibleForTesting
  static void debugLog(String event) {
    if (kDebugMode) {
      print('🎯 [HapticService] $event');
    }
  }
}
