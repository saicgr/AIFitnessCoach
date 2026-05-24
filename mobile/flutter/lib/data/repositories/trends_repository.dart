import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';

/// =========================================================================
/// Trends repository — Wave 1 metric expansion
/// =========================================================================
///
/// Thin adapter over the nine new backend trend endpoints (micronutrients,
/// cardio, glucose, workout feedback, hormonal/cycle, flexibility, habits,
/// wellbeing, NEAT). Each endpoint shares the same contract:
///
///   * takes a `days` query param (0 ⇒ all history)
///   * returns `{ daily_series: [ { date: 'YYYY-MM-DD', ...fields } ] }`
///
/// Rather than spin up a typed model per endpoint (which would need
/// `build_runner` codegen — forbidden in this codebase), every method returns
/// the raw `daily_series` rows as `List<Map<String, dynamic>>`. The
/// trend-series provider projects whichever field a given [TrendMetric] reads.
///
/// On any failure a method returns `null` — the caller surfaces an honest
/// per-series "no data" note and NEVER fabricates points.
class TrendsRepository {
  final ApiClient _client;

  TrendsRepository(this._client);

  /// A generic daily-series fetch. [path] is the endpoint, [seriesKey] the
  /// field holding the row array (almost always `daily_series`).
  Future<List<Map<String, dynamic>>?> _fetchDailySeries(
    String path, {
    required int days,
    Map<String, dynamic>? extraQuery,
    String seriesKey = 'daily_series',
  }) async {
    try {
      final resp = await _client.get(
        path,
        queryParameters: {'days': days, ...?extraQuery},
      );
      if (resp.data is! Map) return null;
      final data = Map<String, dynamic>.from(resp.data as Map);
      final raw = data[seriesKey];
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      debugPrint('⚠️ [Trends] $path?days=$days failed: $e');
      return null;
    }
  }

  /// A fetch that returns TWO series from one payload (e.g. cardio's
  /// `daily_series` + `vo2_series`, glucose's `daily_series` + `a1c_series`).
  Future<Map<String, List<Map<String, dynamic>>>?> _fetchMultiSeries(
    String path, {
    required int days,
    required List<String> seriesKeys,
    Map<String, dynamic>? extraQuery,
  }) async {
    try {
      final resp = await _client.get(
        path,
        queryParameters: {'days': days, ...?extraQuery},
      );
      if (resp.data is! Map) return null;
      final data = Map<String, dynamic>.from(resp.data as Map);
      final out = <String, List<Map<String, dynamic>>>{};
      for (final key in seriesKeys) {
        final raw = data[key];
        out[key] = raw is List
            ? raw
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
            : const [];
      }
      return out;
    } catch (e) {
      debugPrint('⚠️ [Trends] $path?days=$days (multi) failed: $e');
      return null;
    }
  }

  // ── Micronutrients ──────────────────────────────────────────────────────

  /// 38 daily micronutrient columns (vitamins, minerals, fatty acids, …).
  Future<List<Map<String, dynamic>>?> getMicrosSummary(
    String userId, {
    required int days,
  }) =>
      _fetchDailySeries(
        '/nutrition/food-patterns/micros-summary/$userId',
        days: days,
      );

  // ── Cardio ──────────────────────────────────────────────────────────────

  /// Cardio session trends. Returns `daily_series` + `vo2_series`.
  Future<Map<String, List<Map<String, dynamic>>>?> getCardioTrends(
    String userId, {
    required int days,
  }) =>
      _fetchMultiSeries(
        '/cardio/sessions/$userId/trends',
        days: days,
        seriesKeys: const ['daily_series', 'vo2_series'],
      );

  // ── Glucose ─────────────────────────────────────────────────────────────

  /// Glucose / insulin trends. Returns `daily_series` + `a1c_series`.
  Future<Map<String, List<Map<String, dynamic>>>?> getGlucoseTrends(
    String userId, {
    required int days,
  }) =>
      _fetchMultiSeries(
        '/diabetes/glucose/$userId/trends',
        days: days,
        seriesKeys: const ['daily_series', 'a1c_series'],
      );

