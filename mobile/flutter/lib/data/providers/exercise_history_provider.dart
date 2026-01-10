import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exercise_history.dart';
import '../repositories/exercise_history_repository.dart';

// ============================================================================
// State Providers for UI selections
// ============================================================================

/// Currently selected exercise for viewing history
final selectedExerciseProvider = StateProvider<String?>((ref) => null);

/// Time range for exercise history queries
final exerciseHistoryTimeRangeProvider = StateProvider<ExerciseHistoryTimeRange>(
  (ref) => ExerciseHistoryTimeRange.threeMonths,
);

/// Chart data type selector (weight, volume, 1rm)
final exerciseChartTypeProvider = StateProvider<String>((ref) => 'weight');

// ============================================================================
// Data Providers
// ============================================================================

/// Provider for most performed exercises list
/// Note: Removed autoDispose to prevent refetching on navigation
final mostPerformedExercisesProvider = FutureProvider<List<MostPerformedExercise>>((ref) async {
  final repository = ref.watch(exerciseHistoryRepositoryProvider);
  return repository.getMostPerformedExercises(limit: 30);
});

/// Provider for exercise history data (family provider with exercise name parameter)
/// Note: Removed autoDispose to prevent refetching on navigation
final exerciseHistoryProvider = FutureProvider.family<ExerciseHistoryData, String>((ref, exerciseName) async {
  final repository = ref.watch(exerciseHistoryRepositoryProvider);
  final timeRange = ref.watch(exerciseHistoryTimeRangeProvider);

  return repository.getExerciseHistory(
    exerciseName: exerciseName,
    timeRange: timeRange.value,
  );
});

/// Provider for exercise chart data
/// Note: Removed autoDispose to prevent refetching on navigation
final exerciseChartDataProvider = FutureProvider.family<List<ExerciseChartDataPoint>, String>((ref, exerciseName) async {
  final repository = ref.watch(exerciseHistoryRepositoryProvider);
  final timeRange = ref.watch(exerciseHistoryTimeRangeProvider);

  return repository.getExerciseChartData(
    exerciseName: exerciseName,
    timeRange: timeRange.value,
  );
});

/// Provider for exercise personal records
/// Note: Removed autoDispose to prevent refetching on navigation
final exercisePRsProvider = FutureProvider.family<List<ExercisePersonalRecord>, String>((ref, exerciseName) async {
  final repository = ref.watch(exerciseHistoryRepositoryProvider);
  return repository.getExercisePRs(exerciseName: exerciseName);
});

// ============================================================================
// Notifier for managing exercise history state with pagination
// ============================================================================

/// State class for paginated exercise history
class ExerciseHistoryState {
  final List<ExerciseWorkoutSession> sessions;
  final ExerciseProgressionSummary? summary;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final String? error;

  const ExerciseHistoryState({
    this.sessions = const [],
    this.summary,
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.error,
  });

  ExerciseHistoryState copyWith({
    List<ExerciseWorkoutSession>? sessions,
    ExerciseProgressionSummary? summary,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    String? error,
  }) {
    return ExerciseHistoryState(
      sessions: sessions ?? this.sessions,
      summary: summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error,
    );
  }
}

/// Notifier for managing paginated exercise history
class ExerciseHistoryNotifier extends StateNotifier<ExerciseHistoryState> {
  final ExerciseHistoryRepository _repository;
  final String exerciseName;
  final String timeRange;

  ExerciseHistoryNotifier(this._repository, this.exerciseName, this.timeRange)
      : super(const ExerciseHistoryState()) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final data = await _repository.getExerciseHistory(
        exerciseName: exerciseName,
        timeRange: timeRange,
        page: 1,
      );

      state = state.copyWith(
        sessions: data.sessions,
        summary: data.summary,
        isLoading: false,
        hasMore: data.sessions.length >= 20,
        currentPage: 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      final nextPage = state.currentPage + 1;
      final data = await _repository.getExerciseHistory(
        exerciseName: exerciseName,
        timeRange: timeRange,
        page: nextPage,
      );

      state = state.copyWith(
        sessions: [...state.sessions, ...data.sessions],
        isLoading: false,
        hasMore: data.sessions.length >= 20,
        currentPage: nextPage,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh() async {
    state = const ExerciseHistoryState();
    await loadInitial();
  }
}

/// Provider for paginated exercise history notifier
/// Note: Removed autoDispose to prevent refetching on navigation
final paginatedExerciseHistoryProvider = StateNotifierProvider
    .family<ExerciseHistoryNotifier, ExerciseHistoryState, String>((ref, exerciseName) {
  final repository = ref.watch(exerciseHistoryRepositoryProvider);
  final timeRange = ref.watch(exerciseHistoryTimeRangeProvider);
  return ExerciseHistoryNotifier(repository, exerciseName, timeRange.value);
});

// ============================================================================
// Search Provider for filtering exercises
// ============================================================================

/// Search query for filtering most performed exercises
final exerciseSearchQueryProvider = StateProvider<String>((ref) => '');

/// Filtered most performed exercises based on search query
/// Note: Removed autoDispose to prevent refetching on navigation
final filteredExercisesProvider = Provider<AsyncValue<List<MostPerformedExercise>>>((ref) {
  final exercisesAsync = ref.watch(mostPerformedExercisesProvider);
  final query = ref.watch(exerciseSearchQueryProvider).toLowerCase();

  return exercisesAsync.whenData((exercises) {
    if (query.isEmpty) return exercises;
    return exercises.where((e) {
      return e.exerciseName.toLowerCase().contains(query) ||
          (e.muscleGroup?.toLowerCase().contains(query) ?? false);
    }).toList();
  });
});
