import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';

/// Payload returned by `GET /cardio-correlation/sleep-pace`.
///
/// Mirrors `backend/services/cardio_correlation_service.py` ::
/// `compute_sleep_pace_correlation` exactly. Kept here (instead of in
/// `lib/data/models/`) because no other screen consumes this shape — it
/// only powers the sleep correlation insight card.
@immutable
class SleepPaceCorrelation {
  /// Pearson r in [-1, 1].
  final double r;

  /// Number of paired sessions used. Always >= 20 when present.
  final int n;

  /// OLS slope: change in seconds/km of pace per additional hour of sleep.
  /// Negative = faster with more sleep (the expected direction).
  final double slopeSecPerKmPerHour;

  /// Human-readable single-sentence insight. Server-rendered so the variant
  /// pool lives in one place (Python) and stays stable per (user, n, r).
  final String copy;

  const SleepPaceCorrelation({
    required this.r,
    required this.n,
    required this.slopeSecPerKmPerHour,
    required this.copy,
  });

  factory SleepPaceCorrelation.fromJson(Map<String, dynamic> json) {
    return SleepPaceCorrelation(
      r: (json['r'] as num? ?? 0).toDouble(),
      n: (json['n'] as num? ?? 0).toInt(),
      slopeSecPerKmPerHour:
          (json['slope_sec_per_km_per_hour'] as num? ?? 0).toDouble(),
      copy: (json['copy'] as String? ?? '').trim(),
    );
  }
}

/// Repository for the sleep × pace correlation endpoint.
///
/// Backend returns **204 No Content** (empty body) when the user has < 20
/// paired sessions — we surface that as `null` so the calling card can
/// collapse to `SizedBox.shrink()` without exception flow.
class SleepCorrelationRepository {
  final ApiClient _api;
  SleepCorrelationRepository(this._api);

  /// Fetch the sleep × pace correlation for the signed-in user.
  ///
  /// Returns `null` when:
  ///   - server replied 204 (not enough data — by design),
  ///   - server replied with an empty body for any reason,
  ///   - the parsed payload has empty copy (defensive — never render blank).
  ///
  /// Throws on network/transport errors so the card can show a retry; we
  /// deliberately do NOT silently swallow non-204 failures (see
  /// `feedback_no_silent_fallbacks`).
  Future<SleepPaceCorrelation?> fetchSleepPace({int days = 30}) async {
    debugPrint('💤 [SleepCorrelation] fetch days=$days');
    final resp = await _api.get(
      '/cardio-correlation/sleep-pace',
      queryParameters: {'days': days},
    );
    // 204 = explicit "not enough data" — empty body, treat as null.
    if (resp.statusCode == 204) {
      debugPrint('💤 [SleepCorrelation] 204 — not enough data');
      return null;
    }
    if (resp.statusCode != 200) {
      throw Exception(
        'Failed to load sleep correlation (${resp.statusCode})',
      );
    }
    final raw = resp.data;
    if (raw == null) return null;
    if (raw is! Map) {
      throw Exception('Unexpected payload for /cardio-correlation/sleep-pace');
    }
    final parsed = SleepPaceCorrelation.fromJson(
      Map<String, dynamic>.from(raw),
    );
    // Defensive: a payload with empty copy is unrenderable — treat as null.
    if (parsed.copy.isEmpty) return null;
    return parsed;
  }
}

// ---------------------------------------------------------------------------
// Riverpod
// ---------------------------------------------------------------------------

final sleepCorrelationRepositoryProvider =
    Provider<SleepCorrelationRepository>((ref) {
  return SleepCorrelationRepository(ref.watch(apiClientProvider));
});

/// 30-day sleep × pace correlation. `.autoDispose` so the cache resets when
/// the user navigates away — it's a small endpoint and freshness > memory.
final sleepPaceCorrelationProvider =
    FutureProvider.autoDispose<SleepPaceCorrelation?>((ref) async {
  final repo = ref.watch(sleepCorrelationRepositoryProvider);
  return repo.fetchSleepPace();
});
