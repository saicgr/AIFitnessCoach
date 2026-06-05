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

/// Time-of-day bucket in the user's local time. Drives tone branching in the
/// deterministic fallback so the message reads differently morning vs evening
/// (matches the server-side Gemini path, which has full prompt branching).
enum CoachTimeBucket { morning, midday, afternoon, evening, late }

/// Plan P3e surface for the expanded coach hero pools. Picked by
/// `coachHeadline` / `coachBody` when [CoachHeroSurface.morningBrief] or
/// [CoachHeroSurface.eveningRecap] is passed so the deterministic fallback
/// can render a multi-line brief without an API call.
///
/// Edge cases:
///   * `morningBriefOnboarding` covers the <3-days-of-history degrade rule —
///     a fixed onboarding ask, no motivational fluff.
///   * `morningBrief` / `eveningRecap` produce bullet-formatted bodies
///     joined with `\n• ` so the card renders them as a real brief.
///   * Single-line surfaces (home / late) keep the existing pools.
enum CoachHeroSurface {
  /// Default — single-line behaviour (existing pools).
  home,
  /// Rich 3-5 line morning brief (5-10 AM bucket).
  morningBrief,
  /// Rich evening recap (8-10 PM bucket).
  eveningRecap,
  /// Low-history degrade — connect/setup ask.
  morningBriefOnboarding,
}

CoachTimeBucket _timeBucket(DateTime now) {
  final h = now.hour;
  if (h < 5) return CoachTimeBucket.late; // 0–4: still up / wee hours
  if (h < 11) return CoachTimeBucket.morning; // 5–10
  if (h < 14) return CoachTimeBucket.midday; // 11–13
  if (h < 18) return CoachTimeBucket.afternoon; // 14–17
  if (h < 22) return CoachTimeBucket.evening; // 18–21
  return CoachTimeBucket.late; // 22–23
}

/// Headline (1 short sentence, ≤8 words) for the coach hero card.
///
/// [surface] picks one of the rich-brief pools when the card is in
/// expanded mode. The body emitted by [coachBody] must be called with the
/// matching surface or the two will diverge.
String? coachHeadline(
  TodayScore score, {
  String? firstName,
  String? workoutName,
  DateTime? now,
  CoachHeroSurface surface = CoachHeroSurface.home,
}) {
  if (score.isSetupState && surface != CoachHeroSurface.morningBriefOnboarding) {
    // Brand-new / setup-state user on the home card: a warm welcome instead of
    // null (which degraded to "Your coach is gathering thoughts."). Mirrors the
    // backend's deterministic `new`-lifecycle welcome so the offline fallback
    // reads the same. Other surfaces keep returning null.
    if (surface == CoachHeroSurface.home) {
      return _welcomeHeadline(firstName, now ?? DateTime.now());
    }
    return null;
  }
  final t = now ?? DateTime.now();

  // Expanded-surface overlays — these win over the leverage / time pools so
  // morning_brief / evening_recap pairs read coherently (the same template
  // index drives both headline and body).
  if (surface == CoachHeroSurface.morningBrief) {
    final pool = _morningHeadlines;
    return _interpolate(pool[_dailyIndex(pool.length, t)],
        name: firstName,
        workout: workoutName,
        reach: score.score,
        kind: ContributorKind.train);
  }
  if (surface == CoachHeroSurface.eveningRecap) {
    final pool = _eveningRecapHeadlines;
    return _interpolate(pool[_dailyIndex(pool.length, t)],
        name: firstName,
        workout: workoutName,
        reach: score.score,
        kind: ContributorKind.sleep);
  }
  if (surface == CoachHeroSurface.morningBriefOnboarding) {
    final pool = _morningOnboardingHeadlines;
    return _interpolate(pool[_dailyIndex(pool.length, t)],
        name: firstName,
        workout: workoutName,
        reach: 0,
        kind: ContributorKind.train);
  }

  final ctx = _leverageContext(score, now: t);

  // Time-aware overlay — runs FIRST on the morning + late buckets where the
  // generic leverage-driven headline reads off-tone (e.g. "lift first" at
  // 11pm is silly). Mid-day / afternoon / evening fall through to the
  // existing leverage-driven pool.
  final bucket = _timeBucket(t);
  if (bucket == CoachTimeBucket.morning) {
    final pool = _morningHeadlines;
    final template = pool[_dailyIndex(pool.length, t)];
    return _interpolate(template,
        name: firstName,
        workout: workoutName,
        reach: ctx?.reach ?? score.score,
        kind: ctx?.kind ?? ContributorKind.train);
  }
  if (bucket == CoachTimeBucket.late) {
    final pool = _latePool;
    final template = pool[_dailyIndex(pool.length, t)];
    return _interpolate(template,
        name: firstName,
        workout: workoutName,
        reach: ctx?.reach ?? score.score,
        kind: ctx?.kind ?? ContributorKind.sleep);
  }

  if (ctx == null) {
    return _allDoneHeadlines[_dailyIndex(_allDoneHeadlines.length, t)]
        .replaceAll('{name}', _safeName(firstName));
  }
  final pool = _headlinePoolFor(ctx.kind);
  final template = pool[_dailyIndex(pool.length, t)];
  return _interpolate(template,
      name: firstName, workout: workoutName, reach: ctx.reach, kind: ctx.kind);
}

