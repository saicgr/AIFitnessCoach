import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_fitness_coach/screens/home/widgets/components/selectable_chip.dart';
import '../../test_helpers.dart';

void main() {
  group('SelectableChip', () {
    testWidgets('renders label correctly', (tester) async {
      await tester.pumpWidget(createTestWidget(
        SelectableChip(
          label: 'Test Label',
          isSelected: false,
          accentColor: Colors.blue,
          onTap: () {},
        ),
      ));

      expect(find.text('Test Label'), findsOneWidget);
    });

    testWidgets('shows check icon when selected', (tester) async {
      await tester.pumpWidget(createTestWidget(
        SelectableChip(
          label: 'Selected',
          isSelected: true,
          accentColor: Colors.blue,
          onTap: () {},
          showCheckIcon: true,
        ),
      ));

      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('hides check icon when showCheckIcon is false', (tester) async {
      await tester.pumpWidget(createTestWidget(
        SelectableChip(
          label: 'Selected',
          isSelected: true,
          accentColor: Colors.blue,
          onTap: () {},
          showCheckIcon: false,
        ),
      ));

      expect(find.byIcon(Icons.check), findsNothing);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool wasTapped = false;

      await tester.pumpWidget(createTestWidget(
        SelectableChip(
          label: 'Tappable',
          isSelected: false,
          accentColor: Colors.blue,
          onTap: () => wasTapped = true,
        ),
      ));

      await tester.tap(find.text('Tappable'));
      await tester.pump();

      expect(wasTapped, isTrue);
    });

    testWidgets('does not call onTap when disabled', (tester) async {
      bool wasTapped = false;

      await tester.pumpWidget(createTestWidget(
        SelectableChip(
          label: 'Disabled',
          isSelected: false,
          accentColor: Colors.blue,
          onTap: () => wasTapped = true,
          disabled: true,
        ),
      ));

      await tester.tap(find.text('Disabled'));
      await tester.pump();

      expect(wasTapped, isFalse);
    });

    testWidgets('renders trailing widget when provided', (tester) async {
      await tester.pumpWidget(createTestWidget(
        SelectableChip(
          label: 'With Trailing',
          isSelected: true,
          accentColor: Colors.blue,
          onTap: () {},
          trailing: const Icon(Icons.add),
        ),
      ));

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('applies correct styling when selected', (tester) async {
      await tester.pumpWidget(createTestWidget(
        SelectableChip(
          label: 'Selected',
          isSelected: true,
          accentColor: Colors.blue,
          onTap: () {},
        ),
      ));

      // Find the container and verify styling
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(SelectableChip),
          matching: find.byType(Container).first,
        ),
      );

      expect(container.decoration, isNotNull);
    });
  });

  group('OtherInputChip', () {
    testWidgets('shows "Other" when no custom value', (tester) async {
      await tester.pumpWidget(createTestWidget(
        OtherInputChip(
          isInputShown: false,
          customValue: '',
          accentColor: Colors.blue,
          onTap: () {},
        ),
      ));

      expect(find.text('Other'), findsOneWidget);
    });

    testWidgets('shows custom value when provided', (tester) async {
      await tester.pumpWidget(createTestWidget(
        OtherInputChip(
          isInputShown: false,
          customValue: 'Custom Type',
          accentColor: Colors.blue,
          onTap: () {},
        ),
      ));

      expect(find.text('Custom Type'), findsOneWidget);
    });

    testWidgets('shows add icon when input not shown', (tester) async {
      await tester.pumpWidget(createTestWidget(
        OtherInputChip(
          isInputShown: false,
          customValue: '',
          accentColor: Colors.blue,
          onTap: () {},
        ),
      ));

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('shows close icon when input shown', (tester) async {
      await tester.pumpWidget(createTestWidget(
        OtherInputChip(
          isInputShown: true,
          customValue: '',
          accentColor: Colors.blue,
          onTap: () {},
        ),
      ));

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool wasTapped = false;

      await tester.pumpWidget(createTestWidget(
        OtherInputChip(
          isInputShown: false,
          customValue: '',
          accentColor: Colors.blue,
          onTap: () => wasTapped = true,
        ),
      ));

      await tester.tap(find.text('Other'));
      await tester.pump();

      expect(wasTapped, isTrue);
    });
  });
}
