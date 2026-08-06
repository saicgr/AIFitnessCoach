// Regression test for E2E row 75: on every sheet opened through
// showGlassSheet(), the close "×" was painted INSIDE the drag handle in
// near-identical grey (see docs/qa/screenshots/2026-08-05/ui_stats_72_grabber.png),
// producing an overlapping, effectively invisible control.
//
// Root cause was pure layout, in the shared chrome (lib/widgets/glass_sheet.dart):
// GlassSheetHandle's Stack had exactly one non-positioned child — the 48×5
// handle bar — so StackFit.loose shrink-wrapped the Stack to 48×5. The
// `PositionedDirectional(end: 8)` close button was therefore positioned 8pt
// from the right edge of a 48pt-wide box, i.e. centred over the grabber, and
// clipped to the bar's 5pt height by Stack's default Clip.hardEdge.
//
// These tests assert the DEFECT directly:
//   1. the close button's rect does not intersect the handle bar's rect;
//   2. the close button actually sits at the sheet's trailing edge;
//   3. the close button is not vertically clipped (its box fits the band).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/l10n/generated/app_localizations.dart';
import 'package:fitwiz/widgets/glass_sheet.dart';

const double _kSheetWidth = 400;

Future<void> _pumpHandle(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData.dark(),
      home: Scaffold(
        body: SizedBox(
          width: _kSheetWidth,
          height: 800,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: GlassSheet(
              child: const SizedBox(height: 120, child: Text('body')),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The drag handle bar itself — the only [Container] sized exactly
/// [GlassSheetStyle.handleWidth] × [GlassSheetStyle.handleHeight].
Finder _handleBar() => find.descendant(
      of: find.byType(GlassSheetHandle),
      matching: find.byWidgetPredicate(
        (w) => w is Container && w.decoration is BoxDecoration,
      ),
    );

Finder _closeIcon() => find.descendant(
      of: find.byType(GlassSheetHandle),
      matching: find.byIcon(Icons.close),
    );

void main() {
  testWidgets(
    'GlassSheet close button does not overlap the drag handle',
    (tester) async {
      await _pumpHandle(tester);

      final handleRect = tester.getRect(_handleBar().first);
      final closeRect = tester.getRect(_closeIcon());

      expect(
        handleRect.overlaps(closeRect),
        isFalse,
        reason:
            'The sheet close button must not be painted on top of the drag '
            'handle. handle=$handleRect close=$closeRect',
      );
    },
  );

  testWidgets(
    'GlassSheet close button is pinned to the sheet trailing edge',
    (tester) async {
      await _pumpHandle(tester);

      final sheetRect = tester.getRect(find.byType(GlassSheetHandle));
      final closeRect = tester.getRect(_closeIcon());

      // The band must span the full sheet width — the shrink-wrapped-to-48pt
      // bug is exactly what put the close button over the grabber.
      expect(
        sheetRect.width,
        _kSheetWidth,
        reason: 'The handle band must span the sheet, not shrink-wrap to the '
            'handle bar.',
      );
      expect(
        closeRect.right,
        greaterThan(sheetRect.right - 40),
        reason: 'Close button should sit at the trailing edge of the sheet. '
            'band=$sheetRect close=$closeRect',
      );
    },
  );

  testWidgets(
    'GlassSheet close button is not vertically clipped by the handle band',
    (tester) async {
      await _pumpHandle(tester);

      final bandRect = tester.getRect(find.byType(GlassSheetHandle));
      final closeRect = tester.getRect(_closeIcon());

      expect(
        closeRect.height,
        lessThanOrEqualTo(bandRect.height),
        reason: 'Close icon (${closeRect.height}pt) must fit inside the handle '
            'band (${bandRect.height}pt) — it used to be clipped to the 5pt '
            'handle bar.',
      );
    },
  );
}
