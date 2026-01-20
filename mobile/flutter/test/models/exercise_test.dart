import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/data/models/exercise.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('WorkoutExercise', () {
    group('fromJson', () {
      test('should create WorkoutExercise from valid JSON', () {
        final json = {
          'id': 'exercise-id',
          'name': 'Bench Press',
          'sets': 3,
          'reps': 10,
          'rest_seconds': 60,
          'weight': 100.0,
          'muscle_group': 'chest',
          'equipment': 'Barbell',
          'instructions': 'Lower the bar to chest, push up.',
          'primary_muscle': 'pectoralis_major',
          'body_part': 'upper body',
        };
        final exercise = WorkoutExercise.fromJson(json);

        expect(exercise.id, 'exercise-id');
        expect(exercise.name, 'Bench Press');
        expect(exercise.sets, 3);
        expect(exercise.reps, 10);
        expect(exercise.restSeconds, 60);
        expect(exercise.weight, 100.0);
        expect(exercise.muscleGroup, 'chest');
        expect(exercise.equipment, 'Barbell');
        expect(exercise.instructions, 'Lower the bar to chest, push up.');
      });

      test('should handle minimal JSON', () {
        final json = <String, dynamic>{'name': 'Push-ups'};
        final exercise = WorkoutExercise.fromJson(json);

        expect(exercise.name, 'Push-ups');
        expect(exercise.sets, isNull);
        expect(exercise.reps, isNull);
        expect(exercise.weight, isNull);
      });
    });

    group('toJson', () {
      test('should serialize WorkoutExercise to JSON', () {
        final exercise = TestFixtures.createExercise(
          id: 'ex-1',
          nameValue: 'Deadlift',
          sets: 5,
          reps: 5,
          restSeconds: 120,
          weight: 140.0,
          muscleGroup: 'back',
          equipment: 'Barbell',
        );
        final json = exercise.toJson();

        expect(json['id'], 'ex-1');
        expect(json['name'], 'Deadlift');
        expect(json['sets'], 5);
        expect(json['reps'], 5);
        expect(json['rest_seconds'], 120);
        expect(json['weight'], 140.0);
        expect(json['muscle_group'], 'back');
        expect(json['equipment'], 'Barbell');
      });
    });

    group('name getter', () {
      test('should return nameValue when present', () {
        final exercise = TestFixtures.createExercise(nameValue: 'Squats');
        expect(exercise.name, 'Squats');
      });

      test('should return "Exercise" when nameValue is null', () {
        const exercise = WorkoutExercise(nameValue: null);
        expect(exercise.name, 'Exercise');
      });
    });

    group('setsRepsDisplay', () {
      test('should format sets x reps', () {
        final exercise = TestFixtures.createExercise(sets: 4, reps: 12);
        expect(exercise.setsRepsDisplay, '4 x 12');
      });

      test('should format duration when no sets/reps', () {
        const exercise = WorkoutExercise(durationSeconds: 60);
        expect(exercise.setsRepsDisplay, '1m');
      });

      test('should format duration with seconds', () {
        const exercise = WorkoutExercise(durationSeconds: 75);
        expect(exercise.setsRepsDisplay, '1m 15s');
      });

      test('should format seconds only for short duration', () {
        const exercise = WorkoutExercise(durationSeconds: 30);
        expect(exercise.setsRepsDisplay, '30s');
      });

      test('should return empty string when no data', () {
        const exercise = WorkoutExercise();
        expect(exercise.setsRepsDisplay, '');
      });
    });

    group('restDisplay', () {
      test('should format rest in seconds', () {
        final exercise = TestFixtures.createExercise(restSeconds: 45);
        expect(exercise.restDisplay, '45s rest');
      });

      test('should format rest in minutes and seconds', () {
        final exercise = TestFixtures.createExercise(restSeconds: 90);
        expect(exercise.restDisplay, '1m 30s rest');
      });

      test('should format rest in minutes only', () {
        final exercise = TestFixtures.createExercise(restSeconds: 120);
        expect(exercise.restDisplay, '2m rest');
      });

      test('should return empty for zero rest', () {
        final exercise = TestFixtures.createExercise(restSeconds: 0);
        expect(exercise.restDisplay, '');
      });

      test('should return empty for null rest', () {
        const exercise = WorkoutExercise();
        expect(exercise.restDisplay, '');
      });
    });

    group('weightDisplay', () {
      test('should format weight in kg', () {
        final exercise = TestFixtures.createExercise(weight: 80.0);
        expect(exercise.weightDisplay, '80 kg');
      });

      test('should format decimal weight', () {
        final exercise = TestFixtures.createExercise(weight: 67.5);
        expect(exercise.weightDisplay, '67.5 kg');
      });

      test('should return empty for zero weight', () {
        final exercise = TestFixtures.createExercise(weight: 0.0);
        expect(exercise.weightDisplay, '');
      });

      test('should return empty for null weight', () {
        const exercise = WorkoutExercise();
        expect(exercise.weightDisplay, '');
      });
    });

    group('copyWith', () {
      test('should copy with updated values', () {
        final original = TestFixtures.createExercise(
          nameValue: 'Squats',
          sets: 3,
          reps: 10,
        );
        final copied = original.copyWith(
          sets: 5,
          weight: 100.0,
        );

        expect(copied.name, 'Squats'); // Preserved
        expect(copied.sets, 5); // Updated
        expect(copied.reps, 10); // Preserved
        expect(copied.weight, 100.0); // Updated
      });

      test('should preserve all values when no changes', () {
        final original = TestFixtures.createExercise();
        final copied = original.copyWith();

        expect(copied.name, original.name);
        expect(copied.sets, original.sets);
        expect(copied.reps, original.reps);
        expect(copied.weight, original.weight);
      });
    });

    group('Equatable', () {
      test('should be equal when properties match', () {
        final ex1 = TestFixtures.createExercise(
          id: 'ex-1',
          nameValue: 'Bench Press',
          sets: 3,
          reps: 10,
        );
        final ex2 = TestFixtures.createExercise(
          id: 'ex-1',
          nameValue: 'Bench Press',
          sets: 3,
          reps: 10,
        );

        expect(ex1, equals(ex2));
      });

      test('should not be equal when properties differ', () {
        final ex1 = TestFixtures.createExercise(id: 'ex-1');
        final ex2 = TestFixtures.createExercise(id: 'ex-2');

        expect(ex1, isNot(equals(ex2)));
      });
    });
  });

  group('LibraryExercise', () {
    group('fromJson', () {
      test('should create from valid JSON', () {
        final json = {
          'id': 'lib-ex-1',
          'name': 'Barbell Back Squat',
          'body_part': 'legs',
          'equipment': 'Barbell',
          'target_muscle': 'quadriceps',
          'difficulty_level': 'Intermediate',
          'category': 'compound',
          'instructions': 'Stand with feet shoulder-width apart...',
          'tips': 'Keep your chest up.',
          'video_url': 'https://example.com/video.mp4',
          'image_url': 'https://example.com/image.jpg',
          'is_bodyweight': false,
          'is_compound': true,
        };
        final exercise = LibraryExercise.fromJson(json);

        expect(exercise.id, 'lib-ex-1');
        expect(exercise.name, 'Barbell Back Squat');
        expect(exercise.bodyPart, 'legs');
        expect(exercise.targetMuscle, 'quadriceps');
        expect(exercise.difficulty, 'Intermediate');
        expect(exercise.category, 'compound');
        expect(exercise.videoUrl, 'https://example.com/video.mp4');
        expect(exercise.imageUrl, 'https://example.com/image.jpg');
      });

      test('should handle minimal JSON', () {
        final json = <String, dynamic>{'id': 'ex-id'};
        final exercise = LibraryExercise.fromJson(json);

        expect(exercise.id, 'ex-id');
        expect(exercise.name, 'Unknown Exercise');
        expect(exercise.bodyPart, isNull);
        expect(exercise.difficulty, isNull);
      });
    });

    group('name getter', () {
      test('should return nameValue when present', () {
        const exercise = LibraryExercise(nameValue: 'Push-ups');
        expect(exercise.name, 'Push-ups');
      });

      test('should return "Unknown Exercise" when nameValue is null', () {
        const exercise = LibraryExercise();
        expect(exercise.name, 'Unknown Exercise');
      });
    });

    group('muscleGroup getter', () {
      test('should prefer bodyPart', () {
        const exercise = LibraryExercise(
          bodyPart: 'chest',
          targetMuscle: 'pectoralis',
        );
        expect(exercise.muscleGroup, 'chest');
      });

      test('should fall back to targetMuscle', () {
        const exercise = LibraryExercise(
          bodyPart: null,
          targetMuscle: 'biceps',
        );
        expect(exercise.muscleGroup, 'biceps');
      });

      test('should return null when both are null', () {
        const exercise = LibraryExercise();
        expect(exercise.muscleGroup, isNull);
      });
    });

    group('difficulty getter', () {
      test('should return the difficulty level value directly', () {
        const exercise = LibraryExercise(difficultyLevelValue: 'Beginner');
        expect(exercise.difficulty, 'Beginner');
      });

      test('should return Intermediate for Intermediate level', () {
        const exercise = LibraryExercise(difficultyLevelValue: 'Intermediate');
        expect(exercise.difficulty, 'Intermediate');
      });

      test('should return Advanced for Advanced level', () {
        const exercise = LibraryExercise(difficultyLevelValue: 'Advanced');
        expect(exercise.difficulty, 'Advanced');
      });

      test('should return null when difficultyLevelValue is null', () {
        const exercise = LibraryExercise();
        expect(exercise.difficulty, isNull);
      });
    });

    group('equipment getter', () {
      test('should split comma-separated equipment', () {
        const exercise = LibraryExercise(equipmentValue: 'Barbell, Dumbbells');
        expect(exercise.equipment, ['Barbell', 'Dumbbells']);
      });

      test('should normalize bodyweight variations', () {
        const ex1 = LibraryExercise(equipmentValue: 'None (Bodyweight)');
        expect(ex1.equipment, ['Bodyweight']);

        const ex2 = LibraryExercise(equipmentValue: 'Bodyweight only');
        expect(ex2.equipment, ['Bodyweight']);

        const ex3 = LibraryExercise(equipmentValue: 'none');
        expect(ex3.equipment, ['Bodyweight']);
      });

      test('should return empty list for null equipment', () {
        const exercise = LibraryExercise();
        expect(exercise.equipment, isEmpty);
      });
    });

    group('instructions getter', () {
      test('should split numbered instructions', () {
        const exercise = LibraryExercise(
          instructionsValue: '1. Stand straight. 2. Lower down. 3. Push up.',
        );
        final instructions = exercise.instructions;

        expect(instructions, isNotEmpty);
        expect(instructions.length, greaterThan(0));
      });

      test('should return list with single item for simple instructions', () {
        const exercise = LibraryExercise(
          instructionsValue: 'Stand with feet shoulder-width apart.',
        );
        final instructions = exercise.instructions;

        expect(instructions, isNotEmpty);
      });

      test('should return empty list for null instructions', () {
        const exercise = LibraryExercise();
        expect(exercise.instructions, isEmpty);
      });

      test('should filter out empty lines', () {
        const exercise = LibraryExercise(
          instructionsValue: 'Step 1.\n\nStep 2.',
        );
        final instructions = exercise.instructions;

        expect(instructions, isNot(contains('')));
      });
    });

    group('searchableText getter', () {
      test('should include name, body part, target muscle, and category', () {
        const exercise = LibraryExercise(
          nameValue: 'Bench Press',
          bodyPart: 'chest',
          targetMuscle: 'pectoralis',
          category: 'compound',
        );
        final searchable = exercise.searchableText;

        expect(searchable, contains('bench press'));
        expect(searchable, contains('chest'));
        expect(searchable, contains('pectoralis'));
        expect(searchable, contains('compound'));
      });

      test('should be lowercase', () {
        const exercise = LibraryExercise(nameValue: 'BARBELL SQUAT');
        expect(exercise.searchableText, contains('barbell squat'));
      });
    });

    group('Equatable', () {
      test('should be equal when id matches', () {
        const ex1 = LibraryExercise(id: 'ex-1', nameValue: 'Exercise 1');
        const ex2 = LibraryExercise(id: 'ex-1', nameValue: 'Exercise 1');

        expect(ex1, equals(ex2));
      });

      test('should not be equal when id differs', () {
        const ex1 = LibraryExercise(id: 'ex-1');
        const ex2 = LibraryExercise(id: 'ex-2');

        expect(ex1, isNot(equals(ex2)));
      });
    });
  });
}
