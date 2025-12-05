import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'insight.g.dart';

/// AI-generated micro-insight for users
@JsonSerializable()
class UserInsight extends Equatable {
  final String? id;
  @JsonKey(name: 'user_id')
  final String? userId;
  @JsonKey(name: 'insight_type')
  final String? insightType; // 'performance', 'consistency', 'motivation', 'tip', 'milestone'
  final String? message;
  final String? emoji;
  final int? priority;
  @JsonKey(name: 'is_active')
  final bool? isActive;
  @JsonKey(name: 'generated_at')
  final String? generatedAt;

  const UserInsight({
    this.id,
    this.userId,
    this.insightType,
    this.message,
    this.emoji,
    this.priority,
    this.isActive,
    this.generatedAt,
  });

  factory UserInsight.fromJson(Map<String, dynamic> json) =>
      _$UserInsightFromJson(json);
  Map<String, dynamic> toJson() => _$UserInsightToJson(this);

  /// Get display emoji (fallback to type-based)
  String get displayEmoji {
    if (emoji != null && emoji!.isNotEmpty) return emoji!;
    switch (insightType) {
      case 'performance':
        return '💪';
      case 'consistency':
        return '🔥';
      case 'motivation':
        return '⭐';
      case 'tip':
        return '💡';
      case 'milestone':
        return '🏆';
      default:
        return '✨';
    }
  }

  @override
  List<Object?> get props => [id, userId, insightType, message, priority];
}

/// Weekly program progress tracking
@JsonSerializable()
class WeeklyProgress extends Equatable {
  final String? id;
  @JsonKey(name: 'user_id')
  final String? userId;
  @JsonKey(name: 'week_start_date')
  final String? weekStartDate;
  final int? year;
  @JsonKey(name: 'week_number')
  final int? weekNumber;
  @JsonKey(name: 'planned_workouts')
  final int? plannedWorkouts;
  @JsonKey(name: 'completed_workouts')
  final int? completedWorkouts;
  @JsonKey(name: 'total_duration_minutes')
  final int? totalDurationMinutes;
  @JsonKey(name: 'total_calories_burned')
  final int? totalCaloriesBurned;
  @JsonKey(name: 'target_workouts')
  final int? targetWorkouts;
  @JsonKey(name: 'goals_met')
  final bool? goalsMet;

  const WeeklyProgress({
    this.id,
    this.userId,
    this.weekStartDate,
    this.year,
    this.weekNumber,
    this.plannedWorkouts,
    this.completedWorkouts,
    this.totalDurationMinutes,
    this.totalCaloriesBurned,
    this.targetWorkouts,
    this.goalsMet,
  });

  factory WeeklyProgress.fromJson(Map<String, dynamic> json) =>
      _$WeeklyProgressFromJson(json);
  Map<String, dynamic> toJson() => _$WeeklyProgressToJson(this);

  /// Get completion percentage
  double get completionPercent {
    final target = targetWorkouts ?? plannedWorkouts ?? 0;
    if (target == 0) return 0;
    return ((completedWorkouts ?? 0) / target * 100).clamp(0, 100);
  }

  /// Get progress text
  String get progressText => '${completedWorkouts ?? 0}/${targetWorkouts ?? plannedWorkouts ?? 0}';

  @override
  List<Object?> get props => [
        id,
        userId,
        weekStartDate,
        plannedWorkouts,
        completedWorkouts,
        targetWorkouts,
      ];
}

/// Response from insights API
@JsonSerializable()
class InsightsResponse {
  final List<UserInsight> insights;
  @JsonKey(name: 'weekly_progress')
  final WeeklyProgress? weeklyProgress;

  const InsightsResponse({
    this.insights = const [],
    this.weeklyProgress,
  });

  factory InsightsResponse.fromJson(Map<String, dynamic> json) =>
      _$InsightsResponseFromJson(json);
  Map<String, dynamic> toJson() => _$InsightsResponseToJson(this);
}

/// Response from generate insights API
@JsonSerializable()
class GenerateInsightsResponse {
  final String message;
  final bool? generated;
  @JsonKey(name: 'insights_count')
  final int? insightsCount;

  const GenerateInsightsResponse({
    required this.message,
    this.generated,
    this.insightsCount,
  });

  factory GenerateInsightsResponse.fromJson(Map<String, dynamic> json) =>
      _$GenerateInsightsResponseFromJson(json);
  Map<String, dynamic> toJson() => _$GenerateInsightsResponseToJson(this);
}
