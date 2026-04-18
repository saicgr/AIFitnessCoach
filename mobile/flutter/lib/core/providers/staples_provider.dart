import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/today_workout_provider.dart';
import '../../data/repositories/exercise_preferences_repository.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/services/api_client.dart';
import '../constants/api_constants.dart';
import 'pending_workout_mutations_provider.dart';

/// State for staple exercises
class StaplesState {
  final List<StapleExercise> staples;
  final bool isLoading;
  final String? error;

  const StaplesState({
    this.staples = const [],
    this.isLoading = false,
    this.error,
  });

  StaplesState copyWith({
    List<StapleExercise>? staples,
    bool? isLoading,
    String? error,
  }) {
    return StaplesState(
      staples: staples ?? this.staples,
      isLoading: isLoading ?? this.isLoading,
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
  ref.keepAlive();
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
    String? swapExerciseId,
    Map<String, double>? cardioParams,
    int? userSets,
    String? userReps,
    int? userRestSeconds,
    double? userWeightLbs,
    List<int>? targetDays,
    String? userTempo,
    String? userNotes,
    String? userBandColor,
    String? userRangeOfMotion,
  }) async {
    // ── 1. Optimistic insert into today's workout ────────────────────
    //
    // If the user chose "add to today's workout" (and we're not just
    // swapping one-for-one — the swap branch replaces in place so there's
    // nothing to inject), synthesize a fully-detailed exercise map and
    // push it into the pending-mutations provider BEFORE any `await`.
    // The workout detail screen merges this entry immediately, so the
    // new row appears within one frame.
    final pending = _ref.read(pendingWorkoutMutationsProvider.notifier);
    final todayResponse = _ref.read(todayWorkoutProvider).valueOrNull;
    final targetWorkoutId =
        todayResponse?.todayWorkout?.id ?? todayResponse?.nextWorkout?.id;

    String? optimisticTempId;
    final shouldOptimistic = addToCurrentWorkout &&
        swapExerciseId == null &&
        targetWorkoutId != null;
    if (shouldOptimistic) {
      optimisticTempId = pending.addOptimistic(
        workoutId: targetWorkoutId,
        section: section,
        exerciseData: _buildOptimisticExerciseMap(
          exerciseName: exerciseName,
          libraryId: libraryId,
          muscleGroup: muscleGroup,
          section: section,
          cardioParams: cardioParams,
          userSets: userSets,
          userReps: userReps,
          userRestSeconds: userRestSeconds,
          userWeightLbs: userWeightLbs,
          userNotes: userNotes,
        ),
      );
    }

    try {
      final apiClient = _ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();
      if (userId == null) {
        if (optimisticTempId != null) pending.remove(optimisticTempId);
        return false;
      }

      // If swapping, replace the old exercise in the workout first
      if (swapExerciseId != null) {
        final todayWorkoutAsync = _ref.read(todayWorkoutProvider);
        final response = todayWorkoutAsync.valueOrNull;
        final workout = response?.todayWorkout ?? response?.nextWorkout;
        if (workout != null) {
          try {
            await apiClient.post(
              '${ApiConstants.workouts}/swap-exercise',
              data: {
                'workout_id': workout.id,
                'old_exercise_name': swapExerciseId,
                'new_exercise_name': exerciseName,
                'section': section,
                if (cardioParams != null) ...cardioParams,
              },
            );
            debugPrint('✅ Swapped "$swapExerciseId" with "$exerciseName"');
          } catch (e) {
            debugPrint('❌ Failed to swap exercise: $e');
          }
        }
      }

      // Fire the staple-save and the today-workout injection in parallel.
      // They write to independent tables (exercise_preferences vs
      // workouts/warmups) and have no mutual data dependency, so we save
      // a round-trip of wall time on the staple+inject path.
      final repo = _ref.read(exercisePreferencesRepositoryProvider);
      final stapleFuture = repo.addStapleExercise(
        userId,
        exerciseName,
        libraryId: libraryId,
        muscleGroup: muscleGroup,
        reason: reason,
        gymProfileId: gymProfileId,
        section: section,
        cardioParams: cardioParams,
        userSets: userSets,
        userReps: userReps,
        userRestSeconds: userRestSeconds,
        userWeightLbs: userWeightLbs,
        targetDays: targetDays,
        userTempo: userTempo,
        userNotes: userNotes,
        userBandColor: userBandColor,
        userRangeOfMotion: userRangeOfMotion,
      );

      final injectFuture = (addToCurrentWorkout && swapExerciseId == null)
          ? _injectIntoCurrentWorkout(
              exerciseName,
              section,
              cardioParams: cardioParams,
            )
          : Future<void>.value();

      final results = await Future.wait<Object?>([stapleFuture, injectFuture]);
      final staple = results[0] as StapleExercise;

      state = state.copyWith(
        staples: [...state.staples, staple],
      );

      debugPrint('⭐ Staple added: $exerciseName');

      // Drop the optimistic temp BEFORE kicking the silent refresh so
      // the merge path doesn't momentarily show two copies once the
      // canonical server row arrives.
      if (optimisticTempId != null) pending.remove(optimisticTempId);

      // Refresh providers silently (no loading flash)
      _ref.read(todayWorkoutProvider.notifier).invalidateAndRefresh();
      _ref.read(workoutsProvider.notifier).silentRefresh();

      return true;
    } catch (e) {
      debugPrint('Error adding staple: $e');
      if (optimisticTempId != null) pending.remove(optimisticTempId);
      return false;
    }
  }

