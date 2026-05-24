import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/services/live_pr_detector.dart';

void main() {
  group('LivePrDetector.brzycki1rm', () {
    test('returns weight exactly at 1 rep', () {
      // Brzycki: 1RM = w / (1.0278 - 0.0278 * 1) = w / 1.0 = w
      expect(
        LivePrDetector.brzycki1rm(weightKg: 100, reps: 1),
        closeTo(100.0, 1e-9),
      );
    });

    test('scales correctly at 5 reps (~12.5% over)', () {
      // 1.0278 - 0.0278*5 = 0.8888 → 100 / 0.8888 ≈ 112.511
      final v = LivePrDetector.brzycki1rm(weightKg: 100, reps: 5);
      expect(v, closeTo(112.511, 0.01));
    });

    test('returns 0 for non-positive weight', () {
      expect(LivePrDetector.brzycki1rm(weightKg: 0, reps: 5), 0);
      expect(LivePrDetector.brzycki1rm(weightKg: -10, reps: 5), 0);
    });

    test('returns 0 for non-positive reps', () {
      expect(LivePrDetector.brzycki1rm(weightKg: 100, reps: 0), 0);
      expect(LivePrDetector.brzycki1rm(weightKg: 100, reps: -1), 0);
    });
  });

  group('LivePrDetector.evaluateSet', () {
    late LivePrDetector det;
    setUp(() => det = LivePrDetector());

    test('suppresses when previousAllTime1rmKg is null (first set ever)', () {
      final result = det.evaluateSet(
        exerciseId: 'bench',
        weightKg: 200,
        reps: 5,
        previousAllTime1rmKg: null,
      );
      expect(result, isNull);
      expect(det.sessionFiredPrs, isEmpty);
    });

    test('suppresses when weight is 0 (bodyweight exercise)', () {
      final result = det.evaluateSet(
        exerciseId: 'pushup',
        weightKg: 0,
        reps: 20,
        previousAllTime1rmKg: 50,
      );
      expect(result, isNull);
    });

    test('suppresses when computed 1RM equals previous (not strictly greater)', () {
      // 100 @ 1 rep == previous 100
      final result = det.evaluateSet(
        exerciseId: 'bench',
        weightKg: 100,
        reps: 1,
        previousAllTime1rmKg: 100,
      );
      expect(result, isNull);
    });

    test('fires when new 1RM beats previous all-time', () {
      final result = det.evaluateSet(
        exerciseId: 'bench',
        weightKg: 105,
        reps: 1,
        previousAllTime1rmKg: 100,
      );
      expect(result, isNotNull);
      expect(result!.exerciseId, 'bench');
      expect(result.newEstimated1rmKg, closeTo(105.0, 1e-9));
      expect(result.improvementKg, closeTo(5.0, 1e-9));
      expect(result.improvementPercent, closeTo(5.0, 1e-9));
      expect(det.sessionFiredPrs['bench'], closeTo(105.0, 1e-9));
    });

    test('does NOT re-fire for a weaker subsequent set in same session', () {
      // First set establishes session PR.
      final first = det.evaluateSet(
        exerciseId: 'bench',
        weightKg: 110,
        reps: 1,
        previousAllTime1rmKg: 100,
      );
      expect(first, isNotNull);

      // Second set: still beats baseline (100) but below session-best (110).
      final second = det.evaluateSet(
        exerciseId: 'bench',
        weightKg: 105,
        reps: 1,
        previousAllTime1rmKg: 100,
      );
      expect(second, isNull, reason: 'session-best already higher → no re-fire');
    });

    test('re-fires when subsequent set surpasses session-best', () {
      det.evaluateSet(
        exerciseId: 'bench',
        weightKg: 105,
        reps: 1,
        previousAllTime1rmKg: 100,
      );
      final upgrade = det.evaluateSet(
        exerciseId: 'bench',
        weightKg: 115,
        reps: 1,
        previousAllTime1rmKg: 100,
      );
      expect(upgrade, isNotNull);
      expect(upgrade!.newEstimated1rmKg, closeTo(115.0, 1e-9));
      expect(det.sessionFiredPrs['bench'], closeTo(115.0, 1e-9));
    });

    test('multi-exercise isolation — bench PR does not affect squat eval', () {
      det.evaluateSet(
        exerciseId: 'bench',
        weightKg: 120,
        reps: 1,
        previousAllTime1rmKg: 100,
      );
      // Squat with its own baseline should still fire independently.
      final squat = det.evaluateSet(
        exerciseId: 'squat',
        weightKg: 160,
        reps: 1,
        previousAllTime1rmKg: 150,
      );
      expect(squat, isNotNull);
      expect(squat!.exerciseId, 'squat');
      expect(det.sessionFiredPrs.length, 2);
    });

    test('higher-rep PR via Brzycki — 5 reps @ 100kg beats 110kg @ 1', () {
      // 5 @ 100 → ~112.5 1RM, beats baseline 110.
      final r = det.evaluateSet(
        exerciseId: 'bench',
        weightKg: 100,
        reps: 5,
        previousAllTime1rmKg: 110,
      );
      expect(r, isNotNull);
      expect(r!.newEstimated1rmKg, greaterThan(110));
    });
  });

  group('LivePrDetector.retractIfBelow', () {
    test('retracts session PR when no remaining set beats the baseline', () {
      final det = LivePrDetector();
      det.evaluateSet(
        exerciseId: 'bench',
        weightKg: 115,
        reps: 1,
        previousAllTime1rmKg: 100,
      );
      expect(det.sessionFiredPrs['bench'], isNotNull);

      // User edited that set down to 95kg @ 1 (no longer a PR), and that
      // is now their only logged set for the exercise.
      det.retractIfBelow(
        exerciseId: 'bench',
        allLoggedSets: [(weightKg: 95, reps: 1)],
        previousAllTime1rmKg: 100,
      );
      expect(det.sessionFiredPrs.containsKey('bench'), isFalse,
          reason: 'edit-down should retract fired flag');
    });

    test('pins session-best to highest still-valid set after edit', () {
      final det = LivePrDetector();
      det.evaluateSet(
        exerciseId: 'bench',
        weightKg: 120,
        reps: 1,
        previousAllTime1rmKg: 100,
      );

      // User had logged 120 and 105; edits 120 down to 95. Remaining set 105
      // still beats baseline 100, so session-best should be pinned at 105.
      det.retractIfBelow(
        exerciseId: 'bench',
        allLoggedSets: [
          (weightKg: 95, reps: 1),
          (weightKg: 105, reps: 1),
        ],
        previousAllTime1rmKg: 100,
      );
      expect(det.sessionFiredPrs['bench'], closeTo(105.0, 1e-9));

      // A new set at 102 should NOT fire (below pinned 105).
      final r = det.evaluateSet(
        exerciseId: 'bench',
        weightKg: 102,
        reps: 1,
        previousAllTime1rmKg: 100,
      );
      expect(r, isNull);
    });

    test('retract is a no-op for unknown exercise', () {
      final det = LivePrDetector();
      expect(
        () => det.retractIfBelow(
          exerciseId: 'unseen',
          allLoggedSets: const [],
          previousAllTime1rmKg: 100,
        ),
        returnsNormally,
      );
      expect(det.sessionFiredPrs.containsKey('unseen'), isFalse);
    });

    test('null baseline clears any session memory for that exercise', () {
      final det = LivePrDetector();
      // Force-set memory via a successful eval, then drop baseline.
      det.evaluateSet(
        exerciseId: 'bench',
        weightKg: 110,
        reps: 1,
        previousAllTime1rmKg: 100,
      );
      det.retractIfBelow(
        exerciseId: 'bench',
        allLoggedSets: const [],
        previousAllTime1rmKg: null,
      );
      expect(det.sessionFiredPrs.containsKey('bench'), isFalse);
    });
  });

  group('LivePrDetector.resetSession', () {
    test('clears all per-session state', () {
      final det = LivePrDetector();
      det.evaluateSet(
        exerciseId: 'bench',
        weightKg: 110,
        reps: 1,
        previousAllTime1rmKg: 100,
      );
      det.evaluateSet(
        exerciseId: 'squat',
        weightKg: 160,
        reps: 1,
        previousAllTime1rmKg: 150,
      );
      expect(det.sessionFiredPrs.length, 2);

      det.resetSession();
      expect(det.sessionFiredPrs, isEmpty);

      // After reset, a set that previously wouldn't re-fire CAN fire again
      // (since session memory is gone).
      final r = det.evaluateSet(
        exerciseId: 'bench',
        weightKg: 105,
        reps: 1,
        previousAllTime1rmKg: 100,
      );
      expect(r, isNotNull);
    });
  });

  group('LivePrDetector unit conversion helpers', () {
    test('kgToLb round-trip', () {
      expect(LivePrDetector.lbToKg(LivePrDetector.kgToLb(100)),
          closeTo(100.0, 1e-6));
    });
  });
}
