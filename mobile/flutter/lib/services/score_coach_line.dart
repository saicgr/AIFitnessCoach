/// The Today Score coach nudge — deterministic, variant-pooled.
///
/// Picks the single highest-leverage unfinished contributor and phrases it
/// from a pool of ≥8 wordings, so the line reads human and varies day to day.
/// Fully deterministic (stable within a given day — no LLM, no randomness).
///
/// Used by:
///  * The legacy footer in `TodayScoreCard` (single-line)
///  * The new `CoachHeroCard` (headline + body split) — fallback when the
///    backend Gemini insight endpoint is unreachable or cost-capped.
///
/// Rules:
///  * No em dashes ('—') or en dashes ('–') — use commas / periods.
///  * No scare quotes around ordinary words.
///  * First-name + next-workout-name substitution available in headline/body
///    via {name} and {workout} tokens. Both default to friendly fallbacks
///    when null.
library;

import '../data/models/today_score.dart';

/// A one-line coach nudge for [score], or null when there's nothing to say
/// (setup state). Used by the legacy score-card footer.
String? coachLineFor(TodayScore score, {DateTime? now}) {
  final body = coachBody(score, now: now);
  return body;
}

/// Headline (1 short sentence, ≤8 words) for the coach hero card.
String? coachHeadline(
  TodayScore score, {
  String? firstName,
  String? workoutName,
  DateTime? now,
}) {
  if (score.isSetupState) return null;
  final ctx = _leverageContext(score, now: now);
  if (ctx == null) {
    return _allDoneHeadlines[_dailyIndex(_allDoneHeadlines.length, now)]
        .replaceAll('{name}', _safeName(firstName));
  }
  final pool = _headlinePoolFor(ctx.kind);
  final template = pool[_dailyIndex(pool.length, now)];
  return _interpolate(template,
      name: firstName, workout: workoutName, reach: ctx.reach, kind: ctx.kind);
}

/// Body (1-2 sentences) for the coach hero card.
String? coachBody(
  TodayScore score, {
  String? firstName,
  String? workoutName,
  DateTime? now,
}) {
  if (score.isSetupState) return null;
  final ctx = _leverageContext(score, now: now);
  if (ctx == null) {
    return _allDoneBodies[_dailyIndex(_allDoneBodies.length, now)];
  }
  final pool = _bodyPoolFor(ctx.kind);
  final template = pool[_dailyIndex(pool.length, now)];
  return _interpolate(template,
      name: firstName, workout: workoutName, reach: ctx.reach, kind: ctx.kind);
}

// ──────────────────────────────────────────────────────────────────────
//  Leverage picker — which contributor will move the score most?
// ──────────────────────────────────────────────────────────────────────

class _LeverageContext {
  final ContributorKind kind;
  final int reach;
  _LeverageContext(this.kind, this.reach);
}

_LeverageContext? _leverageContext(TodayScore score, {DateTime? now}) {
  ScoreContributor? best;
  double bestGain = 0;
  for (final c in score.applicableContributors) {
    final gain = c.effectiveWeight * (1.0 - c.completion) * 100.0;
    if (gain > bestGain) {
      bestGain = gain;
      best = c;
    }
  }
  if (best == null || bestGain < 1.0) return null;
  final reach = (score.score + bestGain).round().clamp(0, 100);
  return _LeverageContext(best.kind, reach);
}

/// Stable per-day index into a pool of [n] — varies across days, constant
/// within a day.
int _dailyIndex(int n, DateTime? now) {
  final d = now ?? DateTime.now();
  final seed = d.year * 366 + d.month * 31 + d.day;
  return seed % n;
}

String _safeName(String? name) {
  final trimmed = name?.trim();
  return (trimmed == null || trimmed.isEmpty) ? 'You' : trimmed;
}

String _safeWorkout(String? workout) {
  final trimmed = workout?.trim();
  return (trimmed == null || trimmed.isEmpty) ? "today's workout" : trimmed;
}

String _interpolate(
  String template, {
  String? name,
  String? workout,
  required int reach,
  required ContributorKind kind,
}) {
  return template
      .replaceAll('{name}', _safeName(name))
      .replaceAll('{workout}', _safeWorkout(workout))
      .replaceAll('{label}', kind.label)
      .replaceAll('{reach}', '$reach');
}

// ──────────────────────────────────────────────────────────────────────
//  Pools — headline (short) + body (1-2 sentences) per pillar.
//  ≥8 entries each, never em/en dashes, never scare quotes.
// ──────────────────────────────────────────────────────────────────────

List<String> _headlinePoolFor(ContributorKind kind) {
  switch (kind) {
    case ContributorKind.train:
      return _trainHeadlines;
    case ContributorKind.fuel:
      return _nourishHeadlines;
    case ContributorKind.move:
      return _moveHeadlines;
    case ContributorKind.sleep:
      return _sleepHeadlines;
  }
}

List<String> _bodyPoolFor(ContributorKind kind) {
  switch (kind) {
    case ContributorKind.train:
      return _trainBodies;
    case ContributorKind.fuel:
      return _nourishBodies;
    case ContributorKind.move:
      return _moveBodies;
    case ContributorKind.sleep:
      return _sleepBodies;
  }
}

