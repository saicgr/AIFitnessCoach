import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
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
    String? aiPrompt,
    String? workoutName,
  }) async {
    try {
      debugPrint('🔍 [Workout] Regenerating workout $workoutId with:');
      debugPrint('  - difficulty: $difficulty');
      debugPrint('  - durationMinutes: $durationMinutes');
      debugPrint('  - focusAreas: $focusAreas');
      debugPrint('  - injuries: $injuries');
      debugPrint('  - equipment: $equipment');
      debugPrint('  - workoutType: $workoutType');
      debugPrint('  - aiPrompt: $aiPrompt');
      debugPrint('  - workoutName: $workoutName');

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
          if (aiPrompt != null && aiPrompt.isNotEmpty) 'ai_prompt': aiPrompt,
          if (workoutName != null && workoutName.isNotEmpty) 'workout_name': workoutName,
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

  /// Get AI-powered workout suggestions for regeneration
  Future<List<Map<String, dynamic>>> getWorkoutSuggestions({
    required String workoutId,
    required String userId,
    String? currentWorkoutType,
    String? prompt,
  }) async {
    try {
      debugPrint('🔍 [Workout] Getting AI workout suggestions...');
      final response = await _apiClient.post(
        '${ApiConstants.workouts}/suggest',
        data: {
          'workout_id': workoutId,
          'user_id': userId,
          if (currentWorkoutType != null) 'current_workout_type': currentWorkoutType,
          if (prompt != null && prompt.isNotEmpty) 'prompt': prompt,
        },
        options: Options(
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(minutes: 2),
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final suggestions = (data['suggestions'] as List? ?? [])
            .map((s) => s as Map<String, dynamic>)
            .toList();
        debugPrint('✅ [Workout] Got ${suggestions.length} AI suggestions');
        return suggestions;
      }
      return [];
    } catch (e) {
      debugPrint('❌ [Workout] Error getting workout suggestions: $e');
      return [];
    }
  }

  /// Update program preferences and regenerate all workouts
  Future<void> updateProgramAndRegenerate({
    required String userId,
    String? difficulty,
    int? durationMinutes,
    List<String>? focusAreas,
    List<String>? injuries,
    List<String>? equipment,
    String? workoutType,
    List<String>? workoutDays,
  }) async {
    try {
      debugPrint('🔍 [Workout] Updating program and regenerating all workouts');
      debugPrint('  - difficulty: $difficulty');
      debugPrint('  - durationMinutes: $durationMinutes');
      debugPrint('  - focusAreas: $focusAreas');
      debugPrint('  - injuries: $injuries');
      debugPrint('  - equipment: $equipment');
      debugPrint('  - workoutType: $workoutType');
      debugPrint('  - workoutDays: $workoutDays');

      final response = await _apiClient.post(
        '${ApiConstants.workouts}/update-program',
        data: {
          'user_id': userId,
          if (difficulty != null) 'difficulty': difficulty,
          if (durationMinutes != null) 'duration_minutes': durationMinutes,
          if (focusAreas != null && focusAreas.isNotEmpty) 'focus_areas': focusAreas,
          if (injuries != null && injuries.isNotEmpty) 'injuries': injuries,
          if (equipment != null && equipment.isNotEmpty) 'equipment': equipment,
          if (workoutType != null) 'workout_type': workoutType,
          if (workoutDays != null && workoutDays.isNotEmpty) 'workout_days': workoutDays,
        },
        options: Options(
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(minutes: 5),
        ),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [Workout] Program updated and workouts regenerated');
      } else {
        throw Exception('Failed to update program: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Workout] Error updating program: $e');
      rethrow;
    }
  }

  /// Get user's current program preferences
  Future<ProgramPreferences?> getProgramPreferences(String userId) async {
    try {
      debugPrint('🔍 [Workout] Fetching program preferences for user: $userId');
      final response = await _apiClient.get(
        '${ApiConstants.users}/$userId/program-preferences',
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [Workout] Program preferences fetched');
        return ProgramPreferences.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('❌ [Workout] Error fetching program preferences: $e');
      return null;
    }
  }

  /// Check if user needs more workouts and auto-generate if running low
  /// Returns a map with generation status
  Future<Map<String, dynamic>> checkAndRegenerateWorkouts(String userId) async {
    try {
      debugPrint('🔍 [Workout] Checking workout status for user: $userId');
      final response = await _apiClient.post(
        '${ApiConstants.workouts}/check-and-regenerate/$userId',
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        debugPrint('✅ [Workout] Check result: ${data['message']}');
        if (data['needs_generation'] == true) {
          debugPrint('🔄 [Workout] Generation scheduled: job_id=${data['job_id']}');
        }
        return data;
      }
      return {'success': false, 'message': 'Failed to check workout status'};
    } catch (e) {
      debugPrint('❌ [Workout] Error checking workout status: $e');
      // Don't rethrow - this is a background check that shouldn't block the UI
      return {'success': false, 'message': 'Error: $e'};
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
    required WorkoutExercise exercise,
    required String userId,
    String? reason,
  }) async {
    try {
      // Build message based on reason
      String message;
      switch (reason) {
        case 'Too difficult':
          message = 'I need an easier alternative';
          break;
        case 'Too easy':
          message = 'I want something more challenging';
          break;
        case 'Equipment unavailable':
          message = "I don't have the equipment for this exercise";
          break;
        case 'Injury concern':
          message = 'I have an injury and need a safer alternative';
          break;
        case 'Personal preference':
          message = 'I want a different exercise for variety';
          break;
        default:
          message = 'I want an alternative exercise';
      }

      debugPrint('🔍 [Workout] Getting suggestions for ${exercise.name} - reason: $reason');

      final response = await _apiClient.post(
        '/exercise-suggestions/suggest',
        data: {
          'user_id': userId,
          'message': message,
          'current_exercise': {
            'name': exercise.name,
            'sets': exercise.sets ?? 3,
            'reps': exercise.reps ?? 10,
            'muscle_group': exercise.muscleGroup ?? exercise.primaryMuscle ?? exercise.bodyPart,
            'equipment': exercise.equipment,
          },
        },
      );
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final suggestions = List<Map<String, dynamic>>.from(data['suggestions'] ?? []);
        debugPrint('✅ [Workout] Got ${suggestions.length} suggestions');
        return suggestions;
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

  /// Get AI-generated workout summary
  Future<String?> getWorkoutSummary(String workoutId, {bool forceRegenerate = false}) async {
    try {
      debugPrint('🔍 [Workout] Fetching AI summary for workout: $workoutId (force=$forceRegenerate)');
      final response = await _apiClient.get(
        '${ApiConstants.workouts}/$workoutId/summary',
        queryParameters: forceRegenerate ? {'force_regenerate': 'true'} : null,
        options: Options(
          receiveTimeout: const Duration(minutes: 2), // AI generation can take time
        ),
      );
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final summary = data['summary'] as String?;
        debugPrint('✅ [Workout] Got AI summary: ${summary != null ? summary.substring(0, summary.length > 50 ? 50 : summary.length) : "null"}...');
        return summary;
      }
      debugPrint('⚠️ [Workout] Unexpected status code: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('❌ [Workout] Error fetching workout summary: $e');
      return null;
    }
  }

  /// Regenerate AI workout summary (bypasses cache)
  Future<String?> regenerateWorkoutSummary(String workoutId) async {
    return getWorkoutSummary(workoutId, forceRegenerate: true);
  }

  /// Create a workout log (when workout completes)
  Future<Map<String, dynamic>?> createWorkoutLog({
    required String workoutId,
    required String userId,
    required String setsJson,
    required int totalTimeSeconds,
    String? metadata,
  }) async {
    try {
      debugPrint('🔍 [Workout] Creating workout log for workout: $workoutId');
      final data = {
        'workout_id': workoutId,
        'user_id': userId,
        'sets_json': setsJson,
        'total_time_seconds': totalTimeSeconds,
      };
      // Add metadata if provided
      if (metadata != null) {
        data['metadata'] = metadata;
      }
      final response = await _apiClient.post(
        '/performance/workout-logs',
        data: data,
      );
      if (response.statusCode == 200) {
        debugPrint('✅ [Workout] Workout log created successfully');
        return response.data as Map<String, dynamic>;
      }
      debugPrint('⚠️ [Workout] Unexpected status code: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('❌ [Workout] Error creating workout log: $e');
      return null;
    }
  }

  /// Log a single set performance
  Future<Map<String, dynamic>?> logSetPerformance({
    required String workoutLogId,
    required String userId,
    required String exerciseId,
    required String exerciseName,
    required int setNumber,
    required int repsCompleted,
    required double weightKg,
  }) async {
    try {
      debugPrint('🔍 [Workout] Logging set $setNumber for $exerciseName');
      final response = await _apiClient.post(
        '/performance/logs',
        data: {
          'workout_log_id': workoutLogId,
          'user_id': userId,
          'exercise_id': exerciseId,
          'exercise_name': exerciseName,
          'set_number': setNumber,
          'reps_completed': repsCompleted,
          'weight_kg': weightKg,
          'is_completed': true,
        },
      );
      if (response.statusCode == 200) {
        debugPrint('✅ [Workout] Set logged successfully');
        return response.data as Map<String, dynamic>;
      }
      debugPrint('⚠️ [Workout] Unexpected status code: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('❌ [Workout] Error logging set performance: $e');
      return null;
    }
  }

  /// Log workout exit/quit with reason and progress
  Future<Map<String, dynamic>?> logWorkoutExit({
    required String workoutId,
    required String userId,
    required String exitReason,
    String? exitNotes,
    int exercisesCompleted = 0,
    int totalExercises = 0,
    int setsCompleted = 0,
    int timeSpentSeconds = 0,
    double progressPercentage = 0.0,
  }) async {
    try {
      debugPrint('🔍 [Workout] Logging workout exit: $workoutId, reason: $exitReason');
      final response = await _apiClient.post(
        '${ApiConstants.workouts}/$workoutId/exit',
        data: {
          'workout_id': workoutId,
          'user_id': userId,
          'exit_reason': exitReason,
          'exit_notes': exitNotes,
          'exercises_completed': exercisesCompleted,
          'total_exercises': totalExercises,
          'sets_completed': setsCompleted,
          'time_spent_seconds': timeSpentSeconds,
          'progress_percentage': progressPercentage,
        },
      );
      if (response.statusCode == 200) {
        debugPrint('✅ [Workout] Workout exit logged successfully');
        return response.data as Map<String, dynamic>;
      }
      debugPrint('⚠️ [Workout] Unexpected status code: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('❌ [Workout] Error logging workout exit: $e');
      return null;
    }
  }

  /// Log drink intake during workout
  Future<Map<String, dynamic>?> logDrinkIntake({
    required String workoutId,
    required String userId,
    required int amountMl,
    String drinkType = 'water',
  }) async {
    try {
      debugPrint('🔍 [Workout] Logging drink intake: ${amountMl}ml');
      final response = await _apiClient.post(
        '/performance/drink-intake',
        data: {
          'workout_id': workoutId,
          'user_id': userId,
          'amount_ml': amountMl,
          'drink_type': drinkType,
          'logged_at': DateTime.now().toIso8601String(),
        },
      );
      if (response.statusCode == 200) {
        debugPrint('✅ [Workout] Drink intake logged successfully');
        return response.data as Map<String, dynamic>;
      }
      debugPrint('⚠️ [Workout] Unexpected status code: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('❌ [Workout] Error logging drink intake: $e');
      return null;
    }
  }

  /// Log rest interval between sets/exercises
  Future<Map<String, dynamic>?> logRestInterval({
    required String workoutLogId,
    required String userId,
    required int restSeconds,
    String? exerciseId,
    int? setNumber,
    String restType = 'between_sets', // 'between_sets' or 'between_exercises'
  }) async {
    try {
      debugPrint('🔍 [Workout] Logging rest interval: ${restSeconds}s ($restType)');
      final response = await _apiClient.post(
        '/performance/rest-intervals',
        data: {
          'workout_log_id': workoutLogId,
          'user_id': userId,
          'rest_seconds': restSeconds,
          'exercise_id': exerciseId,
          'set_number': setNumber,
          'rest_type': restType,
          'logged_at': DateTime.now().toIso8601String(),
        },
      );
      if (response.statusCode == 200) {
        debugPrint('✅ [Workout] Rest interval logged successfully');
        return response.data as Map<String, dynamic>;
      }
      debugPrint('⚠️ [Workout] Unexpected status code: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('❌ [Workout] Error logging rest interval: $e');
      return null;
    }
  }

  /// Get AI Coach feedback for completed workout
  /// Uses RAG to retrieve past workout history and generate personalized feedback
  Future<String?> getAICoachFeedback({
    required String workoutLogId,
    required String workoutId,
    required String userId,
    required String workoutName,
    required String workoutType,
    required List<Map<String, dynamic>> exercises,
    required int totalTimeSeconds,
    int totalRestSeconds = 0,
    double avgRestSeconds = 0.0,
    int caloriesBurned = 0,
    int totalSets = 0,
    int totalReps = 0,
    double totalVolumeKg = 0.0,
  }) async {
    try {
      debugPrint('🤖 [Workout] Requesting AI Coach feedback for: $workoutName');

      // Format exercises for the API
      final exercisesList = exercises.map((ex) => {
        'name': ex['name'] ?? ex['exercise_name'] ?? 'Unknown',
        'sets': ex['sets'] ?? ex['total_sets'] ?? 1,
        'reps': ex['reps'] ?? ex['total_reps'] ?? 10,
        'weight_kg': (ex['weight_kg'] ?? ex['weight'] ?? 0.0).toDouble(),
      }).toList();

      final response = await _apiClient.post(
        '/feedback/ai-coach',
        data: {
          'user_id': userId,
          'workout_log_id': workoutLogId,
          'workout_id': workoutId,
          'workout_name': workoutName,
          'workout_type': workoutType,
          'exercises': exercisesList,
          'total_time_seconds': totalTimeSeconds,
          'total_rest_seconds': totalRestSeconds,
          'avg_rest_seconds': avgRestSeconds,
          'calories_burned': caloriesBurned,
          'total_sets': totalSets,
          'total_reps': totalReps,
          'total_volume_kg': totalVolumeKg,
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 60), // AI generation can take time
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final feedback = data['feedback'] as String?;
        debugPrint('✅ [Workout] AI Coach feedback received: ${feedback?.substring(0, feedback.length > 50 ? 50 : feedback.length)}...');
        return feedback;
      }

      debugPrint('⚠️ [Workout] Unexpected status code: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('❌ [Workout] Error getting AI Coach feedback: $e');
      return null;
    }
  }

  /// Get AI Coach workout history from RAG
  Future<List<Map<String, dynamic>>> getAICoachWorkoutHistory({
    required String userId,
    int limit = 10,
  }) async {
    try {
      debugPrint('🔍 [Workout] Fetching AI Coach workout history for user: $userId');
      final response = await _apiClient.get(
        '/feedback/ai-coach/history/$userId',
        queryParameters: {'limit': limit},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final sessions = data['sessions'] as List? ?? [];
        debugPrint('✅ [Workout] Got ${sessions.length} workout sessions from AI Coach history');
        return List<Map<String, dynamic>>.from(sessions);
      }

      return [];
    } catch (e) {
      debugPrint('❌ [Workout] Error fetching AI Coach history: $e');
      return [];
    }
  }

  /// Get exercise weight progression from RAG
  Future<List<Map<String, dynamic>>> getExerciseProgress({
    required String userId,
    required String exerciseName,
    int limit = 10,
  }) async {
    try {
      debugPrint('🔍 [Workout] Fetching exercise progress for: $exerciseName');
      final response = await _apiClient.get(
        '/feedback/ai-coach/exercise-progress/$userId/${Uri.encodeComponent(exerciseName)}',
        queryParameters: {'limit': limit},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final history = data['history'] as List? ?? [];
        debugPrint('✅ [Workout] Got ${history.length} data points for $exerciseName');
        return List<Map<String, dynamic>>.from(history);
      }

      return [];
    } catch (e) {
      debugPrint('❌ [Workout] Error fetching exercise progress: $e');
      return [];
    }
  }

  /// Get user personal records and achievements
  Future<Map<String, dynamic>> getUserAchievements({
    required String userId,
  }) async {
    try {
      debugPrint('🏆 [Workout] Fetching achievements for user: $userId');
      final response = await _apiClient.get(
        '/feedback/ai-coach/achievements/$userId',
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        debugPrint('✅ [Workout] Got achievements data');
        return data;
      }

      return {};
    } catch (e) {
      debugPrint('❌ [Workout] Error fetching achievements: $e');
      return {};
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

  /// Check if user needs more workouts and trigger generation if needed
  /// This should be called on home screen load to ensure continuous workout availability
  Future<Map<String, dynamic>> checkAndRegenerateIfNeeded() async {
    final userId = await _apiClient.getUserId();
    if (userId == null) {
      return {'success': false, 'message': 'No user ID'};
    }

    final result = await _repository.checkAndRegenerateWorkouts(userId);

    // If generation was triggered, set up a delayed refresh to fetch new workouts
    if (result['needs_generation'] == true && result['success'] == true) {
      // Refresh workouts after a delay to allow background generation to complete
      Future.delayed(const Duration(seconds: 30), () async {
        await refresh();
      });
    }

    return result;
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

/// Program preferences model for customization
class ProgramPreferences {
  final String? difficulty;
  final int? durationMinutes;
  final String? workoutType;
  final List<String> workoutDays;
  final List<String> equipment;
  final List<String> focusAreas;
  final List<String> injuries;
  final String? lastUpdated;

  ProgramPreferences({
    this.difficulty,
    this.durationMinutes,
    this.workoutType,
    this.workoutDays = const [],
    this.equipment = const [],
    this.focusAreas = const [],
    this.injuries = const [],
    this.lastUpdated,
  });

  factory ProgramPreferences.fromJson(Map<String, dynamic> json) {
    return ProgramPreferences(
      difficulty: json['difficulty'] as String?,
      durationMinutes: json['duration_minutes'] as int?,
      workoutType: json['workout_type'] as String?,
      workoutDays: (json['workout_days'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      equipment: (json['equipment'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      focusAreas: (json['focus_areas'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      injuries: (json['injuries'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      lastUpdated: json['last_updated'] as String?,
    );
  }
}
