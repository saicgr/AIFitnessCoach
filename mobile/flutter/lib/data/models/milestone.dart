/// Milestone and ROI models for tracking user progress and demonstrating value.
///
/// These models support:
/// - Milestone definitions (system-wide milestones)
/// - User milestone achievements
/// - ROI metrics (return on investment of time/effort)
/// - Milestone celebration and sharing
library;

import 'package:json_annotation/json_annotation.dart';

part 'milestone.g.dart';

/// Categories of milestones
enum MilestoneCategory {
  @JsonValue('workouts')
  workouts,
  @JsonValue('streak')
  streak,
  @JsonValue('strength')
  strength,
  @JsonValue('volume')
  volume,
  @JsonValue('time')
  time,
  @JsonValue('weight')
  weight,
  @JsonValue('prs')
  prs,
}

extension MilestoneCategoryExtension on MilestoneCategory {
  String get displayName {
    switch (this) {
      case MilestoneCategory.workouts:
        return 'Workouts';
      case MilestoneCategory.streak:
        return 'Streaks';
      case MilestoneCategory.strength:
        return 'Strength';
      case MilestoneCategory.volume:
        return 'Volume';
      case MilestoneCategory.time:
        return 'Time';
      case MilestoneCategory.weight:
        return 'Weight';
      case MilestoneCategory.prs:
        return 'PRs';
    }
  }

  String get icon {
    switch (this) {
      case MilestoneCategory.workouts:
        return 'fitness_center';
      case MilestoneCategory.streak:
        return 'local_fire_department';
      case MilestoneCategory.strength:
        return 'emoji_events';
      case MilestoneCategory.volume:
        return 'speed';
      case MilestoneCategory.time:
        return 'schedule';
      case MilestoneCategory.weight:
        return 'monitor_weight';
      case MilestoneCategory.prs:
        return 'military_tech';
    }
  }
}

/// Tier levels for milestones (rarity/difficulty)
enum MilestoneTier {
  @JsonValue('bronze')
  bronze,
  @JsonValue('silver')
  silver,
  @JsonValue('gold')
  gold,
  @JsonValue('platinum')
  platinum,
  @JsonValue('diamond')
  diamond,
}

extension MilestoneTierExtension on MilestoneTier {
  String get displayName {
    switch (this) {
      case MilestoneTier.bronze:
        return 'Bronze';
      case MilestoneTier.silver:
        return 'Silver';
      case MilestoneTier.gold:
        return 'Gold';
      case MilestoneTier.platinum:
        return 'Platinum';
      case MilestoneTier.diamond:
        return 'Diamond';
    }
  }

  int get colorValue {
    switch (this) {
      case MilestoneTier.bronze:
        return 0xFFCD7F32; // Bronze
      case MilestoneTier.silver:
        return 0xFFC0C0C0; // Silver
      case MilestoneTier.gold:
        return 0xFFFFD700; // Gold
      case MilestoneTier.platinum:
        return 0xFFE5E4E2; // Platinum
      case MilestoneTier.diamond:
        return 0xFF00BFFF; // Diamond blue
    }
  }
}

/// Definition of a milestone that users can achieve
@JsonSerializable()
class MilestoneDefinition {
  final String id;
  final String name;
  final String? description;
  final MilestoneCategory category;
  final int threshold;
  final String? icon;
  @JsonKey(name: 'badge_color')
  final String badgeColor;
  final MilestoneTier tier;
  final int points;
  @JsonKey(name: 'share_message')
  final String? shareMessage;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'sort_order')
  final int sortOrder;

  const MilestoneDefinition({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    required this.threshold,
    this.icon,
    this.badgeColor = 'cyan',
    this.tier = MilestoneTier.bronze,
    this.points = 10,
    this.shareMessage,
    this.isActive = true,
    this.sortOrder = 0,
  });

  factory MilestoneDefinition.fromJson(Map<String, dynamic> json) =>
      _$MilestoneDefinitionFromJson(json);

  Map<String, dynamic> toJson() => _$MilestoneDefinitionToJson(this);
}

/// A milestone achieved by a user
@JsonSerializable()
class UserMilestone {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'milestone_id')
  final String milestoneId;
  @JsonKey(name: 'achieved_at')
  final DateTime achievedAt;
  @JsonKey(name: 'trigger_value')
  final double? triggerValue;
  @JsonKey(name: 'trigger_context')
  final Map<String, dynamic>? triggerContext;
  @JsonKey(name: 'is_notified')
  final bool isNotified;
  @JsonKey(name: 'is_celebrated')
  final bool isCelebrated;
  @JsonKey(name: 'shared_at')
  final DateTime? sharedAt;
  @JsonKey(name: 'share_platform')
  final String? sharePlatform;
  final MilestoneDefinition? milestone;

  const UserMilestone({
    required this.id,
    required this.userId,
    required this.milestoneId,
    required this.achievedAt,
    this.triggerValue,
    this.triggerContext,
    this.isNotified = false,
    this.isCelebrated = false,
    this.sharedAt,
    this.sharePlatform,
    this.milestone,
  });

  factory UserMilestone.fromJson(Map<String, dynamic> json) =>
      _$UserMilestoneFromJson(json);

  Map<String, dynamic> toJson() => _$UserMilestoneToJson(this);
}

