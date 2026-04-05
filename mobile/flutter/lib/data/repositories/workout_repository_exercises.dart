part of 'workout_repository.dart';

/// Extension on WorkoutRepository for exercise management methods:
/// warmup/stretches generation, exercise suggestions, swap, add,
/// parse input, extend workout, custom workout creation.
extension WorkoutRepositoryExercises on WorkoutRepository {
  /// Generate warmup exercises for a workout
  ///
  /// If [durationMinutes] is null, uses the user's preference from backend (default 5 min).
  Future<List<Map<String, dynamic>>> generateWarmup(
    String workoutId, {
    int? durationMinutes,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (durationMinutes != null) {
        queryParams['duration_minutes'] = durationMinutes;
      }
      final response = await apiClient.post(
        '${ApiConstants.workouts}/$workoutId/warmup',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
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
  ///
  /// If [durationMinutes] is null, uses the user's preference from backend (default 5 min).
  Future<List<Map<String, dynamic>>> generateStretches(
    String workoutId, {
    int? durationMinutes,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (durationMinutes != null) {
        queryParams['duration_minutes'] = durationMinutes;
      }
      final response = await apiClient.post(
        '${ApiConstants.workouts}/$workoutId/stretches',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
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
  ///
  /// If durations are null, uses the user's preferences from backend (default 5 min each).
  Future<Map<String, List<Map<String, dynamic>>>> generateWarmupAndStretches(
    String workoutId, {
    int? warmupDurationMinutes,
    int? stretchDurationMinutes,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (warmupDurationMinutes != null) {
        queryParams['warmup_duration'] = warmupDurationMinutes;
      }
      if (stretchDurationMinutes != null) {
        queryParams['stretch_duration'] = stretchDurationMinutes;
      }
      final response = await apiClient.post(
        '${ApiConstants.workouts}/$workoutId/warmup-and-stretches',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return {
          'warmup': List<Map<String, dynamic>>.from(data['warmup']?['exercises_json'] ?? data['warmup']?['exercises'] ?? []),
          'stretches': List<Map<String, dynamic>>.from(data['stretches']?['exercises_json'] ?? data['stretches']?['exercises'] ?? []),
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
    List<String>? avoidedExercises,
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
      if (avoidedExercises != null && avoidedExercises.isNotEmpty) {
        debugPrint('🚫 [Workout] Filtering ${avoidedExercises.length} avoided exercises');
      }

      final response = await apiClient.post(
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
          if (avoidedExercises != null && avoidedExercises.isNotEmpty)
            'avoided_exercises': avoidedExercises,
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

  /// Get AI exercise suggestions for adding to a workout (not swapping)
  Future<List<Map<String, dynamic>>> getExerciseSuggestionsForAdd({
    required String workoutType,
    required List<String> existingExercises,
    required String userId,
    List<String>? avoidedExercises,
  }) async {
    try {
      final message =
          'Suggest exercises to add to my $workoutType workout that already has: ${existingExercises.join(', ')}';

      debugPrint('🔍 [Workout] Getting add suggestions for $workoutType workout');

      final response = await apiClient.post(
        '/exercise-suggestions/suggest',
        data: {
          'user_id': userId,
          'message': message,
          'current_exercise': {
            'name': '',
            'muscle_group': workoutType,
          },
          'existing_exercises': existingExercises,
          'mode': 'add',
          if (avoidedExercises != null && avoidedExercises.isNotEmpty)
            'avoided_exercises': avoidedExercises,
        },
      );
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final suggestions = List<Map<String, dynamic>>.from(data['suggestions'] ?? []);
        debugPrint('✅ [Workout] Got ${suggestions.length} add suggestions');
        return suggestions;
      }
      return [];
    } catch (e) {
      debugPrint('❌ [Workout] Error getting add exercise suggestions: $e');
      return [];
    }
  }

  /// Swap an exercise in a workout
  /// Swap an exercise in a workout. Returns (Workout?, errorMessage?).
  /// errorMessage is non-null only on failure, with a user-friendly description.
  Future<(Workout?, String?)> swapExercise({
    required String workoutId,
    required String oldExerciseName,
    required String newExerciseName,
    String? reason,
    String swapSource = 'ai_suggestion',
    String? section,
    Map<String, double>? cardioParams,
  }) async {
    try {
      final response = await apiClient.post(
        '${ApiConstants.workouts}/swap-exercise',
        data: {
          'workout_id': workoutId,
          'old_exercise_name': oldExerciseName,
          'new_exercise_name': newExerciseName,
          if (reason != null) 'reason': reason,
          'swap_source': swapSource,
          if (section != null) 'section': section,
          if (cardioParams != null) ...cardioParams,
        },
      );
      if (response.statusCode == 200) {
        return (Workout.fromJson(response.data as Map<String, dynamic>), null);
      }
      debugPrint('❌ [Workout] Swap failed with status ${response.statusCode}: ${response.data}');
      return (null, 'Server error (${response.statusCode}). Please try again.');
    } on DioException catch (e, stackTrace) {
      debugPrint('❌ [Workout] Error swapping exercise: $e\n$stackTrace');
      if (e.response?.statusCode == 429) {
        return (null, 'Too many swaps. Please wait a moment and try again.');
      }
      if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
        return (null, 'Request timed out. Please try again.');
      }
      return (null, 'Failed to swap exercise. Please try again.');
    } catch (e, stackTrace) {
      debugPrint('❌ [Workout] Error swapping exercise: $e\n$stackTrace');
      return (null, 'Failed to swap exercise. Please try again.');
    }
  }

  /// Add a new exercise to a workout
  Future<Workout?> addExercise({
    required String workoutId,
    required String exerciseName,
    String? exerciseId,
    int sets = 3,
    String reps = '8-12',
    int restSeconds = 60,
    String? section,
    Map<String, double>? cardioParams,
  }) async {
    try {
      debugPrint('🔍 [Workout] Adding exercise "$exerciseName" (id: $exerciseId) to workout $workoutId');
      final response = await apiClient.post(
        '${ApiConstants.workouts}/add-exercise',
        data: {
          'workout_id': workoutId,
          'exercise_name': exerciseName,
          if (exerciseId != null) 'exercise_id': exerciseId,
          'sets': sets,
          'reps': reps,
          'rest_seconds': restSeconds,
          if (section != null) 'section': section,
          if (cardioParams != null) ...cardioParams,
        },
      );
      if (response.statusCode == 200) {
        debugPrint('✅ [Workout] Exercise added successfully');
        return Workout.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('❌ [Workout] Error adding exercise: $e');
      return null;
    }
  }

  /// Parse natural language workout input using AI.
  ///
  /// Accepts text, image (base64), or voice transcript and returns
  /// structured exercise data.
  ///
  /// Examples:
  /// - "3x10 deadlift at 135, 5x5 squat at 140"
  /// - "bench press 4 sets of 8 at 80"
  Future<ParseWorkoutInputResponse?> parseWorkoutInput({
    required String userId,
    required String workoutId,
    String? inputText,
    String? imageBase64,
    String? voiceTranscript,
    bool useKg = false,
  }) async {
    try {
      debugPrint('🤖 [Workout] Parsing workout input: text=${inputText?.substring(0, inputText.length.clamp(0, 50)) ?? "none"}');

      final response = await apiClient.post(
        '${ApiConstants.workouts}/parse-input',
        data: {
          'user_id': userId,
          'workout_id': workoutId,
          if (inputText != null) 'input_text': inputText,
          if (imageBase64 != null) 'image_base64': imageBase64,
          if (voiceTranscript != null) 'voice_transcript': voiceTranscript,
          'use_kg': useKg,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final result = ParseWorkoutInputResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
        debugPrint('✅ [Workout] Parsed ${result.exercises.length} exercises');
        return result;
      }
      return null;
    } catch (e) {
      debugPrint('❌ [Workout] Error parsing workout input: $e');
      rethrow;
    }
  }

  /// Parse workout input with dual-mode support (V2).
  ///
  /// Supports TWO use cases simultaneously:
  /// 1. Set logging: "135*8, 145*6" -> logs sets for CURRENT exercise
  /// 2. Add exercise: "3x10 deadlift at 135" -> adds NEW exercise
  ///
  /// Smart shortcuts supported:
  /// - "+10" -> add 10 to last weight
  /// - "same" -> repeat last set
  /// - "drop" -> 10% weight reduction
  Future<ParseWorkoutInputV2Response?> parseWorkoutInputV2({
    required String userId,
    required String workoutId,
    String? currentExerciseName,
    int? currentExerciseIndex,
    double? lastSetWeight,
    int? lastSetReps,
    String? inputText,
    String? imageBase64,
    String? voiceTranscript,
    bool useKg = false,
  }) async {
    try {
      debugPrint(
        '🤖 [Workout] Parsing V2: exercise=$currentExerciseName, '
        'text=${inputText?.substring(0, inputText.length.clamp(0, 50)) ?? "none"}',
      );

      final response = await apiClient.post(
        '${ApiConstants.workouts}/parse-input-v2',
        data: {
          'user_id': userId,
          'workout_id': workoutId,
          if (currentExerciseName != null)
            'current_exercise_name': currentExerciseName,
          if (currentExerciseIndex != null)
            'current_exercise_index': currentExerciseIndex,
          if (lastSetWeight != null) 'last_set_weight': lastSetWeight,
          if (lastSetReps != null) 'last_set_reps': lastSetReps,
          if (inputText != null) 'input_text': inputText,
          if (imageBase64 != null) 'image_base64': imageBase64,
          if (voiceTranscript != null) 'voice_transcript': voiceTranscript,
          'use_kg': useKg,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final result = ParseWorkoutInputV2Response.fromJson(
          response.data as Map<String, dynamic>,
        );
        debugPrint(
          '✅ [Workout] Parsed ${result.setsToLog.length} sets, '
          '${result.exercisesToAdd.length} exercises',
        );
        return result;
      }
      return null;
    } catch (e) {
      debugPrint('❌ [Workout] Error parsing workout input V2: $e');
      rethrow;
    }
  }

  /// Add multiple parsed exercises to a workout at once.
  ///
  /// Enriches exercises with library metadata and generates set_targets.
  Future<Workout?> addExercisesBatch({
    required String workoutId,
    required String userId,
    required List<ParsedExercise> exercises,
    bool useKg = false,
  }) async {
    try {
      debugPrint('🔍 [Workout] Adding ${exercises.length} exercises to workout $workoutId');

      final response = await apiClient.post(
        '${ApiConstants.workouts}/add-exercises-batch',
        data: {
          'workout_id': workoutId,
          'user_id': userId,
          'exercises': exercises.map((e) => e.toJson()).toList(),
          'use_kg': useKg,
        },
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [Workout] ${exercises.length} exercises added successfully');
        return Workout.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('❌ [Workout] Error adding exercises batch: $e');
      return null;
    }
  }

  /// Get user's recent exercise swaps for quick re-selection
  Future<List<Map<String, dynamic>>> getRecentSwapHistory({
    required String userId,
    int limit = 10,
  }) async {
    try {
      debugPrint('🔍 [Workout] Getting recent swaps for user $userId');
      final response = await apiClient.get(
        '/exercise-preferences/recent-swaps',
        queryParameters: {
          'user_id': userId,
          'limit': limit,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        final swaps = List<Map<String, dynamic>>.from(response.data as List);
        debugPrint('✅ [Workout] Found ${swaps.length} recent swaps');
        return swaps;
      }
      return [];
    } catch (e) {
      debugPrint('❌ [Workout] Error getting recent swaps: $e');
      return [];
    }
  }

  /// Get fast exercise suggestions using database queries (no AI).
  /// Returns 8 similar exercises based on muscle group and equipment.
  /// ~20x faster than AI suggestions (~500ms vs ~10s).
  Future<List<Map<String, dynamic>>> getExerciseSuggestionsFast({
    required String exerciseName,
    required String userId,
    List<String>? avoidedExercises,
  }) async {
    try {
      debugPrint('🔍 [Workout] Getting fast suggestions for: $exerciseName');
      final response = await apiClient.post(
        '/exercise-suggestions/suggest-fast',
        data: {
          'exercise_name': exerciseName,
          'user_id': userId,
          'avoided_exercises': avoidedExercises ?? [],
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        final suggestions =
            List<Map<String, dynamic>>.from(response.data as List);
        debugPrint('✅ [Workout] Got ${suggestions.length} fast suggestions');
        return suggestions;
      }
      return [];
    } catch (e) {
      debugPrint('❌ [Workout] Error getting fast suggestions: $e');
      return [];
    }
  }

  /// Extend a workout with additional AI-generated exercises
  ///
  /// Used when users feel the workout wasn't enough and want to "do more".
  /// The AI will generate complementary exercises based on the existing workout.
  Future<Workout?> extendWorkout({
    required String workoutId,
    required String userId,
    int additionalExercises = 3,
    int additionalDurationMinutes = 15,
    bool focusSameMuscles = true,
    String? intensity, // 'lighter', 'same', 'harder'
  }) async {
    try {
      debugPrint('🔥 [Workout] Extending workout $workoutId with $additionalExercises exercises');
      final response = await apiClient.post(
        '${ApiConstants.workouts}/extend',
        data: {
          'workout_id': workoutId,
          'user_id': userId,
          'additional_exercises': additionalExercises,
          'additional_duration_minutes': additionalDurationMinutes,
          'focus_same_muscles': focusSameMuscles,
          if (intensity != null) 'intensity': intensity,
        },
        options: Options(
          receiveTimeout: const Duration(minutes: 2), // AI generation can take time
        ),
      );
      if (response.statusCode == 200) {
        debugPrint('✅ [Workout] Workout extended successfully');
        return Workout.fromJson(response.data as Map<String, dynamic>);
      }
      debugPrint('⚠️ [Workout] Unexpected status code: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('❌ [Workout] Error extending workout: $e');
      return null;
    }
  }

  /// Create a custom workout from scratch
  ///
  /// Addresses complaint: "It's much better to just use the Daily Strength app
  /// and put together your own plan."
  Future<Workout?> createCustomWorkout({
    required String userId,
    required String name,
    required String workoutType,
    required String difficulty,
    required List<Map<String, dynamic>> exercises,
    int durationMinutes = 45,
    DateTime? scheduledDate,
  }) async {
    try {
      debugPrint('🏋️ [Workout] Creating custom workout: $name with ${exercises.length} exercises');
      final response = await apiClient.post(
        ApiConstants.workouts,
        data: {
          'user_id': userId,
          'name': name,
          'type': workoutType,
          'difficulty': difficulty,
          'scheduled_date': (scheduledDate ?? DateTime.now()).toIso8601String(),
          'exercises_json': exercises,
          'duration_minutes': durationMinutes,
          'generation_method': 'manual',
          'generation_source': 'custom_builder',
        },
      );
      if (response.statusCode == 200) {
        debugPrint('✅ [Workout] Custom workout created successfully');
        return Workout.fromJson(response.data as Map<String, dynamic>);
      }
      debugPrint('⚠️ [Workout] Unexpected status code: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('❌ [Workout] Error creating custom workout: $e');
      return null;
    }
  }
}
