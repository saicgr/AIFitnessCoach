import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/consistency_provider.dart';
import '../../data/providers/milestones_provider.dart';
import '../../data/providers/muscle_analytics_provider.dart';
import '../../data/providers/scores_provider.dart';
import '../../data/providers/today_workout_provider.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/services/data_cache_service.dart';

/// The app's ROOT [ProviderContainer] (the one backing the top-level
/// `UncontrolledProviderScope`). Set once from `main.dart` right after the
/// container is created.
///
/// Exposed so logic that runs OUTSIDE the widget tree — a fire-and-forget
/// background completion save, an offline-queue replay that lands minutes
/// later, a disposed screen's pending callback — can still refresh providers.
/// This is the key to making [refreshAfterWorkoutMutation] dispose-proof.
ProviderContainer? appProviderContainer;

/// Analytics / summary providers that aggregate workout history and MUST be
/// re-read whenever any workout's completion state changes. This is the single
/// source of truth for "what does a workout mutation invalidate" — previously
/// this exact list was duplicated across the advanced + easy completion flows
/// and only partially mirrored on mark-done / uncomplete.
final List<ProviderOrFamily> kWorkoutMutationProviders = <ProviderOrFamily>[
  muscleHeatmapProvider,
  muscleFrequencyProvider,
  muscleBalanceProvider,
  scoresProvider,
  milestonesProvider,
  consistencyProvider,
  consistencyDataProvider,
  activityHeatmapProvider,
  calendarHeatmapProvider,
];

// Coalesce a burst of mutation refreshes (e.g. completion + a couple of
// background writes resolving back-to-back) into one pass. NOT tied to any
// widget — lives at library scope so a disposed screen can never strand it.
Timer? _mutationDebounce;

/// THE one place that refreshes the app after a workout's completion state
/// changes. Call it from EVERY mutation entry point — active-workout finish
/// (advanced + easy), "mark as done", uncomplete, chat-suggested completion,
/// and the offline-queue replay senders — AFTER the server call has resolved.
///
/// It runs against the root [appProviderContainer], so it works the same from
/// a live screen, a fire-and-forget background save, or an offline replay that
/// fires long after the originating screen was disposed (the navigation/dispose
/// race that used to silently skip the refresh).
///
/// What it refreshes:
///   - `workoutsProvider` (Workout-tab hero + lists) via a silent, stale-while-
///     revalidate refetch — no loading flash.
///   - `todayWorkoutProvider` (Home "today") — busts its disk cache + silent
///     refetch (server-side `/today` + bootstrap caches are already busted by
///     `POST /complete`, see backend crud_completion.py).
///   - every provider in [kWorkoutMutationProviders] (muscle / scores /
///     milestones / consistency / heatmaps).
///
/// [source] is logged for observability (which entry point fired the refresh).
///
/// [userId] — when provided, the workout-LIST disk cache
/// (`DataCacheService.workoutListKey`, userId-scoped, 24h TTL,
/// `returnExpiredOnMiss:true`) is busted BEFORE the silent refetch. This is the
/// fix for the "stale week re-paints" carousel bug: after a program save /
/// regenerate, the old week sat in SharedPreferences and `silentRefresh()`'s
/// own empty-guard / a cold start would re-serve it. Busting the disk slot first
/// guarantees the stale week can't re-paint once the fresh fetch lands. Callers
/// that don't have a userId handy (completion flows) can omit it — the in-memory
/// state refresh below still happens.
Future<void> refreshAfterWorkoutMutation({
  required String source,
  String? workoutId,
  String? userId,
  Duration debounce = const Duration(milliseconds: 250),
}) async {
  final container = appProviderContainer;
  if (container == null) {
    debugPrint('⚠️ [WorkoutMutation] no root container yet — skipped ($source)');
    return;
  }

  _mutationDebounce?.cancel();
  final completer = Completer<void>();
  _mutationDebounce = Timer(debounce, () async {
    try {
      // Bust the userId-scoped workout-list disk cache first (if we know who),
      // so the silent refetch below can't be shadowed by a stale week that
      // would otherwise re-paint via returnExpiredOnMiss on the next cold read.
      if (userId != null && userId.isNotEmpty) {
        await DataCacheService.instance
            .invalidate(DataCacheService.workoutListKey, userId: userId);
      }
      // Workout-tab hero + lists: silent refetch (stale-while-revalidate).
      container.read(workoutsProvider.notifier).silentRefresh();
      // Home "today": bust disk cache + silent refetch.
      await container
          .read(todayWorkoutProvider.notifier)
          .invalidateAndRefresh();
      // Everything that aggregates workout history.
      for (final p in kWorkoutMutationProviders) {
        container.invalidate(p);
      }
      debugPrint(
          '🔄 [WorkoutMutation] refreshed after $source (workout=$workoutId)');
    } catch (e) {
      debugPrint('⚠️ [WorkoutMutation] refresh failed ($source): $e');
    } finally {
      if (!completer.isCompleted) completer.complete();
    }
  });
  return completer.future;
}
