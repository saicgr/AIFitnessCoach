import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/billing_reminder_provider.dart';
import '../../data/providers/coach_refresh_coordinator.dart';
import '../../data/providers/consistency_provider.dart';
import '../../data/providers/discover_provider.dart';
import '../../data/providers/gym_profile_provider.dart';
import '../../data/providers/habit_provider.dart';
import '../../data/providers/pending_celebrations_provider.dart';
import '../../data/providers/secondary_tile_providers.dart';
import '../../data/providers/today_workout_provider.dart';
import '../../data/providers/weekly_plan_provider.dart';
import '../../data/providers/xp_provider.dart';
import '../../data/repositories/hydration_repository.dart';
import '../../data/repositories/nutrition_repository.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/services/api_client.dart';
import '../../data/services/data_cache_service.dart';
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
/// Marks the start of an explicit, user-initiated refresh.
///
/// Call this FIRST — before any other network work in a pull-to-refresh
/// handler — so nothing in the refresh (including calls made before
/// [refreshAllHome], e.g. `refreshUser()`) can be answered by a GET that was
/// already on the wire when the user pulled. [refreshAllHome] calls it too, so
/// callers that only use that helper are covered automatically; calling it
/// twice is harmless (the epoch is an opaque token, not a count).
void beginUserRefresh(WidgetRef ref) {
  ref.read(apiClientProvider).beginUserInitiatedRefresh();
}

Future<void> refreshAllHome(WidgetRef ref) async {
  debugPrint('🔄 [refreshAllHome] invalidating Home-tier providers');

  // A pull-to-refresh is an explicit "give me current data" — it must never be
  // answered by a GET that was already on the wire when the user pulled.
  // `ApiClient.get` coalesces identical in-flight GETs, so without this barrier
  // a refetch triggered below could ride a request issued seconds earlier and
  // hand back the same payload the user just rejected. Bumping the mutation
  // epoch makes every GET from here on open its own request; the refetches
  // fired inside this refresh still coalesce with each other.
  beginUserRefresh(ref);

  // Synchronous invalidations — cheap, no awaits needed.
  ref.invalidate(todayWorkoutProvider);
  ref.invalidate(gymProfilesProvider);
  ref.invalidate(workoutsProvider);
  ref.invalidate(discoverSnapshotProvider);
  ref.invalidate(dailyNutritionProvider);
  ref.invalidate(nutritionMetaProvider);
  ref.invalidate(hydrationProvider);
  ref.invalidate(upcomingRenewalProvider);
  ref.invalidate(pendingCelebrationsProvider);
  ref.invalidate(xpProvider);
  ref.invalidate(consistencyProvider);
  ref.invalidate(weeklyPlanProvider);
  // Family wholesale-invalidate — all (userId) instances refetch.
  ref.invalidate(habitsProvider);

  // Secondary kept-alive tiles (metric deck, home insights/patterns, achievement
  // + content rows). These are `keepAlive`d so they don't refetch on tab switch,
  // so an EXPLICIT refresh must invalidate them here or they'd never update on a
  // pull-to-refresh / resume. The combined-health disk snapshot is also busted so
  // its fresh-cache-first provider actually re-hits the network instead of
  // re-serving the still-fresh disk entry.
  // Bust the secondary tiles' disk caches FIRST (they're fresh-cache-first, so
  // a bare invalidate would re-serve the still-fresh disk snapshot), then
  // invalidate the providers so their re-run actually re-hits the network.
  final userId = await ref.read(apiClientProvider).getUserId();
  if (userId != null) {
    await DataCacheService.instance.invalidateSecondaryTileCaches(userId);
  }
  for (final p in secondaryTileProviders) {
    ref.invalidate(p);
  }

  // Refresh the Home coach card's graph numbers (cheap, no Gemini) so a
  // pull-to-refresh reflects any data logged since the card was generated.
  ref.read(coachRefreshCoordinatorProvider).bumpNumbers();

  // Run the prewarmer; bootstrap prefetch is omitted because its API takes
  // a Riverpod `Ref` (not `WidgetRef`) and the per-provider invalidations
  // above already trigger the same fresh fetches it would seed.
  await HomePrewarmer.invalidateAndRefresh(ref);

  debugPrint('✅ [refreshAllHome] done');
}
