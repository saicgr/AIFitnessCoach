// Regression test for the light-mode contrast bug reported against the You
// hub gamification tiles ("0 / 464", "Pushup Mastery", "4 ready", "8 to
// unlock" rendering as near-invisible text on a black card). The shared
// cause across `lib/screens/you`, `lib/screens/profile`, `lib/screens/
// rewards`, `lib/screens/trophies`, `lib/screens/achievements` and
// `lib/screens/xp_goals` was raw `AppColors.*` literals (the DARK-theme
// palette) used unconditionally instead of the theme-aware
// `ThemeColors.of(context)` accessor — so cards painted dark regardless of
// the active theme.
//
// `PersonalBestsGrid` (lib/screens/trophies/widgets/personal_bests_grid.dart)
// is one of the fixed surfaces: its tile border was `AppColors.cardBorder`
// (a near-black literal, 0xFF26262B) unconditionally. This test pumps it in
// LIGHT theme and asserts the RESOLVED colours — not just that the widget
// exists — to prove the fix: card border and card fill must be the LIGHT
// palette, and body text must be dark-on-light (not the dark-theme's
// near-white text literal, which is what made the reported tiles
// unreadable).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/core/constants/app_colors.dart';
import 'package:fitwiz/data/providers/personal_bests_provider.dart';
import 'package:fitwiz/l10n/generated/app_localizations.dart';
import 'package:fitwiz/screens/trophies/widgets/personal_bests_grid.dart';

Widget _wrap(Widget child, {required Brightness brightness}) {
  return MaterialApp(
    theme: brightness == Brightness.light ? ThemeData.light() : ThemeData.dark(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SizedBox(
        height: 200,
        child: child,
      ),
    ),
  );
}

const _data = PersonalBests(
  heaviestLift: HeaviestLift(
    exerciseName: 'Bench Press',
    weightLb: 225,
    reps: 5,
    date: '2026-07-01',
  ),
  longestSession: LongestSession(
    workoutName: 'Leg Day',
    durationMinutes: 75,
    date: '2026-07-02',
  ),
  mostVolume: MostVolume(
    workoutName: 'Push Day',
    totalVolumeLb: 12000,
    date: '2026-07-03',
  ),
);

/// Finds every [Container] in the tree whose [BoxDecoration.border] is a
/// uniform [Border] (the tile chrome painted via `Border.all(...)`), and
/// returns the resolved border colors.
List<Color> _tileBorderColors(WidgetTester tester) {
  final containers = tester.widgetList<Container>(find.byType(Container));
  final colors = <Color>[];
  for (final c in containers) {
    final deco = c.decoration;
    if (deco is BoxDecoration && deco.border is Border) {
      final border = deco.border as Border;
      final color = border.top.color;
      if (color != Colors.transparent) colors.add(color);
    }
  }
  return colors;
}

void main() {
  group('PersonalBestsGrid light-theme contrast', () {
    testWidgets('tile border resolves to the LIGHT palette, not the dark literal',
        (tester) async {
      await tester.pumpWidget(_wrap(const PersonalBestsGrid(data: _data), brightness: Brightness.light));
      await tester.pumpAndSettle();

      final borderColors = _tileBorderColors(tester);
      expect(borderColors, isNotEmpty);

      for (final color in borderColors) {
        // The bug: `AppColors.cardBorder` (0xFF26262B, near-black) painted
        // unconditionally regardless of theme. Assert we never see it here.
        expect(color, isNot(equals(AppColors.cardBorder)),
            reason: 'A tile border resolved to the dark-theme cardBorder '
                'literal while running in light theme — this is exactly the '
                'regression: light mode painting dark chrome.');
        // Assert we DO see the light-theme counterpart.
        expect(color, equals(AppColorsLight.cardBorder));
      }
    });

    testWidgets('primary-value text is dark-on-light, not the dark-theme near-white literal',
        (tester) async {
      await tester.pumpWidget(_wrap(const PersonalBestsGrid(data: _data), brightness: Brightness.light));
      await tester.pumpAndSettle();

      // "225 lb × 5" is the heaviest-lift primary value, rendered with
      // `textPrimary` — the exact style class that reads white-on-black when
      // the light/dark branch is missing.
      final valueFinder = find.text('225 lb × 5');
      expect(valueFinder, findsOneWidget);
      final valueText = tester.widget<Text>(valueFinder);
      final resolvedColor = valueText.style!.color!;

      // Contrast assertion: resolved text color must be dark (low luminance)
      // against the light card, and must differ from the dark-theme literal.
      expect(resolvedColor.computeLuminance(), lessThan(0.5),
          reason: 'Primary-value text resolved to a light/near-white color '
              'while the card background is light — text would be '
              'unreadable, reproducing the reported bug.');
      expect(resolvedColor, isNot(equals(AppColors.textPrimary)));
      expect(resolvedColor, equals(AppColorsLight.textPrimary));
    });

    testWidgets('dark theme still renders the dark palette (both directions are wired)',
        (tester) async {
      await tester.pumpWidget(_wrap(const PersonalBestsGrid(data: _data), brightness: Brightness.dark));
      await tester.pumpAndSettle();

      final borderColors = _tileBorderColors(tester);
      expect(borderColors, isNotEmpty);
      for (final color in borderColors) {
        expect(color, equals(AppColors.cardBorder));
      }
    });
  });
}
