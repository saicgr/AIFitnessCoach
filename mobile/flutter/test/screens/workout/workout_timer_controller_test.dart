import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/screens/workout/controllers/workout_timer_controller.dart';

void main() {
  group('WorkoutTimerController', () {
    late WorkoutTimerController controller;

    setUp(() {
      controller = WorkoutTimerController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('initial state is correct', () {
      expect(controller.workoutSeconds, 0);
      expect(controller.restSecondsRemaining, 0);
      expect(controller.initialRestDuration, 0);
      expect(controller.isPaused, false);
      expect(controller.restProgress, 0.0);
    });

    test('formatTime formats seconds correctly', () {
      expect(WorkoutTimerController.formatTime(0), '00:00');
      expect(WorkoutTimerController.formatTime(59), '00:59');
      expect(WorkoutTimerController.formatTime(60), '01:00');
      expect(WorkoutTimerController.formatTime(61), '01:01');
      expect(WorkoutTimerController.formatTime(3599), '59:59');
      expect(WorkoutTimerController.formatTime(3600), '60:00');
    });

    test('togglePause toggles pause state', () {
      expect(controller.isPaused, false);
      controller.togglePause();
      expect(controller.isPaused, true);
      controller.togglePause();
      expect(controller.isPaused, false);
    });

    test('setPaused sets pause state directly', () {
      expect(controller.isPaused, false);
      controller.setPaused(true);
      expect(controller.isPaused, true);
      controller.setPaused(false);
      expect(controller.isPaused, false);
    });

    testWidgets('startWorkoutTimer increments seconds', (tester) async {
      controller.startWorkoutTimer();

      // Wait for timer to tick
      await tester.pump(const Duration(seconds: 2));

      expect(controller.workoutSeconds, greaterThan(0));
    });

    testWidgets('startRestTimer sets initial values', (tester) async {
      controller.startRestTimer(60);

      expect(controller.restSecondsRemaining, 60);
      expect(controller.initialRestDuration, 60);
      expect(controller.restProgress, 1.0);
    });

    testWidgets('rest timer decrements and calls onComplete', (tester) async {
      bool completed = false;
      controller.onRestComplete = () => completed = true;

      controller.startRestTimer(2);

      // Wait for timer to complete
      await tester.pump(const Duration(seconds: 3));

      expect(completed, true);
      expect(controller.restSecondsRemaining, 0);
    });

    testWidgets('skipRest ends rest immediately', (tester) async {
      bool completed = false;
      controller.onRestComplete = () => completed = true;

      controller.startRestTimer(60);
      controller.skipRest();

      expect(completed, true);
      expect(controller.restSecondsRemaining, 0);
    });

    test('restProgress calculates correctly', () {
      controller.startRestTimer(100);

      // Initial progress is 1.0
      expect(controller.restProgress, 1.0);

      // Manually set remaining to test calculation
      // Note: This is testing the getter logic
    });

    testWidgets('paused timer does not increment', (tester) async {
      controller.setPaused(true);
      controller.startWorkoutTimer();

      final initialSeconds = controller.workoutSeconds;
      await tester.pump(const Duration(seconds: 2));

      expect(controller.workoutSeconds, initialSeconds);
    });
  });

  group('PhaseTimerController', () {
    late PhaseTimerController controller;

    setUp(() {
      controller = PhaseTimerController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('initial state is correct', () {
      expect(controller.secondsRemaining, 0);
      expect(controller.isRunning, false);
    });

    testWidgets('start initializes and runs timer', (tester) async {
      controller.start(60);

      expect(controller.secondsRemaining, 60);
      expect(controller.isRunning, true);

      await tester.pump(const Duration(seconds: 1));
      expect(controller.secondsRemaining, lessThan(60));
    });

    testWidgets('pause stops timer', (tester) async {
      controller.start(60);
      controller.pause();

      expect(controller.isRunning, false);
      final remaining = controller.secondsRemaining;

      await tester.pump(const Duration(seconds: 1));
      expect(controller.secondsRemaining, remaining);
    });

    testWidgets('resume continues timer', (tester) async {
      controller.start(60);
      controller.pause();

      final remaining = controller.secondsRemaining;
      controller.resume();

      expect(controller.isRunning, true);
      await tester.pump(const Duration(seconds: 1));
      expect(controller.secondsRemaining, lessThan(remaining));
    });

    test('stop resets running state', () {
      controller.start(60);
      controller.stop();

      expect(controller.isRunning, false);
    });

    test('reset clears all state', () {
      controller.start(60);
      controller.reset();

      expect(controller.secondsRemaining, 0);
      expect(controller.isRunning, false);
    });

    testWidgets('onComplete called when timer ends', (tester) async {
      bool completed = false;
      controller.onComplete = () => completed = true;

      controller.start(1);

      await tester.pump(const Duration(seconds: 2));

      expect(completed, true);
      expect(controller.isRunning, false);
    });

    testWidgets('onTick called on each tick', (tester) async {
      int tickCount = 0;
      controller.onTick = (_) => tickCount++;

      controller.start(3);

      await tester.pump(const Duration(seconds: 3));

      expect(tickCount, greaterThan(0));
    });
  });
}
