import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/today_workout_provider.dart';
import '../../data/repositories/exercise_preferences_repository.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/services/api_client.dart';

/// State for avoided exercises
class AvoidedState {
  final List<AvoidedExercise> avoided;
  final bool isLoading;
  final bool isRegenerating;
  final String? regenerationMessage;
  final String? error;

  const AvoidedState({
    this.avoided = const [],
    this.isLoading = false,
    this.isRegenerating = false,
    this.regenerationMessage,
    this.error,
  });

  AvoidedState copyWith({
    List<AvoidedExercise>? avoided,
    bool? isLoading,
    bool? isRegenerating,
    String? regenerationMessage,
    String? error,
  }) {
    return AvoidedState(
      avoided: avoided ?? this.avoided,
      isLoading: isLoading ?? this.isLoading,
      isRegenerating: isRegenerating ?? this.isRegenerating,
      regenerationMessage: regenerationMessage ?? this.regenerationMessage,
      error: error,
    );
  }

  /// Get only active avoided exercises
  List<AvoidedExercise> get activeAvoided =>
      avoided.where((a) => a.isActive).toList();

  /// Check if an exercise is avoided by name
  bool isAvoided(String exerciseName) {
    return activeAvoided.any(
      (a) => a.exerciseName.toLowerCase() == exerciseName.toLowerCase(),
    );
  }

  /// Get the set of avoided exercise names for quick lookup
  Set<String> get avoidedNames =>
      activeAvoided.map((a) => a.exerciseName.toLowerCase()).toSet();
}

/// Avoided exercises provider
final avoidedProvider =
    StateNotifierProvider<AvoidedNotifier, AvoidedState>((ref) {
  return AvoidedNotifier(ref);
});

/// Notifier for managing avoided exercises state
class AvoidedNotifier extends StateNotifier<AvoidedState> {
  final Ref _ref;
  bool _initialized = false;

  AvoidedNotifier(this._ref) : super(const AvoidedState());

