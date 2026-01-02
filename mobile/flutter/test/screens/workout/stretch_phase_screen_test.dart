import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/screens/workout/widgets/stretch_phase_screen.dart';
import 'package:fitwiz/screens/workout/models/workout_state.dart';

void main() {
  Widget buildTestWidget({
    int workoutSeconds = 1800,
    VoidCallback? onSkipAll,
    VoidCallback? onStretchComplete,
    List<StretchExerciseData>? exercises,
  }) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: StretchPhaseScreen(
        workoutSeconds: workoutSeconds,
        onSkipAll: onSkipAll ?? () {},
        onStretchComplete: onStretchComplete ?? () {},
        exercises: exercises ?? defaultStretchExercises,
      ),
    );
  }

  group('StretchPhaseScreen', () {
    testWidgets('displays COOL DOWN label', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('COOL DOWN'), findsOneWidget);
    });

    testWidgets('displays workout timer', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        workoutSeconds: 1865, // 31:05
      ));

      expect(find.text('31:05'), findsOneWidget);
    });

    testWidgets('displays skip all button', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Skip All'), findsOneWidget);
    });

    testWidgets('skip all calls callback', (tester) async {
      bool skipped = false;

      await tester.pumpWidget(buildTestWidget(
        onSkipAll: () => skipped = true,
      ));

      await tester.tap(find.text('Skip All'));
      await tester.pump();

      expect(skipped, true);
    });

    testWidgets('displays first stretch exercise', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Quad Stretch'), findsOneWidget);
    });

    testWidgets('displays exercise counter', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('1 of 5'), findsOneWidget);
    });

    testWidgets('displays completion banner', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Great job! Time to stretch and recover.'), findsOneWidget);
    });

    testWidgets('has trophy icon in banner', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byIcon(Icons.emoji_events), findsOneWidget);
    });

    testWidgets('displays UP NEXT section', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('UP NEXT'), findsOneWidget);
    });

    testWidgets('has back button', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('back button calls onSkipAll', (tester) async {
      bool skipped = false;

      await tester.pumpWidget(buildTestWidget(
        onSkipAll: () => skipped = true,
      ));

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();

      expect(skipped, true);
    });

    testWidgets('has Next button', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('displays custom stretches', (tester) async {
      final customStretches = [
        const StretchExerciseData(
          name: 'Custom Stretch',
          duration: 45,
          icon: Icons.self_improvement,
        ),
      ];

      await tester.pumpWidget(buildTestWidget(
        exercises: customStretches,
      ));

      expect(find.text('Custom Stretch'), findsOneWidget);
      expect(find.text('1 of 1'), findsOneWidget);
    });

    testWidgets('shows Finish on last exercise', (tester) async {
      final singleStretch = [
        const StretchExerciseData(
          name: 'Final Stretch',
          duration: 60,
          icon: Icons.self_improvement,
        ),
      ];

      await tester.pumpWidget(buildTestWidget(
        exercises: singleStretch,
      ));

      expect(find.text('Finish'), findsOneWidget);
    });

    testWidgets('has self improvement icon', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byIcon(Icons.self_improvement), findsWidgets);
    });

    testWidgets('displays progress indicator', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('has Start Timer button initially', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Start Timer'), findsOneWidget);
    });

    testWidgets('tapping Next on last exercise completes stretch', (tester) async {
      bool completed = false;

      final singleStretch = [
        const StretchExerciseData(
          name: 'Final Stretch',
          duration: 60,
          icon: Icons.self_improvement,
        ),
      ];

      await tester.pumpWidget(buildTestWidget(
        exercises: singleStretch,
        onStretchComplete: () => completed = true,
      ));

      await tester.tap(find.text('Finish'));
      await tester.pump();

      expect(completed, true);
    });
  });
}
