import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/exercise_preferences_repository.dart';
import '../../data/services/api_client.dart';

/// State for week-over-week exercise comparison
class WeekComparisonState {
  final WeekComparison? comparison;
  final bool isLoading;
  final String? error;

  const WeekComparisonState({
    this.comparison,
    this.isLoading = false,
    this.error,
  });

  WeekComparisonState copyWith({
    WeekComparison? comparison,
    bool? isLoading,
    String? error,
  }) {
    return WeekComparisonState(
      comparison: comparison ?? this.comparison,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Check if there are new exercises this week
  bool get hasNewExercises => comparison?.newExercises.isNotEmpty ?? false;

  /// Get the count of new exercises
  int get newExerciseCount => comparison?.newExercises.length ?? 0;

  /// Get summary text for the card
  String get summaryText {
    if (comparison == null) return 'Loading...';
    if (comparison!.newExercises.isEmpty && comparison!.removedExercises.isEmpty) {
      return 'Same exercises as last week';
    }
    return comparison!.variationSummary;
  }
}

/// Provider for managing week comparison state
final weekComparisonProvider = StateNotifierProvider<WeekComparisonNotifier, WeekComparisonState>((ref) {
  return WeekComparisonNotifier(ref);
});

class WeekComparisonNotifier extends StateNotifier<WeekComparisonState> {
  final Ref _ref;

  WeekComparisonNotifier(this._ref) : super(const WeekComparisonState(isLoading: true)) {
    _loadComparison();
  }

  Future<void> _loadComparison() async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();
      if (userId == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final repo = _ref.read(exercisePreferencesRepositoryProvider);
      final comparison = await repo.getWeekComparison(userId);

      state = state.copyWith(
        comparison: comparison,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Error loading week comparison: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _loadComparison();
  }
}

/// Provider that exposes just the new exercise names for badge display
final newExercisesThisWeekProvider = Provider<List<String>>((ref) {
  final comparisonState = ref.watch(weekComparisonProvider);
  return comparisonState.comparison?.newExercises ?? [];
});

/// Provider to check if a specific exercise is new this week
final isExerciseNewThisWeekProvider = Provider.family<bool, String>((ref, exerciseName) {
  final newExercises = ref.watch(newExercisesThisWeekProvider);
  return newExercises.any((e) => e.toLowerCase() == exerciseName.toLowerCase());
});
