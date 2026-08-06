// Regression test for FITWIZ-FLUTTER-HE/HW/G9/H7/J2/HX/J4/HJ: eight Sentry
// issues, all firing the same FlutterError —
// "ListTile background color or ink splashes may be invisible" — from
// eight different screens (/settings, /chat/sessions, /workout/:id, /stats,
// /health/sleep). Root cause: GlassSheet (the app's shared bottom-sheet
// wrapper, lib/widgets/glass_sheet.dart) painted its glass background via a
// `Container`/`BoxDecoration` directly around `child`, with no `Material`
// of its own. Any `ListTile` placed inside a GlassSheet by any screen then
// had to reach past that DecoratedBox to find a Material ancestor, which
// Flutter flags because the DecoratedBox occludes the ListTile's ink/bg.
//
// This test asserts the DEFECT directly: build a GlassSheet with a
// ListTile as its child and confirm FlutterError.onError is never invoked
// with the ListTile assertion. Negative-tested: reverting the Material
// wrapper in glass_sheet.dart makes this test fail with that exact error.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/l10n/generated/app_localizations.dart';
import 'package:fitwiz/widgets/glass_sheet.dart';

void main() {
  testWidgets(
    'GlassSheet does not trigger the ListTile background/ink-splash '
    'visibility assertion when a ListTile is placed inside it',
    (tester) async {
      FlutterErrorDetails? capturedError;
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        capturedError = details;
        // Also forward so genuinely unrelated failures still surface in
        // test output.
        originalOnError?.call(details);
      };

      addTearDown(() => FlutterError.onError = originalOnError);

      // Build GlassSheet directly (rather than via showGlassSheet's modal
      // route) inside a bounded ancestor sized like a phone viewport. This
      // isolates the widget under test — GlassSheet's own Material
      // ancestor — from unrelated modal-route layout behavior, while still
      // exercising the exact widget tree shape (DecoratedBox > ... >
      // ListTile) that produced the Sentry assertion.
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 800,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: GlassSheet(
                  child: ListTile(
                    title: const Text('Row'),
                    onTap: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        capturedError,
        isNull,
        reason:
            'GlassSheet must provide its own Material ancestor so a '
            'ListTile placed inside it never triggers the '
            '"background color or ink splashes may be invisible" '
            'assertion. Got: ${capturedError?.exceptionAsString()}',
      );
    },
  );
}
