import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/workout_repository.dart';

/// Provider for today's workout data
///
/// Fetches the current day's workout summary from the API endpoint.
/// Returns null if no workout is scheduled or user is not authenticated.
///
/// Features:
/// - Auto-disposes when no longer in use
/// - Auto-refreshes on provider invalidation
/// - Caches result for the current session
final todayWorkoutProvider =
    FutureProvider.autoDispose<TodayWorkoutResponse?>((ref) async {
  final repository = ref.watch(workoutRepositoryProvider);
  return repository.getTodayWorkout();
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
