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
    required this.exerciseCount,
    required this.primaryMuscles,
    required this.scheduledDate,
    required this.isToday,
    required this.isCompleted,
    this.exercises = const [],
  });

  factory TodayWorkoutSummary.fromJson(Map<String, dynamic> json) {
    // Parse exercises from JSON array
    final exercisesJson = json['exercises'] as List<dynamic>? ?? [];
    final exercises = exercisesJson
        .map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
        .toList();

    return TodayWorkoutSummary(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Workout',
      type: json['type'] as String? ?? 'strength',
      difficulty: json['difficulty'] as String? ?? 'medium',
      durationMinutes: json['duration_minutes'] as int? ?? 45,
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
        scheduledDate: scheduledDate,
        isCompleted: isCompleted,
        exercisesJson: exercises.map((e) => e.toJson()).toList(),
      );
}

/// Response model for today's workout endpoint
class TodayWorkoutResponse {
  final bool hasWorkoutToday;
  final TodayWorkoutSummary? todayWorkout;
  final TodayWorkoutSummary? nextWorkout;
  final int? daysUntilNext;
  // Generation status fields - used when auto-generating workout
  final bool isGenerating;
  final String? generationMessage;

  const TodayWorkoutResponse({
    required this.hasWorkoutToday,
    this.todayWorkout,
    this.nextWorkout,
    this.daysUntilNext,
    this.isGenerating = false,
    this.generationMessage,
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
      isGenerating: json['is_generating'] as bool? ?? false,
      generationMessage: json['generation_message'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'has_workout_today': hasWorkoutToday,
        'today_workout': todayWorkout?.toJson(),
        'next_workout': nextWorkout?.toJson(),
        'days_until_next': daysUntilNext,
        'is_generating': isGenerating,
        'generation_message': generationMessage,
      };
}
