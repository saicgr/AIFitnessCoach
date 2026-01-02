import 'package:json_annotation/json_annotation.dart';

part 'neat.g.dart';

// ============================================
// NEAT Goal Models
// ============================================

/// Goal type for NEAT tracking
enum NeatGoalType {
  @JsonValue('steps')
  steps,
  @JsonValue('active_minutes')
  activeMinutes,
  @JsonValue('standing_hours')
  standingHours,
  @JsonValue('calories')
  calories;

  String get displayName {
    switch (this) {
      case NeatGoalType.steps:
        return 'Daily Steps';
      case NeatGoalType.activeMinutes:
        return 'Active Minutes';
      case NeatGoalType.standingHours:
        return 'Standing Hours';
      case NeatGoalType.calories:
        return 'NEAT Calories';
    }
  }
}

/// Current NEAT goal for a user
@JsonSerializable()
class NeatGoal {
  final String id;

  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(name: 'goal_type')
  final String goalType;

  @JsonKey(name: 'target_value')
  final int targetValue;

  @JsonKey(name: 'current_value')
  final int currentValue;

  @JsonKey(name: 'unit')
  final String unit;

  @JsonKey(name: 'is_progressive')
  final bool isProgressive;

  @JsonKey(name: 'baseline_value')
  final int? baselineValue;

  @JsonKey(name: 'increment_value')
  final int? incrementValue;

  @JsonKey(name: 'increment_frequency_days')
  final int? incrementFrequencyDays;

  @JsonKey(name: 'created_at')
  final String createdAt;

  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  const NeatGoal({
    required this.id,
    required this.userId,
    required this.goalType,
    required this.targetValue,
    this.currentValue = 0,
    required this.unit,
    this.isProgressive = false,
    this.baselineValue,
    this.incrementValue,
    this.incrementFrequencyDays,
    required this.createdAt,
    this.updatedAt,
  });

  factory NeatGoal.fromJson(Map<String, dynamic> json) =>
      _$NeatGoalFromJson(json);
  Map<String, dynamic> toJson() => _$NeatGoalToJson(this);

  /// Progress percentage (0.0 to 1.0+)
  double get progressPercentage {
    if (targetValue == 0) return 0.0;
    return currentValue / targetValue;
  }

  /// Whether the goal is achieved
  bool get isAchieved => currentValue >= targetValue;

  /// Remaining to reach goal
  int get remaining => (targetValue - currentValue).clamp(0, targetValue);

  /// Display string for progress
  String get progressDisplay => '$currentValue / $targetValue $unit';
}

// ============================================
// Hourly Activity Models
// ============================================

/// Single hour activity data
@JsonSerializable()
class HourlyActivity {
  final int hour;

  final int steps;

  @JsonKey(name: 'active_minutes')
  final int activeMinutes;

  @JsonKey(name: 'standing')
  final bool standing;

  @JsonKey(name: 'calories_burned')
  final double caloriesBurned;

  @JsonKey(name: 'movement_type')
  final String? movementType;

  const HourlyActivity({
    required this.hour,
    this.steps = 0,
    this.activeMinutes = 0,
    this.standing = false,
    this.caloriesBurned = 0.0,
    this.movementType,
  });

  factory HourlyActivity.fromJson(Map<String, dynamic> json) =>
      _$HourlyActivityFromJson(json);
  Map<String, dynamic> toJson() => _$HourlyActivityToJson(this);

  /// Get display time for this hour (e.g., "9 AM")
  String get timeDisplay {
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
  }
}

/// Hourly breakdown for a specific date
@JsonSerializable()
class NeatHourlyBreakdown {
  @JsonKey(name: 'user_id')
  final String userId;

  final String date;

  @JsonKey(name: 'hourly_data')
  final List<HourlyActivity> hourlyData;

  @JsonKey(name: 'total_steps')
  final int totalSteps;

  @JsonKey(name: 'total_active_minutes')
  final int totalActiveMinutes;

  @JsonKey(name: 'total_standing_hours')
  final int totalStandingHours;

