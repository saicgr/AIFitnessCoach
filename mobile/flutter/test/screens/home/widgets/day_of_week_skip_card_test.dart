/// Regression test for Home → PLAN & ADJUSTMENTS → "Wednesdays keep getting
/// skipped" (E2E row 51, HIGH).
///
/// Home told the user "You've missed your Wednesday workout 2 weeks in a
/// row" on a Wednesday he had ALREADY completed that day, with only one
/// missed Wednesday in the account's entire history. `weeksSkipped` is not a
/// verified consecutive-week count — it's `(missRate × weeksObserved).round()`,
/// a rounded rate that can (as it did here, from a duplicate same-day workout
/// row) even exceed its own `weeksObserved` denominator. The fix drops the
/// "in a row" consecutiveness claim in favour of an honest "N of your last M
/// weeks" frequency framing, and clamps the count so it can never exceed the
/// window it was computed over.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/data/providers/home_pattern_providers.dart';
import 'package:fitwiz/screens/home/widgets/cards/day_of_week_skip_card.dart';

Widget _wrap(DayOfWeekSkipData data) {
  return ProviderScope(
    overrides: [
      dayOfWeekSkipProvider.overrideWith((ref) async => data),
    ],
    child: const MaterialApp(home: Scaffold(body: DayOfWeekSkipCard())),
  );
}

void main() {
  testWidgets(
      'never claims "N weeks in a row" — frames the same number as a '
      'historical frequency instead', (tester) async {
    await tester.pumpWidget(_wrap(const DayOfWeekSkipData(
      weekday: 3,
      weekdayName: 'Wednesday',
      missRate: 0.5,
      weeksObserved: 4,
    )));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('in a row'), findsNothing,
        reason: 'weeksSkipped is a rounded rate, not a verified consecutive '
            'count — E2E row 51 caught this claiming "2 weeks in a row" for '
            'an account with exactly one missed Wednesday ever');
    expect(
      find.textContaining(
          "You've missed your Wednesday workout on 2 of your last 4 weeks."),
      findsOneWidget,
      reason: 'must render the honest frequency framing of the same number',
    );
  });

  testWidgets(
      'clamps weeksSkipped to weeksObserved — a duplicate same-day miss row '
      'must never read as "N of the last M weeks" with N > M',
      (tester) async {
    // missRate=2.0 × weeksObserved=1 → naive round() = 2, which must be
    // clamped down to 1 (its own denominator) rather than rendered as
    // nonsense.
    await tester.pumpWidget(_wrap(const DayOfWeekSkipData(
      weekday: 3,
      weekdayName: 'Wednesday',
      missRate: 2.0,
      weeksObserved: 1,
    )));
    await tester.pump();
    await tester.pump();

    // weeksSkipped clamped to 1 means the `>= 2` gate in both render sites
    // hides the card entirely for this single-week account — asserting that
    // is itself proof the clamp landed (an unclamped "2" would render).
    expect(find.textContaining('of your last 1 weeks'), findsNothing);
    expect(find.text('Wednesdays keep getting skipped'), findsNothing,
        reason: 'a 1-week-observed account must never show "2 of the last '
            '1 weeks" — the clamp must keep the count <= weeksObserved');
  });
}
