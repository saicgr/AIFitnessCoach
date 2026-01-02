import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/screens/onboarding/widgets/quiz_continue_button.dart';

void main() {
  group('QuizContinueButton', () {
    testWidgets('shows "Continue" text when not last question', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuizContinueButton(
              canProceed: true,
              isLastQuestion: false,
              onPressed: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('shows "See My Plan" text when last question', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuizContinueButton(
              canProceed: true,
              isLastQuestion: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('See My Plan'), findsOneWidget);
    });

    testWidgets('button is enabled when canProceed is true', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuizContinueButton(
              canProceed: true,
              isLastQuestion: false,
              onPressed: () {
                pressed = true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('button is disabled when canProceed is false', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuizContinueButton(
              canProceed: false,
              isLastQuestion: false,
              onPressed: () {
                pressed = true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(pressed, isFalse);
    });

    testWidgets('shows arrow icon when canProceed is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuizContinueButton(
              canProceed: true,
              isLastQuestion: false,
              onPressed: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
    });

    testWidgets('hides arrow icon when canProceed is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuizContinueButton(
              canProceed: false,
              isLastQuestion: false,
              onPressed: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.arrow_forward_rounded), findsNothing);
    });

    testWidgets('renders in dark mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: QuizContinueButton(
              canProceed: true,
              isLastQuestion: false,
              onPressed: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('renders in light mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: QuizContinueButton(
              canProceed: true,
              isLastQuestion: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('See My Plan'), findsOneWidget);
    });
  });
}