  @JsonKey(name: 'total_calories')
  final double totalCalories;

  @JsonKey(name: 'peak_hour')
  final int? peakHour;

  @JsonKey(name: 'least_active_hour')
  final int? leastActiveHour;

  const NeatHourlyBreakdown({
    required this.userId,
    required this.date,
    this.hourlyData = const [],
    this.totalSteps = 0,
    this.totalActiveMinutes = 0,
    this.totalStandingHours = 0,
    this.totalCalories = 0.0,
    this.peakHour,
    this.leastActiveHour,
  });

  factory NeatHourlyBreakdown.fromJson(Map<String, dynamic> json) =>
      _$NeatHourlyBreakdownFromJson(json);
  Map<String, dynamic> toJson() => _$NeatHourlyBreakdownToJson(this);

  DateTime get dateTime => DateTime.parse(date);

  /// Get activity for a specific hour
  HourlyActivity? getHourActivity(int hour) {
    try {
      return hourlyData.firstWhere((h) => h.hour == hour);
    } catch (_) {
      return null;
    }
  }
}

// ============================================
// Daily Score Models
// ============================================

/// Daily NEAT score
@JsonSerializable()
class NeatDailyScore {
  final String id;

  @JsonKey(name: 'user_id')
  final String userId;

  final String date;

  final int score;

  @JsonKey(name: 'max_score')
  final int maxScore;

  @JsonKey(name: 'steps_score')
  final int stepsScore;

  @JsonKey(name: 'active_minutes_score')
  final int activeMinutesScore;

  @JsonKey(name: 'standing_hours_score')
  final int standingHoursScore;

  @JsonKey(name: 'consistency_bonus')
  final int consistencyBonus;

  @JsonKey(name: 'total_steps')
  final int totalSteps;

  @JsonKey(name: 'total_active_minutes')
  final int totalActiveMinutes;

  @JsonKey(name: 'total_standing_hours')
  final int totalStandingHours;

  @JsonKey(name: 'total_calories')
  final double totalCalories;

  @JsonKey(name: 'goals_achieved')
  final int goalsAchieved;

  @JsonKey(name: 'total_goals')
  final int totalGoals;

  @JsonKey(name: 'calculated_at')
  final String? calculatedAt;

  const NeatDailyScore({
    required this.id,
    required this.userId,
    required this.date,
    this.score = 0,
    this.maxScore = 100,
    this.stepsScore = 0,
    this.activeMinutesScore = 0,
    this.standingHoursScore = 0,
    this.consistencyBonus = 0,
    this.totalSteps = 0,
    this.totalActiveMinutes = 0,
    this.totalStandingHours = 0,
    this.totalCalories = 0.0,
    this.goalsAchieved = 0,
    this.totalGoals = 0,
    this.calculatedAt,
  });

  factory NeatDailyScore.fromJson(Map<String, dynamic> json) =>
      _$NeatDailyScoreFromJson(json);
  Map<String, dynamic> toJson() => _$NeatDailyScoreToJson(this);

  DateTime get dateTime => DateTime.parse(date);

  /// Score percentage (0.0 to 1.0)
  double get scorePercentage {
    if (maxScore == 0) return 0.0;
    return score / maxScore;
  }

  /// Get grade based on score
  String get grade {
    final pct = scorePercentage * 100;
    if (pct >= 90) return 'A';
    if (pct >= 80) return 'B';
    if (pct >= 70) return 'C';
    if (pct >= 60) return 'D';
    return 'F';
  }

  /// Whether all goals were achieved
  bool get allGoalsAchieved => goalsAchieved >= totalGoals && totalGoals > 0;
}

// ============================================
// Streak Models
// ============================================

/// NEAT streak type
enum NeatStreakType {
  @JsonValue('steps')
  steps,
  @JsonValue('active_minutes')
  activeMinutes,
  @JsonValue('standing_hours')
  standingHours,
  @JsonValue('all_goals')
  allGoals;

