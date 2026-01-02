import 'package:json_annotation/json_annotation.dart';

part 'exercise_progression.g.dart';

/// Types of progression chains based on leverage mechanics
enum ChainType {
  @JsonValue('leverage')
  leverage, // Body angle/position changes (e.g., incline to flat to decline)
  @JsonValue('load')
  load, // Weight/resistance increases
  @JsonValue('rom')
  rom, // Range of motion increases
  @JsonValue('stability')
  stability, // Stability decreases (e.g., bench to ball)
  @JsonValue('unilateral')
  unilateral, // Bilateral to unilateral
  @JsonValue('tempo')
  tempo, // Speed/time under tension changes
}

/// Training focus types that affect rep ranges
enum TrainingFocus {
  @JsonValue('strength')
  strength, // 1-5 reps, heavy weight
  @JsonValue('hypertrophy')
  hypertrophy, // 8-12 reps, moderate weight
  @JsonValue('endurance')
  endurance, // 15-25 reps, lighter weight
  @JsonValue('power')
  power, // 3-6 reps, explosive
}

/// Progression style preference
enum ProgressionStyle {
  @JsonValue('leverage_first')
  leverageFirst, // Progress leverage before adding weight
  @JsonValue('load_first')
  loadFirst, // Add weight before changing leverage
  @JsonValue('balanced')
  balanced, // AI decides based on context
}

/// Extension for TrainingFocus display names and descriptions
extension TrainingFocusExtension on TrainingFocus {
  String get displayName {
    switch (this) {
      case TrainingFocus.strength:
        return 'Strength';
      case TrainingFocus.hypertrophy:
        return 'Hypertrophy';
      case TrainingFocus.endurance:
        return 'Endurance';
      case TrainingFocus.power:
        return 'Power';
    }
  }

  String get description {
    switch (this) {
      case TrainingFocus.strength:
        return 'Heavy weights, low reps (1-5)';
      case TrainingFocus.hypertrophy:
        return 'Moderate weights, medium reps (8-12)';
      case TrainingFocus.endurance:
        return 'Lighter weights, high reps (15-25)';
      case TrainingFocus.power:
        return 'Explosive movements, low reps (3-6)';
    }
  }

  /// Get the typical rep range for this focus
  (int min, int max) get repRange {
    switch (this) {
      case TrainingFocus.strength:
        return (1, 5);
      case TrainingFocus.hypertrophy:
        return (8, 12);
      case TrainingFocus.endurance:
        return (15, 25);
      case TrainingFocus.power:
        return (3, 6);
    }
  }
}

/// Extension for ProgressionStyle display names
extension ProgressionStyleExtension on ProgressionStyle {
  String get displayName {
    switch (this) {
      case ProgressionStyle.leverageFirst:
        return 'Leverage First';
      case ProgressionStyle.loadFirst:
        return 'Load First';
      case ProgressionStyle.balanced:
        return 'Balanced (AI Decides)';
    }
  }

  String get description {
    switch (this) {
      case ProgressionStyle.leverageFirst:
        return 'Master harder positions before adding weight';
      case ProgressionStyle.loadFirst:
        return 'Add weight before changing exercise difficulty';
      case ProgressionStyle.balanced:
        return 'AI adapts based on your performance';
    }
  }
}

/// Extension for ChainType display names
extension ChainTypeExtension on ChainType {
  String get displayName {
    switch (this) {
      case ChainType.leverage:
        return 'Leverage';
      case ChainType.load:
        return 'Load';
      case ChainType.rom:
        return 'Range of Motion';
      case ChainType.stability:
        return 'Stability';
      case ChainType.unilateral:
        return 'Unilateral';
      case ChainType.tempo:
        return 'Tempo';
    }
  }
}

