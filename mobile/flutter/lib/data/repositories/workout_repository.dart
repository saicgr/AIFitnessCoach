import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../models/workout.dart';
import '../services/api_client.dart';

/// Workout repository provider
final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return WorkoutRepository(apiClient);
});

/// Workouts state provider
final workoutsProvider =
    StateNotifierProvider<WorkoutsNotifier, AsyncValue<List<Workout>>>((ref) {
  final repository = ref.watch(workoutRepositoryProvider);
  final apiClient = ref.watch(apiClientProvider);
  return WorkoutsNotifier(repository, apiClient);
});

/// Single workout provider
final workoutProvider =
    FutureProvider.family<Workout?, String>((ref, workoutId) async {
  final repository = ref.watch(workoutRepositoryProvider);
  return repository.getWorkout(workoutId);
});

/// Workout repository for API calls
class WorkoutRepository {
  final ApiClient _apiClient;

  WorkoutRepository(this._apiClient);

  /// Get all workouts for a user
  Future<List<Workout>> getWorkouts(String userId) async {
    try {
      debugPrint('🔍 [Workout] Fetching workouts for user: $userId');
      final response = await _apiClient.get(
        ApiConstants.workouts,
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List;
        final workouts = data
            .map((json) => Workout.fromJson(json as Map<String, dynamic>))
            .toList();
        debugPrint('✅ [Workout] Fetched ${workouts.length} workouts');
        return workouts;
      }
      return [];
    } catch (e) {
      debugPrint('❌ [Workout] Error fetching workouts: $e');
      rethrow;
    }
  }

