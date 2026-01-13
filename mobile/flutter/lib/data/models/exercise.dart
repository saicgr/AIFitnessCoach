import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'exercise.g.dart';

/// Per-set AI target (like Gravl/Hevy style)
@JsonSerializable()
class SetTarget extends Equatable {
  @JsonKey(name: 'set_number')
  final int setNumber;
  @JsonKey(name: 'set_type')
  final String setType; // "warmup", "working", "drop", "failure", "amrap"
  @JsonKey(name: 'target_reps')
  final int targetReps;
  @JsonKey(name: 'target_weight_kg')
  final double? targetWeightKg;
  @JsonKey(name: 'target_rpe')
  final int? targetRpe; // 1-10
  @JsonKey(name: 'target_rir')
  final int? targetRir; // 0-5 (Reps in Reserve)

  const SetTarget({
    required this.setNumber,
    this.setType = 'working',
    required this.targetReps,
    this.targetWeightKg,
    this.targetRpe,
    this.targetRir,
  });

  factory SetTarget.fromJson(Map<String, dynamic> json) =>
      _$SetTargetFromJson(json);
  Map<String, dynamic> toJson() => _$SetTargetToJson(this);

  /// Get display label for set type (W = warmup, D = drop, etc.)
  String get setTypeLabel {
    switch (setType.toLowerCase()) {
      case 'warmup':
        return 'W';
      case 'drop':
        return 'D';
      case 'failure':
        return 'F';
      case 'amrap':
        return 'A';
      default:
        return ''; // Working sets show number
    }
  }

  /// Whether this is a warmup set
  bool get isWarmup => setType.toLowerCase() == 'warmup';

  /// Whether this is a drop set
  bool get isDropSet => setType.toLowerCase() == 'drop';

  /// Whether this is a working set
  bool get isWorkingSet => setType.toLowerCase() == 'working';

  /// Whether this is a failure/AMRAP set
  bool get isFailure => setType.toLowerCase() == 'failure' || setType.toLowerCase() == 'amrap';

  @override
  List<Object?> get props => [setNumber, setType, targetReps, targetWeightKg, targetRpe, targetRir];
}

/// Exercise within a workout
@JsonSerializable()
class WorkoutExercise extends Equatable {
  final String? id;
  @JsonKey(name: 'exercise_id')
  final String? exerciseId;
  @JsonKey(name: 'library_id')
  final String? libraryId;
  @JsonKey(name: 'name')
  final String? nameValue;
  final int? sets;
  final int? reps;
  @JsonKey(name: 'rest_seconds')
  final int? restSeconds;
  @JsonKey(name: 'duration_seconds')
  final int? durationSeconds;
  final double? weight;
  final String? notes;
  @JsonKey(name: 'gif_url')
  final String? gifUrl;
  @JsonKey(name: 'video_url')
  final String? videoUrl;
  @JsonKey(name: 'image_s3_path')
  final String? imageS3Path;
  @JsonKey(name: 'video_s3_path')
  final String? videoS3Path;
  @JsonKey(name: 'body_part')
  final String? bodyPart;
  final String? equipment;
  @JsonKey(name: 'muscle_group')
  final String? muscleGroup;
  @JsonKey(name: 'primary_muscle')
  final String? primaryMuscle;
  @JsonKey(name: 'secondary_muscles')
  final dynamic secondaryMuscles;
  final String? instructions;
  @JsonKey(name: 'is_completed')
  final bool? isCompleted;
  @JsonKey(name: 'alternating_hands')
  final bool? alternatingHands;
  @JsonKey(name: 'weight_source')
  final String? weightSource; // "historical" (from past workouts), "generic" (estimated), or null
  @JsonKey(name: 'is_favorite')
  final bool? isFavorite;
  @JsonKey(name: 'from_queue')
  final bool? fromQueue;
  @JsonKey(name: 'hold_seconds')
  final int? holdSeconds; // For static stretches/holds (e.g., 30-60 seconds)
  @JsonKey(name: 'is_unilateral')
  final bool? isUnilateral; // Single-arm or single-leg exercises
  @JsonKey(name: 'superset_group')
  final int? supersetGroup; // Group ID for superset pairing (exercises with same ID are paired)
  @JsonKey(name: 'superset_order')
  final int? supersetOrder; // Order within superset (1 or 2)
  @JsonKey(name: 'is_drop_set')
  final bool? isDropSet; // Whether this exercise uses drop sets
  @JsonKey(name: 'drop_set_count')
  final int? dropSetCount; // Number of drop sets (typically 2-3)
  @JsonKey(name: 'drop_set_percentage')
  final int? dropSetPercentage; // Percentage to reduce weight each drop (typically 20-25%)
  @JsonKey(name: 'is_challenge')
  final bool? isChallenge; // Whether this is an optional challenge exercise for beginners
  @JsonKey(name: 'progression_from')
  final String? progressionFrom; // Name of the main exercise this progresses from
  final String? difficulty; // Exercise difficulty level (e.g., "intermediate", "advanced")
  @JsonKey(name: 'difficulty_num')
  final int? difficultyNum; // Numeric difficulty (1-10)
  @JsonKey(name: 'is_failure_set')
  final bool? isFailureSet; // Whether the final set should be taken to failure
  @JsonKey(name: 'set_targets')
  final List<SetTarget>? setTargets; // Per-set AI targets (Gravl/Hevy style)

