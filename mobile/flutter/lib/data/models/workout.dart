import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'exercise.dart';

part 'workout.g.dart';

/// Parse generation_metadata which can be String or Map from API
Map<String, dynamic>? _parseGenerationMetadata(dynamic value) {
  if (value == null) return null;
  if (value is Map<String, dynamic>) return value;
  if (value is String) {
    if (value.isEmpty) return null;
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } catch (_) {
      return null;
    }
  }
  return null;
}

/// Cache for parsed exercises, keyed by Workout instance.
/// Uses Expando so entries are garbage-collected when the Workout is.
final Expando<List<WorkoutExercise>> _exerciseCache = Expando<List<WorkoutExercise>>();

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
      if (exercisesJson is String) {
        exercisesList = jsonDecode(exercisesJson as String) as List;
      } else if (exercisesJson is List) {
        exercisesList = exercisesJson as List;
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
          return WorkoutExercise.fromJson(exerciseMap);
        }
        return null;
      }).whereType<WorkoutExercise>().toList();
      _exerciseCache[this] = result;
      return result;
    } catch (e) {
      // Log the actual error for debugging
      print('❌ [Workout.exercises] Parse error: $e');
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

  /// Calculate estimated calories (6 cal/min)
  int get estimatedCalories => (durationMinutes ?? 0) * 6;

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
        durationMinutes,
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

  const WorkoutCompletionResponse({
    required this.workout,
    this.personalRecords = const [],
    this.performanceComparison,
    this.strengthScoresUpdated = false,
    this.message = 'Workout completed successfully',
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

/// Response from workout summary API (for completed workouts)
class WorkoutSummaryResponse {
  final Map<String, dynamic> workout;
  final PerformanceComparisonInfo? performanceComparison;
  final List<PersonalRecordInfo> personalRecords;
  final String? coachSummary;
  final String? completionMethod;
  final String? completedAt;

  const WorkoutSummaryResponse({
    required this.workout,
    this.performanceComparison,
    this.personalRecords = const [],
    this.coachSummary,
    this.completionMethod,
    this.completedAt,
  });

  factory WorkoutSummaryResponse.fromJson(Map<String, dynamic> json) {
    final workoutData = json['workout'] as Map<String, dynamic>? ?? {};
    final prsData = json['personal_records'] as List<dynamic>? ?? [];
    final comparisonData = json['performance_comparison'] as Map<String, dynamic>?;

    return WorkoutSummaryResponse(
      workout: workoutData,
      performanceComparison: comparisonData != null
          ? PerformanceComparisonInfo.fromJson(comparisonData)
          : null,
      personalRecords: prsData
          .map((pr) => PersonalRecordInfo.fromJson(pr as Map<String, dynamic>))
          .toList(),
      coachSummary: json['coach_summary'] as String?,
      completionMethod: json['completion_method'] as String?,
      completedAt: json['completed_at'] as String?,
    );
  }

  /// Check if any PRs were achieved
  bool get hasPRs => personalRecords.isNotEmpty;

  /// Check if performance comparison data is available
  bool get hasComparison => performanceComparison != null;

  /// Whether this was a quick mark-as-done (no tracking)
  bool get isMarkedDone => completionMethod == 'marked_done';
}
