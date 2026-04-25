part of 'workout_repository.dart';

/// Result of body part exclusion operation
/// Contains details about which exercises were removed from the workout
class BodyPartExclusionResult {
  final String workoutId;
  final List<String> excludedBodyParts;
  final List<String> removedExercises;
  final int remainingExercises;
  final bool success;
  final String message;

  BodyPartExclusionResult({
    required this.workoutId,
    required this.excludedBodyParts,
    required this.removedExercises,
    required this.remainingExercises,
    this.success = true,
    required this.message,
  });

  factory BodyPartExclusionResult.fromJson(Map<String, dynamic> json) {
    return BodyPartExclusionResult(
      workoutId: json['workout_id'] as String? ?? '',
      excludedBodyParts: List<String>.from(json['excluded_body_parts'] as List? ?? []),
      removedExercises: List<String>.from(json['removed_exercises'] as List? ?? []),
      remainingExercises: (json['remaining_exercises'] as num?)?.toInt() ?? 0,
      success: json['success'] as bool? ?? true,
      message: json['message'] as String? ?? 'Exercises removed successfully',
    );
  }

  /// Whether any exercises were actually removed
  bool get hasRemovedExercises => removedExercises.isNotEmpty;
}

/// Result of exercise replacement operation
/// Contains details about the original and replacement exercise
class ExerciseReplaceResult {
  final bool replaced;
  final bool skipped;
  final String original;
  final String? replacement;
  final String reason;
  final String message;

  ExerciseReplaceResult({
    required this.replaced,
    this.skipped = false,
    required this.original,
    this.replacement,
    required this.reason,
    required this.message,
  });

  factory ExerciseReplaceResult.fromJson(Map<String, dynamic> json) {
    return ExerciseReplaceResult(
      replaced: json['replaced'] as bool? ?? false,
      skipped: json['skipped'] as bool? ?? false,
      original: json['original'] as String? ?? '',
      replacement: json['replacement'] as String?,
      reason: json['reason'] as String? ?? '',
      message: json['message'] as String? ?? '',
    );
  }
}

/// Progression suggestion model
/// Represents an exercise where the user is ready to progress to a harder variant
class ProgressionSuggestion {
  /// Current exercise name that user has mastered
  final String exerciseName;

  /// Suggested harder variant to progress to
  final String suggestedNextVariant;

  /// Number of consecutive sessions rated as "too easy"
  final int consecutiveEasySessions;

  /// Relative difficulty increase (e.g., 0.2 = 20% harder)
  final double? difficultyIncrease;

  /// ID of the progression chain this exercise belongs to
  final String? chainId;

  ProgressionSuggestion({
    required this.exerciseName,
    required this.suggestedNextVariant,
    required this.consecutiveEasySessions,
    this.difficultyIncrease,
    this.chainId,
  });

  factory ProgressionSuggestion.fromJson(Map<String, dynamic> json) {
    return ProgressionSuggestion(
      exerciseName: json['exercise_name'] as String? ?? '',
      suggestedNextVariant: json['suggested_next_variant'] as String? ?? '',
      consecutiveEasySessions: (json['consecutive_easy_sessions'] as num?)?.toInt() ?? 0,
      difficultyIncrease: (json['difficulty_increase'] as num?)?.toDouble(),
      chainId: json['chain_id'] as String?,
    );
  }

  /// Human-readable difficulty increase description
  String get difficultyIncreaseDescription {
    if (difficultyIncrease == null) return '';
    final percent = (difficultyIncrease! * 100).toStringAsFixed(0);
    return '+$percent% difficulty';
  }
}

/// Exercise history item model
class ExerciseHistoryItem {
  final String exerciseName;
  final int totalSets;
  final double? totalVolume;
  final double? maxWeight;
  final int? maxReps;
  final double? estimated1rm;
  final double? avgRpe;
  final String? lastWorkoutDate;
  final ExerciseProgressionTrend? progression;
  final bool hasData;

  ExerciseHistoryItem({
    required this.exerciseName,
    required this.totalSets,
    this.totalVolume,
    this.maxWeight,
    this.maxReps,
    this.estimated1rm,
    this.avgRpe,
    this.lastWorkoutDate,
    this.progression,
    this.hasData = true,
  });

