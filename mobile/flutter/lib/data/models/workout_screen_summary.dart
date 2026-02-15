import 'package:json_annotation/json_annotation.dart';

part 'workout_screen_summary.g.dart';

@JsonSerializable()
class WorkoutMiniSummary {
  final String id;
  final String name;
  final String type;
  @JsonKey(name: 'scheduled_date')
  final String scheduledDate;
  @JsonKey(name: 'is_completed')
  final bool isCompleted;
  @JsonKey(name: 'duration_minutes')
  final int durationMinutes;
  @JsonKey(name: 'exercise_count')
  final int exerciseCount;
  @JsonKey(name: 'primary_muscles')
  final List<String> primaryMuscles;

  const WorkoutMiniSummary({
    required this.id,
    required this.name,
    required this.type,
    required this.scheduledDate,
    required this.isCompleted,
    required this.durationMinutes,
    required this.exerciseCount,
    required this.primaryMuscles,
  });

  factory WorkoutMiniSummary.fromJson(Map<String, dynamic> json) =>
      _$WorkoutMiniSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$WorkoutMiniSummaryToJson(this);

  /// Get formatted duration (e.g., "45m")
  String get formattedDurationShort => '${durationMinutes}m';
}

@JsonSerializable()
class WorkoutScreenSummary {
  @JsonKey(name: 'completed_this_week')
  final int completedThisWeek;
  @JsonKey(name: 'planned_this_week')
  final int plannedThisWeek;
  @JsonKey(name: 'previous_sessions')
  final List<WorkoutMiniSummary> previousSessions;
  @JsonKey(name: 'upcoming_workouts')
  final List<WorkoutMiniSummary> upcomingWorkouts;

  const WorkoutScreenSummary({
    required this.completedThisWeek,
    required this.plannedThisWeek,
    required this.previousSessions,
    required this.upcomingWorkouts,
  });

  factory WorkoutScreenSummary.fromJson(Map<String, dynamic> json) =>
      _$WorkoutScreenSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$WorkoutScreenSummaryToJson(this);
}
