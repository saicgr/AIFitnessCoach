/// Timer controller for workout timing
///
/// Handles workout timer, rest timer, warmup timer, and stretch timer logic.
library;

import 'dart:async';

import 'package:flutter/services.dart';

/// Callback types for timer events
typedef OnTimerTick = void Function(int secondsRemaining);
typedef OnTimerComplete = void Function();

/// Controller for managing workout timers
class WorkoutTimerController {
  Timer? _workoutTimer;
  Timer? _restTimer;

  int _workoutSeconds = 0;
  int _restSecondsRemaining = 0;
  int _initialRestDuration = 0;
  bool _isPaused = false;

  /// Current workout time in seconds
  int get workoutSeconds => _workoutSeconds;

  /// Current rest time remaining in seconds
  int get restSecondsRemaining => _restSecondsRemaining;

  /// Initial rest duration for progress calculation
  int get initialRestDuration => _initialRestDuration;

  /// Whether the timer is paused
  bool get isPaused => _isPaused;

  /// Rest progress (1.0 = full, 0.0 = done)
  double get restProgress =>
      _initialRestDuration > 0 ? _restSecondsRemaining / _initialRestDuration : 0.0;

  /// Callback for workout timer ticks
  OnTimerTick? onWorkoutTick;

  /// Callback for rest timer ticks
  OnTimerTick? onRestTick;

  /// Callback when rest timer completes
  OnTimerComplete? onRestComplete;

  /// Start the main workout timer
  void startWorkoutTimer() {
    _workoutTimer?.cancel();
    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        _workoutSeconds++;
        onWorkoutTick?.call(_workoutSeconds);
      }
    });
  }

  /// Start the rest timer
  void startRestTimer(int seconds) {
    _restSecondsRemaining = seconds;
    _initialRestDuration = seconds;

    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused && _restSecondsRemaining > 0) {
        _restSecondsRemaining--;
        onRestTick?.call(_restSecondsRemaining);

        // Haptic countdown warnings
        if (_restSecondsRemaining == 5) {
          HapticFeedback.lightImpact();
        } else if (_restSecondsRemaining <= 3 && _restSecondsRemaining > 0) {
          HapticFeedback.mediumImpact();
        }

        if (_restSecondsRemaining == 0) {
          _endRest();
        }
      }
    });

    HapticFeedback.mediumImpact();
  }

  void _endRest() {
    _restTimer?.cancel();
    _restSecondsRemaining = 0;

    // Strong haptic feedback pattern when rest ends
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 100), () {
      HapticFeedback.mediumImpact();
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      HapticFeedback.mediumImpact();
    });

    onRestComplete?.call();
  }

  /// Skip the rest timer
  void skipRest() {
    _endRest();
  }

  /// Toggle pause state
  void togglePause() {
    _isPaused = !_isPaused;
    HapticFeedback.selectionClick();
  }

  /// Set pause state
  void setPaused(bool paused) {
    _isPaused = paused;
  }

  /// Stop the workout timer (call when workout completes)
  void stopWorkoutTimer() {
    _workoutTimer?.cancel();
    _workoutTimer = null;
  }

  /// Cancel all timers and dispose
  void dispose() {
    _workoutTimer?.cancel();
    _restTimer?.cancel();
    _workoutTimer = null;
    _restTimer = null;
  }

  /// Format seconds to MM:SS string
  static String formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

/// Controller for phase timers (warmup/stretch)
class PhaseTimerController {
  Timer? _timer;
  int _secondsRemaining = 0;
  bool _isRunning = false;

  /// Current seconds remaining
  int get secondsRemaining => _secondsRemaining;

  /// Whether the timer is running
  bool get isRunning => _isRunning;

  /// Callback for timer ticks
  OnTimerTick? onTick;

  /// Callback when timer completes
  OnTimerComplete? onComplete;

  /// Start the timer with given duration
  void start(int duration) {
    _secondsRemaining = duration;
    _isRunning = true;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        _secondsRemaining--;
        onTick?.call(_secondsRemaining);

        // Haptic feedback at key moments
        if (_secondsRemaining <= 3 && _secondsRemaining > 0) {
          HapticFeedback.lightImpact();
        }
      } else {
        stop();
        onComplete?.call();
      }
    });
  }

  /// Pause the timer
  void pause() {
    _timer?.cancel();
    _isRunning = false;
  }

  /// Resume the timer
  void resume() {
    if (_secondsRemaining > 0) {
      _isRunning = true;
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
          onTick?.call(_secondsRemaining);
        } else {
          stop();
          onComplete?.call();
        }
      });
    }
  }

  /// Stop the timer
  void stop() {
    _timer?.cancel();
    _isRunning = false;
  }

  /// Reset the timer
  void reset() {
    _timer?.cancel();
    _secondsRemaining = 0;
    _isRunning = false;
  }

  /// Dispose the timer
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
