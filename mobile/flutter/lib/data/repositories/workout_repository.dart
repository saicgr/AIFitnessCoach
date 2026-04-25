import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../models/program_history.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../models/mood.dart';
import '../models/today_workout.dart';
import '../models/workout_generation_params.dart';
import '../models/parsed_exercise.dart';
import '../models/workout_screen_summary.dart';
import '../services/api_client.dart';
import '../services/data_cache_service.dart';
import 'auth_repository.dart';
import '../../utils/tz.dart';

export '../models/today_workout.dart';

part 'workout_repository_models.dart';
part 'workout_repository_generation.dart';
part 'workout_repository_exercises.dart';
part 'workout_repository_performance.dart';
part 'workout_repository_modifications.dart';
part 'workout_repository_notifier.dart';

/// Top-level function for parsing workout lists in an isolate via compute().
/// Must be top-level (not a closure or instance method) for compute() to work.
/// Pre-decodes exercisesJson from String to List in the isolate so the
/// exercises getter on the main thread skips the expensive jsonDecode call.
List<Workout> _parseWorkoutList(List<dynamic> data) {
  return data.map((json) {
    final map = json as Map<String, dynamic>;
    // Pre-decode exercises_json String -> List in the isolate so the
    // main-thread getter never needs to call jsonDecode.
    final rawExercises = map['exercises_json'];
    if (rawExercises is String && rawExercises.isNotEmpty) {
      try {
        map['exercises_json'] = jsonDecode(rawExercises);
      } catch (_) {
        // Leave as String; the getter will handle it
      }
    }
    return Workout.fromJson(map);
  }).toList();
}

// ===========================================================================
// Providers
// ===========================================================================

/// Workout repository provider
final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return WorkoutRepository(apiClient);
});

/// Provider to track if AI is generating a workout via chat
/// This allows the home screen to show a loading indicator
final aiGeneratingWorkoutProvider = StateProvider<bool>((ref) => false);

/// Session-scoped provider tracking user's comeback mode choice.
/// null = not yet asked, true = skip comeback (full workout), false = use comeback mode.
/// Resets on app restart.
final comebackChoiceProvider = StateProvider<bool?>((ref) => null);

/// Session-level flag to prevent redundant regeneration checks
/// Resets when app restarts - prevents expensive API calls on every Home tab switch
final hasCheckedRegenerationProvider = StateProvider<bool>((ref) => false);

/// In-memory cache for instant display on provider recreation
/// Survives provider invalidation and prevents loading flash
List<Workout>? _workoutsInMemoryCache;

/// In-memory cache for workout screen summary
WorkoutScreenSummary? _screenSummaryInMemoryCache;