  String get displayName {
    switch (this) {
      case NeatStreakType.steps:
        return 'Step Goal';
      case NeatStreakType.activeMinutes:
        return 'Active Minutes';
      case NeatStreakType.standingHours:
        return 'Standing Hours';
      case NeatStreakType.allGoals:
        return 'All Goals';
    }
  }
}

/// NEAT streak record
@JsonSerializable()
class NeatStreak {
  final String id;

  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(name: 'streak_type')
  final String streakType;

  @JsonKey(name: 'current_streak')
  final int currentStreak;

  @JsonKey(name: 'longest_streak')
  final int longestStreak;

  @JsonKey(name: 'is_active')
  final bool isActive;

  @JsonKey(name: 'started_at')
  final String? startedAt;

  @JsonKey(name: 'last_activity_date')
  final String? lastActivityDate;

  const NeatStreak({
    required this.id,
    required this.userId,
    required this.streakType,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.isActive = false,
    this.startedAt,
    this.lastActivityDate,
  });

  factory NeatStreak.fromJson(Map<String, dynamic> json) =>
      _$NeatStreakFromJson(json);
  Map<String, dynamic> toJson() => _$NeatStreakToJson(this);

  DateTime? get startedAtDate =>
      startedAt != null ? DateTime.tryParse(startedAt!) : null;

  DateTime? get lastActivityDateTime =>
      lastActivityDate != null ? DateTime.tryParse(lastActivityDate!) : null;

  /// Display name for streak type
  String get streakTypeDisplay {
    switch (streakType.toLowerCase()) {
      case 'steps':
        return 'Step Goal';
      case 'active_minutes':
        return 'Active Minutes';
      case 'standing_hours':
        return 'Standing Hours';
      case 'all_goals':
        return 'All Goals';
      default:
        return streakType;
    }
  }
}

// ============================================
// Achievement Models
// ============================================

/// NEAT achievement category
enum NeatAchievementCategory {
  @JsonValue('steps')
  steps,
  @JsonValue('consistency')
  consistency,
  @JsonValue('improvement')
  improvement,
  @JsonValue('milestone')
  milestone;

  String get displayName {
    switch (this) {
      case NeatAchievementCategory.steps:
        return 'Steps';
      case NeatAchievementCategory.consistency:
        return 'Consistency';
      case NeatAchievementCategory.improvement:
        return 'Improvement';
      case NeatAchievementCategory.milestone:
        return 'Milestone';
    }
  }
}

/// User NEAT achievement
@JsonSerializable()
class UserNeatAchievement {
  final String id;

  @JsonKey(name: 'user_id')
  final String? userId;

  final String name;

  final String description;

  final String category;

  @JsonKey(name: 'icon_name')
  final String? iconName;

  @JsonKey(name: 'points')
  final int points;

  @JsonKey(name: 'requirement_type')
  final String requirementType;

  @JsonKey(name: 'requirement_value')
  final int requirementValue;

  @JsonKey(name: 'current_progress')
  final int currentProgress;

  @JsonKey(name: 'is_earned')
  final bool isEarned;

  @JsonKey(name: 'earned_at')
  final String? earnedAt;

  @JsonKey(name: 'is_celebrated')
  final bool isCelebrated;

  const UserNeatAchievement({
    required this.id,
    this.userId,
    required this.name,
    required this.description,
    required this.category,
    this.iconName,
    this.points = 0,
    required this.requirementType,
    required this.requirementValue,
    this.currentProgress = 0,
    this.isEarned = false,
    this.earnedAt,
    this.isCelebrated = false,
  });

  factory UserNeatAchievement.fromJson(Map<String, dynamic> json) =>
      _$UserNeatAchievementFromJson(json);
  Map<String, dynamic> toJson() => _$UserNeatAchievementToJson(this);

  DateTime? get earnedAtDate =>
      earnedAt != null ? DateTime.tryParse(earnedAt!) : null;

  /// Progress percentage (0.0 to 1.0)
  double get progressPercentage {
    if (requirementValue == 0) return 0.0;
    return (currentProgress / requirementValue).clamp(0.0, 1.0);
  }

  /// Progress display string
  String get progressDisplay => '$currentProgress / $requirementValue';
}

