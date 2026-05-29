/// `fuelingSplitProvider` — fetches the training-vs-rest fueling split for the
/// Stats tab from `GET /api/v1/nutrition/training-vs-rest/{user_id}`.
///
/// Reads the user id from `currentUserProvider` and the IANA timezone from
/// `timezoneProvider` internally (day-grouping must be user-local — see
/// feedback_user_local_time_only.md). Cache-tolerant: serves the last good
/// value while refreshing. Returns null on error / no-user rather than
/// throwing — the UI shows an empty state, never fabricated averages.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../core/providers/timezone_provider.dart';
import '../../core/providers/user_provider.dart';
import '../models/fueling_split.dart';
import '../services/api_client.dart';

/// Default rolling window (days) compared training-vs-rest.
const int kDefaultFuelingSplitDays = 30;

FuelingSplit? _fuelingCache;
String? _fuelingCacheOwner;

final fuelingSplitProvider =
    FutureProvider.autoDispose<FuelingSplit?>((ref) async {
  final userId = ref.watch(currentUserProvider).valueOrNull?.id;
  if (userId == null) {
    debugPrint('🔍 [FuelingSplit] No user id — returning null');
    return null;
  }

  if (_fuelingCacheOwner != userId) {
    _fuelingCacheOwner = userId;
    _fuelingCache = null;
  }

  // User-local timezone — falls back to UTC until the tz provider settles.
  final tz = ref.watch(timezoneProvider).timezone;

  final api = ref.read(apiClientProvider);
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
    if (data is Map<String, dynamic>) {
      final split = FuelingSplit.fromJson(data);
      _fuelingCache = split;
      debugPrint(
        '✅ [FuelingSplit] training_days=${split.training.days} '
        'rest_days=${split.rest.days}',
      );
      return split;
    }
    return _fuelingCache;
  } catch (e) {
    debugPrint('❌ [FuelingSplit] Error: $e — serving cache (${_fuelingCache != null})');
    return _fuelingCache;
  }
});
