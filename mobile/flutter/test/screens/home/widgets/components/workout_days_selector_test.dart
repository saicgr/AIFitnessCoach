import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/screens/home/widgets/components/workout_days_selector.dart';
import '../../test_helpers.dart';

void main() {
  group('WorkoutDaysSelector', () {
    testWidgets('renders all day names', (tester) async {
      await tester.pumpWidget(createTestWidget(
        WorkoutDaysSelector(
          selectedDays: const {},
          onSelectionChanged: (_) {},
        ),
      ));

      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Tue'), findsOneWidget);
      expect(find.text('Wed'), findsOneWidget);
      expect(find.text('Thu'), findsOneWidget);
      expect(find.text('Fri'), findsOneWidget);
      expect(find.text('Sat'), findsOneWidget);
      expect(find.text('Sun'), findsOneWidget);
    });

    testWidgets('shows correct days/week count', (tester) async {
      await tester.pumpWidget(createTestWidget(
        WorkoutDaysSelector(
          selectedDays: const {0, 2, 4}, // Mon, Wed, Fri
          onSelectionChanged: (_) {},
        ),
      ));

      expect(find.text('3 days/week'), findsOneWidget);
    });

    testWidgets('calls onSelectionChanged when day is tapped', (tester) async {
      Set<int>? newSelection;

      await tester.pumpWidget(createTestWidget(
        WorkoutDaysSelector(
          selectedDays: const {},
          onSelectionChanged: (days) => newSelection = days,
        ),
      ));

      await tester.tap(find.text('Mon'));
      await tester.pump();

      expect(newSelection, contains(0));
    });

    testWidgets('removes day from selection when tapped again', (tester) async {
      Set<int>? newSelection;

      await tester.pumpWidget(createTestWidget(
        WorkoutDaysSelector(
          selectedDays: const {0}, // Mon selected
          onSelectionChanged: (days) => newSelection = days,
        ),
      ));

      await tester.tap(find.text('Mon'));
      await tester.pump();

      expect(newSelection, isNot(contains(0)));
    });

    testWidgets('does not respond when disabled', (tester) async {
      Set<int>? newSelection;

      await tester.pumpWidget(createTestWidget(
        WorkoutDaysSelector(
          selectedDays: const {},
          onSelectionChanged: (days) => newSelection = days,
          disabled: true,
        ),
      ));

      await tester.tap(find.text('Mon'));
      await tester.pump();

      expect(newSelection, isNull);
    });

    testWidgets('renders subtitle text', (tester) async {
      await tester.pumpWidget(createTestWidget(
        WorkoutDaysSelector(
          selectedDays: const {},
          onSelectionChanged: (_) {},
        ),
      ));

      expect(find.text('Select which days you want to work out'), findsOneWidget);
    });

    testWidgets('uses custom day names', (tester) async {
      await tester.pumpWidget(createTestWidget(
        WorkoutDaysSelector(
          selectedDays: const {},
          onSelectionChanged: (_) {},
          dayNames: const ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
        ),
      ));

      expect(find.text('M'), findsOneWidget);
      // T appears twice (Tuesday and Thursday)
      expect(find.text('T'), findsNWidgets(2));
    });
  });
}
