/// Models for the today's workout quick start feature
library;

import 'exercise.dart';
import 'workout.dart';

/// Summary info for quick display on home screen
class TodayWorkoutSummary {
  final String id;
  final String name;
  final String type;
  final String difficulty;
  final int durationMinutes;
  final int? durationMinutesMin;
  final int? durationMinutesMax;
  final int exerciseCount;
  final List<String> primaryMuscles;
  final String scheduledDate;
  final bool isToday;
  final bool isCompleted;
  final List<WorkoutExercise> exercises;

  const TodayWorkoutSummary({
    required this.id,
    required this.name,
    required this.type,
    required this.difficulty,
    required this.durationMinutes,
    this.durationMinutesMin,
    this.durationMinutesMax,
    required this.exerciseCount,
    required this.primaryMuscles,
    required this.scheduledDate,
    required this.isToday,
    required this.isCompleted,
    this.exercises = const [],
  });

  /// Get formatted duration display (e.g., "45-60m" or "45m")
  String get formattedDurationShort {
    if (durationMinutesMin != null && durationMinutesMax != null &&
        durationMinutesMin != durationMinutesMax) {
      return '$durationMinutesMin-${durationMinutesMax}m';
    }
    return '${durationMinutes}m';
  }

  factory TodayWorkoutSummary.fromJson(Map<String, dynamic> json) {
    // Parse exercises from JSON array
    final exercisesJson = json['exercises'] as List<dynamic>? ?? [];
    print('🔍 [TodayWorkoutSummary.fromJson] workout_id=${json['id']}, '
        'exercises_count=${exercisesJson.length}, '
        'exercise_count_field=${json['exercise_count']}');

    final exercises = exercisesJson
        .map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
        .toList();

    return TodayWorkoutSummary(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Workout',
      type: json['type'] as String? ?? 'strength',
      difficulty: json['difficulty'] as String? ?? 'medium',
      durationMinutes: json['duration_minutes'] as int? ?? 45,
      durationMinutesMin: json['duration_minutes_min'] as int?,
      durationMinutesMax: json['duration_minutes_max'] as int?,
      exerciseCount: json['exercise_count'] as int? ?? 0,
      primaryMuscles: (json['primary_muscles'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      scheduledDate: json['scheduled_date'] as String? ?? '',
      isToday: json['is_today'] as bool? ?? false,
      isCompleted: json['is_completed'] as bool? ?? false,
      exercises: exercises,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'difficulty': difficulty,
        'duration_minutes': durationMinutes,
        'duration_minutes_min': durationMinutesMin,
        'duration_minutes_max': durationMinutesMax,
        'exercise_count': exerciseCount,
        'primary_muscles': primaryMuscles,
        'scheduled_date': scheduledDate,
        'is_today': isToday,
        'is_completed': isCompleted,
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };

  /// Convert to full Workout object for NextWorkoutCard compatibility
  Workout toWorkout() => Workout(
        id: id,
        name: name,
        type: type,
        difficulty: difficulty,
        durationMinutes: durationMinutes,
        durationMinutesMin: durationMinutesMin,
        durationMinutesMax: durationMinutesMax,
        scheduledDate: scheduledDate,
        isCompleted: isCompleted,
        exercisesJson: exercises.map((e) => e.toJson()).toList(),
        // Pass the API's exercise count so it can be used as fallback
        knownExerciseCount: exerciseCount,
      );
}

/// Response model for today's workout endpoint
class TodayWorkoutResponse {
  final bool hasWorkoutToday;
  final TodayWorkoutSummary? todayWorkout;
  final TodayWorkoutSummary? nextWorkout;
  final int? daysUntilNext;
  final String? restDayMessage;
  // Completed workout info (if user already completed today's workout)
  final bool completedToday;
  final TodayWorkoutSummary? completedWorkout;
  // Generation status fields - used when auto-generating workout
  final bool isGenerating;
  final String? generationMessage;
  // Auto-generation trigger fields
  final bool needsGeneration;
  final String? nextWorkoutDate;  // YYYY-MM-DD format for frontend to generate
  // Gym profile context
  final String? gymProfileId;  // Active gym profile ID used for filtering

  /// Whether there's any displayable content for the home screen.
  /// Used by provider normalization and loading screen to make display decisions.
  /// When true, isGenerating should never block the UI from showing content.
  bool get hasDisplayableContent =>
      todayWorkout != null || nextWorkout != null || completedToday || restDayMessage != null;

  const TodayWorkoutResponse({
    required this.hasWorkoutToday,
    this.todayWorkout,
    this.nextWorkout,
    this.daysUntilNext,
    this.restDayMessage,
    this.completedToday = false,
    this.completedWorkout,
    this.isGenerating = false,
    this.generationMessage,
    this.needsGeneration = false,
    this.nextWorkoutDate,
    this.gymProfileId,
  });

  factory TodayWorkoutResponse.fromJson(Map<String, dynamic> json) {
    return TodayWorkoutResponse(
      hasWorkoutToday: json['has_workout_today'] as bool? ?? false,
      todayWorkout: json['today_workout'] != null
          ? TodayWorkoutSummary.fromJson(
              json['today_workout'] as Map<String, dynamic>)
          : null,
      nextWorkout: json['next_workout'] != null
          ? TodayWorkoutSummary.fromJson(
              json['next_workout'] as Map<String, dynamic>)
          : null,
      daysUntilNext: json['days_until_next'] as int?,
      restDayMessage: json['rest_day_message'] as String?,
      completedToday: json['completed_today'] as bool? ?? false,
      completedWorkout: json['completed_workout'] != null
          ? TodayWorkoutSummary.fromJson(
              json['completed_workout'] as Map<String, dynamic>)
          : null,
      isGenerating: json['is_generating'] as bool? ?? false,
      generationMessage: json['generation_message'] as String?,
      needsGeneration: json['needs_generation'] as bool? ?? false,
      nextWorkoutDate: json['next_workout_date'] as String?,
      gymProfileId: json['gym_profile_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'has_workout_today': hasWorkoutToday,
        'today_workout': todayWorkout?.toJson(),
        'next_workout': nextWorkout?.toJson(),
        'days_until_next': daysUntilNext,
        'rest_day_message': restDayMessage,
        'completed_today': completedToday,
        'completed_workout': completedWorkout?.toJson(),
        'is_generating': isGenerating,
        'generation_message': generationMessage,
        'needs_generation': needsGeneration,
        'next_workout_date': nextWorkoutDate,
        'gym_profile_id': gymProfileId,
      };
}
