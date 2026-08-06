// Regression test for E2E row 191: the date picker opened from the shared
// DateStrip (Nutrition + Sleep/Combined-Health) rendered as a stock Material 3
// dialog on a brown/tan panel inside a black-and-orange app
// (docs/qa/screenshots/2026-08-05/ui_nutrition_74_datepicker2_s.png).
//
// Root cause was NOT the DateStrip call site. `DatePickerThemeData
// .backgroundColor` falls back to `colorScheme.surfaceContainerHigh`, a tonal
// role this app never overrode (it overrides `colorScheme.surface` only) — and
// since the whole scheme is seeded from the user's accent, an orange accent
// produces a brown surfaceContainerHigh. 35 call sites open showDatePicker and
// only 8 hand-rolled a `builder: Theme(...)` wrapper, so the fix belongs in
// AppTheme/AppThemeLight, which covers every call site including future ones.
//
// This test asserts the DEFECT: it opens a real showDatePicker under the real
// app theme and reads the colour the dialog actually paints — not merely that
// a theme field is non-null.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/core/constants/app_colors.dart';
import 'package:fitwiz/core/theme/app_theme.dart';
import 'package:fitwiz/core/theme/theme_provider.dart';

/// The app's real accent — an orange seed is what turned the tonal
/// surfaceContainerHigh role brown in the first place.
const _accent = AppColors.orange;

Future<Color?> _openPickerAndReadSurface(
  WidgetTester tester,
  ThemeData theme,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showDatePicker(
                context: context,
                initialDate: DateTime(2026, 8, 5),
                firstDate: DateTime(2025),
                lastDate: DateTime(2027),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();

  expect(find.byType(DatePickerDialog), findsOneWidget,
      reason: 'the picker must actually be on screen for this assertion');

  final dialogTheme = DatePickerTheme.of(
    tester.element(find.byType(DatePickerDialog)),
  );
  return dialogTheme.backgroundColor;
}

void main() {
  testWidgets(
    'dark theme date picker paints the app elevated surface, not the seeded '
    'tonal (brown) surfaceContainerHigh',
    (tester) async {
      final theme = AppTheme.buildDarkTheme(_accent);

      // Guard the premise: without an override the picker WOULD have used
      // this brownish tonal role. If Flutter ever changes that default this
      // test should be revisited rather than silently passing.
      expect(
        theme.colorScheme.surfaceContainerHigh,
        isNot(AppColors.elevated),
        reason: 'premise of the finding: the tonal role differs from the '
            'brand surface, so an unthemed picker looks off-brand',
      );

      final painted = await _openPickerAndReadSurface(tester, theme);

      expect(
        painted,
        AppColors.elevated,
        reason: 'The date picker must use the app surface token. Got '
            '$painted (tonal role is '
            '${theme.colorScheme.surfaceContainerHigh}).',
      );
    },
  );

  testWidgets(
    'light theme date picker paints the app elevated surface',
    (tester) async {
      final theme = AppThemeLight.buildTheme(_accent);
      final painted = await _openPickerAndReadSurface(tester, theme);

      expect(painted, AppColorsLight.elevated);
    },
  );

  testWidgets(
    'time picker is themed too (same tonal-role defect, same chokepoint)',
    (tester) async {
      final theme = AppTheme.buildDarkTheme(_accent);
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 9, minute: 0),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final t = TimePickerTheme.of(
        tester.element(find.byType(TimePickerDialog)),
      );
      expect(t.backgroundColor, AppColors.elevated);
    },
  );
}
