import 'package:json_annotation/json_annotation.dart';

part 'senior_settings.g.dart';

/// User preferences for senior fitness and recovery settings
@JsonSerializable()
class SeniorRecoverySettings {
  final String? id;
  @JsonKey(name: 'user_id')
  final String? userId;

  // Recovery settings
  @JsonKey(name: 'recovery_multiplier')
  final double recoveryMultiplier;
  @JsonKey(name: 'min_rest_days_between_workouts')
  final int minRestDaysBetweenWorkouts;
  @JsonKey(name: 'max_workout_days_per_week')
  final int maxWorkoutDaysPerWeek;

  // Intensity caps
  @JsonKey(name: 'max_intensity_level')
  final String maxIntensityLevel;
  @JsonKey(name: 'max_rpe')
  final int maxRpe;
  @JsonKey(name: 'reduce_volume_percentage')
  final int reduceVolumePercentage;

  // Warmup and cooldown
  @JsonKey(name: 'warmup_duration_minutes')
  final int warmupDurationMinutes;
  @JsonKey(name: 'cooldown_duration_minutes')
  final int cooldownDurationMinutes;
  @JsonKey(name: 'extended_warmup_enabled')
  final bool extendedWarmupEnabled;

  // Low-impact preferences
  @JsonKey(name: 'prefer_low_impact')
  final bool preferLowImpact;
  @JsonKey(name: 'avoid_high_impact_cardio')
  final bool avoidHighImpactCardio;
  @JsonKey(name: 'prefer_seated_exercises')
  final bool preferSeatedExercises;
  @JsonKey(name: 'avoid_jumping_movements')
  final bool avoidJumpingMovements;
  @JsonKey(name: 'avoid_overhead_pressing')
  final bool avoidOverheadPressing;

  // Mobility and balance settings
  @JsonKey(name: 'include_mobility_work')
  final bool includeMobilityWork;
  @JsonKey(name: 'include_balance_exercises')
  final bool includeBalanceExercises;
  @JsonKey(name: 'mobility_focus_areas')
  final List<String> mobilityFocusAreas;
  @JsonKey(name: 'balance_exercise_frequency')
  final String balanceExerciseFrequency;

  // Joint considerations
  @JsonKey(name: 'joint_considerations')
  final List<String> jointConsiderations;
  @JsonKey(name: 'avoid_exercise_patterns')
  final List<String> avoidExercisePatterns;

  // Rest and recovery
  @JsonKey(name: 'rest_between_sets_multiplier')
  final double restBetweenSetsMultiplier;
  @JsonKey(name: 'require_full_recovery')
  final bool requireFullRecovery;

  // Timestamps
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  const SeniorRecoverySettings({
    this.id,
    this.userId,
    this.recoveryMultiplier = 1.5,
    this.minRestDaysBetweenWorkouts = 1,
    this.maxWorkoutDaysPerWeek = 4,
    this.maxIntensityLevel = 'moderate',
    this.maxRpe = 7,
    this.reduceVolumePercentage = 20,
    this.warmupDurationMinutes = 10,
    this.cooldownDurationMinutes = 10,
    this.extendedWarmupEnabled = true,
    this.preferLowImpact = true,
    this.avoidHighImpactCardio = true,
    this.preferSeatedExercises = false,
    this.avoidJumpingMovements = true,
    this.avoidOverheadPressing = false,
    this.includeMobilityWork = true,
    this.includeBalanceExercises = true,
    this.mobilityFocusAreas = const ['hips', 'shoulders', 'spine'],
    this.balanceExerciseFrequency = 'every_workout',
    this.jointConsiderations = const [],
    this.avoidExercisePatterns = const [],
    this.restBetweenSetsMultiplier = 1.5,
    this.requireFullRecovery = true,
    this.createdAt,
    this.updatedAt,
  });

  factory SeniorRecoverySettings.fromJson(Map<String, dynamic> json) =>
      _$SeniorRecoverySettingsFromJson(json);
  Map<String, dynamic> toJson() => _$SeniorRecoverySettingsToJson(this);

  factory SeniorRecoverySettings.defaultSettings() {
    return const SeniorRecoverySettings();
  }

