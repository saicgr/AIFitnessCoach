/// Pre-Set Insight Engine
///
/// Cross-session pattern recognition for the pre-Set-1 coaching banner.
/// Pure Dart — no I/O, no Gemini, no RAG — so it runs in microseconds on
/// already-fetched history data.
///
/// Pipeline:
///   history + today's target → pattern detection → variant-pool copy
///
/// Usage:
///   final copy = PreSetInsightEngine.computeCopy(input);   // nullable
library;

import 'dart:math' as math;

import '../models/set_progression.dart';

// ─── Inputs ──────────────────────────────────────────────────────────────────

/// Single working set from a prior session.
class SetSummary {
  final double weightKg;
  final int reps;
  final int? rpe; // 1-10, nullable
  final int? rir; // 0-5, nullable

  const SetSummary({
    required this.weightKg,
    required this.reps,
    this.rpe,
    this.rir,
  });
}

/// One prior session's working sets (warmups already excluded).
class SessionSummary {
  /// ISO-8601 date (YYYY-MM-DD). Parsed as calendar date in UTC — we only
  /// care about day-level granularity for the "returning after gap" check.
  final String dateIso;
  final List<SetSummary> workingSets;

  const SessionSummary({required this.dateIso, required this.workingSets});
}

/// Everything the engine needs to produce (or decline to produce) copy.
class ExerciseInsightInput {
  final String exerciseId;
  final int targetMinReps;
  final int targetMaxReps;
  final SetProgressionPattern pattern;
  final bool isBodyweight;
  final bool useKg; // user's workout unit preference
  final String todayIso; // YYYY-MM-DD in user-local time
  final int workoutStartEpochMs; // used for variant seeding

  /// Newest session first.
  final List<SessionSummary> history;

  const ExerciseInsightInput({
    required this.exerciseId,
    required this.targetMinReps,
    required this.targetMaxReps,
    required this.pattern,
    required this.isBodyweight,
    required this.useKg,
    required this.todayIso,
    required this.workoutStartEpochMs,
    required this.history,
  });
}

// ─── Pattern codes ───────────────────────────────────────────────────────────

enum PatternCode {
  skipNewExercise,
  skipSpecialtyPattern,
  skipNoRepTarget,
  skipSteadyInRange,
  returnAfterGap,
  brutalLastSession,
  intraSessionFalloff,
  weightJumpTooAggressive,
  readyToProgress,
  plateau,
  earnedOverload,
  trendingUp,
  trendingDown,
  targetMismatchBelow,
  targetMismatchAbove,
  singleSessionShort,
  singleSessionShortBy1,
  singleSessionTop,
}

bool _isSkip(PatternCode c) =>
    c == PatternCode.skipNewExercise ||
    c == PatternCode.skipSpecialtyPattern ||
    c == PatternCode.skipNoRepTarget ||
    c == PatternCode.skipSteadyInRange;

/// Output of detection: pattern + the data numbers each variant pool consumes.
class PatternResult {
  final PatternCode code;
  final Map<String, num> data;
  const PatternResult(this.code, [this.data = const {}]);
}

// ─── Public API ──────────────────────────────────────────────────────────────

class PreSetInsightEngine {
  /// Returns finished copy, or `null` when nothing meaningful to say.
  static String? computeCopy(ExerciseInsightInput input) {
    final result = detectPattern(input);
    if (_isSkip(result.code)) return null;
    return _renderCopy(result, input);
  }