  /// Initialize avoided exercises from API (call explicitly from screens)
  /// Note: Removed auto-init from constructor to prevent API calls on provider creation
  Future<void> ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
    await refresh();
  }

  /// Refresh avoided exercises from API
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final apiClient = _ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final repository = _ref.read(exercisePreferencesRepositoryProvider);
      final avoided = await repository.getAvoidedExercises(userId);

      state = state.copyWith(avoided: avoided, isLoading: false);
      debugPrint('🚫 [AvoidedProvider] Loaded ${avoided.length} avoided exercises');
    } catch (e) {
      debugPrint('❌ [AvoidedProvider] Error loading avoided exercises: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Add an exercise to avoided list
  Future<bool> addAvoided(
    String exerciseName, {
    String? exerciseId,
    String? reason,
    bool isTemporary = false,
    DateTime? endDate,
    bool regenerateNow = true,
  }) async {
    // Optimistic update
    final optimisticAvoided = AvoidedExercise(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      exerciseName: exerciseName,
      exerciseId: exerciseId,
      reason: reason,
      isTemporary: isTemporary,
      endDate: endDate,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(
      avoided: [...state.avoided, optimisticAvoided],
    );

    try {
      final apiClient = _ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId == null) {
        // Rollback
        state = state.copyWith(
          avoided: state.avoided.where((a) => a.id != optimisticAvoided.id).toList(),
          error: 'Not logged in',
        );
        return false;
      }

      final repository = _ref.read(exercisePreferencesRepositoryProvider);
      final avoided = await repository.addAvoidedExercise(
        userId,
        exerciseName,
        exerciseId: exerciseId,
        reason: reason,
        isTemporary: isTemporary,
        endDate: endDate,
      );

      // Replace optimistic with real
      state = state.copyWith(
        avoided: [
          ...state.avoided.where((a) => a.id != optimisticAvoided.id),
          avoided,
        ],
      );

      debugPrint('🚫 [AvoidedProvider] Added avoided: $exerciseName (regenerateNow=$regenerateNow)');

      // Regenerate today's workout to remove the avoided exercise
      if (regenerateNow) {
        await _regenerateTodayWorkout(userId);
      }

      // Invalidate workout providers to trigger UI refresh
      _ref.invalidate(todayWorkoutProvider);
      _ref.invalidate(workoutsProvider);
      return true;
    } catch (e) {
      debugPrint('❌ [AvoidedProvider] Error adding avoided: $e');
      // Rollback
      state = state.copyWith(
        avoided: state.avoided.where((a) => a.id != optimisticAvoided.id).toList(),
        error: e.toString(),
      );
      return false;
    }
  }

  /// Remove an exercise from avoided list
  Future<bool> removeAvoided(String exerciseName) async {
    // Find the avoided item to remove
    final avoided = state.avoided.firstWhere(
      (a) => a.exerciseName.toLowerCase() == exerciseName.toLowerCase() && a.isActive,
      orElse: () => throw Exception('Avoided exercise not found'),
    );

    // Optimistic update
    state = state.copyWith(
      avoided: state.avoided.where((a) => a.id != avoided.id).toList(),
    );

    try {
      final apiClient = _ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId == null) {
        // Rollback
        state = state.copyWith(
          avoided: [...state.avoided, avoided],
          error: 'Not logged in',
        );
        return false;
      }

      final repository = _ref.read(exercisePreferencesRepositoryProvider);
      await repository.removeAvoidedExercise(userId, avoided.id);

      debugPrint('🚫 [AvoidedProvider] Removed avoided: $exerciseName');
      return true;
    } catch (e) {
      debugPrint('❌ [AvoidedProvider] Error removing avoided: $e');
      // Rollback
      state = state.copyWith(
        avoided: [...state.avoided, avoided],
        error: e.toString(),
      );
      return false;
    }
  }

  /// Toggle avoided status for an exercise
  Future<bool> toggleAvoided(String exerciseName, {String? exerciseId}) async {
    if (state.isAvoided(exerciseName)) {
      return await removeAvoided(exerciseName);
    } else {
      return await addAvoided(exerciseName, exerciseId: exerciseId);
    }
  }

  /// Regenerate today's workout without the avoided exercise
  Future<void> _regenerateTodayWorkout(String userId) async {
    try {
      state = state.copyWith(
        isRegenerating: true,
        regenerationMessage: 'Updating workout...',
      );

      // Get today's/next workout
      final todayWorkoutAsync = _ref.read(todayWorkoutProvider);
      final response = todayWorkoutAsync.valueOrNull;

      // Get the workout to regenerate (today's or next upcoming)
      final workoutToRegenerate = response?.todayWorkout ?? response?.nextWorkout;

      if (workoutToRegenerate == null) {
        debugPrint('🚫 No workout today - avoided exercise will apply to next generation');
        state = state.copyWith(isRegenerating: false, regenerationMessage: null);
        return;
      }

      final workoutRepo = _ref.read(workoutRepositoryProvider);

      // Regenerate single workout using streaming API
      await for (final progress in workoutRepo.regenerateWorkoutStreaming(
        workoutId: workoutToRegenerate.id,
        userId: userId,
      )) {
        debugPrint('🏋️ Avoided regeneration: ${progress.message}');
        state = state.copyWith(regenerationMessage: progress.message);

        if (progress.isCompleted || progress.hasError) {
          break;
        }
      }

      debugPrint('✅ Workout regenerated without avoided exercise');
      state = state.copyWith(
        isRegenerating: false,
        regenerationMessage: null,
      );
    } catch (e) {
      debugPrint('❌ Failed to regenerate workout: $e');
      state = state.copyWith(
        isRegenerating: false,
        regenerationMessage: null,
      );
      // Don't fail the avoid addition if regeneration fails
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}
