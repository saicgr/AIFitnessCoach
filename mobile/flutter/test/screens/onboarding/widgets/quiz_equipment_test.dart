import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/screens/onboarding/widgets/quiz_equipment.dart';
import 'package:fitwiz/l10n/generated/app_localizations.dart';

void main() {
  group('QuizEquipment', () {
    testWidgets('displays question text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: QuizEquipment(
              selectedEquipment: const {},
              dumbbellCount: 2,
              kettlebellCount: 1,
              onEquipmentToggled: (_) {},
              onDumbbellCountChanged: (_) {},
              onKettlebellCountChanged: (_) {},
              onInfoTap: (_, __, ___) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('What equipment do you have access to?'), findsOneWidget);
    });

    testWidgets('displays equipment options', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: QuizEquipment(
              selectedEquipment: const {},
              dumbbellCount: 2,
              kettlebellCount: 1,
              onEquipmentToggled: (_) {},
              onDumbbellCountChanged: (_) {},
              onKettlebellCountChanged: (_) {},
              onInfoTap: (_, __, ___) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      // The categorized grid holds the individual equipment tiles. The base
      // cases ("Bodyweight only" / "Full Gym") are Quick Presets, which only
      // render when the parent opts in via onPresetSelected.
      expect(find.text('Dumbbells'), findsOneWidget);
      expect(find.text('Barbell'), findsOneWidget);
      expect(find.text('Kettlebell'), findsOneWidget);
    });

    testWidgets('calls onEquipmentToggled when option is tapped', (tester) async {
      String? toggledId;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: QuizEquipment(
              selectedEquipment: const {},
              dumbbellCount: 2,
              kettlebellCount: 1,
              onEquipmentToggled: (id) {
                toggledId = id;
              },
              onDumbbellCountChanged: (_) {},
              onKettlebellCountChanged: (_) {},
              onInfoTap: (_, __, ___) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Dumbbells'));
      await tester.pump();

      expect(toggledId, equals('dumbbells'));
    });

    testWidgets('shows check mark for selected equipment', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: QuizEquipment(
              selectedEquipment: const {'dumbbells', 'barbell'},
              dumbbellCount: 2,
              kettlebellCount: 1,
              onEquipmentToggled: (_) {},
              onDumbbellCountChanged: (_) {},
              onKettlebellCountChanged: (_) {},
              onInfoTap: (_, __, ___) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check), findsNWidgets(2));
    });

    testWidgets('displays full gym quick preset when presets are wired', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: QuizEquipment(
              selectedEquipment: const {},
              dumbbellCount: 2,
              kettlebellCount: 1,
              onEquipmentToggled: (_) {},
              onDumbbellCountChanged: (_) {},
              onKettlebellCountChanged: (_) {},
              onInfoTap: (_, __, ___) {},
              onPresetSelected: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Bodyweight only'), findsOneWidget);

      // "Full Gym" is the last chip in the horizontally-scrolling preset row,
      // so it is not built until the row is scrolled to it.
      final presetRow = find.descendant(
        of: find.byWidgetPredicate(
          (w) => w is ListView && w.scrollDirection == Axis.horizontal,
        ),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.text('Full Gym'),
        200,
        scrollable: presetRow,
      );
      expect(find.text('Full Gym'), findsOneWidget);
    });

    testWidgets('renders in dark mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData.dark(),
          home: Scaffold(
            body: QuizEquipment(
              selectedEquipment: const {},
              dumbbellCount: 2,
              kettlebellCount: 1,
              onEquipmentToggled: (_) {},
              onDumbbellCountChanged: (_) {},
              onKettlebellCountChanged: (_) {},
              onInfoTap: (_, __, ___) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('What equipment do you have access to?'), findsOneWidget);
    });

    testWidgets('renders in light mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData.light(),
          home: Scaffold(
            body: QuizEquipment(
              selectedEquipment: const {},
              dumbbellCount: 2,
              kettlebellCount: 1,
              onEquipmentToggled: (_) {},
              onDumbbellCountChanged: (_) {},
              onKettlebellCountChanged: (_) {},
              onInfoTap: (_, __, ___) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('What equipment do you have access to?'), findsOneWidget);
    });
  });
}