  /// Build a fully-populated exercise map for optimistic UI rendering.
  ///
  /// Matches the shape that `WorkoutExercise.fromJson` (for main-section
  /// cards) and `_getWarmupExercises` / `_getStretchExercises` (for warmup
  /// and stretch tiles) both read — so the new row renders identically to
  /// a server-returned row, with weight/sets/reps/duration/cardio params
  /// visible immediately.
  Map<String, dynamic> _buildOptimisticExerciseMap({
    required String exerciseName,
    String? libraryId,
    String? muscleGroup,
    required String section,
    Map<String, double>? cardioParams,
    int? userSets,
    String? userReps,
    int? userRestSeconds,
    double? userWeightLbs,
    String? userNotes,
  }) {
    final durationSeconds = cardioParams?['duration_seconds']?.toInt();
    // Warmup/stretches default to a 30s block if the user didn't set a
    // duration — matches the backend default in workout_operations.py.
    final resolvedDuration = (section == 'warmup' || section == 'stretches')
        ? (durationSeconds ?? 30)
        : durationSeconds;

    int? repsInt;
    if (userReps != null && userReps.trim().isNotEmpty) {
      final match = RegExp(r'\d+').firstMatch(userReps);
      if (match != null) repsInt = int.tryParse(match.group(0)!);
    }

    // Convert lbs → kg for the `weight` field (WorkoutExercise.weight is
    // stored in kg; the detail screen re-displays as lbs via user prefs).
    final weightKg =
        userWeightLbs != null ? (userWeightLbs / 2.20462) : null;

    return <String, dynamic>{
      'name': exerciseName,
      if (libraryId != null) 'library_id': libraryId,
      if (muscleGroup != null) 'muscle_group': muscleGroup,
      if (userSets != null) 'sets': userSets,
      if (repsInt != null) 'reps': repsInt,
      if (userReps != null && userReps.trim().isNotEmpty)
        'reps_display': userReps,
      if (userRestSeconds != null) 'rest_seconds': userRestSeconds,
      if (weightKg != null) 'weight': weightKg,
      if (resolvedDuration != null) 'duration_seconds': resolvedDuration,
      if (resolvedDuration != null) 'is_timed': true,
      if (userNotes != null && userNotes.isNotEmpty) 'notes': userNotes,
      if (cardioParams?['speed_mph'] != null)
        'speed_mph': cardioParams!['speed_mph'],
      if (cardioParams?['incline_percent'] != null)
        'incline_percent': cardioParams!['incline_percent'],
      if (cardioParams?['rpm'] != null) 'rpm': cardioParams!['rpm'],
      if (cardioParams?['resistance_level'] != null)
        'resistance_level': cardioParams!['resistance_level'],
      if (cardioParams?['stroke_rate_spm'] != null)
        'stroke_rate_spm': cardioParams!['stroke_rate_spm'],
    };
  }

  /// Inject an exercise directly into the current/today's workout
  Future<void> _injectIntoCurrentWorkout(
    String exerciseName,
    String section, {
    Map<String, double>? cardioParams,
  }) async {
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
          if (cardioParams != null) ...cardioParams,
        },
      );

      debugPrint('✅ Injected "$exerciseName" into workout ${workout.id} (section: $section)');
    } catch (e) {
      debugPrint('❌ Failed to inject exercise into workout: $e');
      // Don't fail the staple addition if injection fails
    }
  }

  Future<bool> updateStaple(
    String stapleId, {
    String? section,
    int? userSets,
    String? userReps,
    int? userRestSeconds,
    double? userWeightLbs,
    List<int>? targetDays,
    Map<String, double>? cardioParams,
  }) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();
      if (userId == null) return false;

      final repo = _ref.read(exercisePreferencesRepositoryProvider);
      final updated = await repo.updateStapleExercise(
        userId,
        stapleId,
        section: section,
        userSets: userSets,
        userReps: userReps,
        userRestSeconds: userRestSeconds,
        userWeightLbs: userWeightLbs,
        targetDays: targetDays,
        cardioParams: cardioParams,
      );

      // Replace the old staple with the updated one in state
      state = state.copyWith(
        staples: state.staples.map((s) => s.id == stapleId ? updated : s).toList(),
      );

      debugPrint('✅ Staple updated: ${updated.exerciseName}');

      // Refresh providers silently (no loading flash)
      _ref.read(todayWorkoutProvider.notifier).invalidateAndRefresh();
      _ref.read(workoutsProvider.notifier).silentRefresh();

      return true;
    } catch (e) {
      debugPrint('Error updating staple: $e');
      return false;
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
