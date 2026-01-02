import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/screens/workout/widgets/rest_timer_overlay.dart';
import 'package:fitwiz/data/models/exercise.dart';

void main() {
  // Helper to create test exercise
  WorkoutExercise createTestExercise({
    String name = 'Bench Press',
    int? sets = 3,
    int? reps = 10,
    double? weight = 60.0,
    int? restSeconds = 90,
  }) {
    return WorkoutExercise(
      id: 'test_id',
      nameValue: name,
      sets: sets,
      reps: reps,
      weight: weight,
      restSeconds: restSeconds,
    );
  }

  // Helper to wrap widget with MaterialApp
  Widget buildTestWidget(RestTimerOverlay overlay) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        body: overlay,
      ),
    );
  }

  group('RestTimerOverlay', () {
    testWidgets('displays rest label', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        RestTimerOverlay(
          restSecondsRemaining: 60,
          initialRestDuration: 90,
          restMessage: 'Great job!',
          currentExercise: createTestExercise(),
          completedSetsCount: 1,
          totalSets: 3,
          onSkipRest: () {},
        ),
      ));

      expect(find.text('REST'), findsOneWidget);
    });

    testWidgets('displays countdown timer', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        RestTimerOverlay(
          restSecondsRemaining: 45,
          initialRestDuration: 90,
          restMessage: '',
          currentExercise: createTestExercise(),
          completedSetsCount: 1,
          totalSets: 3,
          onSkipRest: () {},
        ),
      ));

      expect(find.text('45s'), findsOneWidget);
    });

    testWidgets('displays rest message when provided', (tester) async {
      const message = 'Stay focused and breathe!';

      await tester.pumpWidget(buildTestWidget(
        RestTimerOverlay(
          restSecondsRemaining: 60,
          initialRestDuration: 90,
          restMessage: message,
          currentExercise: createTestExercise(),
          completedSetsCount: 1,
          totalSets: 3,
          onSkipRest: () {},
        ),
      ));

      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text(message), findsOneWidget);
    });

    testWidgets('does not display message when empty', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        RestTimerOverlay(
          restSecondsRemaining: 60,
          initialRestDuration: 90,
          restMessage: '',
          currentExercise: createTestExercise(),
          completedSetsCount: 1,
          totalSets: 3,
          onSkipRest: () {},
        ),
      ));

      await tester.pump(const Duration(milliseconds: 500));

      // Psychology icon should not be present when no message
      expect(find.byIcon(Icons.psychology), findsNothing);
    });

    testWidgets('displays next set info for rest between sets', (tester) async {
      final exercise = createTestExercise(name: 'Squat');

      await tester.pumpWidget(buildTestWidget(
        RestTimerOverlay(
          restSecondsRemaining: 60,
          initialRestDuration: 90,
          restMessage: '',
          currentExercise: exercise,
          completedSetsCount: 1,
          totalSets: 3,
          isRestBetweenExercises: false,
          onSkipRest: () {},
        ),
      ));

      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('NEXT SET'), findsOneWidget);
      expect(find.text('Squat'), findsOneWidget);
      expect(find.text('Set 2 of 3'), findsOneWidget);
    });

    testWidgets('displays next exercise for rest between exercises', (tester) async {
      final current = createTestExercise(name: 'Bench Press');
      final next = createTestExercise(
        name: 'Incline Press',
        sets: 4,
        reps: 8,
        weight: 50.0,
      );

      await tester.pumpWidget(buildTestWidget(
        RestTimerOverlay(
          restSecondsRemaining: 120,
          initialRestDuration: 120,
          restMessage: '',
          currentExercise: current,
          completedSetsCount: 3,
          totalSets: 3,
          nextExercise: next,
          isRestBetweenExercises: true,
          onSkipRest: () {},
        ),
      ));

      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('NEXT UP'), findsOneWidget);
      expect(find.text('Incline Press'), findsOneWidget);
    });

    testWidgets('skip rest button calls callback', (tester) async {
      bool skipCalled = false;

      await tester.pumpWidget(buildTestWidget(
        RestTimerOverlay(
          restSecondsRemaining: 60,
          initialRestDuration: 90,
          restMessage: '',
          currentExercise: createTestExercise(),
          completedSetsCount: 1,
          totalSets: 3,
          onSkipRest: () => skipCalled = true,
        ),
      ));

      await tester.pump();

      await tester.tap(find.text('Skip Rest'));
      await tester.pump();

      expect(skipCalled, true);
    });

    testWidgets('displays 1RM button when callback provided', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        RestTimerOverlay(
          restSecondsRemaining: 60,
          initialRestDuration: 90,
          restMessage: '',
          currentExercise: createTestExercise(),
          completedSetsCount: 1,
          totalSets: 3,
          onSkipRest: () {},
          onLog1RM: () {},
        ),
      ));

      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Log 1RM'), findsOneWidget);
      expect(find.text('Track your max'), findsOneWidget);
    });

    testWidgets('1RM button calls callback', (tester) async {
      bool log1RMCalled = false;

      await tester.pumpWidget(buildTestWidget(
        RestTimerOverlay(
          restSecondsRemaining: 60,
          initialRestDuration: 90,
          restMessage: '',
          currentExercise: createTestExercise(),
          completedSetsCount: 1,
          totalSets: 3,
          onSkipRest: () {},
          onLog1RM: () => log1RMCalled = true,
        ),
      ));

      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Log 1RM'));
      await tester.pump();

      expect(log1RMCalled, true);
    });

    testWidgets('restProgress calculates correctly', (tester) async {
      final overlay = RestTimerOverlay(
        restSecondsRemaining: 45,
        initialRestDuration: 90,
        restMessage: '',
        currentExercise: createTestExercise(),
        completedSetsCount: 1,
        totalSets: 3,
        onSkipRest: () {},
      );

      expect(overlay.restProgress, 0.5);
    });

    testWidgets('restProgress is 0 when initialDuration is 0', (tester) async {
      final overlay = RestTimerOverlay(
        restSecondsRemaining: 0,
        initialRestDuration: 0,
        restMessage: '',
        currentExercise: createTestExercise(),
        completedSetsCount: 1,
        totalSets: 3,
        onSkipRest: () {},
      );

      expect(overlay.restProgress, 0.0);
    });

    testWidgets('isRestBetweenSets is correct', (tester) async {
      // Rest between sets (not all sets complete)
      final restBetweenSets = RestTimerOverlay(
        restSecondsRemaining: 60,
        initialRestDuration: 90,
        restMessage: '',
        currentExercise: createTestExercise(),
        completedSetsCount: 1,
        totalSets: 3,
        isRestBetweenExercises: false,
        onSkipRest: () {},
      );

      expect(restBetweenSets.isRestBetweenSets, true);

      // Rest between exercises
      final restBetweenExercises = RestTimerOverlay(
        restSecondsRemaining: 60,
        initialRestDuration: 90,
        restMessage: '',
        currentExercise: createTestExercise(),
        completedSetsCount: 3,
        totalSets: 3,
        isRestBetweenExercises: true,
        onSkipRest: () {},
      );

      expect(restBetweenExercises.isRestBetweenSets, false);
    });
  });
}
