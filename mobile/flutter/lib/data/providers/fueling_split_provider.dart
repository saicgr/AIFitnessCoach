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

/// Whether the one-time background revalidation has already fired for the
/// current owner. Gates the in-memory-hit branch so it revalidates exactly
/// once per session: enough to (a) refresh stale cold-start data and (b)
/// correct a split that was first fetched with `tz=UTC` before the timezone
/// provider settled — but NOT loop, since the `invalidateSelf` re-run lands
/// back in that same branch. Reset on account switch.
bool _fuelingRevalidated = false;

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

  // Wipe the in-memory cache + re-arm the one-shot revalidation on user switch.
  if (_fuelingCacheOwner != userId) {
    _fuelingCacheOwner = userId;
    _fuelingCache = null;
    _fuelingRevalidated = false;
  }

  // User-local timezone — falls back to UTC until the tz provider settles.
  final tzState = ref.watch(timezoneProvider);
  final tz = tzState.timezone;
  final api = ref.read(apiClientProvider);

  // One-time-per-owner background revalidation: refetch with the settled tz
  // and push the fresh value via `invalidateSelf`. Three guards make this
  // correct and loop-free:
  //   • `_fuelingRevalidated` — fires at most once; the invalidateSelf re-run
  //     lands back in branch 1 and must NOT re-trigger (that was the loop).
  //   • tz must be settled — otherwise we'd refetch with `tz=UTC` and bake in
  //     a wrong training/rest day split; we leave the flag unset so the
  //     tz-settled re-run fires it correctly.
  void revalidateOnce() {
    if (_fuelingRevalidated || tzState.isLoading) return;
    _fuelingRevalidated = true;
    Future.microtask(() async {
      final fresh = await _fetchFuelingSplit(api, userId, tz);
      // Only re-emit on a new REAL value; never overwrite good cache with null.
      if (fresh == null) return;
      try {
        ref.invalidateSelf();
      } catch (_) {
        // Provider disposed (account switch / teardown) before the refresh
        // landed — the fresh value is already in _fuelingCache + disk for the
        // next read; nothing to invalidate.
      }
    });
  }

  // 1. In-memory hit — serve instantly, then revalidate once (refreshes stale
  //    cold-start data and corrects a UTC-first fetch once tz settles).
  if (_fuelingCache != null) {
    revalidateOnce();
    return _fuelingCache;
  }

  // 2. Cold start — seed from disk (incl. expired) so a kill→reopen paints
  //    last-known REAL numbers instantly, then revalidate once in the
  //    background.
  try {
    final disk = await DataCacheService.instance.getCached(
      _kFuelingSplitKey,
      userId: _liveUserId,
      returnExpiredOnMiss: true,
    );
    if (disk != null) {
      final seeded = FuelingSplit.fromJson(disk);
      _fuelingCache = seeded;
      revalidateOnce();
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
