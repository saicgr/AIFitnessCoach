import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/screens/settings/widgets/day_picker_tile.dart';
import 'package:fitwiz/core/constants/app_colors.dart';

void main() {
  group('DayPickerTile', () {
    testWidgets('displays label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DayPickerTile(
              label: 'Day',
              day: 0,
              onChanged: (_) {},
              isDark: true,
            ),
          ),
        ),
      );

      expect(find.text('Day'), findsOneWidget);
    });

    testWidgets('displays Sunday for day 0', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DayPickerTile(
              label: 'Test',
              day: 0,
              onChanged: (_) {},
              isDark: true,
            ),
          ),
        ),
      );

      expect(find.text('Sunday'), findsOneWidget);
    });

    testWidgets('displays Monday for day 1', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DayPickerTile(
              label: 'Test',
              day: 1,
              onChanged: (_) {},
              isDark: true,
            ),
          ),
        ),
      );

      expect(find.text('Monday'), findsOneWidget);
    });

    testWidgets('displays Saturday for day 6', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DayPickerTile(
              label: 'Test',
              day: 6,
              onChanged: (_) {},
              isDark: true,
            ),
          ),
        ),
      );

      expect(find.text('Saturday'), findsOneWidget);
    });

    testWidgets('shows dropdown arrow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DayPickerTile(
              label: 'Test',
              day: 0,
              onChanged: (_) {},
              isDark: true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
    });

    testWidgets('dropdown has cyan color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DayPickerTile(
              label: 'Test',
              day: 0,
              onChanged: (_) {},
              isDark: true,
            ),
          ),
        ),
      );

      final dropdown = tester.widget<DropdownButton<int>>(find.byType(DropdownButton<int>));
      expect((dropdown.icon as Icon).color, AppColors.cyan);
    });

    testWidgets('calls onChanged when value is selected', (tester) async {
      int? selectedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DayPickerTile(
              label: 'Test',
              day: 0,
              onChanged: (value) => selectedValue = value,
              isDark: true,
            ),
          ),
        ),
      );

      // Tap to open dropdown
      await tester.tap(find.byType(DropdownButton<int>));
      await tester.pumpAndSettle();

      // Select Wednesday (index 3)
      await tester.tap(find.text('Wednesday').last);
      await tester.pumpAndSettle();

      expect(selectedValue, 3);
    });

    testWidgets('has correct container styling', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DayPickerTile(
              label: 'Test',
              day: 0,
              onChanged: (_) {},
              isDark: true,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(8));
    });

    testWidgets('all days are available in dropdown', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DayPickerTile(
              label: 'Test',
              day: 0,
              onChanged: (_) {},
              isDark: true,
            ),
          ),
        ),
      );

      // Open dropdown
      await tester.tap(find.byType(DropdownButton<int>));
      await tester.pumpAndSettle();

      // Check all days are present
      expect(find.text('Sunday'), findsWidgets);
      expect(find.text('Monday'), findsWidgets);
      expect(find.text('Tuesday'), findsWidgets);
      expect(find.text('Wednesday'), findsWidgets);
      expect(find.text('Thursday'), findsWidgets);
      expect(find.text('Friday'), findsWidgets);
      expect(find.text('Saturday'), findsWidgets);
    });
  });
}
