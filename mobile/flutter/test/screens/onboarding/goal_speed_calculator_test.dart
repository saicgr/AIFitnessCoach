import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/screens/onboarding/goal_speed_calculator.dart';

void main() {
  group('GoalSpeedCalculator.compute', () {
    test('returns null when maintaining (delta below threshold)', () {
      final result = GoalSpeedCalculator.compute(
        currentWeightKg: 80,
        goalWeightKg: 80.2,
      );
      expect(result, isNull);
    });

    test('multiplier stays within the credible clamp band', () {
      for (final rate in ['slow', 'moderate', 'fast', 'aggressive']) {
        final r = GoalSpeedCalculator.compute(
          currentWeightKg: 90,
          goalWeightKg: 75,
          weightChangeRate: rate,
        )!;
        expect(r.speedMultiplier,
            greaterThanOrEqualTo(GoalSpeedCalculator.minMultiplier));
        expect(r.speedMultiplier,
            lessThanOrEqualTo(GoalSpeedCalculator.maxMultiplier));
      }
    });

    test('multiplier is never below 1', () {
      final r = GoalSpeedCalculator.compute(
        currentWeightKg: 70,
        goalWeightKg: 69,
        weightChangeRate: 'slow',
      )!;
      expect(r.speedMultiplier, greaterThan(1.0));
    });

    test('a faster chosen pace yields a higher (or equal) multiplier', () {
      final slow = GoalSpeedCalculator.compute(
        currentWeightKg: 95,
        goalWeightKg: 75,
        weightChangeRate: 'slow',
      )!;
      final aggressive = GoalSpeedCalculator.compute(
        currentWeightKg: 95,
        goalWeightKg: 75,
        weightChangeRate: 'aggressive',
      )!;
      expect(aggressive.speedMultiplier,
          greaterThanOrEqualTo(slow.speedMultiplier));
    });

    test('plan reaches the goal but solo lags behind at the goal date', () {
      final r = GoalSpeedCalculator.compute(
        currentWeightKg: 90,
        goalWeightKg: 78,
        weightChangeRate: 'moderate',
      )!;
      final planEnd = r.planCurve.last.weightKg;
      final soloEnd = r.soloCurve.last.weightKg;
      // Plan lands on (or essentially on) the goal.
      expect(planEnd, closeTo(78, 0.5));
      // Solo is still heavier than the plan at the same date (loss case).
      expect(soloEnd, greaterThan(planEnd));
    });

    test('safe-rate cap holds for aggressive loss (≤1 kg/wk)', () {
      final rate = GoalSpeedCalculator.plannedWeeklyRate(
        weightChangeRate: 'aggressive',
        isLoss: true,
      );
      expect(rate, lessThanOrEqualTo(GoalSpeedCalculator.maxLossKgPerWeek));
    });

    test('safe-rate cap holds for gain (≤0.5 kg/wk)', () {
      final rate = GoalSpeedCalculator.plannedWeeklyRate(
        weightChangeRate: 'aggressive',
        isLoss: false,
      );
      expect(rate, lessThanOrEqualTo(GoalSpeedCalculator.maxGainKgPerWeek));
    });

    test('multiplierLabel drops a trailing .0', () {
      final r = GoalSpeedCalculator.compute(
        currentWeightKg: 100,
        goalWeightKg: 80,
        weightChangeRate: 'aggressive',
      )!;
      // 4.5 in this case → "4.5×"; just assert format shape.
      expect(r.multiplierLabel, endsWith('×'));
      expect(r.multiplierLabel, isNot(contains('.0')));
    });
  });
}
