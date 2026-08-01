// Regression gate for E2E #160 — the workout-complete screen rendered as a
// black wall with "BOTTOM OVERFLOWED BY Infinity PIXELS".
//
// Root cause: `OverflowBox` is `sizedByParent` and reports `constraints.biggest`
// as its own size. Inside `Scaffold.bottomNavigationBar` the incoming height
// constraint is not tight, so an OverflowBox with only `minWidth`/`maxWidth`
// specified (height passed straight through) sizes itself to the full
// available height. The bottom bar then swallows the whole screen, the body is
// squeezed to nothing, and the Column overflows by infinity.
//
// The irony worth preserving: that OverflowBox was introduced to fix E2E #141,
// a 0.243-PIXEL horizontal overflow on the same Row. The cure was ~2500x the
// size of the disease.
//
// These tests reproduce the mechanism in isolation rather than pumping the real
// screen, which needs a full Workout + provider graph. `bare` fails on the old
// shape; `bounded` passes on the fix. Both assert on real layout, not a string.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The button height the screen's own `_isSubmitting` branch hardcodes, and the
/// height the fix pins the slack-giving OverflowBox to.
const double kCtaHeight = 52;

Widget _harness({required Widget child}) => MaterialApp(
      home: Scaffold(
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [Expanded(child: child)]),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
        body: const SizedBox.expand(child: ColoredBox(color: Colors.blue)),
      ),
    );

void main() {
  testWidgets(
      'an unbounded-height OverflowBox in the bottom bar eats the whole screen',
      (tester) async {
    await tester.pumpWidget(_harness(
      child: LayoutBuilder(
        builder: (context, c) => OverflowBox(
          alignment: Alignment.center,
          minWidth: c.maxWidth,
          maxWidth: c.maxWidth + 16,
          child: const SizedBox(height: kCtaHeight),
        ),
      ),
    ));

    final screenHeight = tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final barHeight = tester.getSize(find.byType(SafeArea).first).height;

    // The defect: the bottom bar is the whole screen, not a ~92px strip.
    expect(barHeight, greaterThan(screenHeight * 0.9),
        reason: 'expected the unbounded OverflowBox to inflate the bottom bar');
    expect(tester.takeException(), isNotNull,
        reason: 'expected a layout overflow to be reported');
  });

  testWidgets('pinning the height keeps the bar a strip and throws nothing',
      (tester) async {
    await tester.pumpWidget(_harness(
      child: SizedBox(
        height: kCtaHeight,
        child: LayoutBuilder(
          builder: (context, c) => OverflowBox(
            alignment: Alignment.center,
            minWidth: c.maxWidth,
            maxWidth: c.maxWidth + 16,
            child: const SizedBox(height: kCtaHeight),
          ),
        ),
      ),
    ));

    final screenHeight = tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final barHeight = tester.getSize(find.byType(SafeArea).first).height;

    expect(barHeight, lessThan(screenHeight * 0.5),
        reason: 'bottom bar must stay a strip, not consume the screen');
    // The horizontal slack that #141 needed is still granted.
    expect(tester.takeException(), isNull);
  });
}