/// Body (1-2 sentences, or a multi-line brief) for the coach hero card.
///
/// When [surface] is morningBrief / eveningRecap / morningBriefOnboarding,
/// the returned string contains `\n` line breaks (and `• ` bullet prefixes
/// for bullet rows). The card widget splits on `\n` and renders bullets.
String? coachBody(
  TodayScore score, {
  String? firstName,
  String? workoutName,
  DateTime? now,
  CoachHeroSurface surface = CoachHeroSurface.home,
}) {
  if (score.isSetupState && surface != CoachHeroSurface.morningBriefOnboarding) {
    // Setup-state welcome body on home (pairs with _welcomeHeadline above).
    if (surface == CoachHeroSurface.home) {
      return _welcomeBody(now ?? DateTime.now());
    }
    return null;
  }
  final t = now ?? DateTime.now();

  if (surface == CoachHeroSurface.morningBrief) {
    final pool = _morningExpandedBodies;
    return _interpolate(pool[_dailyIndex(pool.length, t)],
        name: firstName,
        workout: workoutName,
        reach: score.score,
        kind: ContributorKind.train);
  }
  if (surface == CoachHeroSurface.eveningRecap) {
    final pool = _eveningRecapBodies;
    return _interpolate(pool[_dailyIndex(pool.length, t)],
        name: firstName,
        workout: workoutName,
        reach: score.score,
        kind: ContributorKind.sleep);
  }
  if (surface == CoachHeroSurface.morningBriefOnboarding) {
    final pool = _morningOnboardingBodies;
    return _interpolate(pool[_dailyIndex(pool.length, t)],
        name: firstName,
        workout: workoutName,
        reach: 0,
        kind: ContributorKind.train);
  }

  final ctx = _leverageContext(score, now: t);

  // Same time-aware overlay as the headline so the pair reads coherently.
  final bucket = _timeBucket(t);
  if (bucket == CoachTimeBucket.morning) {
    final pool = _morningBodies;
    final template = pool[_dailyIndex(pool.length, t)];
    final kind = ctx?.kind ?? ContributorKind.train;
    return _appendData(
        _interpolate(template,
            name: firstName,
            workout: workoutName,
            reach: ctx?.reach ?? score.score,
            kind: kind),
        score,
        kind);
  }
  if (bucket == CoachTimeBucket.late) {
    final pool = _lateBodies;
    final template = pool[_dailyIndex(pool.length, t)];
    final kind = ctx?.kind ?? ContributorKind.sleep;
    return _appendData(
        _interpolate(template,
            name: firstName,
            workout: workoutName,
            reach: ctx?.reach ?? score.score,
            kind: kind),
        score,
        kind);
  }

  if (ctx == null) {
    return _allDoneBodies[_dailyIndex(_allDoneBodies.length, t)];
  }
  final pool = _bodyPoolFor(ctx.kind);
  final template = pool[_dailyIndex(pool.length, t)];
  return _appendData(
      _interpolate(template,
          name: firstName, workout: workoutName, reach: ctx.reach, kind: ctx.kind),
      score,
      ctx.kind);
}

