import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_fitness_coach/screens/library/widgets/info_badge.dart';

void main() {
  group('InfoBadge', () {
    testWidgets('renders icon and text correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoBadge(
              icon: Icons.fitness_center,
              text: 'Chest',
              color: Colors.purple,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.fitness_center), findsOneWidget);
      expect(find.text('Chest'), findsOneWidget);
    });

    testWidgets('uses provided color', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoBadge(
              icon: Icons.star,
              text: 'Premium',
              color: Colors.amber,
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.star));
      expect(icon.color, Colors.amber);
    });

    testWidgets('renders in dark mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: InfoBadge(
              icon: Icons.accessibility_new,
              text: 'Beginner',
              color: Colors.green,
            ),
          ),
        ),
      );

      expect(find.text('Beginner'), findsOneWidget);
    });
  });

  group('DetailBadge', () {
    testWidgets('renders label and value correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DetailBadge(
              icon: Icons.signal_cellular_alt,
              label: 'Level',
              value: 'Intermediate',
              color: Colors.orange,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.signal_cellular_alt), findsOneWidget);
      expect(find.text('Level'), findsOneWidget);
      expect(find.text('Intermediate'), findsOneWidget);
    });

    testWidgets('renders in dark mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: DetailBadge(
              icon: Icons.category,
              label: 'Type',
              value: 'Compound',
              color: Colors.cyan,
            ),
          ),
        ),
      );

      expect(find.text('Type'), findsOneWidget);
      expect(find.text('Compound'), findsOneWidget);
    });

    testWidgets('renders in light mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const Scaffold(
            body: DetailBadge(
              icon: Icons.repeat,
              label: 'Reps',
              value: '8-12',
              color: Colors.blue,
            ),
          ),
        ),
      );

      expect(find.text('Reps'), findsOneWidget);
      expect(find.text('8-12'), findsOneWidget);
    });
  });
}
