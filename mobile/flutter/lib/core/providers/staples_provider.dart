import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/today_workout_provider.dart';
import '../../data/repositories/exercise_preferences_repository.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/services/api_client.dart';
import '../constants/api_constants.dart';

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

  /// Get staples matching a specific profile or "All Profiles"
  List<StapleExercise> staplesForProfile(String? profileId) {
    return staples.where((s) =>
        s.gymProfileId == profileId || s.gymProfileId == null
    ).toList();
  }

  /// Get warmup staples only
  List<StapleExercise> get warmupStaples =>
      staples.where((s) => s.section == 'warmup').toList();

  /// Get stretch staples only
  List<StapleExercise> get stretchStaples =>
      staples.where((s) => s.section == 'stretches').toList();

  /// Get main staples only
  List<StapleExercise> get mainStaples =>
      staples.where((s) => s.section == 'main').toList();
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
    bool addToCurrentWorkout = false,
    String section = 'main',
    String? gymProfileId,
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
        gymProfileId: gymProfileId,
        section: section,
      );

      state = state.copyWith(
        staples: [...state.staples, staple],
      );

      debugPrint('⭐ Staple added: $exerciseName');

      if (addToCurrentWorkout) {
        await _injectIntoCurrentWorkout(exerciseName, section);
      }

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

  /// Inject an exercise directly into the current/today's workout
  Future<void> _injectIntoCurrentWorkout(String exerciseName, String section) async {
    try {
      final todayWorkoutAsync = _ref.read(todayWorkoutProvider);
      final response = todayWorkoutAsync.valueOrNull;
      final workout = response?.todayWorkout ?? response?.nextWorkout;

      if (workout == null) {
        debugPrint('⭐ No workout today - staple will apply to next generation');
        return;
      }

      final apiClient = _ref.read(apiClientProvider);
      await apiClient.post(
        '${ApiConstants.workouts}/add-exercise',
        data: {
          'workout_id': workout.id,
          'exercise_name': exerciseName,
          'section': section,
        },
      );

      debugPrint('✅ Injected "$exerciseName" into workout ${workout.id} (section: $section)');
    } catch (e) {
      debugPrint('❌ Failed to inject exercise into workout: $e');
      // Don't fail the staple addition if injection fails
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
