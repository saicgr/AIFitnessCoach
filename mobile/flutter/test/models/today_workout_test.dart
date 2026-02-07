import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/data/models/today_workout.dart';
import 'package:fitwiz/data/models/exercise.dart';

void main() {
  group('TodayWorkoutSummary', () {
    group('fromJson', () {
      test('should create from valid JSON with exercises', () {
        final json = {
          'id': 'workout-1',
          'name': 'Upper Body Strength',
          'type': 'strength',
          'difficulty': 'intermediate',
          'duration_minutes': 45,
          'duration_minutes_min': 40,
          'duration_minutes_max': 50,
          'exercise_count': 6,
          'primary_muscles': ['chest', 'shoulders', 'triceps'],
          'scheduled_date': '2026-02-07',
          'is_today': true,
          'is_completed': false,
          'exercises': [
            {'name': 'Bench Press', 'sets': 3, 'reps': 10},
            {'name': 'Shoulder Press', 'sets': 3, 'reps': 8},
          ],
        };
        final summary = TodayWorkoutSummary.fromJson(json);

        expect(summary.id, 'workout-1');
        expect(summary.name, 'Upper Body Strength');
        expect(summary.type, 'strength');
        expect(summary.difficulty, 'intermediate');
        expect(summary.durationMinutes, 45);
        expect(summary.durationMinutesMin, 40);
        expect(summary.durationMinutesMax, 50);
        expect(summary.exerciseCount, 6);
        expect(summary.primaryMuscles, ['chest', 'shoulders', 'triceps']);
        expect(summary.scheduledDate, '2026-02-07');
        expect(summary.isToday, true);
        expect(summary.isCompleted, false);
        expect(summary.exercises.length, 2);
        expect(summary.exercises[0].name, 'Bench Press');
      });

      test('should handle missing optional fields with defaults', () {
        final json = <String, dynamic>{};
        final summary = TodayWorkoutSummary.fromJson(json);

        expect(summary.id, '');
        expect(summary.name, 'Workout');
        expect(summary.type, 'strength');
        expect(summary.difficulty, 'medium');
        expect(summary.durationMinutes, 45);
        expect(summary.durationMinutesMin, isNull);
        expect(summary.durationMinutesMax, isNull);
        expect(summary.exerciseCount, 0);
        expect(summary.primaryMuscles, isEmpty);
        expect(summary.scheduledDate, '');
        expect(summary.isToday, false);
        expect(summary.isCompleted, false);
        expect(summary.exercises, isEmpty);
      });

      test('should handle null exercises array', () {
        final json = {
          'id': 'w-1',
          'exercises': null,
        };
        final summary = TodayWorkoutSummary.fromJson(json);

        expect(summary.exercises, isEmpty);
      });
    });

    group('toJson', () {
      test('should serialize and deserialize round-trip', () {
        final original = TodayWorkoutSummary.fromJson({
          'id': 'w-1',
          'name': 'Leg Day',
          'type': 'strength',
          'difficulty': 'hard',
          'duration_minutes': 60,
          'exercise_count': 5,
          'primary_muscles': ['quads', 'hamstrings'],
          'scheduled_date': '2026-02-07',
          'is_today': true,
          'is_completed': false,
          'exercises': [
            {'name': 'Squat', 'sets': 4, 'reps': 8},
          ],
        });
        final json = original.toJson();
        final restored = TodayWorkoutSummary.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.name, original.name);
        expect(restored.type, original.type);
        expect(restored.durationMinutes, original.durationMinutes);
        expect(restored.exerciseCount, original.exerciseCount);
        expect(restored.primaryMuscles, original.primaryMuscles);
      });
    });

    group('formattedDurationShort', () {
      test('should show range when min and max differ', () {
        final summary = TodayWorkoutSummary.fromJson({
          'id': 'w-1',
          'duration_minutes': 45,
          'duration_minutes_min': 40,
          'duration_minutes_max': 55,
        });

        expect(summary.formattedDurationShort, '40-55m');
      });

      test('should show single value when min equals max', () {
        final summary = TodayWorkoutSummary.fromJson({
          'id': 'w-1',
          'duration_minutes': 45,
          'duration_minutes_min': 45,
          'duration_minutes_max': 45,
        });

        expect(summary.formattedDurationShort, '45m');
      });

      test('should show duration when no min/max', () {
        final summary = TodayWorkoutSummary.fromJson({
          'id': 'w-1',
          'duration_minutes': 30,
        });

        expect(summary.formattedDurationShort, '30m');
      });
    });

    group('toWorkout', () {
      test('should convert to Workout with correct fields', () {
        final summary = TodayWorkoutSummary.fromJson({
          'id': 'w-123',
          'name': 'Push Day',
          'type': 'strength',
          'difficulty': 'intermediate',
          'duration_minutes': 50,
          'duration_minutes_min': 45,
          'duration_minutes_max': 55,
          'exercise_count': 4,
          'primary_muscles': ['chest'],
          'scheduled_date': '2026-02-07',
          'is_today': true,
          'is_completed': false,
          'exercises': [
            {'name': 'Bench Press', 'sets': 3, 'reps': 10},
          ],
        });
        final workout = summary.toWorkout();

        expect(workout.id, 'w-123');
        expect(workout.name, 'Push Day');
        expect(workout.type, 'strength');
        expect(workout.difficulty, 'intermediate');
        expect(workout.durationMinutes, 50);
        expect(workout.scheduledDate, '2026-02-07');
        expect(workout.isCompleted, false);
        expect(workout.knownExerciseCount, 4);
        // exercises should be parseable from the converted exercisesJson
        expect(workout.exercises.length, 1);
        expect(workout.exercises[0].name, 'Bench Press');
      });
    });
  });

  group('TodayWorkoutResponse', () {
    group('fromJson', () {
      test('should parse workout day response', () {
        final json = {
          'has_workout_today': true,
          'today_workout': {
            'id': 'w-1',
            'name': 'Chest Day',
            'type': 'strength',
            'difficulty': 'intermediate',
            'duration_minutes': 45,
            'exercise_count': 5,
            'primary_muscles': ['chest'],
            'scheduled_date': '2026-02-07',
            'is_today': true,
            'is_completed': false,
            'exercises': [],
          },
          'completed_today': false,
          'is_generating': false,
          'needs_generation': false,
        };
        final response = TodayWorkoutResponse.fromJson(json);

        expect(response.hasWorkoutToday, true);
        expect(response.todayWorkout, isNotNull);
        expect(response.todayWorkout!.name, 'Chest Day');
        expect(response.completedToday, false);
        expect(response.isGenerating, false);
        expect(response.needsGeneration, false);
      });

      test('should parse rest day response', () {
        final json = {
          'has_workout_today': false,
          'today_workout': null,
          'next_workout': {
            'id': 'w-2',
            'name': 'Back Day',
            'type': 'strength',
            'difficulty': 'intermediate',
            'duration_minutes': 50,
            'exercise_count': 6,
            'primary_muscles': ['back'],
            'scheduled_date': '2026-02-08',
            'is_today': false,
            'is_completed': false,
            'exercises': [],
          },
          'days_until_next': 1,
          'rest_day_message': 'Rest and recover today!',
          'completed_today': false,
        };
        final response = TodayWorkoutResponse.fromJson(json);

        expect(response.hasWorkoutToday, false);
        expect(response.todayWorkout, isNull);
        expect(response.nextWorkout, isNotNull);
        expect(response.nextWorkout!.name, 'Back Day');
        expect(response.daysUntilNext, 1);
        expect(response.restDayMessage, 'Rest and recover today!');
      });

      test('should parse completed workout response', () {
        final json = {
          'has_workout_today': true,
          'completed_today': true,
          'completed_workout': {
            'id': 'w-done',
            'name': 'Morning Workout',
            'type': 'strength',
            'difficulty': 'easy',
            'duration_minutes': 30,
            'exercise_count': 4,
            'primary_muscles': ['full body'],
            'scheduled_date': '2026-02-07',
            'is_today': true,
            'is_completed': true,
            'exercises': [],
          },
        };
        final response = TodayWorkoutResponse.fromJson(json);

        expect(response.completedToday, true);
        expect(response.completedWorkout, isNotNull);
        expect(response.completedWorkout!.isCompleted, true);
      });

      test('should parse generation status fields', () {
        final json = {
          'has_workout_today': false,
          'is_generating': true,
          'generation_message': 'Creating your workout...',
          'needs_generation': true,
          'next_workout_date': '2026-02-08',
          'gym_profile_id': 'gym-123',
        };
        final response = TodayWorkoutResponse.fromJson(json);

        expect(response.isGenerating, true);
        expect(response.generationMessage, 'Creating your workout...');
        expect(response.needsGeneration, true);
        expect(response.nextWorkoutDate, '2026-02-08');
        expect(response.gymProfileId, 'gym-123');
      });

      test('should handle empty JSON with defaults', () {
        final response = TodayWorkoutResponse.fromJson({});

        expect(response.hasWorkoutToday, false);
        expect(response.todayWorkout, isNull);
        expect(response.nextWorkout, isNull);
        expect(response.completedToday, false);
        expect(response.isGenerating, false);
        expect(response.needsGeneration, false);
      });
    });

    group('toJson', () {
      test('should serialize and deserialize round-trip', () {
        final original = TodayWorkoutResponse.fromJson({
          'has_workout_today': true,
          'today_workout': {
            'id': 'w-1',
            'name': 'Test',
            'type': 'strength',
            'difficulty': 'medium',
            'duration_minutes': 45,
            'exercise_count': 3,
            'primary_muscles': [],
            'scheduled_date': '2026-02-07',
            'is_today': true,
            'is_completed': false,
            'exercises': [],
          },
          'days_until_next': 2,
          'rest_day_message': 'Rest up!',
          'completed_today': false,
          'needs_generation': false,
        });
        final json = original.toJson();
        final restored = TodayWorkoutResponse.fromJson(json);

        expect(restored.hasWorkoutToday, original.hasWorkoutToday);
        expect(restored.todayWorkout?.id, original.todayWorkout?.id);
        expect(restored.daysUntilNext, original.daysUntilNext);
        expect(restored.restDayMessage, original.restDayMessage);
      });
    });
  });
}
