import 'dart:async';
import 'dart:convert' show jsonEncode;
import 'dart:io' show Platform;
import 'dart:math' show min, pow;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/providers/wearable_provider.dart';
import '../repositories/workout_repository.dart';
import '../services/wearable_service.dart';

/// Tracks poll count for exponential backoff
/// Prevents excessive API calls when generation is failing
int _generationPollCount = 0;

/// Maximum number of polls before giving up
/// ~2 minutes with exponential backoff: 2s, 4s, 8s, 16s, 30s, 30s...
const int _maxGenerationPolls = 30;

/// Calculate backoff seconds with exponential growth, capped at 30s
int _getBackoffSeconds() {
  // 2s, 4s, 8s, 16s, 30s (capped)
  return min(30, 2 * pow(2, min(_generationPollCount, 4)).toInt());
}

/// Provider for today's workout data
///
/// Fetches the current day's workout summary from the API endpoint.
/// Returns null if no workout is scheduled or user is not authenticated.
///
/// Features:
/// - Caches result for the current session (removed autoDispose for faster navigation)
/// - Auto-refreshes on provider invalidation
/// - Auto-polls when is_generating is true (JIT generation in progress)
/// - Exponential backoff to prevent excessive API calls (2s -> 4s -> 8s -> 16s -> 30s cap)
/// - Stops polling after 30 attempts (~2 minutes) to prevent infinite loops
/// - Auto-syncs to WearOS watch when workout is available (Android only)
final todayWorkoutProvider =
    FutureProvider<TodayWorkoutResponse?>((ref) async {
  final repository = ref.watch(workoutRepositoryProvider);
  final response = await repository.getTodayWorkout();

  // If generation is in progress, schedule a refresh with exponential backoff
  // This enables automatic polling until the workout is ready
  if (response?.isGenerating == true) {
    if (_generationPollCount < _maxGenerationPolls) {
      _generationPollCount++;
      final backoffSeconds = _getBackoffSeconds();
      debugPrint('🔄 [Generation] Poll #$_generationPollCount, next in ${backoffSeconds}s');

      // Use a timer to auto-refresh with backoff (non-blocking)
      Timer(Duration(seconds: backoffSeconds), () {
        // Only invalidate if the provider is still active
        try {
          ref.invalidateSelf();
        } catch (_) {
          // Provider may have been disposed
        }
      });
    } else {
      // Stop polling after max attempts - something is wrong
      debugPrint('❌ [Generation] Max polls ($_maxGenerationPolls) reached. Stopping auto-refresh.');
      // Reset counter for next session
      _generationPollCount = 0;
    }
  } else {
    // Reset poll count when generation completes or is not in progress
    if (_generationPollCount > 0) {
      debugPrint('✅ [Generation] Complete after $_generationPollCount polls');
    }
    _generationPollCount = 0;
  }

  // AUTO-GENERATION: If backend signals we need to generate a workout, trigger it
  // This ensures the hero card ALWAYS shows a workout (never empty/rest day)
  if (response?.needsGeneration == true && response?.nextWorkoutDate != null) {
    debugPrint('🚀 [Auto-Gen] Backend signaled needs_generation=true, date=${response!.nextWorkoutDate}');

    // Trigger generation in the background
    _triggerAutoGeneration(ref, response.nextWorkoutDate!);

    // Return response with isGenerating=true so UI shows loading state
    return TodayWorkoutResponse(
      hasWorkoutToday: response.hasWorkoutToday,
      todayWorkout: response.todayWorkout,
      nextWorkout: response.nextWorkout,
      daysUntilNext: response.daysUntilNext,
      restDayMessage: response.restDayMessage,
      completedToday: response.completedToday,
      completedWorkout: response.completedWorkout,
      isGenerating: true,  // Show loading state
      generationMessage: 'Generating your workout...',
      needsGeneration: false,  // Prevent re-triggering
      nextWorkoutDate: response.nextWorkoutDate,
    );
  }

  // If no workouts available (post-onboarding), schedule a refresh after 3 seconds
  // This ensures the UI auto-updates when workouts become available
  if (response?.todayWorkout == null &&
      response?.nextWorkout == null &&
      response?.completedToday != true &&
      response?.isGenerating != true &&
      response?.needsGeneration != true) {
    Timer(const Duration(seconds: 3), () {
      try {
        ref.invalidateSelf();
      } catch (_) {
        // Provider may have been disposed
      }
    });
  }

  // Sync today's workout to WearOS watch (Android only, non-blocking)
  if (Platform.isAndroid && response?.todayWorkout != null && !response!.isGenerating) {
    _syncWorkoutToWatch(response.todayWorkout!, ref);
  }

  return response;
});

/// Flag to prevent multiple simultaneous auto-generations
bool _isAutoGenerating = false;

