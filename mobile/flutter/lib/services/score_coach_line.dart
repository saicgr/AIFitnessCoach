/// The Today Score coach nudge — deterministic, variant-pooled.
///
/// Phase 5. Picks the single highest-leverage unfinished contributor and
/// phrases it from a pool of ≥4 wordings, so the line reads human and varies
/// day to day, but is fully deterministic (stable within a given day — no
/// LLM, no randomness).
library;

import '../data/models/today_score.dart';

/// A one-line coach nudge for [score], or null when there's nothing to say
/// (setup state).
String? coachLineFor(TodayScore score, {DateTime? now}) {
  if (score.isSetupState) return null;

  ScoreContributor? best;
  double bestGain = 0;
  for (final c in score.applicableContributors) {
    final gain = c.effectiveWeight * (1.0 - c.completion) * 100.0;
    if (gain > bestGain) {
      bestGain = gain;
      best = c;
    }
  }

  // Everything that applies is essentially done.
  if (best == null || bestGain < 1.0) {
    return _allDone[_dailyIndex(_allDone.length, now)];
  }

  final reach = (score.score + bestGain).round().clamp(0, 100);
  final pool = _poolFor(best.kind);
  final template = pool[_dailyIndex(pool.length, now)];
  return template
      .replaceAll('{label}', best.kind.label.toLowerCase())
      .replaceAll('{reach}', '$reach');
}

/// A stable per-day index into a pool of [n] — varies across days, constant
/// within a day.
int _dailyIndex(int n, DateTime? now) {
  final d = now ?? DateTime.now();
  final seed = d.year * 366 + d.month * 31 + d.day;
  return seed % n;
}

List<String> _poolFor(ContributorKind kind) {
  switch (kind) {
    case ContributorKind.train:
      return _trainPool;
    case ContributorKind.fuel:
      return _fuelPool;
    case ContributorKind.move:
      return _movePool;
  }
}

const List<String> _allDone = [
  "Every ring closed — that's a clean day.",
  "You've done it all today. Rest easy.",
  "Full marks. Nothing left on the board.",
  "Today's plan is done, top to bottom.",
];

const List<String> _trainPool = [
  "Knock out today's workout and your score reaches {reach}.",
  "The workout is your big lever — finish it for {reach}.",
  "Train is where the points are: do it and you're at {reach}.",
  "One session stands between you and {reach}.",
];

const List<String> _fuelPool = [
  "Hit your protein and your score climbs to {reach}.",
  "Fuel is the move right now — get there for {reach}.",
  "Log the rest of your food to reach {reach}.",
  "Close the {label} gap and you're at {reach}.",
];

const List<String> _movePool = [
  "A short walk gets your score to {reach}.",
  "Move is almost there — finish it for {reach}.",
  "Hit your step goal to reach {reach}.",
  "Close the {label} ring and you're at {reach}.",
];