/// Lightweight workout screen summary provider
/// Uses cache-first pattern: returns cached data instantly, refreshes in background
final workoutScreenSummaryProvider =
    FutureProvider<WorkoutScreenSummary?>((ref) async {
  // Return cached data instantly if available
  if (_screenSummaryInMemoryCache != null) {
    // Still refresh in background
    _refreshScreenSummaryInBackground(ref);
    return _screenSummaryInMemoryCache;
  }

  final repository = ref.watch(workoutRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  final userId = authState.user?.id;
  if (userId == null) return null;

  try {
    final summary = await repository.getWorkoutScreenSummary(userId);
    _screenSummaryInMemoryCache = summary;
    return summary;
  } catch (e) {
    debugPrint('❌ [WorkoutScreenSummary] Error: $e');
    return _screenSummaryInMemoryCache;
  }
});

void _refreshScreenSummaryInBackground(Ref ref) {
  Future.microtask(() async {
    try {
      final repository = ref.read(workoutRepositoryProvider);
      final authState = ref.read(authStateProvider);
      final userId = authState.user?.id;
      if (userId == null) return;

      final summary = await repository.getWorkoutScreenSummary(userId);
      _screenSummaryInMemoryCache = summary;
    } catch (_) {}
  });
}

/// Workouts state provider
final workoutsProvider =
    StateNotifierProvider<WorkoutsNotifier, AsyncValue<List<Workout>>>((ref) {
  final repository = ref.watch(workoutRepositoryProvider);
  final apiClient = ref.watch(apiClientProvider);
  // Only rebuild when user identity changes (login/logout), not on data refresh
  final userId = ref.watch(authStateProvider.select((s) => s.user?.id));
  return WorkoutsNotifier(repository, apiClient, userId);
});

/// Single workout provider
final workoutProvider =
    FutureProvider.family<Workout?, String>((ref, workoutId) async {
  final repository = ref.watch(workoutRepositoryProvider);
  return repository.getWorkout(workoutId);
});

// ===========================================================================
// WorkoutRepository - Core CRUD operations
// ===========================================================================

/// Workout repository for API calls.
///
/// Core CRUD methods live here. Extended by:
/// - [WorkoutRepositoryGeneration] (workout_repository_generation.dart)
/// - [WorkoutRepositoryExercises] (workout_repository_exercises.dart)
/// - [WorkoutRepositoryPerformance] (workout_repository_performance.dart)
class WorkoutRepository {
  final ApiClient _apiClient;

  /// Exposed for use by extension methods in part files.
  /// Not intended for external use outside this library.
  ApiClient get apiClient => _apiClient;

  WorkoutRepository(this._apiClient);

  /// Get the current user's ID from the API client
  Future<String?> getCurrentUserId() async {
    return await _apiClient.getUserId();
  }

  /// Get all workouts for a user
  ///
  /// [userId] The user ID to fetch workouts for
  /// [limit] Optional limit on number of workouts to return (default: 50)
  /// [offset] Optional offset for pagination (default: 0)
  Future<List<Workout>> getWorkouts(
    String userId, {
    int? limit,
    int? offset,
    bool allowMultiplePerDate = false,
  }) async {
    try {
      debugPrint('🔍 [Workout] Fetching workouts for user: $userId (limit: ${limit ?? "unlimited"})');
      final queryParams = {'user_id': userId};

      if (limit != null) {
        queryParams['limit'] = limit.toString();
      }
      if (offset != null) {
        queryParams['offset'] = offset.toString();
      }
      if (allowMultiplePerDate) {
        queryParams['allow_multiple_per_date'] = 'true';
      }

      final response = await _apiClient.get(
        '${ApiConstants.workouts}/',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List;
        // Parse workout list in isolate to avoid blocking the UI thread
        final workouts = await compute(_parseWorkoutList, data);
        debugPrint('✅ [Workout] Fetched ${workouts.length} workouts');
        return workouts;
      }
      return [];
    } catch (e) {
      debugPrint('❌ [Workout] Error fetching workouts: $e');
      rethrow;
    }
  }

  /// Get lightweight workout screen summary
  Future<WorkoutScreenSummary> getWorkoutScreenSummary(String userId) async {
    try {
      debugPrint('🔍 [Workout] Fetching screen summary for user: $userId');
      final response = await _apiClient.get(
        '${ApiConstants.workouts}/screen-summary',
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode == 200) {
        final summary = WorkoutScreenSummary.fromJson(
          response.data as Map<String, dynamic>,
        );
        debugPrint('✅ [Workout] Screen summary: ${summary.completedThisWeek}/${summary.plannedThisWeek} this week');
        return summary;
      }
      throw Exception('Failed to fetch screen summary: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ [Workout] Error fetching screen summary: $e');
      rethrow;
    }
  }

  /// Get a single workout.
  /// Checks in-memory cache first for instant display, then fetches from API.
  Future<Workout?> getWorkout(String workoutId) async {
    // Try in-memory cache first for instant display
    if (_workoutsInMemoryCache != null) {
      final cached = _workoutsInMemoryCache!.where((w) => w.id == workoutId).firstOrNull;
      if (cached != null) return cached;
    }

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
  /// Returns WorkoutCompletionResponse which includes PRs detected during the workout
  ///
  /// Uses optimistic UI pattern: marks workout complete in the in-memory cache
  /// immediately before the API call, then rolls back on error.
  Future<WorkoutCompletionResponse?> completeWorkout(String workoutId) async {
    // Optimistic update: mark workout as completed in the in-memory cache immediately
    List<Workout>? previousCache;
    if (_workoutsInMemoryCache != null) {
      previousCache = List<Workout>.from(_workoutsInMemoryCache!);
      _workoutsInMemoryCache = _workoutsInMemoryCache!.map((w) {
        if (w.id == workoutId) {
          return w.copyWith(isCompleted: true);
        }
        return w;
      }).toList();
      debugPrint('⚡ [Workout] Optimistic update: marked $workoutId as complete in cache');
    }

    try {
      debugPrint('🏋️ [Workout] Completing workout: $workoutId');
      final response = await _apiClient.post(
        '${ApiConstants.workouts}/$workoutId/complete',
      );
      if (response.statusCode == 200) {
        final completionResponse = WorkoutCompletionResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
        debugPrint('✅ [Workout] Workout completed: ${completionResponse.message}');
        if (completionResponse.hasPRs) {
          debugPrint('🏆 [Workout] ${completionResponse.prCount} PRs detected!');
          for (final pr in completionResponse.personalRecords) {
            debugPrint('  - ${pr.exerciseName}: ${pr.weightKg}kg x ${pr.reps} = ${pr.estimated1rmKg}kg 1RM');
            if (pr.celebrationMessage != null) {
              debugPrint('    🎉 ${pr.celebrationMessage}');
            }
          }
        }
        return completionResponse;
      }
      // Non-200 response: rollback optimistic update
      if (previousCache != null) {
        _workoutsInMemoryCache = previousCache;
        debugPrint('⚠️ [Workout] Rolled back optimistic update (non-200 response)');
      }
      return null;
    } catch (e) {
      // Error: rollback optimistic update
      if (previousCache != null) {
        _workoutsInMemoryCache = previousCache;
        debugPrint('⚠️ [Workout] Rolled back optimistic update after error: $e');
      }
      debugPrint('❌ [Workout] Error completing workout: $e');
      rethrow;
    }
  }

  /// Clean up old workouts from database
  ///
  /// Deletes all workouts except the most recent [keepCount] upcoming incomplete workouts.
  /// Completed workouts are always preserved.
  ///
  /// This is useful after migrating from batch generation to JIT generation.
  Future<Map<String, dynamic>?> cleanupOldWorkouts(
    String userId, {
    int keepCount = 1,
  }) async {
    try {
      debugPrint('🧹 [Workout] Cleaning up old workouts for user $userId (keeping $keepCount)');
      final response = await _apiClient.delete(
        '${ApiConstants.workouts}/cleanup/$userId',
        queryParameters: {'keep_count': keepCount.toString()},
      );
      if (response.statusCode == 200) {
        final result = response.data as Map<String, dynamic>;
        debugPrint('✅ [Workout] Cleanup complete: ${result['message']}');
        return result;
      }
      return null;
    } catch (e) {
      debugPrint('❌ [Workout] Error cleaning up workouts: $e');
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

  /// Toggle the favorite status of a workout
  Future<bool> toggleWorkoutFavorite(String workoutId) async {
    final userId = await getCurrentUserId();
    final response = await _apiClient.patch(
      '${ApiConstants.workouts}/$workoutId/favorite',
      queryParameters: {'user_id': userId},
    );
    return response.data['is_favorite'] as bool;
  }

  /// Get today's workout for quick start widget
  ///
  /// Returns today's scheduled workout if available, or the next upcoming
  /// workout if today is a rest day.
  Future<TodayWorkoutResponse?> getTodayWorkout() async {
    try {
      debugPrint('🔍 [Workout] Fetching today\'s workout for quick start');
      final userId = await _apiClient.getUserId();
      if (userId == null) {
        debugPrint('❌ [Workout] User not logged in');
        return null;
      }

      final response = await _apiClient.get(
        '${ApiConstants.workouts}/today',
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        debugPrint('✅ [Workout] Today\'s workout fetched: has_workout=${data['has_workout_today']}');
        return TodayWorkoutResponse.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('❌ [Workout] Error fetching today\'s workout: $e');
      return null;
    }
  }

  /// Log quick start button tap for analytics
  ///
  /// This helps track:
  /// - Quick start usage patterns
  /// - Conversion from home screen to active workout
  /// - Time of day preferences
  Future<void> logQuickStart(String workoutId) async {
    try {
      debugPrint('🎯 [Workout] Logging quick start tap for workout: $workoutId');
      final userId = await _apiClient.getUserId();
      if (userId == null) return;

      await _apiClient.post(
        '${ApiConstants.workouts}/today/start',
        queryParameters: {
          'user_id': userId,
          'workout_id': workoutId,
        },
      );
      debugPrint('✅ [Workout] Quick start logged');
    } catch (e) {
      // Non-critical logging - don't fail the main operation
      debugPrint('⚠️ [Workout] Failed to log quick start: $e');
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

  /// Mark a workout as done (quick mark, no set tracking)
  /// Sends completion_method: 'marked_done' to differentiate from tracked completion
  Future<WorkoutCompletionResponse?> markWorkoutAsDone(String workoutId) async {
    // Optimistic update: mark workout as completed in the in-memory cache immediately
    List<Workout>? previousCache;
    if (_workoutsInMemoryCache != null) {
      previousCache = List<Workout>.from(_workoutsInMemoryCache!);
      _workoutsInMemoryCache = _workoutsInMemoryCache!.map((w) {
        if (w.id == workoutId) {
          return w.copyWith(isCompleted: true, completionMethod: 'marked_done');
        }
        return w;
      }).toList();
      debugPrint('⚡ [Workout] Optimistic update: marked $workoutId as done in cache');
    }

    try {
      debugPrint('🏋️ [Workout] Marking workout as done: $workoutId');
      final response = await _apiClient.post(
        '${ApiConstants.workouts}/$workoutId/complete',
        queryParameters: {'completion_method': 'marked_done'},
      );
      if (response.statusCode == 200) {
        final completionResponse = WorkoutCompletionResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
        debugPrint('✅ [Workout] Workout marked as done: ${completionResponse.message}');
        return completionResponse;
      }
      // Non-200 response: rollback optimistic update
      if (previousCache != null) {
        _workoutsInMemoryCache = previousCache;
        debugPrint('⚠️ [Workout] Rolled back optimistic update (non-200 response)');
      }
      return null;
    } catch (e) {
      // Error: rollback optimistic update
      if (previousCache != null) {
        _workoutsInMemoryCache = previousCache;
        debugPrint('⚠️ [Workout] Rolled back optimistic update after error: $e');
      }
      debugPrint('❌ [Workout] Error marking workout as done: $e');
      rethrow;
    }
  }

  /// Undo a workout completion (mark as incomplete)
  Future<bool> uncompleteWorkout(String workoutId) async {
    // Optimistic update: mark workout as incomplete in cache
    List<Workout>? previousCache;
    if (_workoutsInMemoryCache != null) {
      previousCache = List<Workout>.from(_workoutsInMemoryCache!);
      _workoutsInMemoryCache = _workoutsInMemoryCache!.map((w) {
        if (w.id == workoutId) {
          return w.copyWith(isCompleted: false);
        }
        return w;
      }).toList();
      debugPrint('⚡ [Workout] Optimistic update: marked $workoutId as incomplete in cache');
    }

    try {
      debugPrint('🏋️ [Workout] Uncompleting workout: $workoutId');
      final response = await _apiClient.post(
        '${ApiConstants.workouts}/$workoutId/uncomplete',
      );
      if (response.statusCode == 200) {
        debugPrint('✅ [Workout] Workout uncompleted successfully');
        return true;
      }
      // Non-200 response: rollback
      if (previousCache != null) {
        _workoutsInMemoryCache = previousCache;
        debugPrint('⚠️ [Workout] Rolled back uncomplete optimistic update (non-200)');
      }
      return false;
    } catch (e) {
      // Error: rollback
      if (previousCache != null) {
        _workoutsInMemoryCache = previousCache;
        debugPrint('⚠️ [Workout] Rolled back uncomplete optimistic update after error: $e');
      }
      debugPrint('❌ [Workout] Error uncompleting workout: $e');
      rethrow;
    }
  }

  /// Get workouts imported from Health Connect / Apple Health
  List<Workout> getSyncedWorkouts(List<Workout> allWorkouts) {
    return allWorkouts
        .where((w) => w.generationMethod == 'health_connect_import')
        .toList()
      ..sort((a, b) => (b.scheduledDate ?? '').compareTo(a.scheduledDate ?? ''));
  }

  /// Shallow-merge [patch] into the workout's `generation_metadata`, then
  /// PATCH the serialized JSON string back to the API.
  ///
  /// Used by the synced-workout detail screen for in-place RPE/notes edits
  /// and by the opportunistic re-enrichment path. Keys already on the
  /// existing metadata are preserved (only overwritten by matching keys in
  /// [patch]).
  Future<void> updateGenerationMetadata(
    String workoutId,
    Map<String, dynamic> patch,
  ) async {
    try {
      final current = await _apiClient.get(
        '${ApiConstants.workouts}/$workoutId',
      );
      final raw = current.data['generation_metadata'];
      Map<String, dynamic> existing = {};
      if (raw is String && raw.isNotEmpty) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map<String, dynamic>) existing = decoded;
        } catch (_) {}
      } else if (raw is Map<String, dynamic>) {
        existing = raw;
      }
      final merged = {...existing, ...patch};

      await _apiClient.put(
        '${ApiConstants.workouts}/$workoutId',
        data: {'generation_metadata': jsonEncode(merged)},
      );
      debugPrint('✅ [Workout] Updated metadata for $workoutId (${patch.keys.length} keys)');
    } catch (e) {
      debugPrint('❌ [Workout] updateGenerationMetadata failed: $e');
      rethrow;
    }
  }

}

/// Calculate estimated 1RM using Brzycki formula
/// 1RM = weight x (36 / (37 - reps))
/// Top-level so it is accessible from extension part files.
double _calculate1rm(double weight, int reps) {
  if (reps == 1) return weight;
  if (reps >= 37) return weight; // Formula breaks down at high reps
  return weight * (36 / (37 - reps));
}

// WorkoutsNotifier is in workout_repository_notifier.dart (part file)
