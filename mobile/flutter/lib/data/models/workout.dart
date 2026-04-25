import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'exercise.dart';

part 'workout.g.dart';

/// Parse generation_metadata which can be Map, a JSON string, or — in some
/// older rows — a JSON string that itself decodes to *another* JSON string
/// (double-encoded: the Supabase jsonb column was populated with
/// `json.dumps(json.dumps(...))` somewhere up the write path). We unwrap
/// up to two layers so every downstream consumer gets a usable map.
Map<String, dynamic>? _parseGenerationMetadata(dynamic value) {
  if (value == null) return null;
  dynamic current = value;
  for (var i = 0; i < 3; i++) {
    if (current is Map<String, dynamic>) return current;
    if (current is Map) return current.cast<String, dynamic>();
    if (current is String) {
      if (current.isEmpty) return null;
      try {
        current = jsonDecode(current);
      } catch (_) {
        return null;
      }
      continue;
    }
    return null;
  }
  return null;
}

/// Cache for parsed exercises, keyed by Workout instance.
/// Uses Expando so entries are garbage-collected when the Workout is.
final Expando<List<WorkoutExercise>> _exerciseCache = Expando<List<WorkoutExercise>>();

/// Matches a trailing "(N)" suffix left behind by duplicate library imports
/// (e.g. `Burpee(1)`, `Bird Dog (3)`). Mirrors backend `strip_dedup_suffix`.
final RegExp _dedupSuffixRegex = RegExp(r'\s*\(\s*\d+\s*\)\s*$');

String _stripDedupSuffix(String name) {
  if (name.isEmpty) return name;
  return name.replaceFirst(_dedupSuffixRegex, '').trim();
}

@JsonSerializable()
class Workout extends Equatable {
  final String? id;
  @JsonKey(name: 'user_id')
  final String? userId;
  final String? name;
  final String? description;
  final String? type;
  final String? difficulty;
  @JsonKey(name: 'scheduled_date')
  final String? scheduledDate;
  @JsonKey(name: 'is_completed')
  final bool? isCompleted;
  @JsonKey(name: 'exercises_json')
  final dynamic exercisesJson; // Can be String or List
  @JsonKey(name: 'duration_minutes')
  final int? durationMinutes;
  @JsonKey(name: 'duration_minutes_min')
  final int? durationMinutesMin;
  @JsonKey(name: 'duration_minutes_max')
  final int? durationMinutesMax;
  @JsonKey(name: 'estimated_duration_minutes')
  final int? estimatedDurationMinutes;
  @JsonKey(name: 'estimated_calories')
  final int? estimatedCaloriesStored;
  @JsonKey(name: 'generation_method')
  final String? generationMethod;
  @JsonKey(name: 'generation_metadata', fromJson: _parseGenerationMetadata)
  final Map<String, dynamic>? generationMetadata; // Contains challenge_exercise for beginners
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;
  @JsonKey(name: 'completed_at')
  final String? completedAt;
  @JsonKey(name: 'completion_method')
  final String? completionMethod;
  @JsonKey(name: 'is_favorite')
  final bool? isFavorite;

  /// Optional known exercise count (used when exercises aren't fully loaded)
  /// This is set when converting from TodayWorkoutSummary which has count from API
  @JsonKey(includeFromJson: false, includeToJson: false)
  final int? knownExerciseCount;

  const Workout({
    this.id,
    this.userId,
    this.name,
    this.description,
    this.type,
    this.difficulty,
    this.scheduledDate,
    this.isCompleted,
    this.exercisesJson,
    this.durationMinutes,
    this.durationMinutesMin,
    this.durationMinutesMax,
    this.estimatedDurationMinutes,
    this.estimatedCaloriesStored,
    this.generationMethod,
    this.generationMetadata,
    this.createdAt,
    this.updatedAt,
    this.completedAt,
    this.completionMethod,
    this.isFavorite,
    this.knownExerciseCount,
  });

  factory Workout.fromJson(Map<String, dynamic> json) => _$WorkoutFromJson(json);
  Map<String, dynamic> toJson() => _$WorkoutToJson(this);