/// A chain of exercise variants that progressively increase in difficulty
@JsonSerializable()
class ExerciseVariantChain {
  final String id;
  @JsonKey(name: 'base_exercise_name')
  final String baseExerciseName;
  @JsonKey(name: 'muscle_group')
  final String muscleGroup;
  @JsonKey(name: 'chain_type')
  final ChainType chainType;
  final String? description;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  final List<ExerciseVariant>? variants;

  const ExerciseVariantChain({
    required this.id,
    required this.baseExerciseName,
    required this.muscleGroup,
    required this.chainType,
    this.description,
    this.createdAt,
    this.updatedAt,
    this.variants,
  });

  factory ExerciseVariantChain.fromJson(Map<String, dynamic> json) =>
      _$ExerciseVariantChainFromJson(json);
  Map<String, dynamic> toJson() => _$ExerciseVariantChainToJson(this);

  /// Get variant by step order
  ExerciseVariant? getVariantByOrder(int order) {
    return variants?.firstWhere(
      (v) => v.stepOrder == order,
      orElse: () => variants!.first,
    );
  }

  /// Get next variant after the given step order
  ExerciseVariant? getNextVariant(int currentOrder) {
    if (variants == null || variants!.isEmpty) return null;
    final sortedVariants = List<ExerciseVariant>.from(variants!)
      ..sort((a, b) => a.stepOrder.compareTo(b.stepOrder));

    for (final variant in sortedVariants) {
      if (variant.stepOrder > currentOrder) {
        return variant;
      }
    }
    return null;
  }

  /// Get total number of variants in the chain
  int get totalVariants => variants?.length ?? 0;
}

/// A single exercise variant within a progression chain
@JsonSerializable()
class ExerciseVariant {
  final String id;
  @JsonKey(name: 'chain_id')
  final String chainId;
  @JsonKey(name: 'exercise_name')
  final String exerciseName;
  @JsonKey(name: 'exercise_id')
  final String? exerciseId;
  @JsonKey(name: 'difficulty_level')
  final int difficultyLevel;
  @JsonKey(name: 'step_order')
  final int stepOrder;
  @JsonKey(name: 'unlock_criteria')
  final Map<String, dynamic>? unlockCriteria;
  final String? prerequisites;
  final String? tips;
  @JsonKey(name: 'leverage_description')
  final String? leverageDescription;
  @JsonKey(name: 'video_url')
  final String? videoUrl;
  @JsonKey(name: 'thumbnail_url')
  final String? thumbnailUrl;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  const ExerciseVariant({
    required this.id,
    required this.chainId,
    required this.exerciseName,
    this.exerciseId,
    required this.difficultyLevel,
    required this.stepOrder,
    this.unlockCriteria,
    this.prerequisites,
    this.tips,
    this.leverageDescription,
    this.videoUrl,
    this.thumbnailUrl,
    this.createdAt,
  });

  factory ExerciseVariant.fromJson(Map<String, dynamic> json) =>
      _$ExerciseVariantFromJson(json);
  Map<String, dynamic> toJson() => _$ExerciseVariantToJson(this);

  /// Get difficulty label
  String get difficultyLabel {
    if (difficultyLevel <= 2) return 'Beginner';
    if (difficultyLevel <= 4) return 'Easy';
    if (difficultyLevel <= 6) return 'Intermediate';
    if (difficultyLevel <= 8) return 'Advanced';
    return 'Expert';
  }

  /// Get unlock criteria display text
  String get unlockCriteriaText {
    if (unlockCriteria == null) return 'Complete previous variant';

    final parts = <String>[];
    final minReps = unlockCriteria!['min_reps'] as int?;
    final minSets = unlockCriteria!['min_sets'] as int?;
    final consecutiveSessions = unlockCriteria!['consecutive_sessions'] as int?;
    final minWeight = unlockCriteria!['min_weight_kg'] as num?;

    if (minSets != null && minReps != null) {
      parts.add('$minSets sets x $minReps reps');
    } else if (minReps != null) {
      parts.add('$minReps reps');
    }

    if (consecutiveSessions != null) {
      parts.add('$consecutiveSessions sessions');
    }

    if (minWeight != null) {
      parts.add('${minWeight.toStringAsFixed(1)} kg');
    }

    return parts.isEmpty ? 'Complete exercise' : parts.join(' for ');
  }
}