  const WorkoutExercise({
    this.id,
    this.exerciseId,
    this.libraryId,
    this.nameValue,
    this.sets,
    this.reps,
    this.restSeconds,
    this.durationSeconds,
    this.weight,
    this.notes,
    this.gifUrl,
    this.videoUrl,
    this.imageS3Path,
    this.videoS3Path,
    this.bodyPart,
    this.equipment,
    this.muscleGroup,
    this.primaryMuscle,
    this.secondaryMuscles,
    this.instructions,
    this.isCompleted,
    this.alternatingHands,
    this.weightSource,
    this.isFavorite,
    this.fromQueue,
    this.holdSeconds,
    this.isUnilateral,
    this.supersetGroup,
    this.supersetOrder,
    this.isDropSet,
    this.dropSetCount,
    this.dropSetPercentage,
    this.isChallenge,
    this.progressionFrom,
    this.difficulty,
    this.difficultyNum,
    this.isFailureSet,
    this.setTargets,
  });

  /// Whether the weight is based on user's past workout history
  bool get isWeightFromHistory => weightSource == 'historical';

  /// Get a display label for the weight source
  String get weightSourceLabel {
    switch (weightSource) {
      case 'historical':
        return 'Based on your history';
      case 'generic':
        return 'Estimated';
      default:
        return '';
    }
  }

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) =>
      _$WorkoutExerciseFromJson(json);
  Map<String, dynamic> toJson() => _$WorkoutExerciseToJson(this);

  /// Get name (never null for display)
  String get name => nameValue ?? 'Exercise';

  /// Format sets x reps (or hold time for stretches, or duration for cardio)
  String get setsRepsDisplay {
    // For stretching/mobility exercises with hold times
    if (holdSeconds != null && holdSeconds! > 0) {
      final holdStr = holdSeconds! >= 60
          ? '${holdSeconds! ~/ 60}m ${holdSeconds! % 60}s'
          : '${holdSeconds}s';
      if (sets != null && sets! > 1) {
        return '$sets × $holdStr hold';
      }
      return '$holdStr hold';
    }
    // For strength exercises with sets/reps
    if (sets != null && reps != null) {
      return '$sets × $reps';
    }
    // For cardio exercises with duration
    if (durationSeconds != null) {
      final minutes = durationSeconds! ~/ 60;
      final seconds = durationSeconds! % 60;
      if (minutes > 0 && seconds > 0) {
        return '${minutes}m ${seconds}s';
      } else if (minutes > 0) {
        return '${minutes}m';
      } else {
        return '${seconds}s';
      }
    }
    return '';
  }

  /// Whether this is a timed exercise (planks, holds, cardio with duration)
  bool get isTimedExercise =>
      (durationSeconds != null && durationSeconds! > 0) ||
      (holdSeconds != null && holdSeconds! > 0);

  /// Get the timer duration in seconds (for timed exercises)
  int get timerDurationSeconds =>
      holdSeconds ?? durationSeconds ?? 30;

  /// Whether this is a unilateral (single-side) exercise
  bool get isSingleSide => isUnilateral == true || alternatingHands == true;

  /// Get unilateral indicator text
  String get unilateralIndicator => isSingleSide ? 'Each side' : '';

  /// Whether this exercise is part of a superset
  bool get isInSuperset => supersetGroup != null && supersetGroup! > 0;

  /// Whether this is the first exercise in a superset pair
  bool get isSupersetFirst => isInSuperset && supersetOrder == 1;

  /// Whether this is the second exercise in a superset pair
  bool get isSupersetSecond => isInSuperset && supersetOrder == 2;

  /// Whether this exercise has drop sets
  bool get hasDropSets => isDropSet == true && (dropSetCount ?? 0) > 0;

  /// Get drop set display text (e.g., "3 drop sets @ 20%")
  String get dropSetDisplay {
    if (!hasDropSets) return '';
    final count = dropSetCount ?? 2;
    final percent = dropSetPercentage ?? 20;
    return '$count drops @ $percent% less';
  }

  /// Calculate drop set weights from a starting weight
  List<double> getDropSetWeights(double startingWeight) {
    if (!hasDropSets) return [startingWeight];

    final count = dropSetCount ?? 2;
    final percentDrop = (dropSetPercentage ?? 20) / 100;
    final weights = <double>[startingWeight];

    for (int i = 0; i < count; i++) {
      final previousWeight = weights.last;
      final newWeight = previousWeight * (1 - percentDrop);
      // Round to nearest 2.5kg for practical gym use
      weights.add((newWeight / 2.5).round() * 2.5);
    }

    return weights;
  }

  /// Get rest time display
  String get restDisplay {
    if (restSeconds == null || restSeconds == 0) return '';
    if (restSeconds! >= 60) {
      final minutes = restSeconds! ~/ 60;
      final seconds = restSeconds! % 60;
      if (seconds > 0) {
        return '${minutes}m ${seconds}s rest';
      }
      return '${minutes}m rest';
    }
    return '${restSeconds}s rest';
  }

  /// Get weight display
  String get weightDisplay {
    if (weight == null || weight == 0) return '';
    if (weight! == weight!.toInt()) {
      return '${weight!.toInt()} kg';
    }
    return '${weight!.toStringAsFixed(1)} kg';
  }

  @override
  List<Object?> get props => [
        id,
        exerciseId,
        nameValue,
        sets,
        reps,
        restSeconds,
        durationSeconds,
        weight,
        setTargets,
      ];

  WorkoutExercise copyWith({
    String? id,
    String? exerciseId,
    String? libraryId,
    String? nameValue,
    int? sets,
    int? reps,
    int? restSeconds,
    int? durationSeconds,
    double? weight,
    String? notes,
    String? gifUrl,
    String? videoUrl,
    String? imageS3Path,
    String? videoS3Path,
    String? bodyPart,
    String? equipment,
    String? muscleGroup,
    String? primaryMuscle,
    dynamic secondaryMuscles,
    String? instructions,
    bool? isCompleted,
    bool? alternatingHands,
    String? weightSource,
    bool? isFavorite,
    bool? fromQueue,
    int? holdSeconds,
    bool? isUnilateral,
    int? supersetGroup,
    int? supersetOrder,
    bool? isDropSet,
    int? dropSetCount,
    int? dropSetPercentage,
    bool? isFailureSet,
    List<SetTarget>? setTargets,
  }) {
    return WorkoutExercise(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      libraryId: libraryId ?? this.libraryId,
      nameValue: nameValue ?? this.nameValue,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      restSeconds: restSeconds ?? this.restSeconds,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      weight: weight ?? this.weight,
      notes: notes ?? this.notes,
      gifUrl: gifUrl ?? this.gifUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      imageS3Path: imageS3Path ?? this.imageS3Path,
      videoS3Path: videoS3Path ?? this.videoS3Path,
      bodyPart: bodyPart ?? this.bodyPart,
      equipment: equipment ?? this.equipment,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      primaryMuscle: primaryMuscle ?? this.primaryMuscle,
      secondaryMuscles: secondaryMuscles ?? this.secondaryMuscles,
      instructions: instructions ?? this.instructions,
      isCompleted: isCompleted ?? this.isCompleted,
      alternatingHands: alternatingHands ?? this.alternatingHands,
      weightSource: weightSource ?? this.weightSource,
      isFavorite: isFavorite ?? this.isFavorite,
      fromQueue: fromQueue ?? this.fromQueue,
      holdSeconds: holdSeconds ?? this.holdSeconds,
      isUnilateral: isUnilateral ?? this.isUnilateral,
      supersetGroup: supersetGroup ?? this.supersetGroup,
      supersetOrder: supersetOrder ?? this.supersetOrder,
      isDropSet: isDropSet ?? this.isDropSet,
      dropSetCount: dropSetCount ?? this.dropSetCount,
      dropSetPercentage: dropSetPercentage ?? this.dropSetPercentage,
      isFailureSet: isFailureSet ?? this.isFailureSet,
      setTargets: setTargets ?? this.setTargets,
    );
  }

  /// Get AI target for a specific set number
  SetTarget? getTargetForSet(int setNumber) {
    if (setTargets == null || setTargets!.isEmpty) return null;
    return setTargets!.where((t) => t.setNumber == setNumber).firstOrNull;
  }

  /// Get warmup sets from targets
  List<SetTarget> get warmupSets =>
      setTargets?.where((t) => t.isWarmup).toList() ?? [];

  /// Get working/effective sets from targets (excludes warmup)
  List<SetTarget> get effectiveSets =>
      setTargets?.where((t) => !t.isWarmup).toList() ?? [];

  /// Whether this exercise has AI-generated set targets
  bool get hasSetTargets => setTargets != null && setTargets!.isNotEmpty;
}

