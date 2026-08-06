// Gate: ZealovaTextTabs must not overflow when text scale grows.
//
// 14 files build this tab strip — stats, nutrition, skills, achievements,
// rewards, leaderboard, injuries, streaks, progress. It was a plain Row with
// fixed 18px gaps, so a set of tabs that fits at the default text scale
// overflows the moment the user raises system text size (measured at 2.0x by
// test/ui_gates/no_overflow_gate_test.dart).
//
// That is the failure mode nobody screenshots and everybody with accessibility
// sizing hits.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/widgets/design_system/zealova_chip.dart';

Widget _harness({
  required List<String> tabs,
  required double width,
  double textScale = 1.0,
  int active = 0,
  ValueChanged<int>? onChanged,
}) {
  return MaterialApp(
    theme: ThemeData.dark(),
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: ZealovaTextTabs(
              tabs: tabs,
              activeIndex: active,
              onChanged: onChanged,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  // Real tab sets from the app, not invented ones.
  const statsTabs = ['OVERVIEW', 'SCORE', 'NUTRITION', 'PHOTOS', 'MOOD'];
  const nutritionTabs = ['DAILY', 'RECIPES', 'JOURNAL', 'PATTERNS'];

  group('ZealovaTextTabs — never overflows', () {
    for (final scale in const [1.0, 1.3, 2.0]) {
      testWidgets('stats tab set at ${scale}x on a 393pt phone',
          (tester) async {
        await tester.pumpWidget(
            _harness(tabs: statsTabs, width: 393, textScale: scale));
        await tester.pump();
        expect(tester.takeException(), isNull,
            reason: 'tabs overflowed at ${scale}x — this strip is on 14 '
                'screens, so it breaks all of them at once');
      });
    }

    testWidgets('nutrition tab set on a narrow 320pt phone at 2.0x',
        (tester) async {
      await tester.pumpWidget(
          _harness(tabs: nutritionTabs, width: 320, textScale: 2.0));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('an unusually long tab set does not overflow', (tester) async {
      await tester.pumpWidget(_harness(
        tabs: const ['MEASUREMENTS', 'COMPARISONS', 'MILESTONES', 'CHARTS'],
        width: 360,
      ));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('ZealovaTextTabs — labels stay whole and tappable', () {
    testWidgets('every label renders in FULL, never ellipsized',
        (tester) async {
      // The point of scrolling rather than ellipsizing: a tab truncated to
      // "MEASURE…" stops being a usable navigation control.
      await tester.pumpWidget(
          _harness(tabs: statsTabs, width: 320, textScale: 2.0));
      await tester.pump();
      for (final t in statsTabs) {
        expect(find.text(t), findsOneWidget, reason: '$t must remain readable');
      }
    });

    testWidgets('tapping a tab still reports its index', (tester) async {
      int? tapped;
      await tester.pumpWidget(_harness(
        tabs: nutritionTabs,
        width: 393,
        onChanged: (i) => tapped = i,
      ));
      await tester.pump();
      await tester.tap(find.text('RECIPES'));
      expect(tapped, 1, reason: 'wrapping in a scroll view must not break the '
          'tap target');
    });
  });
}
