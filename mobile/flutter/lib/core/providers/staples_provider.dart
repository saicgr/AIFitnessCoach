import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/today_workout_provider.dart';
import '../../data/repositories/exercise_preferences_repository.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/services/api_client.dart';

/// State for staple exercises
class StaplesState {
  final List<StapleExercise> staples;
  final bool isLoading;
  final bool isRegenerating;
  final String? regenerationMessage;
  final String? error;

  const StaplesState({
    this.staples = const [],
    this.isLoading = false,
    this.isRegenerating = false,
    this.regenerationMessage,
    this.error,
  });

  StaplesState copyWith({
    List<StapleExercise>? staples,
    bool? isLoading,
    bool? isRegenerating,
    String? regenerationMessage,
    String? error,
  }) {
    return StaplesState(
      staples: staples ?? this.staples,
      isLoading: isLoading ?? this.isLoading,
      isRegenerating: isRegenerating ?? this.isRegenerating,
      regenerationMessage: regenerationMessage ?? this.regenerationMessage,
      error: error,
    );
  }

  /// Check if an exercise is a staple by name
  bool isStaple(String exerciseName) {
    return staples.any(
      (s) => s.exerciseName.toLowerCase() == exerciseName.toLowerCase(),
    );
  }

  /// Get the set of staple exercise names for quick lookup
  Set<String> get stapleNames =>
      staples.map((s) => s.exerciseName.toLowerCase()).toSet();
}

/// Provider for managing staple exercises
final staplesProvider = StateNotifierProvider<StaplesNotifier, StaplesState>((ref) {
  return StaplesNotifier(ref);
});

class StaplesNotifier extends StateNotifier<StaplesState> {
  final Ref _ref;

  StaplesNotifier(this._ref) : super(const StaplesState(isLoading: true)) {
    _loadStaples();
  }

  Future<void> _loadStaples() async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();
      if (userId == null) {
        state = state.copyWith(isLoading: false, staples: []);
        return;
      }

      final repo = _ref.read(exercisePreferencesRepositoryProvider);
      final staples = await repo.getStapleExercises(userId);
      state = state.copyWith(staples: staples, isLoading: false);
    } catch (e) {
      debugPrint('Error loading staples: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _loadStaples();
  }

  Future<bool> addStaple(
    String exerciseName, {
    String? libraryId,
    String? muscleGroup,
    String? reason,
  }) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();
      if (userId == null) return false;

      final repo = _ref.read(exercisePreferencesRepositoryProvider);
      final staple = await repo.addStapleExercise(
        userId,
        exerciseName,
        libraryId: libraryId,
        muscleGroup: muscleGroup,
        reason: reason,
      );

      state = state.copyWith(
        staples: [...state.staples, staple],
      );

      debugPrint('⭐ Staple added: $exerciseName - regenerating today\'s workout');

      // Regenerate today's workout to include the new staple
      await _regenerateTodayWorkout(userId);

      // Invalidate providers to refresh UI with new workouts
      _ref.invalidate(todayWorkoutProvider);
      _ref.invalidate(workoutsProvider);

      return true;
    } catch (e) {
      debugPrint('Error adding staple: $e');
      state = state.copyWith(isRegenerating: false, regenerationMessage: null);
      return false;
    }
  }

  /// Regenerate today's workout to include the new staple exercise
  Future<void> _regenerateTodayWorkout(String userId) async {
    try {
      state = state.copyWith(
        isRegenerating: true,
        regenerationMessage: 'Updating today\'s workout...',
      );

      // Get today's/next workout
      final todayWorkoutAsync = _ref.read(todayWorkoutProvider);
      final response = todayWorkoutAsync.valueOrNull;

      // Get the workout to regenerate (today's or next upcoming)
      final workoutToRegenerate = response?.todayWorkout ?? response?.nextWorkout;

      if (workoutToRegenerate == null) {
        debugPrint('⭐ No workout today - staple will apply to next generation');
        state = state.copyWith(isRegenerating: false, regenerationMessage: null);
        return;
      }

      final workoutRepo = _ref.read(workoutRepositoryProvider);

      // Regenerate single workout using streaming API
      await for (final progress in workoutRepo.regenerateWorkoutStreaming(
        workoutId: workoutToRegenerate.id,
        userId: userId,
      )) {
        debugPrint('🏋️ Staple regeneration: ${progress.message}');
        state = state.copyWith(regenerationMessage: progress.message);

        if (progress.isCompleted || progress.hasError) {
          break;
        }
      }

      debugPrint('✅ Workout regenerated with new staple');
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
      // Don't fail the staple addition if regeneration fails
    }
  }

  Future<bool> removeStaple(String stapleId) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();
      if (userId == null) return false;

      final repo = _ref.read(exercisePreferencesRepositoryProvider);
      await repo.removeStapleExercise(userId, stapleId);

      state = state.copyWith(
        staples: state.staples.where((s) => s.id != stapleId).toList(),
      );
      return true;
    } catch (e) {
      debugPrint('Error removing staple: $e');
      return false;
    }
  }

  bool isStaple(String exerciseName) {
    return state.staples.any(
      (s) => s.exerciseName.toLowerCase() == exerciseName.toLowerCase(),
    );
  }

  /// Toggle staple status for an exercise
  Future<bool> toggleStaple(
    String exerciseName, {
    String? libraryId,
    String? muscleGroup,
    String? reason,
  }) async {
    if (isStaple(exerciseName)) {
      // Find the staple to remove
      final staple = state.staples.firstWhere(
        (s) => s.exerciseName.toLowerCase() == exerciseName.toLowerCase(),
      );
      return await removeStaple(staple.id);
    } else {
      return await addStaple(
        exerciseName,
        libraryId: libraryId,
        muscleGroup: muscleGroup,
        reason: reason,
      );
    }
  }

  /// Get the set of staple exercise names for quick lookup
  Set<String> get stapleNames =>
      state.staples.map((s) => s.exerciseName.toLowerCase()).toSet();
}
