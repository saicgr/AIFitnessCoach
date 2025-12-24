import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_fitness_coach/screens/onboarding/widgets/quiz_multi_select.dart';
import 'package:ai_fitness_coach/core/constants/app_colors.dart';

void main() {
  group('QuizMultiSelect', () {
    final testOptions = [
      {'id': 'option1', 'label': 'Option 1', 'icon': Icons.fitness_center, 'color': AppColors.purple},
      {'id': 'option2', 'label': 'Option 2', 'icon': Icons.directions_run, 'color': AppColors.cyan},
      {'id': 'option3', 'label': 'Option 3', 'icon': Icons.favorite_outline, 'color': AppColors.success},
    ];

    testWidgets('displays question text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuizMultiSelect(
              question: 'What are your goals?',
              subtitle: 'Select all that apply',
              options: testOptions,
              selectedValues: const {},
              onToggle: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('What are your goals?'), findsOneWidget);
    });

    testWidgets('displays subtitle text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuizMultiSelect(
              question: 'What are your goals?',
              subtitle: 'Select all that apply',
              options: testOptions,
              selectedValues: const {},
              onToggle: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Select all that apply'), findsOneWidget);
    });

    testWidgets('displays all options', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuizMultiSelect(
              question: 'What are your goals?',
              subtitle: 'Select all that apply',
              options: testOptions,
              selectedValues: const {},
              onToggle: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Option 1'), findsOneWidget);
      expect(find.text('Option 2'), findsOneWidget);
      expect(find.text('Option 3'), findsOneWidget);
    });

    testWidgets('calls onToggle when option is tapped', (tester) async {
      String? toggledId;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuizMultiSelect(
              question: 'What are your goals?',
              subtitle: 'Select all that apply',
              options: testOptions,
              selectedValues: const {},
              onToggle: (id) {
                toggledId = id;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Option 1'));
      await tester.pump();

      expect(toggledId, equals('option1'));
    });

    testWidgets('shows check mark for selected options', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuizMultiSelect(
              question: 'What are your goals?',
              subtitle: 'Select all that apply',
              options: testOptions,
              selectedValues: const {'option1', 'option2'},
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
            body: QuizMultiSelect(
              question: 'What are your goals?',
              subtitle: 'Select all that apply',
              options: testOptions,
              selectedValues: const {},
              onToggle: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('What are your goals?'), findsOneWidget);
    });

    testWidgets('renders in light mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: QuizMultiSelect(
              question: 'What are your goals?',
              subtitle: 'Select all that apply',
              options: testOptions,
              selectedValues: const {},
              onToggle: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('What are your goals?'), findsOneWidget);
    });
  });
}
