import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_fitness_coach/screens/settings/sections/logout_section.dart';
import 'package:ai_fitness_coach/core/constants/app_colors.dart';

void main() {
  group('LogoutSection', () {
    testWidgets('displays Sign Out button', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LogoutSection(),
            ),
          ),
        ),
      );

      expect(find.text('Sign Out'), findsOneWidget);
    });

    testWidgets('displays logout icon', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LogoutSection(),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.logout), findsOneWidget);
    });

    testWidgets('button has error color styling', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LogoutSection(),
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.logout));
      expect(icon.color, AppColors.error);
    });

    testWidgets('button text has error color', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LogoutSection(),
            ),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('Sign Out'));
      expect(text.style?.color, AppColors.error);
    });

    testWidgets('is an OutlinedButton', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LogoutSection(),
            ),
          ),
        ),
      );

      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('shows confirmation dialog when tapped', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LogoutSection(),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(OutlinedButton));
      await tester.pumpAndSettle();

      expect(find.text('Sign Out?'), findsOneWidget);
    });

    testWidgets('confirmation dialog has Cancel button', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LogoutSection(),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(OutlinedButton));
      await tester.pumpAndSettle();

      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('confirmation dialog has Sign Out button', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LogoutSection(),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(OutlinedButton));
      await tester.pumpAndSettle();

      // There should be two Sign Out texts - one in button, one in dialog
      expect(find.text('Sign Out'), findsNWidgets(2));
    });

    testWidgets('dialog closes when Cancel is tapped', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LogoutSection(),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(OutlinedButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Sign Out?'), findsNothing);
    });

    testWidgets('dialog has confirmation message', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LogoutSection(),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(OutlinedButton));
      await tester.pumpAndSettle();

      expect(
        find.text('Are you sure you want to sign out? You can sign back in anytime.'),
        findsOneWidget,
      );
    });

    testWidgets('button takes full width', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LogoutSection(),
            ),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox));
      expect(sizedBox.width, double.infinity);
    });
  });
}