  /// Parse exercises from JSON (memoized - only parses once per instance)
  List<WorkoutExercise> get exercises {
    final cached = _exerciseCache[this];
    if (cached != null) return cached;

    if (exercisesJson == null) return const [];
    try {
      List<dynamic> exercisesList;
      if (exercisesJson is List) {
        exercisesList = exercisesJson as List;
      } else if (exercisesJson is String) {
        exercisesList = jsonDecode(exercisesJson as String) as List;
      } else {
        return const [];
      }
      final result = exercisesList.map((e) {
        // Handle case where exercise is already a WorkoutExercise object
        if (e is WorkoutExercise) {
          return e;
        }
        // Handle case where exercise is a Map (from JSON)
        if (e is Map<String, dynamic>) {
          // Deep convert any SetTarget objects in set_targets to Maps
          final Map<String, dynamic> exerciseMap = Map<String, dynamic>.from(e);
          if (exerciseMap['set_targets'] is List) {
            exerciseMap['set_targets'] = (exerciseMap['set_targets'] as List).map((st) {
              if (st is SetTarget) {
                return st.toJson();
              }
              return st;
            }).toList();
          }
          // Strip trailing "(N)" import-duplicate suffix from legacy rows
          // (e.g. "Burpee(1)"). Newer backend code never stores these, but
          // older workouts in the DB/cache still contain them.
          final rawName = exerciseMap['name'];
          if (rawName is String) {
            final cleaned = _stripDedupSuffix(rawName);
            if (cleaned != rawName) {
              exerciseMap['name'] = cleaned;
            }
          }
          return WorkoutExercise.fromJson(exerciseMap);
        }
        return null;
      }).whereType<WorkoutExercise>().toList();
      _exerciseCache[this] = result;
      return result;
    } catch (e) {
      // Log the actual error for debugging
      debugPrint('❌ [Workout.exercises] Parse error: $e');
      return const [];
    }
  }

  /// Get exercise count (excluding challenge exercise)
  /// Uses knownExerciseCount as fallback when exercises aren't loaded
  int get exerciseCount {
    final parsedCount = exercises.length;
    // If we have parsed exercises, use that count
    if (parsedCount > 0) return parsedCount;
    // Otherwise use the known count from API if available
    return knownExerciseCount ?? 0;
  }

