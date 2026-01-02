import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/scheduling_repository.dart';
import '../services/api_client.dart';

/// Provider for missed workouts with auto-refresh
final missedWorkoutsProvider = FutureProvider.autoDispose<List<MissedWorkout>>((ref) async {
  final userId = await ref.watch(apiClientProvider).getUserId();
  if (userId == null) return [];

  final repository = ref.watch(schedulingRepositoryProvider);

  // Trigger detection of newly missed workouts
  await repository.detectMissedWorkouts(userId);

  // Get missed workouts from past 3 days (for banner display)
  return repository.getMissedWorkouts(
    userId: userId,
    daysBack: 3,
    includeScheduled: true,
  );
});

/// Provider for the most recent missed workout (for banner)
final recentMissedWorkoutProvider = Provider<MissedWorkout?>((ref) {
  final missedWorkouts = ref.watch(missedWorkoutsProvider);
  return missedWorkouts.when(
    data: (workouts) => workouts.isNotEmpty ? workouts.first : null,
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Provider to check if there are any missed workouts
final hasMissedWorkoutsProvider = Provider<bool>((ref) {
  final missedWorkouts = ref.watch(missedWorkoutsProvider);
  return missedWorkouts.when(
    data: (workouts) => workouts.isNotEmpty,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Provider for skip reason categories
final skipReasonsProvider = FutureProvider<List<SkipReasonCategory>>((ref) async {
  final repository = ref.watch(schedulingRepositoryProvider);
  return repository.getSkipReasons();
});

/// State for handling reschedule/skip actions
class SchedulingActionState {
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const SchedulingActionState({
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  SchedulingActionState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return SchedulingActionState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }
}

/// Notifier for scheduling actions
class SchedulingActionNotifier extends StateNotifier<SchedulingActionState> {
  final SchedulingRepository _repository;
  final Ref _ref;

  SchedulingActionNotifier(this._repository, this._ref)
      : super(const SchedulingActionState());

  /// Reschedule a workout to today
  Future<bool> rescheduleToToday(String workoutId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final today = DateTime.now();
      final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final result = await _repository.rescheduleWorkout(
        workoutId: workoutId,
        newDate: dateStr,
      );

      if (result.success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: result.message,
        );

        // Invalidate missed workouts to refresh
        _ref.invalidate(missedWorkoutsProvider);

        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.message,
        );
        return false;
      }
    } catch (e) {
      debugPrint('Error rescheduling workout: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to reschedule workout',
      );
      return false;
    }
  }

  /// Reschedule a workout to a specific date
  Future<bool> rescheduleToDate(String workoutId, DateTime date, {String? swapWithWorkoutId}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final result = await _repository.rescheduleWorkout(
        workoutId: workoutId,
        newDate: dateStr,
        swapWithWorkoutId: swapWithWorkoutId,
      );

      if (result.success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: result.message,
        );

        // Invalidate missed workouts to refresh
        _ref.invalidate(missedWorkoutsProvider);

        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.message,
        );
        return false;
      }
    } catch (e) {
      debugPrint('Error rescheduling workout: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to reschedule workout',
      );
      return false;
    }
  }

  /// Skip a workout
  Future<bool> skipWorkout(String workoutId, {String? reasonCategory, String? reasonText}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await _repository.skipWorkout(
        workoutId: workoutId,
        reasonCategory: reasonCategory,
        reasonText: reasonText,
      );

      if (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Workout skipped',
        );

        // Invalidate missed workouts to refresh
        _ref.invalidate(missedWorkoutsProvider);

        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to skip workout',
        );
        return false;
      }
    } catch (e) {
      debugPrint('Error skipping workout: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to skip workout',
      );
      return false;
    }
  }

  /// Clear any error or success message
  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }
}

/// Provider for scheduling actions
final schedulingActionProvider = StateNotifierProvider<SchedulingActionNotifier, SchedulingActionState>((ref) {
  final repository = ref.watch(schedulingRepositoryProvider);
  return SchedulingActionNotifier(repository, ref);
});

/// Provider for scheduling suggestions (for a specific workout)
final schedulingSuggestionsProvider = FutureProvider.family<List<SchedulingSuggestion>, String>((ref, workoutId) async {
  final userId = await ref.watch(apiClientProvider).getUserId();
  if (userId == null) return [];

  final repository = ref.watch(schedulingRepositoryProvider);
  return repository.getSchedulingSuggestions(
    workoutId: workoutId,
    userId: userId,
  );
});