/// Tracks a user's mastery of a specific exercise
@JsonSerializable()
class UserExerciseMastery {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'exercise_name')
  final String exerciseName;
  @JsonKey(name: 'current_max_reps')
  final int currentMaxReps;
  @JsonKey(name: 'current_max_weight_kg')
  final double? currentMaxWeightKg;
  @JsonKey(name: 'consecutive_easy_sessions')
  final int consecutiveEasySessions;
  @JsonKey(name: 'total_sessions')
  final int totalSessions;
  @JsonKey(name: 'avg_difficulty_rating')
  final double? avgDifficultyRating;
  @JsonKey(name: 'ready_for_progression')
  final bool readyForProgression;
  @JsonKey(name: 'suggested_next_variant')
  final String? suggestedNextVariant;
  @JsonKey(name: 'suggested_next_variant_name')
  final String? suggestedNextVariantName;
  @JsonKey(name: 'last_performed_at')
  final DateTime? lastPerformedAt;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  const UserExerciseMastery({
    required this.id,
    required this.userId,
    required this.exerciseName,
    this.currentMaxReps = 0,
    this.currentMaxWeightKg,
    this.consecutiveEasySessions = 0,
    this.totalSessions = 0,
    this.avgDifficultyRating,
    this.readyForProgression = false,
    this.suggestedNextVariant,
    this.suggestedNextVariantName,
    this.lastPerformedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory UserExerciseMastery.fromJson(Map<String, dynamic> json) =>
      _$UserExerciseMasteryFromJson(json);
  Map<String, dynamic> toJson() => _$UserExerciseMasteryToJson(this);

  /// Get mastery level description
  String get masteryLevel {
    if (consecutiveEasySessions >= 5) return 'Mastered';
    if (consecutiveEasySessions >= 3) return 'Proficient';
    if (totalSessions >= 5) return 'Familiar';
    if (totalSessions >= 2) return 'Learning';
    return 'New';
  }

  /// Check if user should progress based on easy session count
  bool get shouldProgress => consecutiveEasySessions >= 3;
}

/// User's rep range preferences
@JsonSerializable()
class UserRepPreferences {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'training_focus')
  final TrainingFocus trainingFocus;
  @JsonKey(name: 'preferred_min_reps')
  final int preferredMinReps;
  @JsonKey(name: 'preferred_max_reps')
  final int preferredMaxReps;
  @JsonKey(name: 'avoid_high_reps')
  final bool avoidHighReps;
  @JsonKey(name: 'progression_style')
  final ProgressionStyle progressionStyle;
  @JsonKey(name: 'auto_suggest_progressions')
  final bool autoSuggestProgressions;
  @JsonKey(name: 'max_sets_per_exercise')
  final int maxSetsPerExercise;
  @JsonKey(name: 'min_sets_per_exercise')
  final int minSetsPerExercise;
  @JsonKey(name: 'enforce_rep_ceiling')
  final bool enforceRepCeiling;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  const UserRepPreferences({
    required this.id,
    required this.userId,
    this.trainingFocus = TrainingFocus.hypertrophy,
    this.preferredMinReps = 8,
    this.preferredMaxReps = 12,
    this.avoidHighReps = false,
    this.progressionStyle = ProgressionStyle.balanced,
    this.autoSuggestProgressions = true,
    this.maxSetsPerExercise = 4,
    this.minSetsPerExercise = 2,
    this.enforceRepCeiling = false,
    this.createdAt,
    this.updatedAt,
  });

  factory UserRepPreferences.fromJson(Map<String, dynamic> json) =>
      _$UserRepPreferencesFromJson(json);
  Map<String, dynamic> toJson() => _$UserRepPreferencesToJson(this);

  /// Create default preferences for a user
  factory UserRepPreferences.defaultFor(String userId) {
    return UserRepPreferences(
      id: '',
      userId: userId,
      trainingFocus: TrainingFocus.hypertrophy,
      preferredMinReps: 8,
      preferredMaxReps: 12,
      avoidHighReps: false,
      progressionStyle: ProgressionStyle.balanced,
      autoSuggestProgressions: true,
      maxSetsPerExercise: 4,
      minSetsPerExercise: 2,
      enforceRepCeiling: false,
    );
  }

  /// Copy with updated values
  UserRepPreferences copyWith({
    String? id,
    String? userId,
    TrainingFocus? trainingFocus,
    int? preferredMinReps,
    int? preferredMaxReps,
    bool? avoidHighReps,
    ProgressionStyle? progressionStyle,
    bool? autoSuggestProgressions,
    int? maxSetsPerExercise,
    int? minSetsPerExercise,
    bool? enforceRepCeiling,
  }) {
    return UserRepPreferences(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      trainingFocus: trainingFocus ?? this.trainingFocus,
      preferredMinReps: preferredMinReps ?? this.preferredMinReps,
      preferredMaxReps: preferredMaxReps ?? this.preferredMaxReps,
      avoidHighReps: avoidHighReps ?? this.avoidHighReps,
      progressionStyle: progressionStyle ?? this.progressionStyle,
      autoSuggestProgressions: autoSuggestProgressions ?? this.autoSuggestProgressions,
      maxSetsPerExercise: maxSetsPerExercise ?? this.maxSetsPerExercise,
      minSetsPerExercise: minSetsPerExercise ?? this.minSetsPerExercise,
      enforceRepCeiling: enforceRepCeiling ?? this.enforceRepCeiling,
    );
  }

  /// Get rep range display string
  String get repRangeDisplay => '$preferredMinReps-$preferredMaxReps reps';

  /// Get sets range display string
  String get setsRangeDisplay => '$minSetsPerExercise-$maxSetsPerExercise sets';

  /// Get a summary of workout configuration
  String get workoutSummary =>
      'Your workouts will have $minSetsPerExercise-$maxSetsPerExercise sets of $preferredMinReps-$preferredMaxReps reps per exercise';
}

