/// Strain Coach — deterministic intensity recommendation.
///
/// Pure function (no Riverpod, no I/O, no clock). Inputs come from existing
/// providers in the call-site widget; this file only encodes the decision
/// tree per the §12 plan so it can be unit-tested without a widget tree.
///
/// Algorithm (top-down, first match wins) — matches `okay-can-you-make-zany-papert.md` §12:
///
/// ```
/// if priorTwoDaysHard >= 2:                                  rest
/// elif sleepScore < 60 || yesterdayStrainRatio >= 1.4:       light
/// elif sleepScore < 75 || yesterdayStrainRatio >= 1.1:       moderate
/// else:                                                       hard
/// ```
///
/// `sleepScore == null` is treated as 70 (an "average" night) — the same
/// neutral default the plan calls out. Returning a recommendation is always
/// possible; the surface UI never has to guess.
library;

/// Today's recommended training intensity.
enum StrainTier {
  /// Body has accumulated enough load that a true rest day is the right call.
  rest,

  /// Move, but keep it low impact (walk, mobility, easy Z2 cardio).
  light,

  /// Standard session — keep effort honest but no PR attempts.
  moderate,

  /// Green light for hard work, including PR attempts.
  hard,
}

/// Outcome of the strain recommender — a [tier] plus the one-line [rationale]
/// the card surfaces directly to the user.
class StrainRecommendation {
  final StrainTier tier;

  /// Single sentence (≤ ~80 chars) explaining WHY this tier was chosen. The
  /// card renders this verbatim — it MUST be human-readable and reference the
  /// concrete signal that drove the call (sleep score, prior hard days, etc.).
  final String rationale;

  const StrainRecommendation({
    required this.tier,
    required this.rationale,
  });
}

/// Compute today's strain recommendation.
///
/// * [sleepScore] — last night's [SleepScore.total] (0-100). Null is allowed
///   and treated as 70 (the same "average night" default the plan specifies).
/// * [yesterdayStrainRatio] — yesterday's training volume divided by the
///   user's 30-day median volume. 0.0 means "no workout yesterday"; 1.0 means
///   "exactly the typical session"; 1.4 means "40% above typical".
/// * [priorTwoDaysHardCount] — count of the last 2 days with strain ratio
///   `>= 1.2`. 2 = body has been hammered, force rest.
StrainRecommendation chooseStrainRecommendation({
  required int? sleepScore,
  required double yesterdayStrainRatio,
  required int priorTwoDaysHardCount,
}) {
  // Treat a missing sleep score as a neutral 70 — the same default the plan
  // documents. We do NOT fail-open with "hard" when sleep is unknown; that
  // would push intensity on the very users least likely to be tracking sleep.
  final s = sleepScore ?? 70;

  // 1. Two hard days back-to-back trumps everything else. The body needs a
  //    full rest day before we even look at sleep.
  if (priorTwoDaysHardCount >= 2) {
    return const StrainRecommendation(
      tier: StrainTier.rest,
      rationale: 'Two hard days in a row — take today off.',
    );
  }

  // 2. Either poor sleep (<60) OR a clear overreach yesterday (>=1.4x median)
  //    drops us to light. Use the LEADING signal in the rationale so the user
  //    knows which one the system saw.
  if (s < 60 || yesterdayStrainRatio >= 1.4) {
    if (s < 60) {
      return StrainRecommendation(
        tier: StrainTier.light,
        rationale: 'Sleep was $s — keep it light today.',
      );
    }
    return const StrainRecommendation(
      tier: StrainTier.light,
      rationale: 'Yesterday was a heavy day — keep it light.',
    );
  }

  // 3. Middling sleep (60-74) OR a slightly above-baseline yesterday (>=1.1x)
  //    pushes us to moderate — still train, just don't PR.
  if (s < 75 || yesterdayStrainRatio >= 1.1) {
    if (s < 75) {
      return StrainRecommendation(
        tier: StrainTier.moderate,
        rationale: 'Sleep was $s — moderate effort today.',
      );
    }
    return const StrainRecommendation(
      tier: StrainTier.moderate,
      rationale: 'Yesterday added load — moderate effort today.',
    );
  }

  // 4. Default green-light — sleep is good and yesterday wasn't excessive.
  return const StrainRecommendation(
    tier: StrainTier.hard,
    rationale: 'Recovered and ready — green light for hard work.',
  );
}
