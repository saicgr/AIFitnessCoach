/// Light-mode contrast regression test for [EmptyWorkoutCard]
/// (lane: home — light-mode repair).
///
/// Root cause under test: this card's background and accent (teal) colors
/// were painted from bare `AppColors.*` (dark-theme literals) instead of the
/// theme-aware `ThemeColors` accessor, so light mode rendered a near-black
/// card with near-white text painted on top of it — unreadable. This test
/// pumps the card in a light theme and asserts the RESOLVED colors actually
/// differ (real contrast: light background, dark text), not just that the
/// widget builds without throwing.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/core/constants/app_colors.dart';
import 'package:fitwiz/l10n/generated/app_localizations.dart';
import 'package:fitwiz/screens/home/widgets/cards/workout_state_cards.dart';

Widget _wrapLight(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: ThemeData.light(),
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets(
    'EmptyWorkoutCard resolves a light card background in light theme '
    '(not the dark literal), with real text contrast on top of it',
    (tester) async {
      await tester.pumpWidget(_wrapLight(EmptyWorkoutCard(onGenerate: () {})));
      await tester.pumpAndSettle();

      // The card's outer Container is painted from `tc.elevated` (post-fix).
      final containerFinder = find.byWidgetPredicate(
        (w) => w is Container && w.decoration is BoxDecoration,
      );
      expect(containerFinder, findsWidgets);

      final Container card = tester.widget(containerFinder.first);
      final BoxDecoration decoration = card.decoration! as BoxDecoration;
      final Color? resolvedBg = decoration.color;
      expect(resolvedBg, isNotNull);

      // Must be the LIGHT elevated token, not the dark-theme literal — a
      // dark literal here is exactly the "black cards in light mode" bug.
      expect(resolvedBg, equals(AppColorsLight.elevated));
      expect(resolvedBg, isNot(equals(AppColors.elevated)));

      // Heading text ("Ready to start...") is painted from `tc.textPrimary`.
      final textFinder = find.byWidgetPredicate(
        (w) => w is Text && w.style?.fontSize == 22,
      );
      expect(textFinder, findsOneWidget);
      final Text heading = tester.widget(textFinder);
      final Color? resolvedText = heading.style?.color;
      expect(resolvedText, isNotNull);
      expect(resolvedText, equals(AppColorsLight.textPrimary));
      expect(resolvedText, isNot(equals(AppColors.textPrimary)));

      // Real contrast check, not a mechanical token swap: the resolved card
      // background must actually differ from the resolved text color, and
      // by a wide luminance margin -- the whole point of this repair.
      expect(resolvedBg, isNot(equals(resolvedText)));
      final bgLuminance = resolvedBg!.computeLuminance();
      final textLuminance = resolvedText!.computeLuminance();
      expect((bgLuminance - textLuminance).abs(), greaterThan(0.3));

      // And the card background itself must read as "light" (high
      // luminance) in light theme -- not a near-black card masquerading as
      // theme-aware because it happens to differ slightly from pure black.
      expect(bgLuminance, greaterThan(0.5));
    },
  );
}
