import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/progress_charts.dart';
import '../repositories/progress_charts_repository.dart';

// ============================================
// Progress Charts State
// ============================================

/// Complete state for progress charts
class ProgressChartsState {
  final ProgressSummary? summary;
  final VolumeProgressionData? volumeData;
  final StrengthProgressionData? strengthData;
  final ExerciseProgressionData? exerciseData;
  final AvailableMuscleGroups? muscleGroups;
  final ProgressTimeRange selectedTimeRange;
  final String? selectedMuscleGroup;
  final String? selectedExercise;
  final bool isLoading;
  final bool isLoadingVolume;
  final bool isLoadingStrength;
  final bool isLoadingExercise;
  final String? error;
  final DateTime? lastFetched;

  const ProgressChartsState({
    this.summary,
    this.volumeData,
    this.strengthData,
    this.exerciseData,
    this.muscleGroups,
    this.selectedTimeRange = ProgressTimeRange.twelveWeeks,
    this.selectedMuscleGroup,
    this.selectedExercise,
    this.isLoading = false,
    this.isLoadingVolume = false,
    this.isLoadingStrength = false,
    this.isLoadingExercise = false,
    this.error,
    this.lastFetched,
  });

  ProgressChartsState copyWith({
    ProgressSummary? summary,
    VolumeProgressionData? volumeData,
    StrengthProgressionData? strengthData,
    ExerciseProgressionData? exerciseData,
    AvailableMuscleGroups? muscleGroups,
    ProgressTimeRange? selectedTimeRange,
    String? selectedMuscleGroup,
    String? selectedExercise,
    bool? isLoading,
    bool? isLoadingVolume,
    bool? isLoadingStrength,
    bool? isLoadingExercise,
    String? error,
    DateTime? lastFetched,
    bool clearError = false,
    bool clearMuscleGroup = false,
    bool clearExercise = false,
    bool clearExerciseData = false,
  }) {
    return ProgressChartsState(
      summary: summary ?? this.summary,
      volumeData: volumeData ?? this.volumeData,
      strengthData: strengthData ?? this.strengthData,
      exerciseData: clearExerciseData ? null : (exerciseData ?? this.exerciseData),
      muscleGroups: muscleGroups ?? this.muscleGroups,
      selectedTimeRange: selectedTimeRange ?? this.selectedTimeRange,
      selectedMuscleGroup: clearMuscleGroup
          ? null
          : (selectedMuscleGroup ?? this.selectedMuscleGroup),
      selectedExercise: clearExercise
          ? null
          : (selectedExercise ?? this.selectedExercise),
      isLoading: isLoading ?? this.isLoading,
      isLoadingVolume: isLoadingVolume ?? this.isLoadingVolume,
      isLoadingStrength: isLoadingStrength ?? this.isLoadingStrength,
      isLoadingExercise: isLoadingExercise ?? this.isLoadingExercise,
      error: clearError ? null : (error ?? this.error),
      lastFetched: lastFetched ?? this.lastFetched,
    );
  }

  /// Check if any data is available
  bool get hasData =>
      summary != null || volumeData != null || strengthData != null;

  /// Check if volume chart has data points
  bool get hasVolumeData =>
      volumeData != null && volumeData!.data.isNotEmpty;

  /// Check if strength chart has data points
  bool get hasStrengthData =>
      strengthData != null && strengthData!.data.isNotEmpty;

  /// Get available muscle groups for filtering
  List<String> get availableMuscleGroupsList =>
      muscleGroups?.muscleGroups ?? [];

  /// Get formatted muscle groups for display
  List<String> get formattedMuscleGroups =>
      muscleGroups?.formattedMuscleGroups ?? [];
}

// ============================================
// Progress Charts Notifier
// ============================================

class ProgressChartsNotifier extends StateNotifier<ProgressChartsState> {
  final ProgressChartsRepository _repository;
  String? _currentUserId;
  DateTime? _chartViewStartTime;

  ProgressChartsNotifier(this._repository)
      : super(const ProgressChartsState());

  /// Set the user ID for this session
  void setUserId(String userId) {
    _currentUserId = userId;
  }

