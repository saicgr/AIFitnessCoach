import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/screens/library/widgets/exercise_card.dart';
import 'package:fitwiz/data/models/exercise.dart';

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

    testWidgets('renders muscle group badge when provided',
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

      expect(find.text('Chest'), findsOneWidget);
    });

    testWidgets('renders difficulty badge when provided',
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

      expect(find.text('Intermediate'), findsOneWidget);
    });

    testWidgets('renders equipment list when provided',
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

      expect(find.text('Barbell, Bench'), findsOneWidget);
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

    testWidgets('shows chevron right icon', (WidgetTester tester) async {
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

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('is tappable', (WidgetTester tester) async {
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

      // Tapping should not throw an error
      await tester.tap(find.byType(ExerciseCard));
      await tester.pump();
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
      expect(find.text('Back'), findsOneWidget);
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
      expect(find.text('Arms'), findsOneWidget);
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

      // Should only show first 2 equipment items
      expect(find.text('Cable Machine, D-Handle'), findsOneWidget);
    });
  });
}
