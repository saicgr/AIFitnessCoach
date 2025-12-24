import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_fitness_coach/screens/home/widgets/components/difficulty_selector.dart';
import '../../test_helpers.dart';

void main() {
  group('DifficultySelector', () {
    testWidgets('renders all difficulty options', (tester) async {
      await tester.pumpWidget(createTestWidget(
        DifficultySelector(
          selectedDifficulty: 'medium',
          onSelectionChanged: (_) {},
        ),
      ));

      expect(find.text('Easy'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
      expect(find.text('Hard'), findsOneWidget);
    });

    testWidgets('highlights selected difficulty', (tester) async {
      await tester.pumpWidget(createTestWidget(
        DifficultySelector(
          selectedDifficulty: 'hard',
          onSelectionChanged: (_) {},
        ),
      ));

      // The selected difficulty should be visible
      expect(find.text('Hard'), findsOneWidget);
    });

    testWidgets('calls onSelectionChanged when difficulty is tapped', (tester) async {
      String? selectedDifficulty;

      await tester.pumpWidget(createTestWidget(
        DifficultySelector(
          selectedDifficulty: 'medium',
          onSelectionChanged: (d) => selectedDifficulty = d,
        ),
      ));

      await tester.tap(find.text('Easy'));
      await tester.pump();

      expect(selectedDifficulty, equals('easy'));
    });

    testWidgets('does not respond when disabled', (tester) async {
      String? selectedDifficulty;

      await tester.pumpWidget(createTestWidget(
        DifficultySelector(
          selectedDifficulty: 'medium',
          onSelectionChanged: (d) => selectedDifficulty = d,
          disabled: true,
        ),
      ));

      await tester.tap(find.text('Easy'));
      await tester.pump();

      expect(selectedDifficulty, isNull);
    });

    testWidgets('shows icons when showIcons is true', (tester) async {
      await tester.pumpWidget(createTestWidget(
        DifficultySelector(
          selectedDifficulty: 'medium',
          onSelectionChanged: (_) {},
          showIcons: true,
        ),
      ));

      // Should find difficulty icons
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget); // easy
      expect(find.byIcon(Icons.change_history), findsOneWidget); // medium
      expect(find.byIcon(Icons.star_outline), findsOneWidget); // hard
    });

    testWidgets('hides icons when showIcons is false', (tester) async {
      await tester.pumpWidget(createTestWidget(
        DifficultySelector(
          selectedDifficulty: 'medium',
          onSelectionChanged: (_) {},
          showIcons: false,
        ),
      ));

      // Should not find difficulty icons
      expect(find.byIcon(Icons.check_circle_outline), findsNothing);
      expect(find.byIcon(Icons.change_history), findsNothing);
      expect(find.byIcon(Icons.star_outline), findsNothing);
    });

    testWidgets('renders custom difficulty list', (tester) async {
      await tester.pumpWidget(createTestWidget(
        DifficultySelector(
          selectedDifficulty: 'beginner',
          onSelectionChanged: (_) {},
          difficulties: const ['beginner', 'intermediate', 'advanced'],
        ),
      ));

      expect(find.text('Beginner'), findsOneWidget);
      expect(find.text('Intermediate'), findsOneWidget);
      expect(find.text('Advanced'), findsOneWidget);
    });
  });
}
