import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/calibration_repository.dart';

// ============================================
// State Classes
// ============================================

/// State for calibration status
class CalibrationStatusState {
  final bool isLoading;
  final String? error;
  final CalibrationStatus? status;

  const CalibrationStatusState({
    this.isLoading = false,
    this.error,
    this.status,
  });

  CalibrationStatusState copyWith({
    bool? isLoading,
    String? error,
    CalibrationStatus? status,
    bool clearError = false,
  }) {
    return CalibrationStatusState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      status: status ?? this.status,
    );
  }

  /// Check if calibration is needed
  bool get needsCalibration => status?.needsCalibration ?? false;

  /// Check if recalibration is recommended
  bool get recalibrationRecommended => status?.recalibrationRecommended ?? false;
}

/// State for calibration workout
class CalibrationWorkoutState {
  final bool isLoading;
  final bool isGenerating;
  final String? error;
  final CalibrationWorkout? workout;
  final int currentExerciseIndex;
  final List<ExerciseResult> exerciseResults;
  final DateTime? startTime;

  const CalibrationWorkoutState({
    this.isLoading = false,
    this.isGenerating = false,
    this.error,
    this.workout,
    this.currentExerciseIndex = 0,
    this.exerciseResults = const [],
    this.startTime,
  });

  CalibrationWorkoutState copyWith({
    bool? isLoading,
    bool? isGenerating,
    String? error,
    CalibrationWorkout? workout,
    int? currentExerciseIndex,
    List<ExerciseResult>? exerciseResults,
    DateTime? startTime,
    bool clearError = false,
    bool clearWorkout = false,
  }) {
    return CalibrationWorkoutState(
      isLoading: isLoading ?? this.isLoading,
      isGenerating: isGenerating ?? this.isGenerating,
      error: clearError ? null : (error ?? this.error),
      workout: clearWorkout ? null : (workout ?? this.workout),
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      exerciseResults: exerciseResults ?? this.exerciseResults,
      startTime: startTime ?? this.startTime,
    );
  }

  /// Get current exercise
  CalibrationExercise? get currentExercise {
    if (workout == null || workout!.exercises.isEmpty) return null;
    if (currentExerciseIndex >= workout!.exercises.length) return null;
    return workout!.exercises[currentExerciseIndex];
  }

  /// Check if on last exercise
  bool get isLastExercise {
    if (workout == null) return false;
    return currentExerciseIndex >= workout!.exercises.length - 1;
  }

  /// Get progress percentage
  double get progressPercentage {
    if (workout == null || workout!.exercises.isEmpty) return 0;
    return (currentExerciseIndex / workout!.exercises.length) * 100;
  }

  /// Get total duration in seconds
  int get totalDurationSeconds {
    if (startTime == null) return 0;
    return DateTime.now().difference(startTime!).inSeconds;
  }

  /// Check if all exercises are completed
  bool get allExercisesCompleted {
    if (workout == null) return false;
    return exerciseResults.length >= workout!.exercises.length;
  }
}

/// State for calibration analysis
class CalibrationAnalysisState {
  final bool isLoading;
  final bool isProcessing;
  final String? error;
  final CalibrationAnalysis? analysis;

  const CalibrationAnalysisState({
    this.isLoading = false,
    this.isProcessing = false,
    this.error,
    this.analysis,
  });

  CalibrationAnalysisState copyWith({
    bool? isLoading,
    bool? isProcessing,
    String? error,
    CalibrationAnalysis? analysis,
    bool clearError = false,
    bool clearAnalysis = false,
  }) {
    return CalibrationAnalysisState(
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      error: clearError ? null : (error ?? this.error),
      analysis: clearAnalysis ? null : (analysis ?? this.analysis),
    );
  }

  /// Check if there are adjustments to review
  bool get hasAdjustments => analysis?.hasAdjustments ?? false;
}

/// State for strength baselines
class StrengthBaselinesState {
  final bool isLoading;
  final String? error;
  final List<StrengthBaseline> baselines;

  const StrengthBaselinesState({
    this.isLoading = false,
    this.error,
    this.baselines = const [],
  });

