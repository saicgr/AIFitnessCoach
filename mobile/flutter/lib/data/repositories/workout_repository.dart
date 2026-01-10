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
import '../services/api_client.dart';
import 'auth_repository.dart';

export '../models/today_workout.dart';

/// Workout repository provider
final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return WorkoutRepository(apiClient);
});

/// Provider to track if AI is generating a workout via chat
/// This allows the home screen to show a loading indicator
final aiGeneratingWorkoutProvider = StateProvider<bool>((ref) => false);

/// Session-level flag to prevent redundant regeneration checks
/// Resets when app restarts - prevents expensive API calls on every Home tab switch
final hasCheckedRegenerationProvider = StateProvider<bool>((ref) => false);

/// Workouts state provider
final workoutsProvider =
    StateNotifierProvider<WorkoutsNotifier, AsyncValue<List<Workout>>>((ref) {
  final repository = ref.watch(workoutRepositoryProvider);
  final apiClient = ref.watch(apiClientProvider);
  // Get userId from authStateProvider (primary source of truth)
  final authState = ref.watch(authStateProvider);
  final userId = authState.user?.id;
  return WorkoutsNotifier(repository, apiClient, userId);
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
  ///
  /// [userId] The user ID to fetch workouts for
  /// [limit] Optional limit on number of workouts to return (default: 50)
  /// [offset] Optional offset for pagination (default: 0)
  Future<List<Workout>> getWorkouts(
    String userId, {
    int? limit,
    int? offset,
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

      final response = await _apiClient.get(
        ApiConstants.workouts,
        queryParameters: queryParams,
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
  /// Returns WorkoutCompletionResponse which includes PRs detected during the workout
  Future<WorkoutCompletionResponse?> completeWorkout(String workoutId) async {
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
      return null;
    } catch (e) {
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

  /// Generate monthly workouts with streaming progress updates
  ///
  /// Returns a Stream that emits progress as each workout is generated.
  /// By default generates 2 weeks of workouts, but can be limited with maxWorkouts.
  ///
  /// Each progress event contains:
  /// - currentWorkout/totalWorkouts: Progress through the batch
  /// - message: "Generating next workout..."
  /// - detail: "Day X of Y"
  /// - workout: The just-generated workout (when available)
  ///
  /// Use maxWorkouts: 1 for on-demand single workout generation.
  Stream<ProgramGenerationProgress> generateMonthlyWorkoutsStreaming({
    required String userId,
    required List<int> selectedDays,
    int durationMinutes = 45,
    String? monthStartDate,
    int? maxWorkouts,
  }) async* {
    debugPrint('🚀 [Workout] Starting streaming program generation for $userId');
    final startTime = DateTime.now();
    final List<Workout> generatedWorkouts = [];

    try {
      // Emit initial status
      yield ProgramGenerationProgress(
        currentWorkout: 0,
        totalWorkouts: 0,
        message: 'Starting workout generation...',
        elapsedMs: 0,
      );

      // Get the base URL from API client
      final baseUrl = _apiClient.baseUrl;

      // Create a new Dio instance for streaming
      final streamingDio = Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(minutes: 5),
        headers: {
          'Accept': 'text/event-stream',
          'Cache-Control': 'no-cache',
        },
      ));

      // Add auth headers from existing client
      final authHeaders = await _apiClient.getAuthHeaders();
      streamingDio.options.headers.addAll(authHeaders);

      final startDate = monthStartDate ?? DateTime.now().toIso8601String().split('T')[0];

      final requestData = {
        'user_id': userId,
        'month_start_date': startDate,
        'selected_days': selectedDays,
        'duration_minutes': durationMinutes,
      };

      // Add max_workouts if specified (for on-demand single workout generation)
      if (maxWorkouts != null) {
        requestData['max_workouts'] = maxWorkouts;
        debugPrint('🎯 [Workout] On-demand mode: generating max $maxWorkouts workout(s)');
      }

      debugPrint('🔍 [Workout] Request data: $requestData');

      final response = await streamingDio.post(
        '${ApiConstants.workouts}/generate-monthly-stream',
        data: requestData,
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
                  // Progress update - generating next workout
                  yield ProgramGenerationProgress(
                    currentWorkout: data['current'] as int? ?? 0,
                    totalWorkouts: data['total'] as int? ?? 0,
                    message: data['message'] as String? ?? 'Generating next workout...',
                    detail: data['detail'] as String?,
                    elapsedMs: elapsedMs,
                    workouts: List.unmodifiable(generatedWorkouts),
                  );
                } else if (eventType == 'workout') {
                  // A workout was generated
                  final workoutData = data['workout'] as Map<String, dynamic>?;
                  if (workoutData != null) {
                    final workout = Workout.fromJson(workoutData);
                    generatedWorkouts.add(workout);
                    yield ProgramGenerationProgress(
                      currentWorkout: data['current'] as int? ?? generatedWorkouts.length,
                      totalWorkouts: data['total'] as int? ?? 0,
                      message: 'Workout generated!',
                      detail: workout.name,
                      elapsedMs: elapsedMs,
                      workout: workout,
                      workouts: List.unmodifiable(generatedWorkouts),
                    );
                  }
                } else if (eventType == 'done') {
                  // All workouts generated
                  yield ProgramGenerationProgress(
                    currentWorkout: data['total_generated'] as int? ?? generatedWorkouts.length,
                    totalWorkouts: data['total_generated'] as int? ?? generatedWorkouts.length,
                    message: 'All workouts ready!',
                    elapsedMs: elapsedMs,
                    workouts: List.unmodifiable(generatedWorkouts),
                    isCompleted: true,
                  );
                } else if (eventType == 'error') {
                  yield ProgramGenerationProgress(
                    currentWorkout: 0,
                    totalWorkouts: 0,
                    message: data['error'] as String? ?? 'Unknown error',
                    elapsedMs: elapsedMs,
                    workouts: List.unmodifiable(generatedWorkouts),
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
      debugPrint('❌ [Workout] Streaming program generation error: $e');
      yield ProgramGenerationProgress(
        currentWorkout: 0,
        totalWorkouts: 0,
        message: 'Failed to generate workouts: $e',
        elapsedMs: DateTime.now().difference(startTime).inMilliseconds,
        workouts: List.unmodifiable(generatedWorkouts),
        hasError: true,
      );
    }
  }

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
      final baseUrl = _apiClient.baseUrl;

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
      final authHeaders = await _apiClient.getAuthHeaders();
      streamingDio.options.headers.addAll(authHeaders);

      final response = await streamingDio.post(
        '${ApiConstants.workouts}/regenerate-stream',
        data: {
          'workout_id': workoutId,
          'user_id': userId,
          if (difficulty != null) 'difficulty': difficulty,
          if (durationMinutes != null) 'duration_minutes': durationMinutes,
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
                    step: data['step'] as int? ?? 0,
                    totalSteps: data['total_steps'] as int? ?? 4,
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
                    totalTimeMs: data['total_time_ms'] as int?,
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
    List<String>? focusAreas,
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
      final baseUrl = _apiClient.baseUrl;

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
      final authHeaders = await _apiClient.getAuthHeaders();
      streamingDio.options.headers.addAll(authHeaders);

      final response = await streamingDio.post(
        '${ApiConstants.workouts}/generate-stream',
        data: {
          'user_id': userId,
          if (fitnessLevel != null) 'fitness_level': fitnessLevel,
          if (goals != null && goals.isNotEmpty) 'goals': goals,
          if (equipment != null && equipment.isNotEmpty) 'equipment': equipment,
          'duration_minutes': durationMinutes,
          if (focusAreas != null && focusAreas.isNotEmpty) 'focus_areas': focusAreas,
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
                    totalTimeMs: data['total_time_ms'] as int?,
                    chunkCount: data['chunk_count'] as int?,
                  );
                } else if (eventType == 'error') {
                  yield WorkoutGenerationProgress(
                    status: WorkoutGenerationStatus.error,
                    message: data['error'] as String? ?? 'Unknown error',
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
      yield WorkoutGenerationProgress(
        status: WorkoutGenerationStatus.error,
        message: 'Failed to generate workout: $e',
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
      final baseUrl = _apiClient.baseUrl;

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
      final authHeaders = await _apiClient.getAuthHeaders();
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
                    step: data['step'] as int? ?? 0,
                    totalSteps: data['total_steps'] as int? ?? 4,
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
                    totalTimeMs: data['total_time_ms'] as int?,
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
    int? dumbbellCount,
    int? kettlebellCount,
    String? customProgramDescription,
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
      debugPrint('  - dumbbellCount: $dumbbellCount');
      debugPrint('  - kettlebellCount: $kettlebellCount');
      debugPrint('  - customProgramDescription: $customProgramDescription');

      final response = await _apiClient.post(
        '${ApiConstants.workouts}/update-program',
        data: {
          'user_id': userId,
          if (difficulty != null) 'difficulty': difficulty,
          if (durationMinutes != null) 'duration_minutes': durationMinutes,
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

      final userId = await _apiClient.getUserId();
      if (userId == null) {
        return {
          'success': false,
          'message': 'User not logged in',
        };
      }

      final response = await _apiClient.post(
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

      final response = await _apiClient.patch(
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

      final response = await _apiClient.post(
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
      final response = await _apiClient.get(
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

      final response = await _apiClient.post(
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
        final workouts = workoutsData
            .map((json) => Workout.fromJson(json as Map<String, dynamic>))
            .toList();
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

      final response = await _apiClient.post(
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

      final response = await _apiClient.post(
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
  /// [thresholdDays] - Generate more workouts if user has less than this many days of workouts (default: 7)
  Future<Map<String, dynamic>> checkAndRegenerateWorkouts(String userId, {int thresholdDays = 7}) async {
    try {
      debugPrint('🔍 [Workout] Checking workout status for user: $userId (threshold: $thresholdDays days)');
      final response = await _apiClient.post(
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
      final response = await _apiClient.post(
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
      final response = await _apiClient.post(
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
      final response = await _apiClient.post(
        '${ApiConstants.workouts}/$workoutId/warmup-and-stretches',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
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

  /// Swap an exercise in a workout
  Future<Workout?> swapExercise({
    required String workoutId,
    required String oldExerciseName,
    required String newExerciseName,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.workouts}/swap-exercise',
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

  /// Add a new exercise to a workout
  Future<Workout?> addExercise({
    required String workoutId,
    required String exerciseName,
    int sets = 3,
    String reps = '8-12',
    int restSeconds = 60,
  }) async {
    try {
      debugPrint('🔍 [Workout] Adding exercise "$exerciseName" to workout $workoutId');
      final response = await _apiClient.post(
        '${ApiConstants.workouts}/add-exercise',
        data: {
          'workout_id': workoutId,
          'exercise_name': exerciseName,
          'sets': sets,
          'reps': reps,
          'rest_seconds': restSeconds,
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
      final response = await _apiClient.post(
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
      final response = await _apiClient.post(
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

  /// Get workout generation parameters and AI reasoning
  /// Returns the user profile, program preferences, and reasoning for exercise selection
  Future<WorkoutGenerationParams?> getWorkoutGenerationParams(String workoutId) async {
    try {
      debugPrint('🔍 [Workout] Fetching generation params for workout: $workoutId');
      final response = await _apiClient.get(
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
    String setType = 'working', // 'working', 'warmup', 'failure', 'amrap'
    double? rpe,
    int? rir,
  }) async {
    try {
      debugPrint('🔍 [Workout] Logging set $setNumber ($setType) for $exerciseName');
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
          'set_type': setType,
          if (rpe != null) 'rpe': rpe,
          if (rir != null) 'rir': rir,
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

  /// Get the last performance data for a specific exercise
  /// Returns sets from the most recent workout that included this exercise
  Future<Map<String, dynamic>?> getExerciseLastPerformance({
    required String userId,
    required String exerciseName,
  }) async {
    try {
      debugPrint('🔍 [Workout] Fetching last performance for: $exerciseName');
      final response = await _apiClient.get(
        '/performance/exercise-last-performance/${Uri.encodeComponent(exerciseName)}',
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode == 200) {
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

      final response = await _apiClient.get(
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
      // 1RM = weight × (36 / (37 - reps))
      final estimated1rm = _calculate1rm(weightKg, reps);
      debugPrint('  - estimated 1RM: ${estimated1rm.toStringAsFixed(1)}kg');

      final response = await _apiClient.post(
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

  /// Calculate estimated 1RM using Brzycki formula
  /// 1RM = weight × (36 / (37 - reps))
  double _calculate1rm(double weight, int reps) {
    if (reps == 1) return weight;
    if (reps >= 37) return weight; // Formula breaks down at high reps
    return weight * (36 / (37 - reps));
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
      final response = await _apiClient.get(
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
      final response = await _apiClient.get(
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

  // ==================== Program History Methods ====================

  /// Get program history for a user
  Future<List<ProgramHistory>> getProgramHistory(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      debugPrint('🔍 [Workout] Fetching program history for user $userId');

      final response = await _apiClient.get(
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

      final response = await _apiClient.post(
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

      final response = await _apiClient.delete(
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
      final userId = await _apiClient.getUserId();
      if (userId == null) {
        debugPrint('❌ [Workout] User not logged in');
        return null;
      }

      final response = await _apiClient.post(
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
      final userId = await _apiClient.getUserId();
      if (userId == null) {
        debugPrint('❌ [Workout] User not logged in');
        return null;
      }

      final response = await _apiClient.post(
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
      final response = await _apiClient.get(
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
      final response = await _apiClient.post(
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
          'adjusted_at': DateTime.now().toIso8601String(),
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
      final response = await _apiClient.patch(
        '/performance/sets/$workoutLogId/$exerciseId/$setNumber',
        data: {
          'user_id': userId,
          'exercise_name': exerciseName,
          'new_reps': newReps,
          'new_weight_kg': newWeightKg,
          'original_reps': originalReps,
          'original_weight_kg': originalWeightKg,
          'edited_at': DateTime.now().toIso8601String(),
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
      final response = await _apiClient.delete(
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
  ///
  /// Parameters:
  /// - [exerciseName]: Name of the exercise being modified
  /// - [originalSets]: The originally prescribed number of sets
  /// - [actualSets]: The actual number of sets after adjustment
  /// - [reason]: The reason for adjustment (fatigue, time, pain, equipment, other)
  /// - [notes]: Optional additional notes from the user
  /// - [workoutId]: Optional workout ID if available
  /// - [exerciseIndex]: Optional index of exercise in the workout
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
      final userId = await _apiClient.getUserId();
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

      final response = await _apiClient.post(
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
          'recorded_at': DateTime.now().toIso8601String(),
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
      // This data is for analytics, not essential for workout completion
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
      final response = await _apiClient.get(
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
  /// Returns exercises with 2+ consecutive "too easy" ratings that have
  /// available progression variants
  Future<List<ProgressionSuggestion>> getProgressionSuggestions({
    required String userId,
  }) async {
    try {
      debugPrint('🎯 [Workout] Fetching progression suggestions for user: $userId');
      final response = await _apiClient.get(
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
  /// When accepted, the user is agreeing to progress to a harder exercise variant
  /// When declined, a cooldown is applied to avoid spamming
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

      final response = await _apiClient.post(
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
}

/// Result of body part exclusion operation
/// Contains details about which exercises were removed from the workout
class BodyPartExclusionResult {
  final String workoutId;
  final List<String> excludedBodyParts;
  final List<String> removedExercises;
  final int remainingExercises;
  final bool success;
  final String message;

  BodyPartExclusionResult({
    required this.workoutId,
    required this.excludedBodyParts,
    required this.removedExercises,
    required this.remainingExercises,
    this.success = true,
    required this.message,
  });

  factory BodyPartExclusionResult.fromJson(Map<String, dynamic> json) {
    return BodyPartExclusionResult(
      workoutId: json['workout_id'] as String? ?? '',
      excludedBodyParts: List<String>.from(json['excluded_body_parts'] as List? ?? []),
      removedExercises: List<String>.from(json['removed_exercises'] as List? ?? []),
      remainingExercises: json['remaining_exercises'] as int? ?? 0,
      success: json['success'] as bool? ?? true,
      message: json['message'] as String? ?? 'Exercises removed successfully',
    );
  }

  /// Whether any exercises were actually removed
  bool get hasRemovedExercises => removedExercises.isNotEmpty;
}

/// Result of exercise replacement operation
/// Contains details about the original and replacement exercise
class ExerciseReplaceResult {
  final bool replaced;
  final bool skipped;
  final String original;
  final String? replacement;
  final String reason;
  final String message;

  ExerciseReplaceResult({
    required this.replaced,
    this.skipped = false,
    required this.original,
    this.replacement,
    required this.reason,
    required this.message,
  });

  factory ExerciseReplaceResult.fromJson(Map<String, dynamic> json) {
    return ExerciseReplaceResult(
      replaced: json['replaced'] as bool? ?? false,
      skipped: json['skipped'] as bool? ?? false,
      original: json['original'] as String? ?? '',
      replacement: json['replacement'] as String?,
      reason: json['reason'] as String? ?? '',
      message: json['message'] as String? ?? '',
    );
  }
}

/// Progression suggestion model
/// Represents an exercise where the user is ready to progress to a harder variant
class ProgressionSuggestion {
  /// Current exercise name that user has mastered
  final String exerciseName;

  /// Suggested harder variant to progress to
  final String suggestedNextVariant;

  /// Number of consecutive sessions rated as "too easy"
  final int consecutiveEasySessions;

  /// Relative difficulty increase (e.g., 0.2 = 20% harder)
  final double? difficultyIncrease;

  /// ID of the progression chain this exercise belongs to
  final String? chainId;

  ProgressionSuggestion({
    required this.exerciseName,
    required this.suggestedNextVariant,
    required this.consecutiveEasySessions,
    this.difficultyIncrease,
    this.chainId,
  });

  factory ProgressionSuggestion.fromJson(Map<String, dynamic> json) {
    return ProgressionSuggestion(
      exerciseName: json['exercise_name'] as String? ?? '',
      suggestedNextVariant: json['suggested_next_variant'] as String? ?? '',
      consecutiveEasySessions: json['consecutive_easy_sessions'] as int? ?? 0,
      difficultyIncrease: (json['difficulty_increase'] as num?)?.toDouble(),
      chainId: json['chain_id'] as String?,
    );
  }

  /// Human-readable difficulty increase description
  String get difficultyIncreaseDescription {
    if (difficultyIncrease == null) return '';
    final percent = (difficultyIncrease! * 100).toStringAsFixed(0);
    return '+$percent% difficulty';
  }
}

/// Exercise history item model
class ExerciseHistoryItem {
  final String exerciseName;
  final int totalSets;
  final double? totalVolume;
  final double? maxWeight;
  final int? maxReps;
  final double? estimated1rm;
  final double? avgRpe;
  final String? lastWorkoutDate;
  final ExerciseProgressionTrend? progression;
  final bool hasData;

  ExerciseHistoryItem({
    required this.exerciseName,
    required this.totalSets,
    this.totalVolume,
    this.maxWeight,
    this.maxReps,
    this.estimated1rm,
    this.avgRpe,
    this.lastWorkoutDate,
    this.progression,
    this.hasData = true,
  });

  factory ExerciseHistoryItem.fromJson(Map<String, dynamic> json) {
    return ExerciseHistoryItem(
      exerciseName: json['exercise_name'] as String? ?? 'Unknown',
      totalSets: json['total_sets'] as int? ?? 0,
      totalVolume: (json['total_volume'] as num?)?.toDouble(),
      maxWeight: (json['max_weight'] as num?)?.toDouble(),
      maxReps: json['max_reps'] as int?,
      estimated1rm: (json['estimated_1rm'] as num?)?.toDouble(),
      avgRpe: (json['avg_rpe'] as num?)?.toDouble(),
      lastWorkoutDate: json['last_workout_date'] as String?,
      progression: json['progression'] != null
          ? ExerciseProgressionTrend.fromJson(json['progression'] as Map<String, dynamic>)
          : null,
      hasData: json['has_data'] as bool? ?? true,
    );
  }
}

/// Exercise stats model (detailed)
class ExerciseStats {
  final String? exerciseName;
  final int totalSets;
  final double? totalVolume;
  final double? maxWeight;
  final int? maxReps;
  final double? estimated1rm;
  final double? avgRpe;
  final String? lastWorkoutDate;
  final ExerciseProgressionTrend? progression;
  final bool hasData;
  final String? message;

  ExerciseStats({
    this.exerciseName,
    required this.totalSets,
    this.totalVolume,
    this.maxWeight,
    this.maxReps,
    this.estimated1rm,
    this.avgRpe,
    this.lastWorkoutDate,
    this.progression,
    this.hasData = false,
    this.message,
  });

  factory ExerciseStats.fromJson(Map<String, dynamic> json) {
    return ExerciseStats(
      exerciseName: json['exercise_name'] as String?,
      totalSets: json['total_sets'] as int? ?? 0,
      totalVolume: (json['total_volume'] as num?)?.toDouble(),
      maxWeight: (json['max_weight'] as num?)?.toDouble(),
      maxReps: json['max_reps'] as int?,
      estimated1rm: (json['estimated_1rm'] as num?)?.toDouble(),
      avgRpe: (json['avg_rpe'] as num?)?.toDouble(),
      lastWorkoutDate: json['last_workout_date'] as String?,
      progression: json['progression'] != null
          ? ExerciseProgressionTrend.fromJson(json['progression'] as Map<String, dynamic>)
          : null,
      hasData: json['has_data'] as bool? ?? false,
      message: json['message'] as String?,
    );
  }
}

/// Progression trend model
class ExerciseProgressionTrend {
  final String trend; // "increasing", "stable", "decreasing", "insufficient_data", "unknown"
  final double? changePercent;
  final String message;

  ExerciseProgressionTrend({
    required this.trend,
    this.changePercent,
    required this.message,
  });

  factory ExerciseProgressionTrend.fromJson(Map<String, dynamic> json) {
    return ExerciseProgressionTrend(
      trend: json['trend'] as String? ?? 'unknown',
      changePercent: (json['change_percent'] as num?)?.toDouble(),
      message: json['message'] as String? ?? '',
    );
  }

  bool get isIncreasing => trend == 'increasing';
  bool get isDecreasing => trend == 'decreasing';
  bool get isStable => trend == 'stable';
}

/// Workouts state notifier
class WorkoutsNotifier extends StateNotifier<AsyncValue<List<Workout>>> {
  final WorkoutRepository _repository;
  final ApiClient _apiClient;
  final String? _userId;

  WorkoutsNotifier(this._repository, this._apiClient, this._userId)
      : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    // Use userId from authStateProvider (passed from provider)
    if (_userId != null && _userId.isNotEmpty) {
      debugPrint('🏋️ [Workouts] _init() with userId from authState: $_userId');
      await fetchWorkouts(_userId);
    } else {
      // Fallback to apiClient.getUserId() for backwards compatibility
      final userId = await _apiClient.getUserId();
      if (!mounted) return; // Check mounted after async
      if (userId != null && userId.isNotEmpty) {
        debugPrint('🏋️ [Workouts] _init() with userId from apiClient: $userId');
        await fetchWorkouts(userId);
      } else {
        debugPrint('🏋️ [Workouts] _init() - no userId available');
        state = const AsyncValue.data([]);
      }
    }
  }

  /// Fetch workouts for user
  Future<void> fetchWorkouts(String userId) async {
    if (!mounted) return;
    state = const AsyncValue.loading();
    try {
      final workouts = await _repository.getWorkouts(userId);
      if (!mounted) return; // Check mounted after async
      // Sort by scheduled date
      workouts.sort((a, b) {
        final dateA = a.scheduledDate ?? '';
        final dateB = b.scheduledDate ?? '';
        return dateA.compareTo(dateB);
      });
      state = AsyncValue.data(workouts);
    } catch (e, st) {
      if (!mounted) return; // Check mounted after async
      state = AsyncValue.error(e, st);
    }
  }

  /// Refresh workouts
  Future<void> refresh() async {
    if (!mounted) return;
    debugPrint('🏋️ [Workouts] refresh() called');
    // Use userId from authStateProvider (passed from provider) first
    String? userId = _userId;
    if (userId == null || userId.isEmpty) {
      // Fallback to apiClient.getUserId() for backwards compatibility
      userId = await _apiClient.getUserId();
    }
    if (!mounted) return; // Check mounted after async
    if (userId != null && userId.isNotEmpty) {
      debugPrint('🏋️ [Workouts] Fetching workouts for user: $userId');
      await fetchWorkouts(userId);
      if (!mounted) return; // Check mounted after async
      final currentWorkouts = state.valueOrNull ?? [];
      debugPrint('🏋️ [Workouts] After refresh: ${currentWorkouts.length} workouts');
      final nextWorkoutName = nextWorkout?.name;
      debugPrint('🏋️ [Workouts] Next workout: $nextWorkoutName');
    } else {
      debugPrint('🏋️ [Workouts] refresh() - no userId available');
    }
  }

  /// Check if user needs more workouts and trigger generation if needed
  /// This should be called on home screen load to ensure continuous workout availability
  /// Uses a 10-day threshold - will generate if user has less than 10 days of workouts
  Future<Map<String, dynamic>> checkAndRegenerateIfNeeded() async {
    // Use userId from authStateProvider (passed from provider) first
    String? userId = _userId;
    if (userId == null || userId.isEmpty) {
      // Fallback to apiClient.getUserId() for backwards compatibility
      userId = await _apiClient.getUserId();
    }
    if (userId == null || userId.isEmpty) {
      return {'success': false, 'message': 'No user ID'};
    }

    // Use 10-day threshold so we proactively generate more workouts
    // This ensures users who onboard with 1 week get more workouts generated
    final result = await _repository.checkAndRegenerateWorkouts(userId, thresholdDays: 10);

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

  /// Get current workout streak (consecutive days with completed workouts)
  int get currentStreak {
    final workouts = state.valueOrNull ?? [];
    if (workouts.isEmpty) return 0;

    // Get completed workouts sorted by date (most recent first)
    final completedWorkouts = workouts
        .where((w) => w.isCompleted == true && w.scheduledDate != null)
        .toList();

    if (completedWorkouts.isEmpty) return 0;

    // Sort by date descending
    completedWorkouts.sort((a, b) {
      final dateA = DateTime.tryParse(a.scheduledDate!) ?? DateTime(1970);
      final dateB = DateTime.tryParse(b.scheduledDate!) ?? DateTime(1970);
      return dateB.compareTo(dateA);
    });

    // Get unique dates of completed workouts
    final completedDates = <DateTime>{};
    for (final workout in completedWorkouts) {
      final date = DateTime.tryParse(workout.scheduledDate!);
      if (date != null) {
        completedDates.add(DateTime(date.year, date.month, date.day));
      }
    }

    final sortedDates = completedDates.toList()..sort((a, b) => b.compareTo(a));
    if (sortedDates.isEmpty) return 0;

    // Check if streak includes today or yesterday
    final today = DateTime.now();
    final todayNormalized = DateTime(today.year, today.month, today.day);
    final yesterdayNormalized = todayNormalized.subtract(const Duration(days: 1));

    // Streak must start from today or yesterday to be active
    if (sortedDates.first != todayNormalized && sortedDates.first != yesterdayNormalized) {
      return 0;
    }

    // Count consecutive days
    int streak = 1;
    for (int i = 1; i < sortedDates.length; i++) {
      final diff = sortedDates[i - 1].difference(sortedDates[i]).inDays;
      if (diff == 1) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }
}

/// Program preferences model for customization
class ProgramPreferences {
  final String? difficulty;
  final int? durationMinutes;
  final String? workoutType;
  final String? trainingSplit; // Training program ID (full_body, ppl, etc.)
  final List<String> workoutDays;
  final List<String> equipment;
  final List<String> focusAreas;
  final List<String> injuries;
  final String? lastUpdated;
  final int? dumbbellCount;
  final int? kettlebellCount;

  ProgramPreferences({
    this.difficulty,
    this.durationMinutes,
    this.workoutType,
    this.trainingSplit,
    this.workoutDays = const [],
    this.equipment = const [],
    this.focusAreas = const [],
    this.injuries = const [],
    this.lastUpdated,
    this.dumbbellCount,
    this.kettlebellCount,
  });

  factory ProgramPreferences.fromJson(Map<String, dynamic> json) {
    return ProgramPreferences(
      difficulty: json['difficulty'] as String?,
      durationMinutes: json['duration_minutes'] as int?,
      workoutType: json['workout_type'] as String?,
      trainingSplit: json['training_split'] as String?,
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
      dumbbellCount: json['dumbbell_count'] as int?,
      kettlebellCount: json['kettlebell_count'] as int?,
    );
  }
}

/// Status of streaming workout generation
enum WorkoutGenerationStatus {
  /// Generation has started, waiting for AI response
  started,

  /// Generation is in progress, receiving chunks
  progress,

  /// Generation completed successfully
  completed,

  /// An error occurred during generation
  error,
}

/// Progress event for streaming workout generation
class WorkoutGenerationProgress {
  /// Current status of the generation
  final WorkoutGenerationStatus status;

  /// Human-readable status message
  final String message;

  /// Time elapsed since start in milliseconds
  final int elapsedMs;

  /// The generated workout (only available when status is completed)
  final Workout? workout;

  /// Total time for generation (server-side, only available when status is completed)
  final int? totalTimeMs;

  /// Number of chunks received (only available when status is completed)
  final int? chunkCount;

  WorkoutGenerationProgress({
    required this.status,
    required this.message,
    required this.elapsedMs,
    this.workout,
    this.totalTimeMs,
    this.chunkCount,
  });

  /// Whether the generation is still in progress
  bool get isLoading =>
      status == WorkoutGenerationStatus.started ||
      status == WorkoutGenerationStatus.progress;

  /// Whether the generation completed successfully
  bool get isCompleted => status == WorkoutGenerationStatus.completed;

  /// Whether an error occurred
  bool get hasError => status == WorkoutGenerationStatus.error;

  @override
  String toString() => 'WorkoutGenerationProgress(status: $status, message: $message, elapsedMs: $elapsedMs)';
}

/// Progress event for streaming program generation (multiple workouts)
class ProgramGenerationProgress {
  /// Current workout number being generated
  final int currentWorkout;

  /// Total number of workouts to generate
  final int totalWorkouts;

  /// Human-readable status message
  final String message;

  /// Additional detail about the current step
  final String? detail;

  /// Time elapsed since start in milliseconds
  final int elapsedMs;

  /// A workout that was just generated (streamed one at a time)
  final Workout? workout;

  /// All workouts generated so far
  final List<Workout> workouts;

  /// Whether generation completed successfully
  final bool isCompleted;

  /// Whether an error occurred
  final bool hasError;

  ProgramGenerationProgress({
    required this.currentWorkout,
    required this.totalWorkouts,
    required this.message,
    this.detail,
    required this.elapsedMs,
    this.workout,
    this.workouts = const [],
    this.isCompleted = false,
    this.hasError = false,
  });

  /// Progress as a percentage (0.0 to 1.0)
  double get progress => totalWorkouts > 0 ? currentWorkout / totalWorkouts : 0;

  /// Whether generation is still in progress
  bool get isLoading => !isCompleted && !hasError;

  @override
  String toString() => 'ProgramGenerationProgress(workout: $currentWorkout/$totalWorkouts, message: $message, elapsedMs: $elapsedMs)';
}

/// Progress event for streaming workout regeneration
class RegenerateProgress {
  /// Current step number (1-indexed)
  final int step;

  /// Total number of steps
  final int totalSteps;

  /// Human-readable status message
  final String message;

  /// Additional detail about the current step
  final String? detail;

  /// Time elapsed since start in milliseconds
  final int elapsedMs;

  /// The regenerated workout (only available when completed)
  final Workout? workout;

  /// Total time for regeneration (server-side, only available when completed)
  final int? totalTimeMs;

  /// Whether regeneration completed successfully
  final bool isCompleted;

  /// Whether an error occurred
  final bool hasError;

  RegenerateProgress({
    required this.step,
    required this.totalSteps,
    required this.message,
    this.detail,
    required this.elapsedMs,
    this.workout,
    this.totalTimeMs,
    this.isCompleted = false,
    this.hasError = false,
  });

  /// Progress as a percentage (0.0 to 1.0)
  double get progress => totalSteps > 0 ? step / totalSteps : 0;

  /// Whether regeneration is still in progress
  bool get isLoading => !isCompleted && !hasError;

  @override
  String toString() => 'RegenerateProgress(step: $step/$totalSteps, message: $message, elapsedMs: $elapsedMs)';
}

/// Progress event for mood-based workout generation
class MoodWorkoutProgress {
  /// Current step number (1-indexed)
  final int step;

  /// Total number of steps
  final int totalSteps;

  /// Human-readable status message
  final String message;

  /// Additional detail about the current step
  final String? detail;

  /// Time elapsed since start in milliseconds
  final int elapsedMs;

  /// The generated workout (only available when completed)
  final Workout? workout;

  /// Mood that was used for generation
  final Mood? mood;

  /// Mood emoji for UI display
  final String? moodEmoji;

  /// Mood color hex for UI display
  final String? moodColor;

  /// Total time for generation (server-side, only available when completed)
  final int? totalTimeMs;

  /// Whether generation completed successfully
  final bool isCompleted;

  /// Whether an error occurred
  final bool hasError;

  MoodWorkoutProgress({
    required this.step,
    required this.totalSteps,
    required this.message,
    this.detail,
    required this.elapsedMs,
    this.workout,
    this.mood,
    this.moodEmoji,
    this.moodColor,
    this.totalTimeMs,
    this.isCompleted = false,
    this.hasError = false,
  });

  /// Progress as a percentage (0.0 to 1.0)
  double get progress => totalSteps > 0 ? step / totalSteps : 0;

  /// Whether generation is still in progress
  bool get isLoading => !isCompleted && !hasError;

  @override
  String toString() => 'MoodWorkoutProgress(step: $step/$totalSteps, message: $message, mood: ${mood?.value}, elapsedMs: $elapsedMs)';
}
