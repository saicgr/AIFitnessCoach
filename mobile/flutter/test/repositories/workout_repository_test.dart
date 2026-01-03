import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fitwiz/data/repositories/workout_repository.dart';
import '../helpers/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockApiClient mockApiClient;
  late WorkoutRepository repository;

  setUp(() {
    setUpMocks();
    mockApiClient = MockApiClient();
    repository = WorkoutRepository(mockApiClient);
  });

  group('WorkoutRepository', () {
    group('getWorkouts', () {
      test('should return list of workouts on success', () async {
        final workoutsJson = [
          JsonFixtures.workoutJson(),
          {
            ...JsonFixtures.workoutJson(),
            'id': 'workout-2',
            'name': 'Second Workout',
          },
        ];

        when(() => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
        )).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/workouts'),
          statusCode: 200,
          data: workoutsJson,
        ));

        final workouts = await repository.getWorkouts('user-123');

        expect(workouts.length, 2);
        expect(workouts[0].id, 'test-workout-id');
        expect(workouts[1].id, 'workout-2');
      });

      test('should return empty list when response is empty', () async {
        when(() => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
        )).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/workouts'),
          statusCode: 200,
          data: [],
        ));

        final workouts = await repository.getWorkouts('user-123');

        expect(workouts, isEmpty);
      });

      test('should return empty list on non-200 status', () async {
        when(() => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
        )).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/workouts'),
          statusCode: 404,
          data: null,
        ));

        final workouts = await repository.getWorkouts('user-123');

        expect(workouts, isEmpty);
      });

      test('should rethrow on error', () async {
        when(() => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/workouts'),
          error: 'Network error',
        ));

        expect(
          () => repository.getWorkouts('user-123'),
          throwsA(isA<DioException>()),
        );
      });
    });

    group('getWorkout', () {
      test('should return workout on success', () async {
        when(() => mockApiClient.get(any())).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/workouts/workout-id'),
          statusCode: 200,
          data: JsonFixtures.workoutJson(),
        ));

        final workout = await repository.getWorkout('workout-id');

        expect(workout, isNotNull);
        expect(workout!.id, 'test-workout-id');
        expect(workout.name, 'Test Workout');
      });

      test('should return null on non-200 status', () async {
        when(() => mockApiClient.get(any())).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/workouts/workout-id'),
          statusCode: 404,
          data: null,
        ));

        final workout = await repository.getWorkout('workout-id');

        expect(workout, isNull);
      });
    });

    group('completeWorkout', () {
      test('should return completed workout on success', () async {
        when(() => mockApiClient.post(any())).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/workouts/workout-id/complete'),
          statusCode: 200,
          data: {
            ...JsonFixtures.workoutJson(),
            'is_completed': true,
          },
        ));

        final workout = await repository.completeWorkout('workout-id');

        expect(workout, isNotNull);
        expect(workout!.isCompleted, true);
      });

      test('should return null on non-200 status', () async {
        when(() => mockApiClient.post(any())).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/workouts/workout-id/complete'),
          statusCode: 400,
          data: null,
        ));

        final workout = await repository.completeWorkout('workout-id');

        expect(workout, isNull);
      });
    });

    group('deleteWorkout', () {
      test('should return true on successful deletion', () async {
        when(() => mockApiClient.delete(any())).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/workouts/workout-id'),
          statusCode: 200,
        ));

        final result = await repository.deleteWorkout('workout-id');

        expect(result, true);
      });

      test('should return false on non-200 status', () async {
        when(() => mockApiClient.delete(any())).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/workouts/workout-id'),
          statusCode: 404,
        ));

        final result = await repository.deleteWorkout('workout-id');

        expect(result, false);
      });

      test('should return false on error', () async {
        when(() => mockApiClient.delete(any())).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/workouts/workout-id'),
        ));

        final result = await repository.deleteWorkout('workout-id');

        expect(result, false);
      });
    });

    group('rescheduleWorkout', () {
      test('should return true on success', () async {
        when(() => mockApiClient.patch(
          any(),
          queryParameters: any(named: 'queryParameters'),
        )).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/workouts/workout-id/reschedule'),
          statusCode: 200,
        ));

        final result = await repository.rescheduleWorkout('workout-id', '2025-02-01');

        expect(result, true);
      });

      test('should return false on error', () async {
        when(() => mockApiClient.patch(
          any(),
          queryParameters: any(named: 'queryParameters'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/workouts/workout-id/reschedule'),
        ));

        final result = await repository.rescheduleWorkout('workout-id', '2025-02-01');

        expect(result, false);
      });
    });

    group('getWorkoutVersions', () {
      test('should return list of versions on success', () async {
        when(() => mockApiClient.get(any())).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/workouts/workout-id/versions'),
          statusCode: 200,
          data: [
            {'version': 1, 'created_at': '2025-01-01'},
            {'version': 2, 'created_at': '2025-01-02'},
          ],
        ));

        final versions = await repository.getWorkoutVersions('workout-id');

        expect(versions.length, 2);
        expect(versions[0]['version'], 1);
        expect(versions[1]['version'], 2);
      });

      test('should return empty list on error', () async {
        when(() => mockApiClient.get(any())).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/workouts/workout-id/versions'),
        ));

        final versions = await repository.getWorkoutVersions('workout-id');

        expect(versions, isEmpty);
      });
    });

    group('getWorkoutSummary', () {
      test('should return summary on success', () async {
        when(() => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        )).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/workouts/workout-id/summary'),
          statusCode: 200,
          data: {'summary': 'Great upper body workout!'},
        ));

        final summary = await repository.getWorkoutSummary('workout-id');

        expect(summary, 'Great upper body workout!');
      });

      test('should return null on non-200 status', () async {
        when(() => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        )).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/workouts/workout-id/summary'),
          statusCode: 404,
        ));

        final summary = await repository.getWorkoutSummary('workout-id');

        expect(summary, isNull);
      });
    });
  });

  group('ProgramPreferences', () {
    test('should create from JSON', () {
      final json = {
        'difficulty': 'intermediate',
        'duration_minutes': 45,
        'workout_type': 'strength',
        'workout_days': ['monday', 'wednesday', 'friday'],
        'equipment': ['dumbbells', 'barbell'],
        'focus_areas': ['chest', 'back'],
        'injuries': ['lower back'],
        'last_updated': '2025-01-15T10:00:00Z',
      };

      final prefs = ProgramPreferences.fromJson(json);

      expect(prefs.difficulty, 'intermediate');
      expect(prefs.durationMinutes, 45);
      expect(prefs.workoutType, 'strength');
      expect(prefs.workoutDays, ['monday', 'wednesday', 'friday']);
      expect(prefs.equipment, ['dumbbells', 'barbell']);
      expect(prefs.focusAreas, ['chest', 'back']);
      expect(prefs.injuries, ['lower back']);
      expect(prefs.lastUpdated, '2025-01-15T10:00:00Z');
    });

    test('should use empty lists for missing array fields', () {
      final json = <String, dynamic>{};

      final prefs = ProgramPreferences.fromJson(json);

      expect(prefs.workoutDays, isEmpty);
      expect(prefs.equipment, isEmpty);
      expect(prefs.focusAreas, isEmpty);
      expect(prefs.injuries, isEmpty);
    });
  });

  group('ExerciseHistoryItem', () {
    test('should create from JSON', () {
      final json = {
        'exercise_name': 'Bench Press',
        'total_sets': 50,
        'total_volume': 5000.0,
        'max_weight': 100.0,
        'max_reps': 12,
        'estimated_1rm': 120.0,
        'avg_rpe': 7.5,
        'last_workout_date': '2025-01-15',
        'has_data': true,
      };

      final item = ExerciseHistoryItem.fromJson(json);

      expect(item.exerciseName, 'Bench Press');
      expect(item.totalSets, 50);
      expect(item.totalVolume, 5000.0);
      expect(item.maxWeight, 100.0);
      expect(item.maxReps, 12);
      expect(item.estimated1rm, 120.0);
      expect(item.avgRpe, 7.5);
      expect(item.lastWorkoutDate, '2025-01-15');
      expect(item.hasData, true);
    });

    test('should handle missing optional fields', () {
      final json = {
        'exercise_name': 'Squats',
        'total_sets': 30,
      };

      final item = ExerciseHistoryItem.fromJson(json);

      expect(item.exerciseName, 'Squats');
      expect(item.totalSets, 30);
      expect(item.totalVolume, isNull);
      expect(item.maxWeight, isNull);
      expect(item.progression, isNull);
    });
  });

  group('ExerciseStats', () {
    test('should create from JSON', () {
      final json = {
        'exercise_name': 'Deadlift',
        'total_sets': 100,
        'total_volume': 15000.0,
        'max_weight': 180.0,
        'max_reps': 5,
        'estimated_1rm': 200.0,
        'avg_rpe': 8.5,
        'has_data': true,
        'message': 'Good progress!',
      };

      final stats = ExerciseStats.fromJson(json);

      expect(stats.exerciseName, 'Deadlift');
      expect(stats.totalSets, 100);
      expect(stats.totalVolume, 15000.0);
      expect(stats.maxWeight, 180.0);
      expect(stats.estimated1rm, 200.0);
      expect(stats.hasData, true);
      expect(stats.message, 'Good progress!');
    });
  });

  group('ExerciseProgressionTrend', () {
    test('should create from JSON', () {
      final json = {
        'trend': 'increasing',
        'change_percent': 5.5,
        'message': 'Strength is improving!',
      };

      final trend = ExerciseProgressionTrend.fromJson(json);

      expect(trend.trend, 'increasing');
      expect(trend.changePercent, 5.5);
      expect(trend.message, 'Strength is improving!');
    });

    test('should identify increasing trend', () {
      final trend = ExerciseProgressionTrend(
        trend: 'increasing',
        changePercent: 10.0,
        message: 'Improving',
      );

      expect(trend.isIncreasing, true);
      expect(trend.isDecreasing, false);
      expect(trend.isStable, false);
    });

    test('should identify decreasing trend', () {
      final trend = ExerciseProgressionTrend(
        trend: 'decreasing',
        changePercent: -5.0,
        message: 'Declining',
      );

      expect(trend.isIncreasing, false);
      expect(trend.isDecreasing, true);
      expect(trend.isStable, false);
    });

    test('should identify stable trend', () {
      final trend = ExerciseProgressionTrend(
        trend: 'stable',
        changePercent: 0.5,
        message: 'Maintaining',
      );

      expect(trend.isIncreasing, false);
      expect(trend.isDecreasing, false);
      expect(trend.isStable, true);
    });
  });

  group('ProgramGenerationProgress', () {
    test('should identify completion state', () {
      final progressComplete = ProgramGenerationProgress(
        currentWorkout: 8,
        totalWorkouts: 8,
        message: 'Done!',
        elapsedMs: 10000,
        isCompleted: true,
      );

      final progressIncomplete = ProgramGenerationProgress(
        currentWorkout: 3,
        totalWorkouts: 8,
        message: 'Generating...',
        elapsedMs: 5000,
        isCompleted: false,
      );

      expect(progressComplete.isCompleted, true);
      expect(progressIncomplete.isCompleted, false);
    });

    test('should identify error state', () {
      final progressError = ProgramGenerationProgress(
        currentWorkout: 2,
        totalWorkouts: 8,
        message: 'Failed to generate workout',
        elapsedMs: 3000,
        hasError: true,
      );

      final progressOk = ProgramGenerationProgress(
        currentWorkout: 2,
        totalWorkouts: 8,
        message: 'Generating...',
        elapsedMs: 3000,
        hasError: false,
      );

      expect(progressError.hasError, true);
      expect(progressOk.hasError, false);
    });

    test('should store generated workouts', () {
      final workout1 = TestFixtures.createWorkout(id: 'w1');
      final workout2 = TestFixtures.createWorkout(id: 'w2');

      final progress = ProgramGenerationProgress(
        currentWorkout: 2,
        totalWorkouts: 2,
        message: 'Complete',
        elapsedMs: 15000,
        isCompleted: true,
        workouts: [workout1, workout2],
      );

      expect(progress.workouts.length, 2);
      expect(progress.workouts[0].id, 'w1');
      expect(progress.workouts[1].id, 'w2');
    });

    test('should handle on-demand single workout generation state', () {
      // Simulating maxWorkouts: 1 scenario
      final progress = ProgramGenerationProgress(
        currentWorkout: 1,
        totalWorkouts: 1,
        message: 'Generating your workout...',
        elapsedMs: 2000,
        isCompleted: false,
      );

      expect(progress.totalWorkouts, 1);
      expect(progress.currentWorkout, 1);

      // Completion state for single workout
      final completed = ProgramGenerationProgress(
        currentWorkout: 1,
        totalWorkouts: 1,
        message: 'Done!',
        elapsedMs: 5000,
        isCompleted: true,
        workouts: [TestFixtures.createWorkout()],
      );

      expect(completed.isCompleted, true);
      expect(completed.workouts.length, 1);
    });

    test('should calculate progress percentage', () {
      final progress = ProgramGenerationProgress(
        currentWorkout: 2,
        totalWorkouts: 4,
        message: 'Generating...',
        elapsedMs: 5000,
      );

      expect(progress.progress, 0.5);
    });
  });
}
