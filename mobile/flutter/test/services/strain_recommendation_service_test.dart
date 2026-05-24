import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/services/strain_recommendation_service.dart';

/// Tests cover EVERY branch + every numeric boundary the algorithm depends on.
/// The algorithm is:
///   if priorTwoDaysHard >= 2:                                  rest
///   elif sleepScore < 60 || yesterdayStrainRatio >= 1.4:       light
///   elif sleepScore < 75 || yesterdayStrainRatio >= 1.1:       moderate
///   else:                                                       hard
///
/// Boundary inputs intentionally exercised: priorTwoDaysHardCount={1,2},
/// sleepScore={59,60,74,75,null}, yesterdayStrainRatio={1.09,1.1,1.39,1.4}.
void main() {
  group('chooseStrainRecommendation', () {
    test('rest tier when priorTwoDaysHard == 2 (forces rest regardless of other inputs)', () {
      final r = chooseStrainRecommendation(
        sleepScore: 95,
        yesterdayStrainRatio: 0.0,
        priorTwoDaysHardCount: 2,
      );
      expect(r.tier, StrainTier.rest);
      expect(r.rationale, contains('Two hard days'));
    });

    test('rest still wins when priorTwoDaysHard == 3 (capped logic boundary)', () {
      final r = chooseStrainRecommendation(
        sleepScore: 80,
        yesterdayStrainRatio: 0.5,
        priorTwoDaysHardCount: 3,
      );
      expect(r.tier, StrainTier.rest);
    });

    test('priorTwoDaysHard == 1 does NOT force rest', () {
      // priorTwoDaysHard < 2 falls through to the sleep/strain branches.
      final r = chooseStrainRecommendation(
        sleepScore: 80,
        yesterdayStrainRatio: 0.5,
        priorTwoDaysHardCount: 1,
      );
      expect(r.tier, StrainTier.hard);
    });

    test('light tier when sleepScore == 59 (just under the 60 boundary)', () {
      final r = chooseStrainRecommendation(
        sleepScore: 59,
        yesterdayStrainRatio: 0.0,
        priorTwoDaysHardCount: 0,
      );
      expect(r.tier, StrainTier.light);
      expect(r.rationale, contains('59'));
    });

    test('moderate at sleepScore == 60 (boundary — NOT light)', () {
      // 60 is the moderate floor, NOT the light ceiling.
      final r = chooseStrainRecommendation(
        sleepScore: 60,
        yesterdayStrainRatio: 0.0,
        priorTwoDaysHardCount: 0,
      );
      expect(r.tier, StrainTier.moderate);
    });

    test('light tier when yesterdayStrainRatio == 1.4 (boundary)', () {
      final r = chooseStrainRecommendation(
        sleepScore: 90,
        yesterdayStrainRatio: 1.4,
        priorTwoDaysHardCount: 0,
      );
      expect(r.tier, StrainTier.light);
      expect(r.rationale, contains('heavy day'));
    });

    test('moderate (not light) when yesterdayStrainRatio == 1.39 (just under 1.4)', () {
      final r = chooseStrainRecommendation(
        sleepScore: 90,
        yesterdayStrainRatio: 1.39,
        priorTwoDaysHardCount: 0,
      );
      expect(r.tier, StrainTier.moderate);
    });

    test('moderate tier when sleepScore == 74 (just under the 75 boundary)', () {
      final r = chooseStrainRecommendation(
        sleepScore: 74,
        yesterdayStrainRatio: 0.0,
        priorTwoDaysHardCount: 0,
      );
      expect(r.tier, StrainTier.moderate);
      expect(r.rationale, contains('74'));
    });

    test('hard tier when sleepScore == 75 (boundary — green light starts here)', () {
      final r = chooseStrainRecommendation(
        sleepScore: 75,
        yesterdayStrainRatio: 0.0,
        priorTwoDaysHardCount: 0,
      );
      expect(r.tier, StrainTier.hard);
    });

    test('moderate tier when yesterdayStrainRatio == 1.1 (boundary)', () {
      final r = chooseStrainRecommendation(
        sleepScore: 90,
        yesterdayStrainRatio: 1.1,
        priorTwoDaysHardCount: 0,
      );
      expect(r.tier, StrainTier.moderate);
      expect(r.rationale, contains('moderate'));
    });

    test('hard tier when yesterdayStrainRatio == 1.09 (just under 1.1)', () {
      final r = chooseStrainRecommendation(
        sleepScore: 90,
        yesterdayStrainRatio: 1.09,
        priorTwoDaysHardCount: 0,
      );
      expect(r.tier, StrainTier.hard);
    });

    test('null sleepScore is treated as 70 (falls in moderate band)', () {
      // 70 < 75 so moderate is correct. This proves the documented null-defaulting.
      final r = chooseStrainRecommendation(
        sleepScore: null,
        yesterdayStrainRatio: 0.0,
        priorTwoDaysHardCount: 0,
      );
      expect(r.tier, StrainTier.moderate);
    });

    test('sleep-driven light takes precedence over strain in rationale wording', () {
      // Both signals fire at the light tier — verify the rationale references
      // the sleep signal (which is checked first in the OR).
      final r = chooseStrainRecommendation(
        sleepScore: 45,
        yesterdayStrainRatio: 1.6,
        priorTwoDaysHardCount: 0,
      );
      expect(r.tier, StrainTier.light);
      expect(r.rationale, contains('45'));
    });

    test('green-light hard: great sleep, no overload, no prior hard days', () {
      final r = chooseStrainRecommendation(
        sleepScore: 88,
        yesterdayStrainRatio: 0.8,
        priorTwoDaysHardCount: 0,
      );
      expect(r.tier, StrainTier.hard);
      expect(r.rationale, contains('green light'));
    });
  });
}
