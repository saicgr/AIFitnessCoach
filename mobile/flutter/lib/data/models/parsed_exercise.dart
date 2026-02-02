import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'exercise.dart';

part 'parsed_exercise.g.dart';

/// A parsed exercise from AI text/image/voice input.
///
/// This model represents the result of parsing natural language input like:
/// - "3x10 deadlift at 135"
/// - "bench press 4 sets of 8 at 80"
@JsonSerializable()
class ParsedExercise extends Equatable {
  final String name;
  final int sets;
  final int reps;
  @JsonKey(name: 'weight_kg')
  final double? weightKg;
  @JsonKey(name: 'weight_lbs')
  final double? weightLbs;
  @JsonKey(name: 'weight_unit')
  final String weightUnit;
  @JsonKey(name: 'rest_seconds')
  final int restSeconds;
  @JsonKey(name: 'original_text')
  final String originalText;
  final double confidence;
  final String? notes;

  const ParsedExercise({
    required this.name,
    this.sets = 3,
    this.reps = 10,
    this.weightKg,
    this.weightLbs,
    this.weightUnit = 'lbs',
    this.restSeconds = 60,
    required this.originalText,
    this.confidence = 1.0,
    this.notes,
  });

  factory ParsedExercise.fromJson(Map<String, dynamic> json) =>
      _$ParsedExerciseFromJson(json);

  Map<String, dynamic> toJson() => _$ParsedExerciseToJson(this);

  /// Get weight in user's preferred unit
  double? getWeight({required bool useKg}) {
    if (useKg) {
      return weightKg;
    }
    return weightLbs;
  }

  /// Get formatted weight string (e.g., "135 lbs" or "60 kg")
  String getFormattedWeight({required bool useKg}) {
    final weight = getWeight(useKg: useKg);
    if (weight == null) return 'Bodyweight';
    final unit = useKg ? 'kg' : 'lbs';
    // Show whole number if no decimal, otherwise show 1 decimal
    if (weight == weight.roundToDouble()) {
      return '${weight.toInt()} $unit';
    }
    return '${weight.toStringAsFixed(1)} $unit';
  }

  /// Get formatted sets x reps string (e.g., "3 x 10")
  String get formattedSetsReps => '$sets x $reps';

  /// Check if this is a low confidence parse
  bool get isLowConfidence => confidence < 0.7;

  /// Convert to WorkoutExercise for adding to workout
  WorkoutExercise toWorkoutExercise({bool useKg = true}) {
    return WorkoutExercise(
      nameValue: name,
      sets: sets,
      reps: reps,
      weight: useKg ? weightKg : weightLbs,
      restSeconds: restSeconds,
      notes: notes,
    );
  }

  /// Create a copy with modified values
  ParsedExercise copyWith({
    String? name,
    int? sets,
    int? reps,
    double? weightKg,
    double? weightLbs,
    String? weightUnit,
    int? restSeconds,
    String? originalText,
    double? confidence,
    String? notes,
  }) {
    return ParsedExercise(
      name: name ?? this.name,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weightKg: weightKg ?? this.weightKg,
      weightLbs: weightLbs ?? this.weightLbs,
      weightUnit: weightUnit ?? this.weightUnit,
      restSeconds: restSeconds ?? this.restSeconds,
      originalText: originalText ?? this.originalText,
      confidence: confidence ?? this.confidence,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
        name,
        sets,
        reps,
        weightKg,
        weightLbs,
        weightUnit,
        restSeconds,
        originalText,
        confidence,
        notes,
      ];
}

/// Response from the parse workout input API (legacy)
@JsonSerializable()
class ParseWorkoutInputResponse extends Equatable {
  final List<ParsedExercise> exercises;
  final String summary;
  final List<String> warnings;

  const ParseWorkoutInputResponse({
    required this.exercises,
    required this.summary,
    this.warnings = const [],
  });

  factory ParseWorkoutInputResponse.fromJson(Map<String, dynamic> json) =>
      _$ParseWorkoutInputResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ParseWorkoutInputResponseToJson(this);

  @override
  List<Object?> get props => [exercises, summary, warnings];
}

// =============================================================================
// V2 DUAL-MODE PARSING (Sets + Exercises)
// =============================================================================

/// A single set to log for the current exercise.
///
/// Used when user types just weight*reps without exercise name.
@JsonSerializable()
class SetToLog extends Equatable {
  final double weight;
  final int reps;
  final String unit;
  @JsonKey(name: 'is_bodyweight')
  final bool isBodyweight;
  @JsonKey(name: 'is_failure')
  final bool isFailure;
  @JsonKey(name: 'is_warmup')
  final bool isWarmup;
  @JsonKey(name: 'original_input')
  final String originalInput;
  final String? notes;

  const SetToLog({
    required this.weight,
    required this.reps,
    this.unit = 'lbs',
    this.isBodyweight = false,
    this.isFailure = false,
    this.isWarmup = false,
    this.originalInput = '',
    this.notes,
  });

  factory SetToLog.fromJson(Map<String, dynamic> json) =>
      _$SetToLogFromJson(json);

  Map<String, dynamic> toJson() => _$SetToLogToJson(this);

  /// Get weight in user's preferred unit
  double getWeight({required bool useKg}) {
    if (isBodyweight) return 0;
    if (useKg) {
      return unit.toLowerCase() == 'kg' ? weight : weight / 2.20462;
    }
    return unit.toLowerCase() == 'lbs' ? weight : weight * 2.20462;
  }