/// Progress toward a milestone (achieved or upcoming)
@JsonSerializable()
class MilestoneProgress {
  final MilestoneDefinition milestone;
  @JsonKey(name: 'is_achieved')
  final bool isAchieved;
  @JsonKey(name: 'achieved_at')
  final DateTime? achievedAt;
  @JsonKey(name: 'trigger_value')
  final double? triggerValue;
  @JsonKey(name: 'is_celebrated')
  final bool isCelebrated;
  @JsonKey(name: 'shared_at')
  final DateTime? sharedAt;
  @JsonKey(name: 'current_value')
  final double? currentValue;
  @JsonKey(name: 'progress_percentage')
  final double? progressPercentage;

  const MilestoneProgress({
    required this.milestone,
    this.isAchieved = false,
    this.achievedAt,
    this.triggerValue,
    this.isCelebrated = false,
    this.sharedAt,
    this.currentValue,
    this.progressPercentage,
  });

  factory MilestoneProgress.fromJson(Map<String, dynamic> json) =>
      _$MilestoneProgressFromJson(json);

  Map<String, dynamic> toJson() => _$MilestoneProgressToJson(this);

  /// Get progress as a value between 0 and 1 for progress indicators
  double get progressFraction => (progressPercentage ?? 0) / 100;
}

/// Response containing all milestone data for a user
@JsonSerializable()
class MilestonesResponse {
  final List<MilestoneProgress> achieved;
  final List<MilestoneProgress> upcoming;
  @JsonKey(name: 'total_points')
  final int totalPoints;
  @JsonKey(name: 'total_achieved')
  final int totalAchieved;
  @JsonKey(name: 'next_milestone')
  final MilestoneProgress? nextMilestone;
  final List<UserMilestone> uncelebrated;

  const MilestonesResponse({
    this.achieved = const [],
    this.upcoming = const [],
    this.totalPoints = 0,
    this.totalAchieved = 0,
    this.nextMilestone,
    this.uncelebrated = const [],
  });

  factory MilestonesResponse.fromJson(Map<String, dynamic> json) =>
      _$MilestonesResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MilestonesResponseToJson(this);
}

/// ROI metrics for a user's fitness journey
@JsonSerializable()
class ROIMetrics {
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'total_workouts_completed')
  final int totalWorkoutsCompleted;
  @JsonKey(name: 'total_exercises_completed')
  final int totalExercisesCompleted;
  @JsonKey(name: 'total_sets_completed')
  final int totalSetsCompleted;
  @JsonKey(name: 'total_reps_completed')
  final int totalRepsCompleted;
  @JsonKey(name: 'total_workout_time_seconds')
  final int totalWorkoutTimeSeconds;
  @JsonKey(name: 'total_workout_time_hours')
  final double totalWorkoutTimeHours;
  @JsonKey(name: 'total_active_time_seconds')
  final int totalActiveTimeSeconds;
  @JsonKey(name: 'average_workout_duration_seconds')
  final int averageWorkoutDurationSeconds;
  @JsonKey(name: 'average_workout_duration_minutes')
  final int averageWorkoutDurationMinutes;
  @JsonKey(name: 'total_weight_lifted_lbs')
  final double totalWeightLiftedLbs;
  @JsonKey(name: 'total_weight_lifted_kg')
  final double totalWeightLiftedKg;
  @JsonKey(name: 'estimated_calories_burned')
  final int estimatedCaloriesBurned;
  @JsonKey(name: 'strength_increase_percentage')
  final double strengthIncreasePercentage;
  @JsonKey(name: 'prs_achieved_count')
  final int prsAchievedCount;
  @JsonKey(name: 'current_streak_days')
  final int currentStreakDays;
  @JsonKey(name: 'longest_streak_days')
  final int longestStreakDays;
  @JsonKey(name: 'first_workout_date')
  final DateTime? firstWorkoutDate;
  @JsonKey(name: 'last_workout_date')
  final DateTime? lastWorkoutDate;
  @JsonKey(name: 'journey_days')
  final int journeyDays;
  @JsonKey(name: 'workouts_this_week')
  final int workoutsThisWeek;
  @JsonKey(name: 'workouts_this_month')
  final int workoutsThisMonth;
  @JsonKey(name: 'average_workouts_per_week')
  final double averageWorkoutsPerWeek;
  @JsonKey(name: 'strength_summary')
  final String strengthSummary;
  @JsonKey(name: 'journey_summary')
  final String journeySummary;

  const ROIMetrics({
    required this.userId,
    this.totalWorkoutsCompleted = 0,
    this.totalExercisesCompleted = 0,
    this.totalSetsCompleted = 0,
    this.totalRepsCompleted = 0,
    this.totalWorkoutTimeSeconds = 0,
    this.totalWorkoutTimeHours = 0,
    this.totalActiveTimeSeconds = 0,
    this.averageWorkoutDurationSeconds = 0,
    this.averageWorkoutDurationMinutes = 0,
    this.totalWeightLiftedLbs = 0,
    this.totalWeightLiftedKg = 0,
    this.estimatedCaloriesBurned = 0,
    this.strengthIncreasePercentage = 0,
    this.prsAchievedCount = 0,
    this.currentStreakDays = 0,
    this.longestStreakDays = 0,
    this.firstWorkoutDate,
    this.lastWorkoutDate,
    this.journeyDays = 0,
    this.workoutsThisWeek = 0,
    this.workoutsThisMonth = 0,
    this.averageWorkoutsPerWeek = 0,
    this.strengthSummary = '',
    this.journeySummary = '',
  });

  factory ROIMetrics.fromJson(Map<String, dynamic> json) =>
      _$ROIMetricsFromJson(json);

  Map<String, dynamic> toJson() => _$ROIMetricsToJson(this);

  /// Get formatted total weight lifted
  String get formattedWeightLifted {
    if (totalWeightLiftedLbs >= 1000000) {
      return '${(totalWeightLiftedLbs / 1000000).toStringAsFixed(1)}M lbs';
    } else if (totalWeightLiftedLbs >= 1000) {
      return '${(totalWeightLiftedLbs / 1000).toStringAsFixed(1)}K lbs';
    } else {
      return '${totalWeightLiftedLbs.toInt()} lbs';
    }
  }
}

