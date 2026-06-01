import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/screens/workout/models/workout_state.dart';

void main() {
  group('SetLog', () {
    test('creates SetLog with required parameters', () {
      final setLog = SetLog(reps: 10, weight: 50.0);

      expect(setLog.reps, 10);
      expect(setLog.weight, 50.0);
      expect(setLog.setType, 'working');
      expect(setLog.completedAt, isNotNull);
    });

    test('creates SetLog with optional parameters', () {
      final completedAt = DateTime(2024, 1, 1, 12, 0, 0);
      final setLog = SetLog(
        reps: 8,
        weight: 100.0,
        completedAt: completedAt,
        setType: 'warmup',
      );

      expect(setLog.reps, 8);
      expect(setLog.weight, 100.0);
      expect(setLog.setType, 'warmup');
      expect(setLog.completedAt, completedAt);
    });

    test('copyWith creates modified copy', () {
      final original = SetLog(reps: 10, weight: 50.0);
      final copy = original.copyWith(reps: 12);

      expect(copy.reps, 12);
      expect(copy.weight, 50.0);
      expect(original.reps, 10);
    });

    test('copyWith preserves unmodified fields', () {
      final completedAt = DateTime(2024, 1, 1);
      final original = SetLog(
        reps: 10,
        weight: 50.0,
        completedAt: completedAt,
        setType: 'failure',
      );

      final copy = original.copyWith(weight: 60.0);

      expect(copy.reps, 10);
      expect(copy.weight, 60.0);
      expect(copy.completedAt, completedAt);
      expect(copy.setType, 'failure');
    });
  });

  group('WorkoutPhase', () {
    test('has all expected values', () {
      expect(WorkoutPhase.values, [
        WorkoutPhase.warmup,
        WorkoutPhase.active,
        WorkoutPhase.stretch,
        WorkoutPhase.complete,
      ]);
    });
  });

  group('WarmupExerciseData', () {
    test('creates with required parameters', () {
      const warmup = WarmupExerciseData(
        name: 'Jumping Jacks',
        duration: 60,
        icon: Icons.directions_run,
      );

      expect(warmup.name, 'Jumping Jacks');
      expect(warmup.duration, 60);
      expect(warmup.icon, Icons.directions_run);
    });
  });

  group('StretchExerciseData', () {
    test('creates with required parameters', () {
      const stretch = StretchExerciseData(
        name: 'Quad Stretch',
        duration: 30,
        icon: Icons.self_improvement,
      );

      expect(stretch.name, 'Quad Stretch');
      expect(stretch.duration, 30);
      expect(stretch.icon, Icons.self_improvement);
    });
  });

  // The `defaultWarmupExercises` / `defaultStretchExercises` consts were
  // intentionally removed — warmup & stretch sets are now backend-generated and
  // personalized to workout type / injuries / staple preferences, so there is no
  // static default to assert. The WarmupExerciseData / StretchExerciseData models
  // remain covered by the warmup_phase_screen / stretch_phase_screen tests.

  group('RestInterval', () {
    test('creates with required parameters', () {
      final interval = RestInterval(
        restSeconds: 90,
        restType: 'between_sets',
      );

      expect(interval.restSeconds, 90);
      expect(interval.restType, 'between_sets');
      expect(interval.recordedAt, isNotNull);
    });

    test('creates with all parameters', () {
      final recordedAt = DateTime(2024, 1, 1);
      final interval = RestInterval(
        exerciseId: 'ex123',
        exerciseName: 'Bench Press',
        setNumber: 2,
        restSeconds: 120,
        restType: 'between_exercises',
        recordedAt: recordedAt,
      );

      expect(interval.exerciseId, 'ex123');
      expect(interval.exerciseName, 'Bench Press');
      expect(interval.setNumber, 2);
      expect(interval.restSeconds, 120);
      expect(interval.restType, 'between_exercises');
      expect(interval.recordedAt, recordedAt);
    });

    test('toJson produces correct format', () {
      final recordedAt = DateTime(2024, 1, 15, 10, 30, 0);
      final interval = RestInterval(
        exerciseId: 'ex123',
        exerciseName: 'Squat',
        setNumber: 3,
        restSeconds: 90,
        restType: 'between_sets',
        recordedAt: recordedAt,
      );

      final json = interval.toJson();

      expect(json['exercise_id'], 'ex123');
      expect(json['exercise_name'], 'Squat');
      expect(json['set_number'], 3);
      expect(json['rest_seconds'], 90);
      expect(json['rest_type'], 'between_sets');
      expect(json['recorded_at'], recordedAt.toIso8601String());
    });

    test('toJson handles null optional fields', () {
      final interval = RestInterval(
        restSeconds: 60,
        restType: 'warmup',
      );

      final json = interval.toJson();

      expect(json['exercise_id'], isNull);
      expect(json['exercise_name'], isNull);
      expect(json['set_number'], isNull);
      expect(json['rest_seconds'], 60);
      expect(json['rest_type'], 'warmup');
      expect(json['recorded_at'], isNotNull);
    });
  });
}
