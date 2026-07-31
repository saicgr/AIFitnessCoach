// E2E register #134 — the timer block is visually broken ("seconds" sliced
// in half).
//
// `Stack` gives its non-positioned children LOOSE (not bounded)
// constraints and sizes ITSELF to the union of their natural sizes. The
// countdown Column (Text 48pt + Text 14pt) was a THIRD non-positioned
// sibling of the two 140×140 ring `SizedBox`es with nothing bounding its
// own size — so at a large textScaler it grew past 140px, and because
// Stack sizes to the union of ALL non-positioned children (not just the
// smallest), the whole ring+Stack grew with it, blowing out whatever
// fixed-height budget the timer sits in higher up the tree (that's where
// the reported clipping actually surfaced). A bare `FittedBox` alone does
// NOT fix this — with nothing bounding IT either, it has no target box to
// scale into and passes the natural (unbounded) size straight through;
// verified empirically (see commit) that a bare FittedBox produced the
// IDENTICAL overflow as no fix at all. The real fix is
// `SizedBox(140, 140) > FittedBox(scaleDown) > Column` — the SizedBox gives
// FittedBox an actual target matching the two ring circles.
//
// This test wraps the timer in a height budget (450px) sized to comfortably
// fit the FIXED widget at a large textScaler but too small for the
// unfixed one (empirically: unfixed overflows by 125px in this exact
// harness at textScale 3.5; fixed has zero overflow) and asserts no
// RenderFlex overflow exception.
//
// Negative-tested: reverting to a bare (unbounded) Column — no SizedBox, no
// FittedBox — reproduces the 125px overflow and fails this test.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/core/providers/locale_provider.dart' show supportedAppLocales;
import 'package:fitwiz/l10n/generated/app_localizations.dart';
import 'package:fitwiz/screens/workout/widgets/timed_exercise_timer.dart';

void main() {
  Widget buildTimer({required double textScale, required double boxHeight}) {
    // MediaQuery must wrap INSIDE MaterialApp's `builder` — MaterialApp
    // resolves its own ambient MediaQuery from the test `View`, which
    // overrides one supplied as an ANCESTOR of MaterialApp instead.
    return MaterialApp(
      theme: ThemeData.dark(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: supportedAppLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: SizedBox(
          height: boxHeight,
          child: const TimedExerciseTimer(
            durationSeconds: 45,
            exerciseName: 'Plank',
            setNumber: 1,
            totalSets: 3,
          ),
        ),
      ),
    );
  }

  testWidgets(
      '#134 the ring stays 140×140 and never overflows its host at a large textScaler',
      (tester) async {
    await tester.pumpWidget(buildTimer(textScale: 3.5, boxHeight: 450));
    await tester.pump();

    expect(tester.takeException(), isNull);

    final ringRect = tester.getRect(find.byType(Stack).first);
    expect(ringRect.height, closeTo(140, 0.5),
        reason:
            'the ring must stay bounded to its two 140×140 circles, not '
            'inflate to fit the countdown text');
    expect(find.textContaining('45'), findsOneWidget);
    expect(find.text('seconds'), findsOneWidget);
  });

  testWidgets('#134 timer ring renders normally at default text scale',
      (tester) async {
    await tester.pumpWidget(buildTimer(textScale: 1.0, boxHeight: 450));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('45'), findsOneWidget);
    expect(find.text('seconds'), findsOneWidget);
  });
}
