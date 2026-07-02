// Entry gate that picks which active-workout tier to render based on the
// user's workoutUiModeProvider. The two tiers share the same
// todayWorkoutProvider + rest-timer state, so mid-workout tier swaps
// preserve progress automatically.
//
// Simple was retired; the `WorkoutUiMode.simple` enum value is still kept
// for DB back-compat and routes to the Easy screen here.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/active_workout_phase_provider.dart';
import '../../core/providers/workout_ui_mode_provider.dart';
import '../../data/models/workout.dart';
import '../../data/providers/equipment_match_pending_action_provider.dart';
import 'active_workout_screen_refactored.dart';
import 'easy/easy_active_workout_screen.dart';
import 'providers/active_workout_live_provider.dart';
import 'widgets/exercise_add_sheet.dart';
import 'widgets/exercise_swap_sheet.dart';
import 'widgets/pre_workout_reshape_gate.dart';

class ActiveWorkoutEntry extends ConsumerStatefulWidget {
  final Workout workout;
  final String? challengeId;
  final Map<String, dynamic>? challengeData;

  const ActiveWorkoutEntry({
    super.key,
    required this.workout,
    this.challengeId,
    this.challengeData,
  });

  @override
  ConsumerState<ActiveWorkoutEntry> createState() => _ActiveWorkoutEntryState();
}

class _ActiveWorkoutEntryState extends ConsumerState<ActiveWorkoutEntry> {
  /// The workout actually handed to the current tier — the live override when
  /// present (carries swaps/adds across tier switches), else the passed-in one.
  /// Resolved in [build].
  late Workout _activeWorkout = widget.workout;

