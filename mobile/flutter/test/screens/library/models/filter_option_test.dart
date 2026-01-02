import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/screens/library/models/filter_option.dart';

void main() {
  group('FilterOption', () {
    test('fromJson creates instance correctly', () {
      final json = {'name': 'Chest', 'count': 25};
      final option = FilterOption.fromJson(json);

      expect(option.name, 'Chest');
      expect(option.count, 25);
    });

    test('toJson serializes correctly', () {
      const option = FilterOption(name: 'Back', count: 30);
      final json = option.toJson();

      expect(json['name'], 'Back');
      expect(json['count'], 30);
    });

    test('equality works correctly', () {
      const option1 = FilterOption(name: 'Chest', count: 25);
      const option2 = FilterOption(name: 'Chest', count: 25);
      const option3 = FilterOption(name: 'Back', count: 25);

      expect(option1, equals(option2));
      expect(option1, isNot(equals(option3)));
    });

    test('hashCode is consistent with equality', () {
      const option1 = FilterOption(name: 'Chest', count: 25);
      const option2 = FilterOption(name: 'Chest', count: 25);

      expect(option1.hashCode, equals(option2.hashCode));
    });
  });

  group('ExerciseFilterOptions', () {
    test('fromJson parses complete response', () {
      final json = {
        'body_parts': [
          {'name': 'Chest', 'count': 25},
          {'name': 'Back', 'count': 30},
        ],
        'equipment': [
          {'name': 'Barbell', 'count': 50},
          {'name': 'Dumbbell', 'count': 75},
        ],
        'exercise_types': [
          {'name': 'Compound', 'count': 100},
        ],
        'goals': [
          {'name': 'Strength', 'count': 150},
        ],
        'suitable_for': [
          {'name': 'Beginners', 'count': 80},
        ],
        'avoid_if': [
          {'name': 'Lower back pain', 'count': 20},
        ],
        'total_exercises': 500,
      };

      final options = ExerciseFilterOptions.fromJson(json);

      expect(options.bodyParts.length, 2);
      expect(options.bodyParts[0].name, 'Chest');
      expect(options.equipment.length, 2);
      expect(options.exerciseTypes.length, 1);
      expect(options.goals.length, 1);
      expect(options.suitableFor.length, 1);
      expect(options.avoidIf.length, 1);
      expect(options.totalExercises, 500);
    });

    test('fromJson handles empty lists', () {
      final json = {
        'body_parts': [],
        'equipment': [],
        'exercise_types': [],
        'goals': [],
        'suitable_for': [],
        'avoid_if': [],
        'total_exercises': 0,
      };

      final options = ExerciseFilterOptions.fromJson(json);

      expect(options.bodyParts, isEmpty);
      expect(options.equipment, isEmpty);
      expect(options.totalExercises, 0);
    });

    test('fromJson handles missing fields', () {
      final json = <String, dynamic>{};

      final options = ExerciseFilterOptions.fromJson(json);

      expect(options.bodyParts, isEmpty);
      expect(options.totalExercises, 0);
    });

    test('toJson serializes correctly', () {
      const options = ExerciseFilterOptions(
        bodyParts: [FilterOption(name: 'Chest', count: 25)],
        equipment: [FilterOption(name: 'Barbell', count: 50)],
        exerciseTypes: [],
        goals: [],
        suitableFor: [],
        avoidIf: [],
        totalExercises: 75,
      );

      final json = options.toJson();

      expect(json['body_parts'], hasLength(1));
      expect(json['equipment'], hasLength(1));
      expect(json['total_exercises'], 75);
    });

    test('empty constant is correct', () {
      const empty = ExerciseFilterOptions.empty;

      expect(empty.bodyParts, isEmpty);
      expect(empty.equipment, isEmpty);
      expect(empty.exerciseTypes, isEmpty);
      expect(empty.goals, isEmpty);
      expect(empty.suitableFor, isEmpty);
      expect(empty.avoidIf, isEmpty);
      expect(empty.totalExercises, 0);
    });
  });
}
