// Tests for the Wave-2 cardio metric-snapshot registration in TrendMetric.
//
// These are pure registry tests — they do NOT exercise the network fetcher.
// They guarantee that:
//   * All 13 metric_keys are registered in [TrendMetric].
//   * Each registered metric belongs to the Cardio category (so it surfaces
//     under that section in the picker).
//   * Each registered metric is wired to [TrendSource.cardioMetricSnapshot]
//     (so the fetch switch routes it through the new endpoint).
//   * The repository allowlist [TrendsRepository.cardioMetricSnapshotKeys]
//     exactly matches the set of `metric_key`s used by the enum entries.

import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/data/providers/trend_series_provider.dart';
import 'package:fitwiz/data/repositories/trends_repository.dart';

void main() {
  // The 13 metric_keys must be IDENTICAL to the backend's
  // REGISTERED_METRIC_KEYS in cardio_metric_snapshot_job.py.
  const expectedKeys = <String>{
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

  group('Cardio metric-snapshot Custom Trends registration', () {
    final cardioSnapshotMetrics = TrendMetric.values
        .where((m) => m.source == TrendSource.cardioMetricSnapshot)
        .toList();

    test('exactly 13 cardio snapshot metrics are registered', () {
      expect(cardioSnapshotMetrics.length, 13);
    });

    test('every registered metric uses TrendCategory.cardio', () {
      for (final m in cardioSnapshotMetrics) {
        expect(m.category, TrendCategory.cardio,
            reason: '${m.name} must surface under Cardio category');
      }
    });

    test('every registered metric carries a metric_key', () {
      for (final m in cardioSnapshotMetrics) {
        expect(m.metricKey, isNotNull,
            reason: '${m.name} must declare metric_key');
        expect(m.metricKey!.isNotEmpty, isTrue);
      }
    });

    test('registered metric_keys match the backend allowlist exactly', () {
      final actual = cardioSnapshotMetrics.map((m) => m.metricKey!).toSet();
      expect(actual, expectedKeys);
    });

    test('repository allowlist matches the enum metric_keys', () {
      expect(TrendsRepository.cardioMetricSnapshotKeys, expectedKeys);
    });

    test('every registered metric declares a unit override', () {
      for (final m in cardioSnapshotMetrics) {
        expect(m.unitOverride, isNotNull,
            reason: '${m.name} must declare a unit');
      }
    });
  });
}
