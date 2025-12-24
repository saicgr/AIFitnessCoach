import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_fitness_coach/screens/onboarding/widgets/quiz_header.dart';

void main() {
  group('QuizHeader', () {
    testWidgets('displays question counter correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuizHeader(
              currentQuestion: 2,
              totalQuestions: 5,
              canGoBack: true,
              onBack: () {},
              onSkip: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('3 of 5'), findsOneWidget);
    });

    testWidgets('shows back button when canGoBack is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuizHeader(
              currentQuestion: 1,
              totalQuestions: 5,
              canGoBack: true,
              onBack: () {},
              onSkip: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.arrow_back_ios_rounded), findsOneWidget);
    });

    testWidgets('hides back button when canGoBack is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuizHeader(
              currentQuestion: 0,
              totalQuestions: 5,
              canGoBack: false,
              onBack: () {},
              onSkip: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.arrow_back_ios_rounded), findsNothing);
    });

    testWidgets('calls onBack when back button is tapped', (tester) async {
      bool backCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuizHeader(
              currentQuestion: 1,
              totalQuestions: 5,
              canGoBack: true,
              onBack: () {
                backCalled = true;
              },
              onSkip: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_back_ios_rounded));
      await tester.pump();

      expect(backCalled, isTrue);
    });

    testWidgets('shows skip button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuizHeader(
              currentQuestion: 0,
              totalQuestions: 5,
              canGoBack: false,
              onBack: () {},
              onSkip: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('calls onSkip when skip button is tapped', (tester) async {
      bool skipCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuizHeader(
              currentQuestion: 0,
              totalQuestions: 5,
              canGoBack: false,
              onBack: () {},
              onSkip: () {
                skipCalled = true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip'));
      await tester.pump();

      expect(skipCalled, isTrue);
    });
  });
}