  factory ExerciseHistoryItem.fromJson(Map<String, dynamic> json) {
    return ExerciseHistoryItem(
      exerciseName: json['exercise_name'] as String? ?? 'Unknown',
      totalSets: (json['total_sets'] as num?)?.toInt() ?? 0,
      totalVolume: (json['total_volume'] as num?)?.toDouble(),
      maxWeight: (json['max_weight'] as num?)?.toDouble(),
      maxReps: (json['max_reps'] as num?)?.toInt(),
      estimated1rm: (json['estimated_1rm'] as num?)?.toDouble(),
      avgRpe: (json['avg_rpe'] as num?)?.toDouble(),
      lastWorkoutDate: json['last_workout_date'] as String?,
      progression: json['progression'] != null
          ? ExerciseProgressionTrend.fromJson(json['progression'] as Map<String, dynamic>)
          : null,
      hasData: json['has_data'] as bool? ?? true,
    );
  }
}

/// Exercise stats model (detailed)
class ExerciseStats {
  final String? exerciseName;
  final int totalSets;
  final double? totalVolume;
  final double? maxWeight;
  final int? maxReps;
  final double? estimated1rm;
  final double? avgRpe;
  final String? lastWorkoutDate;
  final ExerciseProgressionTrend? progression;
  final bool hasData;
  final String? message;

  ExerciseStats({
    this.exerciseName,
    required this.totalSets,
    this.totalVolume,
    this.maxWeight,
    this.maxReps,
    this.estimated1rm,
    this.avgRpe,
    this.lastWorkoutDate,
    this.progression,
    this.hasData = false,
    this.message,
  });

  factory ExerciseStats.fromJson(Map<String, dynamic> json) {
    return ExerciseStats(
      exerciseName: json['exercise_name'] as String?,
      totalSets: (json['total_sets'] as num?)?.toInt() ?? 0,
      totalVolume: (json['total_volume'] as num?)?.toDouble(),
      maxWeight: (json['max_weight'] as num?)?.toDouble(),
      maxReps: (json['max_reps'] as num?)?.toInt(),
      estimated1rm: (json['estimated_1rm'] as num?)?.toDouble(),
      avgRpe: (json['avg_rpe'] as num?)?.toDouble(),
      lastWorkoutDate: json['last_workout_date'] as String?,
      progression: json['progression'] != null
          ? ExerciseProgressionTrend.fromJson(json['progression'] as Map<String, dynamic>)
          : null,
      hasData: json['has_data'] as bool? ?? false,
      message: json['message'] as String?,
    );
  }
}

/// Progression trend model
class ExerciseProgressionTrend {
  final String trend; // "increasing", "stable", "decreasing", "insufficient_data", "unknown"
  final double? changePercent;
  final String message;

  ExerciseProgressionTrend({
    required this.trend,
    this.changePercent,
    required this.message,
  });

  factory ExerciseProgressionTrend.fromJson(Map<String, dynamic> json) {
    return ExerciseProgressionTrend(
      trend: json['trend'] as String? ?? 'unknown',
      changePercent: (json['change_percent'] as num?)?.toDouble(),
      message: json['message'] as String? ?? '',
    );
  }

  bool get isIncreasing => trend == 'increasing';
  bool get isDecreasing => trend == 'decreasing';
  bool get isStable => trend == 'stable';
}

/// Program preferences model for customization
class ProgramPreferences {
  final String? difficulty;
  final int? durationMinutes;
  final String? workoutType;
  final String? trainingSplit; // Training program ID (full_body, ppl, etc.)
  final List<String> workoutDays;
  final List<String> equipment;
  final List<String> focusAreas;
  final List<String> injuries;
  final String? lastUpdated;
  final int? dumbbellCount;
  final int? kettlebellCount;

  ProgramPreferences({
    this.difficulty,
    this.durationMinutes,
    this.workoutType,
    this.trainingSplit,
    this.workoutDays = const [],
    this.equipment = const [],
    this.focusAreas = const [],
    this.injuries = const [],
    this.lastUpdated,
    this.dumbbellCount,
    this.kettlebellCount,
  });

