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

import '../../core/constants/api_constants.dart';
import '../../core/providers/user_provider.dart';
import '../models/workout_volume_trend.dart';
import '../services/api_client.dart';

/// Default number of ISO weeks to chart.
const int kDefaultVolumeTrendWeeks = 12;

/// In-memory cache keyed by user id, so a provider recreation (e.g. autoDispose
/// after the Stats tab is backgrounded) shows the prior series instantly while
/// the network refresh runs. Survives invalidation; flushed on user switch.
WorkoutVolumeTrend? _trendCache;
String? _trendCacheOwner;

final workoutVolumeTrendProvider =
    FutureProvider.autoDispose<WorkoutVolumeTrend?>((ref) async {
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
