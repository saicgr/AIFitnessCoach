// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'milestone.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MilestoneDefinition _$MilestoneDefinitionFromJson(Map<String, dynamic> json) =>
    MilestoneDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      category: $enumDecode(_$MilestoneCategoryEnumMap, json['category']),
      threshold: (json['threshold'] as num).toInt(),
      icon: json['icon'] as String?,
      badgeColor: json['badge_color'] as String? ?? 'cyan',
      tier:
          $enumDecodeNullable(_$MilestoneTierEnumMap, json['tier']) ??
          MilestoneTier.bronze,
      points: (json['points'] as num?)?.toInt() ?? 10,
      shareMessage: json['share_message'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$MilestoneDefinitionToJson(
  MilestoneDefinition instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'category': _$MilestoneCategoryEnumMap[instance.category]!,
  'threshold': instance.threshold,
  'icon': instance.icon,
  'badge_color': instance.badgeColor,
  'tier': _$MilestoneTierEnumMap[instance.tier]!,
  'points': instance.points,
  'share_message': instance.shareMessage,
  'is_active': instance.isActive,
  'sort_order': instance.sortOrder,
};

const _$MilestoneCategoryEnumMap = {
  MilestoneCategory.workouts: 'workouts',
  MilestoneCategory.streak: 'streak',
  MilestoneCategory.strength: 'strength',
  MilestoneCategory.volume: 'volume',
  MilestoneCategory.time: 'time',
  MilestoneCategory.weight: 'weight',
  MilestoneCategory.prs: 'prs',
};

const _$MilestoneTierEnumMap = {
  MilestoneTier.bronze: 'bronze',
  MilestoneTier.silver: 'silver',
  MilestoneTier.gold: 'gold',
  MilestoneTier.platinum: 'platinum',
  MilestoneTier.diamond: 'diamond',
};

UserMilestone _$UserMilestoneFromJson(Map<String, dynamic> json) =>
    UserMilestone(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      milestoneId: json['milestone_id'] as String,
      achievedAt: DateTime.parse(json['achieved_at'] as String),
      triggerValue: (json['trigger_value'] as num?)?.toDouble(),
      triggerContext: json['trigger_context'] as Map<String, dynamic>?,
      isNotified: json['is_notified'] as bool? ?? false,
      isCelebrated: json['is_celebrated'] as bool? ?? false,
      sharedAt: json['shared_at'] == null
          ? null
          : DateTime.parse(json['shared_at'] as String),
      sharePlatform: json['share_platform'] as String?,
      milestone: json['milestone'] == null
          ? null
          : MilestoneDefinition.fromJson(
              json['milestone'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$UserMilestoneToJson(UserMilestone instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'milestone_id': instance.milestoneId,
      'achieved_at': instance.achievedAt.toIso8601String(),
      'trigger_value': instance.triggerValue,
      'trigger_context': instance.triggerContext,
      'is_notified': instance.isNotified,
      'is_celebrated': instance.isCelebrated,
      'shared_at': instance.sharedAt?.toIso8601String(),
      'share_platform': instance.sharePlatform,
      'milestone': instance.milestone,
    };

MilestoneProgress _$MilestoneProgressFromJson(Map<String, dynamic> json) =>
    MilestoneProgress(
      milestone: MilestoneDefinition.fromJson(
        json['milestone'] as Map<String, dynamic>,
      ),
      isAchieved: json['is_achieved'] as bool? ?? false,
      achievedAt: json['achieved_at'] == null
          ? null
          : DateTime.parse(json['achieved_at'] as String),
      triggerValue: (json['trigger_value'] as num?)?.toDouble(),
      isCelebrated: json['is_celebrated'] as bool? ?? false,
      sharedAt: json['shared_at'] == null
          ? null
          : DateTime.parse(json['shared_at'] as String),
      currentValue: (json['current_value'] as num?)?.toDouble(),
      progressPercentage: (json['progress_percentage'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$MilestoneProgressToJson(MilestoneProgress instance) =>
    <String, dynamic>{
      'milestone': instance.milestone,
      'is_achieved': instance.isAchieved,
      'achieved_at': instance.achievedAt?.toIso8601String(),
      'trigger_value': instance.triggerValue,
      'is_celebrated': instance.isCelebrated,
      'shared_at': instance.sharedAt?.toIso8601String(),
      'current_value': instance.currentValue,
      'progress_percentage': instance.progressPercentage,
    };

MilestonesResponse _$MilestonesResponseFromJson(
  Map<String, dynamic> json,
) => MilestonesResponse(
  achieved:
      (json['achieved'] as List<dynamic>?)
          ?.map((e) => MilestoneProgress.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  upcoming:
      (json['upcoming'] as List<dynamic>?)
          ?.map((e) => MilestoneProgress.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  totalPoints: (json['total_points'] as num?)?.toInt() ?? 0,
  totalAchieved: (json['total_achieved'] as num?)?.toInt() ?? 0,
  nextMilestone: json['next_milestone'] == null
      ? null
      : MilestoneProgress.fromJson(
          json['next_milestone'] as Map<String, dynamic>,
        ),
  uncelebrated:
      (json['uncelebrated'] as List<dynamic>?)
          ?.map((e) => UserMilestone.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$MilestonesResponseToJson(MilestonesResponse instance) =>
    <String, dynamic>{
      'achieved': instance.achieved,
      'upcoming': instance.upcoming,
      'total_points': instance.totalPoints,
      'total_achieved': instance.totalAchieved,
      'next_milestone': instance.nextMilestone,
      'uncelebrated': instance.uncelebrated,
    };

ROIMetrics _$ROIMetricsFromJson(Map<String, dynamic> json) => ROIMetrics(
  userId: json['user_id'] as String,
  totalWorkoutsCompleted:
      (json['total_workouts_completed'] as num?)?.toInt() ?? 0,
  totalExercisesCompleted:
      (json['total_exercises_completed'] as num?)?.toInt() ?? 0,
  totalSetsCompleted: (json['total_sets_completed'] as num?)?.toInt() ?? 0,
  totalRepsCompleted: (json['total_reps_completed'] as num?)?.toInt() ?? 0,
  totalWorkoutTimeSeconds:
      (json['total_workout_time_seconds'] as num?)?.toInt() ?? 0,
  totalWorkoutTimeHours:
      (json['total_workout_time_hours'] as num?)?.toDouble() ?? 0,
  totalActiveTimeSeconds:
      (json['total_active_time_seconds'] as num?)?.toInt() ?? 0,
  averageWorkoutDurationSeconds:
      (json['average_workout_duration_seconds'] as num?)?.toInt() ?? 0,
  averageWorkoutDurationMinutes:
      (json['average_workout_duration_minutes'] as num?)?.toInt() ?? 0,
  totalWeightLiftedLbs:
      (json['total_weight_lifted_lbs'] as num?)?.toDouble() ?? 0,
  totalWeightLiftedKg:
      (json['total_weight_lifted_kg'] as num?)?.toDouble() ?? 0,
  estimatedCaloriesBurned:
      (json['estimated_calories_burned'] as num?)?.toInt() ?? 0,
  strengthIncreasePercentage:
      (json['strength_increase_percentage'] as num?)?.toDouble() ?? 0,
  prsAchievedCount: (json['prs_achieved_count'] as num?)?.toInt() ?? 0,
  currentStreakDays: (json['current_streak_days'] as num?)?.toInt() ?? 0,
  longestStreakDays: (json['longest_streak_days'] as num?)?.toInt() ?? 0,
  firstWorkoutDate: json['first_workout_date'] == null
      ? null
      : DateTime.parse(json['first_workout_date'] as String),
  lastWorkoutDate: json['last_workout_date'] == null
      ? null
      : DateTime.parse(json['last_workout_date'] as String),
  journeyDays: (json['journey_days'] as num?)?.toInt() ?? 0,
  workoutsThisWeek: (json['workouts_this_week'] as num?)?.toInt() ?? 0,
  workoutsThisMonth: (json['workouts_this_month'] as num?)?.toInt() ?? 0,
  averageWorkoutsPerWeek:
      (json['average_workouts_per_week'] as num?)?.toDouble() ?? 0,
  strengthSummary: json['strength_summary'] as String? ?? '',
  journeySummary: json['journey_summary'] as String? ?? '',
);

Map<String, dynamic> _$ROIMetricsToJson(
  ROIMetrics instance,
) => <String, dynamic>{
  'user_id': instance.userId,
  'total_workouts_completed': instance.totalWorkoutsCompleted,
  'total_exercises_completed': instance.totalExercisesCompleted,
  'total_sets_completed': instance.totalSetsCompleted,
  'total_reps_completed': instance.totalRepsCompleted,
  'total_workout_time_seconds': instance.totalWorkoutTimeSeconds,
  'total_workout_time_hours': instance.totalWorkoutTimeHours,
  'total_active_time_seconds': instance.totalActiveTimeSeconds,
  'average_workout_duration_seconds': instance.averageWorkoutDurationSeconds,
  'average_workout_duration_minutes': instance.averageWorkoutDurationMinutes,
  'total_weight_lifted_lbs': instance.totalWeightLiftedLbs,
  'total_weight_lifted_kg': instance.totalWeightLiftedKg,
  'estimated_calories_burned': instance.estimatedCaloriesBurned,
  'strength_increase_percentage': instance.strengthIncreasePercentage,
  'prs_achieved_count': instance.prsAchievedCount,
  'current_streak_days': instance.currentStreakDays,
  'longest_streak_days': instance.longestStreakDays,
  'first_workout_date': instance.firstWorkoutDate?.toIso8601String(),
  'last_workout_date': instance.lastWorkoutDate?.toIso8601String(),
  'journey_days': instance.journeyDays,
  'workouts_this_week': instance.workoutsThisWeek,
  'workouts_this_month': instance.workoutsThisMonth,
  'average_workouts_per_week': instance.averageWorkoutsPerWeek,
  'strength_summary': instance.strengthSummary,
  'journey_summary': instance.journeySummary,
};

ROISummary _$ROISummaryFromJson(Map<String, dynamic> json) => ROISummary(
  totalWorkouts: (json['total_workouts'] as num?)?.toInt() ?? 0,
  totalHoursInvested: (json['total_hours_invested'] as num?)?.toDouble() ?? 0,
  estimatedCaloriesBurned:
      (json['estimated_calories_burned'] as num?)?.toInt() ?? 0,
  totalWeightLifted: json['total_weight_lifted'] as String? ?? '',
  strengthIncreaseText: json['strength_increase_text'] as String? ?? '',
  prsCount: (json['prs_count'] as num?)?.toInt() ?? 0,
  currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
  journeyDays: (json['journey_days'] as num?)?.toInt() ?? 0,
  headline: json['headline'] as String? ?? 'Your Fitness Journey',
  motivationalMessage: json['motivational_message'] as String? ?? '',
);

Map<String, dynamic> _$ROISummaryToJson(ROISummary instance) =>
    <String, dynamic>{
      'total_workouts': instance.totalWorkouts,
      'total_hours_invested': instance.totalHoursInvested,
      'estimated_calories_burned': instance.estimatedCaloriesBurned,
      'total_weight_lifted': instance.totalWeightLifted,
      'strength_increase_text': instance.strengthIncreaseText,
      'prs_count': instance.prsCount,
      'current_streak': instance.currentStreak,
      'journey_days': instance.journeyDays,
      'headline': instance.headline,
      'motivational_message': instance.motivationalMessage,
    };

NewMilestoneAchieved _$NewMilestoneAchievedFromJson(
  Map<String, dynamic> json,
) => NewMilestoneAchieved(
  milestoneId: json['milestone_id'] as String,
  milestoneName: json['milestone_name'] as String,
  milestoneIcon: json['milestone_icon'] as String?,
  milestoneTier:
      $enumDecodeNullable(_$MilestoneTierEnumMap, json['milestone_tier']) ??
      MilestoneTier.bronze,
  points: (json['points'] as num?)?.toInt() ?? 0,
  shareMessage: json['share_message'] as String?,
  achievedAt: DateTime.parse(json['achieved_at'] as String),
);

Map<String, dynamic> _$NewMilestoneAchievedToJson(
  NewMilestoneAchieved instance,
) => <String, dynamic>{
  'milestone_id': instance.milestoneId,
  'milestone_name': instance.milestoneName,
  'milestone_icon': instance.milestoneIcon,
  'milestone_tier': _$MilestoneTierEnumMap[instance.milestoneTier]!,
  'points': instance.points,
  'share_message': instance.shareMessage,
  'achieved_at': instance.achievedAt.toIso8601String(),
};

MilestoneCheckResult _$MilestoneCheckResultFromJson(
  Map<String, dynamic> json,
) => MilestoneCheckResult(
  newMilestones:
      (json['new_milestones'] as List<dynamic>?)
          ?.map((e) => NewMilestoneAchieved.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  totalNewPoints: (json['total_new_points'] as num?)?.toInt() ?? 0,
  roiUpdated: json['roi_updated'] as bool? ?? false,
);

Map<String, dynamic> _$MilestoneCheckResultToJson(
  MilestoneCheckResult instance,
) => <String, dynamic>{
  'new_milestones': instance.newMilestones,
  'total_new_points': instance.totalNewPoints,
  'roi_updated': instance.roiUpdated,
};
