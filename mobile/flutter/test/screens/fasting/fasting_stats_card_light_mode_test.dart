/// Light-mode contrast regression test for [FastingStatsCard]
/// (lane: nutrition/fasting light-mode repair).
///
/// Root cause under test: several borders/dividers/text colors inside this
/// card were painted from bare `AppColors.*` (dark-theme literals) instead
/// of the theme-aware `ThemeColors` accessor, so light mode rendered
/// dark-grey hairlines/dividers indistinguishable from — or worse, darker
/// than — the surface they sat on. This test pumps the card in a light
/// theme and asserts the RESOLVED colors actually differ (real contrast),
/// not just that the widget builds without throwing.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/core/constants/app_colors.dart';
import 'package:fitwiz/data/models/fasting.dart';
import 'package:fitwiz/l10n/generated/app_localizations.dart';
import 'package:fitwiz/screens/fasting/widgets/fasting_stats_card.dart';

Widget _wrapLight(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: ThemeData.light(),
    home: Scaffold(body: child),
  );
}

FastingStatsCard _buildCard({required bool isDark}) => FastingStatsCard(
      stats: const FastingStats(
        userId: 'u1',
        completedFasts: 5,
        totalFasts: 6,
        avgDurationMinutes: 960,
        longestFastMinutes: 1200,
        totalFastingMinutes: 4800,
      ),
      streak: const FastingStreak(
        userId: 'u1',
        currentStreak: 3,
        fastsThisWeek: 3,
        weeklyGoalFasts: 5,
        weeklyGoalEnabled: true,
      ),
      score: const FastingScore(
        userId: 'u1',
        score: 72,
      ),
      isDark: isDark,
    );

void main() {
  testWidgets(
    'FastingStatsCard renders a real light card border in light theme '
    '(not the dark literal)',
    (tester) async {
      await tester.pumpWidget(_wrapLight(_buildCard(isDark: false)));
      await tester.pumpAndSettle();

      // Find the divider Container between the stat tiles — it is painted
      // directly from `tc.cardBorder` (post-fix) inside `_buildDivider`.
      final dividerFinder = find.byWidgetPredicate(
        (w) => w is Container && w.constraints?.maxWidth == 1 && w.color != null,
      );
      expect(dividerFinder, findsWidgets);

      final Container divider = tester.widget(dividerFinder.first);
      final Color resolvedBorder = divider.color!;

      // The light-mode border must be the LIGHT token, not the dark-theme
      // literal — and it must visibly differ from a plain white surface so
      // the divider is not just invisible ink-on-paper.
      expect(resolvedBorder, equals(AppColorsLight.cardBorder));
      expect(resolvedBorder, isNot(equals(AppColors.cardBorder)));
      expect(resolvedBorder, isNot(equals(Colors.white)));

      // Real contrast check: luminance of the resolved border must be
      // clearly darker than a white background (light-mode surface), i.e.
      // it must actually be visible on a light card — not a near-black
      // literal painted on a near-black assumption that happens to also
      // read as "some color".
      expect(resolvedBorder.computeLuminance(),
          lessThan(Colors.white.computeLuminance()));
    },
  );

  testWidgets(
    'FastingStatsCard streak-day text resolves to the light text token, '
    'distinct from its own background',
    (tester) async {
      await tester.pumpWidget(_wrapLight(_buildCard(isDark: false)));
      await tester.pumpAndSettle();

      // The current-streak label ("3 days") is rendered via
      // ZType.disp(26, color: tc.textPrimary) — locate it by substring since
      // the exact string is a localized plural form.
      final textFinder = find.textContaining('3');
      expect(textFinder, findsWidgets);

      final Text textWidget = tester.widget(textFinder.first);
      final Color? resolvedTextColor = textWidget.style?.color;

      expect(resolvedTextColor, isNotNull);
      // Must be the LIGHT text token (near-black), not the dark-theme
      // literal (near-white) — a near-white token here would render
      // invisible text on the light card background.
      expect(resolvedTextColor, equals(AppColorsLight.textPrimary));
      expect(resolvedTextColor, isNot(equals(AppColors.textPrimary)));

      // The resolved text color must have materially different luminance
      // from the light-mode background so it is actually legible.
      final bgLuminance = AppColorsLight.background.computeLuminance();
      final textLuminance = resolvedTextColor!.computeLuminance();
      expect((bgLuminance - textLuminance).abs(), greaterThan(0.3));
    },
  );
}
