import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/core/providers/locale_provider.dart' show supportedAppLocales;
import 'package:fitwiz/l10n/generated/app_localizations.dart';
import 'package:fitwiz/screens/settings/widgets/workout_days_sheet.dart';

// LIGHT-MODE CONTRAST REGRESSION (settings lane repair, "search FAB doesn't
// read as floating" ticket): the selected-day chip used to paint
// `AppColors.cyanGradient` directly — a light-grey gradient
// (0xFFE0E0E0 -> 0xFFBDBDBD) tuned to sit on a near-black DARK-theme sheet.
// With no `isDark` guard, that literal painted in LIGHT theme too, so the
// "selected" chip rendered as a barely-visible light-grey blob on the
// light-theme sheet's near-white background — functionally invisible
// selection state. The fix resolves the gradient through
// `ThemeColors.of(context).accentGradient`, which paints the user's accent
// colour (real contrast) in both themes instead of the dark-only literal.
void main() {
  Future<void> pumpSheet(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        darkTheme: ThemeData.light(),
        themeMode: ThemeMode.light,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: supportedAppLocales,
        home: Scaffold(
          body: WorkoutDaysSheet(
            initialSelectedDays: const {0},
            onSave: (_) async {},
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets(
    'selected day chip resolves a real accent colour in light theme, not '
    'the dark-theme grey literal',
    (tester) async {
      await pumpSheet(tester);

      // The 7 day chips are 44x64 AnimatedContainers; index 0 (Monday) is
      // selected via `initialSelectedDays: {0}` and is the first one built.
      final dayChips = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .where((c) =>
              c.constraints?.maxWidth == 44 && c.constraints?.maxHeight == 64)
          .toList();
      expect(dayChips, isNotEmpty);

      final selectedDecoration = dayChips.first.decoration as BoxDecoration;
      final gradient = selectedDecoration.gradient as LinearGradient?;
      expect(gradient, isNotNull,
          reason: 'selected chip must paint a gradient, not fall through to '
              'the null (unselected) branch');

      final chipColor = gradient!.colors.first;

      // The dark-theme-only literal this used to always render (regardless
      // of theme): must NOT still be what light theme paints.
      expect(chipColor, isNot(equals(const Color(0xFFE0E0E0))));

      // Real contrast check: the resolved colour must be meaningfully
      // darker than a near-white light-theme sheet background — the old
      // light-grey literal (luminance ~0.76) fails this; a genuine accent
      // colour (e.g. the default orange accent, luminance ~0.43) passes.
      expect(
        chipColor.computeLuminance(),
        lessThan(0.75),
        reason:
            'selected-day chip must have real contrast against the light '
            'sheet background, not the near-invisible dark-theme grey',
      );
    },
  );
}
