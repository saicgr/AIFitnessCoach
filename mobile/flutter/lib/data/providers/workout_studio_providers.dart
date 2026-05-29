import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';
import '../services/workout_studio_service.dart';
import '../services/saved_workouts_service.dart';

/// DI for the Workout Customization Studio + saved-workout library services.
/// Both are thin wrappers over the shared [apiClientProvider].

final workoutStudioServiceProvider = Provider<WorkoutStudioService>((ref) {
  return WorkoutStudioService(ref.read(apiClientProvider));
});

final savedWorkoutsServiceProvider = Provider<SavedWorkoutsService>((ref) {
  return SavedWorkoutsService(ref.read(apiClientProvider));
});
