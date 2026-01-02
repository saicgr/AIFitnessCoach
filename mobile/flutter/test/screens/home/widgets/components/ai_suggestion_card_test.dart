import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/screens/home/widgets/components/ai_suggestion_card.dart';
import '../../test_helpers.dart';

void main() {
  group('AISuggestionCard', () {
    final sampleSuggestion = {
      'name': 'Upper Body Strength',
      'type': 'Strength',
      'difficulty': 'medium',
      'duration_minutes': 45,
      'description': 'A focused upper body workout',
      'focus_areas': ['Chest', 'Back', 'Shoulders'],
      'sample_exercises': ['Bench Press', 'Rows', 'Shoulder Press'],
    };

    testWidgets('renders suggestion name', (tester) async {
      await tester.pumpWidget(createTestWidget(
        AISuggestionCard(
          suggestion: sampleSuggestion,
          index: 0,
          isSelected: false,
          onTap: () {},
        ),
      ));

      expect(find.text('Upper Body Strength'), findsOneWidget);
    });

    testWidgets('renders workout type', (tester) async {
      await tester.pumpWidget(createTestWidget(
        AISuggestionCard(
          suggestion: sampleSuggestion,
          index: 0,
          isSelected: false,
          onTap: () {},
        ),
      ));

      expect(find.text('Strength'), findsOneWidget);
    });

    testWidgets('renders difficulty', (tester) async {
      await tester.pumpWidget(createTestWidget(
        AISuggestionCard(
          suggestion: sampleSuggestion,
          index: 0,
          isSelected: false,
          onTap: () {},
        ),
      ));

      expect(find.text('Medium'), findsOneWidget);
    });

    testWidgets('renders duration', (tester) async {
      await tester.pumpWidget(createTestWidget(
        AISuggestionCard(
          suggestion: sampleSuggestion,
          index: 0,
          isSelected: false,
          onTap: () {},
        ),
      ));

      expect(find.text('45 min'), findsOneWidget);
    });

    testWidgets('renders description', (tester) async {
      await tester.pumpWidget(createTestWidget(
        AISuggestionCard(
          suggestion: sampleSuggestion,
          index: 0,
          isSelected: false,
          onTap: () {},
        ),
      ));

      expect(find.text('A focused upper body workout'), findsOneWidget);
    });

    testWidgets('renders focus areas', (tester) async {
      await tester.pumpWidget(createTestWidget(
        AISuggestionCard(
          suggestion: sampleSuggestion,
          index: 0,
          isSelected: false,
          onTap: () {},
        ),
      ));

      expect(find.text('Chest'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Shoulders'), findsOneWidget);
    });

    testWidgets('shows "Best Match" label for first suggestion', (tester) async {
      await tester.pumpWidget(createTestWidget(
        AISuggestionCard(
          suggestion: sampleSuggestion,
          index: 0,
          isSelected: false,
          onTap: () {},
        ),
      ));

      expect(find.text('Best Match'), findsOneWidget);
    });

    testWidgets('shows "2nd Choice" label for second suggestion', (tester) async {
      await tester.pumpWidget(createTestWidget(
        AISuggestionCard(
          suggestion: sampleSuggestion,
          index: 1,
          isSelected: false,
          onTap: () {},
        ),
      ));

      expect(find.text('2nd Choice'), findsOneWidget);
    });

    testWidgets('shows "3rd Choice" label for third suggestion', (tester) async {
      await tester.pumpWidget(createTestWidget(
        AISuggestionCard(
          suggestion: sampleSuggestion,
          index: 2,
          isSelected: false,
          onTap: () {},
        ),
      ));

      expect(find.text('3rd Choice'), findsOneWidget);
    });

    testWidgets('shows check icon when selected', (tester) async {
      await tester.pumpWidget(createTestWidget(
        AISuggestionCard(
          suggestion: sampleSuggestion,
          index: 0,
          isSelected: true,
          onTap: () {},
        ),
      ));

      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('does not show check icon when not selected', (tester) async {
      await tester.pumpWidget(createTestWidget(
        AISuggestionCard(
          suggestion: sampleSuggestion,
          index: 0,
          isSelected: false,
          onTap: () {},
        ),
      ));

      // The check icon should not be in the selection indicator
      // (there may be other check icons in the UI)
      expect(
        find.descendant(
          of: find.byType(AISuggestionCard),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Container &&
                widget.child is Icon &&
                (widget.child as Icon).icon == Icons.check,
          ),
        ),
        findsNothing,
      );
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool wasTapped = false;

      await tester.pumpWidget(createTestWidget(
        AISuggestionCard(
          suggestion: sampleSuggestion,
          index: 0,
          isSelected: false,
          onTap: () => wasTapped = true,
        ),
      ));

      await tester.tap(find.byType(AISuggestionCard));
      await tester.pump();

      expect(wasTapped, isTrue);
    });

    testWidgets('handles missing fields gracefully', (tester) async {
      final minimalSuggestion = <String, dynamic>{
        'name': 'Basic Workout',
      };

      await tester.pumpWidget(createTestWidget(
        AISuggestionCard(
          suggestion: minimalSuggestion,
          index: 0,
          isSelected: false,
          onTap: () {},
        ),
      ));

      expect(find.text('Basic Workout'), findsOneWidget);
      // Should use defaults without crashing
      expect(find.text('Strength'), findsOneWidget); // default type
      expect(find.text('Medium'), findsOneWidget); // default difficulty
      expect(find.text('45 min'), findsOneWidget); // default duration
    });
  });
}
