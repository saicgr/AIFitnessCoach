import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/core/constants/chrome_constants.dart';
import 'package:fitwiz/widgets/quick_log_fab_chrome.dart';

/// Regression gate for E2E register row 16 (+ the row-108 truncation class as
/// it applies to this control).
///
/// Row 16: the always-on quick-log button that docks above the main nav on
/// Home, Workout, Nutrition and You was an UNLABELLED 44×44 square with a bare
/// "+" glyph — no caption, no Semantics — sitting on top of real controls.
/// Two invariants have to hold forever:
///
///   1. GEOMETRY. The space a tab reserves at the end of its scroll extent
///      (`kQuickLogFabClearance`) must be derived from where the button
///      actually is (`kQuickLogFabBottomOffset`) plus how tall it actually is
///      (`kQuickLogFabHeight`). If someone nudges the button and hand-edits
///      only one of the two numbers, content silently slides back under it.
///   2. LEGIBILITY. The caption must be rendered AND exposed to the semantics
///      tree, and must never be ellipsised — including at a large text scale,
///      which is precisely the case where the obvious `TextOverflow.ellipsis`
///      would eat the identifying word.
void main() {
  group('quick-log FAB geometry (row 16 — occlusion)', () {
    test('clearance is derived from the button, not hand-written', () {
      // The button's own footprint, computed independently of the constant
      // under test. Anything a tab reserves that is smaller than this leaves
      // its last row of content underneath the button.
      final double footprintAboveSafeArea =
          kQuickLogFabBottomOffset + kQuickLogFabHeight;

      expect(
        kQuickLogFabClearance,
        greaterThanOrEqualTo(footprintAboveSafeArea),
        reason:
            'kQuickLogFabClearance ($kQuickLogFabClearance) must cover the '
            'button that actually paints there ($footprintAboveSafeArea).',
      );
    });

    test('the button sits clear of the floating nav pill', () {
      expect(
        kQuickLogFabBottomOffset,
        greaterThanOrEqualTo(kMainNavBarHeight + kMainNavBottomGap),
        reason: 'the button must not paint inside the nav pill',
      );
    });

    test('nav-only clearance is NOT enough for a tab that renders the button',
        () {
      // This is the row-16 defect stated as an assertion: every tab reserved
      // kMainNavClearance and nothing else, which is short of the button by
      // this much. Any screen that renders the FAB must use
      // kQuickLogFabClearance instead.
      expect(kQuickLogFabClearance, greaterThan(kMainNavClearance));
    });
  });

  group('quick-log FAB legibility (row 16 — unlabelled control)', () {
    Widget host(String label, {double textScale = 1.0}) => MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: Scaffold(
              body: Align(
                alignment: Alignment.bottomRight,
                child: ConstrainedBox(
                  // Same bound the shell applies (screen width − 2×24).
                  constraints: const BoxConstraints(maxWidth: 800 - 48),
                  child: QuickLogFabChrome(label: label, onTap: () {}),
                ),
              ),
            ),
          ),
        );

    testWidgets('is icon-only on screen but still labelled to a11y',
        (tester) async {
      // 2026-08-03: the visible caption was REMOVED at the user's request —
      // they had it as a bare "+" and preferred that. This is a deliberate
      // partial revert of row 16's original remedy, so the invariant is
      // restated rather than deleted: row 16's real complaint was that the
      // control was unlabelled AND covered content. The caption addressed the
      // first; the icon-only pill plus its Semantics label addresses it for
      // assistive tech, and being ~3x narrower is what actually fixes the
      // second (see #177 — no offset could save a control that wide).
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host('Quick Log'));

      // No visible caption…
      expect(find.text('Quick Log'), findsNothing);
      // …but the semantics tree still announces it as a labelled button.
      expect(
        tester.getSemantics(find.byType(QuickLogFabChrome)),
        matchesSemantics(
          label: 'Quick Log',
          isButton: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('stays a compact circle so it cannot blanket content',
        (tester) async {
      await tester.pumpWidget(host('Quick Log'));

      final size = tester.getSize(find.byType(QuickLogFabChrome));
      // Square-ish: the labelled pill was ~3x wider than tall, which is what
      // put it on top of "View all", the habit rows and the hero title.
      expect(size.width, lessThanOrEqualTo(size.height + 1),
          reason: 'a wide pill re-creates the #177 overlap');
    });

    testWidgets('a long localisation at 2.0 text scale changes nothing',
        (tester) async {
      // With no rendered caption, translation length can no longer affect the
      // control's width at all — which is the point. Kept as a gate so a
      // future re-introduction of a caption has to face this case again.
      const long = 'Schnellerfassung';
      await tester.pumpWidget(host(long, textScale: 2.0));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(long), findsNothing);
      expect(
        tester.getSize(find.byType(QuickLogFabChrome)).width,
        lessThanOrEqualTo(800 - 48),
      );
    });

    testWidgets('tap reaches the handler', (tester) async {
      var taps = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: QuickLogFabChrome(label: 'Quick Log', onTap: () => taps++),
          ),
        ),
      ));
      await tester.tap(find.byType(QuickLogFabChrome));
      expect(taps, 1);
    });
  });
}
