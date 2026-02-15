// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_screen_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkoutMiniSummary _$WorkoutMiniSummaryFromJson(Map<String, dynamic> json) =>
    WorkoutMiniSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      scheduledDate: json['scheduled_date'] as String,
      isCompleted: json['is_completed'] as bool,
      durationMinutes: (json['duration_minutes'] as num).toInt(),
      exerciseCount: (json['exercise_count'] as num).toInt(),
      primaryMuscles: (json['primary_muscles'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$WorkoutMiniSummaryToJson(WorkoutMiniSummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': instance.type,
      'scheduled_date': instance.scheduledDate,
      'is_completed': instance.isCompleted,
      'duration_minutes': instance.durationMinutes,
      'exercise_count': instance.exerciseCount,
      'primary_muscles': instance.primaryMuscles,
    };

WorkoutScreenSummary _$WorkoutScreenSummaryFromJson(
  Map<String, dynamic> json,
) => WorkoutScreenSummary(
  completedThisWeek: (json['completed_this_week'] as num).toInt(),
  plannedThisWeek: (json['planned_this_week'] as num).toInt(),
  previousSessions: (json['previous_sessions'] as List<dynamic>)
      .map((e) => WorkoutMiniSummary.fromJson(e as Map<String, dynamic>))
      .toList(),
  upcomingWorkouts: (json['upcoming_workouts'] as List<dynamic>)
      .map((e) => WorkoutMiniSummary.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$WorkoutScreenSummaryToJson(
  WorkoutScreenSummary instance,
) => <String, dynamic>{
  'completed_this_week': instance.completedThisWeek,
  'planned_this_week': instance.plannedThisWeek,
  'previous_sessions': instance.previousSessions,
  'upcoming_workouts': instance.upcomingWorkouts,
};
