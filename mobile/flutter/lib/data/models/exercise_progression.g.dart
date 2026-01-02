// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_progression.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExerciseVariantChain _$ExerciseVariantChainFromJson(
  Map<String, dynamic> json,
) => ExerciseVariantChain(
  id: json['id'] as String,
  baseExerciseName: json['base_exercise_name'] as String,
  muscleGroup: json['muscle_group'] as String,
  chainType: $enumDecode(_$ChainTypeEnumMap, json['chain_type']),
  description: json['description'] as String?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
  variants: (json['variants'] as List<dynamic>?)
      ?.map((e) => ExerciseVariant.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ExerciseVariantChainToJson(
  ExerciseVariantChain instance,
) => <String, dynamic>{
  'id': instance.id,
  'base_exercise_name': instance.baseExerciseName,
  'muscle_group': instance.muscleGroup,
  'chain_type': _$ChainTypeEnumMap[instance.chainType]!,
  'description': instance.description,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
  'variants': instance.variants,
};

const _$ChainTypeEnumMap = {
  ChainType.leverage: 'leverage',
  ChainType.load: 'load',
  ChainType.rom: 'rom',
  ChainType.stability: 'stability',
  ChainType.unilateral: 'unilateral',
  ChainType.tempo: 'tempo',
};

ExerciseVariant _$ExerciseVariantFromJson(Map<String, dynamic> json) =>
    ExerciseVariant(
      id: json['id'] as String,
      chainId: json['chain_id'] as String,
      exerciseName: json['exercise_name'] as String,
      exerciseId: json['exercise_id'] as String?,
      difficultyLevel: (json['difficulty_level'] as num).toInt(),
      stepOrder: (json['step_order'] as num).toInt(),
      unlockCriteria: json['unlock_criteria'] as Map<String, dynamic>?,
      prerequisites: json['prerequisites'] as String?,
      tips: json['tips'] as String?,
      leverageDescription: json['leverage_description'] as String?,
      videoUrl: json['video_url'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$ExerciseVariantToJson(ExerciseVariant instance) =>
    <String, dynamic>{
      'id': instance.id,
      'chain_id': instance.chainId,
      'exercise_name': instance.exerciseName,
      'exercise_id': instance.exerciseId,
      'difficulty_level': instance.difficultyLevel,
      'step_order': instance.stepOrder,
      'unlock_criteria': instance.unlockCriteria,
      'prerequisites': instance.prerequisites,
      'tips': instance.tips,
      'leverage_description': instance.leverageDescription,
      'video_url': instance.videoUrl,
      'thumbnail_url': instance.thumbnailUrl,
      'created_at': instance.createdAt?.toIso8601String(),
    };

UserExerciseMastery _$UserExerciseMasteryFromJson(Map<String, dynamic> json) =>
    UserExerciseMastery(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      exerciseName: json['exercise_name'] as String,
      currentMaxReps: (json['current_max_reps'] as num?)?.toInt() ?? 0,
      currentMaxWeightKg: (json['current_max_weight_kg'] as num?)?.toDouble(),
      consecutiveEasySessions:
          (json['consecutive_easy_sessions'] as num?)?.toInt() ?? 0,
      totalSessions: (json['total_sessions'] as num?)?.toInt() ?? 0,
      avgDifficultyRating: (json['avg_difficulty_rating'] as num?)?.toDouble(),
      readyForProgression: json['ready_for_progression'] as bool? ?? false,
      suggestedNextVariant: json['suggested_next_variant'] as String?,
      suggestedNextVariantName: json['suggested_next_variant_name'] as String?,
      lastPerformedAt: json['last_performed_at'] == null
          ? null
          : DateTime.parse(json['last_performed_at'] as String),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$UserExerciseMasteryToJson(
  UserExerciseMastery instance,
) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'exercise_name': instance.exerciseName,
  'current_max_reps': instance.currentMaxReps,
  'current_max_weight_kg': instance.currentMaxWeightKg,
  'consecutive_easy_sessions': instance.consecutiveEasySessions,
  'total_sessions': instance.totalSessions,
  'avg_difficulty_rating': instance.avgDifficultyRating,
  'ready_for_progression': instance.readyForProgression,
  'suggested_next_variant': instance.suggestedNextVariant,
  'suggested_next_variant_name': instance.suggestedNextVariantName,
  'last_performed_at': instance.lastPerformedAt?.toIso8601String(),
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
};

UserRepPreferences _$UserRepPreferencesFromJson(Map<String, dynamic> json) =>
    UserRepPreferences(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      trainingFocus:
          $enumDecodeNullable(_$TrainingFocusEnumMap, json['training_focus']) ??
          TrainingFocus.hypertrophy,
      preferredMinReps: (json['preferred_min_reps'] as num?)?.toInt() ?? 8,
      preferredMaxReps: (json['preferred_max_reps'] as num?)?.toInt() ?? 12,
      avoidHighReps: json['avoid_high_reps'] as bool? ?? false,
      progressionStyle:
          $enumDecodeNullable(
            _$ProgressionStyleEnumMap,
            json['progression_style'],
          ) ??
          ProgressionStyle.balanced,
      autoSuggestProgressions:
          json['auto_suggest_progressions'] as bool? ?? true,
      maxSetsPerExercise: (json['max_sets_per_exercise'] as num?)?.toInt() ?? 4,
      minSetsPerExercise: (json['min_sets_per_exercise'] as num?)?.toInt() ?? 2,
      enforceRepCeiling: json['enforce_rep_ceiling'] as bool? ?? false,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$UserRepPreferencesToJson(
  UserRepPreferences instance,
) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'training_focus': _$TrainingFocusEnumMap[instance.trainingFocus]!,
  'preferred_min_reps': instance.preferredMinReps,
  'preferred_max_reps': instance.preferredMaxReps,
  'avoid_high_reps': instance.avoidHighReps,
  'progression_style': _$ProgressionStyleEnumMap[instance.progressionStyle]!,
  'auto_suggest_progressions': instance.autoSuggestProgressions,
  'max_sets_per_exercise': instance.maxSetsPerExercise,
  'min_sets_per_exercise': instance.minSetsPerExercise,
  'enforce_rep_ceiling': instance.enforceRepCeiling,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
};

const _$TrainingFocusEnumMap = {
  TrainingFocus.strength: 'strength',
  TrainingFocus.hypertrophy: 'hypertrophy',
  TrainingFocus.endurance: 'endurance',
  TrainingFocus.power: 'power',
};

const _$ProgressionStyleEnumMap = {
  ProgressionStyle.leverageFirst: 'leverage_first',
  ProgressionStyle.loadFirst: 'load_first',
  ProgressionStyle.balanced: 'balanced',
};

ProgressionSuggestion _$ProgressionSuggestionFromJson(
  Map<String, dynamic> json,
) => ProgressionSuggestion(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  currentExercise: json['current_exercise'] as String,
  suggestedExercise: json['suggested_exercise'] as String,
  chainId: json['chain_id'] as String?,
  chainType: $enumDecodeNullable(_$ChainTypeEnumMap, json['chain_type']),
  difficultyIncrease: (json['difficulty_increase'] as num?)?.toInt() ?? 1,
  reason: json['reason'] as String,
  leverageExplanation: json['leverage_explanation'] as String?,
  currentDifficulty: (json['current_difficulty'] as num?)?.toInt() ?? 5,
  suggestedDifficulty: (json['suggested_difficulty'] as num?)?.toInt() ?? 6,
  isAccepted: json['is_accepted'] as bool? ?? false,
  isDismissed: json['is_dismissed'] as bool? ?? false,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  acceptedAt: json['accepted_at'] == null
      ? null
      : DateTime.parse(json['accepted_at'] as String),
);

Map<String, dynamic> _$ProgressionSuggestionToJson(
  ProgressionSuggestion instance,
) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'current_exercise': instance.currentExercise,
  'suggested_exercise': instance.suggestedExercise,
  'chain_id': instance.chainId,
  'chain_type': _$ChainTypeEnumMap[instance.chainType],
  'difficulty_increase': instance.difficultyIncrease,
  'reason': instance.reason,
  'leverage_explanation': instance.leverageExplanation,
  'current_difficulty': instance.currentDifficulty,
  'suggested_difficulty': instance.suggestedDifficulty,
  'is_accepted': instance.isAccepted,
  'is_dismissed': instance.isDismissed,
  'created_at': instance.createdAt?.toIso8601String(),
  'accepted_at': instance.acceptedAt?.toIso8601String(),
};
