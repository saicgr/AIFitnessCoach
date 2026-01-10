import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/workout_repository.dart';

/// Provider for today's workout data
///
/// Fetches the current day's workout summary from the API endpoint.
/// Returns null if no workout is scheduled or user is not authenticated.
///
/// Features:
/// - Caches result for the current session (removed autoDispose for faster navigation)
/// - Auto-refreshes on provider invalidation
/// - Auto-polls when is_generating is true (JIT generation in progress)
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

  return response;
});

/// Provider to track if the quick start was used
/// This helps with analytics and can be used to show different UI states
final quickStartUsedProvider = StateProvider<bool>((ref) => false);

/// Provider to force refresh of today's workout data
/// Call ref.invalidate(todayWorkoutRefreshProvider) to trigger a refresh
final todayWorkoutRefreshProvider = Provider<void>((ref) {
  // Watching this will trigger refresh
  ref.watch(todayWorkoutProvider);
});
