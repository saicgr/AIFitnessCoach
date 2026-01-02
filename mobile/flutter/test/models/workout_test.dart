import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/data/models/workout.dart';
import 'package:fitwiz/data/models/exercise.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('Workout Model', () {
    group('fromJson', () {
      test('should create Workout from valid JSON', () {
        final json = JsonFixtures.workoutJson();
        final workout = Workout.fromJson(json);

        expect(workout.id, 'test-workout-id');
        expect(workout.userId, 'test-user-id');
        expect(workout.name, 'Test Workout');
        expect(workout.type, 'strength');
        expect(workout.difficulty, 'intermediate');
        expect(workout.isCompleted, false);
        expect(workout.durationMinutes, 45);
      });

      test('should handle null optional fields', () {
        final json = {'id': 'test-id'};
        final workout = Workout.fromJson(json);

        expect(workout.id, 'test-id');
        expect(workout.userId, isNull);
        expect(workout.name, isNull);
        expect(workout.type, isNull);
      });
    });

    group('toJson', () {
      test('should serialize Workout to JSON', () {
        final workout = TestFixtures.createWorkout();
        final json = workout.toJson();

        expect(json['id'], 'test-workout-id');
        expect(json['user_id'], 'test-user-id');
        expect(json['name'], 'Test Workout');
        expect(json['type'], 'strength');
        expect(json['difficulty'], 'intermediate');
      });
    });

    group('exercises', () {
      test('should parse exercises from JSON array', () {
        final workout = TestFixtures.createWorkout(
          exercisesJson: [
            {'name': 'Bench Press', 'sets': 3, 'reps': 10},
            {'name': 'Squats', 'sets': 4, 'reps': 8},
          ],
        );

        final exercises = workout.exercises;
        expect(exercises.length, 2);
        expect(exercises[0].name, 'Bench Press');
        expect(exercises[0].sets, 3);
        expect(exercises[0].reps, 10);
        expect(exercises[1].name, 'Squats');
      });

      test('should parse exercises from JSON string', () {
        final workout = TestFixtures.createWorkout(
          exercisesJson: '[{"name": "Deadlift", "sets": 3, "reps": 5}]',
        );

        final exercises = workout.exercises;
        expect(exercises.length, 1);
        expect(exercises[0].name, 'Deadlift');
      });

      test('should return empty list for null exercises', () {
        final workout = TestFixtures.createWorkout(exercisesJson: null);

        expect(workout.exercises, isEmpty);
      });

      test('should return empty list for invalid JSON string', () {
        final workout = TestFixtures.createWorkout(exercisesJson: 'invalid json');

        expect(workout.exercises, isEmpty);
      });

      test('should return empty list for non-list type', () {
        final workout = TestFixtures.createWorkout(exercisesJson: 123);

        expect(workout.exercises, isEmpty);
      });
    });

    group('exerciseCount', () {
      test('should return number of exercises', () {
        final workout = TestFixtures.createWorkout(
          exercisesJson: [
            {'name': 'Exercise 1'},
            {'name': 'Exercise 2'},
            {'name': 'Exercise 3'},
          ],
        );

        expect(workout.exerciseCount, 3);
      });

      test('should return 0 for no exercises', () {
        final workout = TestFixtures.createWorkout(exercisesJson: null);

        expect(workout.exerciseCount, 0);
      });
    });

    group('estimatedCalories', () {
      test('should calculate calories based on duration (6 cal/min)', () {
        final workout = TestFixtures.createWorkout(durationMinutes: 45);

        expect(workout.estimatedCalories, 270); // 45 * 6
      });

      test('should return 0 for null duration', () {
        final workout = TestFixtures.createWorkout(durationMinutes: null);

        expect(workout.estimatedCalories, 0);
      });
    });

    group('formattedDate', () {
      test('should format date as M/D/YYYY', () {
        final workout = TestFixtures.createWorkout(
          scheduledDate: '2025-01-15',
        );

        expect(workout.formattedDate, '1/15/2025');
      });

      test('should return empty string for null date', () {
        final workout = TestFixtures.createWorkout(scheduledDate: null);

        expect(workout.formattedDate, '');
      });

      test('should return original string for unparseable date', () {
        final workout = TestFixtures.createWorkout(scheduledDate: 'invalid-date');

        expect(workout.formattedDate, 'invalid-date');
      });
    });

    group('isToday', () {
      test('should return true for today\'s date', () {
        final today = DateTime.now().toIso8601String().split('T')[0];
        final workout = TestFixtures.createWorkout(scheduledDate: today);

        expect(workout.isToday, true);
      });

      test('should return false for different date', () {
        final yesterday = DateTime.now()
            .subtract(const Duration(days: 1))
            .toIso8601String()
            .split('T')[0];
        final workout = TestFixtures.createWorkout(scheduledDate: yesterday);

        expect(workout.isToday, false);
      });

      test('should return false for null date', () {
        final workout = TestFixtures.createWorkout(scheduledDate: null);

        expect(workout.isToday, false);
      });
    });

    group('primaryMuscles', () {
      test('should collect unique muscle groups from exercises', () {
        final workout = TestFixtures.createWorkout(
          exercisesJson: [
            {'name': 'Bench Press', 'primary_muscle': 'chest'},
            {'name': 'Incline Press', 'muscle_group': 'chest'},
            {'name': 'Lat Pulldown', 'primary_muscle': 'back'},
          ],
        );

        final muscles = workout.primaryMuscles;
        expect(muscles, containsAll(['chest', 'back']));
        expect(muscles.length, 2); // Unique values only
      });

      test('should return empty list when no exercises', () {
        final workout = TestFixtures.createWorkout(exercisesJson: null);

        expect(workout.primaryMuscles, isEmpty);
      });
    });

    group('equipmentNeeded', () {
      test('should collect unique equipment from exercises', () {
        final workout = TestFixtures.createWorkout(
          exercisesJson: [
            {'name': 'Bench Press', 'equipment': 'Barbell'},
            {'name': 'Dumbbell Curl', 'equipment': 'Dumbbells'},
            {'name': 'Squats', 'equipment': 'Barbell'},
          ],
        );

        final equipment = workout.equipmentNeeded;
        expect(equipment, containsAll(['Barbell', 'Dumbbells']));
        expect(equipment.length, 2);
      });

      test('should exclude bodyweight variations', () {
        final workout = TestFixtures.createWorkout(
          exercisesJson: [
            {'name': 'Push-ups', 'equipment': 'Bodyweight'},
            {'name': 'Pull-ups', 'equipment': 'body weight'},
            {'name': 'Dips', 'equipment': 'none'},
            {'name': 'Bench Press', 'equipment': 'Barbell'},
          ],
        );

        final equipment = workout.equipmentNeeded;
        expect(equipment, ['Barbell']);
        expect(equipment, isNot(contains('Bodyweight')));
      });

      test('should return empty list when all bodyweight exercises', () {
        final workout = TestFixtures.createWorkout(
          exercisesJson: [
            {'name': 'Push-ups', 'equipment': 'Bodyweight'},
            {'name': 'Squats', 'equipment': 'None'},
          ],
        );

        expect(workout.equipmentNeeded, isEmpty);
      });
    });

    group('copyWith', () {
      test('should create copy with updated fields', () {
        final workout = TestFixtures.createWorkout();
        final updatedWorkout = workout.copyWith(
          name: 'New Workout Name',
          isCompleted: true,
        );

        expect(updatedWorkout.id, workout.id);
        expect(updatedWorkout.name, 'New Workout Name');
        expect(updatedWorkout.isCompleted, true);
        expect(updatedWorkout.type, workout.type);
      });

      test('should preserve original values when not specified', () {
        final workout = TestFixtures.createWorkout();
        final copy = workout.copyWith();

        expect(copy.id, workout.id);
        expect(copy.userId, workout.userId);
        expect(copy.name, workout.name);
        expect(copy.type, workout.type);
      });
    });

    group('Equatable', () {
      test('should be equal when key properties match', () {
        final workout1 = TestFixtures.createWorkout();
        final workout2 = TestFixtures.createWorkout();

        expect(workout1, equals(workout2));
      });

      test('should not be equal when id differs', () {
        final workout1 = TestFixtures.createWorkout(id: 'id-1');
        final workout2 = TestFixtures.createWorkout(id: 'id-2');

        expect(workout1, isNot(equals(workout2)));
      });
    });
  });

  group('WorkoutExercise Model', () {
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
      });
    });

    group('name', () {
      test('should return nameValue when present', () {
        final exercise = TestFixtures.createExercise(nameValue: 'Squats');

        expect(exercise.name, 'Squats');
      });

      test('should return "Exercise" when nameValue is null', () {
        final exercise = WorkoutExercise(nameValue: null);

        expect(exercise.name, 'Exercise');
      });
    });

    group('setsRepsDisplay', () {
      test('should format sets x reps', () {
        final exercise = TestFixtures.createExercise(sets: 3, reps: 10);

        expect(exercise.setsRepsDisplay, '3 x 10');
      });

      test('should format duration for time-based exercises', () {
        final exercise = WorkoutExercise(
          sets: null,
          reps: null,
          durationSeconds: 90,
        );

        expect(exercise.setsRepsDisplay, '1m 30s');
      });

      test('should format minutes only when no remaining seconds', () {
        final exercise = WorkoutExercise(durationSeconds: 120);

        expect(exercise.setsRepsDisplay, '2m');
      });

      test('should format seconds only for short durations', () {
        final exercise = WorkoutExercise(durationSeconds: 45);

        expect(exercise.setsRepsDisplay, '45s');
      });

      test('should return empty string when no sets, reps, or duration', () {
        final exercise = WorkoutExercise();

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

      test('should return empty string for 0 rest', () {
        final exercise = TestFixtures.createExercise(restSeconds: 0);

        expect(exercise.restDisplay, '');
      });

      test('should return empty string for null rest', () {
        final exercise = WorkoutExercise(restSeconds: null);

        expect(exercise.restDisplay, '');
      });
    });

    group('weightDisplay', () {
      test('should format weight with kg unit', () {
        final exercise = TestFixtures.createExercise(weight: 100.0);

        expect(exercise.weightDisplay, '100 kg');
      });

      test('should format decimal weights', () {
        final exercise = TestFixtures.createExercise(weight: 67.5);

        expect(exercise.weightDisplay, '67.5 kg');
      });

      test('should return empty string for 0 weight', () {
        final exercise = TestFixtures.createExercise(weight: 0.0);

        expect(exercise.weightDisplay, '');
      });

      test('should return empty string for null weight', () {
        final exercise = WorkoutExercise(weight: null);

        expect(exercise.weightDisplay, '');
      });
    });

    group('copyWith', () {
      test('should create copy with updated fields', () {
        final exercise = TestFixtures.createExercise();
        final updated = exercise.copyWith(
          nameValue: 'New Exercise',
          sets: 5,
        );

        expect(updated.name, 'New Exercise');
        expect(updated.sets, 5);
        expect(updated.reps, exercise.reps);
      });
    });

    group('Equatable', () {
      test('should be equal when key properties match', () {
        final ex1 = TestFixtures.createExercise();
        final ex2 = TestFixtures.createExercise();

        expect(ex1, equals(ex2));
      });
    });
  });

  group('LibraryExercise Model', () {
    test('should create from JSON', () {
      final json = {
        'id': 'lib-exercise-id',
        'name': 'Barbell Squat',
        'body_part': 'legs',
        'equipment': 'Barbell',
        'target_muscle': 'quadriceps',
        'difficulty_level': 2,
        'category': 'compound',
        'instructions': 'Stand with feet shoulder-width apart. Lower your body.',
      };
      final exercise = LibraryExercise.fromJson(json);

      expect(exercise.id, 'lib-exercise-id');
      expect(exercise.name, 'Barbell Squat');
      expect(exercise.bodyPart, 'legs');
      expect(exercise.targetMuscle, 'quadriceps');
      expect(exercise.difficultyLevel, 2);
      expect(exercise.category, 'compound');
    });

    test('should return "Unknown Exercise" for null name', () {
      final exercise = LibraryExercise(nameValue: null);

      expect(exercise.name, 'Unknown Exercise');
    });

    test('should return muscle group from bodyPart or targetMuscle', () {
      final ex1 = LibraryExercise(bodyPart: 'chest', targetMuscle: 'pectorals');
      final ex2 = LibraryExercise(bodyPart: null, targetMuscle: 'biceps');

      expect(ex1.muscleGroup, 'chest');
      expect(ex2.muscleGroup, 'biceps');
    });

    test('should convert difficulty level to string', () {
      expect(LibraryExercise(difficultyLevel: 1).difficulty, 'Beginner');
      expect(LibraryExercise(difficultyLevel: 2).difficulty, 'Intermediate');
      expect(LibraryExercise(difficultyLevel: 3).difficulty, 'Advanced');
      expect(LibraryExercise(difficultyLevel: null).difficulty, isNull);
    });

    test('should normalize equipment list', () {
      final ex1 = LibraryExercise(equipmentValue: 'Barbell, Dumbbells');
      final ex2 = LibraryExercise(equipmentValue: 'None (Bodyweight)');

      expect(ex1.equipment, ['Barbell', 'Dumbbells']);
      expect(ex2.equipment, ['Bodyweight']);
    });

    test('should split instructions into list', () {
      final exercise = LibraryExercise(
        instructionsValue: '1. Stand straight. 2. Lower your body. 3. Push back up.',
      );

      expect(exercise.instructions, isNotEmpty);
    });
  });
}
