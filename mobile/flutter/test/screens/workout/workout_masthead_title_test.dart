// Regression gate for E2E #165(d) — and, just as importantly, for E2E #123,
// which the fix for #165(d) must not reintroduce.
//
// The two pull in opposite directions:
//   #123: long curated names ("Active Recovery & Mobility Day") ellipsized to
//         "Active Rec…" at maxLines:2. Fixed by allowing a 3rd line.
//   #165: "UPPER BODY STRENGTH FOUNDATION" then set THREE 32pt lines and ate
//         roughly a fifth of the screen before any content.
//
// Capping lines re-breaks #123; allowing 3 lines re-breaks #165. The size is
// what gives: WorkoutMastheadTitle measures with a real TextPainter at its
// actual width and steps 32 → 22pt only as far as it must to fit two lines.
//
// These tests assert the RENDERED font size and the absence of overflow, not
// that some helper returns a number — the bug was always about what the screen
// actually did.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/screens/workout/workout_detail_screen.dart';

/// Pump the title at a realistic masthead width and return the size it chose.
Future<double> _renderedSize(
  WidgetTester tester,
  String text, {
  double width = 330, // iPhone 16e content width, minus the screen's padding
  TextScaler scaler = TextScaler.noScaling,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(textScaler: scaler),
        child: Scaffold(
          body: SizedBox(
            width: width,
            child: WorkoutMastheadTitle(text: text, color: Colors.white),
          ),
        ),
      ),
    ),
  );
  final widget = tester.widget<Text>(find.byType(Text));
  return widget.style!.fontSize!;
}

void main() {
  testWidgets('a short name keeps the full 32pt masthead', (tester) async {
    // Nothing should change for the common case — this is the look the
    // masthead was designed around.
    expect(await _renderedSize(tester, 'LEG DAY'), 32);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the name from the bug report no longer needs a third line',
      (tester) async {
    const reported = 'UPPER BODY STRENGTH FOUNDATION';
    final size = await _renderedSize(tester, reported);

    expect(size, lessThan(32),
        reason: 'it must step down rather than spill onto a 3rd line');
    expect(size, greaterThanOrEqualTo(22),
        reason: 'and must not shrink past the floor into illegibility');

    final rendered = tester.widget<Text>(find.byType(Text));
    expect(rendered.maxLines, 2);
    expect(tester.takeException(), isNull,
        reason: 'no overflow at the chosen size');
  });

  testWidgets('E2E #123 stays fixed — the long curated name is not truncated',
      (tester) async {
    // The exact name that regressed in #123. At its chosen size it must fit
    // two lines outright, which is what makes the ellipsis unreachable.
    const curated = 'ACTIVE RECOVERY & MOBILITY DAY';
    final size = await _renderedSize(tester, curated);

    final painter = TextPainter(
      text: TextSpan(
        text: curated,
        style: tester.widget<Text>(find.byType(Text)).style,
      ),
      maxLines: 2,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 330);

    expect(painter.didExceedMaxLines, isFalse,
        reason: 'the chosen size must actually fit — otherwise it ellipsizes, '
            'which is exactly the #123 defect');
    expect(size, greaterThanOrEqualTo(22));
  });

  testWidgets('it holds up at large text scale', (tester) async {
    // Text scale is a user setting and unknowable at build time — the same
    // blind spot that produced the #23 overflow.
    await _renderedSize(
      tester,
      'UPPER BODY STRENGTH FOUNDATION',
      scaler: const TextScaler.linear(1.6),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a pathological name degrades to an ellipsis, never a spill',
      (tester) async {
    final size = await _renderedSize(
      tester,
      'SUPERCALIFRAGILISTIC UPPER POSTERIOR CHAIN HYPERTROPHY AND '
      'CONDITIONING FOUNDATION PHASE TWO',
    );
    expect(size, 22, reason: 'floors out rather than shrinking without limit');
    final rendered = tester.widget<Text>(find.byType(Text));
    expect(rendered.maxLines, 2);
    expect(rendered.overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull);
  });
}
