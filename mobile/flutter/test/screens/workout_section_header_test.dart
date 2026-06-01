import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/data/models/exercise.dart';
import 'package:fitwiz/screens/workout/workout_detail_screen.dart';

WorkoutExercise _ex(String name, String? section) =>
    WorkoutExercise(nameValue: name, section: section);

void main() {
  group('sectionHeaderForIndex', () {
    test('labels only the first exercise of each section (AI-authored)', () {
      final list = [
        _ex('Arm Circles', 'warmup'),
        _ex('Leg Swings', 'warmup'),
        _ex('Hay Bale Squat', 'main'),
        _ex('Hay Bale Swing', 'main'),
        _ex('Hay Bale Press', 'main'),
        _ex('Forward Fold', 'cooldown'),
      ];
      expect(sectionHeaderForIndex(list, 0), 'Warm Up');
      expect(sectionHeaderForIndex(list, 1), isNull);
      expect(sectionHeaderForIndex(list, 2), 'Main Circuit');
      expect(sectionHeaderForIndex(list, 3), isNull);
      expect(sectionHeaderForIndex(list, 4), isNull);
      expect(sectionHeaderForIndex(list, 5), 'Cool Down');
    });

    test('library/legacy workout (all sections null) shows no headers', () {
      final list = [_ex('Squat', null), _ex('Bench', null), _ex('Row', null)];
      for (var i = 0; i < list.length; i++) {
        expect(sectionHeaderForIndex(list, i), isNull);
      }
    });

    test('single-section workout shows no headers', () {
      final list = [_ex('A', 'main'), _ex('B', 'main')];
      expect(sectionHeaderForIndex(list, 0), isNull);
      expect(sectionHeaderForIndex(list, 1), isNull);
    });

    test('handles snake_case + unknown section values', () {
      final list = [_ex('A', 'warm_up'), _ex('B', 'finisher')];
      expect(sectionHeaderForIndex(list, 0), 'Warm Up');
      expect(sectionHeaderForIndex(list, 1), 'Finisher'); // title-cased fallback
    });

    test('out-of-range index returns null (no crash)', () {
      final list = [_ex('A', 'main'), _ex('B', 'cooldown')];
      expect(sectionHeaderForIndex(list, -1), isNull);
      expect(sectionHeaderForIndex(list, 9), isNull);
    });
  });
}
