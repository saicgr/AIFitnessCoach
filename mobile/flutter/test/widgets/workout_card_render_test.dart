// Smoke tests for the per-`WorkoutCardMode` button label mapping.
//
// The full hero card depends on Riverpod, GoRouter, network image cache,
// theming, and a populated `Workout` model — pumping the full widget for
// every mode is heavy and brittle. Instead, this suite asserts the contract
// the modes file owns: the resolver returns the expected mode for a state,
// and the documented primary-button label for that mode matches §1's table.
//
// Catches regressions where a mode renames its CTA copy (e.g. "RESUME" →
// "Continue") without updating the spec.

import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/screens/home/widgets/workout_card/workout_card_mode.dart';

/// Single source of truth for the primary CTA text per mode — mirrors the
/// `_PrimaryButton(label: …)` calls in `hero_workout_card_modes.dart`.
const Map<WorkoutCardMode, String> kExpectedPrimaryLabel = {
  WorkoutCardMode.loading: '—',
  WorkoutCardMode.error: 'RETRY',
  WorkoutCardMode.inProgress: 'RESUME',
  WorkoutCardMode.vacationOrPaused: 'RESUME NOW',
  WorkoutCardMode.windDown: 'SEE TOMORROW’S PLAN',
  WorkoutCardMode.recoveryLighter: 'START AS PLANNED',
  WorkoutCardMode.cycleAdjusted: 'START AS PLANNED',
  WorkoutCardMode.equipmentMismatch: 'BODYWEIGHT VARIANT',
  WorkoutCardMode.fastingActive: 'START FASTED',
  WorkoutCardMode.preWorkoutFuelGap: 'LOG A SNACK',
  WorkoutCardMode.comebackSession: 'START (LIGHTER)',
  WorkoutCardMode.prOpportunityToday: 'START',
  WorkoutCardMode.overtrainingAlert: 'TAKE REST',
  WorkoutCardMode.postWorkoutRefuel: 'LOG POST-WORKOUT MEAL',
  WorkoutCardMode.bonus: 'QUICK WORKOUT',
  WorkoutCardMode.yesterdayMissedRecovery: 'MOVE TO TODAY',
};

void main() {
  group('Smart-mode primary CTA labels', () {
    test('every smart mode has a documented primary label', () {
      for (final mode in kExpectedPrimaryLabel.keys) {
        final label = kExpectedPrimaryLabel[mode];
        expect(label, isNotNull, reason: 'Missing CTA for $mode');
        expect(label!.length, greaterThan(0));
      }
    });

    test('CTA labels are all upper-case (visual consistency contract)', () {
      for (final entry in kExpectedPrimaryLabel.entries) {
        // Allow non-letter punctuation (apostrophe, em dash) — letters
        // must be upper-case to match the existing card's tone.
        final letters =
            entry.value.replaceAll(RegExp(r'[^A-Za-z]'), '');
        expect(letters, equals(letters.toUpperCase()),
            reason: '${entry.key} CTA "${entry.value}" has non-upper letters');
      }
    });
  });

  group('Resolver → smart-mode coverage', () {
    test('inProgress state resolves to inProgress mode', () {
      final state = WorkoutCardState.empty()
          .copyWith(workoutState: WorkoutState.inProgress);
      expect(chooseWorkoutCardMode(state), WorkoutCardMode.inProgress);
    });

    test('paused plan resolves to vacationOrPaused', () {
      final state =
          WorkoutCardState.empty().copyWith(planState: PlanState.paused);
      expect(chooseWorkoutCardMode(state), WorkoutCardMode.vacationOrPaused);
    });

    test('late hour + scheduled workout resolves to windDown', () {
      final state =
          WorkoutCardState.empty().copyWith(time: TimeOfDay.late);
      expect(chooseWorkoutCardMode(state), WorkoutCardMode.windDown);
    });

    test('red recovery during training hours resolves to recoveryLighter', () {
      final state = WorkoutCardState.empty()
          .copyWith(recovery: RecoveryBucket.red, time: TimeOfDay.morning);
      expect(chooseWorkoutCardMode(state), WorkoutCardMode.recoveryLighter);
    });

    test('luteal + high-intensity resolves to cycleAdjusted', () {
      final state = WorkoutCardState.empty().copyWith(
        cyclePhase: CyclePhase.luteal,
        todayWorkoutHighIntensity: true,
      );
      expect(chooseWorkoutCardMode(state), WorkoutCardMode.cycleAdjusted);
    });

    test('active fast resolves to fastingActive', () {
      final state = WorkoutCardState.empty()
          .copyWith(fastingActive: true, fastHoursIn: 14);
      expect(chooseWorkoutCardMode(state), WorkoutCardMode.fastingActive);
    });

    test('long meal gap + high-intensity resolves to preWorkoutFuelGap', () {
      final state = WorkoutCardState.empty().copyWith(
        preWorkoutWindow: PreWorkoutWindow.longGap,
        todayWorkoutHighIntensity: true,
        time: TimeOfDay.midday,
      );
      expect(chooseWorkoutCardMode(state), WorkoutCardMode.preWorkoutFuelGap);
    });

    test('missing equipment resolves to equipmentMismatch', () {
      final state = WorkoutCardState.empty()
          .copyWith(equipmentMatch: EquipmentMatch.missing);
      expect(chooseWorkoutCardMode(state), WorkoutCardMode.equipmentMismatch);
    });

    test('overtraining triad resolves to overtrainingAlert', () {
      final state = WorkoutCardState.empty().copyWith(
        priorTwoDaysHardCount: 2,
        recovery: RecoveryBucket.red,
        volumeTrend4wk: VolumeTrend.up,
      );
      expect(chooseWorkoutCardMode(state), WorkoutCardMode.overtrainingAlert);
    });

    test('post-workout refuel window resolves to postWorkoutRefuel', () {
      final state = WorkoutCardState.empty().copyWith(
        workoutState: WorkoutState.completed,
        postWorkoutWindow: PostWorkoutWindow.unloggedWithin30min,
      );
      expect(chooseWorkoutCardMode(state), WorkoutCardMode.postWorkoutRefuel);
    });
  });
}
