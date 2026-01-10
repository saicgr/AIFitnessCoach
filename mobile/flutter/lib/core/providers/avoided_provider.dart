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
  final String? error;

  const AvoidedState({
    this.avoided = const [],
    this.isLoading = false,
    this.error,
  });

  AvoidedState copyWith({
    List<AvoidedExercise>? avoided,
    bool? isLoading,
    String? error,
  }) {
    return AvoidedState(
      avoided: avoided ?? this.avoided,
      isLoading: isLoading ?? this.isLoading,
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

      // Invalidate workout providers to trigger reload without avoided exercise
      // The backend clears future incomplete workouts, so this will regenerate them
      _ref.invalidate(todayWorkoutProvider);
      _ref.invalidate(workoutsProvider);
      debugPrint('🚫 [AvoidedProvider] Added avoided: $exerciseName - invalidated workout providers for regeneration');
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

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}
