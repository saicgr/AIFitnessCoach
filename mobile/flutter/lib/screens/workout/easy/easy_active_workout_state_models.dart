// Easy-tier — pure data models extracted from easy_active_workout_state.dart
// to keep every file under the 300-line budget.
//
// Contains:
//   • EasyExerciseState   — per-exercise mutable state (weight/reps/completed)
//   • RestStreamBroadcaster — 1 Hz tick broadcaster consumed by the rest
//                             overlay
//
// No Widgets / BuildContext dependencies — safe to import anywhere.

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/workout_state.dart';

/// Small-screen threshold (iPhone SE class). Exposed as a shared const so
/// both the screen build and any golden tests agree.
const double kEasyCompactSafeAreaHeight = 640;

/// Per-exercise mutable state for the Easy screen. Intentionally narrow:
/// Easy doesn't surface RIR, progression patterns, bar type, L/R mode, or
/// drop sets — so none of those live here. Those are Advanced-only.
class EasyExerciseState {
  final List<SetLog> completed;
  double displayWeight; // value shown in the weight stepper (user's unit)
  int reps;
  int targetReps;
  double targetWeightKg; // always kg; converted for display only
  int totalSets;

  EasyExerciseState({
    required this.displayWeight,
    required this.reps,
    required this.targetReps,
    required this.targetWeightKg,
    required this.totalSets,
    List<SetLog>? completed,
  }) : completed = completed ?? <SetLog>[];

  int get completedCount => completed.length;
  bool get isFinished => completed.length >= totalSets;
}

/// Broadcasts remaining rest-seconds to the full-screen overlay. Backed by
/// a ValueNotifier so we can push ticks from `WorkoutTimerController` without
/// forcing a widget rebuild of the parent on every second.
class RestStreamBroadcaster {
  final ValueNotifier<int> _notifier;
  final _controller = StreamController<int>.broadcast();

  RestStreamBroadcaster(int initial) : _notifier = ValueNotifier(initial) {
    _notifier.addListener(_send);
  }

  void _send() => _controller.add(_notifier.value);
  Stream<int> get stream => _controller.stream;

  void push(int value) => _notifier.value = value;

  void dispose() {
    _notifier.removeListener(_send);
    _notifier.dispose();
    _controller.close();
  }
}
