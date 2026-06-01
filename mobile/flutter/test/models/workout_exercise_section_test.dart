import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/data/models/exercise.dart';

void main() {
  group('WorkoutExercise.section (hand-maintained codegen field)', () {
    test('parses section from JSON', () {
      final ex = WorkoutExercise.fromJson({
        'name': 'Hay Bale Swing',
        'sets': 4,
        'reps': 15,
        'section': 'main',
      });
      expect(ex.section, 'main');
      expect(ex.nameValue, 'Hay Bale Swing');
    });

    test('section is null when absent (back-compat with library workouts)', () {
      final ex = WorkoutExercise.fromJson({'name': 'Squat', 'sets': 3});
      expect(ex.section, isNull);
    });

    test('round-trips through toJson', () {
      final ex = WorkoutExercise.fromJson({
        'name': 'Arm Circles',
        'section': 'warmup',
      });
      final json = ex.toJson();
      expect(json['section'], 'warmup');
      final back = WorkoutExercise.fromJson(json);
      expect(back.section, 'warmup');
    });

    test('copyWith preserves and overrides section', () {
      final ex = WorkoutExercise.fromJson({'name': 'Fold', 'section': 'cooldown'});
      expect(ex.copyWith().section, 'cooldown'); // preserved
      expect(ex.copyWith(section: 'main').section, 'main'); // overridden
    });

    test('emoji parses + round-trips (for AI-authored exercises)', () {
      final ex = WorkoutExercise.fromJson({
        'name': 'Hay Bale Swing',
        'section': 'main',
        'emoji': '🦵',
      });
      expect(ex.emoji, '🦵');
      expect(WorkoutExercise.fromJson(ex.toJson()).emoji, '🦵');
      // null for library exercises
      expect(WorkoutExercise.fromJson({'name': 'Squat'}).emoji, isNull);
    });
  });
}
