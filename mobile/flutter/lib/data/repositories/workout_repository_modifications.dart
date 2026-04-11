part of 'workout_repository.dart';

/// Extension on WorkoutRepository for program history, active workout
/// modifications (body part exclusion, exercise replacement), set management
/// (adjustments, edits, deletes), exercise progression, supersets,
/// and workout completion summary methods.
extension WorkoutRepositoryModifications on WorkoutRepository {
  // ==================== Program History Methods ====================

  /// Get program history for a user
  Future<List<ProgramHistory>> getProgramHistory(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      debugPrint('🔍 [Workout] Fetching program history for user $userId');

      final response = await apiClient.get(
        '${ApiConstants.workouts}/program-history/list/$userId',
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final List<dynamic> programsData = data['programs'] as List? ?? [];
        final programs = programsData
            .map((json) => ProgramHistory.fromJson(json as Map<String, dynamic>))
            .toList();

        debugPrint('✅ [Workout] Fetched ${programs.length} program snapshots');
        return programs;
      }

      return [];
    } catch (e) {
      debugPrint('❌ [Workout] Error fetching program history: $e');
      rethrow;
    }
  }

  /// Restore a previous program configuration
  Future<void> restoreProgram(String userId, String programId) async {
    try {
      debugPrint('🔍 [Workout] Restoring program $programId for user $userId');

      final response = await apiClient.post(
        '${ApiConstants.workouts}/program-history/restore',
        data: {
          'user_id': userId,
          'program_id': programId,
        },
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [Workout] Program restored successfully');
      } else {
        throw Exception('Failed to restore program: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Workout] Error restoring program: $e');
      rethrow;
    }
  }

  /// Delete a program snapshot
  Future<void> deleteProgramSnapshot(String programId, String userId) async {
    try {
      debugPrint('🔍 [Workout] Deleting program $programId');

      final response = await apiClient.delete(
        '${ApiConstants.workouts}/program-history/$programId',
        queryParameters: {
          'user_id': userId,
        },
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [Workout] Program deleted successfully');
      } else {
        throw Exception('Failed to delete program: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Workout] Error deleting program: $e');
      rethrow;
    }
  }

  // ==================== Active Workout Modification Methods ====================

  /// Exclude body parts from an active workout
  ///
  /// This removes or skips exercises targeting the specified body parts.
  /// Useful when user has injury or pain in specific areas and wants to
  /// continue their workout without aggravating the issue.
  ///
  /// Returns [BodyPartExclusionResult] with details about removed exercises.
  Future<BodyPartExclusionResult?> excludeBodyParts({
    required String workoutId,
    required List<String> bodyParts,
  }) async {
    try {
      debugPrint('🏋️ [Workout] Excluding body parts: $bodyParts from workout $workoutId');
      final userId = await apiClient.getUserId();
      if (userId == null) {
        debugPrint('❌ [Workout] User not logged in');
        return null;
      }

      final response = await apiClient.post(
        '${ApiConstants.workouts}/$workoutId/exclude-body-parts',
        data: {
          'body_parts': bodyParts,
          'user_id': userId,
        },
      );

      if (response.statusCode == 200) {
        final result = BodyPartExclusionResult.fromJson(
          response.data as Map<String, dynamic>,
        );
        debugPrint('✅ [Workout] Excluded ${result.removedExercises.length} exercises');
        return result;
      }

      debugPrint('⚠️ [Workout] Unexpected status code: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('❌ [Workout] Error excluding body parts: $e');
      return null;
    }
  }

  /// Replace an exercise with a safe alternative
  ///
  /// Finds an alternative exercise that targets the same muscle group
  /// but doesn't involve the body part the user wants to avoid.
  ///
  /// Returns [ExerciseReplaceResult] with the replacement details.
  Future<ExerciseReplaceResult?> replaceExerciseSafe({
    required String workoutId,
    required String exerciseName,
    required String reason,
    String? bodyPartToAvoid,
    String? exerciseId,
  }) async {
    try {
      debugPrint('🔄 [Workout] Replacing exercise: $exerciseName, reason: $reason');
      final userId = await apiClient.getUserId();
      if (userId == null) {
        debugPrint('❌ [Workout] User not logged in');
        return null;
      }

      final response = await apiClient.post(
        '${ApiConstants.workouts}/$workoutId/replace-exercise',
        data: {
          'exercise_name': exerciseName,
          'exercise_id': exerciseId,
          'reason': reason,
          'body_part_to_avoid': bodyPartToAvoid,
          'user_id': userId,
        },
      );

      if (response.statusCode == 200) {
        final result = ExerciseReplaceResult.fromJson(
          response.data as Map<String, dynamic>,
        );
        if (result.replaced) {
          debugPrint('✅ [Workout] Replaced with: ${result.replacement}');
        } else if (result.skipped) {
          debugPrint('⚠️ [Workout] Exercise skipped (no alternative found)');
        }
        return result;
      }

      debugPrint('⚠️ [Workout] Unexpected status code: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('❌ [Workout] Error replacing exercise: $e');
      return null;
    }
  }

  /// Get modification history for a workout
  ///
  /// Returns a list of all modifications made to the workout including
  /// body part exclusions, exercise replacements, and set adjustments.
  Future<List<Map<String, dynamic>>> getWorkoutModificationHistory({
    required String workoutId,
    int limit = 20,
  }) async {
    try {
      debugPrint('🔍 [Workout] Fetching modification history for workout: $workoutId');
      final response = await apiClient.get(
        '${ApiConstants.workouts}/$workoutId/modification-history',
        queryParameters: {'limit': limit},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final modifications = data['modifications'] as List? ?? [];
        debugPrint('✅ [Workout] Got ${modifications.length} modifications');
        return List<Map<String, dynamic>>.from(modifications);
      }

      return [];
    } catch (e) {
      debugPrint('❌ [Workout] Error fetching modification history: $e');
      return [];
    }
  }

  /// Update workout exercises (replace all exercises with new list)
  ///
  /// Used for reverting to original exercises after equipment changes.
  Future<Workout?> updateWorkoutExercises({
    required String workoutId,
    required List<Map<String, dynamic>> exercises,
  }) async {
    try {
      debugPrint('🔄 [Workout] Updating exercises for workout: $workoutId (${exercises.length} exercises)');
      final response = await apiClient.put(
        '${ApiConstants.workouts}/$workoutId/exercises',
        data: {
          'exercises': exercises,
        },
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [Workout] Exercises updated successfully');
        return Workout.fromJson(response.data as Map<String, dynamic>);
      }

      debugPrint('⚠️ [Workout] Unexpected status code: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('❌ [Workout] Error updating exercises: $e');
      rethrow;
    }
  }

  // ==================== Set Management Methods ====================

  /// Log a set adjustment (skipping sets, reducing sets, etc.)
  Future<Map<String, dynamic>?> logSetAdjustment({
    required String workoutLogId,
    required String userId,
    required String exerciseId,
    required String exerciseName,
    required String adjustmentType, // 'skip_remaining', 'remove_set', 'add_set'
    required String reason, // 'fatigue', 'time', 'pain', 'equipment', 'other'
    String? notes,
    required int originalSets,
    required int newSets,
    int? exerciseIndex,
  }) async {
    try {
      debugPrint('🔍 [Workout] Logging set adjustment: $adjustmentType for $exerciseName');
      final response = await apiClient.post(
        '/performance/set-adjustments',
        data: {
          'workout_log_id': workoutLogId,
          'user_id': userId,
          'exercise_id': exerciseId,
          'exercise_name': exerciseName,
          'adjustment_type': adjustmentType,
          'reason': reason,
          'notes': notes,
          'original_sets': originalSets,
          'new_sets': newSets,
          'exercise_index': exerciseIndex,
          'adjusted_at': Tz.timestamp(),
        },
      );
      if (response.statusCode == 200) {
        debugPrint('✅ [Workout] Set adjustment logged successfully');
        return response.data as Map<String, dynamic>;
      }
      debugPrint('⚠️ [Workout] Unexpected status code: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('❌ [Workout] Error logging set adjustment: $e');
      return null;
    }
  }

  /// Edit a completed set's weight and reps
  Future<Map<String, dynamic>?> editSet({
    required String workoutLogId,
    required String userId,
    required String exerciseId,
    required String exerciseName,
    required int setNumber,
    required int newReps,
    required double newWeightKg,
    int? originalReps,
    double? originalWeightKg,
  }) async {
    try {
      debugPrint('🔍 [Workout] Editing set $setNumber for $exerciseName');
      final response = await apiClient.patch(
        '/performance/sets/$workoutLogId/$exerciseId/$setNumber',
        data: {
          'user_id': userId,
          'exercise_name': exerciseName,
          'new_reps': newReps,
          'new_weight_kg': newWeightKg,
          'original_reps': originalReps,
          'original_weight_kg': originalWeightKg,
          'edited_at': Tz.timestamp(),
        },
      );
      if (response.statusCode == 200) {
        debugPrint('✅ [Workout] Set edited successfully');
        return response.data as Map<String, dynamic>;
      }
      debugPrint('⚠️ [Workout] Unexpected status code: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('❌ [Workout] Error editing set: $e');
      return null;
    }
  }

  /// Delete a completed set from a workout
  Future<bool> deleteSet({
    required String workoutLogId,
    required String userId,
    required String exerciseId,
    required int setNumber,
  }) async {
    try {
      debugPrint('🔍 [Workout] Deleting set $setNumber from exercise $exerciseId');
      final response = await apiClient.delete(
        '/performance/sets/$workoutLogId/$exerciseId/$setNumber',
        queryParameters: {
          'user_id': userId,
        },
      );
      if (response.statusCode == 200) {
        debugPrint('✅ [Workout] Set deleted successfully');
        return true;
      }
      debugPrint('⚠️ [Workout] Unexpected status code: ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('❌ [Workout] Error deleting set: $e');
      return false;
    }
  }

  /// Record a set adjustment with reason - convenience method for tracking
  /// user behavior patterns in workout modifications
  ///
  /// This method tracks when users modify their prescribed sets, which helps
  /// the AI learn user preferences and adjust future workout recommendations.
  Future<bool> recordSetAdjustment({
    required String exerciseName,
    required int originalSets,
    required int actualSets,
    required String reason,
    String? notes,
    String? workoutId,
    int? exerciseIndex,
  }) async {
    try {
      final userId = await apiClient.getUserId();
      if (userId == null) {
        debugPrint('⚠️ [Workout] Cannot record set adjustment - user not logged in');
        return false;
      }

      debugPrint('📝 [Workout] Recording set adjustment for $exerciseName');
      debugPrint('   Original: $originalSets sets -> Actual: $actualSets sets');
      debugPrint('   Reason: $reason');
      if (notes != null) debugPrint('   Notes: $notes');

      // Determine adjustment type
      String adjustmentType;
      if (actualSets < originalSets) {
        adjustmentType = actualSets == 0 ? 'skip_all' : 'reduce_sets';
      } else if (actualSets > originalSets) {
        adjustmentType = 'add_sets';
      } else {
        adjustmentType = 'no_change';
      }

      final response = await apiClient.post(
        '/performance/workout-patterns',
        data: {
          'user_id': userId,
          'exercise_name': exerciseName,
          'pattern_type': 'set_adjustment',
          'adjustment_type': adjustmentType,
          'original_sets': originalSets,
          'actual_sets': actualSets,
          'reason': reason,
          'notes': notes,
          'workout_id': workoutId,
          'exercise_index': exerciseIndex,
          'recorded_at': Tz.timestamp(),
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ [Workout] Set adjustment recorded successfully');
        return true;
      }

      debugPrint('⚠️ [Workout] Unexpected status code: ${response.statusCode}');
      return false;
    } catch (e) {
      // Non-critical operation - log error but don't throw
      debugPrint('⚠️ [Workout] Error recording set adjustment (non-critical): $e');
      return false;
    }
  }

  /// Get all set adjustments for a workout
  Future<List<Map<String, dynamic>>> getSetAdjustments({
    required String workoutLogId,
  }) async {
    try {
      debugPrint('🔍 [Workout] Fetching set adjustments for workout: $workoutLogId');
      final response = await apiClient.get(
        '/performance/set-adjustments/$workoutLogId',
      );
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final adjustments = data['adjustments'] as List? ?? [];
        debugPrint('✅ [Workout] Got ${adjustments.length} set adjustments');
        return List<Map<String, dynamic>>.from(adjustments);
      }
      return [];
    } catch (e) {
      debugPrint('❌ [Workout] Error fetching set adjustments: $e');
      return [];
    }
  }

  // ==================== Exercise Progression Methods ====================

  /// Get progression suggestions for exercises the user has mastered
  Future<List<ProgressionSuggestion>> getProgressionSuggestions({
    required String userId,
  }) async {
    try {
      debugPrint('🎯 [Workout] Fetching progression suggestions for user: $userId');
      final response = await apiClient.get(
        '/feedback/progression-suggestions/$userId',
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List;
        final suggestions = data
            .map((json) => ProgressionSuggestion.fromJson(json as Map<String, dynamic>))
            .toList();
        debugPrint('✅ [Workout] Got ${suggestions.length} progression suggestions');
        return suggestions;
      }

      return [];
    } catch (e) {
      debugPrint('⚠️ [Workout] Error fetching progression suggestions: $e');
      return [];
    }
  }

  /// Respond to a progression suggestion (accept or decline)
  Future<bool> respondToProgressionSuggestion({
    required String userId,
    required String exerciseName,
    required String newExerciseName,
    required bool accepted,
    String? declineReason,
  }) async {
    try {
      debugPrint(
        '🎯 [Workout] ${accepted ? "Accepting" : "Declining"} progression: '
        '$exerciseName -> $newExerciseName'
      );

      final response = await apiClient.post(
        '/feedback/progression-response',
        data: {
          'user_id': userId,
          'exercise_name': exerciseName,
          'new_exercise_name': newExerciseName,
          'accepted': accepted,
          'decline_reason': declineReason,
        },
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [Workout] Progression response recorded');
        return true;
      }

      debugPrint('⚠️ [Workout] Unexpected status code: ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('❌ [Workout] Error responding to progression: $e');
      return false;
    }
  }

  /// Log user-created supersets when workout completes (for analytics)
  Future<void> logUserSupersets({
    required String workoutId,
    required String userId,
    required List<WorkoutExercise> exercises,
  }) async {
    try {
      // Find all superset pairs
      final supersetGroups = <int, List<WorkoutExercise>>{};
      for (final ex in exercises) {
        if (ex.isInSuperset) {
          supersetGroups.putIfAbsent(ex.supersetGroup!, () => []).add(ex);
        }
      }

      if (supersetGroups.isEmpty) {
        debugPrint('🔗 [Superset] No supersets to log for workout $workoutId');
        return;
      }

      debugPrint('🔗 [Superset] Logging ${supersetGroups.length} superset pairs');

      // Insert each pair to the analytics table
      for (final entry in supersetGroups.entries) {
        final pair = entry.value;
        if (pair.length == 2) {
          final first = pair.firstWhere((e) => e.isSupersetFirst, orElse: () => pair.first);
          final second = pair.firstWhere((e) => e.isSupersetSecond, orElse: () => pair.last);

          await apiClient.post(
            '/supersets/logs',
            data: {
              'user_id': userId,
              'workout_id': workoutId,
              'exercise_1_name': first.name,
              'exercise_2_name': second.name,
              'exercise_1_muscle': first.primaryMuscle,
              'exercise_2_muscle': second.primaryMuscle,
              'superset_group': entry.key,
            },
          );
          debugPrint('✅ [Superset] Logged: ${first.name} + ${second.name}');
        }
      }
    } catch (e) {
      // Don't fail workout completion if logging fails
      debugPrint('⚠️ [Superset] Failed to log supersets: $e');
    }
  }

  /// Fetch the workout log (including metadata) by workout ID
  Future<Map<String, dynamic>?> getWorkoutLogByWorkoutId(String workoutId) async {
    try {
      debugPrint('🔍 [Workout] Fetching workout log for workout: $workoutId');
      final response = await apiClient.get(
        '/performance/workout-logs/by-workout/$workoutId',
      );
      if (response.statusCode == 200 && response.data != null) {
        debugPrint('✅ [Workout] Workout log fetched successfully');
        return response.data as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('⚠️ [Workout] Error fetching workout log: $e');
      return null;
    }
  }

  /// Get completion summary for a completed workout (PRs, performance comparison, coach summary)
  Future<WorkoutSummaryResponse?> getWorkoutCompletionSummary(String workoutId) async {
    try {
      debugPrint('🏋️ [Workout] Fetching completion summary for workout: $workoutId');
      final response = await apiClient.get(
        '${ApiConstants.workouts}/$workoutId/completion-summary',
      );
      if (response.statusCode == 200) {
        final summary = WorkoutSummaryResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
        debugPrint('✅ [Workout] Completion summary fetched successfully');
        return summary;
      }
      return null;
    } catch (e) {
      debugPrint('❌ [Workout] Error fetching completion summary: $e');
      rethrow;
    }
  }

  /// Update exercise sets for a completed workout (post-completion editing)
  Future<bool> updateExerciseSets(
    String workoutId,
    int exerciseIndex,
    List<Map<String, dynamic>> sets,
  ) async {
    try {
      debugPrint('✏️ [Workout] Updating exercise sets: workout=$workoutId, exercise=$exerciseIndex');
      final response = await apiClient.patch(
        '${ApiConstants.workouts}/$workoutId/exercise-sets',
        data: {
          'exercise_index': exerciseIndex,
          'sets': sets,
        },
      );
      if (response.statusCode == 200) {
        debugPrint('✅ [Workout] Exercise sets updated successfully');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ [Workout] Error updating exercise sets: $e');
      rethrow;
    }
  }

  /// Un-supersede a workout so it becomes current again.
  ///
  /// Used when user regenerates a workout but chooses "Add Workout" instead of
  /// "Replace" -- both the old and new workout should appear for the same date.
  Future<void> unsupersedeWorkout({required String workoutId}) async {
    try {
      debugPrint('🔍 [Workout] Un-superseding workout $workoutId');
      final response = await apiClient.post(
        '${ApiConstants.workouts}/unsupersede',
        data: {'workout_id': workoutId},
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [Workout] Workout un-superseded: $workoutId');
      } else {
        throw Exception('Failed to un-supersede workout: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Workout] Error un-superseding workout: $e');
      rethrow;
    }
  }
}