  // ── Workout feedback ────────────────────────────────────────────────────

  /// Post-workout feedback (overall rating, energy, difficulty).
  Future<List<Map<String, dynamic>>?> getFeedbackTrends(
    String userId, {
    required int days,
  }) =>
      _fetchDailySeries('/feedback/user/$userId/trends', days: days);

  // ── Hormonal / cycle ────────────────────────────────────────────────────

  /// Hormonal-health / menstrual-cycle trends. Carries `cycle_phase` and
  /// `period_flow` used by the period event overlay as well as numeric
  /// fields (basal body temp, libido, recovery feeling, …).
  Future<List<Map<String, dynamic>>?> getHormonalTrends(
    String userId, {
    required int days,
  }) =>
      _fetchDailySeries('/hormonal-health/trends/$userId', days: days);

  // ── Flexibility ─────────────────────────────────────────────────────────

  /// Flexibility-test trends (measurement, rating, percentile).
  Future<List<Map<String, dynamic>>?> getFlexibilityTrends(
    String userId, {
    required int days,
  }) =>
      _fetchDailySeries('/flexibility/user/$userId/trends', days: days);

  // ── Habits ──────────────────────────────────────────────────────────────

  /// Habit completion-percentage trend.
  Future<List<Map<String, dynamic>>?> getHabitTrends(
    String userId, {
    required int days,
  }) =>
      _fetchDailySeries('/habits/$userId/trends', days: days);

  // ── Wellbeing ───────────────────────────────────────────────────────────

  /// Wellbeing scores (fitness, readiness, fasting, morning/evening mood …).
  /// NOTE: this endpoint keys the user on a `user_id` query param.
  Future<List<Map<String, dynamic>>?> getWellbeingTrends(
    String userId, {
    required int days,
  }) =>
      _fetchDailySeries(
        '/scores/wellbeing-trends',
        days: days,
        extraQuery: {'user_id': userId},
      );

  // ── NEAT ────────────────────────────────────────────────────────────────

  /// NEAT-score trends (neat score, step-goal %, total steps, active hours).
  Future<List<Map<String, dynamic>>?> getNeatTrends(
    String userId, {
    required int days,
  }) =>
      _fetchDailySeries('/neat/score/$userId/trends', days: days);

  // ── Cardio metric snapshots (Wave-2 SLICE_TRENDS) ───────────────────────

  /// The 13 metric_keys persisted by `cardio_metric_snapshot_job` and read by
  /// the new `/trends/cardio-series` endpoint. Boolean tags
  /// (e.g. is_hill_workout) are deliberately excluded — Wave-1 trends infra
  /// is numeric-only.
  static const Set<String> cardioMetricSnapshotKeys = {
    'race_predicted_5k_sec',
    'race_predicted_10k_sec',
    'race_predicted_half_sec',
    'race_predicted_marathon_sec',
    'training_load_acute',
    'training_load_chronic',
    'training_load_acwr',
    'cardio_weekly_distance_m',
    'cardio_longest_run_m',
    'cardio_fastest_mile_sec',
    'cardio_pace_avg_sec_per_km',
    'cardio_weather_temp_at_run_c',
    'refuel_carbs_recommended_g',
  };

  /// Per-day history for one cardio snapshot metric. Returns `daily_series`
  /// rows of `{date, value}` from `cardio_metric_snapshots`. Returns null on
  /// transport error and an empty list when the user has no logged history.
  Future<List<Map<String, dynamic>>?> getCardioSnapshotSeries({
    required String metricKey,
    required int days,
  }) {
    assert(cardioMetricSnapshotKeys.contains(metricKey),
        'Unknown cardio snapshot metric: $metricKey');
    return _fetchDailySeries(
      '/trends/cardio-series',
      days: days,
      extraQuery: {'metric': metricKey},
    );
  }
}

/// Riverpod provider for [TrendsRepository].
final trendsRepositoryProvider = Provider<TrendsRepository>((ref) {
  return TrendsRepository(ref.watch(apiClientProvider));
});
