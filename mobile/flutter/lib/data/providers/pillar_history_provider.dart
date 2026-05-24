/// `pillarHistoryProvider` — past-day completion history per pillar.
///
/// Drives the headline sparkline / heatmap / band charts in the per-pillar
/// detail screen. Every value is recomputed client-side from existing
/// per-day history endpoints — no new backend route. A simple in-memory cache
/// keyed by `(userId, pillarKind, dayCount)` makes re-opens instant.
///
/// Mapping to [ContributorKind] (`today_score.dart`):
///   PillarKind.train   → ContributorKind.train
///   PillarKind.nourish → ContributorKind.fuel
///   PillarKind.move    → ContributorKind.move
///   PillarKind.sleep   → ContributorKind.sleep
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/today_score.dart';
import '../models/workout.dart';
import '../repositories/nutrition_repository.dart';
import '../repositories/workout_repository.dart';
import '../services/activity_service.dart';
import '../services/api_client.dart';
import '../services/health_service.dart';
import '../services/health_goals_service.dart';
import 'sleep_detail_provider.dart';
import 'nutrition_preferences_provider.dart';

/// User-facing pillar kinds (renames `fuel` → `nourish` for new UI surfaces
/// while preserving the internal [ContributorKind.fuel] key everywhere else).
enum PillarKind { train, nourish, move, sleep }

extension PillarKindMeta on PillarKind {
  ContributorKind get contributorKind {
    switch (this) {
      case PillarKind.train:
        return ContributorKind.train;
      case PillarKind.nourish:
        return ContributorKind.fuel;
      case PillarKind.move:
        return ContributorKind.move;
      case PillarKind.sleep:
        return ContributorKind.sleep;
    }
  }

  String get label {
    switch (this) {
      case PillarKind.train:
        return 'Train';
      case PillarKind.nourish:
        return 'Nourish';
      case PillarKind.move:
        return 'Move';
      case PillarKind.sleep:
        return 'Sleep';
    }
  }
}

/// One past-day pillar score point. `completion` is a 0.0–1.0 fraction;
/// `atGoal` is true when the pillar's daily goal was met (used by the
/// heatmap accent + streak math).
class PillarDayScore {
  final DateTime date;
  final double completion;
  final bool atGoal;

  const PillarDayScore({
    required this.date,
    required this.completion,
    required this.atGoal,
  });
}

/// Memoization key for the pillar-history family provider.
@immutable
class PillarHistoryKey {
  final PillarKind kind;
  final int days;

  const PillarHistoryKey({required this.kind, required this.days});

  @override
  bool operator ==(Object other) =>
      other is PillarHistoryKey && other.kind == kind && other.days == days;

  @override
  int get hashCode => Object.hash(kind, days);
}

/// In-memory cache: `(userId, kind, days)` → result. Cleared on logout via
/// [clearPillarHistoryCache]. Lets the user re-open the pillar detail screen
/// or scrub between range chips instantly.
final Map<String, List<PillarDayScore>> _cache = {};

String _cacheKey(String userId, PillarHistoryKey k) =>
    '$userId|${k.kind.name}|${k.days}';

/// Clear cached pillar histories — call on logout / user switch.
void clearPillarHistoryCache() => _cache.clear();

/// Family provider: past [days] of completion scores for [kind]. Newest
/// last (oldest first), suitable for direct sparkline rendering.
final pillarHistoryProvider = FutureProvider.autoDispose
    .family<List<PillarDayScore>, PillarHistoryKey>((ref, key) async {
  final apiClient = ref.watch(apiClientProvider);
  final userId = await apiClient.getUserId();
  if (userId == null) return const [];

  final ck = _cacheKey(userId, key);
  final cached = _cache[ck];
  if (cached != null) {
    // Refresh silently so the next open is fresh — but return cached now.
    Future.microtask(() async {
      try {
        final fresh = await _compute(ref, key, userId);
        _cache[ck] = fresh;
      } catch (e) {
        debugPrint('⚠️ [PillarHistory] background refresh failed: $e');
      }
    });
    return cached;
  }

  try {
    final fresh = await _compute(ref, key, userId);
    _cache[ck] = fresh;
    return fresh;
  } catch (e, st) {
    debugPrint('❌ [PillarHistory] compute failed: $e\n$st');
    return const [];
  }
});

// ════════════════════════════════════════════════════════════════════════
// Per-pillar computation
// ════════════════════════════════════════════════════════════════════════

Future<List<PillarDayScore>> _compute(
  Ref ref,
  PillarHistoryKey key,
  String userId,
) async {
  switch (key.kind) {
    case PillarKind.train:
      return _computeTrain(ref, key.days, userId);
    case PillarKind.nourish:
      return _computeNourish(ref, key.days, userId);
    case PillarKind.move:
      return _computeMove(ref, key.days, userId);
    case PillarKind.sleep:
      return _computeSleep(ref, key.days);
  }
}

/// Days list oldest-first, inclusive of today.
List<DateTime> _dayList(int days) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return [for (var i = days - 1; i >= 0; i--) today.subtract(Duration(days: i))];
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

