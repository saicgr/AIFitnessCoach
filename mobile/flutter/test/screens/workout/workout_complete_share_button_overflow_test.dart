// E2E register #141 — "RIGHT OVERFLOWED BY 0.243 PIXELS" on the
// workout-complete summary, layered over the Share / Coach-Recap area.
//
// Root cause: `workout_complete_screen.dart`'s bottom action Row splits its
// width `flex: 1` (Share) vs `flex: 2` (Done) — a division that's rarely an
// integer pixel count. `ZealovaButton` (lib/widgets/design_system/
// zealova_button.dart, a shared design-system widget outside this screen's
// ownership) renders its uppercase label + icon in a bare `Row` with no
// `Flexible` wrapping the `Text`, so it needs marginally more than the
// fractional slot it's handed — a sub-pixel RenderFlex overflow.
//
// Fix (call-site only, since zealova_button.dart isn't owned here):
// LayoutBuilder + OverflowBox hands the Share button a few px of internal
// slack to lay out into WITHOUT changing the size it reports to its
// Expanded slot — the overflow genuinely never occurs (this is verified via
// `tester.takeException()`, which DOES still catch the underlying
// RenderFlex overflow assertion even behind a plain ClipRect — clipping
// only hides the debug-paint stripes, it doesn't stop the layout-time
// error report, so ClipRect alone would NOT pass this gate).
//
// E2E #160 (and why this harness looks the way it does): `OverflowBox` is
// `sizedByParent` — it reports `constraints.biggest` as its OWN size. The
// slack above only constrains the WIDTH, so the height passes straight
// through, and given a loose/unbounded incoming height the box inflates to
// fill it. Production therefore pins the vertical axis with
// `SizedBox(height: _kCompleteCtaHeight /* 52 */)` around the
// LayoutBuilder (workout_complete_screen.dart, the `Expanded` at the head of
// the Share/Done Row). This harness used to build the OLD, pre-#160 shape —
// a bare LayoutBuilder + OverflowBox with nothing bounding its height — and
// blew the Dart stack (48k-deep recursion out of `flushSemantics`) instead
// of asserting anything, i.e. it reproduced a bug production no longer has.
// It now mirrors the shipped shape, so it is a live gate for #141 again and
// additionally pins the 52px height that #160 turned on.
//
// The Row is reproduced at a width chosen so 1/3 of it is NOT an integer
// pixel count (335px, matching a 375px-wide screen minus 40px of horizontal
// padding — an iPhone SE class width, and using the REAL app font via
// flutter_test_config.dart so the text metrics match production, not the
// wider Ahem fallback).
//
// Vacuity guard: the second test builds the same Row WITHOUT the OverflowBox
// slack and asserts the overflow IS reported — so a future change that makes
// the overflow impossible for unrelated reasons can't leave test #1 passing
// while gating nothing.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/widgets/design_system/zealova_button.dart';

/// Mirrors `_kCompleteCtaHeight` in workout_complete_screen.dart (private
/// there). The `_isSubmitting` Done-button branch hardcodes the same 52.
const double _kCtaHeight = 52;

void main() {
  /// The production Share slot: Expanded > SizedBox(height) > LayoutBuilder >
  /// OverflowBox > ZealovaButton. [withSlack] drops the LayoutBuilder +
  /// OverflowBox pair (the pre-#141 shape) for the vacuity guard.
  Widget shareSlot({required bool withSlack}) {
    const button = ZealovaButton(
      label: 'Share',
      onTap: _noop,
      variant: ZealovaButtonVariant.ghost,
      trailingIcon: Icons.share_rounded,
    );
    if (!withSlack) return button;
    return const SizedBox(
      height: _kCtaHeight,
      child: _SlackBox(child: button),
    );
  }

  Widget buildRow({required bool withSlack}) => MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              // 335 / 3 = 111.66... — forces the exact fractional-flex
              // scenario that produced the reported 0.243px overflow.
              width: 335,
              child: Row(
                children: [
                  Expanded(child: shareSlot(withSlack: withSlack)),
                  const SizedBox(width: 12),
                  const Expanded(
                    flex: 2,
                    child: ZealovaButton(label: 'Done', onTap: _noop),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  testWidgets(
      '#141 Share/Done action row never overflows at a fractional flex width',
      (tester) async {
    await tester.pumpWidget(buildRow(withSlack: true));
    await tester.pump();

    expect(tester.takeException(), isNull);

    // #160: the slack is HORIZONTAL only — the OverflowBox must stay pinned to
    // the CTA height rather than swallowing whatever height it is offered.
    final overflowBoxSize = tester.getSize(find.byType(OverflowBox));
    expect(overflowBoxSize.height, _kCtaHeight);

    // #141: and the slack must not leak outward — the Share slot still reports
    // exactly its 1/3 Expanded share (335 - 12 gap = 323; 323 / 3).
    expect(overflowBoxSize.width, closeTo(323 / 3, 0.01));
  });

  testWidgets('vacuity guard: without the slack the same Row DOES overflow',
      (tester) async {
    await tester.pumpWidget(buildRow(withSlack: false));
    await tester.pump();

    final error = tester.takeException();
    expect(error, isNotNull,
        reason: 'expected the bare ZealovaButton to overflow its fractional '
            'slot — if it no longer does, the #141 gate above is vacuous');
    expect(error.toString(), contains('overflowed'));
  });
}

void _noop() {}

/// Const-constructible stand-in for the inline
/// `LayoutBuilder(builder: (_, c) => OverflowBox(...))` production uses.
class _SlackBox extends StatelessWidget {
  const _SlackBox({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => OverflowBox(
          alignment: Alignment.center,
          minWidth: constraints.maxWidth,
          maxWidth: constraints.maxWidth + 16,
          child: child,
        ),
      );
}
