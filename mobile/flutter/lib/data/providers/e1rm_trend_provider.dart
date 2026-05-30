/// `strengthE1rmTrendProvider` — fetches the per-muscle estimated-1RM trend
/// for the Stats tab from `GET /api/v1/scores/strength/e1rm-trend`.
///
/// Cache-tolerant + instant-friendly: serves the last good value while a
/// refresh is in flight (no loading flash on tab switches), reads the user id
/// internally from `currentUserProvider`, and returns null on error / no-user
/// rather than throwing — the UI renders an empty state, never fabricated
/// 1RMs (CLAUDE.md: no mock/fallback data).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import '../../core/constants/api_constants.dart';
import '../../core/providers/user_provider.dart';
import '../models/e1rm_trend.dart';
import '../services/api_client.dart';
import '../services/data_cache_service.dart';

/// Default number of ISO weeks to chart.
const int kDefaultE1rmTrendWeeks = 12;

/// Disk cache key (12h TTL via the `statsKeyPrefix`). Caches the RAW server
/// JSON so a cold start can paint the last-known trend instantly.
const String _e1rmCacheKey = '${DataCacheService.statsKeyPrefix}e1rm_trend';

/// In-memory cache keyed by user id so a provider recreation shows the prior
/// series instantly while the network refresh runs. Flushed on user switch.
E1rmTrend? _e1rmCache;
String? _e1rmCacheOwner;

final strengthE1rmTrendProvider = FutureProvider<E1rmTrend?>((ref) async {
  // keepAlive: hold the parsed series for the session so re-entering the
  // Workouts tab does NOT refetch + flash a skeleton.
  ref.keepAlive();

  final userId = ref.watch(currentUserProvider).valueOrNull?.id;
  if (userId == null) {
    debugPrint('🔍 [E1rmTrend] No user id — returning null');
    return null;
  }

  if (_e1rmCacheOwner != userId) {
    _e1rmCacheOwner = userId;
    _e1rmCache = null;
  }

  // Fresh-cache-first: if we have a NON-expired last-known trend on disk,
  // parse and return it immediately (instant warm start). keepAlive then keeps
  // it for the session. An expired entry is NOT served — it falls through to
  // the network fetch below (which write-throughs + resets the TTL), so the
  // chart can never freeze to a stale value forever. Live session id scopes
  // the slot.
  if (_e1rmCache == null) {
    final cacheUid = Supabase.instance.client.auth.currentUser?.id ?? userId;
    final cached = await DataCacheService.instance.getCached(
      _e1rmCacheKey,
      userId: cacheUid,
    );
    if (cached != null) {
      try {
        _e1rmCache = E1rmTrend.fromJson(cached);
        debugPrint('⚡ [E1rmTrend] Seeded from disk cache');
        return _e1rmCache;
      } catch (e) {
        debugPrint('⚠️ [E1rmTrend] Disk cache parse failed: $e');
      }
    }
  } else {
    // Already warm in memory for this session — serve it, skip the network.
    return _e1rmCache;
  }

  final api = ref.read(apiClientProvider);
  try {
    // baseUrl already carries `/api/v1`; pass `/scores/...` not `/api/v1/...`.
    final res = await api.get<Map<String, dynamic>>(
      ApiConstants.scoresE1rmTrend,
      queryParameters: {
        'user_id': userId,
        'weeks': kDefaultE1rmTrendWeeks,
      },
    );
    final data = res.data;
    if (data is Map<String, dynamic>) {
      final trend = E1rmTrend.fromJson(data);
      _e1rmCache = trend;
      // Write-through: persist the RAW server response for the next cold start.
      final cacheUid = Supabase.instance.client.auth.currentUser?.id ?? userId;
      await DataCacheService.instance.cache(_e1rmCacheKey, data, userId: cacheUid);
      debugPrint(
        '✅ [E1rmTrend] Loaded ${trend.muscles.length} muscle '
        'group${trend.muscles.length == 1 ? '' : 's'}',
      );
      return trend;
    }
    return _e1rmCache;
  } catch (e) {
    debugPrint('❌ [E1rmTrend] Error: $e — serving cache (${_e1rmCache != null})');
    return _e1rmCache;
  }
});
