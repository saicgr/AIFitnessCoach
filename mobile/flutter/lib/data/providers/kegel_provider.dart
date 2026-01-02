import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/kegel.dart';
import '../repositories/kegel_repository.dart';
import '../../core/providers/user_provider.dart';

// ============================================================================
// KEGEL PREFERENCES PROVIDERS
// ============================================================================

/// Provider for user's kegel preferences
final kegelPreferencesProvider = FutureProvider.autoDispose<KegelPreferences?>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return null;

  final repository = ref.watch(kegelRepositoryProvider);
  return repository.getPreferences(user.id);
});

/// State notifier for managing kegel preferences
class KegelPreferencesNotifier extends StateNotifier<AsyncValue<KegelPreferences?>> {
  final KegelRepository _repository;
  final String _userId;

  KegelPreferencesNotifier(this._repository, this._userId)
      : super(const AsyncValue.loading()) {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    state = const AsyncValue.loading();
    try {
      final prefs = await _repository.getPreferences(_userId);
      state = AsyncValue.data(prefs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updatePreferences(Map<String, dynamic> data) async {
    try {
      final updated = await _repository.upsertPreferences(_userId, data);
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> toggleKegelsEnabled(bool enabled) async {
    await updatePreferences({'kegels_enabled': enabled});
  }

  Future<void> toggleIncludeInWarmup(bool enabled) async {
    await updatePreferences({'include_in_warmup': enabled});
  }

  Future<void> toggleIncludeInCooldown(bool enabled) async {
    await updatePreferences({'include_in_cooldown': enabled});
  }

  Future<void> setTargetSessionsPerDay(int sessions) async {
    await updatePreferences({'target_sessions_per_day': sessions});
  }

  Future<void> setCurrentLevel(KegelLevel level) async {
    await updatePreferences({
      'current_level': level.toString().split('.').last,
    });
  }

  Future<void> setFocusArea(KegelFocusArea focusArea) async {
    await updatePreferences({
      'focus_area': focusArea.toString().split('.').last,
    });
  }

  Future<void> refresh() async {
    await _loadPreferences();
  }
}

final kegelPreferencesNotifierProvider = StateNotifierProvider.autoDispose
    .family<KegelPreferencesNotifier, AsyncValue<KegelPreferences?>, String>(
  (ref, userId) {
    final repository = ref.watch(kegelRepositoryProvider);
    return KegelPreferencesNotifier(repository, userId);
  },
);

// ============================================================================
// KEGEL SESSIONS PROVIDERS
// ============================================================================

/// Provider for kegel sessions
final kegelSessionsProvider = FutureProvider.autoDispose
    .family<List<KegelSession>, ({String userId, int days})>((ref, params) async {
  final repository = ref.watch(kegelRepositoryProvider);
  final endDate = DateTime.now();
  final startDate = endDate.subtract(Duration(days: params.days));
  return repository.getSessions(params.userId, startDate: startDate, endDate: endDate);
});

/// Provider for today's kegel sessions
final todayKegelSessionsProvider =
    FutureProvider.autoDispose<List<KegelSession>>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return [];

  final repository = ref.watch(kegelRepositoryProvider);
  return repository.getTodaySessions(user.id);
});

/// State notifier for logging kegel sessions
class KegelSessionNotifier extends StateNotifier<AsyncValue<void>> {
  final KegelRepository _repository;
  final String _userId;

  KegelSessionNotifier(this._repository, this._userId)
      : super(const AsyncValue.data(null));

  Future<KegelSession?> logSession({
    required int durationSeconds,
    int? repsCompleted,
    int? holdDurationSeconds,
    KegelSessionType sessionType = KegelSessionType.standard,
    String? exerciseName,
    KegelPerformedDuring? performedDuring,
    String? workoutId,
    int? difficultyRating,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    try {
      final sessionData = {
        'duration_seconds': durationSeconds,
        if (repsCompleted != null) 'reps_completed': repsCompleted,
        if (holdDurationSeconds != null) 'hold_duration_seconds': holdDurationSeconds,
        'session_type': sessionType.toString().split('.').last,
        if (exerciseName != null) 'exercise_name': exerciseName,
        if (performedDuring != null)
          'performed_during': performedDuring.toString().split('.').last,
        if (workoutId != null) 'workout_id': workoutId,
        if (difficultyRating != null) 'difficulty_rating': difficultyRating,
        if (notes != null) 'notes': notes,
      };

      final session = await _repository.createSession(_userId, sessionData);
      state = const AsyncValue.data(null);
      return session;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<KegelSession?> logFromWorkout(
    String workoutId,
    String placement,
    int durationSeconds, {
    List<String>? exercisesCompleted,
  }) async {
    state = const AsyncValue.loading();
    try {
      final session = await _repository.logFromWorkout(
        _userId,
        workoutId,
        placement,
        durationSeconds,
        exercisesCompleted: exercisesCompleted,
      );
      state = const AsyncValue.data(null);
      return session;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final kegelSessionNotifierProvider =
    StateNotifierProvider.autoDispose.family<KegelSessionNotifier, AsyncValue<void>, String>(
  (ref, userId) {
    final repository = ref.watch(kegelRepositoryProvider);
    return KegelSessionNotifier(repository, userId);
  },
);

// ============================================================================
// KEGEL STATS PROVIDERS
// ============================================================================

/// Provider for kegel statistics
final kegelStatsProvider = FutureProvider.autoDispose<KegelStats?>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return null;

  final repository = ref.watch(kegelRepositoryProvider);
  return repository.getStats(user.id);
});

/// Provider for daily kegel goal
final kegelDailyGoalProvider = FutureProvider.autoDispose<KegelDailyGoal?>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return null;

  final repository = ref.watch(kegelRepositoryProvider);
  return repository.checkDailyGoal(user.id);
});

// ============================================================================
// KEGEL EXERCISES PROVIDERS
// ============================================================================

/// Provider for all kegel exercises
final kegelExercisesProvider =
    FutureProvider.autoDispose<List<KegelExercise>>((ref) async {
  final repository = ref.watch(kegelRepositoryProvider);
  return repository.getExercises();
});

/// Provider for filtered kegel exercises
final filteredKegelExercisesProvider = FutureProvider.autoDispose.family<
    List<KegelExercise>,
    ({String? audience, KegelLevel? level, KegelFocusArea? focus})>(
  (ref, params) async {
    final repository = ref.watch(kegelRepositoryProvider);
    return repository.getExercises(
      targetAudience: params.audience,
      difficulty: params.level,
      focusArea: params.focus,
    );
  },
);

/// Provider for a specific kegel exercise
final kegelExerciseProvider =
    FutureProvider.autoDispose.family<KegelExercise?, String>((ref, exerciseId) async {
  final repository = ref.watch(kegelRepositoryProvider);
  return repository.getExercise(exerciseId);
});

// ============================================================================
// WORKOUT INTEGRATION PROVIDERS
// ============================================================================

/// Provider for kegels to include in workout
final kegelsForWorkoutProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>?, ({String userId, String placement})>(
  (ref, params) async {
    final repository = ref.watch(kegelRepositoryProvider);
    return repository.getKegelsForWorkout(params.userId, params.placement);
  },
);

// ============================================================================
// HELPER PROVIDERS
// ============================================================================

/// Provider to check if kegels are enabled
final kegelsEnabledProvider = Provider.autoDispose<bool>((ref) {
  final prefs = ref.watch(kegelPreferencesProvider).value;
  return prefs?.kegelsEnabled ?? false;
});

/// Provider for today's kegel progress
final todayKegelProgressProvider = Provider.autoDispose<double>((ref) {
  final goal = ref.watch(kegelDailyGoalProvider).value;
  return goal?.progressPercent ?? 0.0;
});

/// Provider for current kegel streak
final kegelStreakProvider = Provider.autoDispose<int>((ref) {
  final stats = ref.watch(kegelStatsProvider).value;
  return stats?.currentStreak ?? 0;
});

/// Provider to check if daily kegel goal is met
final dailyKegelGoalMetProvider = Provider.autoDispose<bool>((ref) {
  final goal = ref.watch(kegelDailyGoalProvider).value;
  return goal?.goalMet ?? false;
});
