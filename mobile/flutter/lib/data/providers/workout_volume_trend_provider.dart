/// `workoutVolumeTrendProvider` — fetches the weekly training-volume trend
/// for the Stats tab from `GET /api/v1/scores/volume-trend`.
///
/// Cache-tolerant + instant-friendly: returns the last good value while a
/// refresh is in flight (no loading flash on tab switches), reads the user id
/// internally from `currentUserProvider`, and returns null on error / no-user
/// rather than throwing — the UI renders an empty state, never fake numbers
/// (CLAUDE.md: no mock/fallback data, no silent degradation to wrong values).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import '../../core/constants/api_constants.dart';
import '../../core/providers/user_provider.dart';
import '../models/workout_volume_trend.dart';
import '../services/api_client.dart';
import '../services/data_cache_service.dart';

/// Default number of ISO weeks to chart.
const int kDefaultVolumeTrendWeeks = 12;

/// Disk cache key (12h TTL via `statsKeyPrefix`). Caches the RAW server JSON.
const String _volumeCacheKey =
    '${DataCacheService.statsKeyPrefix}volume_trend';

/// In-memory cache keyed by user id, so a provider recreation (e.g. autoDispose
/// after the Stats tab is backgrounded) shows the prior series instantly while
/// the network refresh runs. Survives invalidation; flushed on user switch.
WorkoutVolumeTrend? _trendCache;
String? _trendCacheOwner;

final workoutVolumeTrendProvider =
    FutureProvider<WorkoutVolumeTrend?>((ref) async {
  // keepAlive: hold the series for the session so re-entering the Workouts tab
  // does NOT refetch + flash a skeleton.
  ref.keepAlive();

  final userId = ref.watch(currentUserProvider).valueOrNull?.id;
  if (userId == null) {
    debugPrint('🔍 [VolumeTrend] No user id — returning null');
    return null;
  }

  // Flush stale cache on a real account switch.
  if (_trendCacheOwner != userId) {
    _trendCacheOwner = userId;
    _trendCache = null;
  }

  // Fresh-cache-first: a NON-expired last-known trend on disk is returned
  // immediately (instant cold start). keepAlive holds it for the session. An
  // expired entry is NOT served — it falls through to the fetch below (which
  // write-throughs + resets the TTL), so the chart can never freeze stale.
  if (_trendCache == null) {
    final cacheUid = Supabase.instance.client.auth.currentUser?.id ?? userId;
    final cached = await DataCacheService.instance.getCached(
      _volumeCacheKey,
      userId: cacheUid,
    );
    if (cached != null) {
      try {
        _trendCache = WorkoutVolumeTrend.fromJson(cached);
        debugPrint('⚡ [VolumeTrend] Seeded from disk cache');
        return _trendCache;
      } catch (e) {
        debugPrint('⚠️ [VolumeTrend] Disk cache parse failed: $e');
      }
    }
  } else {
    // Already warm in memory for this session — serve it, skip the network.
    return _trendCache;
  }

  final api = ref.read(apiClientProvider);
  try {
    // NOTE: path is `/scores/...` NOT `/api/v1/scores/...` — apiClient.baseUrl
    // already carries `/api/v1` and Dio concatenates without collapsing repeats.
    final res = await api.get<Map<String, dynamic>>(
      ApiConstants.scoresVolumeTrend,
      queryParameters: {
        'user_id': userId,
        'weeks': kDefaultVolumeTrendWeeks,
      },
    );
    final data = res.data;
    if (data is Map<String, dynamic>) {
      final trend = WorkoutVolumeTrend.fromJson(data);
      _trendCache = trend;
      // Write-through: persist RAW server response for the next cold start.
      final cacheUid = Supabase.instance.client.auth.currentUser?.id ?? userId;
      await DataCacheService.instance
          .cache(_volumeCacheKey, data, userId: cacheUid);
      debugPrint(
        '✅ [VolumeTrend] Loaded ${trend.weeks.length} weeks '
        '(total ${trend.totalVolumeKg.toStringAsFixed(0)} kg)',
      );
      return trend;
    }
    return _trendCache;
  } catch (e) {
    debugPrint('❌ [VolumeTrend] Error: $e — serving cache (${_trendCache != null})');
    // Serve the last good value if we have one; otherwise null (empty state).
    return _trendCache;
  }
});
