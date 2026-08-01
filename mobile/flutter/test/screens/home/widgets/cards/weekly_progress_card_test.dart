import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/screens/home/widgets/cards/weekly_progress_card.dart';
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

    // Surface 2.5 deliberately dropped the big "N%" number (it was punitive on
    // a fresh week and duplicated the day-ring row). Completion is now carried
    // by the "X of N workouts" headline plus the progress bar's value.
    testWidgets('progress bar value reflects completion ratio', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const WeeklyProgressCard(
          completed: 3,
          total: 5,
        ),
      ));

      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, closeTo(0.6, 0.0001));
      expect(find.text('60%'), findsNothing);
    });

    testWidgets('progress bar is full when all completed', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const WeeklyProgressCard(
          completed: 5,
          total: 5,
        ),
      ));

      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, closeTo(1.0, 0.0001));
      expect(find.text('5 of 5 workouts'), findsOneWidget);
    });

    testWidgets('progress bar is empty when none completed', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const WeeklyProgressCard(
          completed: 0,
          total: 5,
        ),
      ));

      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, closeTo(0.0, 0.0001));
      expect(find.text('0 of 5 workouts'), findsOneWidget);
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

      // Should render an empty bar without a divide-by-zero crash.
      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, closeTo(0.0, 0.0001));
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
