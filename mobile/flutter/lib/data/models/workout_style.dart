import 'package:flutter/material.dart';

/// The high-level style of a mood-generated workout.
///
/// The user sees these as chips inside the mood picker's Advanced Options
/// panel. Each mood has a recommended style (from [MoodPreset]) that is
/// pre-selected; users can freely override.
enum WorkoutStyle {
  weights('weights', 'Weights', Icons.fitness_center),
  bodyweight('bodyweight', 'Bodyweight', Icons.accessibility_new),
  cardio('cardio', 'Cardio', Icons.directions_run),
  yogaStretch('yoga_stretch', 'Yoga & Stretch', Icons.self_improvement),
  mixed('mixed', 'Mixed', Icons.auto_awesome);

  const WorkoutStyle(this.value, this.label, this.icon);

  final String value;
  final String label;
  final IconData icon;

  /// Maps the style to a [QuickWorkoutEngine] focus value. Falls back to
  /// [fallbackFocus] for mood-driven picks (e.g. Motivated + Weights should
  /// rotate push/pull/legs by weekday — the caller supplies that context).
  String toFocus({String fallbackFocus = 'full_body'}) {
    switch (this) {
      case WorkoutStyle.weights:
        return fallbackFocus; // caller typically supplies push/pull/legs
      case WorkoutStyle.bodyweight:
        return fallbackFocus;
      case WorkoutStyle.cardio:
        return 'cardio';
      case WorkoutStyle.yogaStretch:
        return 'stretch';
      case WorkoutStyle.mixed:
        return fallbackFocus;
    }
  }

  /// Maps the style to a [QuickWorkoutEngine] goal value.
  String toGoal({String fallbackGoal = 'hypertrophy'}) {
    switch (this) {
      case WorkoutStyle.weights:
        return fallbackGoal;
      case WorkoutStyle.bodyweight:
        return 'endurance';
      case WorkoutStyle.cardio:
        return 'endurance';
      case WorkoutStyle.yogaStretch:
        return 'mobility';
      case WorkoutStyle.mixed:
        return fallbackGoal;
    }
  }

  /// Whether the style requires equipment beyond bodyweight.
  bool get requiresEquipment =>
      this == WorkoutStyle.weights; // cardio machines optional; yoga needs only mat

  static WorkoutStyle fromValue(String value) {
    return WorkoutStyle.values.firstWhere(
      (s) => s.value == value.toLowerCase(),
      orElse: () => WorkoutStyle.mixed,
    );
  }
}
