import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/l10n/generated/app_localizations.dart';
import 'package:fitwiz/screens/workout/widgets/workout_bottom_bar.dart';
import 'package:fitwiz/data/models/exercise.dart';

void main() {
  WorkoutExercise createTestExercise({
    String name = 'Bench Press',
    int? sets = 3,
    int? reps = 10,
    double? weight = 60.0,
    int? restSeconds = 90,
    String? notes,
  }) {
    return WorkoutExercise(
      id: 'test_id',
      nameValue: name,
      sets: sets,
      reps: reps,
      weight: weight,
      restSeconds: restSeconds,
      notes: notes,
    );
  }

  Widget buildTestWidget({
    required WorkoutExercise currentExercise,
    WorkoutExercise? nextExercise,
    List<WorkoutExercise>? allExercises,
    int currentExerciseIndex = 0,
    bool showInstructions = false,
    bool isResting = false,
    VoidCallback? onToggleInstructions,
    VoidCallback? onSkip,
    VoidCallback? onShowExerciseInfo,
  }) {
    final exercises =
        allExercises ??
        [currentExercise, if (nextExercise != null) nextExercise];
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData.dark(),
      home: Scaffold(
        body: Column(
          children: [
            const Spacer(),
            WorkoutBottomBar(
              currentExercise: currentExercise,
              nextExercise: nextExercise,
              allExercises: exercises,
              currentExerciseIndex: currentExerciseIndex,
              showInstructions: showInstructions,
              isResting: isResting,
              onToggleInstructions: onToggleInstructions ?? () {},
              onSkip: onSkip ?? () {},
              onShowExerciseInfo: onShowExerciseInfo,
            ),
          ],
        ),
      ),
    );
  }

  group('WorkoutBottomBar', () {
    // The bar was redesigned into a Hevy-style action row
    // ([water][breathe] | Instructions | Skip). It no longer renders the
    // next-exercise strip, an inline instructions panel, notes or duration —
    // `nextExercise` / `showInstructions` / `onToggleInstructions` are retained
    // on the constructor for source compatibility only. These tests pin the
    // shape the widget actually has today.
    testWidgets('renders the water and breathe quick actions', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(currentExercise: createTestExercise()),
      );

      expect(find.byIcon(Icons.water_drop_outlined), findsOneWidget);
      expect(find.byIcon(Icons.air_rounded), findsOneWidget);
    });

    testWidgets('does not render a next-exercise strip', (tester) async {
      final current = createTestExercise(name: 'Bench Press');
      final next = createTestExercise(name: 'Incline Press');

      await tester.pumpWidget(
        buildTestWidget(currentExercise: current, nextExercise: next),
      );

      expect(find.text('Next'), findsNothing);
      expect(find.text('Incline Press'), findsNothing);
      // The action row is what renders instead.
      expect(find.text('Instructions'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('renders the same action row on the last exercise', (
      tester,
    ) async {
      final current = createTestExercise(name: 'Final Exercise');

      await tester.pumpWidget(
        buildTestWidget(currentExercise: current, nextExercise: null),
      );

      expect(find.text('Last Exercise!'), findsNothing);
      expect(find.text('Instructions'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('skip button shows Skip by default', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          currentExercise: createTestExercise(),
          isResting: false,
        ),
      );

      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('skip button label stays Skip while resting', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(currentExercise: createTestExercise(), isResting: true),
      );

      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Skip Rest'), findsNothing);
    });

    testWidgets('skip button calls callback', (tester) async {
      bool skipped = false;

      await tester.pumpWidget(
        buildTestWidget(
          currentExercise: createTestExercise(),
          onSkip: () => skipped = true,
        ),
      );

      await tester.tap(find.text('Skip'));
      await tester.pump();

      expect(skipped, true);
    });

    testWidgets('instructions button calls onShowExerciseInfo', (tester) async {
      bool opened = false;

      await tester.pumpWidget(
        buildTestWidget(
          currentExercise: createTestExercise(),
          onShowExerciseInfo: () => opened = true,
        ),
      );

      await tester.tap(find.text('Instructions'));
      await tester.pump();

      expect(opened, true);
    });

    testWidgets('does not render an inline instructions panel', (tester) async {
      final exercise = createTestExercise(
        name: 'Squat',
        sets: 4,
        reps: 8,
        weight: 100.0,
      );

      await tester.pumpWidget(
        buildTestWidget(currentExercise: exercise, showInstructions: true),
      );

      // Only the button label survives; the set/rep/weight panel moved into the
      // exercise-info bottom sheet opened by onShowExerciseInfo.
      expect(find.text('Instructions'), findsOneWidget);
      expect(find.text('Reps'), findsNothing);
      expect(find.text('8 reps'), findsNothing);
      expect(find.text('Sets'), findsNothing);
      expect(find.text('4 sets'), findsNothing);
      expect(find.text('Weight'), findsNothing);
      expect(find.text('100.0 kg'), findsNothing);
    });

    testWidgets('does not render exercise notes inline', (tester) async {
      final exercise = createTestExercise(notes: 'Keep back straight');

      await tester.pumpWidget(
        buildTestWidget(currentExercise: exercise, showInstructions: true),
      );

      expect(find.text('Keep back straight'), findsNothing);
    });

    testWidgets('does not render duration for timed exercises inline', (
      tester,
    ) async {
      final exercise = WorkoutExercise(
        id: 'test',
        nameValue: 'Plank',
        durationSeconds: 60,
      );

      await tester.pumpWidget(
        buildTestWidget(currentExercise: exercise, showInstructions: true),
      );

      expect(find.text('60s'), findsNothing);
      expect(find.text('Instructions'), findsOneWidget);
    });
  });

  group('SetDotsIndicator', () {
    Widget buildDotsWidget({
      required int totalSets,
      required int completedSets,
    }) {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SetDotsIndicator(
            totalSets: totalSets,
            completedSets: completedSets,
          ),
        ),
      );
    }

    testWidgets('displays correct set count', (tester) async {
      await tester.pumpWidget(buildDotsWidget(totalSets: 4, completedSets: 2));

      expect(find.text('Set 3 of 4'), findsOneWidget);
    });

    testWidgets('shows first set initially', (tester) async {
      await tester.pumpWidget(buildDotsWidget(totalSets: 3, completedSets: 0));

      expect(find.text('Set 1 of 3'), findsOneWidget);
    });
  });

  group('ExerciseOptionTile', () {
    testWidgets('displays title and subtitle', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ExerciseOptionTile(
              icon: Icons.swap_horiz,
              title: 'Swap Exercise',
              subtitle: 'Replace with similar exercise',
              color: Colors.cyan,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Swap Exercise'), findsOneWidget);
      expect(find.text('Replace with similar exercise'), findsOneWidget);
    });

    testWidgets('displays icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ExerciseOptionTile(
              icon: Icons.skip_next,
              title: 'Skip',
              subtitle: 'Move to next',
              color: Colors.orange,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.skip_next), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ExerciseOptionTile(
              icon: Icons.info,
              title: 'Info',
              subtitle: 'View details',
              color: Colors.blue,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ExerciseOptionTile));
      await tester.pump();

      expect(tapped, true);
    });
  });
}