  factory ProgramPreferences.fromJson(Map<String, dynamic> json) {
    return ProgramPreferences(
      difficulty: json['difficulty'] as String?,
      durationMinutes: (json['duration_minutes'] as num?)?.toInt(),
      workoutType: json['workout_type'] as String?,
      trainingSplit: json['training_split'] as String?,
      workoutDays: (json['workout_days'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      equipment: (json['equipment'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      focusAreas: (json['focus_areas'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      injuries: (json['injuries'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      lastUpdated: json['last_updated'] as String?,
      dumbbellCount: (json['dumbbell_count'] as num?)?.toInt(),
      kettlebellCount: (json['kettlebell_count'] as num?)?.toInt(),
    );
  }
}

/// Status of streaming workout generation
enum WorkoutGenerationStatus {
  /// Generation has started, waiting for AI response
  started,

  /// Generation is in progress, receiving chunks
  progress,

  /// Generation completed successfully
  completed,

  /// An error occurred during generation
  error,
}

/// Progress event for streaming workout generation
class WorkoutGenerationProgress {
  /// Current status of the generation
  final WorkoutGenerationStatus status;

  /// Human-readable status message
  final String message;

  /// Time elapsed since start in milliseconds
  final int elapsedMs;

  /// The generated workout (only available when status is completed)
  final Workout? workout;

  /// Total time for generation (server-side, only available when status is completed)
  final int? totalTimeMs;

  /// Number of chunks received (only available when status is completed)
  final int? chunkCount;

  /// Structured error code from the backend (e.g. "EXERCISE_POOL_TOO_SMALL").
  /// Only set when [status] == error and the backend sent a structured
  /// HTTPException detail object. Callers can key UX off this (redirect to
  /// gym-profile editor, show special retry, etc.) without parsing
  /// [message] strings.
  final String? errorCode;

  WorkoutGenerationProgress({
    required this.status,
    required this.message,
    required this.elapsedMs,
    this.workout,
    this.totalTimeMs,
    this.chunkCount,
    this.errorCode,
  });

  /// Whether the generation is still in progress
  bool get isLoading =>
      status == WorkoutGenerationStatus.started ||
      status == WorkoutGenerationStatus.progress;

  /// Whether the generation completed successfully
  bool get isCompleted => status == WorkoutGenerationStatus.completed;

  /// Whether an error occurred
  bool get hasError => status == WorkoutGenerationStatus.error;

  @override
  String toString() => 'WorkoutGenerationProgress(status: $status, message: $message, elapsedMs: $elapsedMs)';
}


/// Progress event for streaming workout regeneration
class RegenerateProgress {
  /// Current step number (1-indexed)
  final int step;

  /// Total number of steps
  final int totalSteps;

  /// Human-readable status message
  final String message;

  /// Additional detail about the current step
  final String? detail;

  /// Time elapsed since start in milliseconds
  final int elapsedMs;

  /// The regenerated workout (only available when completed).
  /// NOTE: after the Phase 1C/1D preview refactor this is a *preview* workout,
  /// not yet persisted to the DB. The caller must POST /regenerate-commit with
  /// [previewId] to materialize it, or /regenerate-discard to release it.
  final Workout? workout;

  /// Preview cache id returned on the final `done` SSE event. Required for
  /// commit / discard / in-sheet swap/add. Null on non-terminal events.
  final String? previewId;

  /// Total time for regeneration (server-side, only available when completed)
  final int? totalTimeMs;

  /// Whether regeneration completed successfully
  final bool isCompleted;

  /// Whether an error occurred
  final bool hasError;

  RegenerateProgress({
    required this.step,
    required this.totalSteps,
    required this.message,
    this.detail,
    required this.elapsedMs,
    this.workout,
    this.previewId,
    this.totalTimeMs,
    this.isCompleted = false,
    this.hasError = false,
  });

  /// Progress as a percentage (0.0 to 1.0)
  double get progress => totalSteps > 0 ? step / totalSteps : 0;

  /// Whether regeneration is still in progress
  bool get isLoading => !isCompleted && !hasError;

  @override
  String toString() => 'RegenerateProgress(step: $step/$totalSteps, message: $message, elapsedMs: $elapsedMs)';
}

/// Progress event for mood-based workout generation
class MoodWorkoutProgress {
  /// Current step number (1-indexed)
  final int step;

  /// Total number of steps
  final int totalSteps;

  /// Human-readable status message
  final String message;

  /// Additional detail about the current step
  final String? detail;

  /// Time elapsed since start in milliseconds
  final int elapsedMs;

  /// The generated workout (only available when completed)
  final Workout? workout;

  /// Mood that was used for generation
  final Mood? mood;

  /// Mood emoji for UI display
  final String? moodEmoji;

  /// Mood color hex for UI display
  final String? moodColor;

  /// Total time for generation (server-side, only available when completed)
  final int? totalTimeMs;

  /// Whether generation completed successfully
  final bool isCompleted;

  /// Whether an error occurred
  final bool hasError;

  MoodWorkoutProgress({
    required this.step,
    required this.totalSteps,
    required this.message,
    this.detail,
    required this.elapsedMs,
    this.workout,
    this.mood,
    this.moodEmoji,
    this.moodColor,
    this.totalTimeMs,
    this.isCompleted = false,
    this.hasError = false,
  });

  /// Progress as a percentage (0.0 to 1.0)
  double get progress => totalSteps > 0 ? step / totalSteps : 0;

  /// Whether generation is still in progress
  bool get isLoading => !isCompleted && !hasError;

  @override
  String toString() => 'MoodWorkoutProgress(step: $step/$totalSteps, message: $message, mood: ${mood?.value}, elapsedMs: $elapsedMs)';
}