/// Library exercise (full details from /library/exercises API)
@JsonSerializable()
class LibraryExercise extends Equatable {
  final String? id;
  @JsonKey(name: 'name')
  final String? nameValue;
  @JsonKey(name: 'original_name')
  final String? originalName;
  @JsonKey(name: 'body_part')
  final String? bodyPart;
  @JsonKey(name: 'equipment')
  final String? equipmentValue;
  @JsonKey(name: 'target_muscle')
  final String? targetMuscle;
  @JsonKey(name: 'secondary_muscles')
  final List<String>? secondaryMuscles;
  @JsonKey(name: 'instructions')
  final String? instructionsValue;
  @JsonKey(name: 'difficulty_level')
  final String? difficultyLevelValue;
  final String? category;
  @JsonKey(name: 'gif_url')
  final String? gifUrl;
  @JsonKey(name: 'video_url')
  final String? videoUrl;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  final List<String>? goals;
  @JsonKey(name: 'suitable_for')
  final List<String>? suitableFor;
  @JsonKey(name: 'avoid_if')
  final List<String>? avoidIf;

  const LibraryExercise({
    this.id,
    this.nameValue,
    this.originalName,
    this.bodyPart,
    this.equipmentValue,
    this.targetMuscle,
    this.secondaryMuscles,
    this.instructionsValue,
    this.difficultyLevelValue,
    this.category,
    this.gifUrl,
    this.videoUrl,
    this.imageUrl,
    this.goals,
    this.suitableFor,
    this.avoidIf,
  });

