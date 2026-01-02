/// NEAT dashboard models for the main NEAT tracking screen.
///
/// These models combine:
/// - Current goal and progress
/// - Today's score and activity
/// - Streak information
/// - Recent achievements
/// - Hourly breakdown
/// - Insights and recommendations
library;

import 'package:json_annotation/json_annotation.dart';

import 'neat_goal.dart';
import 'neat_score.dart';
import 'neat_streak.dart';
import 'neat_achievement.dart';
import 'neat_hourly_activity.dart';

part 'neat_dashboard.g.dart';

/// Complete NEAT dashboard data for the main screen
@JsonSerializable()
class NeatDashboard {
  @JsonKey(name: 'user_id')
  final String userId;

  /// Current goal configuration and progress
  final NeatGoal? goal;

  /// Today's NEAT score
  @JsonKey(name: 'today_score')
  final NeatDailyScore? todayScore;

  /// User's streaks for different metrics
  final List<NeatStreak> streaks;

  /// Recently earned achievements
  @JsonKey(name: 'recent_achievements')
  final List<UserNeatAchievement> recentAchievements;

  /// Today's hourly activity breakdown
  @JsonKey(name: 'hourly_breakdown')
  final NeatHourlyBreakdown? hourlyBreakdown;

  /// Weekly score trend
  @JsonKey(name: 'weekly_trend')
  final NeatScoreTrend? weeklyTrend;

  /// Personalized insight or tip
  final String? insight;

  /// Recommended next action
  final String? recommendation;

  /// Last updated timestamp
  @JsonKey(name: 'last_updated')
  final DateTime? lastUpdated;

  const NeatDashboard({
    required this.userId,
    this.goal,
    this.todayScore,
    this.streaks = const [],
    this.recentAchievements = const [],
    this.hourlyBreakdown,
    this.weeklyTrend,
    this.insight,
    this.recommendation,
    this.lastUpdated,
  });

  factory NeatDashboard.fromJson(Map<String, dynamic> json) =>
      _$NeatDashboardFromJson(json);

  Map<String, dynamic> toJson() => _$NeatDashboardToJson(this);

  /// Get step goal streak
  NeatStreak? get stepStreak {
    try {
      return streaks.firstWhere((s) => s.streakType == NeatStreakType.steps);
    } catch (_) {
      return null;
    }
  }

  /// Get active hours streak
  NeatStreak? get activeHoursStreak {
    try {
      return streaks.firstWhere((s) => s.streakType == NeatStreakType.activeHours);
    } catch (_) {
      return null;
    }
  }

  /// Get NEAT score streak
  NeatStreak? get neatScoreStreak {
    try {
      return streaks.firstWhere((s) => s.streakType == NeatStreakType.neatScore);
    } catch (_) {
      return null;
    }
  }

  /// Primary streak (longest active)
  NeatStreak? get primaryStreak {
    final activeStreaks = streaks.where((s) => s.currentStreak > 0).toList();
    if (activeStreaks.isEmpty) return null;
    return activeStreaks.reduce((a, b) => a.currentStreak >= b.currentStreak ? a : b);
  }

  /// Total steps today from goal or score
  int get stepsToday => goal?.stepsToday ?? todayScore?.totalSteps ?? 0;

  /// Current step goal
  int get currentStepGoal => goal?.currentStepGoal ?? 10000;

  /// Progress toward step goal (0.0 to 1.0)
  double get stepProgress {
    if (currentStepGoal <= 0) return 0.0;
    return (stepsToday / currentStepGoal).clamp(0.0, 1.0);
  }

  /// Whether the step goal has been achieved today
  bool get goalAchievedToday => stepsToday >= currentStepGoal;

  /// Today's NEAT score value
  double get neatScoreValue => todayScore?.neatScore ?? 0.0;

  /// Active hours today
  int get activeHoursToday =>
      hourlyBreakdown?.activeHours ?? todayScore?.activeHours ?? 0;

  /// Sedentary hours today
  int get sedentaryHoursToday =>
      hourlyBreakdown?.sedentaryHours ?? todayScore?.sedentaryHours ?? 0;

  /// Has any new achievements to celebrate
  bool get hasNewAchievements =>
      recentAchievements.any((a) => !a.isCelebrated);

  /// Uncelebrated achievements
  List<UserNeatAchievement> get uncelebratedAchievements =>
      recentAchievements.where((a) => !a.isCelebrated).toList();

  /// Check if data is stale (older than 5 minutes)
  bool get isStale {
    if (lastUpdated == null) return true;
    return DateTime.now().difference(lastUpdated!).inMinutes > 5;
  }

  /// Get score rating text
  String get scoreRatingText => todayScore?.rating.displayName ?? 'No data';

  /// Get weekly trend direction
  NeatScoreTrendDirection? get trendDirection => weeklyTrend?.trendDirection;

