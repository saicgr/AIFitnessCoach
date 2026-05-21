import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/screens/health/widgets/sleep_score.dart';

/// Unit tests for [computeSleepScore] — the pure 0-100 sleep-score logic
/// behind the Sleep detail screen. Exercises the plan's edge cases:
///   * partial data — efficiency null falls back to the stage bonus (case 7);
///   * new user — no mid-sleep history omits consistency + renormalises
///     over the two components that DO have data (case 25);
///   * nothing to score — zero asleep minutes returns null, never a
///     fabricated number (no-mock-data rule).
void main() {
  group('computeSleepScore', () {
    test('returns null when there is nothing to score', () {
      expect(
        computeSleepScore(asleepMinutes: 0, goalMinutes: 480),
        isNull,
      );
      expect(
        computeSleepScore(asleepMinutes: -10, goalMinutes: 480),
        isNull,
      );
    });

    test('a goal-hitting, efficient, well-staged, consistent night scores high',
        () {
      final score = computeSleepScore(
        asleepMinutes: 480, // exactly the 8h goal
        goalMinutes: 480,
        efficiency: 0.95,
        deepMinutes: 110,
        remMinutes: 110, // 220/480 ≈ 46% deep+REM
        midSleepMinutesFromMidnight: 180,
        avgMidSleepMinutesFromMidnight: 180, // perfectly consistent
      );
      expect(score, isNotNull);
      expect(score!.total, greaterThanOrEqualTo(90));
      expect(score.label, 'Excellent');
      // All three components present.
      expect(score.consistencyPoints, isNotNull);
    });

    test('a short, broken, off-schedule night scores poorly', () {
      final score = computeSleepScore(
        asleepMinutes: 240, // 4h — half the goal
        goalMinutes: 480,
        efficiency: 0.60,
        deepMinutes: 20,
        remMinutes: 20,
        midSleepMinutesFromMidnight: 360, // 3h off the usual schedule
        avgMidSleepMinutesFromMidnight: 180,
      );
      expect(score, isNotNull);
      expect(score!.total, lessThan(50));
      expect(score.label, 'Poor');
    });

    test('a short night still scores low even when perfectly on-schedule',
        () {
      // Duration is the dominant component — a 4h night cannot reach the
      // Good band on consistency alone.
      final score = computeSleepScore(
        asleepMinutes: 240,
        goalMinutes: 480,
        efficiency: 0.60,
        deepMinutes: 20,
        remMinutes: 20,
        midSleepMinutesFromMidnight: 180,
        avgMidSleepMinutesFromMidnight: 180,
      )!;
      expect(score.total, lessThan(70));
      expect(score.label, anyOf('Fair', 'Poor'));
    });

    test('duration is the dominant component — full marks at goal', () {
      final atGoal = computeSleepScore(
        asleepMinutes: 480,
        goalMinutes: 480,
        efficiency: 0.90,
      )!;
      expect(atGoal.durationPoints, closeTo(atGoal.durationMax, 0.001));
    });

    test('a large oversleep is mildly penalised on duration', () {
      final huge = computeSleepScore(
        asleepMinutes: 480 + 270, // +4.5h overshoot
        goalMinutes: 480,
        efficiency: 0.90,
      )!;
      // Penalised but never below 80% of the duration weight.
      expect(huge.durationPoints, lessThan(huge.durationMax));
      expect(huge.durationPoints, greaterThan(huge.durationMax * 0.79));
    });

    test('partial data: null efficiency still scores from the stage bonus',
        () {
      final score = computeSleepScore(
        asleepMinutes: 450,
        goalMinutes: 480,
        efficiency: null, // unknown — case 7
        deepMinutes: 100,
        remMinutes: 100,
      );
      expect(score, isNotNull);
      // Restfulness is bounded by the stage proportion, never faked to full.
      expect(score!.restfulnessPoints, greaterThan(0));
      expect(score.restfulnessPoints, lessThanOrEqualTo(score.restfulnessMax));
    });

    test('new user: no mid-sleep history omits consistency + renormalises',
        () {
      final score = computeSleepScore(
        asleepMinutes: 480,
        goalMinutes: 480,
        efficiency: 0.95,
        deepMinutes: 110,
        remMinutes: 110,
        // No history → consistency omitted (case 25).
      );
      expect(score, isNotNull);
      expect(score!.consistencyPoints, isNull);
      expect(score.consistencyMax, 0);
      // A near-perfect night still scores near 100 even without history —
      // the TOTAL is renormalised over the two components that have data.
      expect(score.total, greaterThanOrEqualTo(90));
    });

    test('mid-sleep drift across the midnight boundary folds correctly', () {
      // Last night mid-sleep 23:50 (=1430), average 00:10 (=10) → real
      // drift is 20 min, not 1420. A 20-min drift is well inside the
      // 30-min full-marks window.
      final score = computeSleepScore(
        asleepMinutes: 480,
        goalMinutes: 480,
        efficiency: 0.95,
        deepMinutes: 110,
        remMinutes: 110,
        midSleepMinutesFromMidnight: 1430,
        avgMidSleepMinutesFromMidnight: 10,
      )!;
      expect(score.consistencyPoints, closeTo(score.consistencyMax, 0.001));
    });

    test('a goalMinutes of 0 falls back to the 8h default safely', () {
      final score = computeSleepScore(
        asleepMinutes: 480,
        goalMinutes: 0,
        efficiency: 0.90,
      );
      expect(score, isNotNull);
      expect(score!.durationPoints, closeTo(score.durationMax, 0.001));
    });

    test('total is always clamped to 0-100', () {
      final score = computeSleepScore(
        asleepMinutes: 1000,
        goalMinutes: 480,
        efficiency: 1.0,
        deepMinutes: 500,
        remMinutes: 500,
        midSleepMinutesFromMidnight: 180,
        avgMidSleepMinutesFromMidnight: 180,
      )!;
      expect(score.total, inInclusiveRange(0, 100));
    });
  });
}
