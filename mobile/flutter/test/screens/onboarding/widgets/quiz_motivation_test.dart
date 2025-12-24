import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_fitness_coach/screens/onboarding/widgets/quiz_motivation.dart';

void main() {
  group('QuizMotivation', () {
    testWidgets('displays question text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuizMotivation(
              selectedMotivations: const {},
              onToggle: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text("What's driving you to work out?"), findsOneWidget);
    });

    testWidgets('displays subtitle text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuizMotivation(
              selectedMotivations: const {},
              onToggle: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Select all that resonate with you'), findsOneWidget);
    });

    testWidgets('displays motivation options', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuizMotivation(
              selectedMotivations: const {},
              onToggle: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Look better'), findsOneWidget);
      expect(find.text('Feel stronger'), findsOneWidget);
      expect(find.text('Have more energy'), findsOneWidget);
    });

    testWidgets('calls onToggle when option is tapped', (tester) async {
      String? toggledId;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuizMotivation(
              selectedMotivations: const {},
              onToggle: (id) {
                toggledId = id;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Look better'));
      await tester.pump();

      expect(toggledId, equals('look_better'));
    });

    testWidgets('shows check mark for selected options', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuizMotivation(
              selectedMotivations: const {'look_better', 'feel_stronger'},
              onToggle: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check), findsNWidgets(2));
    });

    testWidgets('renders in dark mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: QuizMotivation(
              selectedMotivations: const {},
              onToggle: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text("What's driving you to work out?"), findsOneWidget);
    });

    testWidgets('renders in light mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: QuizMotivation(
              selectedMotivations: const {},
              onToggle: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text("What's driving you to work out?"), findsOneWidget);
    });
  });
}
