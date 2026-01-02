import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/screens/settings/widgets/interval_picker_tile.dart';
import 'package:fitwiz/core/constants/app_colors.dart';

void main() {
  group('IntervalPickerTile', () {
    testWidgets('displays label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IntervalPickerTile(
              label: 'Remind every',
              minutes: 60,
              onChanged: (_) {},
              isDark: true,
            ),
          ),
        ),
      );

      expect(find.text('Remind every'), findsOneWidget);
    });

    testWidgets('displays minutes correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IntervalPickerTile(
              label: 'Test',
              minutes: 30,
              onChanged: (_) {},
              isDark: true,
            ),
          ),
        ),
      );

      expect(find.text('30m'), findsOneWidget);
    });

    testWidgets('displays hours correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IntervalPickerTile(
              label: 'Test',
              minutes: 120,
              onChanged: (_) {},
              isDark: true,
            ),
          ),
        ),
      );

      expect(find.text('2h'), findsOneWidget);
    });

    testWidgets('displays hours and minutes correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IntervalPickerTile(
              label: 'Test',
              minutes: 90,
              onChanged: (_) {},
              isDark: true,
            ),
          ),
        ),
      );

      expect(find.text('1h 30m'), findsOneWidget);
    });

    testWidgets('shows dropdown arrow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IntervalPickerTile(
              label: 'Test',
              minutes: 60,
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
            body: IntervalPickerTile(
              label: 'Test',
              minutes: 60,
              onChanged: (_) {},
              isDark: true,
            ),
          ),
        ),
      );

      final dropdown = tester.widget<DropdownButton<int>>(find.byType(DropdownButton<int>));
      expect((dropdown.icon as Icon).color, AppColors.cyan);
    });

    testWidgets('uses custom intervals when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IntervalPickerTile(
              label: 'Test',
              minutes: 15,
              onChanged: (_) {},
              isDark: true,
              intervals: const [15, 30, 45],
            ),
          ),
        ),
      );

      expect(find.text('15m'), findsOneWidget);
    });

    testWidgets('calls onChanged when value is selected', (tester) async {
      int? selectedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IntervalPickerTile(
              label: 'Test',
              minutes: 60,
              onChanged: (value) => selectedValue = value,
              isDark: true,
            ),
          ),
        ),
      );

      // Tap to open dropdown
      await tester.tap(find.byType(DropdownButton<int>));
      await tester.pumpAndSettle();

      // Select a different value (30m)
      await tester.tap(find.text('30m').last);
      await tester.pumpAndSettle();

      expect(selectedValue, 30);
    });

    testWidgets('has correct container styling', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IntervalPickerTile(
              label: 'Test',
              minutes: 60,
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

    testWidgets('default intervals are correct', (tester) async {
      final tile = IntervalPickerTile(
        label: 'Test',
        minutes: 60,
        onChanged: (_) {},
        isDark: true,
      );

      expect(tile.intervals, const [30, 60, 90, 120, 180, 240]);
    });
  });
}
