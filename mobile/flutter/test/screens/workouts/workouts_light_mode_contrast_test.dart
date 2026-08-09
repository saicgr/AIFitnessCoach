// Regression gate: LIGHT MODE readability on the Workouts tab.
//
// Photographed defect: the BROWSE BY TYPE category tiles (STRENGTH / CARDIO /
// MOBILITY / HIIT / YOGA / SAVED) were black cards with near-invisible
// labels, the QUICK GENERATE row was dark-on-dark, and the masthead's four
// hairline action pills + the "GYM · <name>" chip were dark boxes floating on
// a white header. Root cause: `_CategoryTile` / `_QuickGenerateBlock` /
// `_HairlineActionPill` / `_EquipmentProfilePill` painted their card fill +
// border from the raw dark-theme literals `AppColors.surface2` /
// `AppColors.cardBorder` instead of the theme-aware `ThemeColors.of(context)`
// accessor, so the card stayed near-black even when the rest of the app
// switched to light mode — while the label text (correctly theme-aware)
// switched to near-black too. Dark-on-dark.
//
// This suite pumps the REAL widgets in `ThemeData.light()` and asserts the
// RESOLVED colours actually differ — not just that the widgets exist.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/screens/workouts/widgets/workout_library_grid.dart';

/// Relative luminance distance between two colors. 0 = identical (the
/// dark-on-dark failure mode); larger = more contrast.
double _luminanceGap(Color a, Color b) =>
    (a.computeLuminance() - b.computeLuminance()).abs();

void main() {
  group('BROWSE BY TYPE tiles — light mode contrast', () {
    Future<void> pumpGrid(WidgetTester tester, ThemeData theme) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Scaffold(body: WorkoutLibraryGrid()),
        ),
      );
      await tester.pump();
    }

    testWidgets(
        'STRENGTH tile: card fill is LIGHT and label text is DARK — not '
        'dark-on-dark', (tester) async {
      await pumpGrid(tester, ThemeData.light());

      final labelFinder = find.text('STRENGTH');
      expect(labelFinder, findsOneWidget);

      final label = tester.widget<Text>(labelFinder);
      final textColor = label.style!.color!;

      // The tile's own fill — the nearest Container ancestor of the label
      // that actually carries a BoxDecoration color (the tile card itself,
      // not an outer layout Container).
      final containers = tester
          .widgetList<Container>(
            find.ancestor(
                of: labelFinder, matching: find.byType(Container)),
          )
          .where((c) => c.decoration is BoxDecoration &&
              (c.decoration as BoxDecoration).color != null)
          .toList();
      expect(containers, isNotEmpty,
          reason: 'expected to find the tile Container with a solid fill '
              'color between the label and the widget root');
      final cardColor =
          (containers.first.decoration as BoxDecoration).color!;

      // The regression: both resolved to (near-)black, so luminance gap ~0
      // and the text was unreadable against the card.
      expect(_luminanceGap(cardColor, textColor), greaterThan(0.3),
          reason: 'card fill ($cardColor) and label text ($textColor) must '
              'have real contrast in light mode — a near-zero gap here is '
              'exactly the dark-card/dark-text bug from the screenshot');

      // Directly pin down the failure mode: in light mode the CARD must be
      // light (not the near-black AppColors.surface2 literal) and the TEXT
      // must be dark.
      expect(cardColor.computeLuminance(), greaterThan(0.5),
          reason: 'tile fill must be a light surface in light mode — a low '
              'luminance here means it is still painting the dark-theme '
              'literal regardless of theme');
      expect(textColor.computeLuminance(), lessThan(0.5),
          reason: 'label text must be dark-on-light in light mode');
    });

    testWidgets('all six category tiles render their labels legibly',
        (tester) async {
      await pumpGrid(tester, ThemeData.light());

      for (final label in [
        'STRENGTH',
        'CARDIO',
        'MOBILITY',
        'HIIT',
        'YOGA',
        'SAVED',
      ]) {
        final finder = find.text(label);
        expect(finder, findsOneWidget, reason: 'missing tile label: $label');
        final text = tester.widget<Text>(finder);
        expect(text.style!.color!.computeLuminance(), lessThan(0.5),
            reason: '$label must render as dark text in light mode');
      }
    });

    testWidgets('dark mode still renders a dark card with light text',
        (tester) async {
      await pumpGrid(tester, ThemeData.dark());

      final labelFinder = find.text('STRENGTH');
      final label = tester.widget<Text>(labelFinder);
      final textColor = label.style!.color!;

      final containers = tester
          .widgetList<Container>(
            find.ancestor(
                of: labelFinder, matching: find.byType(Container)),
          )
          .where((c) => c.decoration is BoxDecoration &&
              (c.decoration as BoxDecoration).color != null)
          .toList();
      final cardColor =
          (containers.first.decoration as BoxDecoration).color!;

      expect(cardColor.computeLuminance(), lessThan(0.5),
          reason: 'dark mode must keep the dark card fill');
      expect(_luminanceGap(cardColor, textColor), greaterThan(0.3),
          reason: 'dark mode must also keep real contrast');
    });
  });
}
