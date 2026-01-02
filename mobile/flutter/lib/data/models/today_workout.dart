/// Models for the today's workout quick start feature
library;

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
  });

  factory TodayWorkoutSummary.fromJson(Map<String, dynamic> json) {
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
      };
}

/// Response model for today's workout endpoint
class TodayWorkoutResponse {
  final bool hasWorkoutToday;
  final TodayWorkoutSummary? todayWorkout;
  final TodayWorkoutSummary? nextWorkout;
  final String? restDayMessage;
  final int? daysUntilNext;

  const TodayWorkoutResponse({
    required this.hasWorkoutToday,
    this.todayWorkout,
    this.nextWorkout,
    this.restDayMessage,
    this.daysUntilNext,
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
      restDayMessage: json['rest_day_message'] as String?,
      daysUntilNext: json['days_until_next'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'has_workout_today': hasWorkoutToday,
        'today_workout': todayWorkout?.toJson(),
        'next_workout': nextWorkout?.toJson(),
        'rest_day_message': restDayMessage,
        'days_until_next': daysUntilNext,
      };
}