  /// Load all progress data
  Future<void> loadAllData({String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) {
      debugPrint('⚠️ [ProgressChartsProvider] No user ID, skipping load');
      return;
    }
    _currentUserId = uid;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Load all data in parallel
      final results = await Future.wait([
        _repository.getProgressSummary(userId: uid),
        _repository.getVolumeOverTime(
          userId: uid,
          timeRange: state.selectedTimeRange,
        ),
        _repository.getStrengthOverTime(
          userId: uid,
          timeRange: state.selectedTimeRange,
          muscleGroup: state.selectedMuscleGroup,
        ),
        _repository.getAvailableMuscleGroups(userId: uid),
      ]);

      state = state.copyWith(
        summary: results[0] as ProgressSummary,
        volumeData: results[1] as VolumeProgressionData,
        strengthData: results[2] as StrengthProgressionData,
        muscleGroups: results[3] as AvailableMuscleGroups,
        isLoading: false,
        lastFetched: DateTime.now(),
      );

      debugPrint('✅ [ProgressChartsProvider] Loaded all progress data');

      // Log the chart view
      _chartViewStartTime = DateTime.now();
      _logChartView(ChartType.all);
    } catch (e) {
      debugPrint('❌ [ProgressChartsProvider] Error loading data: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load progress data: $e',
      );
    }
  }

  /// Load volume progression data
  Future<void> loadVolumeData({String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return;
    _currentUserId = uid;

    state = state.copyWith(isLoadingVolume: true, clearError: true);

    try {
      final volumeData = await _repository.getVolumeOverTime(
        userId: uid,
        timeRange: state.selectedTimeRange,
      );

      state = state.copyWith(
        volumeData: volumeData,
        isLoadingVolume: false,
      );

      debugPrint('✅ [ProgressChartsProvider] Loaded volume data');
      _logChartView(ChartType.volume);
    } catch (e) {
      debugPrint('❌ [ProgressChartsProvider] Error loading volume: $e');
      state = state.copyWith(
        isLoadingVolume: false,
        error: 'Failed to load volume data: $e',
      );
    }
  }

  /// Load strength progression data
  Future<void> loadStrengthData({String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return;
    _currentUserId = uid;

    state = state.copyWith(isLoadingStrength: true, clearError: true);

    try {
      final strengthData = await _repository.getStrengthOverTime(
        userId: uid,
        timeRange: state.selectedTimeRange,
        muscleGroup: state.selectedMuscleGroup,
      );

      state = state.copyWith(
        strengthData: strengthData,
        isLoadingStrength: false,
      );

      debugPrint('✅ [ProgressChartsProvider] Loaded strength data');
      _logChartView(ChartType.strength);
    } catch (e) {
      debugPrint('❌ [ProgressChartsProvider] Error loading strength: $e');
      state = state.copyWith(
        isLoadingStrength: false,
        error: 'Failed to load strength data: $e',
      );
    }
  }

  /// Load exercise-specific progression
  Future<void> loadExerciseData({
    required String exerciseName,
    String? userId,
  }) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return;
    _currentUserId = uid;

    state = state.copyWith(
      isLoadingExercise: true,
      selectedExercise: exerciseName,
      clearError: true,
    );

    try {
      final exerciseData = await _repository.getExerciseProgression(
        userId: uid,
        exerciseName: exerciseName,
        timeRange: state.selectedTimeRange,
      );

      state = state.copyWith(
        exerciseData: exerciseData,
        isLoadingExercise: false,
      );

      debugPrint(
          '✅ [ProgressChartsProvider] Loaded exercise data for $exerciseName');
    } catch (e) {
      debugPrint('❌ [ProgressChartsProvider] Error loading exercise: $e');
      state = state.copyWith(
        isLoadingExercise: false,
        error: 'Failed to load exercise data: $e',
      );
    }
  }

  /// Update selected time range and refresh data
  Future<void> setTimeRange(ProgressTimeRange timeRange) async {
    if (state.selectedTimeRange == timeRange) return;

    state = state.copyWith(selectedTimeRange: timeRange);

    // Reload data with new time range
    if (_currentUserId != null) {
      await Future.wait([
        loadVolumeData(),
        loadStrengthData(),
      ]);
    }
  }

  /// Update selected muscle group filter and refresh strength data
  Future<void> setMuscleGroupFilter(String? muscleGroup) async {
    if (state.selectedMuscleGroup == muscleGroup) return;

    state = state.copyWith(
      selectedMuscleGroup: muscleGroup,
      clearMuscleGroup: muscleGroup == null,
    );

    // Reload strength data with new filter
    if (_currentUserId != null) {
      await loadStrengthData();
    }
  }

  /// Clear selected exercise data
  void clearExerciseData() {
    state = state.copyWith(
      clearExercise: true,
      clearExerciseData: true,
    );
  }

  /// Clear any errors
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Refresh all data
  Future<void> refresh({String? userId}) async {
    await loadAllData(userId: userId);
  }

  /// Log chart view to analytics
  void _logChartView(ChartType chartType) {
    if (_currentUserId == null) return;

    int? duration;
    if (_chartViewStartTime != null) {
      duration = DateTime.now().difference(_chartViewStartTime!).inSeconds;
    }

    _repository.logChartView(
      userId: _currentUserId!,
      chartType: chartType,
      timeRange: state.selectedTimeRange,
      muscleGroup: state.selectedMuscleGroup,
      sessionDurationSeconds: duration,
    );
  }

  /// Called when leaving the charts screen
  void onScreenExit() {
    _logChartView(ChartType.all);
    _chartViewStartTime = null;
  }
}

// ============================================
// Providers
// ============================================

/// Main progress charts provider
final progressChartsProvider =
    StateNotifierProvider<ProgressChartsNotifier, ProgressChartsState>((ref) {
  final repository = ref.watch(progressChartsRepositoryProvider);
  return ProgressChartsNotifier(repository);
});

/// Summary data convenience provider
final progressSummaryProvider = Provider<ProgressSummary?>((ref) {
  return ref.watch(progressChartsProvider).summary;
});

/// Volume data convenience provider
final volumeProgressionProvider = Provider<VolumeProgressionData?>((ref) {
  return ref.watch(progressChartsProvider).volumeData;
});

/// Strength data convenience provider
final strengthProgressionProvider = Provider<StrengthProgressionData?>((ref) {
  return ref.watch(progressChartsProvider).strengthData;
});

/// Selected time range convenience provider
final selectedTimeRangeProvider = Provider<ProgressTimeRange>((ref) {
  return ref.watch(progressChartsProvider).selectedTimeRange;
});

/// Available muscle groups convenience provider
final availableMuscleGroupsProvider = Provider<List<String>>((ref) {
  return ref.watch(progressChartsProvider).availableMuscleGroupsList;
});

/// Is loading convenience provider
final progressChartsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(progressChartsProvider).isLoading;
});

/// Error convenience provider
final progressChartsErrorProvider = Provider<String?>((ref) {
  return ref.watch(progressChartsProvider).error;
});
