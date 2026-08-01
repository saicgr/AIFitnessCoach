import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/l10n/generated/app_localizations.dart';
import 'package:fitwiz/screens/workout/widgets/workout_top_overlay.dart';
import 'package:fitwiz/screens/workout/controllers/workout_timer_controller.dart';

void main() {
  Widget buildTestWidget({
    int workoutSeconds = 300,
    bool isPaused = false,
    int totalExercises = 5,
    int currentExerciseIndex = 2,
    int totalCompletedSets = 6,
    VoidCallback? onTogglePause,
    VoidCallback? onShowExerciseList,
    VoidCallback? onQuit,
    double scaleFactor = 1.0,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData.dark(),
      home: Scaffold(
        body: Stack(
          children: [
            WorkoutTopOverlay(
              workoutSeconds: workoutSeconds,
              isPaused: isPaused,
              totalExercises: totalExercises,
              currentExerciseIndex: currentExerciseIndex,
              totalCompletedSets: totalCompletedSets,
              onTogglePause: onTogglePause ?? () {},
              onShowExerciseList: onShowExerciseList ?? () {},
              onQuit: onQuit ?? () {},
              scaleFactor: scaleFactor,
            ),
          ],
        ),
      ),
    );
  }

  group('WorkoutTopOverlay', () {
    testWidgets('displays formatted workout time', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          workoutSeconds: 125, // 2:05
        ),
      );

      expect(find.text('02:05'), findsOneWidget);
    });

    // The overlay was simplified to [pause] — timer — [close] over a progress
    // bar. The old "3/5" / "N sets" stat chips are gone (the exercise list and
    // set counters live in the set-tracking overlay now), so exercise progress
    // is asserted through the bar's fill fraction instead of a text label.
    testWidgets('exercise progress drives the progress bar fill', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(totalExercises: 5, currentExerciseIndex: 2),
      );

      final bar = tester.widget<AnimatedFractionallySizedBox>(
        find.byType(AnimatedFractionallySizedBox),
      );
      expect(bar.widthFactor, closeTo(3 / 5, 0.0001));
      expect(find.text('3/5'), findsNothing);
    });

    testWidgets('does not render a completed sets chip', (tester) async {
      await tester.pumpWidget(buildTestWidget(totalCompletedSets: 8));

      expect(find.text('8'), findsNothing);
      expect(find.text(' sets'), findsNothing);
    });

    testWidgets('shows timer icon when not paused', (tester) async {
      await tester.pumpWidget(buildTestWidget(isPaused: false));

      expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
    });

    testWidgets('shows pause icon when paused', (tester) async {
      await tester.pumpWidget(buildTestWidget(isPaused: true));

      expect(find.byIcon(Icons.pause), findsOneWidget);
    });

    testWidgets('has close button', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('close button calls onQuit', (tester) async {
      bool quitCalled = false;

      await tester.pumpWidget(buildTestWidget(onQuit: () => quitCalled = true));

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(quitCalled, true);
    });

    testWidgets('tapping timer stat calls onTogglePause', (tester) async {
      bool togglePauseCalled = false;

      await tester.pumpWidget(
        buildTestWidget(onTogglePause: () => togglePauseCalled = true),
      );

      // Find and tap the timer chip
      await tester.tap(find.byIcon(Icons.timer_outlined));
      await tester.pump();

      expect(togglePauseCalled, true);
    });

    testWidgets('pause button also calls onTogglePause', (tester) async {
      bool togglePauseCalled = false;

      await tester.pumpWidget(
        buildTestWidget(onTogglePause: () => togglePauseCalled = true),
      );

      await tester.tap(find.byIcon(Icons.pause));
      await tester.pump();

      expect(togglePauseCalled, true);
    });

    testWidgets('no longer renders an exercise-list stat chip', (tester) async {
      // `onShowExerciseList` is vestigial — the simplified overlay has no
      // fitness_center chip, and the only production caller passes a no-op.
      await tester.pumpWidget(buildTestWidget());

      expect(find.byIcon(Icons.fitness_center), findsNothing);
    });
  });

  group('WorkoutStatChip', () {
    testWidgets('displays value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: WorkoutStatChip(
              icon: Icons.timer,
              value: '05:30',
              color: Colors.cyan,
            ),
          ),
        ),
      );

      expect(find.text('05:30'), findsOneWidget);
    });

    testWidgets('displays suffix when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: WorkoutStatChip(
              icon: Icons.check,
              value: '10',
              suffix: ' sets',
              color: Colors.green,
            ),
          ),
        ),
      );

      expect(find.text('10'), findsOneWidget);
      expect(find.text(' sets'), findsOneWidget);
    });

    testWidgets('displays label instead of value when provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: WorkoutStatChip(
              icon: Icons.pause,
              value: '05:30',
              label: 'PAUSED',
              color: Colors.orange,
            ),
          ),
        ),
      );

      expect(find.text('PAUSED'), findsOneWidget);
      expect(find.text('05:30'), findsNothing);
    });

    testWidgets('calls onTap when tappable', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: WorkoutStatChip(
              icon: Icons.timer,
              value: '05:30',
              color: Colors.cyan,
              isTappable: true,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(WorkoutStatChip));
      await tester.pump();

      expect(tapped, true);
    });
  });

  group('GlassButton', () {
    testWidgets('displays icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: GlassButton(icon: Icons.close, onTap: () {}),
          ),
        ),
      );

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: GlassButton(icon: Icons.close, onTap: () => tapped = true),
          ),
        ),
      );

      await tester.tap(find.byType(GlassButton));
      await tester.pump();

      expect(tapped, true);
    });

    testWidgets('respects size parameter', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: GlassButton(icon: Icons.close, onTap: () {}, size: 60),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(GlassButton),
              matching: find.byType(Container),
            )
            .first,
      );

      expect(container.constraints?.maxWidth, 60);
      expect(container.constraints?.maxHeight, 60);
    });
  });

  group('WorkoutTimerController.formatTime', () {
    test('formats zero correctly', () {
      expect(WorkoutTimerController.formatTime(0), '00:00');
    });

    test('formats seconds only', () {
      expect(WorkoutTimerController.formatTime(45), '00:45');
    });

    test('formats minutes and seconds', () {
      expect(WorkoutTimerController.formatTime(90), '01:30');
    });

    test('formats hours correctly', () {
      expect(WorkoutTimerController.formatTime(3661), '61:01');
    });

    test('pads single digits', () {
      expect(WorkoutTimerController.formatTime(65), '01:05');
    });
  });
}