// ── Train: from the existing `workoutsProvider` cache ──────────────────────
//
// Per-day completion is binary in v1 (matches today_score_service.dart, which
// also treats Train as binary until per-exercise progress is exposed).
//   atGoal = scheduled-and-completed
//   completion = 1.0 if completed, 0.0 if scheduled-not-completed, NaN-skipped
//                if no workout was scheduled (rest day / no plan)
// Rest days are filtered OUT of the returned list — a rest day isn't a zero,
// matching the score engine's "renormalize out" behaviour.
Future<List<PillarDayScore>> _computeTrain(
  Ref ref,
  int days,
  String userId,
) async {
  final workoutsAsync = ref.read(workoutsProvider);
  final List<Workout> workouts = workoutsAsync.maybeWhen(
    data: (w) => w,
    orElse: () => const [],
  );

  // Index by scheduled date (yyyy-MM-dd).
  final byDate = <String, List<Workout>>{};
  for (final w in workouts) {
    final key = w.scheduledDateKey;
    if (key == null) continue;
    byDate.putIfAbsent(key, () => []).add(w);
  }

  String dk(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  final out = <PillarDayScore>[];
  for (final day in _dayList(days)) {
    final list = byDate[dk(day)] ?? const <Workout>[];
    if (list.isEmpty) {
      // No workout scheduled — skip (don't count as a 0).
      continue;
    }
    final anyCompleted = list.any((w) => w.isCompleted == true);
    out.add(PillarDayScore(
      date: day,
      completion: anyCompleted ? 1.0 : 0.0,
      atGoal: anyCompleted,
    ));
  }
  return out;
}

// ── Nourish: per-day macro series from /nutrition/.../macros-summary ───────
//
// completion = average of (calorie-hit, protein-hit) where hit = min(value /
// goal, 1.0). Days without a goal or without logged data are skipped. atGoal
// when both hits ≥ 0.9 (matches the home-screen "on target" threshold).
Future<List<PillarDayScore>> _computeNourish(
  Ref ref,
  int days,
  String userId,
) async {
  final repo = ref.read(nutritionRepositoryProvider);
  final summary = await repo.getMacrosSummaryRange(userId, days: days);
  if (summary == null) return const [];

  // Prefer the live preferences targets (what the score engine reads). Fall
  // back to the goal columns on the response so a brand-new prefs cache
  // still renders something.
  final prefs = ref.read(nutritionPreferencesProvider);
  final calGoal = prefs.currentCalorieTarget > 0
      ? prefs.currentCalorieTarget
      : (summary.calorieGoal ?? 0);
  final protGoal = prefs.currentProteinTarget > 0
      ? prefs.currentProteinTarget.round()
      : (summary.proteinGoal ?? 0);
  if (calGoal <= 0 || protGoal <= 0) return const [];

  final byDate = {for (final p in summary.dailySeries) p.date: p};
  final out = <PillarDayScore>[];
  for (final day in _dayList(days)) {
    final dk = '${day.year.toString().padLeft(4, '0')}-'
        '${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';
    final point = byDate[dk];
    if (point == null || (point.calories == 0 && point.proteinG == 0)) continue;
    final calHit = (point.calories / calGoal).clamp(0.0, 1.0);
    final protHit = (point.proteinG / protGoal).clamp(0.0, 1.0);
    final completion = (calHit + protHit) / 2.0;
    out.add(PillarDayScore(
      date: day,
      completion: completion,
      atGoal: calHit >= 0.9 && protHit >= 0.9,
    ));
  }
  return out;
}

// ── Move: steps from /activity/history ────────────────────────────────────
Future<List<PillarDayScore>> _computeMove(
  Ref ref,
  int days,
  String userId,
) async {
  final sync = ref.read(healthSyncProvider);
  if (!sync.isConnected) return const [];

  final goal = ref.read(healthGoalsProvider).valueOrNull?.stepGoal ?? 10000;
  final now = DateTime.now();
  final from = now.subtract(Duration(days: days));
  final history = await ref
      .read(activityServiceProvider)
      .getActivityHistory(userId, limit: days + 2, fromDate: from, toDate: now);

  final byDay = <DateTime, int>{
    for (final r in history)
      DateTime(r.date.year, r.date.month, r.date.day): r.steps,
  };

  final out = <PillarDayScore>[];
  for (final day in _dayList(days)) {
    final steps = byDay[DateTime(day.year, day.month, day.day)] ?? 0;
    if (steps == 0 && !_sameDay(day, now)) {
      // Skip pre-sync days with no data — don't fabricate zeros.
      continue;
    }
    final completion = goal > 0 ? (steps / goal).clamp(0.0, 1.0) : 0.0;
    out.add(PillarDayScore(
      date: day,
      completion: completion.toDouble(),
      atGoal: steps >= goal,
    ));
  }
  return out;
}

// ── Sleep: delegate to the existing sleep history (Health Connect / HK) ───
Future<List<PillarDayScore>> _computeSleep(Ref ref, int days) async {
  final historyAsync = ref.read(sleepHistoryProvider.future);
  final history = await historyAsync;
  final goalMinutes =
      ref.read(healthGoalsProvider).valueOrNull?.sleepDurationGoalMinutes ?? 480;

  final out = <PillarDayScore>[];
  for (final day in _dayList(days)) {
    final night = history.nightFor(day);
    if (night == null) continue;
    final total = night.totalAsleepMinutes;
    final completion = goalMinutes > 0
        ? (total / goalMinutes).clamp(0.0, 1.0).toDouble()
        : 0.0;
    out.add(PillarDayScore(
      date: day,
      completion: completion,
      // Sleep "at goal" allows a 15-min undershoot to mirror the
      // sleep_detail_screen's on-goal copy band.
      atGoal: total >= (goalMinutes - 15),
    ));
  }
  return out;
}
