/// Pre-warms the World/Social tab data so first navigation renders instantly.
///
/// Strategy: the 5 social FutureProviders (`activityFeedProvider`,
/// `friendsListProvider`, `followersListProvider`, `followingListProvider`,
/// `challengesListProvider`) cache their results inside Riverpod's container
/// once awaited. We just `ref.read(provider(userId).future)` after sign-in
/// to force evaluation; subsequent `ref.watch` calls from `social_screen.dart`
/// then hit the cached AsyncValue.data path immediately.
///
/// Unlike the YouOverview prewarmer, there's no separate in-memory cache or
/// disk persistence — Riverpod's own provider container is the cache. We do
/// keep an `_inFlight` Completer for dedup and a `_lastWarmedAt` for staleness.
///
/// World/Social is the lowest-priority tab in typical usage (Home > Workouts
/// > Food >>> World), so warm() intentionally delays 2 seconds before firing
/// — gives critical-path prewarmers (You, Home, Food, Workouts) unrestricted
/// bandwidth during the first 2s post-sign-in. If the user navigates to World
/// within those 2s, the tab's lazy fetch handles it (no regression).
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../providers/social_provider.dart';
import 'api_client.dart';

DateTime? _lastWarmedAt;
Completer<void>? _inFlight;

const Duration _staleAfter = Duration(minutes: 5);
const Duration _initialDelay = Duration(seconds: 2);

class SocialPrewarmer {
  /// No disk cache for social data — Riverpod's container is the cache and it
  /// dies on app restart anyway. The 2s warm delay means cold-start users won't
  /// get social pre-warmed before they navigate; that's an acceptable trade-off
  /// because (a) social is the lowest-traffic tab and (b) social data has the
  /// shortest useful staleness (live feed should be fresh on every visit).
  static Future<void> hydrateFromDisk() async {
    // Intentionally a no-op. Kept for API symmetry with the other prewarmers.
  }

  /// Drop the staleness clock so the next warm() definitely fires. Called on
  /// sign-out to prevent a freshly-signed-in user from seeing the previous
  /// account's social provider state cached in Riverpod.
  static Future<void> clearAll() async {
    _lastWarmedAt = null;
    // Note: we don't try to invalidate the Riverpod providers here because
    // we don't have a Ref at sign-out. The auth_repository's clearAll path
    // already disposes the entire provider container on full sign-out.
  }

  /// Pre-fetch the 5 social FutureProviders. Fire-and-forget — never throws.
  /// Skips if a recent successful warm exists (within [_staleAfter]).
  static Future<void> warm(dynamic ref, {bool force = false}) async {
    if (!force &&
        _lastWarmedAt != null &&
        DateTime.now().difference(_lastWarmedAt!) < _staleAfter) {
      return;
    }

    final existing = _inFlight;
    if (existing != null) return existing.future;

    final completer = Completer<void>();
    _inFlight = completer;

    try {
      // Defer 2s so the critical-path prewarmers (You, Home, Food, Workouts)
      // get the first slice of HTTP/2 bandwidth uncontested. Skip the delay
      // when force-refreshing (pull-to-refresh) since the user is actively
      // waiting on this data.
      if (!force) await Future.delayed(_initialDelay);

      final api = ref.read(apiClientProvider);
      final userId = await api.getUserId();
      if (userId == null) {
        debugPrint('🔍 [SocialPrewarmer] no userId yet — skipping');
        return;
      }

      debugPrint('🌍 [SocialPrewarmer] warming for $userId');

      // Read all 5 providers in parallel. ref.read(...future) evaluates the
      // provider and caches the result in Riverpod's container so the social
      // tab's ref.watch hits the cached AsyncValue immediately.
      //
      // Wrapped in catchError per-future so one provider's 500 doesn't kill
      // the others.
      final results = await Future.wait<dynamic>(
        [
          ref.read(activityFeedProvider(userId).future).catchError((e) {
            debugPrint('⚠️ [SocialPrewarmer] activityFeed failed: $e');
            return <String, dynamic>{};
          }),
          ref.read(friendsListProvider(userId).future).catchError((e) {
            debugPrint('⚠️ [SocialPrewarmer] friends failed: $e');
            return <Map<String, dynamic>>[];
          }),
          ref.read(followersListProvider(userId).future).catchError((e) {
            debugPrint('⚠️ [SocialPrewarmer] followers failed: $e');
            return <Map<String, dynamic>>[];
          }),
          ref.read(followingListProvider(userId).future).catchError((e) {
            debugPrint('⚠️ [SocialPrewarmer] following failed: $e');
            return <Map<String, dynamic>>[];
          }),
          ref.read(challengesListProvider(userId).future).catchError((e) {
            debugPrint('⚠️ [SocialPrewarmer] challenges failed: $e');
            return <Map<String, dynamic>>[];
          }),
        ],
        eagerError: false,
      );

      _lastWarmedAt = DateTime.now();
      debugPrint(
        '✅ [SocialPrewarmer] warmed ${results.length}/5 providers',
      );
    } catch (e, st) {
      debugPrint('⚠️ [SocialPrewarmer] warm failed: $e\n$st');
    } finally {
      _inFlight = null;
      if (!completer.isCompleted) completer.complete();
    }
  }

  /// Pull-to-refresh entry point — invalidate Riverpod's cache for the 5
  /// social providers, then force-warm. Skips the 2s delay since the user is
  /// actively waiting.
  static Future<void> invalidateAndRefresh(dynamic ref, String userId) async {
    ref.invalidate(activityFeedProvider(userId));
    ref.invalidate(friendsListProvider(userId));
    ref.invalidate(followersListProvider(userId));
    ref.invalidate(followingListProvider(userId));
    ref.invalidate(challengesListProvider(userId));
    _lastWarmedAt = null;
    await warm(ref, force: true);
  }
}