  /// Pattern detection only — exposed for tests and diagnostics.
  static PatternResult detectPattern(ExerciseInsightInput i) {
    // ── Early skip gates ──
    if (i.pattern == SetProgressionPattern.dropSets ||
        i.pattern == SetProgressionPattern.restPause ||
        i.pattern == SetProgressionPattern.myoReps) {
      return const PatternResult(PatternCode.skipSpecialtyPattern);
    }
    if (i.targetMinReps <= 0 || i.targetMaxReps <= 0) {
      return const PatternResult(PatternCode.skipNoRepTarget);
    }

    // Filter: drop sessions with no valid working sets (reps > 0).
    final sessions = <SessionSummary>[
      for (final s in i.history)
        if (_validWorkingSets(s).isNotEmpty)
          SessionSummary(dateIso: s.dateIso, workingSets: _validWorkingSets(s)),
    ];
    if (sessions.isEmpty) {
      return const PatternResult(PatternCode.skipNewExercise);
    }

    final last = sessions.first;
    final lastTop = _topBy(last.workingSets, (s) => s.reps);
    final lastFirst = last.workingSets.first;
    final lastLast = last.workingSets.last;

    // 4. Returning after gap
    final daysSince = _daysBetween(i.todayIso, last.dateIso);
    if (daysSince > 14) {
      return PatternResult(PatternCode.returnAfterGap, {
        'daysSince': daysSince,
        'lastWeightKg': lastTop.weightKg,
      });
    }

    // 5. Brutal last session — every working set pushed to failure
    if (last.workingSets.length >= 2) {
      final brutal = last.workingSets.every((s) =>
          (s.rpe != null && s.rpe! >= 9) || (s.rir != null && s.rir == 0));
      if (brutal) {
        return PatternResult(PatternCode.brutalLastSession, {
          'reps': lastTop.reps,
          'weightKg': lastTop.weightKg,
        });
      }
    }

    // 6. Intra-session falloff (reps crash across sets)
    if (last.workingSets.length >= 3 &&
        lastFirst.reps >= 6 &&
        lastLast.reps <= (lastFirst.reps / 2).floor()) {
      return PatternResult(PatternCode.intraSessionFalloff, {
        'first': lastFirst.reps,
        'last': lastLast.reps,
      });
    }

    // 7. Aggressive weight jump that cost reps
    if (sessions.length >= 4) {
      final priorTopWeights = sessions
          .skip(1)
          .take(3)
          .map((s) => _topBy(s.workingSets, (x) => x.reps).weightKg)
          .toList()
        ..sort();
      final median = priorTopWeights[1];
      if (median > 0 &&
          lastTop.weightKg > 1.10 * median &&
          lastTop.reps < i.targetMinReps) {
        return PatternResult(PatternCode.weightJumpTooAggressive, {
          'newWeightKg': lastTop.weightKg,
          'medianKg': median,
          'reps': lastTop.reps,
        });
      }
    }

    // 8. Ready to progress — 2+ sessions at top of range with reps in reserve
    if (sessions.length >= 2) {
      final twoAtCeiling = sessions.take(2).every((s) {
        if (s.workingSets.isEmpty) return false;
        final top = _topBy(s.workingSets, (x) => x.reps);
        return top.reps >= i.targetMaxReps &&
            top.rir != null &&
            top.rir! >= 2;
      });
      if (twoAtCeiling && _sameTopWeight(sessions.take(2))) {
        return PatternResult(PatternCode.readyToProgress, {
          'reps': lastTop.reps,
          'weightKg': lastTop.weightKg,
        });
      }
    }

    // 9. Plateau — same weight, reps within ±1 across 3+ sessions, below ceiling
    if (sessions.length >= 3) {
      final last3 = sessions.take(3).toList();
      if (_sameTopWeight(last3)) {
        final reps = last3
            .map((s) => _topBy(s.workingSets, (x) => x.reps).reps)
            .toList();
        final mn = reps.reduce(math.min);
        final mx = reps.reduce(math.max);
        if (mx - mn <= 1 && mx < i.targetMaxReps) {
          return PatternResult(PatternCode.plateau, {
            'reps': lastTop.reps,
            'weightKg': lastTop.weightKg,
            'sessionCount': last3.length,
          });
        }
      }
    }

    // 10. Earned overload — single session at ceiling with room to spare
    if (lastTop.reps >= i.targetMaxReps &&
        ((lastTop.rir != null && lastTop.rir! >= 1) ||
            (lastTop.rpe != null && lastTop.rpe! <= 8))) {
      return PatternResult(PatternCode.earnedOverload, {
        'reps': lastTop.reps,
        'weightKg': lastTop.weightKg,
      });
    }

    // 11. Trending up (reps ↑ at same weight across 3 sessions, newest→oldest)
    if (sessions.length >= 3) {
      final last3 = sessions.take(3).toList();
      if (_sameTopWeight(last3)) {
        final reps = last3
            .map((s) => _topBy(s.workingSets, (x) => x.reps).reps)
            .toList();
        if (reps[0] > reps[1] && reps[1] > reps[2]) {
          return PatternResult(PatternCode.trendingUp, {
            'from': reps.last,
            'to': reps.first,
          });
        }
      }
    }

    // 12. Trending down — 2-session drop of ≥2 reps at same weight
    if (sessions.length >= 2 && _sameTopWeight(sessions.take(2))) {
      final a = _topBy(sessions.elementAt(0).workingSets, (x) => x.reps).reps;
      final b = _topBy(sessions.elementAt(1).workingSets, (x) => x.reps).reps;
      if (b - a >= 2) {
        return PatternResult(PatternCode.trendingDown, {'from': b, 'to': a});
      }
    }

    // 13/14. Target mismatch — chronic under/over shoot
    if (sessions.length >= 3) {
      final avg = sessions
              .take(3)
              .map((s) => _topBy(s.workingSets, (x) => x.reps).reps)
              .fold<int>(0, (a, b) => a + b) /
          3.0;
      if (avg <= i.targetMinReps - 2) {
        return PatternResult(PatternCode.targetMismatchBelow, {
          'avgReps': avg.round(),
          'tmin': i.targetMinReps,
          'tmax': i.targetMaxReps,
        });
      }
      if (avg >= i.targetMaxReps + 2) {
        return PatternResult(PatternCode.targetMismatchAbove, {
          'avgReps': avg.round(),
          'tmin': i.targetMinReps,
          'tmax': i.targetMaxReps,
        });
      }
    }

    // 15/16/17. Single-session cases
    if (sessions.length == 1) {
      if (lastTop.reps <= i.targetMinReps - 2) {
        return PatternResult(PatternCode.singleSessionShort, {
          'reps': lastTop.reps,
          'tmin': i.targetMinReps,
          'tmax': i.targetMaxReps,
        });
      }
      if (lastTop.reps == i.targetMinReps - 1) {
        return PatternResult(PatternCode.singleSessionShortBy1, {
          'reps': lastTop.reps,
          'tmin': i.targetMinReps,
        });
      }
      if (lastTop.reps > i.targetMaxReps) {
        return PatternResult(PatternCode.singleSessionTop, {
          'reps': lastTop.reps,
          'tmax': i.targetMaxReps,
        });
      }
    }

    return const PatternResult(PatternCode.skipSteadyInRange);
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

List<SetSummary> _validWorkingSets(SessionSummary s) =>
    s.workingSets.where((w) => w.reps > 0).toList();

SetSummary _topBy(List<SetSummary> sets, num Function(SetSummary) key) =>
    sets.reduce((a, b) => key(a) >= key(b) ? a : b);

bool _sameTopWeight(Iterable<SessionSummary> sessions) {
  double? ref;
  for (final s in sessions) {
    if (s.workingSets.isEmpty) return false;
    final w = _topBy(s.workingSets, (x) => x.reps).weightKg;
    if (ref == null) {
      ref = w;
    } else if ((w - ref).abs() > 0.5) {
      // kg tolerance — handles 0.5kg rounding between sessions
      return false;
    }
  }
  return ref != null;
}

int _daysBetween(String todayIso, String dateIso) {
  final today = DateTime.parse(todayIso);
  final date = DateTime.parse(dateIso);
  return today.difference(date).inDays;
}

// ─── Copy rendering ──────────────────────────────────────────────────────────

String _renderCopy(PatternResult result, ExerciseInsightInput input) {
  final pool = input.isBodyweight
      ? (_bodyweightPools[result.code] ?? _weightedPools[result.code])
      : _weightedPools[result.code];
  if (pool == null || pool.isEmpty) {
    // Should never happen for non-skip codes — fall back to weighted pool.
    final fallback = _weightedPools[result.code];
    if (fallback == null || fallback.isEmpty) return '';
    return _fill(fallback.first, result.data, input);
  }

  final idx = _pickVariantIndex(
    pool.length,
    input.exerciseId,
    input.workoutStartEpochMs,
  );
  return _fill(pool[idx], result.data, input);
}

int _pickVariantIndex(int poolSize, String exerciseId, int workoutStartEpochMs) {
  // Floor to the second so rebuilds inside one workout pick the same variant.
  final seed = exerciseId.hashCode ^ (workoutStartEpochMs ~/ 1000);
  return seed.abs() % poolSize;
}

/// Substitutes {placeholders} in a template string.
/// Unknown placeholders throw — we'd rather crash a test than render "{reps}".
String _fill(String template, Map<String, num> data, ExerciseInsightInput i) {
  return template.replaceAllMapped(RegExp(r'\{(\w+)\}'), (m) {
    final key = m.group(1)!;
    switch (key) {
      case 'reps':
      case 'first':
      case 'last':
      case 'from':
      case 'to':
      case 'avgReps':
      case 'tmin':
      case 'tmax':
      case 'daysSince':
      case 'sessionCount':
        final v = data[key];
        if (v == null) {
          throw StateError('Missing placeholder data: $key');
        }
        return v.round().toString();
      case 'repsPlus2':
        final v = data['reps'];
        if (v == null) throw StateError('Missing reps for repsPlus2');
        return (v.round() + 2).toString();
      case 'range':
        final mn = data['tmin']?.round();
        final mx = data['tmax']?.round();
        if (mn == null || mx == null) {
          throw StateError('Missing tmin/tmax for range');
        }
        return mn == mx ? '$mn' : '$mn-$mx';
      case 'weightDisplay':
        final kg = data['weightKg']?.toDouble();
        if (kg == null) throw StateError('Missing weightKg');
        return _formatWeight(kg, i.useKg);
      case 'newWeightDisplay':
        final kg = data['newWeightKg']?.toDouble();
        if (kg == null) throw StateError('Missing newWeightKg');
        return _formatWeight(kg, i.useKg);
      case 'medianDisplay':
        final kg = data['medianKg']?.toDouble();
        if (kg == null) throw StateError('Missing medianKg');
        return _formatWeight(kg, i.useKg);
      case 'lastWeightDisplay':
        final kg = data['lastWeightKg']?.toDouble();
        if (kg == null) throw StateError('Missing lastWeightKg');
        return _formatWeight(kg, i.useKg);
      case 'eightyPctWeight':
        final kg = data['lastWeightKg']?.toDouble();
        if (kg == null) throw StateError('Missing lastWeightKg');
        return _formatWeight(kg * 0.8, i.useKg);
    }
    throw StateError('Unknown placeholder: $key');
  });
}

String _formatWeight(double kg, bool useKg) {
  if (useKg) {
    final rounded = (kg * 2).round() / 2; // nearest 0.5 kg
    final label = rounded == rounded.roundToDouble()
        ? rounded.toStringAsFixed(0)
        : rounded.toStringAsFixed(1);
    return '$label kg';
  }
  final lbs = kg * 2.20462;
  final rounded = lbs.round(); // nearest lb for display
  return '$rounded lb';
}

// ─── Variant pools ───────────────────────────────────────────────────────────
//
// Hand-curated, 4+ variants per pattern so copy feels fresh across sessions.
// Placeholders are validated at fill time — any typo explodes immediately.

const Map<PatternCode, List<String>> _weightedPools = {
  PatternCode.returnAfterGap: [
    'First time back in {daysSince} days. Start around {eightyPctWeight} — earn the top set.',
    "It's been {daysSince} days. Open light, build into {lastWeightDisplay} if it feels good.",
    '{daysSince}-day gap — today is re-entry. Volume over intensity.',
    "Back from a {daysSince}-day break. Don't chase {lastWeightDisplay} on set 1 — work up to it.",
  ],
  PatternCode.brutalLastSession: [
    'Last one was a grind — every set maxed out. Open light today, feel how you recover.',
    'You emptied the tank last session. Save something for the later sets this time.',
    'Last session was full send. Back off 5-10% today and rebuild quality reps.',
    'Every set at failure last time. Today, leave 2 reps in the tank on set 1.',
  ],
  PatternCode.intraSessionFalloff: [
    'Last time reps fell off a cliff ({first} → {last}). Start one step lighter today.',
    'Set-by-set drop last session ({first} to {last}) — back it down and keep volume steady.',
    "Reps crashed last time ({first}→{last}). Don't open this heavy today.",
    'You bled out last session ({first} to {last} reps). Ease in, protect the later sets.',
  ],
  PatternCode.weightJumpTooAggressive: [
    'Big jump to {newWeightDisplay} cost you reps ({reps} vs usual). Drop back to {medianDisplay} today and rebuild.',
    "{newWeightDisplay} was too much last time — only {reps} reps. Ease back to {medianDisplay}.",
    'You outran your strength — {newWeightDisplay} for {reps} reps. Reset to {medianDisplay} and climb back up.',
    'The {newWeightDisplay} jump was premature ({reps} reps). {medianDisplay} today, earn the weight back.',
  ],
  PatternCode.readyToProgress: [
    'Two sessions at {reps} with reps in the tank. Bump the weight today.',
    'You owned {reps} reps twice now — time to add weight.',
    'Earned it. Last two sessions at {reps}, reps in reserve. Up the weight.',
    "Ceiling-tagged twice at {weightDisplay}. Today's the day — add weight.",
  ],
  PatternCode.plateau: [
    '{sessionCount} sessions in a row at {reps} reps. Time to break through — add a pause at the bottom today.',
    "You've hit {reps} three times at {weightDisplay}. Shift the rep target or drop weight and chase {repsPlus2}.",
    '{reps} reps, {sessionCount} sessions running. One more today, or we deload next time.',
    'Stuck at {reps}. Try a tempo pause or slip one more rep in today.',
    "{sessionCount} sessions glued to {reps}. Break it with tempo, pause, or a backoff set.",
  ],
  PatternCode.earnedOverload: [
    'Tagged {reps} reps with room to spare last session. Add weight today.',
    "Crushed the ceiling at {reps} with reps in reserve — time to go up.",
    "Last session: {reps} reps, still easy. Bump the weight today.",
    "{reps} reps and RIR in the tank — progress the weight this set.",
  ],
  PatternCode.trendingUp: [
    'Up from {from} → {to} over 3 sessions. One more today and we bump the weight.',
    'Reps climbing: {from} to {to}. Keep chasing — weight goes up soon.',
    'Building momentum — {from} to {to} over 3 sessions. Keep the streak.',
    'Three sessions of progress ({from}→{to}). Push for one more rep today.',
  ],
  PatternCode.trendingDown: [
    'Reps have slipped from {from} to {to} at the same weight. Recover, lighten up, or swap reps for tempo today.',
    'Down from {from} to {to} sessions in a row. Check recovery — consider dropping weight today.',
    'Reps are trending the wrong way ({from}→{to}). Back off or take an extra rest day after this.',
    '{from} last session, now {to}. Fatigue is adding up — lighten up today.',
  ],
  PatternCode.targetMismatchBelow: [
    'Averaged {avgReps} reps over your last three on this. Below the {range} target — lighten up today.',
    "You've been coming in under target ({avgReps} avg vs {range}). Drop weight, chase range.",
    'Three sessions below {tmin}. Time to recalibrate — lighter weight, more reps.',
    'Consistently short ({avgReps} avg, target {range}). Ease the weight down today.',
  ],
  PatternCode.targetMismatchAbove: [
    "Averaged {avgReps} reps over your last three — above the {range} target. Add weight today.",
    "You've been crushing target ({avgReps} avg vs {range}). Time to add weight.",
    'Three sessions past {tmax}. The weight is too light — bump it up.',
    'Consistently over ({avgReps} avg, target {range}). Add weight, come back to {range}.',
  ],
  PatternCode.singleSessionShort: [
    'Hit {reps} reps last session — below the {range} range. Lighten up today.',
    'Last session: {reps} reps. Target is {range}, so ease the weight.',
    '{reps} reps last time, target {range}. Drop the weight, chase range.',
    'You hit {reps} reps — short of {range}. Back off the weight today.',
  ],
  PatternCode.singleSessionShortBy1: [
    'Last session: {reps} reps, just shy of {tmin}. Same weight — push for {tmin}+ today.',
    '{reps} reps last time, one shy of {tmin}. Same bar, one more rep.',
    "So close last time — {reps} reps, target's {tmin}. Today, grind for that extra.",
    'Just barely short ({reps} vs {tmin}). Same weight, push through today.',
  ],
  PatternCode.singleSessionTop: [
    'You crushed {reps} reps past the {tmax} ceiling. Bump the weight today.',
    '{reps} reps last session — time to add weight.',
    'Last session: {reps} reps, past {tmax}. Progress the weight today.',
    'You blew past target ({reps} reps). Time to go heavier.',
  ],
};

/// Bodyweight overrides — replace "lighten up / add weight" with tempo cues.
const Map<PatternCode, List<String>> _bodyweightPools = {
  PatternCode.weightJumpTooAggressive: [
    // Rare for bodyweight; fall back to weighted copy if encountered.
  ],
  PatternCode.readyToProgress: [
    'Two sessions at {reps} reps with RIR in the tank. Try a harder variation today.',
    'You owned {reps} reps twice — time to progress the variation.',
    'Ceiling-tagged twice. Today, add a pause or go to a harder variation.',
    "You're outgrowing this — try the next harder variation.",
  ],
  PatternCode.earnedOverload: [
    '{reps} reps with reps in reserve — time to progress the variation.',
    'Crushed {reps} reps last session. Add tempo or progress the movement.',
    "Tagged {reps} reps easy. Slow the tempo or go harder today.",
    "{reps} reps and still fresh — step up the variation.",
  ],
  PatternCode.singleSessionShort: [
    'Hit {reps} reps last session — below {range}. Slow the tempo today and earn each rep.',
    'Last session: {reps} reps, short of {range}. Focus on clean, controlled reps today.',
    '{reps} reps short of {range}. Drop tempo, prioritize form.',
    'You came in at {reps} vs target {range}. Today, slow everything down.',
  ],
  PatternCode.singleSessionTop: [
    'Crushed {reps} reps past {tmax}. Try a harder variation or add a pause.',
    '{reps} reps last time — too easy. Slow the tempo today or progress.',
    'Past target ({reps} reps). Time for a harder version.',
    "{reps} reps? You've outgrown this — step it up today.",
  ],
  PatternCode.targetMismatchAbove: [
    "Averaged {avgReps} reps — above target. Progress the variation today.",
    "You've been above target ({avgReps} avg vs {range}). Make it harder.",
    'Consistently over {tmax} — time for a harder variation.',
    "You're outgrowing this ({avgReps} avg). Step up the movement.",
  ],
};
