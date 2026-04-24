import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/workout.dart';
import '../../data/services/live_activity_service.dart';
import '../../data/services/workout_notification_service.dart';
import '../services/posthog_service.dart';

/// State for the workout mini player
class WorkoutMiniPlayerState {
  /// Whether the workout is currently minimized
  final bool isMinimized;

  /// The active workout object (needed for restore)
  final Workout? workout;

  /// Current workout timer in seconds
  final int workoutSeconds;

  /// Current exercise name being performed
  final String? currentExerciseName;

  /// Current exercise image/GIF URL
  final String? currentExerciseImageUrl;

  /// Current exercise index (0-based)
  final int currentExerciseIndex;

  /// Total number of exercises
  final int totalExercises;

  /// Completed sets data (exercise index -> list of completed sets)
  final Map<int, List<Map<String, dynamic>>> completedSets;

  /// Whether currently in rest period
  final bool isResting;

  /// Rest seconds remaining (if resting)
  final int restSecondsRemaining;

  /// Whether workout is paused
  final bool isPaused;

  /// True while a modal route (bottom sheet / dialog / popup) is on top of
  /// the Navigator. The overlay uses this to hide the pill so it doesn't
  /// z-float above modal sheets. Timer keeps running regardless.
  final bool suppressedForModal;

  const WorkoutMiniPlayerState({
    this.isMinimized = false,
    this.workout,
    this.workoutSeconds = 0,
    this.currentExerciseName,
    this.currentExerciseImageUrl,
    this.currentExerciseIndex = 0,
    this.totalExercises = 0,
    this.completedSets = const {},
    this.isResting = false,
    this.restSecondsRemaining = 0,
    this.isPaused = false,
    this.suppressedForModal = false,
  });

  WorkoutMiniPlayerState copyWith({
    bool? isMinimized,
    Workout? workout,
    int? workoutSeconds,
    String? currentExerciseName,
    String? currentExerciseImageUrl,
    int? currentExerciseIndex,
    int? totalExercises,
    Map<int, List<Map<String, dynamic>>>? completedSets,
    bool? isResting,
    int? restSecondsRemaining,
    bool? isPaused,
    bool? suppressedForModal,
  }) {
    return WorkoutMiniPlayerState(
      isMinimized: isMinimized ?? this.isMinimized,
      workout: workout ?? this.workout,
      workoutSeconds: workoutSeconds ?? this.workoutSeconds,
      currentExerciseName: currentExerciseName ?? this.currentExerciseName,
      currentExerciseImageUrl: currentExerciseImageUrl ?? this.currentExerciseImageUrl,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      totalExercises: totalExercises ?? this.totalExercises,
      completedSets: completedSets ?? this.completedSets,
      isResting: isResting ?? this.isResting,
      restSecondsRemaining: restSecondsRemaining ?? this.restSecondsRemaining,
      isPaused: isPaused ?? this.isPaused,
      suppressedForModal: suppressedForModal ?? this.suppressedForModal,
    );
  }

  /// Clear state (used when workout is closed)
  WorkoutMiniPlayerState clear() {
    return const WorkoutMiniPlayerState();
  }

  /// Progress string for display (e.g., "3/6")
  String get progressString => '$currentExerciseIndex/$totalExercises';

