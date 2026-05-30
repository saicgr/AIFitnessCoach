/// `fuelingSplitProvider` — fetches the training-vs-rest fueling split for the
/// Stats tab from `GET /api/v1/nutrition/training-vs-rest/{user_id}`.
///
/// Reads the user id from `currentUserProvider` and the IANA timezone from
/// `timezoneProvider` internally (day-grouping must be user-local — see
/// feedback_user_local_time_only.md).
///
/// Cache-first (stale-while-revalidate): a two-tier cache (module-static
/// in-memory + SharedPreferences disk) serves the last good value INSTANTLY,
/// then refreshes silently in the background. On a cold start (app killed →
/// in-memory gone) it seeds from disk (incl. expired) so the card paints
/// last-known REAL numbers immediately. Returns null on error / no-user with no
/// cache rather than throwing — the UI shows an empty state, never fabricated
/// averages.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/api_constants.dart';
import '../../core/providers/timezone_provider.dart';
import '../../core/providers/user_provider.dart';
import '../models/fueling_split.dart';
import '../services/api_client.dart';
import '../services/data_cache_service.dart';

/// Default rolling window (days) compared training-vs-rest.
const int kDefaultFuelingSplitDays = 30;

/// Disk-cache key (stats prefix → 12h TTL, per-user scoped).
const String _kFuelingSplitKey =
    '${DataCacheService.statsKeyPrefix}fueling_split';

FuelingSplit? _fuelingCache;
String? _fuelingCacheOwner;

/// Live user id from the current Supabase session (never a cached field —
/// JWT-expiry rule). Used to scope disk-cache entries per user.
String? get _liveUserId => Supabase.instance.client.auth.currentUser?.id;

/// Serialize a [FuelingSplit] to the exact wire shape `FuelingSplit.fromJson`
/// reads. The model has no `toJson` and lives in a file we don't own, so the
/// serializer lives here.
Map<String, dynamic> _fuelingSplitToJson(FuelingSplit v) => {
      'training': {
        'avg_protein_g': v.training.avgProteinG,
        'avg_calories': v.training.avgCalories,
        'days': v.training.days,
      },
      'rest': {
        'avg_protein_g': v.rest.avgProteinG,
        'avg_calories': v.rest.avgCalories,
        'days': v.rest.days,
      },
    };

final fuelingSplitProvider =
    FutureProvider.autoDispose<FuelingSplit?>((ref) async {
  // Survive Stats-tab re-entry within a session; the in-memory cache below
  // would survive anyway, but this avoids a redundant rebuild/refetch cycle.
  ref.keepAlive();

  final userId = ref.watch(currentUserProvider).valueOrNull?.id;
  if (userId == null) {
    debugPrint('🔍 [FuelingSplit] No user id — returning null');
    return null;
  }

  // Wipe the in-memory cache on user switch.
  if (_fuelingCacheOwner != userId) {
    _fuelingCacheOwner = userId;
    _fuelingCache = null;
  }

  // User-local timezone — falls back to UTC until the tz provider settles.
  final tz = ref.watch(timezoneProvider).timezone;
  final api = ref.read(apiClientProvider);

  // 1. In-memory hit — serve instantly. Do NOT fire a revalidate here: this
  //    branch is also where the disk-seed revalidation lands (after its
  //    `invalidateSelf` re-runs the provider), so revalidating again would
  //    invalidate→re-run→revalidate forever — an infinite fetch loop. The
  //    one-time refresh happens on the cold-start disk-seed path below; within
  //    a session keepAlive holds this value.
  if (_fuelingCache != null) {
    return _fuelingCache;
  }

  // 2. Cold start — seed from disk (incl. expired) so a kill→reopen paints
  //    last-known REAL numbers instantly, then refresh ONCE in the background.
  //    The `invalidateSelf` re-run lands in branch 1 above (now warm), which
  //    returns the fresh value without firing another fetch — no loop.
  try {
    final disk = await DataCacheService.instance.getCached(
      _kFuelingSplitKey,
      userId: _liveUserId,
      returnExpiredOnMiss: true,
    );
    if (disk != null) {
      final seeded = FuelingSplit.fromJson(disk);
      _fuelingCache = seeded;
      Future.microtask(() async {
        final fresh = await _fetchFuelingSplit(api, userId, tz);
        if (fresh != null) ref.invalidateSelf();
      });
      return seeded;
    }
  } catch (e) {
    debugPrint('⚠️ [FuelingSplit] disk seed failed: $e');
  }

  // 3. No cache anywhere — fetch synchronously (this is the only path that can
  //    show skeletons, on a true first-ever visit).
  final fresh = await _fetchFuelingSplit(api, userId, tz);
  // On error/no-data with no cache, _fuelingCache stays null → empty state.
  return fresh ?? _fuelingCache;
});

/// Network fetch + write-through to both cache tiers. Returns the REAL split,
/// or null on error / unexpected shape (caller decides whether to serve cache).
/// Never fabricates data.
Future<FuelingSplit?> _fetchFuelingSplit(
  ApiClient api,
  String userId,
  String tz,
) async {
  try {
    // Path-param form: `/nutrition/training-vs-rest/{user_id}`. baseUrl already
    // carries `/api/v1`.
    final res = await api.get<Map<String, dynamic>>(
      '${ApiConstants.nutritionTrainingVsRest}/$userId',
      queryParameters: {
        'days': kDefaultFuelingSplitDays,
        'tz': tz,
      },
    );
    final data = res.data;
    if (data is! Map<String, dynamic>) return null;

    final split = FuelingSplit.fromJson(data);
    _fuelingCache = split;
    // Write-through to disk (REAL response only).
    try {
      await DataCacheService.instance.cache(
        _kFuelingSplitKey,
        _fuelingSplitToJson(split),
        userId: _liveUserId,
      );
    } catch (e) {
      debugPrint('⚠️ [FuelingSplit] disk write failed: $e');
    }
    debugPrint(
      '✅ [FuelingSplit] training_days=${split.training.days} '
      'rest_days=${split.rest.days}',
    );
    return split;
  } catch (e) {
    debugPrint('❌ [FuelingSplit] Error: $e — serving cache (${_fuelingCache != null})');
    return null;
  }
}