  /// Get challenge exercise from generation metadata (for beginners)
  WorkoutExercise? get challengeExercise {
    if (generationMetadata == null) return null;
    final challengeData = generationMetadata!['challenge_exercise'];
    if (challengeData == null) return null;
    try {
      return WorkoutExercise.fromJson(challengeData as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Check if workout has a challenge exercise
  bool get hasChallenge => challengeExercise != null;

  /// Best available duration: AI-estimated > user-requested > 45 default
  int get bestDurationMinutes =>
      estimatedDurationMinutes ?? durationMinutes ?? 45;

  /// Calorie estimate: prefer server-computed, fallback to MET-based calculation
  int get estimatedCalories {
    if (estimatedCaloriesStored != null && estimatedCaloriesStored! > 0) {
      return estimatedCaloriesStored!;
    }
    final minutes = bestDurationMinutes;
    if (minutes <= 0) return 0;
    final met = _estimateMET();
    return (met * 70.0 * (minutes / 60.0)).round();
  }

  double _estimateMET() {
    final exList = exercises;
    if (exList.isEmpty) return 3.5;

    const compoundMuscles = {
      'full_body', 'legs', 'back', 'chest', 'glutes',
      'quadriceps', 'hamstrings', 'shoulders',
    };
    int compoundCount = 0;
    int totalSets = 0;
    int totalReps = 0;
    double totalWeightVolume = 0; // sets × reps × weight
    double restSum = 0;
    int restCount = 0;
    final supersetGroups = <int>{};
    int dropSetExercises = 0;

    for (final ex in exList) {
      final sets = ex.sets ?? 3;
      final reps = ex.reps ?? 10;
      final weight = ex.weight ?? 0;

      totalSets += sets;
      totalReps += sets * reps;
      totalWeightVolume += sets * reps * weight;

      if ((ex.restSeconds ?? 0) > 0) {
        restSum += ex.restSeconds!;
        restCount++;
      }
      if (compoundMuscles.contains((ex.primaryMuscle ?? '').toLowerCase())) {
        compoundCount++;
      }
      if (ex.supersetGroup != null) {
        supersetGroups.add(ex.supersetGroup!);
      }
      if (ex.isDropSet == true) {
        dropSetExercises++;
      }
    }

    final avgRest = restCount > 0 ? restSum / restCount : 60.0;

    // Base MET for weight training
    double met = 3.5;

    // Exercise count: more exercises = higher density
    if (exList.length >= 6) met += 0.3;
    if (exList.length >= 9) met += 0.2;

    // Compound lift ratio — more compounds = more muscle mass engaged
    if (compoundCount >= 3) met += 0.5;
    if (compoundCount >= 5) met += 0.3;

    // Volume: total sets drive work capacity
    if (totalSets >= 15) met += 0.3;
    if (totalSets >= 25) met += 0.3;

    // High rep ranges increase metabolic demand
    final avgReps = exList.isNotEmpty ? totalReps / exList.length : 10;
    if (avgReps >= 12) met += 0.3;
    if (avgReps >= 15) met += 0.2;

    // Weight volume — heavier loads require more energy
    // Rough threshold: >5000 kg total volume is significant work
    if (totalWeightVolume > 5000) met += 0.3;
    if (totalWeightVolume > 15000) met += 0.3;

    // Short rest periods increase intensity (circuit-like effect)
    if (avgRest < 60) met += 0.5;
    if (avgRest < 30) met += 0.3;

    // Supersets reduce rest and increase metabolic demand
    if (supersetGroups.isNotEmpty) {
      met += 0.3 + (supersetGroups.length * 0.1).clamp(0, 0.5);
    }

    // Drop sets add extra volume per exercise
    if (dropSetExercises > 0) {
      met += 0.2 + (dropSetExercises * 0.1).clamp(0, 0.4);
    }

    // Workout type boost
    final wt = (type ?? '').toLowerCase();
    if (wt.contains('hiit') || wt.contains('circuit')) {
      met += 1.5;
    } else if (wt.contains('cardio')) {
      met += 1.0;
    }

    // Difficulty boost
    final d = (difficulty ?? '').toLowerCase();
    if (d == 'hell' || d == 'extreme' || d == 'insane') {
      met += 2.0;
    } else if (d == 'hard' || d == 'advanced' || d == 'challenging') {
      met += 1.2;
    } else if (d == 'moderate' || d == 'intermediate') {
      met += 0.5;
    }

    return met.clamp(3.0, 10.0);
  }

  /// Get formatted duration display (e.g., "~38m" if estimated, "45-60m" or "45m" otherwise)
  String get formattedDurationShort {
    // Prefer estimated duration if available
    if (estimatedDurationMinutes != null) {
      return '~${estimatedDurationMinutes}m';
    }
    // Fall back to range or target duration
    if (durationMinutesMin != null && durationMinutesMax != null &&
        durationMinutesMin != durationMinutesMax) {
      return '$durationMinutesMin-${durationMinutesMax}m';
    }
    return '${durationMinutes ?? 45}m';
  }

  /// Get formatted duration display full (e.g., "~38 min" if estimated, "45-60 min" or "45 min" otherwise)
  String get formattedDuration {
    // Prefer estimated duration if available
    if (estimatedDurationMinutes != null) {
      return '~$estimatedDurationMinutes min';
    }
    // Fall back to range or target duration
    if (durationMinutesMin != null && durationMinutesMax != null &&
        durationMinutesMin != durationMinutesMax) {
      return '$durationMinutesMin-$durationMinutesMax min';
    }
    return '${durationMinutes ?? 45} min';
  }

  /// Extract the "YYYY-MM-DD" date key from scheduledDate, avoiding
  /// timezone-sensitive DateTime.parse (which creates UTC midnight for
  /// date-only strings, causing .toLocal() to shift the date backward).
  String? get scheduledDateKey {
    if (scheduledDate == null) return null;
    return scheduledDate!.split('T')[0];
  }

  /// Get a local date-only DateTime from scheduledDate by splitting
  /// the string first, avoiding UTC→local timezone shift bugs.
  DateTime? get scheduledLocalDate {
    final key = scheduledDateKey;
    if (key == null) return null;
    try {
      final parts = key.split('-');
      if (parts.length != 3) return null;
      return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    } catch (_) {
      return null;
    }
  }

  /// Get formatted date
  String get formattedDate {
    final date = scheduledLocalDate;
    if (date == null) return scheduledDate ?? '';
    return '${date.month}/${date.day}/${date.year}';
  }

  /// Check if workout is today
  bool get isToday {
    final key = scheduledDateKey;
    if (key == null) return false;
    final now = DateTime.now();
    final todayKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return key == todayKey;
  }

  /// Get primary muscle groups
  List<String> get primaryMuscles {
    final muscles = <String>{};
    for (final exercise in exercises) {
      if (exercise.primaryMuscle != null) {
        muscles.add(exercise.primaryMuscle!);
      }
      if (exercise.muscleGroup != null) {
        muscles.add(exercise.muscleGroup!);
      }
    }
    return muscles.toList();
  }

  /// Get equipment needed
  List<String> get equipmentNeeded {
    final equipment = <String>{};
    for (final exercise in exercises) {
      if (exercise.equipment != null && exercise.equipment!.isNotEmpty) {
        String eq = exercise.equipment!;
        // Normalize equipment names
        final lowerEq = eq.toLowerCase();
        if (lowerEq.contains('none') ||
            lowerEq == 'bodyweight' ||
            lowerEq == 'body weight') {
          eq = 'Bodyweight';
        }
        equipment.add(eq);
      }
    }
    // Remove bodyweight variations - we only show actual equipment needed
    equipment.removeWhere((e) => e.toLowerCase() == 'bodyweight');
    return equipment.toList();
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        description,
        type,
        difficulty,
        scheduledDate,
        isCompleted,
        exercisesJson,
        durationMinutes,
        estimatedCaloriesStored,
        generationMetadata,
        completedAt,
        completionMethod,
        isFavorite,
        knownExerciseCount,
      ];

  Workout copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    String? type,
    String? difficulty,
    String? scheduledDate,
    bool? isCompleted,
    dynamic exercisesJson,
    int? durationMinutes,
    int? estimatedCaloriesStored,
    String? generationMethod,
    Map<String, dynamic>? generationMetadata,
    String? createdAt,
    String? updatedAt,
    String? completedAt,
    String? completionMethod,
    bool? isFavorite,
    int? knownExerciseCount,
  }) {
    return Workout(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      difficulty: difficulty ?? this.difficulty,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      isCompleted: isCompleted ?? this.isCompleted,
      exercisesJson: exercisesJson ?? this.exercisesJson,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      estimatedCaloriesStored: estimatedCaloriesStored ?? this.estimatedCaloriesStored,
      generationMethod: generationMethod ?? this.generationMethod,
      generationMetadata: generationMetadata ?? this.generationMetadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      completionMethod: completionMethod ?? this.completionMethod,
      isFavorite: isFavorite ?? this.isFavorite,
      knownExerciseCount: knownExerciseCount ?? this.knownExerciseCount,
    );
  }
}

/// Personal Record info returned from workout completion API
class PersonalRecordInfo {
  final String exerciseName;
  final double weightKg;
  final int reps;
  final double estimated1rmKg;
  final double? previous1rmKg;
  final double? improvementKg;
  final double? improvementPercent;
  final bool isAllTimePr;
  final String? celebrationMessage;

