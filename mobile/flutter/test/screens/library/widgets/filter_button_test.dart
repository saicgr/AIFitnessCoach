import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/screens/library/widgets/filter_button.dart';

void main() {
  group('FilterButton', () {
    testWidgets('renders correctly with zero active filters',
        (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterButton(
              activeFilterCount: 0,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      // Verify filter icon is present
      expect(find.byIcon(Icons.tune), findsOneWidget);

      // Verify no badge is shown
      expect(find.text('0'), findsNothing);

      // Verify tap works
      await tester.tap(find.byType(FilterButton));
      expect(tapped, true);
    });

    testWidgets('shows badge with active filter count',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterButton(
              activeFilterCount: 3,
              onTap: () {},
            ),
          ),
        ),
      );

      // Verify badge shows count
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('shows single filter count', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterButton(
              activeFilterCount: 1,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('renders correctly in dark mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: FilterButton(
              activeFilterCount: 2,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.tune), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('renders correctly in light mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: FilterButton(
              activeFilterCount: 5,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.tune), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });
  });
}
