/// `trainingInsightProvider` — fetches the training-trend AI insight for the
/// Stats tab from `GET /api/v1/coach/daily-insight?source=workout_stats`.
///
/// The backend assembles a real training-trend snapshot (volume deltas,
/// push/pull split, ACWR state, recent PR count, current streak), runs Gemini
/// with a ground-truth number guardrail, and serves a deterministic line
/// derived from the SAME real snapshot on any failure / cost-cap. The client
/// always renders something. Returns null on error / no-user rather than
/// throwing — never fabricates copy locally.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import '../../core/constants/api_constants.dart';
import '../../core/providers/timezone_provider.dart';
import '../../core/providers/user_provider.dart';
import '../models/training_insight.dart';
import '../services/api_client.dart';
import '../services/data_cache_service.dart';

/// Disk cache key (12h TTL via `statsKeyPrefix`). Caches the RAW server JSON.
const String _insightCacheKey =
    '${DataCacheService.statsKeyPrefix}training_insight';

TrainingInsight? _insightCache;
String? _insightCacheOwner;

String _dateString(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

final trainingInsightProvider =
    FutureProvider<TrainingInsight?>((ref) async {
  // keepAlive: hold the insight for the session so re-entering the Workouts
  // tab doesn't refetch + flash a skeleton.
  ref.keepAlive();

  final userId = ref.watch(currentUserProvider).valueOrNull?.id;
  if (userId == null) {
    debugPrint('🔍 [TrainingInsight] No user id — returning null');
    return null;
  }

  if (_insightCacheOwner != userId) {
    _insightCacheOwner = userId;
    _insightCache = null;
  }

  // Fresh-cache-first: a NON-expired last-known insight on disk is returned
  // immediately (instant cold start, skip the network). keepAlive holds it for
  // the session. An expired entry is NOT served — it falls through to the
  // fetch below (which write-throughs + resets the 12h TTL), so the card can
  // never freeze to a stale insight.
  if (_insightCache == null) {
    final cacheUid = Supabase.instance.client.auth.currentUser?.id ?? userId;
    final cached = await DataCacheService.instance.getCached(
      _insightCacheKey,
      userId: cacheUid,
    );
    if (cached != null) {
      try {
        _insightCache = TrainingInsight.fromJson(cached);
        debugPrint('⚡ [TrainingInsight] Seeded from disk cache');
        return _insightCache;
      } catch (e) {
        debugPrint('⚠️ [TrainingInsight] Disk cache parse failed: $e');
      }
    }
  } else {
    // Already warm in memory for this session — serve it, skip the network.
    return _insightCache;
  }

  // Gate on tz settling + an existing session so the server caches the right
  // local day and we don't burn a guaranteed 401. Serve cache meanwhile.
  final tzState = ref.watch(timezoneProvider);
  if (tzState.isLoading ||
      Supabase.instance.client.auth.currentSession == null) {
    return _insightCache;
  }

  final now = DateTime.now();
  final api = ref.read(apiClientProvider);
  try {
    final res = await api.get<Map<String, dynamic>>(
      ApiConstants.coachDailyInsight,
      queryParameters: {
        'source': 'workout_stats',
        'date': _dateString(DateTime(now.year, now.month, now.day)),
        'tz': tzState.timezone,
      },
    );
    final data = res.data;
    if (data is Map<String, dynamic>) {
      final insight = TrainingInsight.fromJson(data);
      _insightCache = insight;
      // Write-through: persist RAW server response for the next cold start.
      final cacheUid = Supabase.instance.client.auth.currentUser?.id ?? userId;
      await DataCacheService.instance
          .cache(_insightCacheKey, data, userId: cacheUid);
      debugPrint(
        '✅ [TrainingInsight] "${insight.headline}" '
        '(fallback=${insight.isFallback})',
      );
      return insight;
    }
    return _insightCache;
  } catch (e) {
    debugPrint('❌ [TrainingInsight] Error: $e — serving cache (${_insightCache != null})');
    return _insightCache;
  }
});