  const PersonalRecordInfo({
    required this.exerciseName,
    required this.weightKg,
    required this.reps,
    required this.estimated1rmKg,
    this.previous1rmKg,
    this.improvementKg,
    this.improvementPercent,
    this.isAllTimePr = true,
    this.celebrationMessage,
  });

  factory PersonalRecordInfo.fromJson(Map<String, dynamic> json) {
    return PersonalRecordInfo(
      exerciseName: json['exercise_name'] as String? ?? '',
      weightKg: (json['weight_kg'] as num?)?.toDouble() ?? 0.0,
      reps: json['reps'] as int? ?? 0,
      estimated1rmKg: (json['estimated_1rm_kg'] as num?)?.toDouble() ?? 0.0,
      previous1rmKg: (json['previous_1rm_kg'] as num?)?.toDouble(),
      improvementKg: (json['improvement_kg'] as num?)?.toDouble(),
      improvementPercent: (json['improvement_percent'] as num?)?.toDouble(),
      isAllTimePr: json['is_all_time_pr'] as bool? ?? true,
      celebrationMessage: json['celebration_message'] as String?,
    );
  }
}

/// Exercise comparison data - improvements/setbacks vs previous session
class ExerciseComparisonInfo {
  final String exerciseName;
  final String? exerciseId;

  // Current session
  final int currentSets;
  final int currentReps;
  final double currentVolumeKg;
  final double? currentMaxWeightKg;
  final double? current1rmKg;
  final int? currentTimeSeconds;

  // Previous session
  final int? previousSets;
  final int? previousReps;
  final double? previousVolumeKg;
  final double? previousMaxWeightKg;
  final double? previous1rmKg;
  final int? previousTimeSeconds;
  final DateTime? previousDate;

  // Differences
  final double? volumeDiffKg;
  final double? volumeDiffPercent;
  final double? weightDiffKg;
  final double? weightDiffPercent;
  final double? rmDiffKg;
  final double? rmDiffPercent;
  final int? timeDiffSeconds;
  final double? timeDiffPercent;
  final int? repsDiff;
  final int? setsDiff;

  // Status: 'improved', 'maintained', 'declined', 'first_time'
  final String status;

  const ExerciseComparisonInfo({
    required this.exerciseName,
    this.exerciseId,
    this.currentSets = 0,
    this.currentReps = 0,
    this.currentVolumeKg = 0.0,
    this.currentMaxWeightKg,
    this.current1rmKg,
    this.currentTimeSeconds,
    this.previousSets,
    this.previousReps,
    this.previousVolumeKg,
    this.previousMaxWeightKg,
    this.previous1rmKg,
    this.previousTimeSeconds,
    this.previousDate,
    this.volumeDiffKg,
    this.volumeDiffPercent,
    this.weightDiffKg,
    this.weightDiffPercent,
    this.rmDiffKg,
    this.rmDiffPercent,
    this.timeDiffSeconds,
    this.timeDiffPercent,
    this.repsDiff,
    this.setsDiff,
    this.status = 'first_time',
  });

