import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/screens/library/widgets/exercise_card.dart';
import 'package:fitwiz/data/models/exercise.dart';
import 'package:fitwiz/widgets/signature/signature.dart';

// The signature-v2 redesign turned ExerciseCard from a badge-stack card into a
// dense [ZHairlineRow]: the muscle group / difficulty / equipment now render as
// ONE uppercase metadata line (`●LEVEL · MUSCLE · EQUIPMENT`) instead of
// separate title-case badges, and the trailing chevron was replaced by three
// inline actions (favourite / add-to-workout / alternatives). These tests
// assert that shape.
void main() {
  group('ExerciseCard', () {
    LibraryExercise createExercise({
      String name = 'Bench Press',
      String? bodyPart,
      String? difficultyLevel,
      String? equipment,
      String? videoUrl,
    }) {
      return LibraryExercise(
        id: 'test-id',
        nameValue: name,
        bodyPart: bodyPart,
        difficultyLevelValue: difficultyLevel,
        equipmentValue: equipment,
        videoUrl: videoUrl,
      );
    }

    testWidgets('renders exercise name', (WidgetTester tester) async {
      final exercise = createExercise(name: 'Squat');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ExerciseCard(exercise: exercise),
            ),
          ),
        ),
      );

      expect(find.text('Squat'), findsOneWidget);
    });

    testWidgets('renders muscle group in the metadata line when provided',
        (WidgetTester tester) async {
      final exercise = createExercise(
        name: 'Bench Press',
        bodyPart: 'Chest',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ExerciseCard(exercise: exercise),
            ),
          ),
        ),
      );

      expect(find.text('CHEST'), findsOneWidget);
    });

    testWidgets('renders difficulty level when provided',
        (WidgetTester tester) async {
      final exercise = createExercise(
        name: 'Deadlift',
        difficultyLevel: 'Intermediate',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ExerciseCard(exercise: exercise),
            ),
          ),
        ),
      );

      expect(find.text('INTERMEDIATE'), findsOneWidget);
    });

    testWidgets('renders the primary equipment when provided',
        (WidgetTester tester) async {
      final exercise = createExercise(
        name: 'Incline Press',
        equipment: 'Barbell, Bench',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ExerciseCard(exercise: exercise),
            ),
          ),
        ),
      );

      // The dense row shows only the primary (first) piece of equipment so the
      // metadata line stays on one line at 9.5px.
      expect(find.text('BARBELL'), findsOneWidget);
      expect(find.textContaining('Bench'), findsNothing);
    });

    testWidgets('shows video indicator when video is available',
        (WidgetTester tester) async {
      final exercise = createExercise(
        name: 'Pull-up',
        videoUrl: 'https://example.com/video.mp4',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ExerciseCard(exercise: exercise),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('hides video indicator when no video',
        (WidgetTester tester) async {
      final exercise = createExercise(
        name: 'Push-up',
        videoUrl: null,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ExerciseCard(exercise: exercise),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.play_arrow), findsNothing);
    });

    testWidgets('shows the inline row actions instead of a chevron',
        (WidgetTester tester) async {
      final exercise = createExercise();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ExerciseCard(exercise: exercise),
            ),
          ),
        ),
      );

      // The trailing chevron was replaced by three inline actions: favourite,
      // add-to-workout and alternatives.
      expect(find.byIcon(Icons.chevron_right), findsNothing);
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.swap_horiz), findsOneWidget);
    });

    testWidgets('the row is tappable', (WidgetTester tester) async {
      final exercise = createExercise();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ExerciseCard(exercise: exercise),
            ),
          ),
        ),
      );

      // Actually firing the tap would push the exercise-browse route, which
      // resolves the library repository (and therefore Supabase) — out of
      // reach in a widget test. Assert the tap affordance is wired instead.
      final row = tester.widget<ZHairlineRow>(find.byType(ZHairlineRow));
      expect(row.onTap, isNotNull);
    });

    testWidgets('renders correctly in dark mode',
        (WidgetTester tester) async {
      final exercise = createExercise(
        name: 'Lat Pulldown',
        bodyPart: 'Back',
        difficultyLevel: 'Beginner',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              body: ExerciseCard(exercise: exercise),
            ),
          ),
        ),
      );

      expect(find.text('Lat Pulldown'), findsOneWidget);
      // Level + muscle share one metadata line: `BEGINNER · BACK`.
      expect(find.text('BEGINNER'), findsOneWidget);
      expect(find.textContaining('BACK'), findsOneWidget);
    });

    testWidgets('renders correctly in light mode',
        (WidgetTester tester) async {
      final exercise = createExercise(
        name: 'Bicep Curl',
        bodyPart: 'Arms',
        difficultyLevel: 'Beginner',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.light(),
            home: Scaffold(
              body: ExerciseCard(exercise: exercise),
            ),
          ),
        ),
      );

      expect(find.text('Bicep Curl'), findsOneWidget);
      expect(find.text('BEGINNER'), findsOneWidget);
      expect(find.textContaining('ARMS'), findsOneWidget);
    });

    testWidgets('truncates long equipment list',
        (WidgetTester tester) async {
      final exercise = createExercise(
        name: 'Cable Crossover',
        equipment: 'Cable Machine, D-Handle, Extra Handle',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ExerciseCard(exercise: exercise),
            ),
          ),
        ),
      );

      // Only the first equipment item survives into the dense metadata line.
      expect(find.text('CABLE MACHINE'), findsOneWidget);
      expect(find.textContaining('D-Handle'), findsNothing);
      expect(find.textContaining('Extra Handle'), findsNothing);
    });
  });
}
