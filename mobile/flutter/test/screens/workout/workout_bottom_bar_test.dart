import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
  }) {
    final exercises = allExercises ?? [currentExercise, if (nextExercise != null) nextExercise];
    return MaterialApp(
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
            ),
          ],
        ),
      ),
    );
  }

  group('WorkoutBottomBar', () {
    testWidgets('displays next exercise indicator', (tester) async {
      final current = createTestExercise(name: 'Bench Press');
      final next = createTestExercise(name: 'Incline Press');

      await tester.pumpWidget(buildTestWidget(
        currentExercise: current,
        nextExercise: next,
      ));

      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Incline Press'), findsOneWidget);
    });

    testWidgets('displays last exercise indicator when no next', (tester) async {
      final current = createTestExercise(name: 'Final Exercise');

      await tester.pumpWidget(buildTestWidget(
        currentExercise: current,
        nextExercise: null,
      ));

      expect(find.text('Last Exercise!'), findsOneWidget);
    });

    testWidgets('skip button shows Skip by default', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        currentExercise: createTestExercise(),
        isResting: false,
      ));

      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('skip button shows Skip Rest when resting', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        currentExercise: createTestExercise(),
        isResting: true,
      ));

      expect(find.text('Skip Rest'), findsOneWidget);
    });

    testWidgets('skip button calls callback', (tester) async {
      bool skipped = false;

      await tester.pumpWidget(buildTestWidget(
        currentExercise: createTestExercise(),
        onSkip: () => skipped = true,
      ));

      await tester.tap(find.text('Skip'));
      await tester.pump();

      expect(skipped, true);
    });

    testWidgets('toggle instructions button works', (tester) async {
      bool toggled = false;

      await tester.pumpWidget(buildTestWidget(
        currentExercise: createTestExercise(),
        showInstructions: false,
        onToggleInstructions: () => toggled = true,
      ));

      // Find and tap the expand button
      await tester.tap(find.byIcon(Icons.expand_less));
      await tester.pump();

      expect(toggled, true);
    });

    testWidgets('shows instructions panel when showInstructions is true', (tester) async {
      final exercise = createTestExercise(
        name: 'Squat',
        sets: 4,
        reps: 8,
        weight: 100.0,
      );

      await tester.pumpWidget(buildTestWidget(
        currentExercise: exercise,
        showInstructions: true,
      ));

      expect(find.text('Instructions'), findsOneWidget);
      expect(find.text('Reps'), findsOneWidget);
      expect(find.text('8 reps'), findsOneWidget);
      expect(find.text('Sets'), findsOneWidget);
      expect(find.text('4 sets'), findsOneWidget);
      expect(find.text('Weight'), findsOneWidget);
      expect(find.text('100.0 kg'), findsOneWidget);
    });

    testWidgets('shows notes when provided', (tester) async {
      final exercise = createTestExercise(
        notes: 'Keep back straight',
      );

      await tester.pumpWidget(buildTestWidget(
        currentExercise: exercise,
        showInstructions: true,
      ));

      expect(find.text('Keep back straight'), findsOneWidget);
    });

    testWidgets('shows duration for timed exercises', (tester) async {
      final exercise = WorkoutExercise(
        id: 'test',
        nameValue: 'Plank',
        durationSeconds: 60,
      );

      await tester.pumpWidget(buildTestWidget(
        currentExercise: exercise,
        showInstructions: true,
      ));

      expect(find.text('60s'), findsOneWidget);
    });
  });

  group('SetDotsIndicator', () {
    Widget buildDotsWidget({
      required int totalSets,
      required int completedSets,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SetDotsIndicator(
            totalSets: totalSets,
            completedSets: completedSets,
          ),
        ),
      );
    }

    testWidgets('displays correct set count', (tester) async {
      await tester.pumpWidget(buildDotsWidget(
        totalSets: 4,
        completedSets: 2,
      ));

      expect(find.text('Set 3 of 4'), findsOneWidget);
    });

    testWidgets('shows first set initially', (tester) async {
      await tester.pumpWidget(buildDotsWidget(
        totalSets: 3,
        completedSets: 0,
      ));

      expect(find.text('Set 1 of 3'), findsOneWidget);
    });
  });

  group('ExerciseOptionTile', () {
    testWidgets('displays title and subtitle', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ExerciseOptionTile(
            icon: Icons.swap_horiz,
            title: 'Swap Exercise',
            subtitle: 'Replace with similar exercise',
            color: Colors.cyan,
            onTap: () {},
          ),
        ),
      ));

      expect(find.text('Swap Exercise'), findsOneWidget);
      expect(find.text('Replace with similar exercise'), findsOneWidget);
    });

    testWidgets('displays icon', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ExerciseOptionTile(
            icon: Icons.skip_next,
            title: 'Skip',
            subtitle: 'Move to next',
            color: Colors.orange,
            onTap: () {},
          ),
        ),
      ));

      expect(find.byIcon(Icons.skip_next), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ExerciseOptionTile(
            icon: Icons.info,
            title: 'Info',
            subtitle: 'View details',
            color: Colors.blue,
            onTap: () => tapped = true,
          ),
        ),
      ));

      await tester.tap(find.byType(ExerciseOptionTile));
      await tester.pump();

      expect(tapped, true);
    });
  });
}
