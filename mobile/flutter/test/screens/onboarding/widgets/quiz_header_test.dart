import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/screens/onboarding/widgets/quiz_header.dart';
import 'package:fitwiz/l10n/generated/app_localizations.dart';

void main() {
  group('QuizHeader', () {
    // v7 redesign: the default header shows a time-remaining estimate, and the
    // bounded "STEP n OF m" counter is the `onboarding_step_counter` treatment
    // (showStepCount: true).
    testWidgets('displays time-remaining estimate by default', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
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
      // 3 questions left * 15s = 45s -> ceil to 1 minute.
      expect(find.text('~1 min left'), findsOneWidget);
    });

    testWidgets('displays question counter correctly under step-count treatment', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: QuizHeader(
              currentQuestion: 2,
              totalQuestions: 5,
              canGoBack: true,
              onBack: () {},
              showStepCount: true,
              requiredQuestions: 5,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('STEP 3 OF 5'), findsOneWidget);
    });

    testWidgets('shows ALMOST DONE past the required questions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: QuizHeader(
              currentQuestion: 6,
              totalQuestions: 9,
              canGoBack: true,
              onBack: () {},
              showStepCount: true,
              requiredQuestions: 5,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('ALMOST DONE'), findsOneWidget);
    });

    testWidgets('shows back button when canGoBack is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
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
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    });

    testWidgets('hides back button when canGoBack is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
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
      expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
    });

    testWidgets('calls onBack when back button is tapped', (tester) async {
      bool backCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
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
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pump();

      expect(backCalled, isTrue);
    });

    // Note: Skip functionality tests removed - QuizHeader no longer has onSkip parameter
  });
}