  @override
  void initState() {
    super.initState();
    // Reset the shared warmup flag for THIS fresh workout BEFORE the child
    // tier mounts. Easy/Simple flip it back to true in their own init;
    // Advanced reads it in its own initState and skips warmup only if still
    // true (i.e. user tier-swapped mid-session).
    //
    // Important: we can't unconditionally do `notifier.state = false` here.
    // If an upstream widget is listening to this StateProvider at the
    // moment /active-workout mounts, Riverpod throws "Tried to modify a
    // provider while the widget tree was building" — the very error this
    // code was getting. And previously, deferring the reset into dispose()
    // crashed too (post-frame fired after ConsumerElement was torn down).
    //
    // Two-tier fix:
    //   • Fast path: if state is already false (default, and the common case
    //     on fresh app launch), no write → no listener notification → no
    //     crash. This covers normal workout-to-workout flow.
    //   • Slow path: if state is stale-true (prior workout didn't clean up),
    //     defer the reset to a post-frame callback with a `mounted` guard
    //     so it runs after the current build completes. Advanced's child
    //     initState will observe `true` for this one frame and skip warmup;
    //     the next fresh workout will see the reset value. That's the
    //     trade-off for avoiding the crash — and the underlying stale-true
    //     bug should be fixed at workout-end time, not here.
    final notifier = ref.read(activeWorkoutWarmupDoneProvider.notifier);
    // Clear any live-workout override left over from a PREVIOUS session so this
    // workout starts from its own passed-in exercise list. Post-frame to avoid
    // mutating a provider during build. The build-time id guard also defends
    // against a stale override, but clearing keeps the provider tidy.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final live = ref.read(activeWorkoutLiveProvider);
      if (live != null && live.id != widget.workout.id) {
        ref.read(activeWorkoutLiveProvider.notifier).state = null;
      }
    });
    // Consume any chat-deeplink pending action AFTER first frame so the
    // child tier has fully mounted and the user sees the workout shell
    // first (avoids a sheet over a blank background). One-shot: we clear
    // the provider before opening so a remount doesn't replay it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _maybeConsumeEquipmentMatchPendingAction();
    });
    // Pre-workout reshape gate (Dr-Yaad audit #1) — once per workout per day,
    // ask the check-in and live-reshape the session before the first set. Runs
    // after the equipment-match consumer so we never stack two sheets; the gate
    // self-skips if it already ran today, and applies via activeWorkoutLiveProvider.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      maybeRunPreWorkoutReshape(context, ref, widget.workout);
    });
    if (!notifier.state) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(activeWorkoutWarmupDoneProvider.notifier).state = false;
    });
  }

  /// Reads the pending action provider once and, if a non-stale payload is
  /// present, opens the matching sheet (swap or add) with the matched
  /// exercise pre-highlighted. Always clears the provider — even on a
  /// no-op — so a later mount doesn't replay an old signal.
  Future<void> _maybeConsumeEquipmentMatchPendingAction() async {
    final pending = ref.read(equipmentMatchPendingActionProvider);
    if (pending == null) return;
    // Clear immediately to make this strictly one-shot.
    ref.read(equipmentMatchPendingActionProvider.notifier).state = null;
    if (pending.isStale()) return;

    final workoutId = widget.workout.id;
    if (workoutId == null) return;

    // Gate the tier tour while the swap/add sheet is up — same collision as
    // the reshape check-in sheet: the tour would spotlight workout controls
    // buried under this modal. Controller captured up-front so the `finally`
    // decrement is safe even if this screen is popped mid-sheet.
    final tourGate = ref.read(preWorkoutModalDepthProvider.notifier);
    tourGate.state++;
    try {
      await _consumeEquipmentMatchPendingAction(pending, workoutId);
    } finally {
      tourGate.state--;
    }
  }

  Future<void> _consumeEquipmentMatchPendingAction(
    EquipmentMatchPendingAction pending,
    String workoutId,
  ) async {
    if (pending.mode == EquipmentMatchPendingMode.swap) {
      // Pick the first existing exercise as the swap target. The user can
      // change which exercise to swap from the sheet's reason chips, but
      // we need *some* exercise to seed `widget.exercise`. Prefer the
      // earliest non-completed entry (proxy for "current"); fall back to
      // index 0.
      final exercises = widget.workout.exercises;
      if (exercises.isEmpty) {
        await showExerciseAddSheet(
          context,
          ref,
          workoutId: workoutId,
          workoutType: widget.workout.type ?? 'strength',
          currentExerciseNames: const [],
          preselectedExerciseId: pending.exerciseId,
          preselectedExerciseName: pending.exerciseName,
        );
        return;
      }
      final target = exercises.first;
      await showExerciseSwapSheet(
        context,
        ref,
        workoutId: workoutId,
        exercise: target,
        preselectedExerciseId: pending.exerciseId,
        preselectedExerciseName: pending.exerciseName,
      );
    } else {
      await showExerciseAddSheet(
        context,
        ref,
        workoutId: workoutId,
        workoutType: widget.workout.type ?? 'strength',
        currentExerciseNames:
            widget.workout.exercises.map((e) => e.name).toList(),
        preselectedExerciseId: pending.exerciseId,
        preselectedExerciseName: pending.exerciseName,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(workoutUiModeProvider.select((s) => s.mode));
    // Prefer the live (post-swap / post-add) workout so a structural mutation
    // made in one tier survives a switch to the other. Guarded by id so a
    // stale override from a prior session is ignored.
    final live = ref.watch(activeWorkoutLiveProvider);
    _activeWorkout =
        (live != null && live.id == widget.workout.id) ? live : widget.workout;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.02),
            end: Offset.zero,
          ).animate(anim),
          child: child,
        ),
      ),
      child: _buildForMode(mode),
    );
  }

  Widget _buildForMode(WorkoutUiMode mode) {
    switch (mode) {
      case WorkoutUiMode.easy:
      // ignore: deprecated_member_use_from_same_package
      case WorkoutUiMode.simple:
        return EasyActiveWorkoutScreen(
          key: const ValueKey('easy_active_workout'),
          workout: _activeWorkout,
          challengeId: widget.challengeId,
          challengeData: widget.challengeData,
        );
      case WorkoutUiMode.advanced:
        return ActiveWorkoutScreen(
          key: const ValueKey('advanced_active_workout'),
          workout: _activeWorkout,
          challengeId: widget.challengeId,
          challengeData: widget.challengeData,
        );
    }
  }
}
