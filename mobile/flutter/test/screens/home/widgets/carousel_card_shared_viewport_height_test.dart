/// Regression test for Home → metrics carousel dead-space gap after
/// "Make the card taller" (E2E row 194, LOW).
///
/// The whole carousel PageView viewport grows when the Training page opts
/// into the taller 240px card, but every OTHER page's `CarouselCardShell`
/// (`tall: false`, since only Training supports the taller variant) used to
/// independently re-derive its own height from ITS OWN `tall` flag and
/// render at the normal 170px anyway — opening an ~87pt dead gap between
/// the card and "Browse programs" below on every non-Training page. Pins
/// that a shell with `tall: false` still fills whatever tight height its
/// slot actually provides (240px here), rather than shrinking to its own
/// 170px regardless of the shared viewport.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/screens/home/widgets/metrics_carousel/metrics_carousel_cards.dart';

void main() {
  testWidgets(
      'a normal-height (tall: false) card still fills a taller shared '
      'viewport slot — no dead gap below it', (tester) async {
    // Simulates the PageView item slot once Training has opted into the
    // taller 240px viewport — every page (including this non-Training,
    // tall:false one) gets that same tight height from the shared PageView.
    const sharedViewportHeight = kCarouselCardHeightTall;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: SizedBox(
            width: 358,
            height: sharedViewportHeight,
            // `Align` gives its child LOOSE constraints (min 0, max = the
            // 240pt slot) — this is what actually lets a `SizedBox(height:
            // 170)` inside the shell render smaller than the slot in the
            // first place. A directly-tight parent alone can't reproduce
            // the bug (same class of constraint-propagation subtlety as
            // the row-137 width fix's test harness).
            child: Align(
              alignment: Alignment.topLeft,
              child: CarouselCardShell(
                pageIndex: 1,
                pageCount: 3,
                tall: false, // this page itself is NOT the tall one
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

    final height = tester.getSize(find.byType(CarouselCardShell)).height;
    expect(height, sharedViewportHeight,
        reason: 'the card must fill the full shared viewport height '
            '(${sharedViewportHeight}pt) rather than shrinking to its own '
            '${kCarouselCardHeightNormal}pt and leaving a dead gap below it '
            '(E2E row 194)');
  });
}