  /// Get a single workout
  Future<Workout?> getWorkout(String workoutId) async {
    try {
      final response = await _apiClient.get('${ApiConstants.workouts}/$workoutId');
      if (response.statusCode == 200) {
        return Workout.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('❌ [Workout] Error fetching workout: $e');
      rethrow;
    }
  }

  /// Mark workout as complete
  Future<Workout?> completeWorkout(String workoutId) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.workouts}/$workoutId/complete',
      );
      if (response.statusCode == 200) {
        return Workout.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('❌ [Workout] Error completing workout: $e');
      rethrow;
    }
  }

  /// Generate monthly workouts
  Future<List<Workout>> generateMonthlyWorkouts({
    required String userId,
    required List<int> selectedDays,
    int durationMinutes = 45,
    int weeks = 4,
    String? monthStartDate,
  }) async {
    try {
      debugPrint('🔍 [Workout] Generating monthly workouts...');
      final startDate = monthStartDate ?? DateTime.now().toIso8601String().split('T')[0];

      final response = await _apiClient.post(
        '${ApiConstants.workouts}/generate-monthly',
        data: {
          'user_id': userId,
          'month_start_date': startDate,
          'selected_days': selectedDays,
          'duration_minutes': durationMinutes,
          'weeks': weeks,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final List<dynamic> workoutsData = data['workouts'] as List? ?? [];
        final workouts = workoutsData
            .map((json) => Workout.fromJson(json as Map<String, dynamic>))
            .toList();
        debugPrint('✅ [Workout] Generated ${workouts.length} workouts');
        return workouts;
      }
      return [];
    } catch (e) {
      debugPrint('❌ [Workout] Error generating workouts: $e');
      rethrow;
    }
  }

  /// Regenerate a workout with modifications
  Future<Workout?> regenerateWorkout({
    required String workoutId,
    required String userId,
    String? difficulty,
    int? durationMinutes,
    List<String>? focusAreas,
    List<String>? injuries,
    List<String>? equipment,
    String? workoutType,
  }) async {
    try {
      debugPrint('🔍 [Workout] Regenerating workout $workoutId with:');
      debugPrint('  - difficulty: $difficulty');
      debugPrint('  - durationMinutes: $durationMinutes');
      debugPrint('  - focusAreas: $focusAreas');
      debugPrint('  - injuries: $injuries');
      debugPrint('  - equipment: $equipment');
      debugPrint('  - workoutType: $workoutType');

      // Use longer timeout for regeneration (AI generation can take time + server cold start)
      final response = await _apiClient.post(
        '${ApiConstants.workouts}/regenerate',
        data: {
          'workout_id': workoutId,
          'user_id': userId,
          if (difficulty != null) 'difficulty': difficulty,
          if (durationMinutes != null) 'duration_minutes': durationMinutes,
          if (focusAreas != null) 'focus_areas': focusAreas,
          if (injuries != null && injuries.isNotEmpty) 'injuries': injuries,
          if (equipment != null && equipment.isNotEmpty) 'equipment': equipment,
          if (workoutType != null) 'workout_type': workoutType,
        },
        options: Options(
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(minutes: 5), // Longer timeout for AI generation + cold start
        ),
      );

      if (response.statusCode == 200) {
        return Workout.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('❌ [Workout] Error regenerating workout: $e');
      rethrow;
    }
  }

  /// Delete a workout
  Future<bool> deleteWorkout(String workoutId) async {
    try {
      final response = await _apiClient.delete('${ApiConstants.workouts}/$workoutId');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ [Workout] Error deleting workout: $e');
      return false;
    }
  }

  /// Reschedule a workout
  Future<bool> rescheduleWorkout(String workoutId, String newDate) async {
    try {
      final response = await _apiClient.patch(
        '${ApiConstants.workouts}/$workoutId/reschedule',
        queryParameters: {'new_date': newDate},
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ [Workout] Error rescheduling workout: $e');
      return false;
    }
  }

  /// Get workout versions (history)
  Future<List<Map<String, dynamic>>> getWorkoutVersions(String workoutId) async {
    try {
      final response = await _apiClient.get('${ApiConstants.workouts}/$workoutId/versions');
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data as List);
      }
      return [];
    } catch (e) {
      debugPrint('❌ [Workout] Error fetching versions: $e');
      return [];
    }
  }

  /// Revert workout to a previous version
  Future<Workout?> revertWorkout(String workoutId, int version) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.workouts}/revert',
        data: {'workout_id': workoutId, 'version': version},
      );
      if (response.statusCode == 200) {
        return Workout.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('❌ [Workout] Error reverting workout: $e');
      return null;
    }
  }

  /// Generate warmup exercises for a workout
  Future<List<Map<String, dynamic>>> generateWarmup(String workoutId) async {
    try {
      final response = await _apiClient.post('${ApiConstants.workouts}/$workoutId/warmup');
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(data['exercises'] ?? []);
      }
      return [];
    } catch (e) {
      debugPrint('❌ [Workout] Error generating warmup: $e');
      return [];
    }
  }

  /// Generate stretches for a workout
  Future<List<Map<String, dynamic>>> generateStretches(String workoutId) async {
    try {
      final response = await _apiClient.post('${ApiConstants.workouts}/$workoutId/stretches');
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(data['exercises'] ?? []);
      }
      return [];
    } catch (e) {
      debugPrint('❌ [Workout] Error generating stretches: $e');
      return [];
    }
  }

  /// Generate both warmup and stretches
  Future<Map<String, List<Map<String, dynamic>>>> generateWarmupAndStretches(String workoutId) async {
    try {
      final response = await _apiClient.post('${ApiConstants.workouts}/$workoutId/warmup-and-stretches');
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return {
          'warmup': List<Map<String, dynamic>>.from(data['warmup']?['exercises'] ?? []),
          'stretches': List<Map<String, dynamic>>.from(data['stretches']?['exercises'] ?? []),
        };
      }
      return {'warmup': [], 'stretches': []};
    } catch (e) {
      debugPrint('❌ [Workout] Error generating warmup/stretches: $e');
      return {'warmup': [], 'stretches': []};
    }
  }

  /// Get AI exercise swap suggestions
  Future<List<Map<String, dynamic>>> getExerciseSuggestions({
    required String workoutId,
    required String exerciseName,
    required String userId,
    String? reason,
  }) async {
    try {
      final response = await _apiClient.post(
        '/exercise-suggestions/suggest',
        data: {
          'workout_id': workoutId,
          'exercise_name': exerciseName,
          'user_id': userId,
          if (reason != null) 'reason': reason,
        },
      );
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(data['suggestions'] ?? []);
      }
      return [];
    } catch (e) {
      debugPrint('❌ [Workout] Error getting exercise suggestions: $e');
      return [];
    }
  }

  /// Swap an exercise in a workout
  Future<Workout?> swapExercise({
    required String workoutId,
    required String oldExerciseName,
    required String newExerciseName,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.workouts}/swap',
        data: {
          'workout_id': workoutId,
          'old_exercise_name': oldExerciseName,
          'new_exercise_name': newExerciseName,
        },
      );
      if (response.statusCode == 200) {
        return Workout.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('❌ [Workout] Error swapping exercise: $e');
      return null;
    }
  }
}

