import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/l10n/generated/app_localizations.dart';
import 'package:fitwiz/screens/workout/widgets/warmup_phase_screen.dart';
import 'package:fitwiz/screens/workout/models/workout_state.dart';

// Local fixture — the hardcoded `defaultWarmupExercises` const was intentionally
// removed (warmup sets are now backend-generated, personalized to workout type /
// injuries / staples). This test only needs a representative list to render the
// screen, so it defines its own instead of depending on removed app data.
const List<WarmupExerciseData> _warmupFixture = [
  WarmupExerciseData(
    name: 'Jumping Jacks',
    duration: 30,
    icon: Icons.directions_run,
  ),
  WarmupExerciseData(
    name: 'Arm Circles',
    duration: 30,
    icon: Icons.accessibility_new,
  ),
  WarmupExerciseData(name: 'Light Cardio', duration: 60, icon: Icons.favorite),
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
    int workoutSeconds = 120,
    VoidCallback? onSkipWarmup,
    VoidCallback? onWarmupComplete,
    VoidCallback? onQuitRequested,
    List<WarmupExerciseData>? exercises,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData.dark(),
      home: WarmupPhaseScreen(
        workoutSeconds: workoutSeconds,
        onSkipWarmup: onSkipWarmup ?? () {},
        onWarmupComplete: onWarmupComplete ?? () {},
        onQuitRequested: onQuitRequested ?? () {},
        exercises: exercises ?? _warmupFixture,
      ),
    );
  }

  group('WarmupPhaseScreen', () {
    testWidgets('displays WARM UP label', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('WARM UP'), findsOneWidget);

      await disposeAndDrainTimers(tester);
    });

    testWidgets('displays workout timer', (tester) async {
      await tester.pumpWidget(buildTestWidget(workoutSeconds: 65));

      expect(find.text('01:05'), findsOneWidget);

      await disposeAndDrainTimers(tester);
    });

    testWidgets('displays skip warmup button', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Skip Warmup'), findsOneWidget);

      await disposeAndDrainTimers(tester);
    });

    testWidgets('skip warmup calls callback', (tester) async {
      bool skipped = false;

      await tester.pumpWidget(
        buildTestWidget(onSkipWarmup: () => skipped = true),
      );

      await tester.tap(find.text('Skip Warmup'));
      await tester.pump();

      expect(skipped, true);

      await disposeAndDrainTimers(tester);
    });

    testWidgets('displays first exercise', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Jumping Jacks'), findsOneWidget);

      await disposeAndDrainTimers(tester);
    });

    testWidgets('displays exercise counter', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('1 of ${_warmupFixture.length}'), findsOneWidget);

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

    testWidgets('back button calls onQuitRequested', (tester) async {
      bool quitRequested = false;

      await tester.pumpWidget(
        buildTestWidget(onQuitRequested: () => quitRequested = true),
      );

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();

      expect(quitRequested, true);

      await disposeAndDrainTimers(tester);
    });

    testWidgets('has Start Timer button initially', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Start Timer'), findsOneWidget);

      await disposeAndDrainTimers(tester);
    });

    testWidgets('has Next button', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Next'), findsOneWidget);

      await disposeAndDrainTimers(tester);
    });

    testWidgets('displays custom exercises', (tester) async {
      final customExercises = [
        const WarmupExerciseData(
          name: 'Custom Warmup',
          duration: 45,
          icon: Icons.sports,
        ),
      ];

      await tester.pumpWidget(buildTestWidget(exercises: customExercises));

      expect(find.text('Custom Warmup'), findsOneWidget);
      expect(find.text('1 of 1'), findsOneWidget);

      await disposeAndDrainTimers(tester);
    });

    testWidgets('shows Start Workout on last exercise', (tester) async {
      final singleExercise = [
        const WarmupExerciseData(
          name: 'Only Exercise',
          duration: 30,
          icon: Icons.sports,
        ),
      ];

      await tester.pumpWidget(buildTestWidget(exercises: singleExercise));

      expect(find.text('Start Workout'), findsOneWidget);

      await disposeAndDrainTimers(tester);
    });

    testWidgets('has warmup icon', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byIcon(Icons.local_fire_department), findsOneWidget);

      await disposeAndDrainTimers(tester);
    });

    testWidgets('displays progress indicator', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      await disposeAndDrainTimers(tester);
    });
  });
}
