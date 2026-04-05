part of 'workout_repository.dart';

/// Extension on WorkoutRepository for performance tracking, AI coach feedback,
/// strength records, exercise stats, program history, active workout modifications,
/// set management, and exercise progression methods.
extension WorkoutRepositoryPerformance on WorkoutRepository {
  /// Get AI-generated workout summary
  Future<String?> getWorkoutSummary(String workoutId, {bool forceRegenerate = false}) async {
    try {
      debugPrint('🔍 [Workout] Fetching AI summary for workout: $workoutId (force=$forceRegenerate)');
      final response = await apiClient.get(
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

  /// Get workout generation parameters and AI reasoning
  /// Returns the user profile, program preferences, and reasoning for exercise selection
  Future<WorkoutGenerationParams?> getWorkoutGenerationParams(String workoutId) async {
    try {
      debugPrint('🔍 [Workout] Fetching generation params for workout: $workoutId');
      final response = await apiClient.get(
        '${ApiConstants.workouts}/$workoutId/generation-params',
        options: Options(
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
      if (response.statusCode == 200) {
        final params = WorkoutGenerationParams.fromJson(response.data as Map<String, dynamic>);
        debugPrint('✅ [Workout] Got generation params with ${params.exerciseReasoning.length} exercise reasons');
        return params;
      }
      debugPrint('⚠️ [Workout] Unexpected status code: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('❌ [Workout] Error fetching generation params: $e');
      return null;
    }
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
      final response = await apiClient.post(
        '/performance/workout-logs',
        data: data,
      );
      if (response.statusCode == 200) {
        debugPrint('✅ [Workout] Workout log created successfully');
        return response.data as Map<String, dynamic>;
      } else if (response.statusCode == 404) {
        debugPrint('⚠️ [Workout] Workout $workoutId not found in database - may not have been synced');
        // The workout ID doesn't exist in the database
        // This can happen if the workout was generated but not saved properly
        return null;
      }
      debugPrint('⚠️ [Workout] Unexpected status code: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('❌ [Workout] Error creating workout log: $e');
      // Log more details about the error for debugging
      if (e.toString().contains('404')) {
        debugPrint('⚠️ [Workout] Workout not found - workout may not have been saved to database');
      }
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
    String setType = 'working', // 'working', 'warmup', 'failure', 'amrap'
    double? rpe,
    int? rir,
    String? notes,
    String? aiInputSource,
    double? targetWeightKg,
    int? targetReps,
    String? progressionModel,
  }) async {
    try {
      debugPrint('🔍 [Workout] Logging set $setNumber ($setType) for $exerciseName');
      final response = await apiClient.post(
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
          'set_type': setType,
          if (rpe != null) 'rpe': rpe,
          if (rir != null) 'rir': rir,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
          if (aiInputSource != null && aiInputSource.isNotEmpty) 'ai_input_source': aiInputSource,
          if (targetWeightKg != null) 'target_weight_kg': targetWeightKg,
          if (targetReps != null) 'target_reps': targetReps,
          if (progressionModel != null) 'progression_model': progressionModel,
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
      final response = await apiClient.post(
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
      final response = await apiClient.post(
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
      final response = await apiClient.post(
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
    // Coach personality settings
    String? coachName,
    String? coachingStyle,
    String? communicationTone,
    double? encouragementLevel,
    // Enhanced context for skip detection and timing
    List<Map<String, dynamic>>? plannedExercises,
    Map<int, int>? exerciseTimeSeconds,
    // Trophy/achievement context for personalized feedback
    List<Map<String, dynamic>>? earnedPRs,
    List<Map<String, dynamic>>? earnedAchievements,
    int? totalWorkoutsCompleted,
    Map<String, dynamic>? nextMilestone,
  }) async {
    try {
      debugPrint('🤖 [Workout] Requesting AI Coach feedback for: $workoutName');
      debugPrint('🤖 [Workout] Completed exercises: ${exercises.length}');
      debugPrint('🤖 [Workout] Planned exercises: ${plannedExercises?.length ?? 0}');

      // Format exercises for the API with enhanced data (time_seconds, set_details)
      final exercisesList = exercises.asMap().entries.map((entry) {
        final idx = entry.key;
        final ex = entry.value;
        return {
          'name': ex['name'] ?? ex['exercise_name'] ?? 'Unknown',
          'sets': ex['sets'] ?? ex['total_sets'] ?? 1,
          'reps': ex['reps'] ?? ex['total_reps'] ?? 10,
          'weight_kg': (ex['weight_kg'] ?? ex['weight'] ?? 0.0).toDouble(),
          'time_seconds': ex['time_seconds'] ?? exerciseTimeSeconds?[idx] ?? 0,
          'set_details': ex['set_details'] ?? [],
        };
      }).toList();

      // Format planned exercises for skip detection
      final plannedList = plannedExercises?.map((ex) => {
        'name': ex['name'] ?? 'Unknown',
        'target_sets': ex['target_sets'] ?? ex['sets'] ?? 3,
        'target_reps': ex['target_reps'] ?? ex['reps'] ?? 10,
        'target_weight_kg': (ex['target_weight_kg'] ?? ex['weight'] ?? 0.0).toDouble(),
      }).toList() ?? [];

      final requestData = {
        'user_id': userId,
        'workout_log_id': workoutLogId,
        'workout_id': workoutId,
        'workout_name': workoutName,
        'workout_type': workoutType,
        'exercises': exercisesList,
        'planned_exercises': plannedList,
        'total_time_seconds': totalTimeSeconds,
        'total_rest_seconds': totalRestSeconds,
        'avg_rest_seconds': avgRestSeconds,
        'calories_burned': caloriesBurned,
        'total_sets': totalSets,
        'total_reps': totalReps,
        'total_volume_kg': totalVolumeKg,
      };

      // Add coach personality settings if provided
      if (coachName != null) requestData['coach_name'] = coachName;
      if (coachingStyle != null) requestData['coaching_style'] = coachingStyle;
      if (communicationTone != null) requestData['communication_tone'] = communicationTone;
      if (encouragementLevel != null) requestData['encouragement_level'] = encouragementLevel;

      // Add trophy/achievement context for personalized feedback
      if (earnedPRs != null && earnedPRs.isNotEmpty) {
        requestData['earned_prs'] = earnedPRs;
      }
      if (earnedAchievements != null && earnedAchievements.isNotEmpty) {
        requestData['earned_achievements'] = earnedAchievements;
      }
      if (totalWorkoutsCompleted != null) {
        requestData['total_workouts_completed'] = totalWorkoutsCompleted;
      }
      if (nextMilestone != null) {
        requestData['next_milestone'] = nextMilestone;
      }

      final response = await apiClient.post(
        '/feedback/ai-coach',
        data: requestData,
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
      final response = await apiClient.get(
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
      final response = await apiClient.get(
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
      final response = await apiClient.get(
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

  /// Get the last performance data for a specific exercise
  /// Returns sets from the most recent workout that included this exercise
  Future<Map<String, dynamic>?> getExerciseLastPerformance({
    required String userId,
    required String exerciseName,
  }) async {
    try {
      debugPrint('🔍 [Workout] Fetching last performance for: $exerciseName');
      final response = await apiClient.get(
        '/performance/exercise-last-performance/${Uri.encodeComponent(exerciseName)}',
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        debugPrint('✅ [Workout] Got last performance for $exerciseName: ${data['sets']?.length ?? 0} sets');
        return data;
      }

      return null;
    } catch (e) {
      debugPrint('⚠️ [Workout] No previous performance for $exerciseName: $e');
      return null;
    }
  }

  /// Get strength records (PRs) for a user
  /// Can filter by exercise_id and only show PRs
  Future<List<Map<String, dynamic>>> getStrengthRecords({
    required String userId,
    String? exerciseId,
    bool prsOnly = true,
    int limit = 50,
  }) async {
    try {
      debugPrint('🏆 [Workout] Fetching strength records for user: $userId');
      final queryParams = <String, dynamic>{
        'user_id': userId,
        'prs_only': prsOnly,
        'limit': limit,
      };
      if (exerciseId != null) {
        queryParams['exercise_id'] = exerciseId;
      }

      final response = await apiClient.get(
        '/performance/strength-records',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data as List;
        debugPrint('✅ [Workout] Got ${data.length} strength records');
        return List<Map<String, dynamic>>.from(data);
      }

      return [];
    } catch (e) {
      debugPrint('❌ [Workout] Error fetching strength records: $e');
      return [];
    }
  }

  /// Create a strength record (manual 1RM logging)
  /// The estimated_1rm will be calculated using Brzycki formula if reps > 1
  Future<Map<String, dynamic>?> createStrengthRecord({
    required String userId,
    required String exerciseId,
    required String exerciseName,
    required double weightKg,
    required int reps,
    double? rpe,
    bool isPr = false,
  }) async {
    try {
      debugPrint('🏋️ [Workout] Creating strength record for: $exerciseName');
      debugPrint('  - weight: ${weightKg}kg, reps: $reps, rpe: $rpe');

      // Calculate estimated 1RM using Brzycki formula
      // 1RM = weight x (36 / (37 - reps))
      final estimated1rm = _calculate1rm(weightKg, reps);
      debugPrint('  - estimated 1RM: ${estimated1rm.toStringAsFixed(1)}kg');

      final response = await apiClient.post(
        '/performance/strength-records',
        data: {
          'user_id': userId,
          'exercise_id': exerciseId,
          'exercise_name': exerciseName,
          'weight_kg': weightKg,
          'reps': reps,
          'estimated_1rm': estimated1rm,
          'rpe': rpe,
          'is_pr': isPr,
        },
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [Workout] Strength record created successfully');
        return response.data as Map<String, dynamic>;
      }

      debugPrint('⚠️ [Workout] Unexpected status code: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('❌ [Workout] Error creating strength record: $e');
      return null;
    }
  }

  /// Get estimated 1RM for a specific exercise
  Future<double?> getExercise1rm({
    required String userId,
    required String exerciseName,
  }) async {
    try {
      // Get strength records for this exercise, PRs only
      final records = await getStrengthRecords(
        userId: userId,
        prsOnly: true,
        limit: 10,
      );

      // Find the record with the highest estimated 1RM for this exercise
      final exerciseRecords = records.where(
        (r) => (r['exercise_name'] as String?)?.toLowerCase() == exerciseName.toLowerCase()
      ).toList();

      if (exerciseRecords.isEmpty) return null;

      double max1rm = 0;
      for (final record in exerciseRecords) {
        final est1rm = (record['estimated_1rm'] as num?)?.toDouble() ?? 0;
        if (est1rm > max1rm) max1rm = est1rm;
      }

      return max1rm > 0 ? max1rm : null;
    } catch (e) {
      debugPrint('❌ [Workout] Error getting exercise 1RM: $e');
      return null;
    }
  }

  /// Get exercise history for user (all exercises with stats)
  /// Returns a list of exercises sorted by most performed
  Future<List<ExerciseHistoryItem>> getExerciseHistory({
    required String userId,
    int limit = 20,
  }) async {
    try {
      debugPrint('📊 [Workout] Fetching exercise history for user: $userId');
      final response = await apiClient.get(
        '/performance/exercise-history/$userId',
        queryParameters: {'limit': limit},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List;
        final history = data.map((json) => ExerciseHistoryItem.fromJson(json as Map<String, dynamic>)).toList();
        debugPrint('✅ [Workout] Fetched history for ${history.length} exercises');
        return history;
      }
      return [];
    } catch (e) {
      debugPrint('❌ [Workout] Error fetching exercise history: $e');
      return [];
    }
  }

  /// Get stats for a specific exercise
  Future<ExerciseStats?> getExerciseStats({
    required String userId,
    required String exerciseName,
  }) async {
    try {
      debugPrint('📊 [Workout] Fetching stats for exercise: $exerciseName');
      final encodedName = Uri.encodeComponent(exerciseName);
      final response = await apiClient.get(
        '/performance/exercise-stats/$userId/$encodedName',
      );

      if (response.statusCode == 200) {
        final stats = ExerciseStats.fromJson(response.data as Map<String, dynamic>);
        debugPrint('✅ [Workout] Fetched stats: ${stats.totalSets} sets, max weight: ${stats.maxWeight}kg');
        return stats;
      }
      return null;
    } catch (e) {
      debugPrint('❌ [Workout] Error fetching exercise stats: $e');
      return null;
    }
  }

  // Program history, modifications, set management, and progression methods
  // are in workout_repository_modifications.dart
}
