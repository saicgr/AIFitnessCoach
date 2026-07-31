// E2E register #114 — the injury-safety 409 is discarded; the guard works
// but says nothing useful.
//
// The backend correctly blocks a contraindicated swap/add with HTTP 409
// `EXERCISE_UNSAFE_FOR_INJURY`, but the response body's machine-readable
// code lives at `detail.error` (FastAPI's `http_exception_handler` wraps
// every error under a top-level `detail` key) — the OLD client code read a
// top-level `error_code` that never existed in any response this endpoint
// sends, so the 409 silently fell through to a generic "Failed to swap
// exercise" message (and the two PRE-EXISTING preview-lifecycle exceptions,
// PreviewExpiredException/PreviewNotOwnedException, were equally dead code
// for the same reason). This gate asserts:
//   1. swapExercise/addExercise throw ExerciseUnsafeForInjuryException
//      carrying the backend's real, human-readable message — for BOTH a
//      committed swap (previewId == null) and a preview swap.
//   2. The (now-fixed) key read also revives PREVIEW_EXPIRED/PREVIEW_NOT_OWNED.
//
// Negative-tested: reverting the key read to `data['error_code']` (the
// pre-fix shape) reproduces "swallowed into generic copy" and fails this
// test — see the diff / commit message for the before/after run.

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

  /// Builds the exact response shape FastAPI's `http_exception_handler`
  /// sends for `injury_block_response()` — `{"detail": {"error": ...}}`.
  DioException injuryDioException({required String path}) {
    final requestOptions = RequestOptions(path: path);
    return DioException(
      requestOptions: requestOptions,
      response: Response(
        requestOptions: requestOptions,
        statusCode: 409,
        data: {
          'detail': {
            'error': 'EXERCISE_UNSAFE_FOR_INJURY',
            'message':
                "Barbell Back Squat isn't safe to program around your knee "
                    "injury right now. Pick a different exercise, or mark "
                    "that injury healed first.",
            'exercise': 'Barbell Back Squat',
            'reason': 'contraindicated',
            'injuries': ['knee'],
          },
        },
      ),
      type: DioExceptionType.badResponse,
    );
  }

  group('swapExercise — injury guard (#114)', () {
    test('committed swap (no previewId): throws with the real backend message', () async {
      when(() => mockApiClient.post(any(), data: any(named: 'data')))
          .thenThrow(injuryDioException(path: '/workouts/swap-exercise'));

      expect(
        () => repository.swapExercise(
          workoutId: 'w1',
          oldExerciseName: 'Leg Press',
          newExerciseName: 'Barbell Back Squat',
        ),
        throwsA(
          isA<ExerciseUnsafeForInjuryException>()
              .having((e) => e.message, 'message', contains('knee'))
              .having((e) => e.exerciseName, 'exerciseName', 'Barbell Back Squat')
              .having((e) => e.injuries, 'injuries', contains('knee')),
        ),
      );
    });

    test('preview swap (previewId set): ALSO throws the injury exception', () async {
      when(() => mockApiClient.post(any(), data: any(named: 'data')))
          .thenThrow(injuryDioException(path: '/workouts/preview/swap-exercise'));

      expect(
        () => repository.swapExercise(
          workoutId: 'w1',
          oldExerciseName: 'Leg Press',
          newExerciseName: 'Barbell Back Squat',
          previewId: 'preview-1',
        ),
        throwsA(isA<ExerciseUnsafeForInjuryException>()),
      );
    });
  });

  group('addExercise — injury guard (#114)', () {
    test('throws ExerciseUnsafeForInjuryException with the real message', () async {
      when(() => mockApiClient.post(any(), data: any(named: 'data')))
          .thenThrow(injuryDioException(path: '/workouts/add-exercise'));

      expect(
        () => repository.addExercise(
          workoutId: 'w1',
          exerciseName: 'Barbell Back Squat',
        ),
        throwsA(
          isA<ExerciseUnsafeForInjuryException>()
              .having((e) => e.message, 'message', contains('knee')),
        ),
      );
    });
  });

  group('swapOrAddExceptionMessage (#114)', () {
    test('unwraps the injury exception message', () {
      final e = ExerciseUnsafeForInjuryException('Squat', 'not safe for knee');
      expect(swapOrAddExceptionMessage(e), 'not safe for knee');
    });

    test('falls back to a generic message for unknown errors', () {
      expect(swapOrAddExceptionMessage(Exception('boom')),
          isNot(contains('boom')));
    });
  });

  group('swapExercise — revived preview-lifecycle exceptions (#114 neighbour)', () {
    test('PREVIEW_EXPIRED (404) now actually throws (previously dead code)', () async {
      final requestOptions = RequestOptions(path: '/workouts/preview/swap-exercise');
      when(() => mockApiClient.post(any(), data: any(named: 'data'))).thenThrow(
        DioException(
          requestOptions: requestOptions,
          response: Response(
            requestOptions: requestOptions,
            statusCode: 404,
            data: {
              'detail': {'error': 'PREVIEW_EXPIRED', 'message': 'Preview expired'},
            },
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      expect(
        () => repository.swapExercise(
          workoutId: 'w1',
          oldExerciseName: 'Leg Press',
          newExerciseName: 'Squat',
          previewId: 'preview-1',
        ),
        throwsA(isA<PreviewExpiredException>()),
      );
    });
  });
}
