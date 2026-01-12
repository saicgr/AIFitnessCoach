import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/wearable_provider.dart';
import '../repositories/workout_repository.dart';
import '../services/wearable_service.dart';

/// Provider for today's workout data
///
/// Fetches the current day's workout summary from the API endpoint.
/// Returns null if no workout is scheduled or user is not authenticated.
///
/// Features:
/// - Caches result for the current session (removed autoDispose for faster navigation)
/// - Auto-refreshes on provider invalidation
/// - Auto-polls when is_generating is true (JIT generation in progress)
/// - Auto-syncs to WearOS watch when workout is available (Android only)
final todayWorkoutProvider =
    FutureProvider<TodayWorkoutResponse?>((ref) async {
  final repository = ref.watch(workoutRepositoryProvider);
  final response = await repository.getTodayWorkout();

  // If generation is in progress, schedule a refresh after 2 seconds
  // This enables automatic polling until the workout is ready
  if (response?.isGenerating == true) {
    // Use a timer to auto-refresh (non-blocking)
    Timer(const Duration(seconds: 2), () {
      // Only invalidate if the provider is still active
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
          'targetWeightKg': e.suggestedWeight,
          'restSeconds': e.restSeconds ?? 60,
          'videoUrl': e.videoUrl,
          'thumbnailUrl': e.thumbnailUrl,
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
