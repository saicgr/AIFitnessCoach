import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/data/models/workout.dart';
import 'package:fitwiz/data/models/exercise.dart';

void main() {
  group('PersonalRecordInfo', () {
    group('fromJson', () {
      test('should create from valid JSON', () {
        final json = {
          'exercise_name': 'Bench Press',
          'weight_kg': 100.0,
          'reps': 5,
          'estimated_1rm_kg': 112.5,
          'previous_1rm_kg': 105.0,
          'improvement_kg': 7.5,
          'improvement_percent': 7.1,
          'is_all_time_pr': true,
          'celebration_message': 'New PR!',
        };
        final pr = PersonalRecordInfo.fromJson(json);

        expect(pr.exerciseName, 'Bench Press');
        expect(pr.weightKg, 100.0);
        expect(pr.reps, 5);
        expect(pr.estimated1rmKg, 112.5);
        expect(pr.previous1rmKg, 105.0);
        expect(pr.improvementKg, 7.5);
        expect(pr.improvementPercent, 7.1);
        expect(pr.isAllTimePr, true);
        expect(pr.celebrationMessage, 'New PR!');
      });

      test('should handle missing fields with defaults', () {
        final json = <String, dynamic>{};
        final pr = PersonalRecordInfo.fromJson(json);

        expect(pr.exerciseName, '');
        expect(pr.weightKg, 0.0);
        expect(pr.reps, 0);
        expect(pr.estimated1rmKg, 0.0);
        expect(pr.previous1rmKg, isNull);
        expect(pr.improvementKg, isNull);
        expect(pr.isAllTimePr, true);
        expect(pr.celebrationMessage, isNull);
      });

      test('should handle numeric types (int vs double)', () {
        final json = {
          'exercise_name': 'Squat',
          'weight_kg': 100,  // int, not double
          'reps': 5,
          'estimated_1rm_kg': 112,  // int, not double
        };
        final pr = PersonalRecordInfo.fromJson(json);

        expect(pr.weightKg, 100.0);
        expect(pr.estimated1rmKg, 112.0);
      });
    });
  });

  group('ExerciseComparisonInfo', () {
    group('fromJson', () {
      test('should create from valid JSON with improvement', () {
        final json = {
          'exercise_name': 'Bench Press',
          'exercise_id': 'ex-1',
          'current_sets': 3,
          'current_reps': 30,
          'current_volume_kg': 3000.0,
          'current_max_weight_kg': 100.0,
          'current_1rm_kg': 112.5,
          'previous_sets': 3,
          'previous_reps': 27,
          'previous_volume_kg': 2700.0,
          'previous_max_weight_kg': 95.0,
          'previous_1rm_kg': 107.0,
          'previous_date': '2026-02-01',
          'volume_diff_kg': 300.0,
          'volume_diff_percent': 11.1,
          'weight_diff_kg': 5.0,
          'weight_diff_percent': 5.3,
          'rm_diff_kg': 5.5,
          'rm_diff_percent': 5.1,
          'reps_diff': 3,
          'sets_diff': 0,
          'status': 'improved',
        };
        final comp = ExerciseComparisonInfo.fromJson(json);

        expect(comp.exerciseName, 'Bench Press');
        expect(comp.status, 'improved');
        expect(comp.isImproved, true);
        expect(comp.isDeclined, false);
        expect(comp.isMaintained, false);
        expect(comp.hasPrevious, true);
      });

      test('should handle first_time status', () {
        final json = {
          'exercise_name': 'New Exercise',
          'status': 'first_time',
        };
        final comp = ExerciseComparisonInfo.fromJson(json);

        expect(comp.hasPrevious, false);
        expect(comp.isImproved, false);
      });
    });

    group('formattedWeightDiff', () {
      test('should format positive diff', () {
        const comp = ExerciseComparisonInfo(
          exerciseName: 'Test',
          weightDiffKg: 5.0,
        );

        expect(comp.formattedWeightDiff, '+5.0 kg');
      });

      test('should format negative diff', () {
        const comp = ExerciseComparisonInfo(
          exerciseName: 'Test',
          weightDiffKg: -2.5,
        );

        expect(comp.formattedWeightDiff, '-2.5 kg');
      });

      test('should return empty string for null diff', () {
        const comp = ExerciseComparisonInfo(exerciseName: 'Test');

        expect(comp.formattedWeightDiff, '');
      });
    });

    group('formattedPercentDiff', () {
      test('should format positive percent from rmDiffPercent', () {
        const comp = ExerciseComparisonInfo(
          exerciseName: 'Test',
          rmDiffPercent: 5.2,
        );

        expect(comp.formattedPercentDiff, '+5.2%');
      });

      test('should fallback to volumeDiffPercent', () {
        const comp = ExerciseComparisonInfo(
          exerciseName: 'Test',
          volumeDiffPercent: 10.0,
        );

        expect(comp.formattedPercentDiff, '+10.0%');
      });

      test('should return empty string when no percent data', () {
        const comp = ExerciseComparisonInfo(exerciseName: 'Test');

        expect(comp.formattedPercentDiff, '');
      });
    });

    group('formattedTimeDiff', () {
      test('should format positive seconds', () {
        const comp = ExerciseComparisonInfo(
          exerciseName: 'Test',
          timeDiffSeconds: 30,
        );

        expect(comp.formattedTimeDiff, '+30s');
      });

      test('should format negative minutes and seconds', () {
        const comp = ExerciseComparisonInfo(
          exerciseName: 'Test',
          timeDiffSeconds: -75,
        );

        expect(comp.formattedTimeDiff, '-1m 15s');
      });

      test('should return empty string for null', () {
        const comp = ExerciseComparisonInfo(exerciseName: 'Test');

        expect(comp.formattedTimeDiff, '');
      });
    });
  });

  group('WorkoutComparisonInfo', () {
    group('fromJson', () {
      test('should create from valid JSON', () {
        final json = {
          'current_duration_seconds': 2700,
          'current_total_volume_kg': 5000.0,
          'current_total_sets': 15,
          'current_total_reps': 120,
          'current_exercises': 5,
          'current_calories': 270,
          'has_previous': true,
          'previous_duration_seconds': 2400,
          'previous_total_volume_kg': 4500.0,
          'previous_performed_at': '2026-02-01T10:00:00Z',
          'duration_diff_seconds': 300,
          'duration_diff_percent': 12.5,
          'volume_diff_kg': 500.0,
          'volume_diff_percent': 11.1,
          'overall_status': 'improved',
        };
        final comp = WorkoutComparisonInfo.fromJson(json);

        expect(comp.currentDurationSeconds, 2700);
        expect(comp.currentTotalVolumeKg, 5000.0);
        expect(comp.hasPrevious, true);
        expect(comp.overallStatus, 'improved');
      });

      test('should handle empty JSON with defaults', () {
        final comp = WorkoutComparisonInfo.fromJson({});

        expect(comp.currentDurationSeconds, 0);
        expect(comp.currentTotalVolumeKg, 0.0);
        expect(comp.hasPrevious, false);
        expect(comp.overallStatus, 'first_time');
      });
    });

    group('formattedDurationDiff', () {
      test('should format positive minutes', () {
        const comp = WorkoutComparisonInfo(durationDiffSeconds: 120);

        expect(comp.formattedDurationDiff, '+2m');
      });

      test('should format negative minutes with seconds', () {
        const comp = WorkoutComparisonInfo(durationDiffSeconds: -90);

        expect(comp.formattedDurationDiff, '-1m 30s');
      });

      test('should format seconds only', () {
        const comp = WorkoutComparisonInfo(durationDiffSeconds: 45);

        expect(comp.formattedDurationDiff, '+45s');
      });

      test('should return empty string for null', () {
        const comp = WorkoutComparisonInfo();

        expect(comp.formattedDurationDiff, '');
      });
    });

    group('formattedVolumeDiff', () {
      test('should format positive volume', () {
        const comp = WorkoutComparisonInfo(volumeDiffKg: 500.0);

        expect(comp.formattedVolumeDiff, '+500 kg');
      });

      test('should format negative volume', () {
        const comp = WorkoutComparisonInfo(volumeDiffKg: -200.0);

        expect(comp.formattedVolumeDiff, '-200 kg');
      });

      test('should return empty string for null', () {
        const comp = WorkoutComparisonInfo();

        expect(comp.formattedVolumeDiff, '');
      });
    });
  });

  group('PerformanceComparisonInfo', () {
    group('fromJson', () {
      test('should create from valid JSON', () {
        final json = {
          'workout_comparison': {
            'current_duration_seconds': 3000,
            'current_total_volume_kg': 6000.0,
            'overall_status': 'improved',
          },
          'exercise_comparisons': [
            {
              'exercise_name': 'Bench Press',
              'status': 'improved',
            },
            {
              'exercise_name': 'Squat',
              'status': 'maintained',
            },
            {
              'exercise_name': 'Row',
              'status': 'declined',
            },
          ],
          'improved_count': 1,
          'maintained_count': 1,
          'declined_count': 1,
          'first_time_count': 0,
        };
        final perf = PerformanceComparisonInfo.fromJson(json);

        expect(perf.workoutComparison.overallStatus, 'improved');
        expect(perf.exerciseComparisons.length, 3);
        expect(perf.improvedCount, 1);
        expect(perf.maintainedCount, 1);
        expect(perf.declinedCount, 1);
        expect(perf.hasImprovements, true);
        expect(perf.hasDeclines, true);
        expect(perf.totalExercises, 3);
      });

      test('should handle missing data', () {
        final perf = PerformanceComparisonInfo.fromJson({});

        expect(perf.exerciseComparisons, isEmpty);
        expect(perf.improvedCount, 0);
        expect(perf.hasImprovements, false);
        expect(perf.hasDeclines, false);
        expect(perf.totalExercises, 0);
      });
    });

    group('filtered exercises', () {
      test('should return improved exercises only', () {
        const perf = PerformanceComparisonInfo(
          workoutComparison: WorkoutComparisonInfo(),
          exerciseComparisons: [
            ExerciseComparisonInfo(exerciseName: 'A', status: 'improved'),
            ExerciseComparisonInfo(exerciseName: 'B', status: 'declined'),
            ExerciseComparisonInfo(exerciseName: 'C', status: 'improved'),
          ],
          improvedCount: 2,
        );

        expect(perf.improvedExercises.length, 2);
        expect(perf.improvedExercises[0].exerciseName, 'A');
        expect(perf.improvedExercises[1].exerciseName, 'C');
      });

      test('should return declined exercises only', () {
        const perf = PerformanceComparisonInfo(
          workoutComparison: WorkoutComparisonInfo(),
          exerciseComparisons: [
            ExerciseComparisonInfo(exerciseName: 'A', status: 'improved'),
            ExerciseComparisonInfo(exerciseName: 'B', status: 'declined'),
          ],
          declinedCount: 1,
        );

        expect(perf.declinedExercises.length, 1);
        expect(perf.declinedExercises[0].exerciseName, 'B');
      });
    });
  });

  group('WorkoutCompletionResponse', () {
    group('fromJson', () {
      test('should create from valid JSON with PRs and comparison', () {
        final json = {
          'workout': {
            'id': 'w-1',
            'name': 'Completed Workout',
            'is_completed': true,
          },
          'personal_records': [
            {
              'exercise_name': 'Bench Press',
              'weight_kg': 100.0,
              'reps': 5,
              'estimated_1rm_kg': 112.5,
            },
          ],
          'performance_comparison': {
            'workout_comparison': {
              'overall_status': 'improved',
            },
            'exercise_comparisons': [],
            'improved_count': 3,
          },
          'strength_scores_updated': true,
          'message': 'Great workout!',
        };
        final response = WorkoutCompletionResponse.fromJson(json);

        expect(response.workout.id, 'w-1');
        expect(response.isCompleted, true);
        expect(response.hasPRs, true);
        expect(response.prCount, 1);
        expect(response.personalRecords[0].exerciseName, 'Bench Press');
        expect(response.hasComparison, true);
        expect(response.hasImprovements, true);
        expect(response.strengthScoresUpdated, true);
        expect(response.message, 'Great workout!');
      });

      test('should handle minimal response', () {
        final json = {
          'id': 'w-2',
          'name': 'Simple Workout',
          'is_completed': true,
        };
        final response = WorkoutCompletionResponse.fromJson(json);

        // When no 'workout' key, it uses the json itself
        expect(response.workout.id, 'w-2');
        expect(response.hasPRs, false);
        expect(response.hasComparison, false);
        expect(response.strengthScoresUpdated, false);
        expect(response.message, 'Workout completed successfully');
      });
    });
  });

  group('SetTarget', () {
    group('fromJson', () {
      test('should create from valid JSON', () {
        final json = {
          'set_number': 1,
          'set_type': 'warmup',
          'target_reps': 12,
          'target_weight_kg': 40.0,
          'target_rpe': 5,
          'target_rir': 5,
        };
        final target = SetTarget.fromJson(json);

        expect(target.setNumber, 1);
        expect(target.setType, 'warmup');
        expect(target.targetReps, 12);
        expect(target.targetWeightKg, 40.0);
        expect(target.targetRpe, 5);
        expect(target.targetRir, 5);
      });
    });

    group('setTypeLabel', () {
      test('should return W for warmup', () {
        const target = SetTarget(setNumber: 1, setType: 'warmup', targetReps: 10);
        expect(target.setTypeLabel, 'W');
      });

      test('should return D for drop', () {
        const target = SetTarget(setNumber: 1, setType: 'drop', targetReps: 10);
        expect(target.setTypeLabel, 'D');
      });

      test('should return F for failure', () {
        const target = SetTarget(setNumber: 1, setType: 'failure', targetReps: 10);
        expect(target.setTypeLabel, 'F');
      });

      test('should return A for amrap', () {
        const target = SetTarget(setNumber: 1, setType: 'amrap', targetReps: 10);
        expect(target.setTypeLabel, 'A');
      });

      test('should return empty string for working set', () {
        const target = SetTarget(setNumber: 1, setType: 'working', targetReps: 10);
        expect(target.setTypeLabel, '');
      });
    });

    group('type checks', () {
      test('isWarmup', () {
        const target = SetTarget(setNumber: 1, setType: 'warmup', targetReps: 10);
        expect(target.isWarmup, true);
        expect(target.isWorkingSet, false);
      });

      test('isDropSet', () {
        const target = SetTarget(setNumber: 1, setType: 'drop', targetReps: 10);
        expect(target.isDropSet, true);
      });

      test('isWorkingSet', () {
        const target = SetTarget(setNumber: 1, setType: 'working', targetReps: 10);
        expect(target.isWorkingSet, true);
      });

      test('isFailure for failure and amrap', () {
        const failure = SetTarget(setNumber: 1, setType: 'failure', targetReps: 10);
        const amrap = SetTarget(setNumber: 1, setType: 'amrap', targetReps: 10);
        expect(failure.isFailure, true);
        expect(amrap.isFailure, true);
      });
    });

    group('holdTimeDisplay', () {
      test('should format seconds', () {
        const target = SetTarget(
          setNumber: 1,
          targetReps: 1,
          targetHoldSeconds: 30,
        );
        expect(target.holdTimeDisplay, '30s');
      });

      test('should format minutes and seconds', () {
        const target = SetTarget(
          setNumber: 1,
          targetReps: 1,
          targetHoldSeconds: 90,
        );
        expect(target.holdTimeDisplay, '1m 30s');
      });

      test('should format minutes only', () {
        const target = SetTarget(
          setNumber: 1,
          targetReps: 1,
          targetHoldSeconds: 60,
        );
        expect(target.holdTimeDisplay, '1m');
      });

      test('should return empty for null', () {
        const target = SetTarget(setNumber: 1, targetReps: 1);
        expect(target.holdTimeDisplay, '');
      });

      test('should return empty for zero', () {
        const target = SetTarget(
          setNumber: 1,
          targetReps: 1,
          targetHoldSeconds: 0,
        );
        expect(target.holdTimeDisplay, '');
      });
    });

    group('hasHoldTime', () {
      test('should return true when hold seconds > 0', () {
        const target = SetTarget(
          setNumber: 1,
          targetReps: 1,
          targetHoldSeconds: 30,
        );
        expect(target.hasHoldTime, true);
      });

      test('should return false when null', () {
        const target = SetTarget(setNumber: 1, targetReps: 1);
        expect(target.hasHoldTime, false);
      });
    });
  });

  group('WorkoutExercise advanced features', () {
    group('superset', () {
      test('should detect superset membership', () {
        const exercise = WorkoutExercise(
          nameValue: 'Bench Press',
          supersetGroup: 1,
          supersetOrder: 1,
        );

        expect(exercise.isInSuperset, true);
        expect(exercise.isSupersetFirst, true);
        expect(exercise.isSupersetSecond, false);
      });

      test('should detect second in superset', () {
        const exercise = WorkoutExercise(
          nameValue: 'Fly',
          supersetGroup: 1,
          supersetOrder: 2,
        );

        expect(exercise.isInSuperset, true);
        expect(exercise.isSupersetFirst, false);
        expect(exercise.isSupersetSecond, true);
      });

      test('should not be in superset when group is null', () {
        const exercise = WorkoutExercise(nameValue: 'Solo Exercise');

        expect(exercise.isInSuperset, false);
      });

      test('should not be in superset when group is 0', () {
        const exercise = WorkoutExercise(
          nameValue: 'Solo',
          supersetGroup: 0,
        );

        expect(exercise.isInSuperset, false);
      });
    });

    group('drop sets', () {
      test('should detect drop sets', () {
        const exercise = WorkoutExercise(
          nameValue: 'Bicep Curl',
          isDropSet: true,
          dropSetCount: 3,
          dropSetPercentage: 20,
        );

        expect(exercise.hasDropSets, true);
        expect(exercise.dropSetDisplay, '3 drops @ 20% less');
      });

      test('should not have drop sets when isDropSet is false', () {
        const exercise = WorkoutExercise(nameValue: 'Normal Exercise');

        expect(exercise.hasDropSets, false);
        expect(exercise.dropSetDisplay, '');
      });

      test('should calculate drop set weights', () {
        const exercise = WorkoutExercise(
          nameValue: 'Curl',
          isDropSet: true,
          dropSetCount: 2,
          dropSetPercentage: 20,
        );

        final weights = exercise.getDropSetWeights(100.0);
        expect(weights.length, 3); // original + 2 drops
        expect(weights[0], 100.0);
        expect(weights[1], 80.0); // 100 * 0.8
        expect(weights[2], 65.0); // 80 * 0.8 = 64 -> rounded to 65.0
      });
    });

    group('timed exercises', () {
      test('should detect timed exercise via isTimed flag', () {
        const exercise = WorkoutExercise(
          nameValue: 'Plank',
          isTimed: true,
        );

        expect(exercise.isTimedExercise, true);
      });

      test('should detect timed exercise via durationSeconds', () {
        const exercise = WorkoutExercise(
          nameValue: 'Cardio',
          durationSeconds: 300,
        );

        expect(exercise.isTimedExercise, true);
      });

      test('should detect timed exercise via holdSeconds', () {
        const exercise = WorkoutExercise(
          nameValue: 'Wall Sit',
          holdSeconds: 45,
        );

        expect(exercise.isTimedExercise, true);
      });

      test('should format hold time display', () {
        const exercise = WorkoutExercise(
          nameValue: 'Plank',
          sets: 3,
          holdSeconds: 30,
        );

        expect(exercise.setsRepsDisplay, '3 \u00d7 30s hold');
      });

      test('should format single set hold time', () {
        const exercise = WorkoutExercise(
          nameValue: 'Plank',
          sets: 1,
          holdSeconds: 60,
        );

        expect(exercise.setsRepsDisplay, '1m 0s hold');
      });
    });

    group('unilateral', () {
      test('should detect unilateral exercise', () {
        const exercise = WorkoutExercise(
          nameValue: 'Single Arm Row',
          isUnilateral: true,
        );

        expect(exercise.isSingleSide, true);
        expect(exercise.unilateralIndicator, 'Each side');
      });

      test('should detect alternating hands', () {
        const exercise = WorkoutExercise(
          nameValue: 'Alternating Curl',
          alternatingHands: true,
        );

        expect(exercise.isSingleSide, true);
      });

      test('should return empty indicator for bilateral', () {
        const exercise = WorkoutExercise(nameValue: 'Bench Press');

        expect(exercise.isSingleSide, false);
        expect(exercise.unilateralIndicator, '');
      });
    });

    group('set targets', () {
      test('should find target for specific set', () {
        const exercise = WorkoutExercise(
          nameValue: 'Squat',
          setTargets: [
            SetTarget(setNumber: 1, setType: 'warmup', targetReps: 10, targetWeightKg: 40.0),
            SetTarget(setNumber: 2, setType: 'working', targetReps: 8, targetWeightKg: 80.0),
            SetTarget(setNumber: 3, setType: 'working', targetReps: 8, targetWeightKg: 80.0),
          ],
        );

        expect(exercise.hasSetTargets, true);
        expect(exercise.getTargetForSet(1)?.setType, 'warmup');
        expect(exercise.getTargetForSet(2)?.targetWeightKg, 80.0);
        expect(exercise.getTargetForSet(99), isNull);
      });

      test('should split warmup and effective sets', () {
        const exercise = WorkoutExercise(
          nameValue: 'Bench',
          setTargets: [
            SetTarget(setNumber: 1, setType: 'warmup', targetReps: 12),
            SetTarget(setNumber: 2, setType: 'warmup', targetReps: 10),
            SetTarget(setNumber: 3, setType: 'working', targetReps: 8),
            SetTarget(setNumber: 4, setType: 'working', targetReps: 8),
            SetTarget(setNumber: 5, setType: 'failure', targetReps: 6),
          ],
        );

        expect(exercise.warmupSets.length, 2);
        expect(exercise.effectiveSets.length, 3);
      });

      test('should handle no set targets', () {
        const exercise = WorkoutExercise(nameValue: 'Simple');

        expect(exercise.hasSetTargets, false);
        expect(exercise.warmupSets, isEmpty);
        expect(exercise.effectiveSets, isEmpty);
      });
    });

    group('weight source', () {
      test('should detect historical weight', () {
        const exercise = WorkoutExercise(
          nameValue: 'Squat',
          weightSource: 'historical',
        );

        expect(exercise.isWeightFromHistory, true);
        expect(exercise.weightSourceLabel, 'Based on your history');
      });

      test('should detect generic weight', () {
        const exercise = WorkoutExercise(
          nameValue: 'Squat',
          weightSource: 'generic',
        );

        expect(exercise.isWeightFromHistory, false);
        expect(exercise.weightSourceLabel, 'Estimated');
      });

      test('should handle null weight source', () {
        const exercise = WorkoutExercise(nameValue: 'Squat');

        expect(exercise.isWeightFromHistory, false);
        expect(exercise.weightSourceLabel, '');
      });
    });
  });

  group('Workout generation metadata', () {
    test('should parse challenge exercise from metadata', () {
      final workout = Workout(
        id: 'w-1',
        name: 'Beginner Workout',
        generationMetadata: {
          'challenge_exercise': {
            'name': 'Pull-up Negative',
            'sets': 2,
            'reps': 5,
          },
        },
      );

      expect(workout.hasChallenge, true);
      expect(workout.challengeExercise, isNotNull);
      expect(workout.challengeExercise!.name, 'Pull-up Negative');
    });

    test('should return null challenge when no metadata', () {
      const workout = Workout(id: 'w-2', name: 'Normal Workout');

      expect(workout.hasChallenge, false);
      expect(workout.challengeExercise, isNull);
    });

    test('should handle malformed challenge data', () {
      const workout = Workout(
        id: 'w-3',
        name: 'Test',
        generationMetadata: {'challenge_exercise': 'invalid'},
      );

      expect(workout.hasChallenge, false);
      expect(workout.challengeExercise, isNull);
    });
  });

  group('Workout formatted duration', () {
    test('should show estimated duration when available', () {
      const workout = Workout(
        id: 'w-1',
        estimatedDurationMinutes: 38,
      );

      expect(workout.formattedDurationShort, '~38m');
      expect(workout.formattedDuration, '~38 min');
    });

    test('should show range when min/max differ', () {
      const workout = Workout(
        id: 'w-1',
        durationMinutesMin: 40,
        durationMinutesMax: 55,
      );

      expect(workout.formattedDurationShort, '40-55m');
      expect(workout.formattedDuration, '40-55 min');
    });

    test('should show single duration', () {
      const workout = Workout(
        id: 'w-1',
        durationMinutes: 45,
      );

      expect(workout.formattedDurationShort, '45m');
      expect(workout.formattedDuration, '45 min');
    });

    test('should default to 45 min when null', () {
      const workout = Workout(id: 'w-1');

      expect(workout.formattedDurationShort, '45m');
      expect(workout.formattedDuration, '45 min');
    });
  });
}