  /// Create a copy with updated values
  NeatDashboard copyWith({
    String? userId,
    NeatGoal? goal,
    NeatDailyScore? todayScore,
    List<NeatStreak>? streaks,
    List<UserNeatAchievement>? recentAchievements,
    NeatHourlyBreakdown? hourlyBreakdown,
    NeatScoreTrend? weeklyTrend,
    String? insight,
    String? recommendation,
    DateTime? lastUpdated,
  }) {
    return NeatDashboard(
      userId: userId ?? this.userId,
      goal: goal ?? this.goal,
      todayScore: todayScore ?? this.todayScore,
      streaks: streaks ?? this.streaks,
      recentAchievements: recentAchievements ?? this.recentAchievements,
      hourlyBreakdown: hourlyBreakdown ?? this.hourlyBreakdown,
      weeklyTrend: weeklyTrend ?? this.weeklyTrend,
      insight: insight ?? this.insight,
      recommendation: recommendation ?? this.recommendation,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Quick stats for a compact dashboard view
@JsonSerializable()
class NeatQuickStats {
  @JsonKey(name: 'steps_today')
  final int stepsToday;

  @JsonKey(name: 'step_goal')
  final int stepGoal;

  @JsonKey(name: 'neat_score')
  final double neatScore;

  @JsonKey(name: 'active_hours')
  final int activeHours;

  @JsonKey(name: 'best_streak')
  final int bestStreak;

  @JsonKey(name: 'total_achievements')
  final int totalAchievements;

  const NeatQuickStats({
    this.stepsToday = 0,
    this.stepGoal = 10000,
    this.neatScore = 0.0,
    this.activeHours = 0,
    this.bestStreak = 0,
    this.totalAchievements = 0,
  });

  factory NeatQuickStats.fromJson(Map<String, dynamic> json) =>
      _$NeatQuickStatsFromJson(json);

  Map<String, dynamic> toJson() => _$NeatQuickStatsToJson(this);

  /// Step goal progress
  double get stepProgress {
    if (stepGoal <= 0) return 0.0;
    return (stepsToday / stepGoal).clamp(0.0, 1.0);
  }

  /// Whether step goal is achieved
  bool get goalAchieved => stepsToday >= stepGoal;

  /// Formatted steps
  String get formattedSteps {
    if (stepsToday >= 1000) {
      return '${(stepsToday / 1000).toStringAsFixed(1)}k';
    }
    return stepsToday.toString();
  }
}

/// NEAT insights for analysis and recommendations
@JsonSerializable()
class NeatInsights {
  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(name: 'most_active_day')
  final String? mostActiveDay;

  @JsonKey(name: 'least_active_day')
  final String? leastActiveDay;

  @JsonKey(name: 'most_active_hour')
  final int? mostActiveHour;

  @JsonKey(name: 'average_daily_steps')
  final double averageDailySteps;

  @JsonKey(name: 'average_neat_score')
  final double averageNeatScore;

  @JsonKey(name: 'goal_achievement_rate')
  final double goalAchievementRate;

  @JsonKey(name: 'sedentary_percentage')
  final double sedentaryPercentage;

  final List<String> recommendations;

  final List<String> achievements;

  @JsonKey(name: 'improvement_areas')
  final List<String> improvementAreas;

  const NeatInsights({
    required this.userId,
    this.mostActiveDay,
    this.leastActiveDay,
    this.mostActiveHour,
    this.averageDailySteps = 0.0,
    this.averageNeatScore = 0.0,
    this.goalAchievementRate = 0.0,
    this.sedentaryPercentage = 0.0,
    this.recommendations = const [],
    this.achievements = const [],
    this.improvementAreas = const [],
  });

  factory NeatInsights.fromJson(Map<String, dynamic> json) =>
      _$NeatInsightsFromJson(json);

  Map<String, dynamic> toJson() => _$NeatInsightsToJson(this);

  /// Formatted most active hour
  String? get mostActiveHourFormatted {
    if (mostActiveHour == null) return null;
    final hour = mostActiveHour!;
    if (hour == 0) return '12 AM';
    if (hour == 12) return '12 PM';
    if (hour < 12) return '$hour AM';
    return '${hour - 12} PM';
  }
}

/// NEAT sync status with health platforms
@JsonSerializable()
class NeatSyncStatus {
  @JsonKey(name: 'health_kit_connected')
  final bool healthKitConnected;

  @JsonKey(name: 'google_fit_connected')
  final bool googleFitConnected;

  @JsonKey(name: 'last_sync')
  final DateTime? lastSync;

  @JsonKey(name: 'sync_error')
  final String? syncError;

  @JsonKey(name: 'steps_source')
  final String? stepsSource;

  const NeatSyncStatus({
    this.healthKitConnected = false,
    this.googleFitConnected = false,
    this.lastSync,
    this.syncError,
    this.stepsSource,
  });

  factory NeatSyncStatus.fromJson(Map<String, dynamic> json) =>
      _$NeatSyncStatusFromJson(json);

  Map<String, dynamic> toJson() => _$NeatSyncStatusToJson(this);

  /// Whether any health source is connected
  bool get isConnected => healthKitConnected || googleFitConnected;

  /// Has a sync error
  bool get hasError => syncError != null && syncError!.isNotEmpty;

  /// Minutes since last sync
  int? get minutesSinceSync {
    if (lastSync == null) return null;
    return DateTime.now().difference(lastSync!).inMinutes;
  }

  /// Whether data might be stale (no sync in 30+ minutes)
  bool get isStale => minutesSinceSync != null && minutesSinceSync! > 30;
}
