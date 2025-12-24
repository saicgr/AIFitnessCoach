import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_fitness_coach/screens/settings/sections/preferences_section.dart';

void main() {
  group('PreferencesSection', () {
    testWidgets('displays section header', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PreferencesSection(),
            ),
          ),
        ),
      );

      expect(find.text('PREFERENCES'), findsOneWidget);
    });

    testWidgets('displays Follow System option', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PreferencesSection(),
            ),
          ),
        ),
      );

      expect(find.text('Follow System'), findsOneWidget);
      expect(find.text('Match device theme'), findsOneWidget);
    });

    testWidgets('displays Dark Mode option', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PreferencesSection(),
            ),
          ),
        ),
      );

      expect(find.text('Dark Mode'), findsOneWidget);
    });

    testWidgets('displays smartphone icon for Follow System', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PreferencesSection(),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.smartphone_outlined), findsOneWidget);
    });

    testWidgets('displays dark mode icon', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PreferencesSection(),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
    });

    testWidgets('has two switches', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PreferencesSection(),
            ),
          ),
        ),
      );

      expect(find.byType(Switch), findsNWidgets(2));
    });

    testWidgets('is a Column widget', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PreferencesSection(),
            ),
          ),
        ),
      );

      expect(find.byType(Column), findsWidgets);
    });
  });
}