  factory ExerciseComparisonInfo.fromJson(Map<String, dynamic> json) {
    return ExerciseComparisonInfo(
      exerciseName: json['exercise_name'] as String? ?? '',
      exerciseId: json['exercise_id'] as String?,
      currentSets: json['current_sets'] as int? ?? 0,
      currentReps: json['current_reps'] as int? ?? 0,
      currentVolumeKg: (json['current_volume_kg'] as num?)?.toDouble() ?? 0.0,
      currentMaxWeightKg: (json['current_max_weight_kg'] as num?)?.toDouble(),
      current1rmKg: (json['current_1rm_kg'] as num?)?.toDouble(),
      currentTimeSeconds: json['current_time_seconds'] as int?,
      previousSets: json['previous_sets'] as int?,
      previousReps: json['previous_reps'] as int?,
      previousVolumeKg: (json['previous_volume_kg'] as num?)?.toDouble(),
      previousMaxWeightKg: (json['previous_max_weight_kg'] as num?)?.toDouble(),
      previous1rmKg: (json['previous_1rm_kg'] as num?)?.toDouble(),
      previousTimeSeconds: json['previous_time_seconds'] as int?,
      previousDate: json['previous_date'] != null
          ? DateTime.tryParse(json['previous_date'] as String)
          : null,
      volumeDiffKg: (json['volume_diff_kg'] as num?)?.toDouble(),
      volumeDiffPercent: (json['volume_diff_percent'] as num?)?.toDouble(),
      weightDiffKg: (json['weight_diff_kg'] as num?)?.toDouble(),
      weightDiffPercent: (json['weight_diff_percent'] as num?)?.toDouble(),
      rmDiffKg: (json['rm_diff_kg'] as num?)?.toDouble(),
      rmDiffPercent: (json['rm_diff_percent'] as num?)?.toDouble(),
      timeDiffSeconds: json['time_diff_seconds'] as int?,
      timeDiffPercent: (json['time_diff_percent'] as num?)?.toDouble(),
      repsDiff: json['reps_diff'] as int?,
      setsDiff: json['sets_diff'] as int?,
      status: json['status'] as String? ?? 'first_time',
    );
  }

  /// Whether this exercise has previous data to compare
  bool get hasPrevious => status != 'first_time';

  /// Whether performance improved
  bool get isImproved => status == 'improved';

  /// Whether performance declined
  bool get isDeclined => status == 'declined';

  /// Whether performance was maintained
  bool get isMaintained => status == 'maintained';

  /// Get formatted weight difference string (e.g., "+5.0 kg")
  String get formattedWeightDiff {
    if (weightDiffKg == null) return '';
    final sign = weightDiffKg! >= 0 ? '+' : '';
    return '$sign${weightDiffKg!.toStringAsFixed(1)} kg';
  }

  /// Get formatted percentage difference string (e.g., "+5.2%")
  String get formattedPercentDiff {
    final percent = rmDiffPercent ?? volumeDiffPercent;
    if (percent == null) return '';
    final sign = percent >= 0 ? '+' : '';
    return '$sign${percent.toStringAsFixed(1)}%';
  }

  /// Get formatted time difference string (e.g., "+30s" or "-1m 15s")
  String get formattedTimeDiff {
    if (timeDiffSeconds == null) return '';
    final abs = timeDiffSeconds!.abs();
    final sign = timeDiffSeconds! >= 0 ? '+' : '-';
    if (abs >= 60) {
      final mins = abs ~/ 60;
      final secs = abs % 60;
      return '$sign${mins}m ${secs}s';
    }
    return '$sign${abs}s';
  }
}

/// Workout comparison data - overall workout vs previous similar workout
class WorkoutComparisonInfo {
  // Current workout
  final int currentDurationSeconds;
  final double currentTotalVolumeKg;
  final int currentTotalSets;
  final int currentTotalReps;
  final int currentExercises;
  final int currentCalories;

  // Previous workout
  final bool hasPrevious;
  final int? previousDurationSeconds;
  final double? previousTotalVolumeKg;
  final int? previousTotalSets;
  final int? previousTotalReps;
  final DateTime? previousPerformedAt;

  // Differences
  final int? durationDiffSeconds;
  final double? durationDiffPercent;
  final double? volumeDiffKg;
  final double? volumeDiffPercent;

  // Overall status
  final String overallStatus;

  const WorkoutComparisonInfo({
    this.currentDurationSeconds = 0,
    this.currentTotalVolumeKg = 0.0,
    this.currentTotalSets = 0,
    this.currentTotalReps = 0,
    this.currentExercises = 0,
    this.currentCalories = 0,
    this.hasPrevious = false,
    this.previousDurationSeconds,
    this.previousTotalVolumeKg,
    this.previousTotalSets,
    this.previousTotalReps,
    this.previousPerformedAt,
    this.durationDiffSeconds,
    this.durationDiffPercent,
    this.volumeDiffKg,
    this.volumeDiffPercent,
    this.overallStatus = 'first_time',
  });

  factory WorkoutComparisonInfo.fromJson(Map<String, dynamic> json) {
    return WorkoutComparisonInfo(
      currentDurationSeconds: json['current_duration_seconds'] as int? ?? 0,
      currentTotalVolumeKg: (json['current_total_volume_kg'] as num?)?.toDouble() ?? 0.0,
      currentTotalSets: json['current_total_sets'] as int? ?? 0,
      currentTotalReps: json['current_total_reps'] as int? ?? 0,
      currentExercises: json['current_exercises'] as int? ?? 0,
      currentCalories: json['current_calories'] as int? ?? 0,
      hasPrevious: json['has_previous'] as bool? ?? false,
      previousDurationSeconds: json['previous_duration_seconds'] as int?,
      previousTotalVolumeKg: (json['previous_total_volume_kg'] as num?)?.toDouble(),
      previousTotalSets: json['previous_total_sets'] as int?,
      previousTotalReps: json['previous_total_reps'] as int?,
      previousPerformedAt: json['previous_performed_at'] != null
          ? DateTime.tryParse(json['previous_performed_at'] as String)
          : null,
      durationDiffSeconds: json['duration_diff_seconds'] as int?,
      durationDiffPercent: (json['duration_diff_percent'] as num?)?.toDouble(),
      volumeDiffKg: (json['volume_diff_kg'] as num?)?.toDouble(),
      volumeDiffPercent: (json['volume_diff_percent'] as num?)?.toDouble(),
      overallStatus: json['overall_status'] as String? ?? 'first_time',
    );
  }

