// Regression gate for defect 1: the always-on quick-log FAB (a fixed
// screen-space overlay, independent of scroll position — see
// quick_log_fab_chrome.dart) sat directly on top of the SCHEDULE / LIBRARY /
// BUILDER / PROGRAMS tile row in `WorkoutsSignatureBody`, screenshot-confirmed
// at rest (no scrolling) on an iPhone-16e-class device. `workouts_screen.dart`
// already reserved `kQuickLogFabClearance` at the END of its scroll extent,
// but that only protects the LAST content in the list — this tile row is the
// SECOND block rendered, so the fix has to push the row itself clear of the
// FAB's fixed band, not pad the tail of an unrelated scroll extent.
//
// `extraGapBeforeProgramTiles` (workouts_signature_body.dart) is an ESTIMATE
// (not a measurement) of the row's on-screen top, derived from the same
// public constants production uses — see that function's doc comment for the
// full explanation of why a static estimate can't fully close this class of
// bug (the real fix needs either a measure-then-layout pass or the FAB itself
// to stop floating over arbitrary content). This suite verifies the FORMULA
// itself is internally consistent and actually produces the geometric
// guarantee it claims, using the REAL production constants (not a
// hand-duplicated proxy of them).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/screens/workouts/widgets/workouts_signature_body.dart';
import 'package:fitwiz/widgets/quick_log_fab_chrome.dart'
    show kQuickLogFabBottomOffset;

Future<double> _gapFor(WidgetTester tester, Size size, EdgeInsets padding) async {
  late double result;
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: size, padding: padding),
      child: Builder(builder: (context) {
        result = extraGapBeforeProgramTiles(context);
        return const SizedBox.shrink();
      }),
    ),
  );
  return result;
}

void main() {
  group('extraGapBeforeProgramTiles', () {
    // The exact device class the defect was screenshot-confirmed on.
    const iPhone16e = Size(393, 852);
    const iPhone16ePadding = EdgeInsets.only(top: 59, bottom: 34);

    testWidgets('is positive on the reported device (the row would '
        'otherwise land under the FAB)', (tester) async {
      final gap = await _gapFor(tester, iPhone16e, iPhone16ePadding);
      expect(gap, greaterThan(0),
          reason: 'on the screenshot-confirmed device, the estimated tile '
              'row position lands inside the FAB band with zero extra gap — '
              'if this is 0, the fix does nothing on the device it was '
              'written for');
    });

    testWidgets('the resulting row position clears PAST the FAB band, '
        'not just its near edge', (tester) async {
      final gap = await _gapFor(tester, iPhone16e, iPhone16ePadding);
      final tileRowTop = estimatedProgramTilesTopWithoutExtraGap(59) + gap;
      final fabBandBottom = 852 - 34 - kQuickLogFabBottomOffset;

      expect(tileRowTop, greaterThanOrEqualTo(fabBandBottom),
          reason: 'the row must start at/after the FAB band\'s bottom edge '
              '(clearing only the near edge would still overlap the pill)');
    });

    testWidgets('adds no gap at all on a generously tall device',
        (tester) async {
      final gap = await _gapFor(
        tester,
        const Size(430, 1100),
        const EdgeInsets.only(top: 59, bottom: 34),
      );
      expect(gap, 0.0,
          reason: 'a device with plenty of headroom below the tile row must '
              'not get extra padding it does not need — this formula should '
              'only correct the devices that actually need it');
    });

    testWidgets('a bigger bottom safe-area inset needs LESS (or equal) extra '
        'gap, never more', (tester) async {
      // Holding width/height/top fixed and only growing the bottom inset:
      // the FAB's band is anchored to that inset, so a bigger inset pushes
      // the band's bottom edge UP the screen (fabBandBottom = height -
      // bottomInset - offset shrinks) — the row needs to clear a LOWER
      // target, never a higher one. A formula that got this backwards would
      // punish devices with a bigger home-indicator area instead of helping
      // them.
      // A small delta (0 vs 10) deliberately keeps BOTH cases inside the
      // "row overlaps the band" regime — a large delta risks the SECOND
      // case's overlap check itself flipping to false (already fully
      // cleared), which would make gap 0 for an unrelated reason and mask
      // whether the sign of this relationship is even correct.
      final smallInsetGap = await _gapFor(
        tester,
        iPhone16e,
        const EdgeInsets.only(top: 59, bottom: 0),
      );
      final bigInsetGap = await _gapFor(
        tester,
        iPhone16e,
        const EdgeInsets.only(top: 59, bottom: 10),
      );

      expect(bigInsetGap, lessThan(smallInsetGap));
    });
  });
}
