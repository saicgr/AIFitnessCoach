import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/core/utils/exercise_tracking_metric.dart';

void main() {
  group('resolveProfile — capability set', () {
    test('Sled Push = weight + distance (loaded carry fix)', () {
      final p = ExerciseTrackingMetric.resolveProfile(
          name: 'Sled Push', repsSpec: '1');
      expect(p.tracksWeight, isTrue);
      expect(p.tracksDistance, isTrue);
      expect(p.primary, 'distance');
    });

    test("Dumbbell Farmer's Carry = weight + distance", () {
      final p = ExerciseTrackingMetric.resolveProfile(
          name: "Dumbbell Farmer's Carry",
          equipment: 'Dumbbells',
          repsSpec: '40 m');
      expect(p.tracksWeight, isTrue);
      expect(p.tracksDistance, isTrue);
    });

    test('Bench Press = weight + reps', () {
      final p = ExerciseTrackingMetric.resolveProfile(
          name: 'Bench Press', equipment: 'Barbell', repsSpec: '8');
      expect(p.metricKeys, ['weight', 'reps']);
      expect(p.primary, 'reps');
    });

    test('Plank = time only', () {
      final p =
          ExerciseTrackingMetric.resolveProfile(name: 'Plank', repsSpec: '45s');
      expect(p.metricKeys, ['time']);
      expect(p.tracksWeight, isFalse);
    });

    test('Push-up = reps only (no load by default)', () {
      final p = ExerciseTrackingMetric.resolveProfile(
          name: 'Push-up', repsSpec: '12');
      expect(p.metricKeys, ['reps']);
      expect(p.tracksWeight, isFalse);
    });

    test('SkiErg = distance only — NOT a loaded carry', () {
      final p = ExerciseTrackingMetric.resolveProfile(
          name: 'SkiErg', repsSpec: '1000 m');
      expect(p.tracksDistance, isTrue);
      expect(p.tracksWeight, isFalse);
    });

    test('explicit backend metric_keys win over heuristic', () {
      final p = ExerciseTrackingMetric.resolveProfile(
          name: 'Box Jump', explicitKeys: ['reps', 'box_height']);
      expect(p.metricKeys, ['reps', 'box_height']);
      expect(p.primary, 'reps');
    });

    test('legacy resolve() shim unchanged for sled (still distance)', () {
      final m = ExerciseTrackingMetric.resolve(name: 'Sled Push', repsSpec: '1');
      expect(m, TrackingMetric.distance);
    });
  });
}
