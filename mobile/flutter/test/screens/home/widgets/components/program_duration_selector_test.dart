import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/screens/home/widgets/components/program_duration_selector.dart';
import '../../test_helpers.dart';

void main() {
  group('ProgramDurationSelector', () {
    testWidgets('renders all duration options', (tester) async {
      await tester.pumpWidget(createTestWidget(
        ProgramDurationSelector(
          selectedWeeks: 4,
          onSelectionChanged: (_) {},
        ),
      ));

      expect(find.text('1 Week'), findsOneWidget);
      expect(find.text('2 Weeks'), findsOneWidget);
      expect(find.text('1 Month'), findsOneWidget);
      expect(find.text('2 Months'), findsOneWidget);
      expect(find.text('3 Months'), findsOneWidget);
    });

    testWidgets('displays correct badge for 1 week', (tester) async {
      await tester.pumpWidget(createTestWidget(
        ProgramDurationSelector(
          selectedWeeks: 1,
          onSelectionChanged: (_) {},
        ),
      ));

      expect(find.text('1 week'), findsOneWidget);
    });

    testWidgets('displays correct badge for 2 weeks', (tester) async {
      await tester.pumpWidget(createTestWidget(
        ProgramDurationSelector(
          selectedWeeks: 2,
          onSelectionChanged: (_) {},
        ),
      ));

      expect(find.text('2 weeks'), findsOneWidget);
    });

    testWidgets('displays correct badge for 4 weeks (1 month)', (tester) async {
      await tester.pumpWidget(createTestWidget(
        ProgramDurationSelector(
          selectedWeeks: 4,
          onSelectionChanged: (_) {},
        ),
      ));

      expect(find.text('4 weeks'), findsOneWidget);
    });

    testWidgets('displays correct badge for 8 weeks (2 months)', (tester) async {
      await tester.pumpWidget(createTestWidget(
        ProgramDurationSelector(
          selectedWeeks: 8,
          onSelectionChanged: (_) {},
        ),
      ));

      expect(find.text('2 months'), findsOneWidget);
    });

    testWidgets('calls onSelectionChanged when option is tapped', (tester) async {
      int? selectedWeeks;

      await tester.pumpWidget(createTestWidget(
        ProgramDurationSelector(
          selectedWeeks: 4,
          onSelectionChanged: (weeks) => selectedWeeks = weeks,
        ),
      ));

      await tester.tap(find.text('2 Weeks'));
      await tester.pump();

      expect(selectedWeeks, equals(2));
    });

    testWidgets('does not respond when disabled', (tester) async {
      int? selectedWeeks;

      await tester.pumpWidget(createTestWidget(
        ProgramDurationSelector(
          selectedWeeks: 4,
          onSelectionChanged: (weeks) => selectedWeeks = weeks,
          disabled: true,
        ),
      ));

      await tester.tap(find.text('2 Weeks'));
      await tester.pump();

      expect(selectedWeeks, isNull);
    });

    testWidgets('renders subtitle text', (tester) async {
      await tester.pumpWidget(createTestWidget(
        ProgramDurationSelector(
          selectedWeeks: 4,
          onSelectionChanged: (_) {},
        ),
      ));

      expect(find.text('How far ahead to schedule workouts'), findsOneWidget);
    });

    testWidgets('renders section icon', (tester) async {
      await tester.pumpWidget(createTestWidget(
        ProgramDurationSelector(
          selectedWeeks: 4,
          onSelectionChanged: (_) {},
        ),
      ));

      expect(find.byIcon(Icons.date_range), findsOneWidget);
    });
  });
}
