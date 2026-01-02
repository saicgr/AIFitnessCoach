import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/screens/home/widgets/components/stat_badge.dart';
import '../../test_helpers.dart';

void main() {
  group('StatBadge', () {
    testWidgets('renders icon and value', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const StatBadge(
          icon: Icons.check_circle_outline,
          value: '10',
          color: Colors.green,
        ),
      ));

      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('applies correct color to icon and text', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const StatBadge(
          icon: Icons.fitness_center,
          value: '5',
          color: Colors.blue,
        ),
      ));

      final icon = tester.widget<Icon>(find.byIcon(Icons.fitness_center));
      expect(icon.color, equals(Colors.blue));
    });

    testWidgets('renders without tooltip when not provided', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const StatBadge(
          icon: Icons.check,
          value: '3',
          color: Colors.green,
        ),
      ));

      expect(find.byType(Tooltip), findsNothing);
    });

    testWidgets('renders with tooltip when provided', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const StatBadge(
          icon: Icons.check,
          value: '3',
          color: Colors.green,
          tooltip: 'Total completed',
        ),
      ));

      expect(find.byType(Tooltip), findsOneWidget);
    });
  });

  group('StatPill', () {
    testWidgets('renders icon and value', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const StatPill(
          icon: Icons.timer_outlined,
          value: '45m',
        ),
      ));

      expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
      expect(find.text('45m'), findsOneWidget);
    });

    testWidgets('renders in both dark and light themes', (tester) async {
      // Dark theme
      await tester.pumpWidget(createTestWidget(
        const StatPill(
          icon: Icons.fitness_center,
          value: '8 exercises',
        ),
        isDark: true,
      ));

      expect(find.text('8 exercises'), findsOneWidget);

      // Light theme
      await tester.pumpWidget(createTestWidget(
        const StatPill(
          icon: Icons.fitness_center,
          value: '8 exercises',
        ),
        isDark: false,
      ));

      expect(find.text('8 exercises'), findsOneWidget);
    });
  });
}
