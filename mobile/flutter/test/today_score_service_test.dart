// Unit tests for the Today Score engine (Phase 1).
//
// Pure-Dart tests — no widgets, no device. Run with:
//   flutter test test/today_score_service_test.dart
//
// Covers the renormalization rule across every edge case: training day,
// rest day, no plan, no Health Connect, combinations, the setup state,
// clamping, and the plain-language status strings.

import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/data/models/today_score.dart';
import 'package:fitwiz/services/today_score_service.dart';

void main() {
  // A fixed timestamp so nothing depends on the wall clock.
  final fixedNow = DateTime(2026, 5, 21, 12, 52);

  group('Training day — all three contributors apply', () {
    test('everything complete → 100', () {
      final s = computeTodayScore(
        const TodayScoreInputs(
          hasPlan: true,
          hasWorkoutScheduledToday: true,
          workoutComplete: true,
          hasNutritionTargets: true,
          calorieTarget: 2000,
          caloriesLogged: 2000,
          proteinTargetG: 100,
          proteinLoggedG: 100,
          healthConnected: true,
          steps: 10000,
          stepGoal: 10000,
        ),
        now: fixedNow,
      );
      expect(s.score, 100);
      expect(s.isSetupState, false);
      expect(s.applicableContributors.length, 3);
    });

    test('half done everywhere → weighted 25', () {
      // Train 0 · Fuel .5 · Move .5 → (.50·0 + .35·.5 + .15·.5)·100 = 25
      final s = computeTodayScore(
        const TodayScoreInputs(
          hasPlan: true,
          hasWorkoutScheduledToday: true,
          hasNutritionTargets: true,
          calorieTarget: 2000,
          caloriesLogged: 1000,
          proteinTargetG: 100,
          proteinLoggedG: 50,
          healthConnected: true,
          steps: 5000,
          stepGoal: 10000,
        ),
        now: fixedNow,
      );
      expect(s.score, 25);
      expect(s.contributor(ContributorKind.train).effectiveWeight,
          closeTo(0.50, 1e-9));
    });

    test('workout in progress gives partial Train credit', () {
      final s = computeTodayScore(
        const TodayScoreInputs(
          hasPlan: true,
          hasWorkoutScheduledToday: true,
          exercisesDone: 3,
          exercisesTotal: 6,
          hasNutritionTargets: true,
        ),
        now: fixedNow,
      );
      expect(s.contributor(ContributorKind.train).completion, closeTo(0.5, 1e-9));
    });
  });

  group('Rest day — Train drops out, weights renormalize', () {
    test('Fuel/Move renormalize to .70/.30; resting is not punished', () {
      final s = computeTodayScore(
        const TodayScoreInputs(
          hasPlan: true,
          hasWorkoutScheduledToday: false,
          isRestDay: true,
          hasNutritionTargets: true,
          calorieTarget: 2000,
          caloriesLogged: 1000,
          proteinTargetG: 100,
          proteinLoggedG: 50,
          healthConnected: true,
          steps: 5000,
          stepGoal: 10000,
        ),
        now: fixedNow,
      );
      // (.70·.5 + .30·.5)·100 = 50
      expect(s.score, 50);
      expect(s.contributor(ContributorKind.train).applicable, false);
      expect(s.contributor(ContributorKind.train).effectiveWeight, 0.0);
      expect(s.contributor(ContributorKind.fuel).effectiveWeight,
          closeTo(0.70, 1e-9));
      expect(s.contributor(ContributorKind.move).effectiveWeight,
          closeTo(0.30, 1e-9));
    });

    test('rest day shows the rest-day status', () {
      final s = computeTodayScore(
        const TodayScoreInputs(
          hasPlan: true,
          isRestDay: true,
          hasNutritionTargets: true,
        ),
        now: fixedNow,
      );
      expect(s.contributor(ContributorKind.train).statusText,
          'Rest day · recover well');
    });
  });

  group('No plan', () {
    test('same math as a rest day, but a setup nudge on Train', () {
      final s = computeTodayScore(
        const TodayScoreInputs(
          hasPlan: false,
          hasWorkoutScheduledToday: false,
          isRestDay: false,
          hasNutritionTargets: true,
          calorieTarget: 2000,
          caloriesLogged: 1000,
          proteinTargetG: 100,
          proteinLoggedG: 50,
          healthConnected: true,
          steps: 5000,
          stepGoal: 10000,
        ),
        now: fixedNow,
      );
      expect(s.score, 50);
      expect(s.contributor(ContributorKind.train).statusText,
          'Add a plan to count training');
    });
  });

  group('No Health Connect — Move drops out', () {
    test('Train/Fuel renormalize to ~.59/.41', () {
      // Train 0 · Fuel .5 → (.35/.85)·.5·100 = 20.59 → 21
      final s = computeTodayScore(
        const TodayScoreInputs(
          hasPlan: true,
          hasWorkoutScheduledToday: true,
          hasNutritionTargets: true,
          calorieTarget: 2000,
          caloriesLogged: 1000,
          proteinTargetG: 100,
          proteinLoggedG: 50,
          healthConnected: false,
        ),
        now: fixedNow,
      );
      expect(s.score, 21);
      expect(s.contributor(ContributorKind.move).applicable, false);
      expect(s.contributor(ContributorKind.train).effectiveWeight,
          closeTo(0.50 / 0.85, 1e-9));
      expect(s.contributor(ContributorKind.move).statusText,
          'Connect Health to count steps');
    });
  });

  group('No plan + no Health Connect — Fuel only', () {
    test('Fuel carries the whole score', () {
      final s = computeTodayScore(
        const TodayScoreInputs(
          hasPlan: false,
          hasNutritionTargets: true,
          calorieTarget: 2000,
          caloriesLogged: 1000,
          proteinTargetG: 100,
          proteinLoggedG: 50,
          healthConnected: false,
        ),
        now: fixedNow,
      );
      expect(s.score, 50); // fuel .5 × effW 1.0
      expect(s.contributor(ContributorKind.fuel).effectiveWeight,
          closeTo(1.0, 1e-9));
    });
  });

  group('Setup state — nothing applies', () {
    test('brand-new user → score 0, isSetupState true', () {
      final s = computeTodayScore(
        const TodayScoreInputs(),
        now: fixedNow,
      );
      expect(s.isSetupState, true);
      expect(s.score, 0);
      expect(s.applicableContributors, isEmpty);
    });
  });

  group('Clamping — over-target never overflows', () {
    test('logging past every goal still caps at 100', () {
      final s = computeTodayScore(
        const TodayScoreInputs(
          hasPlan: true,
          hasWorkoutScheduledToday: true,
          workoutComplete: true,
          hasNutritionTargets: true,
          calorieTarget: 2000,
          caloriesLogged: 4000,
          proteinTargetG: 100,
          proteinLoggedG: 250,
          healthConnected: true,
          steps: 50000,
          stepGoal: 10000,
        ),
        now: fixedNow,
      );
      expect(s.score, 100);
      expect(s.contributor(ContributorKind.fuel).completion, closeTo(1.0, 1e-9));
      expect(s.contributor(ContributorKind.move).completion, closeTo(1.0, 1e-9));
    });
  });

  group('Status text', () {
    final base = const TodayScoreInputs(
      hasPlan: true,
      hasWorkoutScheduledToday: true,
      hasNutritionTargets: true,
      calorieTarget: 2000,
      proteinTargetG: 102,
      proteinLoggedG: 13,
      healthConnected: true,
      steps: 7412,
      stepGoal: 10000,
      workoutLabel: 'Leg day',
    );

    test('Fuel shows a qualitative protein status (no duplicate number)', () {
      // protein 13/102 → well under half → "running low" (no gram count;
      // the exact number lives in the Nutrition card).
      expect(computeTodayScore(base, now: fixedNow)
          .contributor(ContributorKind.fuel)
          .statusText, 'Protein running low');
    });

    test('Move shows steps remaining with thousands separator', () {
      expect(computeTodayScore(base, now: fixedNow)
          .contributor(ContributorKind.move)
          .statusText, '2,588 steps to go');
    });

    test('Train not-started uses the workout label', () {
      expect(computeTodayScore(base, now: fixedNow)
          .contributor(ContributorKind.train)
          .statusText, 'Leg day · not started');
    });

    test('Train complete', () {
      final s = computeTodayScore(
        const TodayScoreInputs(
          hasPlan: true,
          hasWorkoutScheduledToday: true,
          workoutComplete: true,
          hasNutritionTargets: true,
        ),
        now: fixedNow,
      );
      expect(s.contributor(ContributorKind.train).statusText,
          'Workout complete');
    });

    test('Fuel goal hit', () {
      final s = computeTodayScore(
        const TodayScoreInputs(
          hasNutritionTargets: true,
          proteinTargetG: 100,
          proteinLoggedG: 100,
        ),
        now: fixedNow,
      );
      expect(s.contributor(ContributorKind.fuel).statusText,
          'Protein goal hit');
    });
  });

  group('stateLabel', () {
    TodayScore scoreWith(int caloriesLogged) => computeTodayScore(
          TodayScoreInputs(
            hasNutritionTargets: true,
            calorieTarget: 2000,
            caloriesLogged: caloriesLogged,
            proteinTargetG: 100,
            proteinLoggedG: caloriesLogged ~/ 20,
          ),
          now: fixedNow,
        );

    test('reads as a word, not a number', () {
      expect(scoreWith(2000).stateLabel, 'Crushing it'); // ~100
      expect(scoreWith(0).stateLabel, 'Just getting started'); // 0-ish
    });
  });
}
