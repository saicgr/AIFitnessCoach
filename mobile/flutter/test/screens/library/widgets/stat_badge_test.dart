import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/screens/library/widgets/stat_badge.dart';

void main() {
  group('StatBadge', () {
    testWidgets('renders icon, value, and label correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatBadge(
              icon: Icons.fitness_center,
              value: '50',
              label: 'sets',
              color: Colors.cyan,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.fitness_center), findsOneWidget);
      expect(find.text('50'), findsOneWidget);
      expect(find.text('sets'), findsOneWidget);
    });

    testWidgets('uses provided color for icon and value',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatBadge(
              icon: Icons.emoji_events,
              value: '100',
              label: 'kg',
              color: Colors.green,
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.emoji_events));
      expect(icon.color, Colors.green);
    });

    testWidgets('renders in dark mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: StatBadge(
              icon: Icons.timer,
              value: '45',
              label: 'min',
              color: Colors.orange,
            ),
          ),
        ),
      );

      expect(find.text('45'), findsOneWidget);
      expect(find.text('min'), findsOneWidget);
    });
  });

  group('StatTile', () {
    testWidgets('renders title and value correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatTile(
              title: 'Max Weight',
              value: '100 kg',
              icon: Icons.monitor_weight,
              color: Colors.purple,
            ),
          ),
        ),
      );

      expect(find.text('Max Weight'), findsOneWidget);
      expect(find.text('100 kg'), findsOneWidget);
      expect(find.byIcon(Icons.monitor_weight), findsOneWidget);
    });

    testWidgets('renders in dark mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: StatTile(
              title: 'Est. 1RM',
              value: '120 kg',
              icon: Icons.emoji_events_outlined,
              color: Colors.green,
            ),
          ),
        ),
      );

      expect(find.text('Est. 1RM'), findsOneWidget);
      expect(find.text('120 kg'), findsOneWidget);
    });

    testWidgets('renders in light mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const Scaffold(
            body: StatTile(
              title: 'Total Reps',
              value: '500',
              icon: Icons.repeat,
              color: Colors.blue,
            ),
          ),
        ),
      );

      expect(find.text('Total Reps'), findsOneWidget);
      expect(find.text('500'), findsOneWidget);
    });

    testWidgets('handles long values', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatTile(
              title: 'Volume',
              value: '1,250,000 kg',
              icon: Icons.bar_chart,
              color: Colors.teal,
            ),
          ),
        ),
      );

      expect(find.text('Volume'), findsOneWidget);
      expect(find.text('1,250,000 kg'), findsOneWidget);
    });
  });
}
