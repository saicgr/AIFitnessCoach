// E2E register #132(c) — the Evening Recap card invoked the "Move ring"
// while Home still showed the "Connect Health to see steps, sleep &
// readiness" banner, referencing a ring that cannot exist for that account.
//
// The client-side mirror of that copy pool is `_moveHeadlines`/`_moveBodies`
// in lib/services/score_coach_line.dart. This test proves the client-side
// gate is already sound: the ONLY place those pools are reached is
// `_leverageContext`, which selects a pillar exclusively from
// `TodayScore.applicableContributors` — and `ContributorKind.move` is only
// ever `applicable` when Health Connect / HealthKit is linked
// (`moveApplicable = i.healthConnected` in
// lib/services/today_score_service.dart:132, NOT owned by this file, but the
// invariant it produces — an inapplicable move contributor never appears in
// `applicableContributors` — is what this file's picker relies on).
//
// So: "no connected health source ⇒ never select a move-pillar line" is
// already the implemented rule for `CoachHeroSurface.home`, reconciling with
// whatever the backend agent's server-side gate turns out to be for
// `daily_insight.py`'s Gemini-authored evening-recap prose (a separate,
// server-owned surface this file does not produce for eveningRecap/
// morningBrief — see the second group below).
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/data/models/today_score.dart';
import 'package:fitwiz/services/score_coach_line.dart';

/// Literal fixed portions of every `_moveHeadlines` / `_moveBodies` template
/// in lib/services/score_coach_line.dart (name/workout placeholders
/// stripped). `_moveHeadlines`/`_moveBodies` are library-private, so this
/// test can't import them directly — these are copied verbatim from the
/// source as the ground truth for "did the Move pillar's copy leak". A bare
/// `contains('Move')` is too broad: other pools use "Move" as an ordinary
/// verb ("Move first, then desk.") with no pillar meaning, which is NOT the
/// register #132(c) bug.
const List<String> _movePillarMarkers = [
  'a walk closes Move.',
  'steps are the easiest win.',
  'Move is almost there,',
  'get outside for the easy win.',
  'Close the Move ring,',
  'a few thousand steps left.',
  'Steps are your easiest ring to close.',
  'your feet do the work.',
  'A short walk closes your Move ring for the day.',
  'You are close to your step goal. Finishing it closes Move.',
  'Move is your fastest open ring today. A 20 minute walk closes it.',
  'Steps are the easiest win on the card. Hit the goal to close Move.',
  'A loop around the block usually does it. That closes Move.',
  'Your step goal is within reach. Close it before the day winds down.',
  'Move counts every step, even slow ones. Hit your goal to close it.',
  'A walk after your next break closes the ring.',
];

bool _containsMovePillarCopy(String? text) {
  if (text == null) return false;
  return _movePillarMarkers.any(text.contains);
}