// ============================================
// Reminder Preferences Models
// ============================================

/// NEAT reminder preferences
@JsonSerializable()
class NeatReminderPreferences {
  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(name: 'reminders_enabled')
  final bool remindersEnabled;

  @JsonKey(name: 'hourly_movement_enabled')
  final bool hourlyMovementEnabled;

  @JsonKey(name: 'hourly_start_time')
  final String hourlyStartTime;

  @JsonKey(name: 'hourly_end_time')
  final String hourlyEndTime;

  @JsonKey(name: 'step_milestone_enabled')
  final bool stepMilestoneEnabled;

  @JsonKey(name: 'step_milestones')
  final List<int> stepMilestones;

  @JsonKey(name: 'goal_reminder_enabled')
  final bool goalReminderEnabled;

  @JsonKey(name: 'goal_reminder_time')
  final String? goalReminderTime;

  @JsonKey(name: 'inactivity_reminder_enabled')
  final bool inactivityReminderEnabled;

  @JsonKey(name: 'inactivity_threshold_minutes')
  final int inactivityThresholdMinutes;

  @JsonKey(name: 'quiet_hours_enabled')
  final bool quietHoursEnabled;

  @JsonKey(name: 'quiet_hours_start')
  final String? quietHoursStart;

  @JsonKey(name: 'quiet_hours_end')
  final String? quietHoursEnd;

  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  const NeatReminderPreferences({
    required this.userId,
    this.remindersEnabled = true,
    this.hourlyMovementEnabled = true,
    this.hourlyStartTime = '09:00',
    this.hourlyEndTime = '21:00',
    this.stepMilestoneEnabled = true,
    this.stepMilestones = const [2500, 5000, 7500, 10000],
    this.goalReminderEnabled = true,
    this.goalReminderTime,
    this.inactivityReminderEnabled = false,
    this.inactivityThresholdMinutes = 60,
    this.quietHoursEnabled = false,
    this.quietHoursStart,
    this.quietHoursEnd,
    this.updatedAt,
  });

  factory NeatReminderPreferences.fromJson(Map<String, dynamic> json) =>
      _$NeatReminderPreferencesFromJson(json);
  Map<String, dynamic> toJson() => _$NeatReminderPreferencesToJson(this);

  NeatReminderPreferences copyWith({
    String? userId,
    bool? remindersEnabled,
    bool? hourlyMovementEnabled,
    String? hourlyStartTime,
    String? hourlyEndTime,
    bool? stepMilestoneEnabled,
    List<int>? stepMilestones,
    bool? goalReminderEnabled,
    String? goalReminderTime,
    bool? inactivityReminderEnabled,
    int? inactivityThresholdMinutes,
    bool? quietHoursEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
  }) {
    return NeatReminderPreferences(
      userId: userId ?? this.userId,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      hourlyMovementEnabled:
          hourlyMovementEnabled ?? this.hourlyMovementEnabled,
      hourlyStartTime: hourlyStartTime ?? this.hourlyStartTime,
      hourlyEndTime: hourlyEndTime ?? this.hourlyEndTime,
      stepMilestoneEnabled: stepMilestoneEnabled ?? this.stepMilestoneEnabled,
      stepMilestones: stepMilestones ?? this.stepMilestones,
      goalReminderEnabled: goalReminderEnabled ?? this.goalReminderEnabled,
      goalReminderTime: goalReminderTime ?? this.goalReminderTime,
      inactivityReminderEnabled:
          inactivityReminderEnabled ?? this.inactivityReminderEnabled,
      inactivityThresholdMinutes:
          inactivityThresholdMinutes ?? this.inactivityThresholdMinutes,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
    );
  }
}

// ============================================
// Dashboard Models
// ============================================

/// Complete NEAT dashboard data
@JsonSerializable()
class NeatDashboard {
  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(name: 'today_score')
  final NeatDailyScore? todayScore;

  @JsonKey(name: 'current_goals')
  final List<NeatGoal> currentGoals;

