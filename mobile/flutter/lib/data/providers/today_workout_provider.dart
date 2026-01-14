import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' show min, pow;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  // If no workouts available (post-onboarding), schedule a refresh after 3 seconds
  // This ensures the UI auto-updates when workouts become available
  if (response?.todayWorkout == null &&
      response?.nextWorkout == null &&
      response?.completedToday != true &&
      response?.isGenerating != true) {
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

/// Syncs the workout to watch in the background (non-blocking)
void _syncWorkoutToWatch(TodayWorkoutSummary workout, FutureProviderRef ref) {
  // Fire and forget - don't block the provider
  Future(() async {
    try {
      final wearableSync = ref.read(wearableSyncProvider);

      // Check if watch is connected
      await wearableSync.refreshConnection();
      if (!wearableSync.isConnected) {
        debugPrint('⌚ [Watch] Not connected, skipping workout sync');
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

/// Provider to track if the quick start was used
/// This helps with analytics and can be used to show different UI states
final quickStartUsedProvider = StateProvider<bool>((ref) => false);

/// Provider to force refresh of today's workout data
/// Call ref.invalidate(todayWorkoutRefreshProvider) to trigger a refresh
final todayWorkoutRefreshProvider = Provider<void>((ref) {
  // Watching this will trigger refresh
  ref.watch(todayWorkoutProvider);
});
