// Shared mid-workout session state. Both the Easy and Advanced active-
// workout screens read on init / write on every logged set so that
// flipping the tier toggle mid-session preserves all completed sets and
// the current exercise index.
//
// The session is keyed by `workoutId` — `start(id)` only clears state
// when the id differs from what's already there, so a tier swap (which
// remounts the screen with the same workout id) keeps the data.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/workout_state.dart';

class ActiveWorkoutSessionState {
  final String? workoutId;
  final Map<int, List<SetLog>> completedSets;
  final int currentExerciseIndex;

  const ActiveWorkoutSessionState({
    this.workoutId,
    this.completedSets = const {},
    this.currentExerciseIndex = 0,
  });

  ActiveWorkoutSessionState copyWith({
    String? workoutId,
    Map<int, List<SetLog>>? completedSets,
    int? currentExerciseIndex,
  }) {
    return ActiveWorkoutSessionState(
      workoutId: workoutId ?? this.workoutId,
      completedSets: completedSets ?? this.completedSets,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
    );
  }
}

class ActiveWorkoutSessionNotifier
    extends StateNotifier<ActiveWorkoutSessionState> {
  ActiveWorkoutSessionNotifier() : super(const ActiveWorkoutSessionState()) {
    _instances.add(this);
  }

  /// Track every live notifier so [clearCache] (a static, called from the
  /// sign-out orchestration in AuthRepository) can reach the in-memory
  /// session state without holding a Ref. There is normally only one
  /// instance — the StateNotifierProvider is not autoDispose — but the
  /// set keeps us safe across hot-reload / test rebuilds.
  static final Set<ActiveWorkoutSessionNotifier> _instances = {};

  /// Wipe in-memory active-workout state on sign-out. Without this, a
  /// user who signs out mid-workout and signs in as a different account
  /// would briefly see the prior user's completed-sets map / current
  /// exercise index until the next `start()` call clobbered it.
  static void clearCache() {
    for (final n in _instances) {
      if (n.mounted) {
        n.state = const ActiveWorkoutSessionState();
      }
    }
  }

  /// Begin (or continue) a session for [workoutId]. If the existing
  /// session is for a different workout, clear it. Otherwise leave it
  /// alone so a tier swap retains progress.
  void start(String? workoutId) {
    if (workoutId == null) return;
    if (state.workoutId == workoutId) return; // same workout — keep state
    state = ActiveWorkoutSessionState(workoutId: workoutId);
  }

  /// Append a freshly-logged set for [exerciseIndex]. No-ops if the
  /// session was never started (defensive — log paths should always
  /// `start` first).
  void recordSet(int exerciseIndex, SetLog log) {
    if (state.workoutId == null) return;
    final next = Map<int, List<SetLog>>.from(state.completedSets);
    final list = List<SetLog>.from(next[exerciseIndex] ?? const <SetLog>[]);
    list.add(log);
    next[exerciseIndex] = list;
    state = state.copyWith(completedSets: next);
  }

  /// Replace an existing set at [setIndex] within [exerciseIndex] (used
  /// when the user edits a previously-logged set).
  void replaceSet(int exerciseIndex, int setIndex, SetLog log) {
    if (state.workoutId == null) return;
    final next = Map<int, List<SetLog>>.from(state.completedSets);
    final list = List<SetLog>.from(next[exerciseIndex] ?? const <SetLog>[]);
    if (setIndex < 0 || setIndex >= list.length) return;
    list[setIndex] = log;
    next[exerciseIndex] = list;
    state = state.copyWith(completedSets: next);
  }

  /// Drop the last set for [exerciseIndex] (used when undoing).
  void popLastSet(int exerciseIndex) {
    if (state.workoutId == null) return;
    final next = Map<int, List<SetLog>>.from(state.completedSets);
    final list = List<SetLog>.from(next[exerciseIndex] ?? const <SetLog>[]);
    if (list.isEmpty) return;
    list.removeLast();
    next[exerciseIndex] = list;
    state = state.copyWith(completedSets: next);
  }

  void setCurrentIndex(int idx) {
    if (state.workoutId == null) return;
    if (state.currentExerciseIndex == idx) return;
    state = state.copyWith(currentExerciseIndex: idx);
  }

  /// Wipe the session. Call when the user finalizes or quits the
  /// workout — otherwise re-entering the same workout would double-
  /// count old sets.
  void clear() {
    state = const ActiveWorkoutSessionState();
  }

  @override
  void dispose() {
    _instances.remove(this);
    super.dispose();
  }
}

final activeWorkoutSessionProvider = StateNotifierProvider<
    ActiveWorkoutSessionNotifier, ActiveWorkoutSessionState>(
  (ref) => ActiveWorkoutSessionNotifier(),
);
