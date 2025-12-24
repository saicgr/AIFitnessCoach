import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_fitness_coach/screens/settings/widgets/date_picker_button.dart';
import 'package:ai_fitness_coach/core/constants/app_colors.dart';

void main() {
  group('DatePickerButton', () {
    testWidgets('displays label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DatePickerButton(
              label: 'Start',
              date: null,
              onTap: () {},
              isDark: true,
            ),
          ),
        ),
      );

      expect(find.text('Start'), findsOneWidget);
    });

    testWidgets('displays placeholder when date is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DatePickerButton(
              label: 'Test',
              date: null,
              onTap: () {},
              isDark: true,
            ),
          ),
        ),
      );

      expect(find.text('Select date'), findsOneWidget);
    });

    testWidgets('displays formatted date when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DatePickerButton(
              label: 'Test',
              date: DateTime(2024, 3, 15),
              onTap: () {},
              isDark: true,
            ),
          ),
        ),
      );

      expect(find.text('Mar 15, 2024'), findsOneWidget);
    });

    testWidgets('displays January correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DatePickerButton(
              label: 'Test',
              date: DateTime(2024, 1, 1),
              onTap: () {},
              isDark: true,
            ),
          ),
        ),
      );

      expect(find.text('Jan 1, 2024'), findsOneWidget);
    });

    testWidgets('displays December correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DatePickerButton(
              label: 'Test',
              date: DateTime(2024, 12, 25),
              onTap: () {},
              isDark: true,
            ),
          ),
        ),
      );

      expect(find.text('Dec 25, 2024'), findsOneWidget);
    });

    testWidgets('displays calendar icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DatePickerButton(
              label: 'Test',
              date: null,
              onTap: () {},
              isDark: true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });

    testWidgets('calendar icon has cyan color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DatePickerButton(
              label: 'Test',
              date: null,
              onTap: () {},
              isDark: true,
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.calendar_today));
      expect(icon.color, AppColors.cyan);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DatePickerButton(
              label: 'Test',
              date: null,
              onTap: () => tapped = true,
              isDark: true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      expect(tapped, true);
    });

    testWidgets('has correct container styling', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DatePickerButton(
              label: 'Test',
              date: null,
              onTap: () {},
              isDark: true,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(8));
    });

    testWidgets('placeholder text has muted color in dark mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: DatePickerButton(
              label: 'Test',
              date: null,
              onTap: () {},
              isDark: true,
            ),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('Select date'));
      expect(text.style?.color, AppColors.textMuted);
    });

    testWidgets('date text has primary color when date is set', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: DatePickerButton(
              label: 'Test',
              date: DateTime(2024, 5, 10),
              onTap: () {},
              isDark: true,
            ),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('May 10, 2024'));
      expect(text.style?.color, AppColors.textPrimary);
    });
  });
}