  /// Get formatted duration difference string
  String get formattedDurationDiff {
    if (durationDiffSeconds == null) return '';
    final abs = durationDiffSeconds!.abs();
    final sign = durationDiffSeconds! >= 0 ? '+' : '-';
    if (abs >= 60) {
      final mins = abs ~/ 60;
      final secs = abs % 60;
      if (secs > 0) return '$sign${mins}m ${secs}s';
      return '$sign${mins}m';
    }
    return '$sign${abs}s';
  }

  /// Get formatted volume difference string
  String get formattedVolumeDiff {
    if (volumeDiffKg == null) return '';
    final sign = volumeDiffKg! >= 0 ? '+' : '';
    return '$sign${volumeDiffKg!.toStringAsFixed(0)} kg';
  }
}

/// Complete performance comparison for workout completion
class PerformanceComparisonInfo {
  final WorkoutComparisonInfo workoutComparison;
  final List<ExerciseComparisonInfo> exerciseComparisons;
  final int improvedCount;
  final int maintainedCount;
  final int declinedCount;
  final int firstTimeCount;

  const PerformanceComparisonInfo({
    required this.workoutComparison,
    this.exerciseComparisons = const [],
    this.improvedCount = 0,
    this.maintainedCount = 0,
    this.declinedCount = 0,
    this.firstTimeCount = 0,
  });

  factory PerformanceComparisonInfo.fromJson(Map<String, dynamic> json) {
    final workoutData = json['workout_comparison'] as Map<String, dynamic>? ?? {};
    final exercisesData = json['exercise_comparisons'] as List<dynamic>? ?? [];

    return PerformanceComparisonInfo(
      workoutComparison: WorkoutComparisonInfo.fromJson(workoutData),
      exerciseComparisons: exercisesData
          .map((e) => ExerciseComparisonInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      improvedCount: json['improved_count'] as int? ?? 0,
      maintainedCount: json['maintained_count'] as int? ?? 0,
      declinedCount: json['declined_count'] as int? ?? 0,
      firstTimeCount: json['first_time_count'] as int? ?? 0,
    );
  }

  /// Total exercises compared
  int get totalExercises => exerciseComparisons.length;

  /// Whether any exercises improved
  bool get hasImprovements => improvedCount > 0;

  /// Whether any exercises declined
  bool get hasDeclines => declinedCount > 0;

  /// Get exercises that improved
  List<ExerciseComparisonInfo> get improvedExercises =>
      exerciseComparisons.where((e) => e.isImproved).toList();

  /// Get exercises that declined
  List<ExerciseComparisonInfo> get declinedExercises =>
      exerciseComparisons.where((e) => e.isDeclined).toList();
}

/// Response from workout completion API including PRs and performance comparison
class WorkoutCompletionResponse {
  final Workout workout;
  final List<PersonalRecordInfo> personalRecords;
  final PerformanceComparisonInfo? performanceComparison;
  final bool strengthScoresUpdated;
  final String message;
  /// Workstream 1 (Day 0-7 retention). True when this was the user's
  /// first-ever completed workout — the frontend should fire the
  /// First Workout Forecast sheet after confetti.
  final bool isFirstWorkout;
  /// Server-side XP award guarantee. When `xpAwarded == true`, the server
  /// has already inserted the daily workout_complete XP transaction — the
  /// client MUST skip its own `/xp/award-goal-xp` call to avoid redundant
  /// network round-trips (the server dedup would treat it as a no-op
  /// anyway, but skipping avoids the pointless request).
  final bool xpAwarded;
  final int xpAmount;

  const WorkoutCompletionResponse({
    required this.workout,
    this.personalRecords = const [],
    this.performanceComparison,
    this.strengthScoresUpdated = false,
    this.message = 'Workout completed successfully',
    this.isFirstWorkout = false,
    this.xpAwarded = false,
    this.xpAmount = 0,
  });

  factory WorkoutCompletionResponse.fromJson(Map<String, dynamic> json) {
    final workoutData = json['workout'] as Map<String, dynamic>? ?? json;
    final prsData = json['personal_records'] as List<dynamic>? ?? [];
    final comparisonData = json['performance_comparison'] as Map<String, dynamic>?;

    return WorkoutCompletionResponse(
      workout: Workout.fromJson(workoutData),
      personalRecords: prsData
          .map((pr) => PersonalRecordInfo.fromJson(pr as Map<String, dynamic>))
          .toList(),
      performanceComparison: comparisonData != null
          ? PerformanceComparisonInfo.fromJson(comparisonData)
          : null,
      strengthScoresUpdated: json['strength_scores_updated'] as bool? ?? false,
      message: json['message'] as String? ?? 'Workout completed successfully',
      isFirstWorkout: json['is_first_workout'] as bool? ?? false,
      xpAwarded: json['xp_awarded'] as bool? ?? false,
      xpAmount: json['xp_amount'] as int? ?? 0,
    );
  }

