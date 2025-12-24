import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ai_fitness_coach/data/repositories/hydration_repository.dart';
import 'package:ai_fitness_coach/data/models/hydration.dart';
import '../helpers/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockApiClient mockApiClient;
  late HydrationRepository repository;

  setUp(() {
    setUpMocks();
    mockApiClient = MockApiClient();
    repository = HydrationRepository(mockApiClient);
  });

  group('HydrationState', () {
    test('should have default values', () {
      const state = HydrationState();

      expect(state.isLoading, false);
      expect(state.error, isNull);
      expect(state.todaySummary, isNull);
      expect(state.recentLogs, isEmpty);
      expect(state.dailyGoalMl, 2500);
    });

    test('should create with custom values', () {
      final summary = DailyHydrationSummary.fromJson(
        JsonFixtures.dailyHydrationSummaryJson(),
      );

      final state = HydrationState(
        isLoading: true,
        error: 'Test error',
        todaySummary: summary,
        recentLogs: const [],
        dailyGoalMl: 3000,
      );

      expect(state.isLoading, true);
      expect(state.error, 'Test error');
      expect(state.todaySummary, isNotNull);
      expect(state.dailyGoalMl, 3000);
    });

    group('copyWith', () {
      test('should copy with new values', () {
        const original = HydrationState();
        final copied = original.copyWith(
          isLoading: true,
          dailyGoalMl: 3000,
        );

        expect(copied.isLoading, true);
        expect(copied.dailyGoalMl, 3000);
        expect(copied.error, isNull); // Error is set to null when not provided
      });

      test('should preserve values when not specified', () {
        const original = HydrationState(
          isLoading: true,
          dailyGoalMl: 3000,
        );
        final copied = original.copyWith();

        expect(copied.isLoading, true);
        expect(copied.dailyGoalMl, 3000);
      });
    });
  });

  group('HydrationRepository', () {
    group('getDailySummary', () {
      test('should return daily summary on success', () async {
        when(() => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
        )).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/hydration/daily/user-123'),
          statusCode: 200,
          data: JsonFixtures.dailyHydrationSummaryJson(),
        ));

        final summary = await repository.getDailySummary('user-123');

        expect(summary.totalMl, 2000);
        expect(summary.waterMl, 1500);
        expect(summary.goalMl, 2500);
      });

      test('should pass date parameter when provided', () async {
        when(() => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
        )).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/hydration/daily/user-123'),
          statusCode: 200,
          data: JsonFixtures.dailyHydrationSummaryJson(),
        ));

        await repository.getDailySummary('user-123', date: '2025-01-15');

        verify(() => mockApiClient.get(
          any(),
          queryParameters: {'date_str': '2025-01-15'},
        )).called(1);
      });

      test('should rethrow on error', () async {
        when(() => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/hydration/daily/user-123'),
        ));

        expect(
          () => repository.getDailySummary('user-123'),
          throwsA(isA<DioException>()),
        );
      });
    });

    group('logHydration', () {
      test('should return HydrationLog on success', () async {
        when(() => mockApiClient.post(
          any(),
          data: any(named: 'data'),
        )).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/hydration/log'),
          statusCode: 200,
          data: JsonFixtures.hydrationLogJson(),
        ));

        final log = await repository.logHydration(
          userId: 'user-123',
          drinkType: 'water',
          amountMl: 250,
        );

        expect(log.userId, 'test-user-id');
        expect(log.drinkType, 'water');
        expect(log.amountMl, 250);
      });

      test('should include optional parameters', () async {
        when(() => mockApiClient.post(
          any(),
          data: any(named: 'data'),
        )).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/hydration/log'),
          statusCode: 200,
          data: JsonFixtures.hydrationLogJson(),
        ));

        await repository.logHydration(
          userId: 'user-123',
          drinkType: 'protein_shake',
          amountMl: 300,
          workoutId: 'workout-456',
          notes: 'Post-workout shake',
        );

        final captured = verify(() => mockApiClient.post(
          any(),
          data: captureAny(named: 'data'),
        )).captured.single as Map<String, dynamic>;

        expect(captured['user_id'], 'user-123');
        expect(captured['drink_type'], 'protein_shake');
        expect(captured['amount_ml'], 300);
        expect(captured['workout_id'], 'workout-456');
        expect(captured['notes'], 'Post-workout shake');
      });

      test('should rethrow on error', () async {
        when(() => mockApiClient.post(
          any(),
          data: any(named: 'data'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/hydration/log'),
        ));

        expect(
          () => repository.logHydration(
            userId: 'user-123',
            drinkType: 'water',
            amountMl: 250,
          ),
          throwsA(isA<DioException>()),
        );
      });
    });

    group('quickLog', () {
      test('should return HydrationLog on success', () async {
        when(() => mockApiClient.post(
          any(),
          queryParameters: any(named: 'queryParameters'),
        )).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/hydration/quick-log/user-123'),
          statusCode: 200,
          data: JsonFixtures.hydrationLogJson(),
        ));

        final log = await repository.quickLog(userId: 'user-123');

        expect(log, isNotNull);
      });

      test('should use default values', () async {
        when(() => mockApiClient.post(
          any(),
          queryParameters: any(named: 'queryParameters'),
        )).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/hydration/quick-log/user-123'),
          statusCode: 200,
          data: JsonFixtures.hydrationLogJson(),
        ));

        await repository.quickLog(userId: 'user-123');

        verify(() => mockApiClient.post(
          any(),
          queryParameters: {
            'drink_type': 'water',
            'amount_ml': 250,
          },
        )).called(1);
      });

      test('should use custom values', () async {
        when(() => mockApiClient.post(
          any(),
          queryParameters: any(named: 'queryParameters'),
        )).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/hydration/quick-log/user-123'),
          statusCode: 200,
          data: JsonFixtures.hydrationLogJson(),
        ));

        await repository.quickLog(
          userId: 'user-123',
          drinkType: 'sports_drink',
          amountMl: 500,
        );

        verify(() => mockApiClient.post(
          any(),
          queryParameters: {
            'drink_type': 'sports_drink',
            'amount_ml': 500,
          },
        )).called(1);
      });
    });

    group('getLogs', () {
      test('should return list of logs on success', () async {
        when(() => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
        )).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/hydration/logs/user-123'),
          statusCode: 200,
          data: [
            JsonFixtures.hydrationLogJson(),
            {...JsonFixtures.hydrationLogJson(), 'id': 'log-2'},
          ],
        ));

        final logs = await repository.getLogs('user-123');

        expect(logs.length, 2);
      });

      test('should pass days parameter', () async {
        when(() => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
        )).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/hydration/logs/user-123'),
          statusCode: 200,
          data: [],
        ));

        await repository.getLogs('user-123', days: 14);

        verify(() => mockApiClient.get(
          any(),
          queryParameters: {'days': 14},
        )).called(1);
      });
    });

    group('deleteLog', () {
      test('should call delete endpoint', () async {
        when(() => mockApiClient.delete(any())).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/hydration/log/log-123'),
            statusCode: 200,
          ),
        );

        await repository.deleteLog('log-123');

        verify(() => mockApiClient.delete('/hydration/log/log-123')).called(1);
      });

      test('should rethrow on error', () async {
        when(() => mockApiClient.delete(any())).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/hydration/log/log-123'),
        ));

        expect(
          () => repository.deleteLog('log-123'),
          throwsA(isA<DioException>()),
        );
      });
    });

    group('getGoal', () {
      test('should return goal on success', () async {
        when(() => mockApiClient.get(any())).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/hydration/goal/user-123'),
          statusCode: 200,
          data: {'daily_goal_ml': 3000},
        ));

        final goal = await repository.getGoal('user-123');

        expect(goal, 3000);
      });

      test('should return default goal when not set', () async {
        when(() => mockApiClient.get(any())).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/hydration/goal/user-123'),
          statusCode: 200,
          data: {},
        ));

        final goal = await repository.getGoal('user-123');

        expect(goal, 2500);
      });

      test('should return default goal on error', () async {
        when(() => mockApiClient.get(any())).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/hydration/goal/user-123'),
        ));

        final goal = await repository.getGoal('user-123');

        expect(goal, 2500);
      });
    });

    group('updateGoal', () {
      test('should call put endpoint with goal', () async {
        when(() => mockApiClient.put(
          any(),
          data: any(named: 'data'),
        )).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/hydration/goal/user-123'),
          statusCode: 200,
        ));

        await repository.updateGoal('user-123', 3500);

        verify(() => mockApiClient.put(
          '/hydration/goal/user-123',
          data: {'daily_goal_ml': 3500},
        )).called(1);
      });

      test('should rethrow on error', () async {
        when(() => mockApiClient.put(
          any(),
          data: any(named: 'data'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/hydration/goal/user-123'),
        ));

        expect(
          () => repository.updateGoal('user-123', 3000),
          throwsA(isA<DioException>()),
        );
      });
    });
  });
}
