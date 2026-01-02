import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/screens/workout/widgets/warmup_phase_screen.dart';
import 'package:fitwiz/screens/workout/models/workout_state.dart';

void main() {
  Widget buildTestWidget({
    int workoutSeconds = 120,
    VoidCallback? onSkipWarmup,
    VoidCallback? onWarmupComplete,
    VoidCallback? onQuitRequested,
    List<WarmupExerciseData>? exercises,
  }) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: WarmupPhaseScreen(
        workoutSeconds: workoutSeconds,
        onSkipWarmup: onSkipWarmup ?? () {},
        onWarmupComplete: onWarmupComplete ?? () {},
        onQuitRequested: onQuitRequested ?? () {},
        exercises: exercises ?? defaultWarmupExercises,
      ),
    );
  }

  group('WarmupPhaseScreen', () {
    testWidgets('displays WARM UP label', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('WARM UP'), findsOneWidget);
    });

    testWidgets('displays workout timer', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        workoutSeconds: 65,
      ));

      expect(find.text('01:05'), findsOneWidget);
    });

    testWidgets('displays skip warmup button', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Skip Warmup'), findsOneWidget);
    });

    testWidgets('skip warmup calls callback', (tester) async {
      bool skipped = false;

      await tester.pumpWidget(buildTestWidget(
        onSkipWarmup: () => skipped = true,
      ));

      await tester.tap(find.text('Skip Warmup'));
      await tester.pump();

      expect(skipped, true);
    });

    testWidgets('displays first exercise', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Jumping Jacks'), findsOneWidget);
    });

    testWidgets('displays exercise counter', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('1 of 5'), findsOneWidget);
    });

    testWidgets('displays UP NEXT section', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('UP NEXT'), findsOneWidget);
    });

    testWidgets('has back button', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('back button calls onQuitRequested', (tester) async {
      bool quitRequested = false;

      await tester.pumpWidget(buildTestWidget(
        onQuitRequested: () => quitRequested = true,
      ));

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();

      expect(quitRequested, true);
    });

    testWidgets('has Start Timer button initially', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Start Timer'), findsOneWidget);
    });

    testWidgets('has Next button', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('displays custom exercises', (tester) async {
      final customExercises = [
        const WarmupExerciseData(
          name: 'Custom Warmup',
          duration: 45,
          icon: Icons.sports,
        ),
      ];

      await tester.pumpWidget(buildTestWidget(
        exercises: customExercises,
      ));

      expect(find.text('Custom Warmup'), findsOneWidget);
      expect(find.text('1 of 1'), findsOneWidget);
    });

    testWidgets('shows Start Workout on last exercise', (tester) async {
      final singleExercise = [
        const WarmupExerciseData(
          name: 'Only Exercise',
          duration: 30,
          icon: Icons.sports,
        ),
      ];

      await tester.pumpWidget(buildTestWidget(
        exercises: singleExercise,
      ));

      expect(find.text('Start Workout'), findsOneWidget);
    });

    testWidgets('has warmup icon', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byIcon(Icons.whatshot), findsOneWidget);
    });

    testWidgets('displays progress indicator', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });
}
