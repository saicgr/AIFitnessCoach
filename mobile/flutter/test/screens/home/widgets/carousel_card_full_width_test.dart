/// Regression test for Home → metrics carousel card width (E2E row 137,
/// MED).
///
/// The carousel card was pinned to a flat 330pt (`kCarouselCardWidth`)
/// regardless of the width its PageView item slot actually offered — on a
/// real device that left a ~28pt unused gap on the right, a ragged step
/// against every neighbouring full-width Home card. Pins that
/// `CarouselCardShell` fills the exact width it's given.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/screens/home/widgets/metrics_carousel/metrics_carousel_cards.dart';

void main() {
  testWidgets('CarouselCardShell fills the full width of its slot, not a '
      'flat 330pt', (tester) async {
    // 358pt — the real available width on a 390pt phone after the shared
    // 16pt kHomeHPad gutters on each side (the exact case from the finding).
    const slotWidth = 358.0;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: SizedBox(
            width: slotWidth,
            // An outer `Align` gives its child LOOSE constraints (min 0,
            // max = the slot width) — this is what the production PageView
            // item used to wrap the shell in, and is exactly what let a
            // `ConstrainedBox(maxWidth: 330)` shrink the card below the
            // real 358pt slot in the first place. A *tight* slot alone
            // (no `Align`) can't reproduce the bug, since `ConstrainedBox`
            // has no effect once its incoming constraints are already
            // tight — so this wrapper is required for the test to be
            // sensitive to a regression back to the old code.
            child: Align(
              alignment: Alignment.topLeft,
              child: CarouselCardShell(
                pageIndex: 0,
                pageCount: 1,
                onEdit: () {},
                child: const SizedBox(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);

    final shellFinder = find.byType(CarouselCardShell);
    final width = tester.getSize(shellFinder).width;
    expect(width, slotWidth,
        reason: 'must fill the full slot width (358pt here) rather than '
            'shrink-wrapping to the old fixed 330pt constant and leaving a '
            'gap other Home cards do not have (E2E row 137)');
  });
}
