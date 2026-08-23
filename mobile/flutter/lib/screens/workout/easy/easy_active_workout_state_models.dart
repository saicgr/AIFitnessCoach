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
/// Easy doesn't surface progression patterns, bar type, L/R mode, or
/// drop sets — so none of those live here. Those are Advanced-only.
class EasyExerciseState {
  final List<SetLog> completed;
  double displayWeight; // value shown in the weight stepper (user's unit)
  int reps;
  int targetReps;

  /// Reps-in-reserve for the set about to be logged, chosen via the compact
  /// [FeltPicker] (Easy/Good/Hard/V.Hard). Null when the user hasn't tapped a
  /// bucket yet — logged as-is (no RIR) rather than a fabricated value.
  /// Sticky across sets like [displayWeight]/[reps] so an unchanged effort
  /// doesn't need re-tapping every set (E2E #168 — Easy previously had no
  /// path to persist RIR/RPE at all).
  int? rir;
  double targetWeightKg; // always kg; converted for display only
  int totalSets;

  /// Set true once the user manually edits the weight, so the async
  /// smart-weight preload never clobbers an in-flight edit (it only guards on
  /// "no set logged yet", which isn't enough — the edit can precede the log).
  bool userEditedWeight;

  /// True when the exercise is measured by hold time (planks, wall sits,
  /// dead-hangs) rather than reps. Drives the focal column to render a
  /// seconds stepper instead of weight + reps.
  final bool isTimed;

  /// User-entered hold target for the current set, in seconds. Only
  /// meaningful when [isTimed] is true. Persists into `SetLog.durationSeconds`.
  int durationSeconds;

  /// True for distance/cardio moves (SkiErg, sled, carries, runs). Drives the
  /// focal column to render a distance (meters) stepper instead of weight×reps.
  final bool isDistance;

  /// True when the move carries NO external load by classification — a
  /// bodyweight rep move (push-up, air squat, burpee). Seeded from the same
  /// `TrackingMetric` decision that zeroes the target load, so the focal
  /// column can say "bodyweight" in words instead of rendering the jargon
  /// token "BW" beside a weight field showing 0 (which reads as broken).
  /// A weighted move the user simply hasn't loaded yet is NOT bodyweight.
  final bool isBodyweight;

  /// User-entered distance for the current set, in METERS. Only meaningful
  /// when [isDistance] is true. Persists into `SetLog.distanceMeters`.
  double distanceMeters;

  /// EXTRA metric columns this exercise tracks BEYOND the four standard ones
  /// (weight / reps / distance / time) already owned by the poster + load/reps
  /// steppers — e.g. box_height, calories, or any user-custom key. Recomputed
  /// each build from the classifier profile unioned with the user's saved
  /// per-exercise prefs (`exerciseMetricPrefsProvider`), so a freshly added
  /// column appears immediately. Drives the dynamic stepper stack.
  List<String> extraMetricKeys;

  /// Live values for the current set's extra metrics, keyed by metric KEY (NOT
  /// bagKey). Snapshotted (KEY→bagKey) into `SetLog.extraMetrics` when the set
  /// logs. Sticky across sets like [displayWeight] — not cleared on log.
  Map<String, num> extraMetrics;

  EasyExerciseState({
    required this.displayWeight,
    required this.reps,
    required this.targetReps,
    required this.targetWeightKg,
    required this.totalSets,
    this.isTimed = false,
    this.durationSeconds = 30,
    this.isDistance = false,
    this.distanceMeters = 0,
    this.isBodyweight = false,
    this.userEditedWeight = false,
    List<String>? extraMetricKeys,
    Map<String, num>? extraMetrics,
    List<SetLog>? completed,
  })  : extraMetricKeys = extraMetricKeys ?? <String>[],
        extraMetrics = extraMetrics ?? <String, num>{},
        completed = completed ?? <SetLog>[];

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