/// A progression suggestion to show to the user
@JsonSerializable()
class ProgressionSuggestion {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'current_exercise')
  final String currentExercise;
  @JsonKey(name: 'suggested_exercise')
  final String suggestedExercise;
  @JsonKey(name: 'chain_id')
  final String? chainId;
  @JsonKey(name: 'chain_type')
  final ChainType? chainType;
  @JsonKey(name: 'difficulty_increase')
  final int difficultyIncrease;
  final String reason;
  @JsonKey(name: 'leverage_explanation')
  final String? leverageExplanation;
  @JsonKey(name: 'current_difficulty')
  final int currentDifficulty;
  @JsonKey(name: 'suggested_difficulty')
  final int suggestedDifficulty;
  @JsonKey(name: 'is_accepted')
  final bool isAccepted;
  @JsonKey(name: 'is_dismissed')
  final bool isDismissed;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'accepted_at')
  final DateTime? acceptedAt;

  const ProgressionSuggestion({
    required this.id,
    required this.userId,
    required this.currentExercise,
    required this.suggestedExercise,
    this.chainId,
    this.chainType,
    this.difficultyIncrease = 1,
    required this.reason,
    this.leverageExplanation,
    this.currentDifficulty = 5,
    this.suggestedDifficulty = 6,
    this.isAccepted = false,
    this.isDismissed = false,
    this.createdAt,
    this.acceptedAt,
  });

  factory ProgressionSuggestion.fromJson(Map<String, dynamic> json) =>
      _$ProgressionSuggestionFromJson(json);
  Map<String, dynamic> toJson() => _$ProgressionSuggestionToJson(this);

  /// Check if this suggestion is still pending
  bool get isPending => !isAccepted && !isDismissed;
}
