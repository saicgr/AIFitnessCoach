import 'package:fitwiz/data/services/live_activity_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkoutActivityState.toPackagePayload', () {
    final startedAt = DateTime.fromMillisecondsSinceEpoch(1_700_000_000_000);
    final restEndsAt = DateTime.fromMillisecondsSinceEpoch(1_700_000_060_000);

    test('serializes every field as a non-empty string', () {
      final state = WorkoutActivityState(
        workoutName: 'Push Day',
        currentExercise: 'Bench Press',
        currentExerciseIndex: 2,
        totalExercises: 6,
        currentSet: 3,
        totalSets: 4,
        isResting: true,
        restEndsAt: restEndsAt,
        isPaused: false,
        startedAt: startedAt,
        pausedDurationSeconds: 12,
      );

      final payload = state.toPackagePayload();

      expect(payload, <String, dynamic>{
        'workoutName': 'Push Day',
        'currentExercise': 'Bench Press',
        'currentExerciseIndex': '2',
        'totalExercises': '6',
        'currentSet': '3',
        'totalSets': '4',
        'isResting': 'true',
        'restEndsAtEpochMs': '1700000060000',
        'isPaused': 'false',
        'startedAtEpochMs': '1700000000000',
        'pausedDurationSeconds': '12',
      });
    });

    test('restEndsAtEpochMs is "0" when not resting', () {
      final state = WorkoutActivityState(
        workoutName: 'Leg Day',
        currentExercise: 'Squat',
        currentExerciseIndex: 1,
        totalExercises: 5,
        currentSet: 1,
        totalSets: 4,
        isResting: false,
        restEndsAt: null,
        isPaused: false,
        startedAt: startedAt,
        pausedDurationSeconds: 0,
      );

      expect(state.toPackagePayload()['restEndsAtEpochMs'], '0');
      expect(state.toPackagePayload()['isResting'], 'false');
    });

    test('paused state serializes correctly', () {
      final state = WorkoutActivityState(
        workoutName: 'Pull Day',
        currentExercise: 'Rows',
        currentExerciseIndex: 3,
        totalExercises: 5,
        currentSet: 2,
        totalSets: 3,
        isResting: false,
        restEndsAt: null,
        isPaused: true,
        startedAt: startedAt,
        pausedDurationSeconds: 45,
      );

      final payload = state.toPackagePayload();
      expect(payload['isPaused'], 'true');
      expect(payload['pausedDurationSeconds'], '45');
    });
  });

  group('LiveActivityService host platform', () {
    // When running on the Flutter test host (Linux/macOS/Windows) the
    // platform is not iOS or Android, so all methods should no-op and
    // never throw.
    final service = LiveActivityService.instance;

    final dummyState = WorkoutActivityState(
      workoutName: 'Test',
      currentExercise: 'Test Ex',
      currentExerciseIndex: 1,
      totalExercises: 3,
      currentSet: 1,
      totalSets: 3,
      isResting: false,
      restEndsAt: null,
      isPaused: false,
      startedAt: DateTime.now(),
      pausedDurationSeconds: 0,
    );

    test('init() does not throw on host', () async {
      await expectLater(service.init(), completes);
    });

    test('start() does not throw on host', () async {
      await expectLater(service.start(dummyState), completes);
    });

    test('update() does not throw on host', () async {
      await expectLater(service.update(dummyState), completes);
    });

    test('end() does not throw on host', () async {
      await expectLater(service.end(), completes);
    });
  });
}
