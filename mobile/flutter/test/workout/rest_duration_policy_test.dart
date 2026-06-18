import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/screens/workout/widgets/rest_duration_policy.dart';

void main() {
  group('RestDurationPolicy', () {
    test('prescribed rest wins', () {
      expect(
          RestDurationPolicy.resolveSeconds(
              prescribedRestSeconds: 150, rir: 0),
          150);
    });
    test('RIR ladder', () {
      expect(RestDurationPolicy.resolveSeconds(rir: 0), 180);
      expect(RestDurationPolicy.resolveSeconds(rir: 1), 120);
      expect(RestDurationPolicy.resolveSeconds(rir: 2), 120);
      expect(RestDurationPolicy.resolveSeconds(rir: 3), 90);
      expect(RestDurationPolicy.resolveSeconds(rir: 5), 90);
    });
    test('RPE ladder when no RIR', () {
      expect(RestDurationPolicy.resolveSeconds(rpe: 10), 180);
      expect(RestDurationPolicy.resolveSeconds(rpe: 8), 120);
      expect(RestDurationPolicy.resolveSeconds(rpe: 6), 90);
    });
    test('between exercises ignores effort', () {
      expect(
          RestDurationPolicy.resolveSeconds(rir: 0, betweenExercises: true),
          120);
    });
    test('default base', () {
      expect(RestDurationPolicy.resolveSeconds(), 90);
    });
    test('reason text', () {
      expect(RestDurationPolicy.reasonFor(rir: 0), contains('Near failure'));
      expect(RestDurationPolicy.reasonFor(prescribedRestSeconds: 90), isNull);
    });
  });
}