  @JsonKey(name: 'hourly_breakdown')
  final NeatHourlyBreakdown? hourlyBreakdown;

  @JsonKey(name: 'streaks')
  final List<NeatStreak> streaks;

  @JsonKey(name: 'recent_achievements')
  final List<UserNeatAchievement> recentAchievements;

  @JsonKey(name: 'weekly_summary')
  final NeatWeeklySummary? weeklySummary;

  @JsonKey(name: 'suggestions')
  final List<String> suggestions;

  @JsonKey(name: 'calculated_at')
  final String? calculatedAt;

  const NeatDashboard({
    required this.userId,
    this.todayScore,
    this.currentGoals = const [],
    this.hourlyBreakdown,
    this.streaks = const [],
    this.recentAchievements = const [],
    this.weeklySummary,
    this.suggestions = const [],
    this.calculatedAt,
  });

  factory NeatDashboard.fromJson(Map<String, dynamic> json) =>
      _$NeatDashboardFromJson(json);
  Map<String, dynamic> toJson() => _$NeatDashboardToJson(this);

  /// Get the primary step goal
  NeatGoal? get stepGoal {
    try {
      return currentGoals.firstWhere((g) => g.goalType == 'steps');
    } catch (_) {
      return null;
    }
  }

  /// Get the step streak
  NeatStreak? get stepStreak {
    try {
      return streaks.firstWhere((s) => s.streakType == 'steps');
    } catch (_) {
      return null;
    }
  }

  /// Get all goals streak
  NeatStreak? get allGoalsStreak {
    try {
      return streaks.firstWhere((s) => s.streakType == 'all_goals');
    } catch (_) {
      return null;
    }
  }
}

/// Weekly NEAT summary
@JsonSerializable()
class NeatWeeklySummary {
  @JsonKey(name: 'week_start')
  final String weekStart;

  @JsonKey(name: 'week_end')
  final String weekEnd;

  @JsonKey(name: 'total_steps')
  final int totalSteps;

  @JsonKey(name: 'average_daily_steps')
  final int averageDailySteps;

  @JsonKey(name: 'total_active_minutes')
  final int totalActiveMinutes;

  @JsonKey(name: 'total_standing_hours')
  final int totalStandingHours;

  @JsonKey(name: 'goals_achieved_days')
  final int goalsAchievedDays;

  @JsonKey(name: 'total_days')
  final int totalDays;

  @JsonKey(name: 'average_score')
  final double averageScore;

  @JsonKey(name: 'best_day')
  final String? bestDay;

  @JsonKey(name: 'best_day_steps')
  final int bestDaySteps;

  @JsonKey(name: 'trend')
  final String trend;

  @JsonKey(name: 'trend_percentage')
  final double trendPercentage;

  const NeatWeeklySummary({
    required this.weekStart,
    required this.weekEnd,
    this.totalSteps = 0,
    this.averageDailySteps = 0,
    this.totalActiveMinutes = 0,
    this.totalStandingHours = 0,
    this.goalsAchievedDays = 0,
    this.totalDays = 7,
    this.averageScore = 0.0,
    this.bestDay,
    this.bestDaySteps = 0,
    this.trend = 'stable',
    this.trendPercentage = 0.0,
  });

  factory NeatWeeklySummary.fromJson(Map<String, dynamic> json) =>
      _$NeatWeeklySummaryFromJson(json);
  Map<String, dynamic> toJson() => _$NeatWeeklySummaryToJson(this);

  DateTime get weekStartDate => DateTime.parse(weekStart);
  DateTime get weekEndDate => DateTime.parse(weekEnd);

  /// Goal achievement rate (0.0 to 1.0)
  double get goalAchievementRate {
    if (totalDays == 0) return 0.0;
    return goalsAchievedDays / totalDays;
  }

  /// Trend display with arrow
  String get trendDisplay {
    final arrow = trend == 'up'
        ? '\u2191'
        : trend == 'down'
            ? '\u2193'
            : '\u2192';
    return '$arrow ${trendPercentage.abs().toStringAsFixed(1)}%';
  }
}
