part of 'workout_repository.dart';

/// Extension on WorkoutRepository for streaming generation, regeneration,
/// and program management methods.
extension WorkoutRepositoryGeneration on WorkoutRepository {
  /// Regenerate a workout with streaming progress updates
  ///
  /// Returns a Stream that emits progress updates at each step:
  /// - Step 1: Loading user profile
  /// - Step 2: Selecting exercises via RAG
  /// - Step 3: Creating workout with AI
  /// - Step 4: Saving workout
  ///
  /// Each progress event contains:
  /// - step/total_steps: Current step number and total steps
  /// - message: Human-readable status
  /// - detail: Additional context
  /// - elapsed_ms: Time elapsed since start
  Stream<RegenerateProgress> regenerateWorkoutStreaming({
    required String workoutId,
    required String userId,
    String? difficulty,
    int? durationMinutes,
    int? durationMinutesMin,
    int? durationMinutesMax,
    List<String>? focusAreas,
    List<String>? injuries,
    List<String>? equipment,
    String? workoutType,
    String? aiPrompt,
    String? workoutName,
    int? dumbbellCount,
    int? kettlebellCount,
  }) async* {
    debugPrint('🚀 [Workout] Starting streaming regeneration for workout $workoutId');
    final startTime = DateTime.now();

    try {
      // Emit initial status
      yield RegenerateProgress(
        step: 0,
        totalSteps: 4,
        message: 'Starting regeneration...',
        elapsedMs: 0,
      );

      // Get the base URL from API client
      final baseUrl = apiClient.baseUrl;

      // Create a new Dio instance for streaming
      final streamingDio = Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(minutes: 3),
        headers: {
          'Accept': 'text/event-stream',
          'Cache-Control': 'no-cache',
        },
      ));

      // Add auth headers from existing client
      final authHeaders = await apiClient.getAuthHeaders();
      streamingDio.options.headers.addAll(authHeaders);

      final response = await streamingDio.post(
        '${ApiConstants.workouts}/regenerate-stream',
        data: {
          'workout_id': workoutId,
          'user_id': userId,
          if (difficulty != null) 'difficulty': difficulty,
          if (durationMinutes != null) 'duration_minutes': durationMinutes,
          if (durationMinutesMin != null) 'duration_minutes_min': durationMinutesMin,
          if (durationMinutesMax != null) 'duration_minutes_max': durationMinutesMax,
          if (focusAreas != null && focusAreas.isNotEmpty) 'focus_areas': focusAreas,
          if (injuries != null && injuries.isNotEmpty) 'injuries': injuries,
          if (equipment != null && equipment.isNotEmpty) 'equipment': equipment,
          if (workoutType != null) 'workout_type': workoutType,
          if (aiPrompt != null && aiPrompt.isNotEmpty) 'ai_prompt': aiPrompt,
          if (workoutName != null && workoutName.isNotEmpty) 'workout_name': workoutName,
          if (dumbbellCount != null) 'dumbbell_count': dumbbellCount,
          if (kettlebellCount != null) 'kettlebell_count': kettlebellCount,
        },
        options: Options(
          responseType: ResponseType.stream,
        ),
      );

      // Handle the response stream properly - cast to ResponseBody first
      final responseBody = response.data as ResponseBody;

      String eventType = '';
      String eventData = '';
      String buffer = '';