// ── Train ─────────────────────────────────────────────────────────────

const List<String> _trainHeadlines = [
  '{name}, training is today\'s wedge.',
  '{name}, the workout is your big lever.',
  'Today rises with training, {name}.',
  '{name}, your plan is waiting.',
  '{name}, one session unlocks {reach}.',
  'Train is where the points are.',
  '{name}, lift first, the rest follows.',
  'Score climbs fast with training.',
];

const List<String> _trainBodies = [
  'Knock out {workout} and your score reaches {reach}.',
  'Finish {workout} and you are at {reach}. Everything else is incremental from there.',
  'Your plan calls for {workout}. Completing it puts the day at {reach}.',
  'One session, {workout}, gets you to {reach}.',
  'Train is the heaviest pillar on your card. Hit {workout} to climb to {reach}.',
  'Start {workout} when you can. Completion alone lifts you to {reach}.',
  'Even half of {workout} moves the needle. Full completion lands {reach}.',
  'The score is built around your training. Do {workout} to reach {reach}.',
];

// ── Nourish ───────────────────────────────────────────────────────────

const List<String> _nourishHeadlines = [
  '{name}, fuel is the move right now.',
  '{name}, your protein is lagging.',
  'Eat your way to {reach}, {name}.',
  '{name}, food logging is the gap.',
  'Close the Nourish gap, {name}.',
  '{name}, the kitchen is your next stop.',
  'Hit your macros to land {reach}.',
  '{name}, a meal away from {reach}.',
];

const List<String> _nourishBodies = [
  'Log the rest of your food to climb to {reach}.',
  'You are short on protein. Hit the target to reach {reach}.',
  'A solid meal closes the Nourish ring and lands you at {reach}.',
  'Your calorie target is partly logged. Finish the day to reach {reach}.',
  'Protein is the lever right now. Hitting your goal moves the day to {reach}.',
  'Log your remaining meals and the score lifts to {reach}.',
  'You have macros left on the table. Close the gap to reach {reach}.',
  'A balanced meal here clears the Nourish gap and gets you to {reach}.',
];

// ── Move ──────────────────────────────────────────────────────────────

const List<String> _moveHeadlines = [
  '{name}, a walk closes Move.',
  '{name}, steps are the easiest win.',
  'Move is almost there, {name}.',
  '{name}, get outside for {reach}.',
  'Close the Move ring, {name}.',
  '{name}, a few thousand steps left.',
  'Steps unlock {reach} for you.',
  '{name}, your feet do the work.',
];

const List<String> _moveBodies = [
  'A short walk gets your score to {reach}.',
  'You are close to your step goal. Finishing it puts the day at {reach}.',
  'Move is your fastest open ring today. A 20 minute walk lands {reach}.',
  'Steps are the cheapest points on the card. Hit the goal to reach {reach}.',
  'A loop around the block usually does it. Closing Move gets you to {reach}.',
  'Step goal is in reach. Closing it brings the score to {reach}.',
  'Move counts every step, even slow ones. Hit goal to land {reach}.',
  'A walk after your next break closes the ring and reaches {reach}.',
];

// ── Sleep ─────────────────────────────────────────────────────────────

const List<String> _sleepHeadlines = [
  '{name}, last night was short.',
  '{name}, sleep is dragging your score.',
  'Build tonight back in, {name}.',
  '{name}, rest is on the card now.',
  'Sleep counts here, {name}.',
  '{name}, an earlier bedtime helps.',
  'Wind down by ten, land {reach}.',
  '{name}, recovery is the lever tonight.',
];

const List<String> _sleepBodies = [
  'Last night came in short. An earlier wind down tonight protects tomorrow\'s score.',
  'Sleep is a contributor now. A solid night lifts you toward {reach} tomorrow.',
  'Recovery shows up on the card. Aim for your goal tonight to bank {reach}.',
  'Bed by ten gives you a better starting line tomorrow.',
  'Your sleep score is below your usual. Tonight is a chance to reset.',
  'A full goal-length night tonight resets the trend.',
  'The Sleep ring rewards consistency. Match your usual bedtime to land {reach}.',
  'Wind down 30 minutes earlier. Tomorrow\'s score starts with tonight.',
];

// ── All-done state ────────────────────────────────────────────────────

const List<String> _allDoneHeadlines = [
  'Clean day, {name}.',
  '{name}, every ring closed.',
  '{name}, full marks today.',
  'Day is locked in, {name}.',
  '{name}, plan complete.',
  'Top to bottom, {name}.',
  'Card cleared, {name}.',
  'You did the work, {name}.',
];

const List<String> _allDoneBodies = [
  'Every ring closed. Rest easy.',
  'Today\'s plan is done, top to bottom.',
  'Full marks. Nothing left on the board.',
  'Nailed every pillar. Sleep well.',
  'Clean execution across the board.',
  'All four contributors at goal.',
  'Day complete. Tomorrow\'s your reset.',
  'You did everything the plan asked for.',
];
