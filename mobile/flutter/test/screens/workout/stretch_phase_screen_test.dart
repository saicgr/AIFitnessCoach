import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/l10n/generated/app_localizations.dart';
import 'package:fitwiz/screens/workout/widgets/stretch_phase_screen.dart';
import 'package:fitwiz/screens/workout/models/workout_state.dart';

// Local fixture — `defaultStretchExercises` was intentionally removed (stretch
// sets are now backend-generated). This test only needs a representative list.
const List<StretchExerciseData> _stretchFixture = [
  StretchExerciseData(
    name: 'Quad Stretch',
    duration: 30,
    icon: Icons.self_improvement,
  ),
  StretchExerciseData(
    name: 'Hamstring Stretch',
    duration: 30,
    icon: Icons.self_improvement,
  ),
  StretchExerciseData(
    name: 'Chest Opener',
    duration: 30,
    icon: Icons.self_improvement,
  ),
];

/// Unmounts the widget under test and lets its self-scheduled timers fire.
///
/// The phase screens auto-start their exercise timer from a delayed callback in
/// `initState`, so a bare `pumpWidget` always leaves a pending timer behind and
/// the test framework's end-of-test invariant check fails. Disposing the tree
/// stops the periodic ticker; the extra pump lets the one-shot delayed callback
/// resolve (it no-ops because `mounted` is false).
Future<void> disposeAndDrainTimers(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 2));
}

void main() {
  Widget buildTestWidget({
    int workoutSeconds = 1800,
    VoidCallback? onSkipAll,
    VoidCallback? onStretchComplete,
    List<StretchExerciseData>? exercises,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData.dark(),
      home: StretchPhaseScreen(
        workoutSeconds: workoutSeconds,
        onSkipAll: onSkipAll ?? () {},
        onStretchComplete: onStretchComplete ?? () {},
        exercises: exercises ?? _stretchFixture,
      ),
    );
  }

  group('StretchPhaseScreen', () {
    testWidgets('displays COOL DOWN label', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('COOL DOWN'), findsOneWidget);

      await disposeAndDrainTimers(tester);
    });

    testWidgets('displays workout timer', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          workoutSeconds: 1865, // 31:05
        ),
      );

      expect(find.text('31:05'), findsOneWidget);

      await disposeAndDrainTimers(tester);
    });

    testWidgets('displays skip all button', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Skip All'), findsOneWidget);

      await disposeAndDrainTimers(tester);
    });

    testWidgets('skip all calls callback', (tester) async {
      bool skipped = false;

      await tester.pumpWidget(buildTestWidget(onSkipAll: () => skipped = true));

      await tester.tap(find.text('Skip All'));
      await tester.pump();

      expect(skipped, true);

      await disposeAndDrainTimers(tester);
    });

    testWidgets('displays first stretch exercise', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Quad Stretch'), findsOneWidget);

      await disposeAndDrainTimers(tester);
    });

    testWidgets('displays exercise counter', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('1 of ${_stretchFixture.length}'), findsOneWidget);

      await disposeAndDrainTimers(tester);
    });

    testWidgets('displays completion banner', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(
        find.text('Great job! Time to stretch and recover.'),
        findsOneWidget,
      );

      await disposeAndDrainTimers(tester);
    });

    testWidgets('has trophy icon in banner', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byIcon(Icons.emoji_events), findsOneWidget);

      await disposeAndDrainTimers(tester);
    });

    testWidgets('displays UP NEXT section', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('UP NEXT'), findsOneWidget);

      await disposeAndDrainTimers(tester);
    });

    testWidgets('has back button', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      await disposeAndDrainTimers(tester);
    });

    testWidgets('back button calls onSkipAll', (tester) async {
      bool skipped = false;

      await tester.pumpWidget(buildTestWidget(onSkipAll: () => skipped = true));

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();

      expect(skipped, true);

      await disposeAndDrainTimers(tester);
    });

    testWidgets('has Next button', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Next'), findsOneWidget);

      await disposeAndDrainTimers(tester);
    });

    testWidgets('displays custom stretches', (tester) async {
      final customStretches = [
        const StretchExerciseData(
          name: 'Custom Stretch',
          duration: 45,
          icon: Icons.self_improvement,
        ),
      ];

      await tester.pumpWidget(buildTestWidget(exercises: customStretches));

      expect(find.text('Custom Stretch'), findsOneWidget);
      expect(find.text('1 of 1'), findsOneWidget);

      await disposeAndDrainTimers(tester);
    });

    testWidgets('shows Finish on last exercise', (tester) async {
      final singleStretch = [
        const StretchExerciseData(
          name: 'Final Stretch',
          duration: 60,
          icon: Icons.self_improvement,
        ),
      ];

      await tester.pumpWidget(buildTestWidget(exercises: singleStretch));

      expect(find.text('Finish'), findsOneWidget);

      await disposeAndDrainTimers(tester);
    });

    testWidgets('has self improvement icon', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byIcon(Icons.self_improvement), findsWidgets);

      await disposeAndDrainTimers(tester);
    });

    testWidgets('displays progress indicator', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      await disposeAndDrainTimers(tester);
    });

    testWidgets('has Start Timer button initially', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Start Timer'), findsOneWidget);

      await disposeAndDrainTimers(tester);
    });

    testWidgets('tapping Next on last exercise completes stretch', (
      tester,
    ) async {
      bool completed = false;

      final singleStretch = [
        const StretchExerciseData(
          name: 'Final Stretch',
          duration: 60,
          icon: Icons.self_improvement,
        ),
      ];

      await tester.pumpWidget(
        buildTestWidget(
          exercises: singleStretch,
          onStretchComplete: () => completed = true,
        ),
      );

      await tester.tap(find.text('Finish'));
      await tester.pump();

      expect(completed, true);

      await disposeAndDrainTimers(tester);
    });
  });
}