  factory SeniorRecoverySettings.conservative() {
    return const SeniorRecoverySettings(
      recoveryMultiplier: 2.0,
      minRestDaysBetweenWorkouts: 2,
      maxWorkoutDaysPerWeek: 3,
      maxIntensityLevel: 'light',
      maxRpe: 5,
      reduceVolumePercentage: 30,
      warmupDurationMinutes: 15,
      cooldownDurationMinutes: 15,
      preferSeatedExercises: true,
      avoidOverheadPressing: true,
      restBetweenSetsMultiplier: 2.0,
    );
  }

  SeniorRecoverySettings copyWith({
    String? id,
    String? userId,
    double? recoveryMultiplier,
    int? minRestDaysBetweenWorkouts,
    int? maxWorkoutDaysPerWeek,
    String? maxIntensityLevel,
    int? maxRpe,
    int? reduceVolumePercentage,
    int? warmupDurationMinutes,
    int? cooldownDurationMinutes,
    bool? extendedWarmupEnabled,
    bool? preferLowImpact,
    bool? avoidHighImpactCardio,
    bool? preferSeatedExercises,
    bool? avoidJumpingMovements,
    bool? avoidOverheadPressing,
    bool? includeMobilityWork,
    bool? includeBalanceExercises,
    List<String>? mobilityFocusAreas,
    String? balanceExerciseFrequency,
    List<String>? jointConsiderations,
    List<String>? avoidExercisePatterns,
    double? restBetweenSetsMultiplier,
    bool? requireFullRecovery,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SeniorRecoverySettings(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      recoveryMultiplier: recoveryMultiplier ?? this.recoveryMultiplier,
      minRestDaysBetweenWorkouts: minRestDaysBetweenWorkouts ?? this.minRestDaysBetweenWorkouts,
      maxWorkoutDaysPerWeek: maxWorkoutDaysPerWeek ?? this.maxWorkoutDaysPerWeek,
      maxIntensityLevel: maxIntensityLevel ?? this.maxIntensityLevel,
      maxRpe: maxRpe ?? this.maxRpe,
      reduceVolumePercentage: reduceVolumePercentage ?? this.reduceVolumePercentage,
      warmupDurationMinutes: warmupDurationMinutes ?? this.warmupDurationMinutes,
      cooldownDurationMinutes: cooldownDurationMinutes ?? this.cooldownDurationMinutes,
      extendedWarmupEnabled: extendedWarmupEnabled ?? this.extendedWarmupEnabled,
      preferLowImpact: preferLowImpact ?? this.preferLowImpact,
      avoidHighImpactCardio: avoidHighImpactCardio ?? this.avoidHighImpactCardio,
      preferSeatedExercises: preferSeatedExercises ?? this.preferSeatedExercises,
      avoidJumpingMovements: avoidJumpingMovements ?? this.avoidJumpingMovements,
      avoidOverheadPressing: avoidOverheadPressing ?? this.avoidOverheadPressing,
      includeMobilityWork: includeMobilityWork ?? this.includeMobilityWork,
      includeBalanceExercises: includeBalanceExercises ?? this.includeBalanceExercises,
      mobilityFocusAreas: mobilityFocusAreas ?? this.mobilityFocusAreas,
      balanceExerciseFrequency: balanceExerciseFrequency ?? this.balanceExerciseFrequency,
      jointConsiderations: jointConsiderations ?? this.jointConsiderations,
      avoidExercisePatterns: avoidExercisePatterns ?? this.avoidExercisePatterns,
      restBetweenSetsMultiplier: restBetweenSetsMultiplier ?? this.restBetweenSetsMultiplier,
      requireFullRecovery: requireFullRecovery ?? this.requireFullRecovery,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get intensityDisplayName {
    switch (maxIntensityLevel.toLowerCase()) {
      case 'very_light':
        return 'Very Light';
      case 'light':
        return 'Light';
      case 'moderate':
        return 'Moderate';
      case 'vigorous':
        return 'Vigorous';
      default:
        return maxIntensityLevel;
    }
  }

  String get recoveryDescription {
    return '${recoveryMultiplier}x recovery time, $minRestDaysBetweenWorkouts+ rest days';
  }

  bool get hasLowImpactPreferences {
    return preferLowImpact || avoidHighImpactCardio || avoidJumpingMovements;
  }

  String get mobilityAreasDisplay {
    if (mobilityFocusAreas.isEmpty) return 'None specified';
    return mobilityFocusAreas.join(', ');
  }
}

@JsonSerializable()
class RecoveryStatus {
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'is_ready')
  final bool isReady;
  @JsonKey(name: 'days_since_last_workout')
  final int daysSinceLastWorkout;
  @JsonKey(name: 'days_until_ready')
  final int daysUntilReady;
  final String recommendation;
  @JsonKey(name: 'recovery_percentage')
  final double recoveryPercentage;
  @JsonKey(name: 'last_workout_date')
  final DateTime? lastWorkoutDate;
  @JsonKey(name: 'last_workout_intensity')
  final String? lastWorkoutIntensity;
  @JsonKey(name: 'fatigue_indicators')
  final List<String> fatigueIndicators;
  @JsonKey(name: 'recommended_workout_type')
  final String? recommendedWorkoutType;
  @JsonKey(name: 'suggested_intensity')
  final String? suggestedIntensity;
  @JsonKey(name: 'checked_at')
  final DateTime checkedAt;

  const RecoveryStatus({
    required this.userId,
    required this.isReady,
    this.daysSinceLastWorkout = 0,
    this.daysUntilReady = 0,
    required this.recommendation,
    this.recoveryPercentage = 100.0,
    this.lastWorkoutDate,
    this.lastWorkoutIntensity,
    this.fatigueIndicators = const [],
    this.recommendedWorkoutType,
    this.suggestedIntensity,
    required this.checkedAt,
  });

  factory RecoveryStatus.fromJson(Map<String, dynamic> json) =>
      _$RecoveryStatusFromJson(json);
  Map<String, dynamic> toJson() => _$RecoveryStatusToJson(this);

  String get statusColor {
    if (recoveryPercentage >= 90) return '#4CAF50';
    if (recoveryPercentage >= 70) return '#8BC34A';
    if (recoveryPercentage >= 50) return '#FFC107';
    if (recoveryPercentage >= 30) return '#FF9800';
    return '#F44336';
  }

  String get statusLabel {
    if (recoveryPercentage >= 90) return 'Fully Recovered';
    if (recoveryPercentage >= 70) return 'Well Recovered';
    if (recoveryPercentage >= 50) return 'Partially Recovered';
    if (recoveryPercentage >= 30) return 'Still Recovering';
    return 'Needs More Rest';
  }

  String get recoveryPercentageDisplay => '${recoveryPercentage.toInt()}%';

  bool get workoutRecommendedToday => isReady && daysUntilReady == 0;

  String get daysDisplay {
    if (isReady) return 'Ready to workout';
    if (daysUntilReady == 1) return 'Ready in 1 day';
    return 'Ready in $daysUntilReady days';
  }
}

@JsonSerializable()
class WorkoutModificationResult {
  final bool success;
  final String message;
  @JsonKey(name: 'original_workout_id')
  final String? originalWorkoutId;
  @JsonKey(name: 'modified_workout_id')
  final String? modifiedWorkoutId;
  @JsonKey(name: 'modifications_applied')
  final List<WorkoutModification> modificationsApplied;
  @JsonKey(name: 'exercises_swapped')
  final int exercisesSwapped;
  @JsonKey(name: 'exercises_removed')
  final int exercisesRemoved;
  @JsonKey(name: 'volume_reduction_percent')
  final double volumeReductionPercent;
  @JsonKey(name: 'intensity_reduction')
  final String? intensityReduction;
  @JsonKey(name: 'warmup_extended')
  final bool warmupExtended;
  @JsonKey(name: 'cooldown_extended')
  final bool cooldownExtended;
  @JsonKey(name: 'balance_exercises_added')
  final int balanceExercisesAdded;
  @JsonKey(name: 'mobility_exercises_added')
  final int mobilityExercisesAdded;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  const WorkoutModificationResult({
    required this.success,
    required this.message,
    this.originalWorkoutId,
    this.modifiedWorkoutId,
    this.modificationsApplied = const [],
    this.exercisesSwapped = 0,
    this.exercisesRemoved = 0,
    this.volumeReductionPercent = 0,
    this.intensityReduction,
    this.warmupExtended = false,
    this.cooldownExtended = false,
    this.balanceExercisesAdded = 0,
    this.mobilityExercisesAdded = 0,
    this.createdAt,
  });

  factory WorkoutModificationResult.fromJson(Map<String, dynamic> json) =>
      _$WorkoutModificationResultFromJson(json);
  Map<String, dynamic> toJson() => _$WorkoutModificationResultToJson(this);

  String get modificationsSummary {
    final parts = <String>[];
    if (exercisesSwapped > 0) {
      parts.add('$exercisesSwapped exercise${exercisesSwapped > 1 ? 's' : ''} swapped');
    }
    if (exercisesRemoved > 0) {
      parts.add('$exercisesRemoved exercise${exercisesRemoved > 1 ? 's' : ''} removed');
    }
    if (volumeReductionPercent > 0) {
      parts.add('${volumeReductionPercent.toInt()}% volume reduction');
    }
    if (warmupExtended) parts.add('warmup extended');
    if (cooldownExtended) parts.add('cooldown extended');
    if (balanceExercisesAdded > 0) parts.add('balance work added');
    if (mobilityExercisesAdded > 0) parts.add('mobility work added');
    return parts.isEmpty ? 'No modifications needed' : parts.join(', ');
  }

  bool get hasSignificantModifications {
    return exercisesSwapped > 0 ||
        exercisesRemoved > 0 ||
        volumeReductionPercent >= 10 ||
        balanceExercisesAdded > 0 ||
        mobilityExercisesAdded > 0;
  }
}

@JsonSerializable()
class WorkoutModification {
  @JsonKey(name: 'modification_type')
  final String modificationType;
  @JsonKey(name: 'original_value')
  final String? originalValue;
  @JsonKey(name: 'new_value')
  final String? newValue;
  final String reason;
  @JsonKey(name: 'exercise_name')
  final String? exerciseName;

  const WorkoutModification({
    required this.modificationType,
    this.originalValue,
    this.newValue,
    required this.reason,
    this.exerciseName,
  });

  factory WorkoutModification.fromJson(Map<String, dynamic> json) =>
      _$WorkoutModificationFromJson(json);
  Map<String, dynamic> toJson() => _$WorkoutModificationToJson(this);

  String get displayText {
    switch (modificationType) {
      case 'exercise_swap':
        return 'Swapped "$originalValue" with "$newValue"';
      case 'exercise_remove':
        return 'Removed "$originalValue"';
      case 'volume_reduction':
        return 'Reduced sets from $originalValue to $newValue';
      case 'intensity_reduction':
        return 'Reduced intensity from $originalValue to $newValue';
      case 'rest_increase':
        return 'Increased rest from $originalValue to $newValue';
      case 'add_balance':
        return 'Added balance exercise: $newValue';
      case 'add_mobility':
        return 'Added mobility exercise: $newValue';
      default:
        return '$modificationType: $originalValue -> $newValue';
    }
  }
}

@JsonSerializable()
class SeniorMobilityExercise {
  final String id;
  final String name;
  final String description;
  @JsonKey(name: 'target_areas')
  final List<String> targetAreas;
  @JsonKey(name: 'duration_seconds')
  final int durationSeconds;
  final int? reps;
  final int sets;
  @JsonKey(name: 'difficulty_level')
  final String difficultyLevel;
  @JsonKey(name: 'equipment_needed')
  final List<String> equipmentNeeded;
  @JsonKey(name: 'is_seated')
  final bool isSeated;
  @JsonKey(name: 'is_balance_exercise')
  final bool isBalanceExercise;
  @JsonKey(name: 'requires_support')
  final bool requiresSupport;
  final List<String> benefits;
  @JsonKey(name: 'common_mistakes')
  final List<String> commonMistakes;
  final List<String> cues;
  @JsonKey(name: 'video_url')
  final String? videoUrl;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  const SeniorMobilityExercise({
    required this.id,
    required this.name,
    required this.description,
    this.targetAreas = const [],
    this.durationSeconds = 30,
    this.reps,
    this.sets = 2,
    this.difficultyLevel = 'easy',
    this.equipmentNeeded = const [],
    this.isSeated = false,
    this.isBalanceExercise = false,
    this.requiresSupport = false,
    this.benefits = const [],
    this.commonMistakes = const [],
    this.cues = const [],
    this.videoUrl,
    this.imageUrl,
    this.isActive = true,
    this.createdAt,
  });

  factory SeniorMobilityExercise.fromJson(Map<String, dynamic> json) =>
      _$SeniorMobilityExerciseFromJson(json);
  Map<String, dynamic> toJson() => _$SeniorMobilityExerciseToJson(this);

  String get prescriptionText {
    if (reps != null) return '$sets x $reps reps';
    return '$sets x ${durationSeconds}s hold';
  }

  String get difficultyColor {
    switch (difficultyLevel.toLowerCase()) {
      case 'easy':
        return '#4CAF50';
      case 'moderate':
        return '#FFC107';
      case 'challenging':
        return '#FF9800';
      default:
        return '#9E9E9E';
    }
  }

  String get iconName {
    if (isBalanceExercise) return 'accessibility_new';
    if (isSeated) return 'event_seat';
    if (targetAreas.contains('spine') || targetAreas.contains('back')) {
      return 'rotate_right';
    }
    if (targetAreas.contains('hips')) return 'directions_walk';
    if (targetAreas.contains('shoulders')) return 'fitness_center';
    return 'self_improvement';
  }

  bool get requiresEquipment => equipmentNeeded.isNotEmpty;

  String get targetAreasDisplay {
    if (targetAreas.isEmpty) return 'Full body';
    return targetAreas.join(', ');
  }
}

@JsonSerializable()
class SeniorWorkoutLog {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'workout_id')
  final String? workoutId;
  @JsonKey(name: 'workout_name')
  final String workoutName;
  @JsonKey(name: 'workout_type')
  final String workoutType;
  @JsonKey(name: 'completed_at')
  final DateTime completedAt;
  @JsonKey(name: 'duration_minutes')
  final int durationMinutes;
  @JsonKey(name: 'perceived_exertion')
  final int? perceivedExertion;
  @JsonKey(name: 'energy_level_before')
  final int? energyLevelBefore;
  @JsonKey(name: 'energy_level_after')
  final int? energyLevelAfter;
  @JsonKey(name: 'joint_pain_reported')
  final bool jointPainReported;
  @JsonKey(name: 'joint_pain_areas')
  final List<String> jointPainAreas;
  @JsonKey(name: 'balance_exercises_completed')
  final int balanceExercisesCompleted;
  @JsonKey(name: 'mobility_exercises_completed')
  final int mobilityExercisesCompleted;
  @JsonKey(name: 'modifications_used')
  final List<String> modificationsUsed;
  @JsonKey(name: 'warmup_completed')
  final bool warmupCompleted;
  @JsonKey(name: 'cooldown_completed')
  final bool cooldownCompleted;
  @JsonKey(name: 'recovery_rating')
  final int? recoveryRating;
  final String? notes;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  const SeniorWorkoutLog({
    required this.id,
    required this.userId,
    this.workoutId,
    required this.workoutName,
    required this.workoutType,
    required this.completedAt,
    required this.durationMinutes,
    this.perceivedExertion,
    this.energyLevelBefore,
    this.energyLevelAfter,
    this.jointPainReported = false,
    this.jointPainAreas = const [],
    this.balanceExercisesCompleted = 0,
    this.mobilityExercisesCompleted = 0,
    this.modificationsUsed = const [],
    this.warmupCompleted = true,
    this.cooldownCompleted = true,
    this.recoveryRating,
    this.notes,
    this.createdAt,
  });

  factory SeniorWorkoutLog.fromJson(Map<String, dynamic> json) =>
      _$SeniorWorkoutLogFromJson(json);
  Map<String, dynamic> toJson() => _$SeniorWorkoutLogToJson(this);

  String? get energyChangeDisplay {
    if (energyLevelBefore == null || energyLevelAfter == null) return null;
    final change = energyLevelAfter! - energyLevelBefore!;
    if (change > 0) return '+$change energy';
    if (change < 0) return '$change energy';
    return 'No change';
  }

  bool get energyIncreased {
    if (energyLevelBefore == null || energyLevelAfter == null) return false;
    return energyLevelAfter! > energyLevelBefore!;
  }

  String? get perceivedExertionLabel {
    if (perceivedExertion == null) return null;
    if (perceivedExertion! <= 2) return 'Very Light';
    if (perceivedExertion! <= 4) return 'Light';
    if (perceivedExertion! <= 6) return 'Moderate';
    if (perceivedExertion! <= 8) return 'Hard';
    return 'Very Hard';
  }

  String get durationDisplay {
    if (durationMinutes < 60) return '$durationMinutes min';
    final hours = durationMinutes ~/ 60;
    final mins = durationMinutes % 60;
    return '${hours}h ${mins}m';
  }

  bool get wasFullyCompleted => warmupCompleted && cooldownCompleted;

  String? get recoveryRatingLabel {
    if (recoveryRating == null) return null;
    if (recoveryRating! >= 4) return 'Excellent';
    if (recoveryRating! >= 3) return 'Good';
    if (recoveryRating! >= 2) return 'Fair';
    return 'Poor';
  }
}

@JsonSerializable()
class LowImpactAlternative {
  @JsonKey(name: 'original_exercise_id')
  final String? originalExerciseId;
  @JsonKey(name: 'original_exercise_name')
  final String originalExerciseName;
  @JsonKey(name: 'alternative_exercise_id')
  final String? alternativeExerciseId;
  @JsonKey(name: 'alternative_exercise_name')
  final String alternativeExerciseName;
  @JsonKey(name: 'alternative_description')
  final String? alternativeDescription;
  final String reason;
  @JsonKey(name: 'muscle_similarity_score')
  final double muscleSimilarityScore;
  @JsonKey(name: 'impact_reduction')
  final String impactReduction;
  @JsonKey(name: 'is_seated')
  final bool isSeated;
  @JsonKey(name: 'equipment_needed')
  final List<String> equipmentNeeded;
  final List<String> benefits;

