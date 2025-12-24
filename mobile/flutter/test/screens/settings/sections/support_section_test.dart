import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_fitness_coach/screens/settings/sections/support_section.dart';

void main() {
  group('SupportSection', () {
    testWidgets('displays section header', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SupportSection(),
            ),
          ),
        ),
      );

      expect(find.text('SUPPORT'), findsOneWidget);
    });

    testWidgets('displays Help & Support option', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SupportSection(),
            ),
          ),
        ),
      );

      expect(find.text('Help & Support'), findsOneWidget);
    });

    testWidgets('displays Privacy Policy option', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SupportSection(),
            ),
          ),
        ),
      );

      expect(find.text('Privacy Policy'), findsOneWidget);
    });

    testWidgets('displays Terms of Service option', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SupportSection(),
            ),
          ),
        ),
      );

      expect(find.text('Terms of Service'), findsOneWidget);
    });

    testWidgets('displays help icon', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SupportSection(),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.help_outline), findsOneWidget);
    });

    testWidgets('displays privacy icon', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SupportSection(),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.privacy_tip_outlined), findsOneWidget);
    });

    testWidgets('displays description icon', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SupportSection(),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.description_outlined), findsOneWidget);
    });

    testWidgets('calls onHelpTap when Help is tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SupportSection(
                onHelpTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Help & Support'));
      await tester.pumpAndSettle();

      expect(tapped, true);
    });

    testWidgets('calls onPrivacyTap when Privacy is tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SupportSection(
                onPrivacyTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Privacy Policy'));
      await tester.pumpAndSettle();

      expect(tapped, true);
    });

    testWidgets('calls onTermsTap when Terms is tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SupportSection(
                onTermsTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Terms of Service'));
      await tester.pumpAndSettle();

      expect(tapped, true);
    });

    testWidgets('shows chevrons for navigation items', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SupportSection(),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.chevron_right), findsNWidgets(3));
    });
  });
}
