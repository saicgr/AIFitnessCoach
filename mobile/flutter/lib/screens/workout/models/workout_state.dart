/// Workout state models for the active workout screen
///
/// These models encapsulate the state used during an active workout session.
library;

import 'package:flutter/material.dart';

/// Log for a single completed set
class SetLog {
  final int reps;
  final double weight;
  final DateTime completedAt;
  final String setType;
  final int? rpe; // Rate of Perceived Exertion (6-10)
  final int? rir; // Reps in Reserve (0-5)
  final int targetReps; // Original target reps for this set

  SetLog({
    required this.reps,
    required this.weight,
    DateTime? completedAt,
    this.setType = 'working',
    this.rpe,
    this.rir,
    this.targetReps = 0,
  }) : completedAt = completedAt ?? DateTime.now();

  SetLog copyWith({
    int? reps,
    double? weight,
    DateTime? completedAt,
    String? setType,
    int? rpe,
    int? rir,
    int? targetReps,
  }) {
    return SetLog(
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      completedAt: completedAt ?? this.completedAt,
      setType: setType ?? this.setType,
      rpe: rpe ?? this.rpe,
      rir: rir ?? this.rir,
      targetReps: targetReps ?? this.targetReps,
    );
  }
}

/// Enum for workout phase
enum WorkoutPhase {
  warmup,
  active,
  stretch,
  complete,
}

/// Standard warmup exercises data
class WarmupExerciseData {
  final String name;
  final int duration;
  final IconData icon;

  const WarmupExerciseData({
    required this.name,
    required this.duration,
    required this.icon,
  });
}

/// Standard stretch exercises data
class StretchExerciseData {
  final String name;
  final int duration;
  final IconData icon;

  const StretchExerciseData({
    required this.name,
    required this.duration,
    required this.icon,
  });
}

/// Default warmup exercises
const List<WarmupExerciseData> defaultWarmupExercises = [
  WarmupExerciseData(
    name: 'Jumping Jacks',
    duration: 60,
    icon: Icons.directions_run,
  ),
  WarmupExerciseData(
    name: 'Arm Circles',
    duration: 30,
    icon: Icons.loop,
  ),
  WarmupExerciseData(
    name: 'Hip Circles',
    duration: 30,
    icon: Icons.refresh,
  ),
  WarmupExerciseData(
    name: 'Leg Swings',
    duration: 30,
    icon: Icons.swap_horiz,
  ),
  WarmupExerciseData(
    name: 'Light Cardio',
    duration: 120,
    icon: Icons.favorite,
  ),
];

/// Default stretch exercises
const List<StretchExerciseData> defaultStretchExercises = [
  StretchExerciseData(
    name: 'Quad Stretch',
    duration: 30,
    icon: Icons.self_improvement,
  ),
  StretchExerciseData(
    name: 'Hamstring Stretch',
    duration: 30,
    icon: Icons.self_improvement,
  ),
  StretchExerciseData(
    name: 'Shoulder Stretch',
    duration: 30,
    icon: Icons.self_improvement,
  ),
  StretchExerciseData(
    name: 'Chest Opener',
    duration: 30,
    icon: Icons.self_improvement,
  ),
  StretchExerciseData(
    name: 'Cat-Cow Stretch',
    duration: 60,
    icon: Icons.self_improvement,
  ),
];

/// Rest interval tracking data
class RestInterval {
  final String? exerciseId;
  final String? exerciseName;
  final int? setNumber;
  final int restSeconds;
  final String restType;
  final DateTime recordedAt;

  RestInterval({
    this.exerciseId,
    this.exerciseName,
    this.setNumber,
    required this.restSeconds,
    required this.restType,
    DateTime? recordedAt,
  }) : recordedAt = recordedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'exercise_id': exerciseId,
        'exercise_name': exerciseName,
        'set_number': setNumber,
        'rest_seconds': restSeconds,
        'rest_type': restType,
        'recorded_at': recordedAt.toIso8601String(),
      };
}
