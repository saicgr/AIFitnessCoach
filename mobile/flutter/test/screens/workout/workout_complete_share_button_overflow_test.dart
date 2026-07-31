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
// This test reproduces the exact Row shape (flex:1 / flex:2, 12px gap) at a
// width chosen so 1/3 of it is NOT an integer pixel count (335px, matching a
// 375px-wide screen minus 40px of horizontal padding — an iPhone SE class
// width, and using the REAL app font via flutter_test_config.dart so the
// text metrics match production, not the wider Ahem fallback), and asserts
// no RenderFlex overflow is reported.
//
// Negative-tested: removing the `OverflowBox` wrapper (plain Expanded ->
// ZealovaButton) reproduces the reported overflow exception and fails this
// test.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/widgets/design_system/zealova_button.dart';

void main() {
  Widget buildRow({required bool withFix}) {
    Widget shareButton = ZealovaButton(
      label: 'Share',
      onTap: () {},
      variant: ZealovaButtonVariant.ghost,
      trailingIcon: Icons.share_rounded,
    );
    if (withFix) {
      shareButton = LayoutBuilder(
        builder: (context, constraints) => OverflowBox(
          alignment: Alignment.center,
          minWidth: constraints.maxWidth,
          maxWidth: constraints.maxWidth + 16,
          child: shareButton,
        ),
      );
    }
    return MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            // 335 / 3 = 111.66... — forces the exact fractional-flex
            // scenario that produced the reported 0.243px overflow.
            width: 335,
            child: Row(
              children: [
                Expanded(child: shareButton),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ZealovaButton(label: 'Done', onTap: () {}),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
      '#141 Share/Done action row never overflows at a fractional flex width',
      (tester) async {
    await tester.pumpWidget(buildRow(withFix: true));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
