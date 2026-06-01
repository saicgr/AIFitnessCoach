/// `userHistorySnapshotProvider` — fetches the rich history snapshot the
/// workout-card resolver consumes from the backend (`GET /api/v1/user/history-snapshot`).
///
/// Returns `AsyncValue&lt;UserHistorySnapshot?&gt;` — null is a valid degraded
/// state. When the network call fails the provider returns null rather than
/// throwing so the card can fall back to its pure-client resolution.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import '../services/api_client.dart';

/// Snapshot of the user's recent + medium-term history. Mirrors the JSON
/// shape documented in §1b.7 of the home v2 plan but only surfaces the
/// fields the workout-card resolver actually needs.
class UserHistorySnapshot {
  // Yesterday
  final bool yesterdayWorkoutScheduled;
  final bool yesterdayWorkoutCompleted;

  // PRs
  final int prsLast7d;

  // Volume trend (4w)
  /// One of "up" / "flat" / "under" / "unknown".
  final String volumeTrend4wk;

  // Muscle group recency — primary muscle group of today's workout, days since.
  final int daysSincePrimaryMuscleGroup;

  // PR opportunity for today
  final bool hasPrOpportunityToday;

  // Recent intensity bookkeeping
  final int priorTwoDaysHardCount;

  // --- Strain signals (top-level fields on backend response) ---------------
  // Per-day completed-workout volume (sum of weight_kg * reps across all
  // sets in `exercises_json`). 0.0 means "no completed workout yesterday".
  final double yesterdayVolumeKg;
  // Median of the last 30 days' NON-ZERO completed-workout volumes. 0.0
  // means "no history" — callers should treat this as "skip the strain
  // branch entirely" rather than dividing by zero.
  final double volume30dMedianKg;

  const UserHistorySnapshot({
    required this.yesterdayWorkoutScheduled,
    required this.yesterdayWorkoutCompleted,
    required this.prsLast7d,
    required this.volumeTrend4wk,
    required this.daysSincePrimaryMuscleGroup,
    required this.hasPrOpportunityToday,
    required this.priorTwoDaysHardCount,
    required this.yesterdayVolumeKg,
    required this.volume30dMedianKg,
  });

  factory UserHistorySnapshot.fromJson(Map<String, dynamic> json) {
    final yesterday = json['yesterday'] is Map<String, dynamic>
        ? (json['yesterday'] as Map<String, dynamic>)['workout']
              as Map<String, dynamic>?
        : null;
    final prs = json['prs_last_7d'] is List
        ? (json['prs_last_7d'] as List).length
        : 0;
    final trend30 = json['thirty_day_trends'] is Map<String, dynamic>
        ? (json['thirty_day_trends'] as Map<String, dynamic>)['volume_direction']
                as String? ??
            'unknown'
        : 'unknown';
    int daysMg = 0;
    final muscleMap = json['days_since_muscle_group'];
    if (muscleMap is Map && muscleMap.isNotEmpty) {
      // Pick the LARGEST days-since across groups — the resolver only cares
      // about the most overdue group (drives `comebackSession`).
      for (final v in muscleMap.values) {
        if (v is num && v.toInt() > daysMg) daysMg = v.toInt();
      }
    }
    // Strain signals — added as top-level fields by the backend
    // `_strain_volume_signals` collector. Safe defaults (0/0/0) per
    // feedback_no_silent_fallbacks.md: a missing/zero baseline is read by the
    // algorithm as "skip the strain branch", which is the correct degraded
    // behavior — not a fabricated tier.
    final yVol = json['yesterday_volume_kg'];
    final medVol = json['volume_30d_median_kg'];
    final priorHard = json['prior_two_days_hard_count'];
    return UserHistorySnapshot(
      yesterdayWorkoutScheduled: (yesterday?['scheduled'] as bool?) ?? false,
      yesterdayWorkoutCompleted: (yesterday?['completed'] as bool?) ?? false,
      prsLast7d: prs,
      volumeTrend4wk: trend30,
      daysSincePrimaryMuscleGroup: daysMg,
      hasPrOpportunityToday: json['pr_opportunity_today'] is Map,
      priorTwoDaysHardCount: priorHard is num ? priorHard.toInt() : 0,
      yesterdayVolumeKg: yVol is num ? yVol.toDouble() : 0.0,
      volume30dMedianKg: medVol is num ? medVol.toDouble() : 0.0,
    );
  }
}

/// AsyncValue&lt;UserHistorySnapshot?&gt; — null means "snapshot unavailable, fall
/// back to client-only resolution". Errors are swallowed → null.
final userHistorySnapshotProvider =
    FutureProvider.autoDispose<UserHistorySnapshot?>((ref) async {
  ref.keepAlive();
  if (Supabase.instance.client.auth.currentSession == null) return null;
  final api = ref.read(apiClientProvider);
  try {
    // NOTE: path is `/user/history-snapshot` — the api client's baseUrl
    // already carries `/api/v1`. Passing `/api/v1/...` here produces
    // `/api/v1/api/v1/...` 404s (see daily_coach_insight_provider.dart).
    final res = await api.get<Map<String, dynamic>>('/user/history-snapshot');
    final data = res.data;
    if (data is Map<String, dynamic>) {
      return UserHistorySnapshot.fromJson(data);
    }
    return null;
  } catch (_) {
    return null;
  }
});