void main() {
  /// A score where Move has the LARGEST theoretical gain of any pillar
  /// (completion 0, a nonzero effectiveWeight as if a weight-zeroing bug
  /// leaked through) but is marked NOT applicable (no Health source) —
  /// exactly the "disconnected account" state from the register repro. Fuel
  /// has a real, smaller gap so a genuine non-move pick is still available.
  TodayScore buildScore({required bool moveApplicable}) {
    return TodayScore(
      score: 74,
      generatedAt: DateTime(2026, 7, 30, 12),
      isSetupState: false,
      contributors: [
        const ScoreContributor(
          kind: ContributorKind.train,
          applicable: true,
          completion: 1.0,
          effectiveWeight: 0.40,
          statusText: 'Workout complete',
        ),
        const ScoreContributor(
          kind: ContributorKind.fuel,
          applicable: true,
          completion: 0.9,
          effectiveWeight: 0.30,
          statusText: '20g protein to go',
        ),
        ScoreContributor(
          kind: ContributorKind.move,
          applicable: moveApplicable,
          completion: 0.0,
          // Deliberately nonzero even though inapplicable — proves the guard
          // is the `applicable` FILTER, not a downstream gain comparison
          // (this weight, if counted, would dwarf fuel's gain).
          effectiveWeight: 0.15,
          statusText: moveApplicable
              ? '4,200 steps to go'
              : 'Connect Health to count steps',
        ),
        const ScoreContributor(
          kind: ContributorKind.sleep,
          applicable: true,
          completion: 1.0,
          effectiveWeight: 0.15,
          statusText: 'Goal-length night',
        ),
      ],
    );
  }

  group('CoachHeroSurface.home — the only surface that can select the Move pool',
      () {
    test(
        'with Health disconnected (move inapplicable), no headline/body across '
        'a full year of day-indices or any time bucket ever mentions Move',
        () {
      final score = buildScore(moveApplicable: false);
      var checked = 0;
      for (var day = 1; day <= 366; day++) {
        for (final hour in [6, 9, 12, 15, 19, 21, 23]) {
          final now = DateTime(2026, 1, 1, hour).add(Duration(days: day - 1));
          final headline = coachHeadline(score,
              firstName: 'Sam', workoutName: 'Leg Day', now: now);
          final body = coachBody(score,
              firstName: 'Sam', workoutName: 'Leg Day', now: now);
          checked++;
          // NEGATIVE TEST target: reverting `_leverageContext`'s loop from
          // `score.applicableContributors` to plain `score.contributors`
          // makes this FAIL — move (gain 15) then beats fuel (gain 3) and
          // both headline/body render literal "Move" copy ("Close the Move
          // ring, Sam." / "...closes Move.") for a disconnected account.
          expect(_containsMovePillarCopy(headline), isFalse,
              reason: 'headline leaked Move-pillar copy for a disconnected '
                  'account: "$headline"');
          expect(_containsMovePillarCopy(body), isFalse,
              reason: 'body leaked Move-pillar copy for a disconnected '
                  'account: "$body"');
        }
      }
      expect(checked, greaterThan(2000)); // sanity: the sweep actually ran
    });

    test(
        'with Health connected (move applicable + largest gap), Move copy IS '
        'reachable — proves the above is a real gate, not a pool that never '
        'contains "Move" at all', () {
      final score = buildScore(moveApplicable: true);
      var sawMove = false;
      for (var day = 1; day <= 60; day++) {
        final now = DateTime(2026, 3, 1, 12).add(Duration(days: day - 1));
        final body = coachBody(score, firstName: 'Sam', now: now);
        if (_containsMovePillarCopy(body)) sawMove = true;
      }
      expect(sawMove, isTrue,
          reason: 'sanity check failed — Move copy should be reachable when '
              'Health is connected and Move has the largest gap; if this '
              'fails the gate above may be passing for the wrong reason '
              '(e.g. the Move pool is unreachable regardless of applicable)');
    });
  });

  group('CoachHeroSurface.eveningRecap / morningBrief — server-mirrored surfaces',
      () {
    // These surfaces bypass `_leverageContext` entirely (fixed, rotating
    // pools) and, as of this fix, contain no pillar-specific "Move" copy at
    // all — so they cannot leak it regardless of Health-connection state.
    // This is the CLIENT fallback only; the register repro's actual prose
    // was Gemini-authored server-side (daily_insight.py), which is the
    // backend agent's surface to gate.
    test('evening recap body never mentions Move, at any day index', () {
      final score = buildScore(moveApplicable: false);
      for (var day = 1; day <= 366; day++) {
        final now = DateTime(2026, 1, 1, 20).add(Duration(days: day - 1));
        final body = coachBody(score,
            firstName: 'Sam', now: now, surface: CoachHeroSurface.eveningRecap);
        expect(body, isNotNull);
        expect(_containsMovePillarCopy(body), isFalse,
            reason: 'evening recap fallback leaked Move copy: "$body"');
      }
    });

    test('morning brief body never mentions Move, at any day index', () {
      final score = buildScore(moveApplicable: false);
      for (var day = 1; day <= 366; day++) {
        final now = DateTime(2026, 1, 1, 8).add(Duration(days: day - 1));
        final body = coachBody(score,
            firstName: 'Sam', now: now, surface: CoachHeroSurface.morningBrief);
        expect(body, isNotNull);
        expect(_containsMovePillarCopy(body), isFalse,
            reason: 'morning brief fallback leaked Move copy: "$body"');
      }
    });
  });
}