/// Workouts state notifier
class WorkoutsNotifier extends StateNotifier<AsyncValue<List<Workout>>> {
  final WorkoutRepository _repository;
  final ApiClient _apiClient;

  WorkoutsNotifier(this._repository, this._apiClient)
      : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    final userId = await _apiClient.getUserId();
    if (userId != null) {
      await fetchWorkouts(userId);
    } else {
      state = const AsyncValue.data([]);
    }
  }

  /// Fetch workouts for user
  Future<void> fetchWorkouts(String userId) async {
    state = const AsyncValue.loading();
    try {
      final workouts = await _repository.getWorkouts(userId);
      // Sort by scheduled date
      workouts.sort((a, b) {
        final dateA = a.scheduledDate ?? '';
        final dateB = b.scheduledDate ?? '';
        return dateA.compareTo(dateB);
      });
      state = AsyncValue.data(workouts);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Refresh workouts
  Future<void> refresh() async {
    final userId = await _apiClient.getUserId();
    if (userId != null) {
      await fetchWorkouts(userId);
    }
  }

  /// Get next workout (closest upcoming incomplete)
  Workout? get nextWorkout {
    final workouts = state.valueOrNull ?? [];
    final today = DateTime.now().toIso8601String().split('T')[0];

    final upcoming = workouts.where((w) {
      final date = w.scheduledDate?.split('T')[0] ?? '';
      return !w.isCompleted! && date.compareTo(today) >= 0;
    }).toList();

    if (upcoming.isEmpty) return null;
    return upcoming.first;
  }

  /// Get upcoming workouts (excluding next)
  List<Workout> get upcomingWorkouts {
    final workouts = state.valueOrNull ?? [];
    final today = DateTime.now().toIso8601String().split('T')[0];
    final next = nextWorkout;

    return workouts.where((w) {
      final date = w.scheduledDate?.split('T')[0] ?? '';
      return !w.isCompleted! && date.compareTo(today) >= 0 && w.id != next?.id;
    }).take(5).toList();
  }

  /// Get completed workouts count
  int get completedCount {
    final workouts = state.valueOrNull ?? [];
    return workouts.where((w) => w.isCompleted == true).length;
  }

  /// Get this week's progress
  (int completed, int total) get weeklyProgress {
    final workouts = state.valueOrNull ?? [];
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));

    final thisWeek = workouts.where((w) {
      if (w.scheduledDate == null) return false;
      try {
        final date = DateTime.parse(w.scheduledDate!);
        return date.isAfter(weekStart.subtract(const Duration(days: 1))) &&
            date.isBefore(weekEnd);
      } catch (_) {
        return false;
      }
    }).toList();

    final completed = thisWeek.where((w) => w.isCompleted == true).length;
    return (completed, thisWeek.length);
  }
}