/// Compact ROI summary for home screen display
@JsonSerializable()
class ROISummary {
  @JsonKey(name: 'total_workouts')
  final int totalWorkouts;
  @JsonKey(name: 'total_hours_invested')
  final double totalHoursInvested;
  @JsonKey(name: 'estimated_calories_burned')
  final int estimatedCaloriesBurned;
  @JsonKey(name: 'total_weight_lifted')
  final String totalWeightLifted;
  @JsonKey(name: 'strength_increase_text')
  final String strengthIncreaseText;
  @JsonKey(name: 'prs_count')
  final int prsCount;
  @JsonKey(name: 'current_streak')
  final int currentStreak;
  @JsonKey(name: 'journey_days')
  final int journeyDays;
  final String headline;
  @JsonKey(name: 'motivational_message')
  final String motivationalMessage;

  const ROISummary({
    this.totalWorkouts = 0,
    this.totalHoursInvested = 0,
    this.estimatedCaloriesBurned = 0,
    this.totalWeightLifted = '',
    this.strengthIncreaseText = '',
    this.prsCount = 0,
    this.currentStreak = 0,
    this.journeyDays = 0,
    this.headline = 'Your Fitness Journey',
    this.motivationalMessage = '',
  });

  factory ROISummary.fromJson(Map<String, dynamic> json) =>
      _$ROISummaryFromJson(json);

  Map<String, dynamic> toJson() => _$ROISummaryToJson(this);
}

/// Notification for a newly achieved milestone
@JsonSerializable()
class NewMilestoneAchieved {
  @JsonKey(name: 'milestone_id')
  final String milestoneId;
  @JsonKey(name: 'milestone_name')
  final String milestoneName;
  @JsonKey(name: 'milestone_icon')
  final String? milestoneIcon;
  @JsonKey(name: 'milestone_tier')
  final MilestoneTier milestoneTier;
  final int points;
  @JsonKey(name: 'share_message')
  final String? shareMessage;
  @JsonKey(name: 'achieved_at')
  final DateTime achievedAt;

  const NewMilestoneAchieved({
    required this.milestoneId,
    required this.milestoneName,
    this.milestoneIcon,
    this.milestoneTier = MilestoneTier.bronze,
    this.points = 0,
    this.shareMessage,
    required this.achievedAt,
  });

  factory NewMilestoneAchieved.fromJson(Map<String, dynamic> json) =>
      _$NewMilestoneAchievedFromJson(json);

  Map<String, dynamic> toJson() => _$NewMilestoneAchievedToJson(this);
}

/// Result of checking for new milestones
@JsonSerializable()
class MilestoneCheckResult {
  @JsonKey(name: 'new_milestones')
  final List<NewMilestoneAchieved> newMilestones;
  @JsonKey(name: 'total_new_points')
  final int totalNewPoints;
  @JsonKey(name: 'roi_updated')
  final bool roiUpdated;

  const MilestoneCheckResult({
    this.newMilestones = const [],
    this.totalNewPoints = 0,
    this.roiUpdated = false,
  });

  factory MilestoneCheckResult.fromJson(Map<String, dynamic> json) =>
      _$MilestoneCheckResultFromJson(json);

  Map<String, dynamic> toJson() => _$MilestoneCheckResultToJson(this);

  /// Check if there are any new milestones
  bool get hasNewMilestones => newMilestones.isNotEmpty;
}