/// Triggers auto-generation of a workout for the specified date
/// This is called when the backend signals needs_generation=true
void _triggerAutoGeneration(FutureProviderRef ref, String scheduledDate) {
  // Prevent multiple simultaneous generations
  if (_isAutoGenerating) {
    debugPrint('⏳ [Auto-Gen] Already generating, skipping duplicate request');
    return;
  }

  _isAutoGenerating = true;
  debugPrint('🔄 [Auto-Gen] Starting generation for date: $scheduledDate');

  // Fire and forget - don't block the provider
  Future(() async {
    try {
      final repository = ref.read(workoutRepositoryProvider);

      // Get user ID from repository
      final userId = await repository.getCurrentUserId();
      if (userId == null) {
        debugPrint('❌ [Auto-Gen] No user ID available');
        return;
      }

      // Listen to the streaming generation
      await for (final progress in repository.generateWorkoutStreaming(
        userId: userId,
        scheduledDate: scheduledDate,
      )) {
        debugPrint('🔄 [Auto-Gen] Progress: ${progress.status} - ${progress.message}');

        if (progress.status == WorkoutGenerationStatus.completed) {
          debugPrint('✅ [Auto-Gen] Workout generated successfully!');
          // Refresh the today workout provider to show the new workout
          try {
            ref.invalidateSelf();
          } catch (_) {
            // Provider may have been disposed
          }
          break;
        }

        if (progress.status == WorkoutGenerationStatus.error) {
          debugPrint('❌ [Auto-Gen] Generation failed: ${progress.message}');
          break;
        }
      }
    } catch (e) {
      debugPrint('❌ [Auto-Gen] Error: $e');
    } finally {
      _isAutoGenerating = false;
    }
  });
}

/// Syncs the workout to watch in the background (non-blocking)
void _syncWorkoutToWatch(TodayWorkoutSummary workout, FutureProviderRef ref) {
  // Fire and forget - don't block the provider
  Future(() async {
    try {
      // Cache workout to SharedPreferences for Kotlin service to read
      // when watch reconnects
      await _cacheWorkoutForWatch(workout);

      final wearableSync = ref.read(wearableSyncProvider);

      // Check if watch is connected
      await wearableSync.refreshConnection();
      if (!wearableSync.isConnected) {
        debugPrint('⌚ [Watch] Not connected, workout cached for later');
        return;
      }

      // Format workout for watch
      final watchWorkout = WearableService.instance.createWorkoutForWatch(
        id: workout.id,
        name: workout.name,
        type: workout.type,
        exercises: workout.exercises.map((e) => {
          'id': e.id,
          'name': e.name,
          'targetSets': e.sets,
          'targetReps': e.reps.toString(),
          'targetWeightKg': e.weight,
          'restSeconds': e.restSeconds ?? 60,
          'videoUrl': e.videoUrl,
          'thumbnailUrl': e.gifUrl ?? e.imageS3Path,
        }).toList(),
        estimatedDuration: workout.durationMinutes,
        targetMuscleGroups: workout.primaryMuscles,
        scheduledDate: workout.scheduledDate,
      );

      await wearableSync.syncWorkoutToWatch(watchWorkout);
    } catch (e) {
      debugPrint('⚠️ [Watch] Error syncing workout: $e');
    }
  });
}

/// Cache workout data to SharedPreferences for Kotlin service to read
Future<void> _cacheWorkoutForWatch(TodayWorkoutSummary workout) async {
  try {
    final prefs = await SharedPreferences.getInstance();

    // Create a JSON structure that the Kotlin service can parse
    final workoutData = {
      'workout': {
        'id': workout.id,
        'name': workout.name,
        'type': workout.type,
        'estimated_duration': workout.durationMinutes,
        'target_muscles': workout.primaryMuscles,
        'exercises': workout.exercises.map((e) => {
          'id': e.id,
          'name': e.name,
          'sets': e.sets,
          'reps': e.reps,
          'weight_kg': e.weight,
          'rest_seconds': e.restSeconds ?? 60,
          'video_url': e.videoUrl,
          'thumbnail_url': e.gifUrl ?? e.imageS3Path,
        }).toList(),
      },
      'date': workout.scheduledDate,
    };

    await prefs.setString('today_workout_cache', jsonEncode(workoutData));
    debugPrint('💾 [Watch] Workout cached for watch sync');
  } catch (e) {
    debugPrint('⚠️ [Watch] Error caching workout: $e');
  }
}

/// Provider to track if the quick start was used
/// This helps with analytics and can be used to show different UI states
final quickStartUsedProvider = StateProvider<bool>((ref) => false);

/// Provider to force refresh of today's workout data
/// Call ref.invalidate(todayWorkoutRefreshProvider) to trigger a refresh
final todayWorkoutRefreshProvider = Provider<void>((ref) {
  // Watching this will trigger refresh
  ref.watch(todayWorkoutProvider);
});