  factory LibraryExercise.fromJson(Map<String, dynamic> json) =>
      _$LibraryExerciseFromJson(json);
  Map<String, dynamic> toJson() => _$LibraryExerciseToJson(this);

  /// Get name (never null for display)
  String get name => nameValue ?? 'Unknown Exercise';

  /// Get muscle group for filtering (use body_part as primary)
  String? get muscleGroup => bodyPart ?? targetMuscle;

  /// Get difficulty string (already a string from API, just return it)
  String? get difficulty => difficultyLevelValue;

  /// Get type (category)
  String? get type => category;

  /// Get equipment as list (normalized)
  List<String> get equipment {
    if (equipmentValue == null || equipmentValue!.isEmpty) return [];
    return equipmentValue!.split(',').map((e) {
      final eq = e.trim();
      final lower = eq.toLowerCase();
      // Normalize "None (Bodyweight)" and similar to just "Bodyweight"
      if (lower.contains('none') || lower == 'bodyweight' || lower == 'body weight') {
        return 'Bodyweight';
      }
      return eq;
    }).toList();
  }

  /// Get instructions as list
  List<String> get instructions {
    if (instructionsValue == null || instructionsValue!.isEmpty) return [];
    // Try to split by numbered list or periods
    final lines = instructionsValue!
        .split(RegExp(r'(?:\d+\.\s*|\n|\.(?=\s+[A-Z]))'))
        .where((s) => s.trim().isNotEmpty)
        .map((s) => s.trim())
        .toList();
    return lines.isNotEmpty ? lines : [instructionsValue!];
  }

  /// Check if this is a bodyweight exercise
  bool get isBodyweight {
    if (equipmentValue == null) return true;
    final lower = equipmentValue!.toLowerCase();
    return lower.contains('bodyweight') ||
        lower.contains('body weight') ||
        lower.contains('none') ||
        lower.isEmpty;
  }

  /// Check if this is a compound exercise
  bool get isCompound {
    if (category == null) return false;
    return category!.toLowerCase() == 'compound';
  }

  /// Get searchable text for filtering (lowercase)
  String get searchableText {
    final parts = <String>[
      nameValue ?? '',
      bodyPart ?? '',
      targetMuscle ?? '',
      category ?? '',
      equipmentValue ?? '',
      secondaryMuscles?.join(' ') ?? '',
    ];
    return parts.join(' ').toLowerCase();
  }

  @override
  List<Object?> get props => [id, nameValue, bodyPart, targetMuscle];
}
