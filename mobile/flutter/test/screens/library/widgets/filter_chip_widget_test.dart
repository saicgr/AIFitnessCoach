import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/screens/library/widgets/filter_chip_widget.dart';

void main() {
  group('FilterChipWidget', () {
    testWidgets('renders unselected state correctly',
        (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterChipWidget(
              label: 'Chest',
              isSelected: false,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Chest'), findsOneWidget);

      await tester.tap(find.text('Chest'));
      expect(tapped, true);
    });

    testWidgets('renders selected state correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterChipWidget(
              label: 'Back',
              isSelected: true,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Back'), findsOneWidget);
    });

    testWidgets('can toggle selection', (WidgetTester tester) async {
      bool isSelected = false;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: FilterChipWidget(
                  label: 'Legs',
                  isSelected: isSelected,
                  onTap: () => setState(() => isSelected = !isSelected),
                ),
              ),
            );
          },
        ),
      );

      expect(isSelected, false);

      await tester.tap(find.text('Legs'));
      await tester.pump();

      expect(isSelected, true);
    });

    testWidgets('renders in dark mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: FilterChipWidget(
              label: 'Shoulders',
              isSelected: true,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Shoulders'), findsOneWidget);
    });

    testWidgets('renders in light mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: FilterChipWidget(
              label: 'Arms',
              isSelected: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Arms'), findsOneWidget);
    });

    testWidgets('handles long labels', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterChipWidget(
              label: 'Very Long Category Name That Should Still Render',
              isSelected: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(
        find.text('Very Long Category Name That Should Still Render'),
        findsOneWidget,
      );
    });
  });
}
