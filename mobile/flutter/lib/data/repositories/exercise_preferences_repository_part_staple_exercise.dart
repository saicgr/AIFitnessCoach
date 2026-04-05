part of 'exercise_preferences_repository.dart';


/// Model for a staple exercise (never rotated out)
class StapleExercise {
  final String id;
  final String exerciseName;
  final String? libraryId;
  final String? muscleGroup;
  final String? reason;
  final DateTime createdAt;
  final String? bodyPart;
  final String? equipment;
  final String? gifUrl;
  final String? gymProfileId;
  final String? gymProfileName;
  final String? gymProfileColor;
  final String section; // 'main', 'warmup', or 'stretches'
  // Cardio metadata from exercise_library
  final double? defaultInclinePercent;
  final double? defaultSpeedMph;
  final int? defaultRpm;
  final int? defaultResistanceLevel;
  final int? strokeRateSpm;
  final int? defaultDurationSeconds;
  // Movement classification
  final String? movementPattern;
  final String? energySystem;
  final String? impactLevel;
  final String? category;
  // User-specified strength/timed params
  final int? userSets;
  final String? userReps;  // "10" or "8-12" format
  final int? userRestSeconds;
  final double? userWeightLbs;  // User-specified weight in lbs
  // Day-of-week targeting: [0,2,4] = Mon/Wed/Fri, null = all days
  final List<int>? targetDays;

  const StapleExercise({
    required this.id,
    required this.exerciseName,
    this.libraryId,
    this.muscleGroup,
    this.reason,
    required this.createdAt,
    this.bodyPart,
    this.equipment,
    this.gifUrl,
    this.gymProfileId,
    this.gymProfileName,
    this.gymProfileColor,
    this.section = 'main',
    this.defaultInclinePercent,
    this.defaultSpeedMph,
    this.defaultRpm,
    this.defaultResistanceLevel,
    this.strokeRateSpm,
    this.defaultDurationSeconds,
    this.movementPattern,
    this.energySystem,
    this.impactLevel,
    this.category,
    this.userSets,
    this.userReps,
    this.userRestSeconds,
    this.userWeightLbs,
    this.targetDays,
  });

