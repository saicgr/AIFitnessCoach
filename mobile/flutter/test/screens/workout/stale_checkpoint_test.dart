// E2E register #136 — a freshly started workout opens with a stale session
// already running (23m37s / 161 kcal / 666 kg).
//
// `_WorkoutCheckpointStore.save()` writes `saved_at_ms` but `load()` never
// read it back — a checkpoint left behind by backing out of a workout (only
// `clear()` deletes it; abandoning via the back button doesn't) rehydrated
// SILENTLY on re-entry no matter how old it was. This gate asserts:
//   1. `peekStaleCheckpoint` reports the real age for a checkpoint with
//      logged sets, and null for an empty one (nothing to lose → no prompt).
//   2. A checkpoint older than `kCheckpointHardTtl` is auto-expired —
//      `peekStaleCheckpoint`/`restoreCheckpoint` both see it as absent.
//   3. `discardOnDiskCheckpoint` actually deletes the on-disk blob.
//
// Negative-tested: reverting `peekStaleCheckpoint` to return null
// unconditionally (the pre-fix "load() never reads saved_at_ms" behavior)
// reproduces "no prompt for a 23-minute-old checkpoint" and fails this test.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitwiz/screens/workout/models/workout_state.dart';
import 'package:fitwiz/screens/workout/providers/active_workout_session_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const userId = 'user-1';
  const workoutId = 'workout-1';

  /// Seeds the exact on-disk shape `_WorkoutCheckpointStore.save` writes,
  /// with a controllable `saved_at_ms` so age can be asserted precisely.
  Future<void> seedCheckpoint({
    required Duration age,
    bool withSets = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final savedAtMs =
        DateTime.now().subtract(age).millisecondsSinceEpoch;
    await prefs.setString(
      'workout_checkpoint::$userId',
      '{"v":1,"workout_id":"$workoutId","current_exercise_index":1,'
      '"elapsed_seconds":1417,"saved_at_ms":$savedAtMs,'
      '"completed_sets":${withSets ? '{"0":[{"reps":8,"weight":60.0}]}' : '{}'}}',
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('peekStaleCheckpoint (#136)', () {
    test('reports the real age for a checkpoint with logged sets', () async {
      final notifier = ActiveWorkoutSessionNotifier();
      await seedCheckpoint(age: const Duration(minutes: 23, seconds: 37));

      final age = await notifier.peekStaleCheckpoint(
        workoutId: workoutId,
        userId: userId,
      );

      expect(age, isNotNull);
      expect(age!.inMinutes, 23);
      expect(age > kCheckpointStalePromptThreshold, isTrue,
          reason: '23m37s must clear the 10-minute prompt threshold');
    });

    test('a fresh checkpoint (under the prompt threshold) does not need a prompt',
        () async {
      final notifier = ActiveWorkoutSessionNotifier();
      await seedCheckpoint(age: const Duration(minutes: 2));

      final age = await notifier.peekStaleCheckpoint(
        workoutId: workoutId,
        userId: userId,
      );

      expect(age, isNotNull);
      expect(age! > kCheckpointStalePromptThreshold, isFalse);
    });

    test('an EMPTY checkpoint (no logged sets) never prompts — nothing to lose',
        () async {
      final notifier = ActiveWorkoutSessionNotifier();
      await seedCheckpoint(age: const Duration(hours: 2), withSets: false);

      final age = await notifier.peekStaleCheckpoint(
        workoutId: workoutId,
        userId: userId,
      );

      expect(age, isNull);
    });

    test('a checkpoint past the hard TTL is auto-expired — treated as absent',
        () async {
      final notifier = ActiveWorkoutSessionNotifier();
      await seedCheckpoint(age: kCheckpointHardTtl + const Duration(hours: 1));

      final age = await notifier.peekStaleCheckpoint(
        workoutId: workoutId,
        userId: userId,
      );
      expect(age, isNull);

      // restoreCheckpoint must ALSO see it as gone, not just the peek.
      final restored = await notifier.restoreCheckpoint(
        workoutId: workoutId,
        userId: userId,
      );
      expect(restored, isNull);
    });

    test('a checkpoint for a DIFFERENT workoutId never surfaces here', () async {
      final notifier = ActiveWorkoutSessionNotifier();
      await seedCheckpoint(age: const Duration(minutes: 30));

      final age = await notifier.peekStaleCheckpoint(
        workoutId: 'some-other-workout',
        userId: userId,
      );
      expect(age, isNull);
    });
  });

  group('discardOnDiskCheckpoint (#136)', () {
    test('deletes the on-disk blob so a later restore sees nothing', () async {
      final notifier = ActiveWorkoutSessionNotifier();
      await seedCheckpoint(age: const Duration(minutes: 30));
      notifier.bindUser(userId);

      await notifier.discardOnDiskCheckpoint();

      final restored = await notifier.restoreCheckpoint(
        workoutId: workoutId,
        userId: userId,
      );
      expect(restored, isNull);
    });
  });

  group('restoreCheckpoint still resumes a valid, non-stale checkpoint', () {
    test('a checkpoint within the TTL restores its logged sets', () async {
      final notifier = ActiveWorkoutSessionNotifier();
      await seedCheckpoint(age: const Duration(minutes: 2));

      final restored = await notifier.restoreCheckpoint(
        workoutId: workoutId,
        userId: userId,
      );

      expect(restored, isNotNull);
      expect(restored!.completedSets[0], hasLength(1));
      expect(restored.completedSets[0]!.first, isA<SetLog>());
    });
  });
}
