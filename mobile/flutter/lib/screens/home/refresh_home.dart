import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/billing_reminder_provider.dart';
import '../../data/providers/consistency_provider.dart';
import '../../data/providers/discover_provider.dart';
import '../../data/providers/gym_profile_provider.dart';
import '../../data/providers/habit_provider.dart';
import '../../data/providers/pending_celebrations_provider.dart';
import '../../data/providers/today_workout_provider.dart';
import '../../data/providers/weekly_plan_provider.dart';
import '../../data/providers/xp_provider.dart';
import '../../data/repositories/hydration_repository.dart';
import '../../data/repositories/nutrition_repository.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/services/home_prewarmer.dart';

/// Consolidated pull-to-refresh helper for the Home tab.
///
/// Invalidates every provider that backs a Home-tier widget in a single
/// call so individual screens don't have to remember which ones to bust.
///
/// Idempotent: safe to call multiple times back-to-back — Riverpod's
/// `invalidate` is a no-op when a provider has no listeners yet to rebuild.
///
/// Edge cases handled:
///   • `habitsProvider` is `StateNotifierProvider.family<_, _, String>`
///     keyed by userId. `ref.invalidate(habitsProvider)` invalidates ALL
///     family instances (per Riverpod's family contract), so we don't need
///     to know the userId here.
///   • `upcomingRenewalProvider` is the canonical billing-reminder provider
///     in this codebase (there is no top-level `billingReminderProvider`).
///   • `BootstrapPrefetchService.refresh` does not exist; the equivalent
///     hard-refresh path is `HomePrewarmer.invalidateAndRefresh(ref)` plus
///     `BootstrapPrefetchService.prefetch(ref)` (fire-and-forget, deduped).
Future<void> refreshAllHome(WidgetRef ref) async {
  debugPrint('🔄 [refreshAllHome] invalidating Home-tier providers');

  // Synchronous invalidations — cheap, no awaits needed.
  ref.invalidate(todayWorkoutProvider);
  ref.invalidate(gymProfilesProvider);
  ref.invalidate(workoutsProvider);
  ref.invalidate(discoverSnapshotProvider);
  ref.invalidate(nutritionProvider);
  ref.invalidate(hydrationProvider);
  ref.invalidate(upcomingRenewalProvider);
  ref.invalidate(pendingCelebrationsProvider);
  ref.invalidate(xpProvider);
  ref.invalidate(consistencyProvider);
  ref.invalidate(weeklyPlanProvider);
  // Family wholesale-invalidate — all (userId) instances refetch.
  ref.invalidate(habitsProvider);

  // Run the prewarmer; bootstrap prefetch is omitted because its API takes
  // a Riverpod `Ref` (not `WidgetRef`) and the per-provider invalidations
  // above already trigger the same fresh fetches it would seed.
  await HomePrewarmer.invalidateAndRefresh(ref);

  debugPrint('✅ [refreshAllHome] done');
}
