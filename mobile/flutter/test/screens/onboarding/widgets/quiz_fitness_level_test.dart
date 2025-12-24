import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_fitness_coach/screens/onboarding/widgets/quiz_fitness_level.dart';

void main() {
  group('QuizFitnessLevel', () {
    testWidgets('displays question text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuizFitnessLevel(
              selectedLevel: null,
              selectedExperience: null,
              onLevelChanged: (_) {},
              onExperienceChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text("What's your current fitness level?"), findsOneWidget);
    });

    testWidgets('displays fitness level options', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuizFitnessLevel(
              selectedLevel: null,
              selectedExperience: null,
              onLevelChanged: (_) {},
              onExperienceChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Beginner'), findsOneWidget);
      expect(find.text('Intermediate'), findsOneWidget);
      expect(find.text('Advanced'), findsOneWidget);
    });

    testWidgets('calls onLevelChanged when level is selected', (tester) async {
      String? selectedLevel;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuizFitnessLevel(
              selectedLevel: null,
              selectedExperience: null,
              onLevelChanged: (level) {
                selectedLevel = level;
              },
              onExperienceChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Beginner'));
      await tester.pump();

      expect(selectedLevel, equals('beginner'));
    });

    testWidgets('shows experience options after level is selected', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuizFitnessLevel(
              selectedLevel: 'beginner',
              selectedExperience: null,
              onLevelChanged: (_) {},
              onExperienceChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('How long have you been lifting weights?'), findsOneWidget);
    });

    testWidgets('hides experience options when no level selected', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuizFitnessLevel(
              selectedLevel: null,
              selectedExperience: null,
              onLevelChanged: (_) {},
              onExperienceChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('How long have you been lifting weights?'), findsNothing);
    });

    testWidgets('calls onExperienceChanged when experience is selected', (tester) async {
      String? selectedExperience;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuizFitnessLevel(
              selectedLevel: 'beginner',
              selectedExperience: null,
              onLevelChanged: (_) {},
              onExperienceChanged: (exp) {
                selectedExperience = exp;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Never'));
      await tester.pump();

      expect(selectedExperience, equals('never'));
    });

    testWidgets('shows check mark for selected level', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuizFitnessLevel(
              selectedLevel: 'intermediate',
              selectedExperience: null,
              onLevelChanged: (_) {},
              onExperienceChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('renders in dark mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: QuizFitnessLevel(
              selectedLevel: null,
              selectedExperience: null,
              onLevelChanged: (_) {},
              onExperienceChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text("What's your current fitness level?"), findsOneWidget);
    });

    testWidgets('renders in light mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: QuizFitnessLevel(
              selectedLevel: null,
              selectedExperience: null,
              onLevelChanged: (_) {},
              onExperienceChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text("What's your current fitness level?"), findsOneWidget);
    });
  });
}
