import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/screens/onboarding/widgets/quiz_header.dart';

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
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_back_ios_rounded));
      await tester.pump();

      expect(backCalled, isTrue);
    });

    // Note: Skip functionality tests removed - QuizHeader no longer has onSkip parameter
  });
}
