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

/// Session-scoped snapshot of the last successfully loaded saved-workouts list,
/// keyed by user id. The Library "Workouts" tab paints this instantly while a
/// fresh fetch revalidates, instead of blocking on a full-screen spinner every
/// time the screen is reopened.
final _savedWorkoutsCache = <String, List<Map<String, dynamic>>>{};

/// The last cached saved-workouts list for [userId], or null if it has never
/// loaded this session. Lets the tab render real rows before the future
/// resolves (instant-data UX) without ever fabricating data.
List<Map<String, dynamic>>? cachedSavedWorkouts(String userId) =>
    _savedWorkoutsCache[userId];

/// Saved custom workouts for a user. Loads via [SavedWorkoutsService] and
/// caches the result for the session so re-entering the Library tab is instant
/// (cache shown immediately, network revalidates in the background).
///
/// `autoDispose` so it refetches when the tab is reopened (silent refresh on
/// top of the cached snapshot); the snapshot in [_savedWorkoutsCache] survives
/// disposal so there is never a blank spinner after the first load.
final savedWorkoutsListProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, userId) async {
  final list = await ref
      .read(savedWorkoutsServiceProvider)
      .getSavedWorkouts(userId: userId);
  _savedWorkoutsCache[userId] = list;
  return list;
});