  /// Get formatted weight string
  String getFormattedWeight({required bool useKg}) {
    if (isBodyweight) return 'BW';
    final w = getWeight(useKg: useKg);
    final u = useKg ? 'kg' : 'lbs';
    if (w == w.roundToDouble()) {
      return '${w.toInt()} $u';
    }
    return '${w.toStringAsFixed(1)} $u';
  }

  /// Get formatted display string (e.g., "135 lbs × 8")
  String getFormattedDisplay({required bool useKg}) {
    final weightStr = getFormattedWeight(useKg: useKg);
    if (isFailure) {
      return '$weightStr × AMRAP';
    }
    return '$weightStr × $reps';
  }

  @override
  List<Object?> get props => [
        weight,
        reps,
        unit,
        isBodyweight,
        isFailure,
        isWarmup,
        originalInput,
        notes,
      ];
}

/// A new exercise to add to the workout (contains exercise name).
@JsonSerializable()
class ExerciseToAdd extends Equatable {
  final String name;
  final int sets;
  final int reps;
  @JsonKey(name: 'weight_kg')
  final double? weightKg;
  @JsonKey(name: 'weight_lbs')
  final double? weightLbs;
  @JsonKey(name: 'rest_seconds')
  final int restSeconds;
  @JsonKey(name: 'is_bodyweight')
  final bool isBodyweight;
  @JsonKey(name: 'original_text')
  final String originalText;
  final double confidence;
  final String? notes;

  const ExerciseToAdd({
    required this.name,
    this.sets = 3,
    this.reps = 10,
    this.weightKg,
    this.weightLbs,
    this.restSeconds = 60,
    this.isBodyweight = false,
    this.originalText = '',
    this.confidence = 1.0,
    this.notes,
  });

  factory ExerciseToAdd.fromJson(Map<String, dynamic> json) =>
      _$ExerciseToAddFromJson(json);

  Map<String, dynamic> toJson() => _$ExerciseToAddToJson(this);

  /// Get weight in user's preferred unit
  double? getWeight({required bool useKg}) {
    if (isBodyweight) return null;
    return useKg ? weightKg : weightLbs;
  }

  /// Get formatted weight string
  String getFormattedWeight({required bool useKg}) {
    if (isBodyweight) return 'Bodyweight';
    final weight = getWeight(useKg: useKg);
    if (weight == null) return 'Bodyweight';
    final unit = useKg ? 'kg' : 'lbs';
    if (weight == weight.roundToDouble()) {
      return '${weight.toInt()} $unit';
    }
    return '${weight.toStringAsFixed(1)} $unit';
  }

  /// Get formatted sets x reps string
  String get formattedSetsReps => '$sets × $reps';

  /// Get formatted summary (e.g., "Deadlift (3×10 @ 135 lbs)")
  String getFormattedSummary({required bool useKg}) {
    return '$name ($formattedSetsReps @ ${getFormattedWeight(useKg: useKg)})';
  }

  /// Check if low confidence parse
  bool get isLowConfidence => confidence < 0.7;

  /// Convert to ParsedExercise for compatibility
  ParsedExercise toParsedExercise() {
    return ParsedExercise(
      name: name,
      sets: sets,
      reps: reps,
      weightKg: weightKg,
      weightLbs: weightLbs,
      weightUnit: weightLbs != null ? 'lbs' : 'kg',
      restSeconds: restSeconds,
      originalText: originalText,
      confidence: confidence,
      notes: notes,
    );
  }

  @override
  List<Object?> get props => [
        name,
        sets,
        reps,
        weightKg,
        weightLbs,
        restSeconds,
        isBodyweight,
        originalText,
        confidence,
        notes,
      ];
}

/// Response from the V2 parse workout input API.
///
/// Supports DUAL modes:
/// - [setsToLog]: Sets for the CURRENT exercise (just weight*reps)
/// - [exercisesToAdd]: NEW exercises to add (contains exercise names)
@JsonSerializable()
class ParseWorkoutInputV2Response extends Equatable {
  @JsonKey(name: 'sets_to_log')
  final List<SetToLog> setsToLog;
  @JsonKey(name: 'exercises_to_add')
  final List<ExerciseToAdd> exercisesToAdd;
  final String summary;
  final List<String> warnings;

  const ParseWorkoutInputV2Response({
    this.setsToLog = const [],
    this.exercisesToAdd = const [],
    required this.summary,
    this.warnings = const [],
  });

  factory ParseWorkoutInputV2Response.fromJson(Map<String, dynamic> json) =>
      _$ParseWorkoutInputV2ResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ParseWorkoutInputV2ResponseToJson(this);

  /// Check if there's any data parsed
  bool get hasData => setsToLog.isNotEmpty || exercisesToAdd.isNotEmpty;

  /// Check if only sets (no exercises)
  bool get hasOnlySets => setsToLog.isNotEmpty && exercisesToAdd.isEmpty;

  /// Check if only exercises (no sets)
  bool get hasOnlyExercises => exercisesToAdd.isNotEmpty && setsToLog.isEmpty;

  /// Check if both sets and exercises
  bool get hasBoth => setsToLog.isNotEmpty && exercisesToAdd.isNotEmpty;

  @override
  List<Object?> get props => [setsToLog, exercisesToAdd, summary, warnings];
}
