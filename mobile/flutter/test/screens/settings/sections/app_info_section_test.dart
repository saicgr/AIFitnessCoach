import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_fitness_coach/screens/settings/sections/app_info_section.dart';

void main() {
  group('AppInfoSection', () {
    testWidgets('displays section header', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AppInfoSection(),
            ),
          ),
        ),
      );

      expect(find.text('APP INFO'), findsOneWidget);
    });

    testWidgets('displays About option', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AppInfoSection(),
            ),
          ),
        ),
      );

      expect(find.text('About'), findsOneWidget);
    });

    testWidgets('displays Rate App option', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AppInfoSection(),
            ),
          ),
        ),
      );

      expect(find.text('Rate App'), findsOneWidget);
    });

    testWidgets('displays info icon', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AppInfoSection(),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('displays star icon', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AppInfoSection(),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.star_outline), findsOneWidget);
    });

    testWidgets('shows about dialog when About is tapped', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AppInfoSection(),
            ),
          ),
        ),
      );

      await tester.tap(find.text('About'));
      await tester.pumpAndSettle();

      expect(find.text('AI Fitness Coach'), findsOneWidget);
      expect(find.text('Version 1.0.0'), findsOneWidget);
    });

    testWidgets('about dialog has Close button', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AppInfoSection(),
            ),
          ),
        ),
      );

      await tester.tap(find.text('About'));
      await tester.pumpAndSettle();

      expect(find.text('Close'), findsOneWidget);
    });

    testWidgets('about dialog closes when Close is tapped', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AppInfoSection(),
            ),
          ),
        ),
      );

      await tester.tap(find.text('About'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.text('Version 1.0.0'), findsNothing);
    });

    testWidgets('calls custom onAboutTap when provided', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AppInfoSection(
                onAboutTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('About'));
      await tester.pumpAndSettle();

      expect(tapped, true);
    });

    testWidgets('calls onRateTap when Rate App is tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AppInfoSection(
                onRateTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Rate App'));
      await tester.pumpAndSettle();

      expect(tapped, true);
    });

    testWidgets('shows chevrons for navigation items', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AppInfoSection(),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.chevron_right), findsNWidgets(2));
    });
  });
}
