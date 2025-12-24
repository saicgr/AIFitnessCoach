import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_fitness_coach/screens/settings/widgets/time_picker_tile.dart';
import 'package:ai_fitness_coach/core/constants/app_colors.dart';

void main() {
  group('TimePickerTile', () {
    testWidgets('displays label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimePickerTile(
              label: 'Reminder time',
              time: '08:00',
              onTimeChanged: (_) {},
              isDark: true,
            ),
          ),
        ),
      );

      expect(find.text('Reminder time'), findsOneWidget);
    });

    testWidgets('formats AM time correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimePickerTile(
              label: 'Test',
              time: '08:30',
              onTimeChanged: (_) {},
              isDark: true,
            ),
          ),
        ),
      );

      expect(find.text('8:30 AM'), findsOneWidget);
    });

    testWidgets('formats PM time correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimePickerTile(
              label: 'Test',
              time: '14:45',
              onTimeChanged: (_) {},
              isDark: true,
            ),
          ),
        ),
      );

      expect(find.text('2:45 PM'), findsOneWidget);
    });

    testWidgets('formats noon correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimePickerTile(
              label: 'Test',
              time: '12:00',
              onTimeChanged: (_) {},
              isDark: true,
            ),
          ),
        ),
      );

      expect(find.text('12:00 PM'), findsOneWidget);
    });

    testWidgets('formats midnight correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimePickerTile(
              label: 'Test',
              time: '00:00',
              onTimeChanged: (_) {},
              isDark: true,
            ),
          ),
        ),
      );

      expect(find.text('12:00 AM'), findsOneWidget);
    });

    testWidgets('displays clock icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimePickerTile(
              label: 'Test',
              time: '08:00',
              onTimeChanged: (_) {},
              isDark: true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.access_time), findsOneWidget);
    });

    testWidgets('has cyan colored time text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimePickerTile(
              label: 'Test',
              time: '08:00',
              onTimeChanged: (_) {},
              isDark: true,
            ),
          ),
        ),
      );

      final timeText = tester.widget<Text>(find.text('8:00 AM'));
      expect(timeText.style?.color, AppColors.cyan);
    });

    testWidgets('is tappable', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimePickerTile(
              label: 'Test',
              time: '08:00',
              onTimeChanged: (_) {},
              isDark: true,
            ),
          ),
        ),
      );

      expect(find.byType(InkWell), findsOneWidget);
    });

    testWidgets('has correct container styling in dark mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: TimePickerTile(
              label: 'Test',
              time: '08:00',
              onTimeChanged: (_) {},
              isDark: true,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(8));
      expect(decoration.border, isNotNull);
    });

    testWidgets('has correct container styling in light mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: TimePickerTile(
              label: 'Test',
              time: '08:00',
              onTimeChanged: (_) {},
              isDark: false,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(8));
    });

    testWidgets('handles invalid time format gracefully', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimePickerTile(
              label: 'Test',
              time: 'invalid',
              onTimeChanged: (_) {},
              isDark: true,
            ),
          ),
        ),
      );

      // Should display the invalid time as-is
      expect(find.text('invalid'), findsOneWidget);
    });
  });
}
