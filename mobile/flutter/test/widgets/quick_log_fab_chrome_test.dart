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

    testWidgets('renders its caption and exposes it as a button to a11y',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host('Quick Log'));

      expect(find.text('Quick Log'), findsOneWidget);
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

    testWidgets('caption is never ellipsised', (tester) async {
      await tester.pumpWidget(host('Quick Log'));

      final text = tester.widget<Text>(find.text('Quick Log'));
      expect(
        text.overflow,
        isNot(TextOverflow.ellipsis),
        reason:
            'ellipsis on a caption this short deletes the identifying word '
            '(row 108); the caption must scale down instead',
      );
      expect(find.byType(FittedBox), findsOneWidget);
    });

    testWidgets('a long localisation at 2.0 text scale neither overflows '
        'nor loses letters', (tester) async {
      // German-length caption at the largest accessibility step.
      const long = 'Schnellerfassung';
      await tester.pumpWidget(host(long, textScale: 2.0));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // Every letter still present — scaled, not truncated.
      expect(find.text(long), findsOneWidget);
      // And the control still respects the shell's width bound.
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