  const LowImpactAlternative({
    this.originalExerciseId,
    required this.originalExerciseName,
    this.alternativeExerciseId,
    required this.alternativeExerciseName,
    this.alternativeDescription,
    required this.reason,
    this.muscleSimilarityScore = 0.8,
    this.impactReduction = 'moderate',
    this.isSeated = false,
    this.equipmentNeeded = const [],
    this.benefits = const [],
  });

  factory LowImpactAlternative.fromJson(Map<String, dynamic> json) =>
      _$LowImpactAlternativeFromJson(json);
  Map<String, dynamic> toJson() => _$LowImpactAlternativeToJson(this);

  String get similarityDisplay => '${(muscleSimilarityScore * 100).toInt()}% similar';

  String get impactReductionDisplay {
    switch (impactReduction.toLowerCase()) {
      case 'low':
        return 'Slight reduction';
      case 'moderate':
        return 'Moderate reduction';
      case 'high':
        return 'Significant reduction';
      case 'complete':
        return 'No impact';
      default:
        return impactReduction;
    }
  }

  bool get isGoodMatch => muscleSimilarityScore >= 0.7;
}

@JsonSerializable()
class SeniorWorkoutHistoryResponse {
  @JsonKey(name: 'workout_logs')
  final List<SeniorWorkoutLog> workoutLogs;
  @JsonKey(name: 'total_workouts')
  final int totalWorkouts;
  @JsonKey(name: 'total_duration_minutes')
  final int totalDurationMinutes;
  @JsonKey(name: 'average_perceived_exertion')
  final double? averagePerceivedExertion;
  @JsonKey(name: 'workouts_with_joint_pain')
  final int workoutsWithJointPain;
  @JsonKey(name: 'most_common_pain_areas')
  final List<String> mostCommonPainAreas;
  @JsonKey(name: 'balance_exercises_total')
  final int balanceExercisesTotal;
  @JsonKey(name: 'mobility_exercises_total')
  final int mobilityExercisesTotal;
  @JsonKey(name: 'consistency_score')
  final double? consistencyScore;

  const SeniorWorkoutHistoryResponse({
    this.workoutLogs = const [],
    this.totalWorkouts = 0,
    this.totalDurationMinutes = 0,
    this.averagePerceivedExertion,
    this.workoutsWithJointPain = 0,
    this.mostCommonPainAreas = const [],
    this.balanceExercisesTotal = 0,
    this.mobilityExercisesTotal = 0,
    this.consistencyScore,
  });

  factory SeniorWorkoutHistoryResponse.fromJson(Map<String, dynamic> json) =>
      _$SeniorWorkoutHistoryResponseFromJson(json);
  Map<String, dynamic> toJson() => _$SeniorWorkoutHistoryResponseToJson(this);

  double get averageWorkoutDuration {
    if (totalWorkouts == 0) return 0;
    return totalDurationMinutes / totalWorkouts;
  }

  double get jointPainPercentage {
    if (totalWorkouts == 0) return 0;
    return (workoutsWithJointPain / totalWorkouts) * 100;
  }

  bool get jointPainIsConcern => jointPainPercentage > 20;
}
