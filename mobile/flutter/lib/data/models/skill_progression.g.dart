// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skill_progression.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProgressionChain _$ProgressionChainFromJson(Map<String, dynamic> json) =>
    ProgressionChain(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      icon: json['icon'] as String?,
      difficultyStart: (json['difficulty_start'] as num?)?.toInt() ?? 1,
      difficultyEnd: (json['difficulty_end'] as num?)?.toInt() ?? 10,
      estimatedWeeks: (json['estimated_weeks'] as num?)?.toInt(),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      steps: (json['steps'] as List<dynamic>?)
          ?.map((e) => ProgressionStep.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ProgressionChainToJson(ProgressionChain instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'category': instance.category,
      'icon': instance.icon,
      'difficulty_start': instance.difficultyStart,
      'difficulty_end': instance.difficultyEnd,
      'estimated_weeks': instance.estimatedWeeks,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'steps': instance.steps,
    };

ProgressionStep _$ProgressionStepFromJson(Map<String, dynamic> json) =>
    ProgressionStep(
      id: json['id'] as String,
      chainId: json['chain_id'] as String,
      exerciseName: json['exercise_name'] as String,
      exerciseId: json['exercise_id'] as String?,
      stepOrder: (json['step_order'] as num).toInt(),
      difficultyLevel: (json['difficulty_level'] as num).toInt(),
      prerequisites: json['prerequisites'] as String?,
      unlockCriteria: json['unlock_criteria'] as Map<String, dynamic>?,
      tips: json['tips'] as String?,
      videoUrl: json['video_url'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      targetReps: (json['target_reps'] as num?)?.toInt(),
      targetSets: (json['target_sets'] as num?)?.toInt(),
      targetHoldSeconds: (json['target_hold_seconds'] as num?)?.toInt(),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$ProgressionStepToJson(ProgressionStep instance) =>
    <String, dynamic>{
      'id': instance.id,
      'chain_id': instance.chainId,
      'exercise_name': instance.exerciseName,
      'exercise_id': instance.exerciseId,
      'step_order': instance.stepOrder,
      'difficulty_level': instance.difficultyLevel,
      'prerequisites': instance.prerequisites,
      'unlock_criteria': instance.unlockCriteria,
      'tips': instance.tips,
      'video_url': instance.videoUrl,
      'thumbnail_url': instance.thumbnailUrl,
      'target_reps': instance.targetReps,
      'target_sets': instance.targetSets,
      'target_hold_seconds': instance.targetHoldSeconds,
      'created_at': instance.createdAt?.toIso8601String(),
    };

UserSkillProgress _$UserSkillProgressFromJson(Map<String, dynamic> json) =>
    UserSkillProgress(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      chainId: json['chain_id'] as String,
      currentStepOrder: (json['current_step_order'] as num?)?.toInt() ?? 1,
      unlockedSteps:
          (json['unlocked_steps'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [1],
      attemptsAtCurrent: (json['attempts_at_current'] as num?)?.toInt() ?? 0,
      bestRepsAtCurrent: (json['best_reps_at_current'] as num?)?.toInt() ?? 0,
      bestHoldSeconds: (json['best_hold_seconds'] as num?)?.toInt(),
      lastPracticedAt: json['last_practiced_at'] == null
          ? null
          : DateTime.parse(json['last_practiced_at'] as String),
      startedAt: json['started_at'] == null
          ? null
          : DateTime.parse(json['started_at'] as String),
      completedAt: json['completed_at'] == null
          ? null
          : DateTime.parse(json['completed_at'] as String),
      chain: json['chain'] == null
          ? null
          : ProgressionChain.fromJson(json['chain'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserSkillProgressToJson(UserSkillProgress instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'chain_id': instance.chainId,
      'current_step_order': instance.currentStepOrder,
      'unlocked_steps': instance.unlockedSteps,
      'attempts_at_current': instance.attemptsAtCurrent,
      'best_reps_at_current': instance.bestRepsAtCurrent,
      'best_hold_seconds': instance.bestHoldSeconds,
      'last_practiced_at': instance.lastPracticedAt?.toIso8601String(),
      'started_at': instance.startedAt?.toIso8601String(),
      'completed_at': instance.completedAt?.toIso8601String(),
      'chain': instance.chain,
    };

ProgressionAttempt _$ProgressionAttemptFromJson(Map<String, dynamic> json) =>
    ProgressionAttempt(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      chainId: json['chain_id'] as String,
      stepId: json['step_id'] as String,
      stepOrder: (json['step_order'] as num).toInt(),
      repsCompleted: (json['reps_completed'] as num?)?.toInt(),
      setsCompleted: (json['sets_completed'] as num?)?.toInt(),
      holdSeconds: (json['hold_seconds'] as num?)?.toInt(),
      wasSuccessful: json['was_successful'] as bool? ?? false,
      unlockedNext: json['unlocked_next'] as bool? ?? false,
      notes: json['notes'] as String?,
      attemptedAt: DateTime.parse(json['attempted_at'] as String),
    );

Map<String, dynamic> _$ProgressionAttemptToJson(ProgressionAttempt instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'chain_id': instance.chainId,
      'step_id': instance.stepId,
      'step_order': instance.stepOrder,
      'reps_completed': instance.repsCompleted,
      'sets_completed': instance.setsCompleted,
      'hold_seconds': instance.holdSeconds,
      'was_successful': instance.wasSuccessful,
      'unlocked_next': instance.unlockedNext,
      'notes': instance.notes,
      'attempted_at': instance.attemptedAt.toIso8601String(),
    };

SkillProgressionSummary _$SkillProgressionSummaryFromJson(
  Map<String, dynamic> json,
) => SkillProgressionSummary(
  totalChainsStarted: (json['total_chains_started'] as num?)?.toInt() ?? 0,
  totalChainsCompleted: (json['total_chains_completed'] as num?)?.toInt() ?? 0,
  totalStepsUnlocked: (json['total_steps_unlocked'] as num?)?.toInt() ?? 0,
  totalAttempts: (json['total_attempts'] as num?)?.toInt() ?? 0,
  currentProgressions:
      (json['current_progressions'] as List<dynamic>?)
          ?.map((e) => UserSkillProgress.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  recentlyPracticed:
      (json['recently_practiced'] as List<dynamic>?)
          ?.map((e) => UserSkillProgress.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$SkillProgressionSummaryToJson(
  SkillProgressionSummary instance,
) => <String, dynamic>{
  'total_chains_started': instance.totalChainsStarted,
  'total_chains_completed': instance.totalChainsCompleted,
  'total_steps_unlocked': instance.totalStepsUnlocked,
  'total_attempts': instance.totalAttempts,
  'current_progressions': instance.currentProgressions,
  'recently_practiced': instance.recentlyPracticed,
};