      await for (final bytes in responseBody.stream) {
        // Decode bytes to string and add to buffer
        buffer += utf8.decode(bytes);

        // Process complete lines from buffer
        while (buffer.contains('\n')) {
          final newlineIndex = buffer.indexOf('\n');
          final line = buffer.substring(0, newlineIndex).trim();
          buffer = buffer.substring(newlineIndex + 1);

          if (line.isEmpty) {
            // End of event - process accumulated data
            if (eventType.isNotEmpty && eventData.isNotEmpty) {
              try {
                final data = jsonDecode(eventData) as Map<String, dynamic>;
                final elapsedMs = DateTime.now().difference(startTime).inMilliseconds;

                if (eventType == 'progress') {
                  // Progress update
                  yield RegenerateProgress(
                    step: (data['step'] as num?)?.toInt() ?? 0,
                    totalSteps: (data['total_steps'] as num?)?.toInt() ?? 4,
                    message: data['message'] as String? ?? 'Processing...',
                    detail: data['detail'] as String?,
                    elapsedMs: elapsedMs,
                  );
                } else if (eventType == 'done') {
                  // Workout complete
                  final workout = Workout.fromJson(data);
                  yield RegenerateProgress(
                    step: 4,
                    totalSteps: 4,
                    message: 'Workout ready!',
                    elapsedMs: elapsedMs,
                    workout: workout,
                    totalTimeMs: (data['total_time_ms'] as num?)?.toInt(),
                    isCompleted: true,
                  );
                } else if (eventType == 'error') {
                  yield RegenerateProgress(
                    step: 0,
                    totalSteps: 4,
                    message: data['error'] as String? ?? 'Unknown error',
                    elapsedMs: elapsedMs,
                    hasError: true,
                  );
                }
              } catch (e) {
                debugPrint('⚠️ [Workout] Error parsing SSE data: $e');
              }
              eventType = '';
              eventData = '';
            }
            continue;
          }

          if (line.startsWith('event:')) {
            eventType = line.substring(6).trim();
          } else if (line.startsWith('data:')) {
            eventData = line.substring(5).trim();
          }
        }
      }
    } catch (e) {
      debugPrint('❌ [Workout] Streaming regeneration error: $e');
      yield RegenerateProgress(
        step: 0,
        totalSteps: 4,
        message: 'Failed to regenerate workout: $e',
        elapsedMs: DateTime.now().difference(startTime).inMilliseconds,
        hasError: true,
      );
    }
  }

  /// Generate a workout with streaming for faster perceived performance
  ///
  /// Returns a Stream that emits progress updates:
  /// - WorkoutGenerationProgress.started: Generation has begun
  /// - WorkoutGenerationProgress.progress: Generation is in progress with elapsed time
  /// - WorkoutGenerationProgress.completed: Workout is ready
  /// - WorkoutGenerationProgress.error: An error occurred
  Stream<WorkoutGenerationProgress> generateWorkoutStreaming({
    required String userId,
    String? fitnessLevel,
    List<String>? goals,
    List<String>? equipment,
    int durationMinutes = 45,
    int? durationMinutesMin,
    int? durationMinutesMax,
    List<String>? focusAreas,
    String? scheduledDate,  // YYYY-MM-DD format for specific date generation
    bool? skipComeback,
    String? gymProfileId,
  }) async* {
    debugPrint('🚀 [Workout] Starting streaming workout generation for $userId');
    final startTime = DateTime.now();

    try {
      // First, emit started status
      yield WorkoutGenerationProgress(
        status: WorkoutGenerationStatus.started,
        message: 'Generating workout...',
        elapsedMs: 0,
      );

      // Get the base URL from API client
      final baseUrl = apiClient.baseUrl;

      // Create a new Dio instance for streaming
      final streamingDio = Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(minutes: 2),
        headers: {
          'Accept': 'text/event-stream',
          'Cache-Control': 'no-cache',
        },
      ));

      // Add auth headers from existing client
      final authHeaders = await apiClient.getAuthHeaders();
      streamingDio.options.headers.addAll(authHeaders);

      final response = await streamingDio.post(
        '${ApiConstants.workouts}/generate-stream',
        data: {
          'user_id': userId,
          if (fitnessLevel != null) 'fitness_level': fitnessLevel,
          if (goals != null && goals.isNotEmpty) 'goals': goals,
          if (equipment != null && equipment.isNotEmpty) 'equipment': equipment,
          'duration_minutes': durationMinutes,
          if (durationMinutesMin != null) 'duration_minutes_min': durationMinutesMin,
          if (durationMinutesMax != null) 'duration_minutes_max': durationMinutesMax,
          if (focusAreas != null && focusAreas.isNotEmpty) 'focus_areas': focusAreas,
          if (scheduledDate != null) 'scheduled_date': scheduledDate,
          if (skipComeback != null) 'skip_comeback': skipComeback,
          if (gymProfileId != null) 'gym_profile_id': gymProfileId,
        },
        options: Options(
          responseType: ResponseType.stream,
        ),
      );

      // Handle the response stream properly - cast to ResponseBody first
      final responseBody = response.data as ResponseBody;

      String eventType = '';
      String eventData = '';
      String buffer = '';

      await for (final bytes in responseBody.stream) {
        // Decode bytes to string and add to buffer
        buffer += utf8.decode(bytes);

        // Process complete lines from buffer
        while (buffer.contains('\n')) {
          final newlineIndex = buffer.indexOf('\n');
          final line = buffer.substring(0, newlineIndex).trim();
          buffer = buffer.substring(newlineIndex + 1);

          if (line.isEmpty) {
            // End of event - process accumulated data
            if (eventType.isNotEmpty && eventData.isNotEmpty) {
              try {
                final data = jsonDecode(eventData) as Map<String, dynamic>;
                final elapsedMs = DateTime.now().difference(startTime).inMilliseconds;

                if (eventType == 'chunk') {
                  // Progress update
                  yield WorkoutGenerationProgress(
                    status: WorkoutGenerationStatus.progress,
                    message: data['status'] == 'started'
                        ? 'AI is generating your workout...'
                        : 'Building exercises (${data['progress'] ?? 0} chars)...',
                    elapsedMs: elapsedMs,
                  );
                } else if (eventType == 'done') {
                  // Workout complete
                  final workout = Workout.fromJson(data);
                  yield WorkoutGenerationProgress(
                    status: WorkoutGenerationStatus.completed,
                    message: 'Workout ready!',
                    elapsedMs: elapsedMs,
                    workout: workout,
                    totalTimeMs: (data['total_time_ms'] as num?)?.toInt(),
                    chunkCount: (data['chunk_count'] as num?)?.toInt(),
                  );
                } else if (eventType == 'error') {
                  yield WorkoutGenerationProgress(
                    status: WorkoutGenerationStatus.error,
                    message: data['error'] as String? ?? 'Unknown error',
                    elapsedMs: elapsedMs,
                  );
                } else if (eventType == 'already_generating') {
                  // Idempotency: workout generation already in progress
                  debugPrint('⏳ [Workout] Generation already in progress: ${data['workout_id']}');
                  yield WorkoutGenerationProgress(
                    status: WorkoutGenerationStatus.progress,
                    message: data['message'] as String? ?? 'Workout generation in progress...',
                    elapsedMs: elapsedMs,
                  );
                }
              } catch (e) {
                debugPrint('⚠️ [Workout] Error parsing SSE data: $e');
              }
              eventType = '';
              eventData = '';
            }
            continue;
          }

          if (line.startsWith('event:')) {
            eventType = line.substring(6).trim();
          } else if (line.startsWith('data:')) {
            eventData = line.substring(5).trim();
          }
        }
      }
    } catch (e) {
      debugPrint('❌ [Workout] Streaming generation error: $e');

      // Check for rate limit (429) error
      String errorMessage = 'Failed to generate workout';
      if (e is DioException && e.response?.statusCode == 429) {
        errorMessage = 'Rate limit reached. Please wait a moment before trying again.';
        debugPrint('⚠️ [Workout] Rate limit (429) hit - user should wait before retrying');
      } else if (e.toString().contains('429')) {
        errorMessage = 'Rate limit reached. Please wait a moment before trying again.';
      } else {
        errorMessage = 'Failed to generate workout. Please try again.';
      }

      yield WorkoutGenerationProgress(
        status: WorkoutGenerationStatus.error,
        message: errorMessage,
        elapsedMs: DateTime.now().difference(startTime).inMilliseconds,
      );
    }
  }

  /// Generate a mood-based workout with streaming progress updates
  ///
  /// Returns a Stream that emits progress updates at each step:
  /// - Step 1: Loading user profile and mood config
  /// - Step 2: Selecting exercises via RAG
  /// - Step 3: Creating workout with AI
  /// - Step 4: Saving workout and mood check-in
  ///
  /// Each progress event contains:
  /// - step/total_steps: Current step number and total steps
  /// - message: Human-readable status
  /// - detail: Additional context
  /// - mood_emoji/mood_color: Mood info for UI display
  Stream<MoodWorkoutProgress> generateMoodWorkoutStreaming({
    required String userId,
    required Mood mood,
    int? durationMinutes,
    String? deviceInfo,
  }) async* {
    debugPrint('🚀 [Workout] Starting mood workout generation for $userId with mood: ${mood.value}');
    final startTime = DateTime.now();

    try {
      // Emit initial status
      yield MoodWorkoutProgress(
        step: 0,
        totalSteps: 4,
        message: 'Starting ${mood.label.toLowerCase()} mood workout...',
        mood: mood,
        moodEmoji: mood.emoji,
        elapsedMs: 0,
      );

      // Get the base URL from API client
      final baseUrl = apiClient.baseUrl;

      // Create a new Dio instance for streaming
      final streamingDio = Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(minutes: 3),
        headers: {
          'Accept': 'text/event-stream',
          'Cache-Control': 'no-cache',
        },
      ));

      // Add auth headers from existing client
      final authHeaders = await apiClient.getAuthHeaders();
      streamingDio.options.headers.addAll(authHeaders);

      final response = await streamingDio.post(
        '${ApiConstants.workouts}/generate-from-mood-stream',
        data: {
          'user_id': userId,
          'mood': mood.value,
          if (durationMinutes != null) 'duration_minutes': durationMinutes,
          if (deviceInfo != null) 'device_info': deviceInfo,
        },
        options: Options(
          responseType: ResponseType.stream,
        ),
      );

      // Handle the response stream properly - cast to ResponseBody first
      final responseBody = response.data as ResponseBody;

      String eventType = '';
      String eventData = '';
      String buffer = '';

      await for (final bytes in responseBody.stream) {
        // Decode bytes to string and add to buffer
        buffer += utf8.decode(bytes);

        // Process complete lines from buffer
        while (buffer.contains('\n')) {
          final newlineIndex = buffer.indexOf('\n');
          final line = buffer.substring(0, newlineIndex).trim();
          buffer = buffer.substring(newlineIndex + 1);

          if (line.isEmpty) {
            // End of event - process accumulated data
            if (eventType.isNotEmpty && eventData.isNotEmpty) {
              try {
                final data = jsonDecode(eventData) as Map<String, dynamic>;
                final elapsedMs = DateTime.now().difference(startTime).inMilliseconds;

                if (eventType == 'progress') {
                  // Progress update
                  yield MoodWorkoutProgress(
                    step: (data['step'] as num?)?.toInt() ?? 0,
                    totalSteps: (data['total_steps'] as num?)?.toInt() ?? 4,
                    message: data['message'] as String? ?? 'Processing...',
                    detail: data['detail'] as String?,
                    mood: mood,
                    moodEmoji: data['mood_emoji'] as String? ?? mood.emoji,
                    moodColor: data['mood_color'] as String?,
                    elapsedMs: elapsedMs,
                  );
                } else if (eventType == 'done') {
                  // Workout complete - extract workout from response
                  final workoutData = data['workout'] as Map<String, dynamic>?;
                  Workout? workout;
                  if (workoutData != null) {
                    workout = Workout.fromJson(workoutData);
                  }

                  yield MoodWorkoutProgress(
                    step: 4,
                    totalSteps: 4,
                    message: 'Workout ready!',
                    mood: mood,
                    moodEmoji: data['mood_emoji'] as String? ?? mood.emoji,
                    moodColor: data['mood_color'] as String?,
                    elapsedMs: elapsedMs,
                    workout: workout,
                    totalTimeMs: (data['total_time_ms'] as num?)?.toInt(),
                    isCompleted: true,
                  );
                } else if (eventType == 'error') {
                  yield MoodWorkoutProgress(
                    step: 0,
                    totalSteps: 4,
                    message: data['error'] as String? ?? 'Unknown error',
                    mood: mood,
                    elapsedMs: elapsedMs,
                    hasError: true,
                  );
                }
              } catch (e) {
                debugPrint('⚠️ [Workout] Error parsing SSE data: $e');
              }
              eventType = '';
              eventData = '';
            }
            continue;
          }

          if (line.startsWith('event:')) {
            eventType = line.substring(6).trim();
          } else if (line.startsWith('data:')) {
            eventData = line.substring(5).trim();
          }
        }
      }
    } catch (e) {
      debugPrint('❌ [Workout] Mood workout streaming error: $e');
      yield MoodWorkoutProgress(
        step: 0,
        totalSteps: 4,
        message: 'Failed to generate mood workout: $e',
        mood: mood,
        elapsedMs: DateTime.now().difference(startTime).inMilliseconds,
        hasError: true,
      );
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
      final response = await apiClient.post(
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
    int? durationMinutesMin,
    int? durationMinutesMax,
    List<String>? focusAreas,
    List<String>? injuries,
    List<String>? equipment,
    String? workoutType,
    List<String>? workoutDays,
    int? dumbbellCount,
    int? kettlebellCount,
    String? customProgramDescription,
  }) async {
    try {
      debugPrint('🔍 [Workout] Updating program and regenerating all workouts');
      debugPrint('  - difficulty: $difficulty');
      debugPrint('  - durationMinutesMin: $durationMinutesMin');
      debugPrint('  - durationMinutesMax: $durationMinutesMax');
      debugPrint('  - focusAreas: $focusAreas');
      debugPrint('  - injuries: $injuries');
      debugPrint('  - equipment: $equipment');
      debugPrint('  - workoutType: $workoutType');
      debugPrint('  - workoutDays: $workoutDays');
      debugPrint('  - dumbbellCount: $dumbbellCount');
      debugPrint('  - kettlebellCount: $kettlebellCount');
      debugPrint('  - customProgramDescription: $customProgramDescription');

      final response = await apiClient.post(
        '${ApiConstants.workouts}/update-program',
        data: {
          'user_id': userId,
          if (difficulty != null) 'difficulty': difficulty,
          if (durationMinutes != null) 'duration_minutes': durationMinutes,
          if (durationMinutesMin != null) 'duration_minutes_min': durationMinutesMin,
          if (durationMinutesMax != null) 'duration_minutes_max': durationMinutesMax,
          if (focusAreas != null && focusAreas.isNotEmpty) 'focus_areas': focusAreas,
          if (injuries != null) 'injuries': injuries,  // Send even if empty to clear injuries
          if (equipment != null) 'equipment': equipment,  // Send even if empty to clear equipment
          if (workoutType != null) 'workout_type': workoutType,
          if (workoutDays != null && workoutDays.isNotEmpty) 'workout_days': workoutDays,
          if (dumbbellCount != null) 'dumbbell_count': dumbbellCount,
          if (kettlebellCount != null) 'kettlebell_count': kettlebellCount,
          if (customProgramDescription != null && customProgramDescription.isNotEmpty)
            'custom_program_description': customProgramDescription,
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

  /// Quick regenerate workouts using current settings
  /// This deletes future incomplete workouts and regenerates them
  /// without requiring the user to go through the full customization wizard
  Future<Map<String, dynamic>> quickRegenerateWorkouts() async {
    try {
      debugPrint('🔍 [Workout] Quick regenerating workouts with current settings');

      final userId = await apiClient.getUserId();
      if (userId == null) {
        return {
          'success': false,
          'message': 'User not logged in',
        };
      }

      final response = await apiClient.post(
        '${ApiConstants.workouts}/quick-regenerate',
        data: {'user_id': userId},
        options: Options(
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(minutes: 5),
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        debugPrint('✅ [Workout] Quick regeneration complete: ${data['message']}');
        return {
          'success': true,
          'message': data['message'] ?? 'Workouts regenerated successfully!',
          'workouts_deleted': data['workouts_deleted'],
          'workouts_generated': data['workouts_generated'],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to regenerate workouts: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('❌ [Workout] Error quick regenerating workouts: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  /// Quick change workout days without regenerating all workouts
  /// This reschedules existing workouts to the new days intelligently
  Future<Map<String, dynamic>> quickDayChange(
    String userId,
    List<String> workoutDays,
  ) async {
    try {
      debugPrint('🔍 [Workout] Quick day change to: $workoutDays');

      final response = await apiClient.patch(
        '${ApiConstants.workouts}/quick-day-change',
        data: {
          'user_id': userId,
          'workout_days': workoutDays,
        },
        options: Options(
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(minutes: 2),
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        debugPrint('✅ [Workout] Quick day change complete: ${data['message']}');
        debugPrint('  - Rescheduled: ${data['rescheduled_count']} workouts');
        debugPrint('  - Unchanged: ${data['unchanged_count']} workouts');
        return {
          'success': true,
          'message': data['message'] ?? 'Workout days updated!',
          'rescheduled_count': data['rescheduled_count'] ?? 0,
          'unchanged_count': data['unchanged_count'] ?? 0,
          'old_days': data['old_days'] ?? [],
          'new_days': data['new_days'] ?? [],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to update workout days: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('❌ [Workout] Error quick day change: $e');
      rethrow;
    }
  }

  /// Schedule remaining workouts for background generation
  /// This is called after generating the first week, to queue up the rest
  Future<void> scheduleRemainingWorkouts({
    required String userId,
    required List<int> selectedDays,
    required int durationMinutes,
    required int totalWeeks,
    required int weeksGenerated,
  }) async {
    try {
      final remainingWeeks = totalWeeks - weeksGenerated;
      debugPrint('🔍 [Workout] Scheduling $remainingWeeks more weeks for background generation');

      // Calculate start date for remaining workouts (after first week)
      final startDate = DateTime.now().add(Duration(days: 7 * weeksGenerated));
      final startDateStr = startDate.toIso8601String().split('T')[0];

      final response = await apiClient.post(
        '${ApiConstants.workouts}/schedule-background-generation',
        data: {
          'user_id': userId,
          'selected_days': selectedDays,
          'duration_minutes': durationMinutes,
          'weeks': remainingWeeks,
          'month_start_date': startDateStr,
        },
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        debugPrint('✅ [Workout] Background generation scheduled: ${data['message']}');
      }
    } catch (e) {
      // Don't throw - this is a background operation
      debugPrint('⚠️ [Workout] Failed to schedule remaining workouts: $e');
    }
  }

  /// Get generation status for a user
  Future<Map<String, dynamic>> getGenerationStatus(String userId) async {
    try {
      final response = await apiClient.get(
        '${ApiConstants.workouts}/generation-status/$userId',
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      return {'status': 'none'};
    } catch (e) {
      debugPrint('❌ [Workout] Error getting generation status: $e');
      return {'status': 'error', 'error': e.toString()};
    }
  }

  /// Generate more workouts (called when user clicks "View All" or needs more)
  Future<List<Workout>> generateMoreWorkouts({
    required String userId,
    int weeks = 2,
  }) async {
    try {
      debugPrint('🔍 [Workout] Generating $weeks more weeks of workouts...');

      // Use generate-remaining which picks up after existing workouts
      final today = DateTime.now();

      final response = await apiClient.post(
        '${ApiConstants.workouts}/generate-remaining',
        data: {
          'user_id': userId,
          'month_start_date': today.toIso8601String().split('T')[0],
          'selected_days': [0, 1, 2, 3, 4, 5, 6], // Will be filtered by existing prefs
          'duration_minutes': 45,
          'weeks': weeks,
        },
        options: Options(
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: Duration(minutes: weeks <= 2 ? 3 : 5),
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final List<dynamic> workoutsData = data['workouts'] as List? ?? [];
        // Parse workout list in isolate to avoid blocking the UI thread
        final workouts = await compute(_parseWorkoutList, workoutsData);
        debugPrint('✅ [Workout] Generated ${workouts.length} more workouts');
        return workouts;
      }
      return [];
    } catch (e) {
      debugPrint('❌ [Workout] Error generating more workouts: $e');
      rethrow;
    }
  }

  /// Trigger generation of more workouts (max 4) using the simplified endpoint.
  /// Returns immediately - generation happens in background.
  /// Check generation status with [getGenerationStatus] to monitor progress.
  Future<Map<String, dynamic>> triggerGenerateMore({
    required String userId,
    int maxWorkouts = 4,
  }) async {
    try {
      debugPrint('🔍 [Workout] Triggering generation of up to $maxWorkouts workouts...');

      final response = await apiClient.post(
        '${ApiConstants.workouts}/generate-more/$userId',
        queryParameters: {'max_workouts': maxWorkouts},
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        debugPrint('✅ [Workout] Generate more response: $data');
        return data;
      }

      return {'success': false, 'message': 'Unexpected response'};
    } catch (e) {
      debugPrint('❌ [Workout] Error triggering generate more: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Trigger generation of the next single workout (JIT generation)
  ///
  /// This is the primary method for on-demand workout generation.
  /// Called when:
  /// - No workout exists (safety net)
  /// - User manually requests next workout generation
  ///
  /// Returns immediately - generation happens in background.
  Future<Map<String, dynamic>> triggerGenerateNext({
    required String userId,
  }) async {
    try {
      debugPrint('🔍 [Workout] Triggering JIT generation of next workout...');

      final response = await apiClient.post(
        '${ApiConstants.workouts}/generate-next/$userId',
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        debugPrint('✅ [Workout] Generate next response: $data');
        return data;
      }

      return {'success': false, 'message': 'Unexpected response'};
    } catch (e) {
      debugPrint('❌ [Workout] Error triggering generate next: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get user's current program preferences
  Future<ProgramPreferences?> getProgramPreferences(String userId) async {
    try {
      debugPrint('🔍 [Workout] Fetching program preferences for user: $userId');
      final response = await apiClient.get(
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
  /// [thresholdDays] - Generate more workouts if user has less than this many days of workouts (default: 7)
  Future<Map<String, dynamic>> checkAndRegenerateWorkouts(String userId, {int thresholdDays = 7}) async {
    try {
      debugPrint('🔍 [Workout] Checking workout status for user: $userId (threshold: $thresholdDays days)');
      final response = await apiClient.post(
        '${ApiConstants.workouts}/check-and-regenerate/$userId',
        queryParameters: {'threshold_days': thresholdDays},
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
}
