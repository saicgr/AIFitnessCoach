import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_fitness_coach/screens/onboarding/widgets/quiz_days_selector.dart';

void main() {
  group('QuizDaysSelector', () {
    testWidgets('displays question text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuizDaysSelector(
              selectedDays: null,
              selectedWorkoutDays: const {},
              onDaysChanged: (_) {},
              onWorkoutDayToggled: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('How many days per week can you train?'), findsOneWidget);
    });

    testWidgets('displays all day count options', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuizDaysSelector(
              selectedDays: null,
              selectedWorkoutDays: const {},
              onDaysChanged: (_) {},
              onWorkoutDayToggled: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      for (int i = 1; i <= 7; i++) {
        expect(find.text('$i'), findsOneWidget);
      }
    });

    testWidgets('calls onDaysChanged when day count is selected', (tester) async {
      int? selectedDays;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuizDaysSelector(
              selectedDays: null,
              selectedWorkoutDays: const {},
              onDaysChanged: (days) {
                selectedDays = days;
              },
              onWorkoutDayToggled: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('3'));
      await tester.pump();

      expect(selectedDays, equals(3));
    });

    testWidgets('shows specific days picker after days count is selected', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuizDaysSelector(
              selectedDays: 3,
              selectedWorkoutDays: const {},
              onDaysChanged: (_) {},
              onWorkoutDayToggled: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Which days work best?'), findsOneWidget);
    });

    testWidgets('hides specific days picker when no days count selected', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuizDaysSelector(
              selectedDays: null,
              selectedWorkoutDays: const {},
              onDaysChanged: (_) {},
              onWorkoutDayToggled: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Which days work best?'), findsNothing);
    });

    testWidgets('displays day abbreviations when days count is selected', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuizDaysSelector(
              selectedDays: 3,
              selectedWorkoutDays: const {},
              onDaysChanged: (_) {},
              onWorkoutDayToggled: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Tue'), findsOneWidget);
      expect(find.text('Wed'), findsOneWidget);
      expect(find.text('Thu'), findsOneWidget);
      expect(find.text('Fri'), findsOneWidget);
      expect(find.text('Sat'), findsOneWidget);
      expect(find.text('Sun'), findsOneWidget);
    });

    testWidgets('calls onWorkoutDayToggled when specific day is tapped', (tester) async {
      int? toggledDay;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuizDaysSelector(
              selectedDays: 3,
              selectedWorkoutDays: const {},
              onDaysChanged: (_) {},
              onWorkoutDayToggled: (day) {
                toggledDay = day;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Mon'));
      await tester.pump();

      expect(toggledDay, equals(0)); // Monday is index 0
    });

    testWidgets('shows selection counter', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuizDaysSelector(
              selectedDays: 3,
              selectedWorkoutDays: const {0, 2}, // Mon, Wed
              onDaysChanged: (_) {},
              onWorkoutDayToggled: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('2 / 3 days selected'), findsOneWidget);
    });

    testWidgets('renders in dark mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: QuizDaysSelector(
              selectedDays: null,
              selectedWorkoutDays: const {},
              onDaysChanged: (_) {},
              onWorkoutDayToggled: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('How many days per week can you train?'), findsOneWidget);
    });

    testWidgets('renders in light mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: QuizDaysSelector(
              selectedDays: null,
              selectedWorkoutDays: const {},
              onDaysChanged: (_) {},
              onWorkoutDayToggled: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('How many days per week can you train?'), findsOneWidget);
    });
  });
}
