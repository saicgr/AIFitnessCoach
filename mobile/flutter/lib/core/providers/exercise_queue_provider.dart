import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/exercise_preferences_repository.dart';
import '../../data/services/api_client.dart';

/// State for exercise queue
class ExerciseQueueState {
  final List<QueuedExercise> queue;
  final bool isLoading;
  final String? error;

  // Computed once per state instance — avoids filter+sort on every isQueued call.
  late final List<QueuedExercise> activeQueue =
      (queue.where((q) => q.isActive).toList()
        ..sort((a, b) => a.priority.compareTo(b.priority)));

  late final Set<String> queuedNames =
      activeQueue.map((q) => q.exerciseName.toLowerCase()).toSet();

  /// Spent items whose destination workout hasn't happened yet (row 280) —
  /// shown in their own "Added to upcoming" section instead of counted
  /// among the pending queue.
  late final List<QueuedExercise> addedToUpcoming =
      (queue.where((q) => q.isAddedToUpcoming).toList()
        ..sort((a, b) => (a.usedAt ?? a.addedAt).compareTo(b.usedAt ?? b.addedAt)));

  ExerciseQueueState({
    this.queue = const [],
    this.isLoading = false,
    this.error,
  });

  ExerciseQueueState copyWith({
    List<QueuedExercise>? queue,
    bool? isLoading,
    String? error,
  }) {
    return ExerciseQueueState(
      queue: queue ?? this.queue,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Check if an exercise is in the queue (O(1) set lookup).
  bool isQueued(String exerciseName) =>
      queuedNames.contains(exerciseName.toLowerCase());
}

/// Exercise queue provider
final exerciseQueueProvider =
    StateNotifierProvider<ExerciseQueueNotifier, ExerciseQueueState>((ref) {
  return ExerciseQueueNotifier(ref);
});

/// Notifier for managing exercise queue state
class ExerciseQueueNotifier extends StateNotifier<ExerciseQueueState> {
  final Ref _ref;

  ExerciseQueueNotifier(this._ref) : super(ExerciseQueueState()) {
    _init();
  }

  /// Initialize queue from API
  Future<void> _init() async {
    await refresh();
  }

  /// Refresh queue from API
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final apiClient = _ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final repository = _ref.read(exercisePreferencesRepositoryProvider);
      final queue = await repository.getExerciseQueue(userId);

      state = state.copyWith(queue: queue, isLoading: false);
      debugPrint('📋 [QueueProvider] Loaded ${queue.length} queued exercises');
    } catch (e) {
      debugPrint('❌ [QueueProvider] Error loading queue: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Re-fetch the queue WITHOUT flipping `isLoading` — the retained
  /// app-scoped provider is deliberately cache-first so re-opening the Queue
  /// tab renders instantly (no skeleton flash). But that cache can go stale:
  /// a server-side job (the workout generator) can mark a queued exercise
  /// `used_at` and inject it into a workout at any time, and the cached copy
  /// has no way to learn that on its own — it keeps showing the entry as
  /// pending under the "will be included in your next workout" banner long
  /// after it's already landed somewhere. Call this on screen appearance to
  /// reconcile silently; the GET endpoint already excludes anything used or
  /// expired, so a stale entry simply drops out of the list once this lands.
  Future<void> silentRefresh() async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();
      if (userId == null) return;

      final repository = _ref.read(exercisePreferencesRepositoryProvider);
      final queue = await repository.getExerciseQueue(userId);
      state = state.copyWith(queue: queue);
      debugPrint('📋 [QueueProvider] Silently refreshed ${queue.length} queued exercises');
    } catch (e) {
      debugPrint('❌ [QueueProvider] Error silently refreshing queue: $e');
    }
  }

  /// Add an exercise to the queue
  Future<bool> addToQueue(
    String exerciseName, {
    String? exerciseId,
    int priority = 0,
    String? targetMuscleGroup,
  }) async {
    // Optimistic update
    final optimisticQueued = QueuedExercise(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      exerciseName: exerciseName,
      exerciseId: exerciseId,
      priority: priority,
      targetMuscleGroup: targetMuscleGroup,
      addedAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 7)),
    );
    state = state.copyWith(
      queue: [...state.queue, optimisticQueued],
    );

    try {
      final apiClient = _ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId == null) {
        // Rollback
        state = state.copyWith(
          queue: state.queue.where((q) => q.id != optimisticQueued.id).toList(),
          error: 'Not logged in',
        );
        return false;
      }

      final repository = _ref.read(exercisePreferencesRepositoryProvider);
      final queued = await repository.addToQueue(
        userId,
        exerciseName,
        exerciseId: exerciseId,
        priority: priority,
        targetMuscleGroup: targetMuscleGroup,
      );

      // Replace optimistic with real
      state = state.copyWith(
        queue: [
          ...state.queue.where((q) => q.id != optimisticQueued.id),
          queued,
        ],
      );

      debugPrint('📋 [QueueProvider] Added to queue: $exerciseName');
      return true;
    } catch (e) {
      debugPrint('❌ [QueueProvider] Error adding to queue: $e');
      // Rollback
      state = state.copyWith(
        queue: state.queue.where((q) => q.id != optimisticQueued.id).toList(),
        error: e.toString(),
      );
      return false;
    }
  }

  /// Remove an exercise from the queue.
  ///
  /// Returns null on failure, false on success (item had not been used yet),
  /// or true on success where the item had ALREADY been consumed by the
  /// workout generator — deleting the queue row does not pull it back out of
  /// that workout, so the caller must not claim it "won't be included".
  Future<bool?> removeFromQueue(String exerciseName) async {
    // Find the queued item to remove
    final queued = state.queue.firstWhere(
      (q) => q.exerciseName.toLowerCase() == exerciseName.toLowerCase() && q.isActive,
      orElse: () => throw Exception('Queue item not found'),
    );

    // Optimistic update
    state = state.copyWith(
      queue: state.queue.where((q) => q.id != queued.id).toList(),
    );

    try {
      final apiClient = _ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId == null) {
        // Rollback
        state = state.copyWith(
          queue: [...state.queue, queued],
          error: 'Not logged in',
        );
        return null;
      }

      final repository = _ref.read(exercisePreferencesRepositoryProvider);
      final alreadyUsed = await repository.removeFromQueue(userId, exerciseName);

      debugPrint('📋 [QueueProvider] Removed from queue: $exerciseName');
      return alreadyUsed;
    } catch (e) {
      debugPrint('❌ [QueueProvider] Error removing from queue: $e');
      // Rollback
      state = state.copyWith(
        queue: [...state.queue, queued],
        error: e.toString(),
      );
      return null;
    }
  }

  /// Toggle queue status for an exercise
  Future<bool> toggleQueue(
    String exerciseName, {
    String? exerciseId,
    String? targetMuscleGroup,
  }) async {
    if (state.isQueued(exerciseName)) {
      return await removeFromQueue(exerciseName) != null;
    } else {
      return await addToQueue(
        exerciseName,
        exerciseId: exerciseId,
        targetMuscleGroup: targetMuscleGroup,
      );
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}
