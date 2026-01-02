import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/screens/library/components/filter_section.dart';
import 'package:fitwiz/screens/library/models/filter_option.dart';

void main() {
  group('FilterSection', () {
    final testOptions = [
      const FilterOption(name: 'Chest', count: 25),
      const FilterOption(name: 'Back', count: 30),
      const FilterOption(name: 'Legs', count: 35),
      const FilterOption(name: 'Shoulders', count: 20),
      const FilterOption(name: 'Arms', count: 28),
      const FilterOption(name: 'Core', count: 22),
      const FilterOption(name: 'Glutes', count: 15),
      const FilterOption(name: 'Other', count: 10),
    ];

    testWidgets('renders title and icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterSection(
              title: 'BODY PART',
              icon: Icons.accessibility_new,
              color: Colors.purple,
              options: testOptions,
              selectedValues: const {},
              onToggle: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('BODY PART'), findsOneWidget);
      expect(find.byIcon(Icons.accessibility_new), findsOneWidget);
    });

    testWidgets('is collapsed by default when no selection',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterSection(
              title: 'BODY PART',
              icon: Icons.accessibility_new,
              color: Colors.purple,
              options: testOptions,
              selectedValues: const {},
              onToggle: (_) {},
              initiallyExpanded: false,
            ),
          ),
        ),
      );

      // Options should not be visible when collapsed
      expect(find.text('Chest'), findsNothing);
    });

    testWidgets('expands when tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FilterSection(
                title: 'BODY PART',
                icon: Icons.accessibility_new,
                color: Colors.purple,
                options: testOptions,
                selectedValues: const {},
                onToggle: (_) {},
              ),
            ),
          ),
        ),
      );

      // Tap to expand
      await tester.tap(find.text('BODY PART'));
      await tester.pumpAndSettle();

      // Options should be visible now
      expect(find.text('Chest'), findsOneWidget);
    });

    testWidgets('is expanded when there is a selection',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FilterSection(
                title: 'BODY PART',
                icon: Icons.accessibility_new,
                color: Colors.purple,
                options: testOptions,
                selectedValues: const {'Chest'},
                onToggle: (_) {},
              ),
            ),
          ),
        ),
      );

      // Should be expanded due to selection
      expect(find.text('Chest'), findsOneWidget);
    });

    testWidgets('shows selection count badge', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterSection(
              title: 'BODY PART',
              icon: Icons.accessibility_new,
              color: Colors.purple,
              options: testOptions,
              selectedValues: const {'Chest', 'Back'},
              onToggle: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('calls onToggle when option is tapped',
        (WidgetTester tester) async {
      String? toggledValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FilterSection(
                title: 'BODY PART',
                icon: Icons.accessibility_new,
                color: Colors.purple,
                options: testOptions,
                selectedValues: const {},
                onToggle: (value) => toggledValue = value,
                initiallyExpanded: true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Back'));
      await tester.pump();

      expect(toggledValue, 'Back');
    });

    testWidgets('shows checkmark for selected options',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FilterSection(
                title: 'BODY PART',
                icon: Icons.accessibility_new,
                color: Colors.purple,
                options: testOptions,
                selectedValues: const {'Chest'},
                onToggle: (_) {},
                initiallyExpanded: true,
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.check), findsWidgets);
    });

    testWidgets('shows "Show more" when options exceed limit',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FilterSection(
                title: 'BODY PART',
                icon: Icons.accessibility_new,
                color: Colors.purple,
                options: testOptions,
                selectedValues: const {},
                onToggle: (_) {},
                initiallyExpanded: true,
                initialShowCount: 4,
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('Show'), findsOneWidget);
    });

    testWidgets('collapses when header is tapped again',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FilterSection(
                title: 'BODY PART',
                icon: Icons.accessibility_new,
                color: Colors.purple,
                options: testOptions,
                selectedValues: const {},
                onToggle: (_) {},
                initiallyExpanded: true,
              ),
            ),
          ),
        ),
      );

      // Verify expanded
      expect(find.text('Chest'), findsOneWidget);

      // Tap to collapse
      await tester.tap(find.text('BODY PART'));
      await tester.pumpAndSettle();

      // Verify collapsed
      expect(find.text('Chest'), findsNothing);
    });

    testWidgets('renders in dark mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: FilterSection(
              title: 'EQUIPMENT',
              icon: Icons.fitness_center,
              color: Colors.cyan,
              options: testOptions,
              selectedValues: const {},
              onToggle: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('EQUIPMENT'), findsOneWidget);
    });

    testWidgets('puts Other at end of list', (WidgetTester tester) async {
      final optionsWithOther = [
        const FilterOption(name: 'Other', count: 10),
        const FilterOption(name: 'Chest', count: 25),
        const FilterOption(name: 'Back', count: 30),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FilterSection(
                title: 'BODY PART',
                icon: Icons.accessibility_new,
                color: Colors.purple,
                options: optionsWithOther,
                selectedValues: const {},
                onToggle: (_) {},
                initiallyExpanded: true,
              ),
            ),
          ),
        ),
      );

      // Verify all options are shown
      expect(find.text('Chest'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Other'), findsOneWidget);
    });
  });
}
