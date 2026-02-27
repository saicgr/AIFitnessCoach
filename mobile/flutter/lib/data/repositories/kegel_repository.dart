import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/kegel.dart';
import '../services/api_client.dart';

/// Repository for kegel/pelvic floor API interactions
class KegelRepository {
  final ApiClient _apiClient;

  KegelRepository(this._apiClient);

  // ============================================================================
  // KEGEL PREFERENCES
  // ============================================================================

  /// Get user's kegel preferences
  Future<KegelPreferences?> getPreferences(String userId) async {
    try {
      final response = await _apiClient.get('/kegel/preferences/$userId');
      if (response.data == null) return null;
      return KegelPreferences.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error fetching kegel preferences: $e');
      return null;
    }
  }

  /// Update or create kegel preferences
  Future<KegelPreferences?> upsertPreferences(
    String userId,
    Map<String, dynamic> preferencesData,
  ) async {
    try {
      final response = await _apiClient.put(
        '/kegel/preferences/$userId',
        data: preferencesData,
      );
      return KegelPreferences.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error upserting kegel preferences: $e');
      rethrow;
    }
  }

  /// Delete kegel preferences
  Future<void> deletePreferences(String userId) async {
    try {
      await _apiClient.delete('/kegel/preferences/$userId');
    } catch (e) {
      debugPrint('Error deleting kegel preferences: $e');
      rethrow;
    }
  }

  // ============================================================================
  // KEGEL SESSIONS
  // ============================================================================

  /// Log a kegel session
  Future<KegelSession?> createSession(
    String userId,
    Map<String, dynamic> sessionData,
  ) async {
    try {
      final response = await _apiClient.post(
        '/kegel/sessions/$userId',
        data: sessionData,
      );
      return KegelSession.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error creating kegel session: $e');
      rethrow;
    }
  }

  /// Get kegel sessions with optional date range
  Future<List<KegelSession>> getSessions(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String().split('T')[0];
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String().split('T')[0];
      }
      queryParams['limit'] = limit;

      final response = await _apiClient.get(
        '/kegel/sessions/$userId',
        queryParameters: queryParams,
      );

      if (response.data is List) {
        return (response.data as List)
            .map((e) => KegelSession.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching kegel sessions: $e');
      return [];
    }
  }

  /// Get today's kegel sessions
  Future<List<KegelSession>> getTodaySessions(String userId) async {
    try {
      final response = await _apiClient.get('/kegel/sessions/$userId/today');
      if (response.data is List) {
        return (response.data as List)
            .map((e) => KegelSession.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching today\'s kegel sessions: $e');
      return [];
    }
  }

  // ============================================================================
  // KEGEL STATS
  // ============================================================================

  /// Get kegel statistics
  Future<KegelStats?> getStats(String userId) async {
    try {
      final response = await _apiClient.get('/kegel/stats/$userId');
      if (response.data == null) return null;
      return KegelStats.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error fetching kegel stats: $e');
      return null;
    }
  }

  /// Check daily goal
  Future<KegelDailyGoal?> checkDailyGoal(String userId, {DateTime? date}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (date != null) {
        queryParams['check_date'] = date.toIso8601String().split('T')[0];
      }

      final response = await _apiClient.get(
        '/kegel/daily-goal/$userId',
        queryParameters: queryParams,
      );
      if (response.data == null) return null;
      return KegelDailyGoal.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error checking daily kegel goal: $e');
      return null;
    }
  }

  // ============================================================================
  // KEGEL EXERCISES
  // ============================================================================

  /// Get list of kegel exercises
  Future<List<KegelExercise>> getExercises({
    String? targetAudience,
    KegelLevel? difficulty,
    KegelFocusArea? focusArea,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (targetAudience != null) {
        queryParams['target_audience'] = targetAudience;
      }
      if (difficulty != null) {
        queryParams['difficulty'] = difficulty.toString().split('.').last;
      }
      if (focusArea != null) {
        queryParams['focus_area'] = focusArea.toString().split('.').last;
      }

      final response = await _apiClient.get(
        '/kegel/exercises',
        queryParameters: queryParams,
      );

      if (response.data is List) {
        return (response.data as List)
            .map((e) => KegelExercise.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching kegel exercises: $e');
      return [];
    }
  }

  /// Get a specific kegel exercise by ID
  Future<KegelExercise?> getExercise(String exerciseId) async {
    try {
      final response = await _apiClient.get('/kegel/exercises/$exerciseId');
      if (response.data == null) return null;
      return KegelExercise.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error fetching kegel exercise: $e');
      return null;
    }
  }

  /// Get a kegel exercise by name
  Future<KegelExercise?> getExerciseByName(String name) async {
    try {
      final response = await _apiClient.get('/kegel/exercises/by-name/$name');
      if (response.data == null) return null;
      return KegelExercise.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error fetching kegel exercise by name: $e');
      return null;
    }
  }

  // ============================================================================
  // WORKOUT INTEGRATION
  // ============================================================================

  /// Get kegels to include in a workout
  Future<Map<String, dynamic>?> getKegelsForWorkout(
    String userId,
    String placement, // 'warmup', 'cooldown', or 'standalone'
  ) async {
    try {
      final response = await _apiClient.get(
        '/kegel/for-workout/$userId',
        queryParameters: {'placement': placement},
      );
      return response.data as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Error fetching kegels for workout: $e');
      return null;
    }
  }

  /// Log kegels completed during a workout
  Future<KegelSession?> logFromWorkout(
    String userId,
    String workoutId,
    String placement,
    int durationSeconds, {
    List<String>? exercisesCompleted,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'placement': placement,
        'duration_seconds': durationSeconds,
        'workout_id': workoutId,
      };
      if (exercisesCompleted != null && exercisesCompleted.isNotEmpty) {
        queryParams['exercises_completed'] = exercisesCompleted.join(',');
      }

      final response = await _apiClient.post(
        '/kegel/log-from-workout/$userId',
        queryParameters: queryParams,
      );
      if (response.data == null) return null;
      return KegelSession.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error logging kegels from workout: $e');
      rethrow;
    }
  }
}

/// Provider for KegelRepository
final kegelRepositoryProvider = Provider<KegelRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return KegelRepository(apiClient);
});
