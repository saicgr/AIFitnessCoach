import 'package:json_annotation/json_annotation.dart';

part 'weekly_summary.g.dart';

/// Weekly summary with AI-generated content
@JsonSerializable()
class WeeklySummary {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'week_start')
  final String weekStart;
  @JsonKey(name: 'week_end')
  final String weekEnd;

  // Stats
  @JsonKey(name: 'workouts_completed')
  final int workoutsCompleted;
  @JsonKey(name: 'workouts_scheduled')
  final int workoutsScheduled;
  @JsonKey(name: 'total_exercises')
  final int totalExercises;
  @JsonKey(name: 'total_sets')
  final int totalSets;
  @JsonKey(name: 'total_time_minutes')
  final int totalTimeMinutes;
  @JsonKey(name: 'calories_burned_estimate')
  final int caloriesBurnedEstimate;

  // Streak info
  @JsonKey(name: 'current_streak')
  final int currentStreak;
  @JsonKey(name: 'streak_status')
  final String? streakStatus;

  // PRs
  @JsonKey(name: 'prs_achieved')
  final int prsAchieved;
  @JsonKey(name: 'pr_details')
  final List<Map<String, dynamic>>? prDetails;

  // AI-generated content
  @JsonKey(name: 'ai_summary')
  final String? aiSummary;
  @JsonKey(name: 'ai_highlights')
  final List<String>? aiHighlights;
  @JsonKey(name: 'ai_encouragement')
  final String? aiEncouragement;
  @JsonKey(name: 'ai_next_week_tips')
  final List<String>? aiNextWeekTips;
  @JsonKey(name: 'ai_generated_at')
  final DateTime? aiGeneratedAt;

  // Notification status
  @JsonKey(name: 'email_sent')
  final bool emailSent;
  @JsonKey(name: 'push_sent')
  final bool pushSent;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  const WeeklySummary({
    required this.id,
    required this.userId,
    required this.weekStart,
    required this.weekEnd,
    this.workoutsCompleted = 0,
    this.workoutsScheduled = 0,
    this.totalExercises = 0,
    this.totalSets = 0,
    this.totalTimeMinutes = 0,
    this.caloriesBurnedEstimate = 0,
    this.currentStreak = 0,
    this.streakStatus,
    this.prsAchieved = 0,
    this.prDetails,
    this.aiSummary,
    this.aiHighlights,
    this.aiEncouragement,
    this.aiNextWeekTips,
    this.aiGeneratedAt,
    this.emailSent = false,
    this.pushSent = false,
    required this.createdAt,
  });

  factory WeeklySummary.fromJson(Map<String, dynamic> json) =>
      _$WeeklySummaryFromJson(json);
  Map<String, dynamic> toJson() => _$WeeklySummaryToJson(this);

  /// Get completion rate as percentage
  double get completionRate {
    if (workoutsScheduled == 0) return 0;
    return (workoutsCompleted / workoutsScheduled) * 100;
  }

  /// Get streak status text
  String get streakStatusText {
    switch (streakStatus) {
      case 'growing':
        return 'On Fire!';
      case 'maintained':
        return 'Consistent';
      case 'broken':
        return 'Keep Going';
      default:
        return '';
    }
  }
}