  factory StapleExercise.fromJson(Map<String, dynamic> json) {
    return StapleExercise(
      id: json['id'] as String,
      exerciseName: json['exercise_name'] as String,
      libraryId: json['library_id'] as String?,
      muscleGroup: json['muscle_group'] as String?,
      reason: json['reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      bodyPart: json['body_part'] as String?,
      equipment: json['equipment'] as String?,
      gifUrl: json['gif_url'] as String?,
      gymProfileId: json['gym_profile_id'] as String?,
      gymProfileName: json['gym_profile_name'] as String?,
      gymProfileColor: json['gym_profile_color'] as String?,
      section: json['section'] as String? ?? 'main',
      defaultInclinePercent: (json['default_incline_percent'] as num?)?.toDouble(),
      defaultSpeedMph: (json['default_speed_mph'] as num?)?.toDouble(),
      defaultRpm: (json['default_rpm'] as num?)?.toInt(),
      defaultResistanceLevel: (json['default_resistance_level'] as num?)?.toInt(),
      strokeRateSpm: (json['stroke_rate_spm'] as num?)?.toInt(),
      defaultDurationSeconds: (json['default_duration_seconds'] as num?)?.toInt(),
      movementPattern: json['movement_pattern'] as String?,
      energySystem: json['energy_system'] as String?,
      impactLevel: json['impact_level'] as String?,
      category: json['category'] as String?,
      userSets: (json['user_sets'] as num?)?.toInt(),
      userReps: json['user_reps'] as String?,
      userRestSeconds: (json['user_rest_seconds'] as num?)?.toInt(),
      userWeightLbs: (json['user_weight_lbs'] as num?)?.toDouble(),
      targetDays: (json['target_days'] as List<dynamic>?)?.map((e) => (e as num).toInt()).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'exercise_name': exerciseName,
    'library_id': libraryId,
    'muscle_group': muscleGroup,
    'reason': reason,
    'created_at': createdAt.toIso8601String(),
    'section': section,
  };

  /// Whether this staple has cardio equipment metadata
  bool get isCardioEquipment =>
      defaultInclinePercent != null ||
      defaultSpeedMph != null ||
      defaultRpm != null ||
      defaultResistanceLevel != null ||
      strokeRateSpm != null;

  /// Formatted cardio params for display
  String get cardioParamsDisplay {
    final parts = <String>[];
    if (defaultDurationSeconds != null) {
      final mins = defaultDurationSeconds! ~/ 60;
      parts.add('$mins min');
    }
    if (defaultSpeedMph != null) parts.add('${defaultSpeedMph!.toStringAsFixed(1)} mph');
    if (defaultInclinePercent != null) parts.add('Incline ${defaultInclinePercent!.toStringAsFixed(0)}');
    if (defaultRpm != null) parts.add('$defaultRpm RPM');
    if (defaultResistanceLevel != null) parts.add('Resistance $defaultResistanceLevel');
    if (strokeRateSpm != null) parts.add('$strokeRateSpm spm');
    return parts.join(' | ');
  }
}


/// Model for variation preference
class VariationPreference {
  final int variationPercentage;
  final String description;

  const VariationPreference({
    required this.variationPercentage,
    required this.description,
  });

  factory VariationPreference.fromJson(Map<String, dynamic> json) {
    return VariationPreference(
      variationPercentage: (json['variation_percentage'] as num).toInt(),
      description: json['description'] as String,
    );
  }
}


/// Model for week-over-week exercise comparison
class WeekComparison {
  final DateTime currentWeekStart;
  final DateTime previousWeekStart;
  final List<String> keptExercises;
  final List<String> newExercises;
  final List<String> removedExercises;
  final int totalCurrent;
  final int totalPrevious;
  final String variationSummary;

  const WeekComparison({
    required this.currentWeekStart,
    required this.previousWeekStart,
    required this.keptExercises,
    required this.newExercises,
    required this.removedExercises,
    required this.totalCurrent,
    required this.totalPrevious,
    required this.variationSummary,
  });

  factory WeekComparison.fromJson(Map<String, dynamic> json) {
    return WeekComparison(
      currentWeekStart: DateTime.parse(json['current_week_start'] as String),
      previousWeekStart: DateTime.parse(json['previous_week_start'] as String),
      keptExercises: (json['kept_exercises'] as List<dynamic>).cast<String>(),
      newExercises: (json['new_exercises'] as List<dynamic>).cast<String>(),
      removedExercises: (json['removed_exercises'] as List<dynamic>).cast<String>(),
      totalCurrent: (json['total_current'] as num).toInt(),
      totalPrevious: (json['total_previous'] as num).toInt(),
      variationSummary: json['variation_summary'] as String,
    );
  }

  /// Check if there are any changes this week
  bool get hasChanges => newExercises.isNotEmpty || removedExercises.isNotEmpty;

  /// Get percentage of exercises that changed
  double get changePercentage {
    if (totalPrevious == 0) return 0.0;
    return (newExercises.length / totalPrevious) * 100;
  }
}


/// Model for a queued exercise
class QueuedExercise {
  final String id;
  final String exerciseName;
  final String? exerciseId;
  final int priority;
  final String? targetMuscleGroup;
  final DateTime addedAt;
  final DateTime expiresAt;
  final DateTime? usedAt;

  const QueuedExercise({
    required this.id,
    required this.exerciseName,
    this.exerciseId,
    required this.priority,
    this.targetMuscleGroup,
    required this.addedAt,
    required this.expiresAt,
    this.usedAt,
  });

  factory QueuedExercise.fromJson(Map<String, dynamic> json) {
    return QueuedExercise(
      id: json['id'] as String,
      exerciseName: json['exercise_name'] as String,
      exerciseId: json['exercise_id'] as String?,
      priority: json['priority'] as int? ?? 0,
      targetMuscleGroup: json['target_muscle_group'] as String?,
      addedAt: DateTime.parse(json['added_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      usedAt: json['used_at'] != null ? DateTime.parse(json['used_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'exercise_name': exerciseName,
    'exercise_id': exerciseId,
    'priority': priority,
    'target_muscle_group': targetMuscleGroup,
    'added_at': addedAt.toIso8601String(),
    'expires_at': expiresAt.toIso8601String(),
    'used_at': usedAt?.toIso8601String(),
  };

  /// Check if this queue item is still active (not used, not expired)
  bool get isActive => usedAt == null && expiresAt.isAfter(DateTime.now());
}


/// Model for an avoided exercise
class AvoidedExercise {
  final String id;
  final String exerciseName;
  final String? exerciseId;
  final String? reason;
  final bool isTemporary;
  final DateTime? endDate;
  final DateTime createdAt;

  const AvoidedExercise({
    required this.id,
    required this.exerciseName,
    this.exerciseId,
    this.reason,
    this.isTemporary = false,
    this.endDate,
    required this.createdAt,
  });

  factory AvoidedExercise.fromJson(Map<String, dynamic> json) {
    return AvoidedExercise(
      id: json['id'] as String,
      exerciseName: json['exercise_name'] as String,
      exerciseId: json['exercise_id'] as String?,
      reason: json['reason'] as String?,
      isTemporary: json['is_temporary'] as bool? ?? false,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'exercise_name': exerciseName,
    'exercise_id': exerciseId,
    'reason': reason,
    'is_temporary': isTemporary,
    'end_date': endDate?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
  };

  /// Check if this avoidance is still active
  bool get isActive {
    if (!isTemporary) return true;
    if (endDate == null) return true;
    return endDate!.isAfter(DateTime.now());
  }
}


/// Model for a substitute exercise suggestion
class SubstituteExercise {
  final String name;
  final String? muscleGroup;
  final String? equipment;
  final String? difficulty;
  final bool isSafeForReason;
  final String? libraryId;
  final String? gifUrl;

  const SubstituteExercise({
    required this.name,
    this.muscleGroup,
    this.equipment,
    this.difficulty,
    this.isSafeForReason = true,
    this.libraryId,
    this.gifUrl,
  });

  factory SubstituteExercise.fromJson(Map<String, dynamic> json) {
    return SubstituteExercise(
      name: json['name'] as String,
      muscleGroup: json['muscle_group'] as String?,
      equipment: json['equipment'] as String?,
      difficulty: json['difficulty'] as String?,
      isSafeForReason: json['is_safe_for_reason'] as bool? ?? true,
      libraryId: json['library_id'] as String?,
      gifUrl: json['gif_url'] as String?,
    );
  }
}


/// Response model for substitute suggestions
class SubstituteResponse {
  final String originalExercise;
  final String? reason;
  final List<SubstituteExercise> substitutes;
  final String message;

  const SubstituteResponse({
    required this.originalExercise,
    this.reason,
    required this.substitutes,
    required this.message,
  });

  factory SubstituteResponse.fromJson(Map<String, dynamic> json) {
    return SubstituteResponse(
      originalExercise: json['original_exercise'] as String,
      reason: json['reason'] as String?,
      substitutes: (json['substitutes'] as List<dynamic>?)
              ?.map((e) => SubstituteExercise.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      message: json['message'] as String? ?? '',
    );
  }
}


/// Response model for injury-based exercise recommendations
class InjuryExercisesResponse {
  final String injuryType;
  final List<String> exercisesToAvoid;
  final Map<String, dynamic> safeAlternativesByMuscle;
  final String message;

  const InjuryExercisesResponse({
    required this.injuryType,
    required this.exercisesToAvoid,
    required this.safeAlternativesByMuscle,
    required this.message,
  });

  factory InjuryExercisesResponse.fromJson(Map<String, dynamic> json) {
    return InjuryExercisesResponse(
      injuryType: json['injury_type'] as String? ?? '',
      exercisesToAvoid: (json['exercises_to_avoid'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      safeAlternativesByMuscle:
          json['safe_alternatives_by_muscle'] as Map<String, dynamic>? ?? {},
      message: json['message'] as String? ?? '',
    );
  }
}


/// Model for an avoided muscle group
class AvoidedMuscle {
  final String id;
  final String muscleGroup;
  final String? reason;
  final bool isTemporary;
  final DateTime? endDate;
  final String severity; // 'avoid' or 'reduce'
  final DateTime createdAt;

  const AvoidedMuscle({
    required this.id,
    required this.muscleGroup,
    this.reason,
    this.isTemporary = false,
    this.endDate,
    this.severity = 'avoid',
    required this.createdAt,
  });

  factory AvoidedMuscle.fromJson(Map<String, dynamic> json) {
    return AvoidedMuscle(
      id: json['id'] as String,
      muscleGroup: json['muscle_group'] as String,
      reason: json['reason'] as String?,
      isTemporary: json['is_temporary'] as bool? ?? false,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      severity: json['severity'] as String? ?? 'avoid',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'muscle_group': muscleGroup,
    'reason': reason,
    'is_temporary': isTemporary,
    'end_date': endDate?.toIso8601String(),
    'severity': severity,
    'created_at': createdAt.toIso8601String(),
  };

  /// Check if this avoidance is still active
  bool get isActive {
    if (!isTemporary) return true;
    if (endDate == null) return true;
    return endDate!.isAfter(DateTime.now());
  }

  /// Get display name for the muscle group
  String get displayName {
    return muscleGroup
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
  }
}