/// Ground a fallback body in the user's OWN data by appending the chosen
/// pillar's concrete status (e.g. "2,588 steps to go", "7h 12m last night",
/// "3 of 5 exercises") — drawn from the already-vetted `statusText` on the
/// matching contributor, so nothing is invented. Statuses without a digit
/// (qualitative, e.g. "Protein running low", "Workout complete") are skipped
/// so we never pad the body with filler.
String _appendData(String body, TodayScore score, ContributorKind kind) {
  ScoreContributor? match;
  for (final c in score.contributors) {
    if (c.kind == kind) {
      match = c;
      break;
    }
  }
  final status = match?.statusText.trim() ?? '';
  if (status.isEmpty || !RegExp(r'\d').hasMatch(status)) return body;
  final tail = status.endsWith('.') ? status : '$status.';
  return '$body $tail';
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

/// Warm welcome headline for a brand-new / setup-state user on the home coach
/// card (the offline mirror of the backend's `new`-lifecycle welcome). Drops
/// the vocative when there's no real name, so it never reads "…, You!".
String _welcomeHeadline(String? firstName, DateTime t) {
  final name = (firstName != null && firstName.trim().isNotEmpty)
      ? firstName.trim()
      : null;
  final v = name != null ? ', $name' : '';
  final pool = [
    'Welcome to Zealova$v!',
    'Let\'s get you started$v.',
    'Glad you\'re here$v.',
    'Your coaching starts now$v.',
  ];
  return pool[_dailyIndex(pool.length, t)];
}

/// Welcome body (pairs with [_welcomeHeadline]) — no numbers, time-agnostic,
/// points at the two first actions. ≥4 variants, no em/en dashes.
String _welcomeBody(DateTime t) {
  const pool = [
    'I\'m your AI coach. Generate today\'s workout or log a meal, and I\'ll start tailoring everything to you.',
    'Start with one thing, a workout or a logged meal, and your daily plan comes to life.',
    'Build your first workout or snap a meal to log it, and real, personalized coaching kicks in.',
    'Lay the first brick today: a workout or a logged meal. The rest of your plan follows.',
  ];
  return pool[_dailyIndex(pool.length, t)];
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
  // NOTE: copy intentionally no longer references the projected score number
  // ({reach}). The composite 0-100 score is opaque to users (the Today Score
  // card deliberately hides it too), so the pools phrase leverage concretely
  // (the action + its real payoff, e.g. "closes your Move ring"). The {reach}
  // substitution is kept as a harmless no-op for any future template + so the
  // [reach] plumbing (which still selects the leverage pillar) stays intact.
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
  '{name}, one session carries the day.',
  'Train is where the day is won.',
  '{name}, lift first, the rest follows.',
  'Momentum starts with training.',
];

const List<String> _trainBodies = [
  'Knock out {workout} and today\'s biggest lever is done.',
  'Finish {workout} and everything else today is incremental.',
  'Your plan calls for {workout}. Completing it anchors the whole day.',
  'One session, {workout}, and the hard part is behind you.',
  'Train is the heaviest pillar on your card. Hit {workout} to clear it.',
  'Start {workout} when you can. Completion alone moves the day forward.',
  'Even half of {workout} moves the needle. Full completion seals it.',
  'Training is the core of your day. Do {workout} and the rest follows.',
];

// ── Nourish ───────────────────────────────────────────────────────────

const List<String> _nourishHeadlines = [
  '{name}, fuel is the move right now.',
  '{name}, your protein is lagging.',
  'Eat your way back on track, {name}.',
  '{name}, food logging is the gap.',
  'Close the Nourish gap, {name}.',
  '{name}, the kitchen is your next stop.',
  'Hit your macros and close the gap.',
  '{name}, a meal away from on target.',
];

const List<String> _nourishBodies = [
  'Log the rest of your food to close the nutrition gap.',
  'You are short on protein. Hit the target to close it out.',
  'A solid meal closes the Nourish ring for the day.',
  'Your calorie target is partly logged. Finish the day to close it.',
  'Protein is the lever right now. Hitting your goal closes the gap.',
  'Log your remaining meals and the Nourish ring closes.',
  'You have macros left on the table. Close the gap before the day ends.',
  'A balanced meal here clears the Nourish gap.',
];

// ── Move ──────────────────────────────────────────────────────────────

const List<String> _moveHeadlines = [
  '{name}, a walk closes Move.',
  '{name}, steps are the easiest win.',
  'Move is almost there, {name}.',
  '{name}, get outside for the easy win.',
  'Close the Move ring, {name}.',
  '{name}, a few thousand steps left.',
  'Steps are your easiest ring to close.',
  '{name}, your feet do the work.',
];

const List<String> _moveBodies = [
  'A short walk closes your Move ring for the day.',
  'You are close to your step goal. Finishing it closes Move.',
  'Move is your fastest open ring today. A 20 minute walk closes it.',
  'Steps are the easiest win on the card. Hit the goal to close Move.',
  'A loop around the block usually does it. That closes Move.',
  'Your step goal is within reach. Close it before the day winds down.',
  'Move counts every step, even slow ones. Hit your goal to close it.',
  'A walk after your next break closes the ring.',
];

// ── Sleep ─────────────────────────────────────────────────────────────

const List<String> _sleepHeadlines = [
  '{name}, last night was short.',
  '{name}, sleep is dragging your day.',
  'Build tonight back in, {name}.',
  '{name}, rest is on the card now.',
  'Sleep counts here, {name}.',
  '{name}, an earlier bedtime helps.',
  'Wind down by ten tonight, {name}.',
  '{name}, recovery is the lever tonight.',
];

const List<String> _sleepBodies = [
  'Last night came in short. An earlier wind down tonight protects tomorrow.',
  'Sleep is a contributor now. A solid night sets up a stronger tomorrow.',
  'Recovery shows up on the card. Aim for your sleep goal tonight.',
  'Bed by ten gives you a better starting line tomorrow.',
  'Your sleep is below your usual. Tonight is a chance to reset.',
  'A full goal-length night tonight resets the trend.',
  'The Sleep ring rewards consistency. Match your usual bedtime tonight.',
  'Wind down 30 minutes earlier. Tomorrow starts with tonight.',
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

// ── Time-aware overlays (morning + late) ─────────────────────────────
// These run BEFORE the leverage-driven pools so the message reads naturally
// at the edges of the day. Use {workout} when available; the {reach} token
// is still substituted from the current score.

const List<String> _morningHeadlines = [
  'Good morning, {name}.',
  '{name}, fresh slate.',
  'Morning, {name}. Day\'s open.',
  '{name}, here\'s your setup.',
  'Hey {name}, easy start?',
  'Morning hit list, {name}.',
  '{name}, plan\'s ready.',
  'Up early, {name}? Let\'s go.',
];

const List<String> _morningBodies = [
  'Plan today around {workout}. Hit it and the day has its anchor.',
  'You\'ve got {workout} on deck. Knock it out and the day is yours.',
  'Open with hydration, then food. {workout} is the lever, so land it.',
  'Start protein early so Nourish isn\'t the lever later. {workout} closes the day.',
  'Get your steps in before the desk traps you, then {workout}.',
  'Easy meal first, {workout} second. That sets the day up right.',
  'Set the tone: hit your protein and your workout.',
  '{workout} is today\'s headline. Everything else flows from there.',
];

const List<String> _latePool = [
  '{name}, wind down soon.',
  'Late hour, {name}.',
  '{name}, tomorrow\'s on the line.',
  'Bed pays you back, {name}.',
  '{name}, screen off, lights down.',
  'Recovery is the lever now.',
  '{name}, tomorrow starts tonight.',
  'Sleep is the highest-leverage move.',
];

// ── Expanded morning brief (plan §1e) ────────────────────────────────
// Multi-line bodies — split on `\n` by the card, bullets keep "• " prefix.
// Variant pool of 4+ per pool per `feedback_dynamic_copy_not_robotic`.
// Edge cases:
//   * {workout} falls back to "today's session" when unknown.
//   * {reach} is the CURRENT day score, not a projected reach, so the line
//     "you're at {reach}" never lies when called from the deterministic
//     fallback (no leverage projection is possible without an LLM here).

const List<String> _morningExpandedBodies = [
  'Open with water, then food.\n• Water: 16oz now, overnight loss is real.\n• Breakfast: 30g protein within 60 min.\n• {workout} on the calendar.',
  'A simple morning shape.\n• Hydrate, then a quick protein bite.\n• Move first, then desk.\n• {workout} is the headline.',
  'Three to anchor the day.\n• Water in, screens out for ten.\n• Protein-forward breakfast.\n• {workout} when you have a window.',
  'Start with the basics.\n• 16oz water before coffee.\n• Eat in the next hour.\n• Plan around {workout}.',
];

// ── Expanded evening recap (plan §1e) ────────────────────────────────

const List<String> _eveningRecapHeadlines = [
  'Recap time, {name}.',
  '{name}, day report.',
  'How today landed, {name}.',
  '{name}, end-of-day pulse.',
];

const List<String> _eveningRecapBodies = [
  'Today: a solid run on the basics.\nThis week: keep the streak alive one more night.\nTonight: bed at your usual time.',
  'Today: you put in the work.\nThis week: momentum is on your side.\nTonight: screens off by 10:30.',
  'Today: plan held together.\nThis week: training cadence is steady.\nTonight: wind down 30 min earlier than last night.',
  'Today: enough done to bank.\nThis week: a few more reps to go.\nTonight: protect sleep, the rest follows.',
];

// ── Morning brief — onboarding (low-history degrade, plan §1e) ───────
// Functional asks only: connect / set / build. No "you got this" filler.

const List<String> _morningOnboardingHeadlines = [
  'Morning, {name}.',
  'Welcome in, {name}.',
  'First steps, {name}.',
  '{name}, three to unlock today.',
];

const List<String> _morningOnboardingBodies = [
  'Three things to start real coaching:\n• Connect Health for sleep and recovery.\n• Set nutrition targets.\n• Build your first week of plan.\nOnce these are in, I can actually coach you.',
  'A quick setup unlocks the full picture:\n• Connect Health.\n• Set calorie and protein targets.\n• Build a first week plan.\nThen the home screen starts pulling in real data.',
  'Three setup steps:\n• Health connection for sleep.\n• Calorie and protein targets.\n• A starter week of workouts.\nKnocking these out means tomorrow opens informed.',
  'Lock in the inputs:\n• Connect a Health source.\n• Nutrition targets in settings.\n• A first plan to follow.\nReal coaching starts the moment these land.',
];

const List<String> _lateBodies = [
  'Sleep is the highest-leverage move right now. Aim for goal length tonight.',
  'Get to bed at your usual time and tomorrow opens with momentum.',
  'Tonight\'s sleep is on tomorrow\'s scorecard. Wind down within 30 minutes.',
  'Screens off, lights down. A goal-length night protects the whole next day.',
  'Skip the late scroll. Sleep is one of your four pillars now.',
  'The Sleep ring rewards consistency. Same bedtime as last night, please.',
  'Anything you do now costs you Sleep. Bed first, list tomorrow.',
  'You\'ve done enough today. The smart move is rest.',
];