  /// Check if workout is completed (from underlying workout)
  bool get isCompleted => workout.isCompleted ?? false;

  /// Check if any PRs were achieved
  bool get hasPRs => personalRecords.isNotEmpty;

  /// Get count of PRs
  int get prCount => personalRecords.length;

  /// Check if performance comparison data is available
  bool get hasComparison => performanceComparison != null;

  /// Check if any exercises improved
  bool get hasImprovements => performanceComparison?.hasImprovements ?? false;

  /// Check if any exercises declined
  bool get hasDeclines => performanceComparison?.hasDeclines ?? false;
}

/// Per-set log data returned from workout summary API. Mirrors
/// `backend.api.v1.workouts.crud_models.SetLogInfo` — every field the active
/// workout writes round-trips here so the summary screen can render notes,
/// audio/photo media, target deltas, set timing, and the logging-mode tier.
class SetLogInfo {
  final String exerciseName;
  final int exerciseIndex;
  final int setNumber;
  final int repsCompleted;
  final double weightKg;
  final double? rpe;
  final int? rir;
  final String setType;

  // Rich fields (post-A4 backend rollout). Each is tolerant of legacy rows
  // that didn't carry the field — empty list / null on absence.
  final List<String> notes;
  final String? notesAudioUrl;
  final List<String> notesPhotoUrls;
  final int? targetReps;
  final double? targetWeightKg;
  final int? failedAtRep;
  final String? recordedAt;
  final String? startedAt;
  final int? setDurationSeconds;
  final int? restDurationSeconds;
  final String? loggingMode;
  final String? aiInputSource;
  final bool? isAiRecommendedSetType;
  final String? tempo;
  final bool? isCompleted;

  const SetLogInfo({
    required this.exerciseName,
    this.exerciseIndex = 0,
    required this.setNumber,
    required this.repsCompleted,
    required this.weightKg,
    this.rpe,
    this.rir,
    this.setType = 'working',
    this.notes = const [],
    this.notesAudioUrl,
    this.notesPhotoUrls = const [],
    this.targetReps,
    this.targetWeightKg,
    this.failedAtRep,
    this.recordedAt,
    this.startedAt,
    this.setDurationSeconds,
    this.restDurationSeconds,
    this.loggingMode,
    this.aiInputSource,
    this.isAiRecommendedSetType,
    this.tempo,
    this.isCompleted,
  });

  factory SetLogInfo.fromJson(Map<String, dynamic> json) {
    return SetLogInfo(
      exerciseName: json['exercise_name'] as String? ?? '',
      exerciseIndex: json['exercise_index'] as int? ?? 0,
      setNumber: json['set_number'] as int? ?? 0,
      repsCompleted: json['reps_completed'] as int? ?? 0,
      weightKg: (json['weight_kg'] as num?)?.toDouble() ?? 0.0,
      rpe: (json['rpe'] as num?)?.toDouble(),
      rir: json['rir'] as int?,
      setType: json['set_type'] as String? ?? 'working',
      notes: _coerceNotes(json['notes']),
      notesAudioUrl: json['notes_audio_url'] as String?,
      notesPhotoUrls: (json['notes_photo_urls'] as List?)
              ?.map((e) => e?.toString() ?? '')
              .where((s) => s.isNotEmpty)
              .toList() ??
          const [],
      targetReps: json['target_reps'] as int?,
      targetWeightKg: (json['target_weight_kg'] as num?)?.toDouble(),
      failedAtRep: json['failed_at_rep'] as int?,
      recordedAt: json['recorded_at'] as String?,
      startedAt: json['started_at'] as String?,
      setDurationSeconds: json['set_duration_seconds'] as int?,
      restDurationSeconds: json['rest_duration_seconds'] as int?,
      loggingMode: json['logging_mode'] as String?,
      aiInputSource: json['ai_input_source'] as String?,
      isAiRecommendedSetType: json['is_ai_recommended_set_type'] as bool?,
      tempo: json['tempo'] as String?,
      isCompleted: json['is_completed'] as bool?,
    );
  }

  /// Backwards-compatible: list (new) | string (legacy) | null → List<String>.
  static List<String> _coerceNotes(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) {
      return raw
          .map((e) => e?.toString().trim() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    }
    if (raw is String) {
      final trimmed = raw.trim();
      return trimmed.isEmpty ? const [] : [trimmed];
    }
    return const [];
  }

