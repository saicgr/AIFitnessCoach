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

// ─── Tone ────────────────────────────────────────────────────────────────────

/// Controls copy density. Kept here (not in the UI layer) so the engine is the
/// single source of truth — the `PreSetInsightBanner` re-imports from here.
///
///   - easy     → more explanatory, extra reassurance, plain language
///   - simple   → balanced middle ground (default)
///   - advanced → data-dense, numeric-first, compact
enum InsightTone { easy, simple, advanced }

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
  // Per-set signals — surface AFTER Set 1 when the same setIndex in last
  // session carried a specific signal. Keyed by setIndex so set 4's RIR=0
  // doesn't mute set 3's rep-miss hint.
  setRirZero, // last session this exact set was pushed to 0 RIR / RPE 10
  setRepMiss, // last session this exact set came in below target min reps
  setPrNear, // current reps on this set are 1 shy of an all-time rep PR
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
    return _renderCopy(result, input, InsightTone.simple);
  }

  /// Per-set variant of [computeCopy].
  ///
  /// Behaviour by `setIndex`:
  ///  • `setIndex == 0` (pre-Set-1) → full exercise-level insight (same
  ///    patterns [computeCopy] detects), with tone-aware copy.
  ///  • `setIndex > 0`  → inspects the matching set in the last session plus
  ///    the optional current-set context. Surfaces set-specific signals:
  ///        - RIR drift on this specific set (last session set-N RIR was 0)
  ///        - Rep-range miss on this specific set
  ///        - PR-near (one more rep = new all-time rep PR at this weight)
  ///    Returns `null` when no per-set signal applies.
  ///
  /// `currentWeightKg` / `currentReps` are optional — when supplied they
  /// enable the PR-near check. When omitted (e.g. Easy/Simple haven't
  /// wired the focal state yet) PR-near simply doesn't fire.
  static String? insightForSet({
    required ExerciseInsightInput input,
    required int setIndex,
    InsightTone tone = InsightTone.simple,
    double? currentWeightKg,
    int? currentReps,
  }) {
    // Safety: negative / huge indices return null.
    if (setIndex < 0 || setIndex > 50) return null;

    // Pre-Set-1 reuses the full exercise-level detection.
    if (setIndex == 0) {
      final result = detectPattern(input);
      if (_isSkip(result.code)) return null;
      return _renderCopy(result, input, tone);
    }

    // Per-set detection: look at last session's set at the same index.
    final sessions = <SessionSummary>[
      for (final s in input.history)
        if (_validWorkingSets(s).isNotEmpty)
          SessionSummary(dateIso: s.dateIso, workingSets: _validWorkingSets(s)),
    ];
    if (sessions.isEmpty) return null;

    final last = sessions.first;
    // Last session may have fewer working sets than today's target.
    final lastAtIdx = setIndex < last.workingSets.length
        ? last.workingSets[setIndex]
        : null;

    // 1) RIR drift on this specific set — last session this set was taken to
    //    failure (RIR 0 / RPE ≥ 10). Flagging this nudges the user to pull
    //    effort back on this same set today.
    if (lastAtIdx != null &&
        ((lastAtIdx.rir != null && lastAtIdx.rir == 0) ||
            (lastAtIdx.rpe != null && lastAtIdx.rpe! >= 10))) {
      return _renderPerSet(
        PatternResult(PatternCode.setRirZero, {
          'setNum': setIndex + 1,
          'reps': lastAtIdx.reps,
          'weightKg': lastAtIdx.weightKg,
        }),
        input,
        tone,
      );
    }

    // 2) Rep-range miss on this specific set — last session this set came in
    //    below the target min. Only fires if the shortfall is material
    //    (≥2 reps short) to avoid near-target noise.
    if (lastAtIdx != null &&
        input.targetMinReps > 0 &&
        lastAtIdx.reps > 0 &&
        lastAtIdx.reps <= input.targetMinReps - 2) {
      return _renderPerSet(
        PatternResult(PatternCode.setRepMiss, {
          'setNum': setIndex + 1,
          'reps': lastAtIdx.reps,
          'tmin': input.targetMinReps,
          'tmax': input.targetMaxReps,
        }),
        input,
        tone,
      );
    }

    // 3) PR-near — current weight matches best-ever weight for this exercise
    //    and one more rep than last session's matching-weight top set would
    //    land an all-time rep PR at this weight. Requires caller context.
    if (currentWeightKg != null && currentReps != null && currentReps > 0) {
      final prRepsAtThisWeight = _bestRepsAtWeight(sessions, currentWeightKg);
      if (prRepsAtThisWeight != null &&
          currentReps == prRepsAtThisWeight + 1 &&
          currentReps >= input.targetMinReps) {
        return _renderPerSet(
          PatternResult(PatternCode.setPrNear, {
            'setNum': setIndex + 1,
            'reps': currentReps,
            'prevBest': prRepsAtThisWeight,
            'weightKg': currentWeightKg,
          }),
          input,
          tone,
        );
      }
    }

    return null;
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

String _renderCopy(
  PatternResult result,
  ExerciseInsightInput input,
  InsightTone tone,
) {
  // Pool resolution order:
  //   1. tone-specific bodyweight pool (rare)
  //   2. tone-specific weighted pool
  //   3. base bodyweight pool
  //   4. base weighted pool
  // This lets us ship tone variants for only the high-value patterns
  // without duplicating every single pool.
  final toneWeighted = _toneWeightedPools[tone];
  final toneBw = _toneBodyweightPools[tone];
  List<String>? pool;
  if (input.isBodyweight) {
    pool = toneBw?[result.code] ??
        toneWeighted?[result.code] ??
        _bodyweightPools[result.code] ??
        _weightedPools[result.code];
  } else {
    pool = toneWeighted?[result.code] ?? _weightedPools[result.code];
  }
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

/// Render a per-set signal with tone-aware copy. Same pool-resolution rules
/// as [_renderCopy] — per-set pools live in [_perSetPools] keyed by tone.
String _renderPerSet(
  PatternResult result,
  ExerciseInsightInput input,
  InsightTone tone,
) {
  final tonePools = _perSetPools[tone] ?? _perSetPools[InsightTone.simple]!;
  final pool = tonePools[result.code];
  if (pool == null || pool.isEmpty) return '';
  // Seed also mixes in setNum so set 3 and set 4 don't pick the same variant
  // when they happen to fire the same code in one workout.
  final setNum = (result.data['setNum'] ?? 0).toInt();
  final idx = _pickVariantIndex(
    pool.length,
    '${input.exerciseId}#$setNum',
    input.workoutStartEpochMs,
  );
  return _fill(pool[idx], result.data, input);
}

/// Returns the best rep count ever logged at the given weight (±0.5 kg) for
/// this exercise, or null if no matching-weight set is in history.
int? _bestRepsAtWeight(List<SessionSummary> sessions, double weightKg) {
  int? best;
  for (final s in sessions) {
    for (final w in s.workingSets) {
      if ((w.weightKg - weightKg).abs() <= 0.5) {
        if (best == null || w.reps > best) best = w.reps;
      }
    }
  }
  return best;
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
      case 'setNum':
      case 'prevBest':
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

// ─── Tone variant pools ──────────────────────────────────────────────────────
//
// Only the highest-value patterns ship with tone-specific copy. Anything not
// overridden here falls back to the base `_weightedPools` / `_bodyweightPools`
// above via `_renderCopy`'s resolution order. The set of covered patterns can
// grow without code changes — just add a code→list entry and it'll be picked.

const Map<InsightTone, Map<PatternCode, List<String>>> _toneWeightedPools = {
  // Easy: more explanatory, extra reassurance, plain language. Avoid jargon
  // (no "RIR", no "deload"). Keep a warm, encouraging voice.
  InsightTone.easy: {
    PatternCode.readyToProgress: [
      'Great job — you hit {reps} reps twice in a row and it felt manageable. Try a little more weight today, you have got this.',
      'You have earned this. Last two times you nailed {reps} reps with energy to spare. Add a touch more weight.',
      'Two solid sessions at {weightDisplay} — your muscles are ready for the next step. Tiny weight bump today.',
      'Nice progress. You owned {reps} reps twice. Today is the day to go a bit heavier.',
    ],
    PatternCode.singleSessionShort: [
      'Last time you did {reps} reps, and your plan asks for {range}. Try a lighter weight today so you can hit the range.',
      'No worries — {reps} reps was under your goal of {range}. Let us ease the weight down and rebuild.',
      'Your goal is {range} reps. Last time you got {reps}, so lighten the weight a little and keep good form.',
      'Short of range last time ({reps} vs {range}). Drop the weight a notch — rhythm matters more than max.',
    ],
    PatternCode.targetMismatchBelow: [
      'Three workouts in a row you came in under {range} reps. Let us lighten the weight so you can hit your target and build up properly.',
      'Your last three sessions averaged {avgReps} reps — below the {range} goal. Drop the weight today and chase the range first.',
      "You've been coming in a bit short (around {avgReps} reps, goal is {range}). Lighter today — build confidence, then climb.",
      'Consistently under target ({avgReps} reps avg). Ease the weight back so the {range} range feels reachable.',
    ],
    PatternCode.singleSessionTop: [
      'You crushed it last time — {reps} reps is past your {tmax} goal. Bump the weight up a bit today, you are ready.',
      'Last session you went past target ({reps} reps). Today add a little weight — your muscles are asking for more.',
      '{reps} reps past {tmax} — that is a green light. Step the weight up today.',
      'Nice work going past {tmax}. A small weight increase today will feel great.',
    ],
    PatternCode.returnAfterGap: [
      'Welcome back. It has been {daysSince} days — start a little lighter today around {eightyPctWeight} and work up if it feels good.',
      'Glad to see you. After {daysSince} days off, open light and build in — no need to chase {lastWeightDisplay} on set 1.',
      '{daysSince} days away — today is just getting back in rhythm. Smooth reps beat heavy reps.',
    ],
  },

  // Advanced: numeric-first, compact. Leads with the data, assumes the user
  // reads RIR/RPE. ~8-10 words where possible.
  InsightTone.advanced: {
    PatternCode.readyToProgress: [
      '2x at {reps} / RIR ≥ 2 → +1 increment today.',
      'Ceiling tagged 2x at {weightDisplay}, RIR in tank. Progress the load.',
      'Top-set reps: {reps}, {reps} — both with reserve. Bump weight.',
      'Hit ceiling twice w/ RIR ≥ 2. Overload this session.',
    ],
    PatternCode.singleSessionShort: [
      'Top set {reps} reps · target {range}. Drop load 5-10%.',
      'Shortfall: {reps} < {tmin}. Reduce weight, chase range.',
      'Last top set: {reps}. Target {range}. Lighten.',
      '{reps} reps below range — back off the weight.',
    ],
    PatternCode.earnedOverload: [
      'Top set {reps} @ {weightDisplay}, RIR ≥ 1. Load up.',
      '{reps} reps, reserve on the plate — progress the weight.',
      'Ceiling tagged, RIR in tank — overload.',
      'Cleared {reps} with reserve — add weight.',
    ],
    PatternCode.targetMismatchBelow: [
      '3-session avg {avgReps} < {tmin}. Deload 5-10%, chase {range}.',
      'Chronic under-target ({avgReps} avg vs {range}). Drop load.',
      '{avgReps} reps avg over 3 sessions. Target {range}. Lighten.',
      'Below target x3 ({avgReps} avg, {range} goal). Reset weight.',
    ],
    PatternCode.targetMismatchAbove: [
      '3-session avg {avgReps} > {tmax}. +1 increment today.',
      'Over target x3 ({avgReps} avg vs {range}). Load up.',
      'Target: {range}. Actual avg: {avgReps}. Add weight.',
      'Cruising above {tmax} x3 — progress the load.',
    ],
    PatternCode.singleSessionTop: [
      '{reps} reps > {tmax} last session. +1 increment.',
      'Past ceiling ({reps} vs {tmax}) — progress the weight.',
      'Over top-end by {reps} reps. Load up today.',
      '{reps} reps, {tmax} cap — progress today.',
    ],
    PatternCode.plateau: [
      '{sessionCount}x at {reps} / {weightDisplay} — deload or tempo.',
      'Plateau: {reps} reps x {sessionCount}. Vary stimulus.',
      'Stalled at {reps} x {sessionCount}. Tempo or deload.',
    ],
    PatternCode.trendingDown: [
      '{from} → {to} reps, same load. Fatigue — back off.',
      'Regression: {from}→{to} at {weightDisplay}. Lighten.',
      'Reps trending {from}→{to}. Recover or drop weight.',
    ],
  },
};

const Map<InsightTone, Map<PatternCode, List<String>>> _toneBodyweightPools = {
  // Bodyweight + tone overrides only where the base pool's "add weight"
  // framing would read wrong. Rest falls back to base `_bodyweightPools`.
  InsightTone.easy: {
    PatternCode.readyToProgress: [
      'You did {reps} reps twice with energy to spare — try a slightly harder version today.',
      'Two great sessions at {reps} reps. Ready to step up to a harder variation.',
      'You are owning {reps} reps. Add a slow pause or try the next level.',
    ],
    PatternCode.singleSessionShort: [
      'Last time {reps} reps, goal is {range}. Slow each rep down today and focus on control — form over count.',
      '{reps} reps short of {range}. Ease off, slow the tempo, clean reps only.',
    ],
  },
  InsightTone.advanced: {
    PatternCode.readyToProgress: [
      '2x at {reps} reps, RIR ≥ 2. Progress variation.',
      'Ceiling x2 w/ reserve. Harder variation.',
    ],
    PatternCode.singleSessionShort: [
      '{reps} reps < {tmin}. Slow tempo, keep form.',
      'Top {reps}, target {range}. 3-1-1 tempo.',
    ],
  },
};

// ─── Per-set pools ───────────────────────────────────────────────────────────
//
// Copy pools for signals that only exist after Set 1. Keyed by tone then
// pattern code. Every signal ships ≥4 variants so repeat workouts don't
// read robotic.

const Map<InsightTone, Map<PatternCode, List<String>>> _perSetPools = {
  InsightTone.simple: {
    PatternCode.setRirZero: [
      'Heads up — set {setNum} last time you left nothing in the tank ({reps} reps to failure). Ease up today, leave 1-2 in reserve.',
      'Set {setNum} was a grinder last session (RIR 0 · {reps} reps). Pull back the effort a touch today.',
      'Last week set {setNum} went to failure. Save a rep or two this time for cleaner volume.',
      'You redlined set {setNum} last session. Today, leave something on the bar — recovery matters.',
    ],
    PatternCode.setRepMiss: [
      'Set {setNum} last session: {reps} reps — short of {range}. Stay patient on this one.',
      'Last time set {setNum} came in at {reps} (target {range}). Control the negative, chase clean reps.',
      'This exact set dropped to {reps} last week. Goal is {range} — one rep at a time.',
      'Set {setNum} was your weak link last session ({reps} vs {range}). Today, stay in range.',
    ],
    PatternCode.setPrNear: [
      'One more rep here = new rep PR at {weightDisplay} (best was {prevBest}). Send it.',
      'Set {setNum}: you are one rep from a PR at {weightDisplay}. Squeeze it out.',
      'Rep {reps} on the board = PR territory (prev best {prevBest}). Dig in.',
      'PR-near · {weightDisplay} · {prevBest}→{reps}. Finish strong.',
    ],
  },
  InsightTone.easy: {
    PatternCode.setRirZero: [
      'Last week set {setNum} was really hard — you pushed to failure. Today, stop with 1-2 reps still in the tank. That is a good thing.',
      'Set {setNum} was brutal last time. Let us pace it today — leave a rep or two in reserve.',
      'You went all-out on set {setNum} last week. Today, ease off a little — smoother reps, better recovery.',
      'Last session this set was a grinder. Today, stop when it gets tough instead of chasing failure.',
    ],
    PatternCode.setRepMiss: [
      'Set {setNum} last week you got {reps} reps, and your goal is {range}. Take it slow and focus on form today.',
      'No worries — set {setNum} was short last time ({reps} vs {range}). Let us focus on clean reps, not the number.',
      'Last session this set came in under goal. Today, slow down the tempo and make every rep count.',
      'Set {setNum} is a sticking point. Stay patient, control the weight, aim for {tmin} clean reps.',
    ],
    PatternCode.setPrNear: [
      'You are one rep away from your best ever at {weightDisplay}. Squeeze it out — you can do this.',
      'This set could be a personal best. Previous best was {prevBest} reps at this weight.',
      'So close to a new record. Steady breathing, full reps, finish strong.',
      'One more rep beats your best ever at this weight. Go get it.',
    ],
  },
  InsightTone.advanced: {
    PatternCode.setRirZero: [
      'Set {setNum} last wk · {reps} reps · RIR 0. Target RIR 1-2 today.',
      'Set-{setNum} RIR 0 last session. Leave 1-2 in tank.',
      'Last set {setNum}: failure. Cap effort at RIR 1 today.',
      'Prev set {setNum}: RIR 0 @ {reps}. Pull back 5-10%.',
    ],
    PatternCode.setRepMiss: [
      'Set {setNum} last wk · {reps} reps · below {range}.',
      'Set-{setNum} shortfall: {reps} < {tmin}. Hold range.',
      'Prev set {setNum}: {reps}/{tmin}. Slow tempo.',
      'Set {setNum} under-target ({reps} vs {range}).',
    ],
    PatternCode.setPrNear: [
      'PR-near: {weightDisplay} · {prevBest}→{reps}.',
      '+1 rep = PR @ {weightDisplay} (prev {prevBest}).',
      'Set {setNum}: PR window, {prevBest}→{reps} @ {weightDisplay}.',
      'Rep PR on deck: {reps} vs {prevBest}.',
    ],
  },
};
