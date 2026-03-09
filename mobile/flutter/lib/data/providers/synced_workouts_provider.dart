import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout.dart';
import '../repositories/workout_repository.dart';

/// Provider for Health Connect / Apple Health synced workouts.
/// Derives from the existing workouts provider (client-side filter).
final syncedWorkoutsProvider = Provider<List<Workout>>((ref) {
  final workoutsState = ref.watch(workoutsProvider);
  final repository = ref.watch(workoutRepositoryProvider);
  return workoutsState.maybeWhen(
    data: (workouts) => repository.getSyncedWorkouts(workouts),
    orElse: () => [],
  );
});
