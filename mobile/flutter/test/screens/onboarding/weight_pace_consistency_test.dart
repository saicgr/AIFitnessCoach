import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/screens/onboarding/weight_projection_screen.dart'
    show WeightProjectionCalculator;
import 'package:fitwiz/screens/onboarding/widgets/quiz_weight_rate.dart';

/// This test asserts calorie/rate MATH, not colour — the accent is
/// irrelevant here, so a fixed placeholder stands in for the
/// `context.accentColor` a real screen would pass.
const _testAccent = Color(0xFFF97316);

/// Regression gate: the pace a user SEES must be the pace we COMPUTE with.
///
/// The onboarding funnel quoted three different timelines for the same plan
/// (projection chart "Sep 22", commitment pact "about 8 weeks", sign-in
/// "Goal: Oct 20") because three places disagreed about the weekly rate:
///
///   * `QuizWeightRateChips` renders `weightChangeRate ?? 'moderate'` as the
///     selected chip, and that chip declares 0.5 kg/wk ("1 lb/wk").
///   * The projection screen passed the RAW (still null) rate into
///     `calculateWeeklyRate`, which fell through to its no-rate branch —
///     `0.5 + workoutDays/14`, i.e. ~0.79 kg/wk for a 4-day week. That value
///     corresponds to NO chip on screen; the curve simply ran ~60% hot.
///   * The commitment pact hardcoded its own 0.75 kg/wk.
///
/// Two independent copies of the rate table still exist (the chips' own
/// `weeklyRate` field and `calculateWeeklyRate`'s switch). These tests pin
/// them together so changing one without the other fails here rather than in
/// front of a user.
void main() {
  const kLosingCurrent = 82.0;
  const kLosingGoal = 76.0;
  const kGainingCurrent = 70.0;
  const kGainingGoal = 76.0;
  const kWorkoutDays = 4;

  group('pace chip weeklyRate matches calculateWeeklyRate', () {
    test('every LOSING chip agrees with the calculator', () {
      final options = getWeightRateOptions(isLosing: true, useMetric: true, accentColor: _testAccent);
      expect(options, isNotEmpty);

      for (final o in options) {
        final computed = WeightProjectionCalculator.calculateWeeklyRate(
          currentWeight: kLosingCurrent,
          goalWeight: kLosingGoal,
          workoutDaysPerWeek: kWorkoutDays,
          weightChangeRate: o.id,
        );
        expect(
          computed,
          o.weeklyRate,
          reason: 'Chip "${o.label}" (${o.id}) advertises ${o.weeklyRate} kg/wk '
              '("${o.rateLabel}") but calculateWeeklyRate returns $computed. '
              'The user would be shown a curve that contradicts the label '
              'they picked.',
        );
      }
    });

    test('every GAINING chip agrees with the calculator', () {
      final options = getWeightRateOptions(isLosing: false, useMetric: true, accentColor: _testAccent);
      expect(options, isNotEmpty);

      for (final o in options) {
        final computed = WeightProjectionCalculator.calculateWeeklyRate(
          currentWeight: kGainingCurrent,
          goalWeight: kGainingGoal,
          workoutDaysPerWeek: kWorkoutDays,
          weightChangeRate: o.id,
        );
        expect(
          computed,
          o.weeklyRate,
          reason: 'Chip "${o.label}" (${o.id}) advertises ${o.weeklyRate} kg/wk '
              'but calculateWeeklyRate returns $computed.',
        );
      }
    });
  });

  group('the default-selected chip drives the projection', () {
    // QuizWeightRateChips is constructed with `selectedRate: rate ?? 'moderate'`,
    // so an untouched screen SHOWS "Moderate". The maths must use the same
    // value — passing the raw null instead is the exact defect this guards.
    test("an untouched screen must compute at Moderate's rate, not the "
        'no-rate fallback', () {
      final moderate = WeightProjectionCalculator.calculateWeeklyRate(
        currentWeight: kLosingCurrent,
        goalWeight: kLosingGoal,
        workoutDaysPerWeek: kWorkoutDays,
        weightChangeRate: 'moderate',
      );
      final noRateFallback = WeightProjectionCalculator.calculateWeeklyRate(
        currentWeight: kLosingCurrent,
        goalWeight: kLosingGoal,
        workoutDaysPerWeek: kWorkoutDays,
        weightChangeRate: null,
      );

      // Guard the premise: these genuinely differ, which is why passing null
      // silently produced a different curve than the visible label.
      expect(
        noRateFallback,
        isNot(moderate),
        reason: 'If these ever became equal this test would pass vacuously.',
      );

      final chipRate = getWeightRateOptions(isLosing: true, useMetric: true, accentColor: _testAccent)
          .firstWhere((o) => o.id == 'moderate')
          .weeklyRate;
      expect(moderate, chipRate);
    });

    test('the no-rate fallback matches no chip at all', () {
      final fallback = WeightProjectionCalculator.calculateWeeklyRate(
        currentWeight: kLosingCurrent,
        goalWeight: kLosingGoal,
        workoutDaysPerWeek: kWorkoutDays,
        weightChangeRate: null,
      );
      final chipRates = getWeightRateOptions(isLosing: true, useMetric: true, accentColor: _testAccent)
          .map((o) => o.weeklyRate)
          .toList();
      expect(
        chipRates.contains(fallback),
        isFalse,
        reason: 'The unlabeled fallback rate ($fallback kg/wk) is not offered '
            'as a chip, so it must never drive a curve the user sees.',
      );
    });
  });

  group('imperial chip labels are honest about their kg rate', () {
    // Labels are deliberately rounded for readability ("1 lb/wk" for
    // 0.5 kg/wk = 1.10 lb). Allow the rounding, catch a real mismatch.
    test('losing labels are within 15% of the true conversion', () {
      for (final o in getWeightRateOptions(isLosing: true, useMetric: false, accentColor: _testAccent)) {
        final labelled =
            double.parse(RegExp(r'[\d.]+').firstMatch(o.rateLabel)!.group(0)!);
        final trueLb = o.weeklyRate * 2.20462;
        expect(
          (labelled - trueLb).abs() / trueLb,
          lessThan(0.15),
          reason: 'Chip "${o.label}" says "${o.rateLabel}" but '
              '${o.weeklyRate} kg/wk is ${trueLb.toStringAsFixed(2)} lb/wk.',
        );
      }
    });
  });
}
