import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/core/constants/chrome_constants.dart';
import 'package:fitwiz/widgets/quick_log_fab_chrome.dart';

/// Regression gate for E2E register row 16 (+ the row-108 truncation class as
/// it applies to this control) and its #177 recurrence (collapse on scroll).
///
/// Row 16: the always-on quick-log button that docks above the main nav on
/// Home, Workout, Nutrition and You was an UNLABELLED 44×44 square with a bare
/// "+" glyph — no caption, no Semantics — sitting on top of real controls.
/// #177: even captioned, a pill wide enough to read blankets whatever the
/// scroll view renders underneath it, because a `Positioned(bottom:)` control
/// is painted at a fixed screen offset independent of scroll position. Three
/// invariants have to hold forever:
///
///   1. GEOMETRY. The space a tab reserves at the end of its scroll extent
///      (`kQuickLogFabClearance`) must be derived from where the button
///      actually is (`kQuickLogFabBottomOffset`) plus how tall it actually is
///      (`kQuickLogFabHeight`). If someone nudges the button and hand-edits
///      only one of the two numbers, content silently slides back under it.
///      The button's HEIGHT (unlike its width) never changes between the
///      expanded and collapsed states, so this invariant holds regardless of
///      [QuickLogFabChrome.expanded].
///   2. LEGIBILITY. The caption must be rendered AND exposed to the semantics
///      tree, and must never be ellipsised — including at a large text scale,
///      which is precisely the case where the obvious `TextOverflow.ellipsis`
///      would eat the identifying word.
///   3. COLLAPSE ON SCROLL. The button is a labelled pill only at rest (top
///      of scroll); the instant content is moving under it, it must shrink to
///      the icon-only circle — and grow back the moment the scroll returns to
///      rest at the top. In BOTH states the control must stay reachable (this
///      suite never hides it) and the [Semantics] label must be identical, so
///      a screen reader never hears the control change identity mid-scroll.
void main() {
  group('quick-log FAB geometry (row 16 — occlusion)', () {
    test('clearance is derived from the button, not hand-written', () {
      // The button's own footprint, computed independently of the constant
      // under test. Anything a tab reserves that is smaller than this leaves
      // its last row of content underneath the button. Uses kQuickLogFabHeight
      // directly — the button's HEIGHT is identical in both the expanded and
      // collapsed state (only its WIDTH differs), so this is state-agnostic.
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

  group('quick-log FAB legibility + collapse-on-scroll (row 16 / #177)', () {
    Widget host(
      String label, {
      required bool expanded,
      double textScale = 1.0,
    }) =>
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: Scaffold(
              body: Align(
                alignment: Alignment.bottomRight,
                child: ConstrainedBox(
                  // Same bound the shell applies (screen width − 2×24).
                  constraints: const BoxConstraints(maxWidth: 800 - 48),
                  child: QuickLogFabChrome(
                    label: label,
                    expanded: expanded,
                    onTap: () {},
                  ),
                ),
              ),
            ),
          ),
        );

    testWidgets(
        'expanded at rest: caption renders and is announced (not doubled)',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host('Quick Log', expanded: true));

      // Visible caption at rest…
      expect(find.text('Quick Log'), findsOneWidget);
      // …and the outer Semantics node announces the same label exactly once
      // (ExcludeSemantics on the Text stops it doubling up).
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

    testWidgets('collapsed after scroll: icon-only but still labelled to a11y',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host('Quick Log', expanded: false));

      // The caption is REVEALED, not inserted — so while collapsed the Text
      // still exists in the tree, clipped to zero width and fully
      // transparent. Asserting `findsNothing` would be asserting an
      // implementation detail (two swapped subtrees) that we deliberately
      // replaced with one interpolated widget, because swapping is what made
      // the transition jump. Assert the VISIBLE result instead: it occupies
      // no width and paints nothing.
      final capAlign = tester.widget<Align>(find.ancestor(
        of: find.text('Quick Log'), matching: find.byType(Align)).first);
      expect(capAlign.widthFactor, 0.0);
      expect(
        tester.widget<Opacity>(find.ancestor(
            of: find.text('Quick Log'), matching: find.byType(Opacity)).first)
            .opacity,
        0.0,
      );
      // …but the semantics tree still announces it as a labelled button —
      // identical to the expanded-state label above, so a screen-reader user
      // never hears the control change identity when the FAB collapses.
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

    testWidgets('collapsed stays a compact circle so it cannot blanket content',
        (tester) async {
      await tester.pumpWidget(host('Quick Log', expanded: false));
      await tester.pumpAndSettle();

      final size = tester.getSize(find.byType(QuickLogFabChrome));
      // Square-ish: the labelled pill is ~3x wider than tall, which is what
      // put it on top of "View all", the habit rows and the hero title
      // (#177) — only safe while the button isn't floating over moving
      // content, i.e. never while collapsed.
      expect(size.width, lessThanOrEqualTo(size.height + 1),
          reason: 'a wide pill while collapsed re-creates the #177 overlap');
    });

    testWidgets('expanding again at the top restores the wider pill',
        (tester) async {
      // Simulates the return-to-top transition: rebuild the same widget with
      // expanded flipped true→false→true, as main_shell.dart does by
      // re-watching quickLogFabExpandedProvider on scroll position.
      await tester.pumpWidget(host('Quick Log', expanded: true));
      await tester.pumpAndSettle();
      final expandedWidth =
          tester.getSize(find.byType(QuickLogFabChrome)).width;

      await tester.pumpWidget(host('Quick Log', expanded: false));
      await tester.pumpAndSettle();
      final collapsedWidth =
          tester.getSize(find.byType(QuickLogFabChrome)).width;

      await tester.pumpWidget(host('Quick Log', expanded: true));
      await tester.pumpAndSettle();
      final reExpandedWidth =
          tester.getSize(find.byType(QuickLogFabChrome)).width;

      expect(collapsedWidth, lessThan(expandedWidth),
          reason: 'collapsing must actually narrow the button');
      expect(reExpandedWidth, expandedWidth,
          reason: 'returning to the top must restore the same pill width');
      expect(find.text('Quick Log'), findsOneWidget,
          reason: 'the caption must be back after re-expanding');
    });

    testWidgets(
        'a long localisation at 2.0 text scale scales down, never ellipsises, '
        'when expanded', (tester) async {
      const long = 'Schnellerfassung';
      await tester.pumpWidget(host(long, expanded: true, textScale: 2.0));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // The full string renders — a real ellipsis would swap in "…" and the
      // literal text would no longer be found intact.
      expect(find.text(long), findsOneWidget);
      expect(
        tester.getSize(find.byType(QuickLogFabChrome)).width,
        lessThanOrEqualTo(800 - 48),
      );
    });

    testWidgets(
        'collapsed state is immune to caption length / text scale entirely',
        (tester) async {
      const long = 'Schnellerfassung';
      await tester.pumpWidget(host(long, expanded: false, textScale: 2.0));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // Width is what matters: however long the localisation, the collapsed
      // control is a circle. The caption contributes zero because its Align
      // widthFactor is 0 — see the note in the collapsed a11y test above.
      final size = tester.getSize(find.byType(QuickLogFabChrome));
      expect(size.width, lessThanOrEqualTo(size.height + 1));
    });

    testWidgets('expanded pill hugs its caption instead of filling the width',
        (tester) async {
      // Shipped bug, 2026-08-03: `Container(alignment: Alignment.center)` on
      // the expanded branch made the pill span the ENTIRE screen. A Container
      // with an alignment expands to fill BOUNDED constraints, and the shell
      // wraps this in a ConstrainedBox(maxWidth: screenWidth - 48) — so the
      // alignment silently turned a hug-your-content pill into a full-width
      // bar. Every existing test still passed, because they all asserted on
      // the caption and none on the WIDTH.
      await tester.pumpWidget(host('Quick Log', expanded: true));

      final fab = tester.getSize(find.byType(QuickLogFabChrome));
      // Generous ceiling — the point is "hugs its content", not an exact px.
      expect(fab.width, lessThan(220),
          reason: 'the expanded pill must size to its caption, not to the '
              'constraints it is offered');
      // …and it is still clearly wider than the collapsed circle, or the
      // expand state would be pointless.
      expect(fab.width, greaterThan(kQuickLogFabHeight));
    });

    testWidgets('tap reaches the handler in both states', (tester) async {
      var taps = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: QuickLogFabChrome(
              label: 'Quick Log',
              expanded: true,
              onTap: () => taps++,
            ),
          ),
        ),
      ));
      await tester.tap(find.byType(QuickLogFabChrome));
      expect(taps, 1);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: QuickLogFabChrome(
              label: 'Quick Log',
              expanded: false,
              onTap: () => taps++,
            ),
          ),
        ),
      ));
      await tester.tap(find.byType(QuickLogFabChrome));
      expect(taps, 2);
    });

    testWidgets('reduced motion snaps instead of animating the collapse',
        (tester) async {
      Widget hostWithMotion({required bool expanded, required bool reduce}) =>
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(disableAnimations: reduce),
              child: Scaffold(
                body: Align(
                  alignment: Alignment.bottomRight,
                  child: QuickLogFabChrome(
                    label: 'Quick Log',
                    expanded: expanded,
                    onTap: () {},
                  ),
                ),
              ),
            ),
          );

      await tester.pumpWidget(hostWithMotion(expanded: true, reduce: true));
      await tester.pumpWidget(hostWithMotion(expanded: false, reduce: true));
      // A single pump (no pumpAndSettle needed) already reflects the
      // collapsed size under reduced motion — nothing is mid-flight.
      await tester.pump();
      final size = tester.getSize(find.byType(QuickLogFabChrome));
      expect(size.width, lessThanOrEqualTo(size.height + 1),
          reason:
              'disableAnimations must snap straight to the collapsed size, '
              'not animate toward it');
    });
  });
}