  Map<String, dynamic> toJson() => {
    'exercise_name': exerciseName,
    'exercise_index': exerciseIndex,
    'set_number': setNumber,
    'reps_completed': repsCompleted,
    'weight_kg': weightKg,
    'rpe': rpe,
    'rir': rir,
    'set_type': setType,
    'notes': notes,
    if (notesAudioUrl != null) 'notes_audio_url': notesAudioUrl,
    if (notesPhotoUrls.isNotEmpty) 'notes_photo_urls': notesPhotoUrls,
    if (targetReps != null) 'target_reps': targetReps,
    if (targetWeightKg != null) 'target_weight_kg': targetWeightKg,
    if (failedAtRep != null) 'failed_at_rep': failedAtRep,
    if (recordedAt != null) 'recorded_at': recordedAt,
    if (startedAt != null) 'started_at': startedAt,
    if (setDurationSeconds != null) 'set_duration_seconds': setDurationSeconds,
    if (restDurationSeconds != null) 'rest_duration_seconds': restDurationSeconds,
    if (loggingMode != null) 'logging_mode': loggingMode,
    if (aiInputSource != null) 'ai_input_source': aiInputSource,
    if (isAiRecommendedSetType != null)
      'is_ai_recommended_set_type': isAiRecommendedSetType,
    if (tempo != null) 'tempo': tempo,
    if (isCompleted != null) 'is_completed': isCompleted,
  };
}

/// Structured AI coach review parsed from JSON response
class CoachReview {
  final List<String> highlights;
  final List<String> areasToImprove;
  final int overallRating;
  final String summary;

  const CoachReview({
    required this.highlights,
    required this.areasToImprove,
    required this.overallRating,
    required this.summary,
  });

  /// Parse from JSON string. Returns null if parsing fails.
  static CoachReview? tryParse(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      String cleaned = jsonStr.trim();
      if (cleaned.startsWith('```')) {
        cleaned = cleaned.replaceAll(RegExp(r'^```\w*\n?'), '').replaceAll(RegExp(r'\n?```$'), '').trim();
      }
      if (!cleaned.startsWith('{')) return null;

      final json = jsonDecode(cleaned) as Map<String, dynamic>;

      return CoachReview(
        highlights: (json['highlights'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        areasToImprove: (json['areas_to_improve'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        overallRating: (json['overall_rating'] as num?)?.toInt() ?? 7,
        summary: json['summary'] as String? ?? '',
      );
    } catch (_) {
      return null;
    }
  }
}

/// Response from workout summary API (for completed workouts)
class WorkoutSummaryResponse {
  final Map<String, dynamic> workout;
  final PerformanceComparisonInfo? performanceComparison;
  final List<PersonalRecordInfo> personalRecords;
  /// Long-form 2–3 sentence encouragement shown in the Summary tab.
  final String? coachSummary;
  /// Punchy one-liner (≤20 words) anchored to real session deltas.
  /// Rendered as the hero card on the Advanced tab.
  final String? heroNarrative;
  final String? completionMethod;
  final String? completedAt;
  final List<SetLogInfo> setLogs;

  const WorkoutSummaryResponse({
    required this.workout,
    this.performanceComparison,
    this.personalRecords = const [],
    this.coachSummary,
    this.heroNarrative,
    this.completionMethod,
    this.completedAt,
    this.setLogs = const [],
  });

  factory WorkoutSummaryResponse.fromJson(Map<String, dynamic> json) {
    final workoutData = json['workout'] as Map<String, dynamic>? ?? {};
    final prsData = json['personal_records'] as List<dynamic>? ?? [];
    final comparisonData = json['performance_comparison'] as Map<String, dynamic>?;
    final setLogsData = json['set_logs'] as List<dynamic>? ?? [];

    return WorkoutSummaryResponse(
      workout: workoutData,
      performanceComparison: comparisonData != null
          ? PerformanceComparisonInfo.fromJson(comparisonData)
          : null,
      personalRecords: prsData
          .map((pr) => PersonalRecordInfo.fromJson(pr as Map<String, dynamic>))
          .toList(),
      coachSummary: json['coach_summary'] as String?,
      heroNarrative: json['hero_narrative'] as String?,
      completionMethod: json['completion_method'] as String?,
      completedAt: json['completed_at'] as String?,
      setLogs: setLogsData
          .map((sl) => SetLogInfo.fromJson(sl as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Group set logs by exercise name for display
  Map<String, List<SetLogInfo>> get setLogsByExercise {
    final Map<String, List<SetLogInfo>> grouped = {};
    for (final log in setLogs) {
      grouped.putIfAbsent(log.exerciseName, () => []).add(log);
    }
    return grouped;
  }

  /// Parse structured coach review, falls back to null
  CoachReview? get parsedCoachReview => CoachReview.tryParse(coachSummary);

  /// Check if any PRs were achieved
  bool get hasPRs => personalRecords.isNotEmpty;

  /// Check if performance comparison data is available
  bool get hasComparison => performanceComparison != null;

  /// Whether this was a quick mark-as-done (no tracking)
  bool get isMarkedDone => completionMethod == 'marked_done';
}
