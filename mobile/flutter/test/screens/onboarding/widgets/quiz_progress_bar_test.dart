import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_fitness_coach/screens/onboarding/widgets/quiz_progress_bar.dart';

void main() {
  group('QuizProgressBar', () {
    testWidgets('renders progress bar container', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuizProgressBar(progress: 0.5),
          ),
        ),
      );

      expect(find.byType(QuizProgressBar), findsOneWidget);
    });

    testWidgets('animates progress from 0 to target', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuizProgressBar(progress: 0.8),
          ),
        ),
      );

      // Initial state
      await tester.pump();

      // Animation in progress
      await tester.pump(const Duration(milliseconds: 200));

      // Animation complete
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(QuizProgressBar), findsOneWidget);
    });

    testWidgets('renders in dark mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: QuizProgressBar(progress: 0.3),
          ),
        ),
      );

      expect(find.byType(QuizProgressBar), findsOneWidget);
    });

    testWidgets('renders in light mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const Scaffold(
            body: QuizProgressBar(progress: 0.7),
          ),
        ),
      );

      expect(find.byType(QuizProgressBar), findsOneWidget);
    });

    testWidgets('handles zero progress', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuizProgressBar(progress: 0.0),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(QuizProgressBar), findsOneWidget);
    });

    testWidgets('handles full progress', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuizProgressBar(progress: 1.0),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(QuizProgressBar), findsOneWidget);
    });
  });
}
