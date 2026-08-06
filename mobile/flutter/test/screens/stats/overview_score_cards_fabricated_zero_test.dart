// REGRESSION GATE — E2E 2026-08-05, stats lane finding row 1 (CRIT).
//
// The Stats Overview tab and the Score tab's Fitness Score card rendered
// hard 0s with confident labels ("0 BEGINNER", "OVERALL FITNESS 0 BEGINNER",
// "SAME AS LAST WEEK") for an account with ZERO rows in strength_scores,
// fitness_scores and nutrition_scores — i.e. "never calculated" was rendered
// identically to "calculated a real zero".
//
// Root cause: several ScoresOverview / FitnessScoreResponse fields the
// backend legitimately CANNOT make nullable without a breaking API change
// (`overall_strength_score`, `overall_strength_level` are non-nullable and
// default to 0/"beginner" when unscored) were read directly instead of via
// an honest signal already present in the same payload
// (`muscle_scores_summary` is only populated from real rows; `calculated_date`
// is only set on a real computed fitness score).
//
// These tests pin that an unscored-but-loaded overview renders "—" / "NOT
// SCORED YET", never a fabricated 0/Beginner.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/data/models/scores.dart';
import 'package:fitwiz/data/providers/scores_provider.dart';
import 'package:fitwiz/data/repositories/scores_repository.dart';
import 'package:fitwiz/screens/stats/widgets/overview/strength_score_card.dart';
import 'package:fitwiz/screens/stats/widgets/overview/weekly_score_card.dart';
import 'package:fitwiz/screens/stats/widgets/overview/fitness_score_breakdown_section.dart';

class _UnusedRepository implements ScoresRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FixedScoresNotifier extends ScoresNotifier {
  _FixedScoresNotifier(ScoresState initial)
      : super(_UnusedRepository()) {
    state = initial;
  }
}

/// The overview payload for an account that has NEVER been scored: the
/// backend's non-nullable strength fields default to 0/"beginner", the
/// genuinely-nullable fitness/nutrition/consistency fields are null, and
/// `muscle_scores_summary` — the only honest "ever scored" signal for
/// strength — is empty.
ScoresOverview _neverScoredOverview() => const ScoresOverview(
      userId: 'u1',
      hasCheckedInToday: false,
      overallStrengthScore: 0,
      overallStrengthLevel: 'beginner',
      muscleScoresSummary: {},
      prCount30Days: 0,
      nutritionScore: null,
      consistencyScore: null,
      overallFitnessScore: null,
      fitnessLevel: null,
    );

Future<void> _pump(WidgetTester tester, Widget card, ScoresState state) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        scoresProvider.overrideWith((ref) => _FixedScoresNotifier(state)),
      ],
      child: MaterialApp(home: Scaffold(body: card)),
    ),
  );
  await tester.pump();
}

void main() {
  group('StrengthScoreCard', () {
    testWidgets('never-scored overview renders "—" / NOT SCORED YET, not 0/BEGINNER',
        (tester) async {
      await _pump(
        tester,
        const StrengthScoreCard(),
        ScoresState(overview: _neverScoredOverview()),
      );

      expect(find.text('0'), findsNothing,
          reason: 'must not show the backend\'s fabricated overall_strength_score=0');
      expect(find.text('BEGINNER'), findsNothing,
          reason: 'must not show the backend\'s fabricated overall_strength_level');
      expect(find.text('—'), findsOneWidget);
      expect(find.text('NOT SCORED YET'), findsOneWidget);
    });

    testWidgets('a real muscle score renders the actual score', (tester) async {
      final overview = ScoresOverview(
        userId: 'u1',
        hasCheckedInToday: false,
        overallStrengthScore: 62,
        overallStrengthLevel: 'intermediate',
        muscleScoresSummary: const {'chest': 62},
        prCount30Days: 0,
      );
      await _pump(
        tester,
        const StrengthScoreCard(),
        ScoresState(overview: overview),
      );

      expect(find.text('62'), findsOneWidget);
      expect(find.text('INTERMEDIATE'), findsOneWidget);
      expect(find.text('NOT SCORED YET'), findsNothing);
    });
  });

  group('WeeklyScoreCard', () {
    testWidgets('no fitness score anywhere renders an honest empty state, not "0"',
        (tester) async {
      await _pump(
        tester,
        const WeeklyScoreCard(),
        ScoresState(overview: _neverScoredOverview()),
      );

      expect(find.text('0'), findsNothing,
          reason: 'must not render "0 WEEK OVER WEEK" for an account that has '
              'never had a fitness score calculated');
      expect(find.text('—'), findsOneWidget);
      expect(find.text('NOT SCORED YET'), findsOneWidget);
    });
  });

  group('FitnessScoreBreakdownSection', () {
    testWidgets(
        'never-scored overview renders "NOT SCORED YET", never "0 BEGINNER"',
        (tester) async {
      await _pump(
        tester,
        const FitnessScoreBreakdownSection(),
        ScoresState(overview: _neverScoredOverview()),
      );

      expect(find.text('0'), findsNothing,
          reason: 'the hero + all four component tiles must not show a '
              'fabricated 0');
      expect(find.text('BEGINNER'), findsNothing);
      expect(find.text('NOT SCORED YET'), findsOneWidget);
      // Four component tiles, each an honest "—".
      expect(find.text('—'), findsWidgets);
    });
  });
}
