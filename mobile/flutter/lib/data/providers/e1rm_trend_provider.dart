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

import '../../core/constants/api_constants.dart';
import '../../core/providers/user_provider.dart';
import '../models/e1rm_trend.dart';
import '../services/api_client.dart';

/// Default number of ISO weeks to chart.
const int kDefaultE1rmTrendWeeks = 12;

/// In-memory cache keyed by user id so a provider recreation shows the prior
/// series instantly while the network refresh runs. Flushed on user switch.
E1rmTrend? _e1rmCache;
String? _e1rmCacheOwner;

final strengthE1rmTrendProvider =
    FutureProvider.autoDispose<E1rmTrend?>((ref) async {
  final userId = ref.watch(currentUserProvider).valueOrNull?.id;
  if (userId == null) {
    debugPrint('🔍 [E1rmTrend] No user id — returning null');
    return null;
  }

  if (_e1rmCacheOwner != userId) {
    _e1rmCacheOwner = userId;
    _e1rmCache = null;
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
