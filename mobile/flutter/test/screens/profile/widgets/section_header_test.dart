import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_fitness_coach/screens/profile/widgets/section_header.dart';

void main() {
  group('SectionHeader', () {
    testWidgets('displays title correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SectionHeader(title: 'QUICK ACCESS'),
          ),
        ),
      );

      expect(find.text('QUICK ACCESS'), findsOneWidget);
    });

    testWidgets('displays action widget when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SectionHeader(
              title: 'SETTINGS',
              action: TextButton(
                onPressed: () {},
                child: const Text('Edit'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('SETTINGS'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
    });

    testWidgets('does not show action when null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SectionHeader(title: 'TEST'),
          ),
        ),
      );

      expect(find.text('TEST'), findsOneWidget);
      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets('renders in dark mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: SectionHeader(title: 'DARK MODE'),
          ),
        ),
      );

      expect(find.text('DARK MODE'), findsOneWidget);
    });

    testWidgets('renders in light mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const Scaffold(
            body: SectionHeader(title: 'LIGHT MODE'),
          ),
        ),
      );

      expect(find.text('LIGHT MODE'), findsOneWidget);
    });
  });
}
