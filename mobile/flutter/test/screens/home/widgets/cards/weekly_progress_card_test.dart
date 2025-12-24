import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_fitness_coach/screens/home/widgets/cards/weekly_progress_card.dart';
import '../../test_helpers.dart';

void main() {
  group('WeeklyProgressCard', () {
    testWidgets('renders progress text', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const WeeklyProgressCard(
          completed: 3,
          total: 5,
        ),
      ));

      expect(find.text('3 of 5 workouts'), findsOneWidget);
    });

    testWidgets('renders percentage', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const WeeklyProgressCard(
          completed: 3,
          total: 5,
        ),
      ));

      expect(find.text('60%'), findsOneWidget);
    });

    testWidgets('renders 100% when all completed', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const WeeklyProgressCard(
          completed: 5,
          total: 5,
        ),
      ));

      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('renders 0% when none completed', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const WeeklyProgressCard(
          completed: 0,
          total: 5,
        ),
      ));

      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('renders all day indicators', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const WeeklyProgressCard(
          completed: 2,
          total: 5,
        ),
      ));

      // Check for day labels
      expect(find.text('M'), findsOneWidget);
      expect(find.text('T'), findsNWidgets(2)); // Tuesday and Thursday
      expect(find.text('W'), findsOneWidget);
      expect(find.text('F'), findsOneWidget);
      expect(find.text('S'), findsNWidgets(2)); // Saturday and Sunday
    });

    testWidgets('renders progress indicator', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const WeeklyProgressCard(
          completed: 3,
          total: 5,
        ),
      ));

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('handles zero total without division error', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const WeeklyProgressCard(
          completed: 0,
          total: 0,
        ),
      ));

      // Should show 0% without crashing
      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('renders correctly in dark theme', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const WeeklyProgressCard(
          completed: 2,
          total: 4,
          isDark: true,
        ),
      ));

      expect(find.text('2 of 4 workouts'), findsOneWidget);
    });

    testWidgets('renders correctly in light theme', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const WeeklyProgressCard(
          completed: 2,
          total: 4,
          isDark: false,
        ),
        isDark: false,
      ));

      expect(find.text('2 of 4 workouts'), findsOneWidget);
    });
  });
}
