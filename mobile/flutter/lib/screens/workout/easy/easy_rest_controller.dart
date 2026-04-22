// Easy tier — rest flow controller.
//
// Encapsulates the rest-timer + full-screen overlay lifecycle so the main
// state class stays under 300 lines. Holds no widget state itself — the
// state class owns `_perExercise`, the timer controller, and the active
// broadcaster; this helper just composes them into "start rest", "stop
// rest" and "resolve next-set target" operations.

import 'package:flutter/material.dart';

import '../../../data/models/exercise.dart';
import '../controllers/workout_timer_controller.dart';
import 'easy_active_workout_state_models.dart';
import 'widgets/easy_rest_overlay.dart';

/// Data bundle returned by `resolveNextTarget` — what the rest overlay
/// should display for the upcoming set.
class EasyNextTarget {
  final WorkoutExercise exercise;
  final int setNumber;
  final double targetWeightKg;
  final int targetReps;
  final int totalSets;

  EasyNextTarget({
    required this.exercise,
    required this.setNumber,
    required this.targetWeightKg,
    required this.targetReps,
    required this.totalSets,
  });
}

/// Pure resolver: given the current state, figure out what set the user
/// should see on the rest overlay. Called by the state class just before
/// it pushes the overlay route.
EasyNextTarget resolveEasyNextTarget({
  required bool finishedExercise,
  required int currentIndex,
  required List<WorkoutExercise> exercises,
  required Map<int, EasyExerciseState> perExercise,
}) {
  final nextIdx = finishedExercise
      ? (currentIndex + 1).clamp(0, exercises.length - 1)
      : currentIndex;
  final nextExercise = exercises[nextIdx];
  final nextState = perExercise[nextIdx]!;
  final nextSetNumber =
      finishedExercise ? 1 : nextState.completed.length + 1;
  final setTarget = nextExercise.getTargetForSet(nextSetNumber);
  final nextTargetKg = (setTarget?.targetWeightKg ??
          nextExercise.weight ??
          nextState.targetWeightKg)
      .toDouble();
  final nextTargetReps =
      setTarget?.targetReps ?? nextExercise.reps ?? nextState.targetReps;
  return EasyNextTarget(
    exercise: nextExercise,
    setNumber: nextSetNumber,
    targetWeightKg: nextTargetKg,
    targetReps: nextTargetReps,
    totalSets: nextState.totalSets,
  );
}

/// Push the full-screen rest overlay and wire the broadcaster to the timer.
/// Replaces any active broadcaster; caller should dispose old references
/// before calling.
RestStreamBroadcaster startEasyRest({
  required BuildContext context,
  required WorkoutTimerController timer,
  required int seconds,
  required EasyNextTarget target,
  required bool useKg,
}) {
  final broadcaster = RestStreamBroadcaster(seconds);
  timer.startRestTimer(seconds);

  Navigator.of(context).push(PageRouteBuilder(
    opaque: false,
    barrierColor: Colors.black.withValues(alpha: 0.92),
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (_, anim, __) => FadeTransition(
      opacity: anim,
      child: EasyRestOverlay(
        initialSeconds: seconds,
        remainingStream: broadcaster.stream,
        nextExercise: target.exercise,
        nextSetNumber: target.setNumber,
        totalSets: target.totalSets,
        nextTargetWeightKg: target.targetWeightKg,
        nextTargetReps: target.targetReps,
        useKg: useKg,
        onSkip: timer.skipRest,
        onDone: () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        },
      ),
    ),
  ));

  return broadcaster;
}