  /// Formatted time string (e.g., "12:34")
  String get formattedTime {
    final minutes = workoutSeconds ~/ 60;
    final seconds = workoutSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Notifier for workout mini player state
class WorkoutMiniPlayerNotifier extends StateNotifier<WorkoutMiniPlayerState> {
  Timer? _timer;
  final PosthogService _posthogService;

  WorkoutMiniPlayerNotifier(this._posthogService) : super(const WorkoutMiniPlayerState());

  /// Minimize the workout and start background timer
  void minimize({
    required Workout workout,
    required int workoutSeconds,
    required String? currentExerciseName,
    String? currentExerciseImageUrl,
    required int currentExerciseIndex,
    required int totalExercises,
    Map<int, List<Map<String, dynamic>>>? completedSets,
    bool isResting = false,
    int restSecondsRemaining = 0,
    bool isPaused = false,
  }) {
    debugPrint('🎬 [MiniPlayer] Minimizing workout: ${workout.name}');
    debugPrint('🎬 [MiniPlayer] Timer: $workoutSeconds, Exercise: $currentExerciseIndex/$totalExercises');

    _posthogService.capture(
      eventName: 'workout_minimized',
      properties: {
        'workout_name': workout.name ?? '',
        'elapsed_seconds': workoutSeconds,
      },
    );

    state = state.copyWith(
      isMinimized: true,
      workout: workout,
      workoutSeconds: workoutSeconds,
      currentExerciseName: currentExerciseName,
      currentExerciseImageUrl: currentExerciseImageUrl,
      currentExerciseIndex: currentExerciseIndex,
      totalExercises: totalExercises,
      completedSets: completedSets ?? {},
      isResting: isResting,
      restSecondsRemaining: restSecondsRemaining,
      isPaused: isPaused,
    );

    // Wire notification actions as a remote control for the mini player.
    // Stop deliberately routes through restore() (not close()) so the workout
    // session isn't silently dropped — the user finishes the end flow in-app
    // where DB persistence happens.
    //
    // Body-tap (no action id) is wired separately in app.dart so it can both
    // restore *and* push '/active-workout' — tapping just restore() when the
    // user is on the home screen leaves them staring at home instead of
    // their ongoing workout, which reads like the workout vanished.
    WorkoutNotificationService.instance.onPauseResumePressed = togglePause;
    WorkoutNotificationService.instance.onStopPressed = restore;
    _pushNotification();

    // Start background timer if not paused
    if (!isPaused) {
      _startTimer();
    }
  }

  /// Restore the workout (called when mini player is tapped)
  void restore() {
    debugPrint('🎬 [MiniPlayer] Restoring workout');

    _posthogService.capture(
      eventName: 'workout_restored',
      properties: {
        'workout_name': state.workout?.name ?? '',
      },
    );

    _stopTimer();
    state = state.copyWith(isMinimized: false);
    // Cancel the ongoing notification — user is back in the app and
    // should use the in-screen controls. The active workout screen's
    // mixin will reshow the notification if they minimize again.
    WorkoutNotificationService.instance.cancel();
    WorkoutNotificationService.instance.clearCallbacks();
  }

  /// Close the workout completely
  void close() {
    debugPrint('🎬 [MiniPlayer] Closing workout');
    _stopTimer();
    state = state.clear();
    // Cancel the persistent workout notification + iOS Live Activity.
    WorkoutNotificationService.instance.cancel();
    WorkoutNotificationService.instance.clearCallbacks();
    unawaited(LiveActivityService.instance.end());
  }

  /// Hide the pill while a modal route (bottom sheet / dialog / popup) is
  /// on the Navigator. Called from `WorkoutMiniPlayerRouteObserver`.
  /// Does NOT affect the minimize/restore lifecycle — the timer keeps ticking.
  void setSuppressedForModal(bool suppressed) {
    if (state.suppressedForModal == suppressed) return;
    state = state.copyWith(suppressedForModal: suppressed);
  }

  /// Toggle pause state
  void togglePause() {
    final newPaused = !state.isPaused;
    state = state.copyWith(isPaused: newPaused);

    if (newPaused) {
      _stopTimer();
    } else {
      _startTimer();
    }
    _pushNotification();
  }

  /// Update current exercise info
  void updateExercise({
    required String? exerciseName,
    String? exerciseImageUrl,
    required int exerciseIndex,
  }) {
    state = state.copyWith(
      currentExerciseName: exerciseName,
      currentExerciseImageUrl: exerciseImageUrl,
      currentExerciseIndex: exerciseIndex,
    );
    _pushNotification();
  }

  /// Update completed sets
  void updateCompletedSets(Map<int, List<Map<String, dynamic>>> sets) {
    state = state.copyWith(completedSets: sets);
  }

  /// Push the current mini-player state to the ongoing Android notification.
  /// No-op on iOS / when nothing is minimized.
  void _pushNotification() {
    if (!state.isMinimized) return;
    final workout = state.workout;
    if (workout == null) return;
    try {
      WorkoutNotificationService.instance.show(
        workoutName: workout.name ?? 'Workout',
        currentExerciseName: state.currentExerciseName ?? 'Exercise',
        timerText: state.formattedTime,
        exerciseProgress:
            '${state.currentExerciseIndex + 1}/${state.totalExercises}',
        isPaused: state.isPaused,
      );
    } catch (e) {
      debugPrint('⚠️ [MiniPlayer] Notification push failed: $e');
    }
  }

  /// Start the background timer
  void _startTimer() {
    _stopTimer(); // Cancel any existing timer

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!state.isPaused && state.isMinimized) {
        state = state.copyWith(
          workoutSeconds: state.workoutSeconds + 1,
        );

        // Also decrement rest timer if resting
        if (state.isResting && state.restSecondsRemaining > 0) {
          final newRest = state.restSecondsRemaining - 1;
          state = state.copyWith(
            restSecondsRemaining: newRest,
            isResting: newRest > 0,
          );
        }

        _pushNotification();
      }
    });
  }

  /// Stop the background timer
  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    WorkoutNotificationService.instance.cancel();
    WorkoutNotificationService.instance.clearCallbacks();
    unawaited(LiveActivityService.instance.end());
    super.dispose();
  }
}

/// Provider for workout mini player state
final workoutMiniPlayerProvider =
    StateNotifierProvider<WorkoutMiniPlayerNotifier, WorkoutMiniPlayerState>(
  (ref) => WorkoutMiniPlayerNotifier(ref.read(posthogServiceProvider)),
);

/// Convenience provider to check if a workout is minimized
final isWorkoutMinimizedProvider = Provider<bool>((ref) {
  return ref.watch(workoutMiniPlayerProvider).isMinimized;
});
