import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/screens/workout/widgets/hr_recovery_policy.dart';

void main() {
  group('HrRecoveryPolicy.recoveryTarget', () {
    test('Karvonen reserve when age + resting HR known', () {
      // age 30 -> maxHr 187; 60 + 0.60*(187-60) = 136.2 -> 136
      final t = HrRecoveryPolicy.recoveryTarget(age: 30, restingHr: 60);
      expect(t, isNotNull);
      expect(t!.method, HrRecoveryMethod.reserve);
      expect(t.targetBpm, 136);
    });

    test('zone-based when age known but no resting HR', () {
      // age 30 -> maxHr 187; 0.70*187 = 130.9 -> 131
      final t = HrRecoveryPolicy.recoveryTarget(age: 30);
      expect(t, isNotNull);
      expect(t!.method, HrRecoveryMethod.zone);
      expect(t.targetBpm, 131);
    });

    test('relative drop when only live HR available (peak + lull)', () {
      // max(peak-35, lull+15) = max(130, 135) = 135
      final t =
          HrRecoveryPolicy.recoveryTarget(peakHr: 165, minHrThisRest: 120);
      expect(t, isNotNull);
      expect(t!.method, HrRecoveryMethod.relative);
      expect(t.targetBpm, 135);
    });

    test('relative drop with peak only', () {
      // both branches collapse to peak-35 = 125
      final t = HrRecoveryPolicy.recoveryTarget(peakHr: 160);
      expect(t!.targetBpm, 125);
      expect(t.method, HrRecoveryMethod.relative);
    });

    test('reserve preferred over zone and relative when all present', () {
      final t = HrRecoveryPolicy.recoveryTarget(
          age: 30, restingHr: 60, peakHr: 165, minHrThisRest: 120);
      expect(t!.method, HrRecoveryMethod.reserve);
    });

    test('not computable -> null (caller leaves timer un-gated)', () {
      expect(HrRecoveryPolicy.recoveryTarget(), isNull);
      expect(HrRecoveryPolicy.recoveryTarget(restingHr: 60), isNull);
      expect(HrRecoveryPolicy.recoveryTarget(minHrThisRest: 100), isNull);
    });

    test('target clamped to sane floor/ceiling', () {
      // Absurd peak clamps to the ceiling.
      final hi = HrRecoveryPolicy.recoveryTarget(peakHr: 260);
      expect(hi!.targetBpm, HrRecoveryPolicy.maxTargetBpm);
      // Low zone target floors at minTargetBpm.
      final lo = HrRecoveryPolicy.recoveryTarget(peakHr: 90);
      expect(lo!.targetBpm, greaterThanOrEqualTo(HrRecoveryPolicy.minTargetBpm));
    });
  });

  group('HrRecoveryPolicy.isRecovered', () {
    test('recovered at or below target', () {
      expect(HrRecoveryPolicy.isRecovered(130, 136), isTrue);
      expect(HrRecoveryPolicy.isRecovered(136, 136), isTrue);
      expect(HrRecoveryPolicy.isRecovered(140, 136), isFalse);
    });
  });

  group('HrRecoveryPolicy.maxHrForAge', () {
    test('Tanaka formula', () {
      expect(HrRecoveryPolicy.maxHrForAge(30), 187); // 208 - 21
      expect(HrRecoveryPolicy.maxHrForAge(40), 180); // 208 - 28
    });
  });
}