  StrengthBaselinesState copyWith({
    bool? isLoading,
    String? error,
    List<StrengthBaseline>? baselines,
    bool clearError = false,
  }) {
    return StrengthBaselinesState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      baselines: baselines ?? this.baselines,
    );
  }

  /// Get baselines grouped by muscle group
  Map<String, List<StrengthBaseline>> get baselinesByMuscleGroup {
    final grouped = <String, List<StrengthBaseline>>{};
    for (final baseline in baselines) {
      grouped.putIfAbsent(baseline.muscleGroup, () => []).add(baseline);
    }
    return grouped;
  }

  /// Get baselines that need recalibration
  List<StrengthBaseline> get baselinesNeedingRecalibration {
    return baselines.where((b) => b.needsRecalibration).toList();
  }
}

// ============================================
// State Notifiers
// ============================================

/// Notifier for calibration status
class CalibrationStatusNotifier extends StateNotifier<CalibrationStatusState> {
  final CalibrationRepository _repository;

  CalibrationStatusNotifier(this._repository) : super(const CalibrationStatusState());

  /// Refresh calibration status
  Future<void> refreshStatus() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final status = await _repository.getCalibrationStatus();
      state = state.copyWith(isLoading: false, status: status);
      debugPrint('Loaded calibration status: ${status.statusMessage}');
    } catch (e) {
      debugPrint('Error refreshing calibration status: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load calibration status: $e',
      );
    }
  }

  /// Skip calibration
  Future<bool> skipCalibration() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _repository.skipCalibration();
      await refreshStatus();
      debugPrint('Calibration skipped successfully');
      return true;
    } catch (e) {
      debugPrint('Error skipping calibration: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to skip calibration: $e',
      );
      return false;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// Notifier for calibration workout
class CalibrationWorkoutNotifier extends StateNotifier<CalibrationWorkoutState> {
  final CalibrationRepository _repository;

  CalibrationWorkoutNotifier(this._repository) : super(const CalibrationWorkoutState());

  /// Generate a new calibration workout
  Future<CalibrationWorkout?> generateCalibration() async {
    state = state.copyWith(isGenerating: true, clearError: true);

    try {
      final workout = await _repository.generateCalibrationWorkout();
      state = state.copyWith(
        isGenerating: false,
        workout: workout,
        currentExerciseIndex: 0,
        exerciseResults: [],
      );
      debugPrint('Generated calibration workout: ${workout.name}');
      return workout;
    } catch (e) {
      debugPrint('Error generating calibration workout: $e');
      state = state.copyWith(
        isGenerating: false,
        error: 'Failed to generate calibration workout: $e',
      );
      return null;
    }
  }

  /// Start calibration workout
  Future<bool> startCalibration() async {
    if (state.workout == null) {
      state = state.copyWith(error: 'No workout to start');
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final workout = await _repository.startCalibration(state.workout!.id);
      state = state.copyWith(
        isLoading: false,
        workout: workout,
        startTime: DateTime.now(),
      );
      debugPrint('Started calibration workout: ${workout.id}');
      return true;
    } catch (e) {
      debugPrint('Error starting calibration: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to start calibration: $e',
      );
      return false;
    }
  }

  /// Record result for current exercise and move to next
  void recordExerciseResult({
    required int repsCompleted,
    required double weightUsed,
    int perceivedDifficulty = 5,
    String? notes,
  }) {
    final exercise = state.currentExercise;
    if (exercise == null) return;

    final result = ExerciseResult(
      exerciseId: exercise.id,
      repsCompleted: repsCompleted,
      weightUsed: weightUsed,
      perceivedDifficulty: perceivedDifficulty,
      notes: notes,
    );

    final updatedResults = [...state.exerciseResults, result];

    state = state.copyWith(
      exerciseResults: updatedResults,
      currentExerciseIndex: state.currentExerciseIndex + 1,
    );

    debugPrint('Recorded exercise result: ${exercise.name} - $repsCompleted reps @ ${weightUsed}lbs');
  }

  /// Go to previous exercise
  void previousExercise() {
    if (state.currentExerciseIndex > 0) {
      // Remove the last result when going back
      final updatedResults = state.exerciseResults.isNotEmpty
          ? state.exerciseResults.sublist(0, state.exerciseResults.length - 1)
          : <ExerciseResult>[];

      state = state.copyWith(
        currentExerciseIndex: state.currentExerciseIndex - 1,
        exerciseResults: updatedResults,
      );
    }
  }

  /// Build calibration result for submission
  CalibrationResult buildCalibrationResult({String? notes}) {
    return CalibrationResult(
      calibrationId: state.workout!.id,
      exerciseResults: state.exerciseResults,
      totalDurationSeconds: state.totalDurationSeconds,
      notes: notes,
    );
  }

  /// Reset workout state
  void reset() {
    state = const CalibrationWorkoutState();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Set workout directly (e.g., from loaded results)
  void setWorkout(CalibrationWorkout workout) {
    state = state.copyWith(workout: workout);
  }
}

/// Notifier for calibration analysis
class CalibrationAnalysisNotifier extends StateNotifier<CalibrationAnalysisState> {
  final CalibrationRepository _repository;

  CalibrationAnalysisNotifier(this._repository) : super(const CalibrationAnalysisState());

  /// Complete calibration and get analysis
  Future<CalibrationAnalysis?> completeCalibration(CalibrationResult result) async {
    state = state.copyWith(isProcessing: true, clearError: true);

    try {
      final analysis = await _repository.completeCalibration(
        calibrationId: result.calibrationId,
        result: result,
      );
      state = state.copyWith(isProcessing: false, analysis: analysis);
      debugPrint('Calibration completed: ${analysis.message}');
      return analysis;
    } catch (e) {
      debugPrint('Error completing calibration: $e');
      state = state.copyWith(
        isProcessing: false,
        error: 'Failed to complete calibration: $e',
      );
      return null;
    }
  }

  /// Accept recommended adjustments
  Future<bool> acceptAdjustments() async {
    if (state.analysis == null) {
      state = state.copyWith(error: 'No analysis available');
      return false;
    }

    state = state.copyWith(isProcessing: true, clearError: true);

    try {
      await _repository.acceptAdjustments(state.analysis!.calibrationId);
      state = state.copyWith(isProcessing: false);
      debugPrint('Adjustments accepted');
      return true;
    } catch (e) {
      debugPrint('Error accepting adjustments: $e');
      state = state.copyWith(
        isProcessing: false,
        error: 'Failed to accept adjustments: $e',
      );
      return false;
    }
  }

  /// Decline recommended adjustments
  Future<bool> declineAdjustments() async {
    if (state.analysis == null) {
      state = state.copyWith(error: 'No analysis available');
      return false;
    }

    state = state.copyWith(isProcessing: true, clearError: true);

    try {
      await _repository.declineAdjustments(state.analysis!.calibrationId);
      state = state.copyWith(isProcessing: false);
      debugPrint('Adjustments declined');
      return true;
    } catch (e) {
      debugPrint('Error declining adjustments: $e');
      state = state.copyWith(
        isProcessing: false,
        error: 'Failed to decline adjustments: $e',
      );
      return false;
    }
  }

  /// Reset analysis state
  void reset() {
    state = const CalibrationAnalysisState();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Set analysis directly
  void setAnalysis(CalibrationAnalysis analysis) {
    state = state.copyWith(analysis: analysis);
  }
}

/// Notifier for strength baselines
class StrengthBaselinesNotifier extends StateNotifier<StrengthBaselinesState> {
  final CalibrationRepository _repository;

  StrengthBaselinesNotifier(this._repository) : super(const StrengthBaselinesState());

  /// Load strength baselines
  Future<void> loadBaselines() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final baselines = await _repository.getStrengthBaselines();
      state = state.copyWith(isLoading: false, baselines: baselines);
      debugPrint('Loaded ${baselines.length} strength baselines');
    } catch (e) {
      debugPrint('Error loading strength baselines: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load strength baselines: $e',
      );
    }
  }

  /// Refresh baselines
  Future<void> refresh() async {
    await loadBaselines();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// ============================================
// Providers
// ============================================

/// Calibration status provider
final calibrationStatusProvider =
    StateNotifierProvider<CalibrationStatusNotifier, CalibrationStatusState>((ref) {
  final repository = ref.watch(calibrationRepositoryProvider);
  return CalibrationStatusNotifier(repository);
});

/// Calibration workout provider
final calibrationWorkoutProvider =
    StateNotifierProvider<CalibrationWorkoutNotifier, CalibrationWorkoutState>((ref) {
  final repository = ref.watch(calibrationRepositoryProvider);
  return CalibrationWorkoutNotifier(repository);
});

/// Calibration analysis provider
final calibrationAnalysisProvider =
    StateNotifierProvider<CalibrationAnalysisNotifier, CalibrationAnalysisState>((ref) {
  final repository = ref.watch(calibrationRepositoryProvider);
  return CalibrationAnalysisNotifier(repository);
});

/// Strength baselines provider
final strengthBaselinesProvider =
    StateNotifierProvider<StrengthBaselinesNotifier, StrengthBaselinesState>((ref) {
  final repository = ref.watch(calibrationRepositoryProvider);
  return StrengthBaselinesNotifier(repository);
});

// ============================================
// Convenience Providers
// ============================================

/// Whether calibration is needed (convenience provider)
final needsCalibrationProvider = Provider<bool>((ref) {
  return ref.watch(calibrationStatusProvider).needsCalibration;
});

/// Whether recalibration is recommended (convenience provider)
final recalibrationRecommendedProvider = Provider<bool>((ref) {
  return ref.watch(calibrationStatusProvider).recalibrationRecommended;
});

/// Current calibration workout (convenience provider)
final currentCalibrationWorkoutProvider = Provider<CalibrationWorkout?>((ref) {
  return ref.watch(calibrationWorkoutProvider).workout;
});

/// Current calibration exercise (convenience provider)
final currentCalibrationExerciseProvider = Provider<CalibrationExercise?>((ref) {
  return ref.watch(calibrationWorkoutProvider).currentExercise;
});

/// Calibration workout progress percentage (convenience provider)
final calibrationProgressProvider = Provider<double>((ref) {
  return ref.watch(calibrationWorkoutProvider).progressPercentage;
});

/// Calibration analysis results (convenience provider)
final calibrationAnalysisResultsProvider = Provider<CalibrationAnalysis?>((ref) {
  return ref.watch(calibrationAnalysisProvider).analysis;
});

/// Recommended adjustments (convenience provider)
final recommendedAdjustmentsProvider = Provider<List<WeightAdjustment>>((ref) {
  return ref.watch(calibrationAnalysisProvider).analysis?.recommendedAdjustments ?? [];
});

/// Strength baselines list (convenience provider)
final strengthBaselinesListProvider = Provider<List<StrengthBaseline>>((ref) {
  return ref.watch(strengthBaselinesProvider).baselines;
});

/// Baselines needing recalibration (convenience provider)
final baselinesNeedingRecalibrationProvider = Provider<List<StrengthBaseline>>((ref) {
  return ref.watch(strengthBaselinesProvider).baselinesNeedingRecalibration;
});

/// Calibration loading state (convenience provider)
final calibrationIsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(calibrationStatusProvider).isLoading ||
      ref.watch(calibrationWorkoutProvider).isLoading ||
      ref.watch(calibrationAnalysisProvider).isLoading;
});

/// Calibration generating state (convenience provider)
final calibrationIsGeneratingProvider = Provider<bool>((ref) {
  return ref.watch(calibrationWorkoutProvider).isGenerating;
});

/// Calibration processing state (convenience provider)
final calibrationIsProcessingProvider = Provider<bool>((ref) {
  return ref.watch(calibrationAnalysisProvider).isProcessing;
});

/// Baseline for a specific exercise (family provider)
final baselineForExerciseProvider =
    Provider.family<StrengthBaseline?, String>((ref, exerciseId) {
  final baselines = ref.watch(strengthBaselinesProvider).baselines;
  try {
    return baselines.firstWhere((b) => b.exerciseId == exerciseId);
  } catch (_) {
    return null;
  }
});

/// Baselines for a specific muscle group (family provider)
final baselinesForMuscleGroupProvider =
    Provider.family<List<StrengthBaseline>, String>((ref, muscleGroup) {
  final baselines = ref.watch(strengthBaselinesProvider).baselines;
  return baselines.where((b) => b.muscleGroup == muscleGroup).toList();
});
