/// Composes a display-ready [MetricValue] for any home metric ([RingKind])
/// from the app's existing live providers (today-score, activity, sleep,
/// nutrition, hydration, readiness, weight/body trends). Hot-path, cache-first,
/// deterministic — no RAG, no network of its own. Presentation widgets watch
/// `metricValueProvider(kind)` and never touch the source providers directly.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/metric_value.dart';
import '../models/today_score.dart';
import '../repositories/hydration_repository.dart';
import '../repositories/nutrition_repository.dart';
import '../services/health_service.dart';
import '../../screens/home/widgets/cards/readiness_score_card.dart'
    show readinessScoreSignalProvider;
import '../../screens/home/widgets/cards/sleep_latency_tile.dart'
    show sleepLatencySignalProvider;
import '../../screens/home/widgets/cards/wake_consistency_tile.dart'
    show wakeConsistencySignalProvider;
import '../../screens/home/widgets/cards/bedtime_window_tile.dart'
    show bedtimeWindowSignalProvider;
import '../../screens/home/widgets/cards/vo2max_trend_chip.dart'
    show vo2maxTrendSignalProvider;
import '../../screens/home/widgets/cards/zone_minutes_bar.dart'
    show zoneMinutesSignalProvider;
import '../../screens/home/widgets/cards/step_streak_tile.dart'
    show stepStreakSignalProvider;
import 'mindfulness_provider.dart' show mindfulnessTodayProvider;
import '../../screens/home/widgets/ring_catalog.dart';
import 'metric_layout_provider.dart';
import 'nutrition_preferences_provider.dart';
import 'sleep_score_provider.dart';
import 'today_score_provider.dart';
import 'trend_series_provider.dart';

const double _mlPerOz = 29.5735;

/// Maps a home metric to its trend series (for sparkline/line tiles), or null
/// when no trend series fits. Public so the home deck can deep-link a tile to
/// the custom-trend screen pre-seeded with that metric.
TrendMetric? trendMetricForRing(RingKind kind) => _trendMetricFor(kind);

TrendMetric? _trendMetricFor(RingKind kind) {
  switch (kind) {
    case RingKind.move:
      return TrendMetric.steps;
    case RingKind.weight:
      return TrendMetric.weight;
    case RingKind.heartRate:
      return TrendMetric.restingHeartRate;
    case RingKind.nourish:
      return TrendMetric.calories;
    case RingKind.sleep:
      return TrendMetric.sleepHours;
    case RingKind.hydration:
      return TrendMetric.water;
    case RingKind.recovery:
      return TrendMetric.readinessScore;
    case RingKind.vo2max:
      return TrendMetric.vo2Max;
    case RingKind.bodyFat:
      return TrendMetric.bodyFat;
    case RingKind.cardioDistance:
      return TrendMetric.cardioDistance;
    case RingKind.train:
    case RingKind.hrv:
    case RingKind.stress:
    case RingKind.cycle:
    case RingKind.sleepLatency:
    case RingKind.wakeConsistency:
    case RingKind.bedtimeWindow:
    case RingKind.activeEnergy:
    case RingKind.protein:
    case RingKind.zoneMinutes:
    case RingKind.mindfulMinutes:
    case RingKind.stepStreak:
      return null;
  }
}

TrendRange _trendRangeFor(MetricRange r) {
  switch (r) {
    case MetricRange.d7:
      return TrendRange.d7;
    case MetricRange.d30:
      return TrendRange.d30;
    case MetricRange.d90:
      return TrendRange.d90;
    case MetricRange.y1:
      return TrendRange.y1;
  }
}

/// Normalises a trend series into 0..1 sparkline points (x by index, y by
/// min/max). Returns null when there are <2 real points.
List<MetricSpark>? _sparkFrom(TrendSeries? series) {
  if (series == null) return null;
  final pts = [for (final p in series.points) p.value];
  if (pts.length < 2) return null;
  final lo = pts.reduce((a, b) => a < b ? a : b);
  final hi = pts.reduce((a, b) => a > b ? a : b);
  final span = hi - lo;
  final n = pts.length;
  return [
    for (var i = 0; i < n; i++)
      MetricSpark(i / (n - 1), span == 0 ? 0.5 : (pts[i] - lo) / span),
  ];
}

String _fmtDuration(int minutes) {
  if (minutes <= 0) return '0m';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return '${m}m';
  if (m == 0) return '${h}h';
  return '${h}h ${m}m';
}

/// Display-ready value for a single home metric, recomputed when any of its
/// source providers change.
final metricValueProvider = Provider.family<MetricValue, RingKind>((ref, kind) {
  final layout = ref.watch(metricLayoutProvider.notifier).configFor(kind);
  final Color color = layout.colorOverride != null
      ? Color(layout.colorOverride!)
      : kind.color;
  final String label = kind.label;
  final String id = kind.id;

  // Sparkline (best-effort) for line/area tiles.
  List<MetricSpark>? series;
  final tm = _trendMetricFor(kind);
  if (tm != null &&
      (layout.chart == MetricChart.line || layout.chart == MetricChart.area)) {
    final s = ref
        .watch(
          trendSeriesProvider(TrendSeriesKey(tm, _trendRangeFor(layout.range))),
        )
        .valueOrNull;
    series = _sparkFrom(s);
  }

  MetricValue base({
    double? value,
    String? displayValue,
    String unit = '',
    double? goal,
    double? pct,
    String? deltaLabel,
    bool empty = false,
  }) => MetricValue(
    id: id,
    label: label,
    unit: unit,
    color: color,
    value: value,
    displayValue: displayValue,
    goal: goal,
    pct: pct,
    deltaLabel: deltaLabel,
    series: series,
    isEmpty: empty,
  );

  switch (kind) {
    case RingKind.train:
      {
        final c = ref
            .watch(todayScoreProvider)
            .contributor(ContributorKind.train);
        if (!c.applicable) {
          return base(displayValue: 'Rest', unit: '', empty: false, pct: 0);
        }
        return base(
          displayValue: '${(c.completion * 100).round()}%',
          pct: c.completion,
          deltaLabel: c.statusText,
        );
      }
    case RingKind.nourish:
      {
        final summary = ref.watch(dailyNutritionProvider(todayNutritionKey())).summary;
        final goal = ref
            .watch(nutritionPreferencesProvider)
            .currentCalorieTarget;
        final cals = summary?.totalCalories;
        if (cals == null) return base(empty: true, unit: 'kcal');
        final hasGoal = (goal ?? 0) > 0;
        final pct = hasGoal ? (cals / goal!).clamp(0.0, 1.0) : null;
        return base(
          value: cals.toDouble(),
          unit: 'kcal',
          goal: goal?.toDouble(),
          pct: pct,
          deltaLabel: hasGoal
              ? '${((pct ?? 0) * 100).round()}% of $goal'
              : null,
        );
      }
    case RingKind.move:
      {
        final steps = ref.watch(dailyActivityProvider).today?.steps;
        if (steps == null) return base(empty: true, unit: 'steps');
        const goal = 10000.0;
        return base(
          value: steps.toDouble(),
          unit: 'steps',
          goal: goal,
          pct: (steps / goal).clamp(0.0, 1.0),
          deltaLabel: 'of 10k',
        );
      }
    case RingKind.sleep:
      {
        final snap = ref.watch(sleepScoreProvider).valueOrNull;
        if (snap == null || !snap.hasData) return base(empty: true);
        final mins = snap.summary.totalMinutes;
        final score = snap.score?.total;
        return base(
          displayValue: _fmtDuration(mins),
          pct: score != null ? (score / 100).clamp(0.0, 1.0) : null,
          deltaLabel: score != null ? '$score · score' : null,
        );
      }
    case RingKind.hydration:
      {
        final s = ref.watch(hydrationProvider).todaySummary;
        if (s == null) return base(empty: true, unit: 'oz');
        final oz = s.totalMl / _mlPerOz;
        final goalOz = s.goalMl / _mlPerOz;
        return base(
          value: oz,
          displayValue: oz.round().toString(),
          unit: 'oz',
          goal: goalOz,
          pct: (s.goalPercentage / 100).clamp(0.0, 1.0),
          deltaLabel: s.goalMl > 0 ? 'of ${goalOz.round()} oz' : null,
        );
      }
    case RingKind.heartRate:
      {
        final hr = ref.watch(dailyActivityProvider).today?.restingHeartRate;
        if (hr == null) return base(empty: true, unit: 'bpm');
        return base(value: hr.toDouble(), unit: 'bpm');
      }
    case RingKind.recovery:
      {
        final r = ref.watch(readinessScoreSignalProvider);
        if (r == null) return base(empty: true);
        return base(value: r.toDouble(), pct: (r / 100).clamp(0.0, 1.0));
      }
    case RingKind.weight:
      {
        final s = ref
            .watch(
              trendSeriesProvider(
                TrendSeriesKey(
                  TrendMetric.weight,
                  _trendRangeFor(layout.range),
                ),
              ),
            )
            .valueOrNull;
        final pts = s?.points;
        if (pts == null || pts.isEmpty) return base(empty: true, unit: 'lb');
        final last = pts.last.value;
        String? delta;
        if (pts.length >= 2) {
          final d = last - pts.first.value;
          delta = '${d >= 0 ? '↑' : '↓'} ${d.abs().toStringAsFixed(1)}';
        }
        return base(
          value: last,
          displayValue: last.toStringAsFixed(1),
          unit: 'lb',
          deltaLabel: delta,
        );
      }
    case RingKind.sleepLatency:
      {
        final lat = ref.watch(sleepLatencySignalProvider);
        if (lat == null) return base(empty: true, unit: 'min');
        return base(value: lat.toDouble(), unit: 'min');
      }
    case RingKind.wakeConsistency:
      {
        final w = ref.watch(wakeConsistencySignalProvider);
        if (w.stddevMinutes == null) return base(empty: true, unit: 'min');
        return base(
          displayValue: '±${w.stddevMinutes!.round()}',
          unit: 'min',
          deltaLabel: w.meanWake != null ? 'avg ${w.meanWake}' : null,
        );
      }
    case RingKind.bedtimeWindow:
      {
        final bw = ref.watch(bedtimeWindowSignalProvider);
        if (bw.windowStart == null || bw.windowEnd == null) {
          return base(empty: true);
        }
        return base(displayValue: '${bw.windowStart} – ${bw.windowEnd}');
      }
    case RingKind.vo2max:
      {
        final v = ref.watch(vo2maxTrendSignalProvider);
        if (v.latest == null) return base(empty: true, unit: 'ml/kg/min');
        final d = v.previous != null ? v.latest! - v.previous! : null;
        return base(
          value: v.latest,
          displayValue: v.latest!.toStringAsFixed(1),
          unit: 'ml/kg/min',
          deltaLabel: d == null
              ? null
              : '${d >= 0 ? '↑' : '↓'} ${d.abs().toStringAsFixed(1)}',
        );
      }
    case RingKind.activeEnergy:
      {
        final kcal = ref.watch(dailyActivityProvider).today?.caloriesBurned;
        if (kcal == null || kcal <= 0) return base(empty: true, unit: 'kcal');
        return base(value: kcal, unit: 'kcal');
      }
    case RingKind.protein:
      {
        final eaten = ref.watch(dailyNutritionProvider(todayNutritionKey())).summary?.totalProteinG;
        final goal =
            ref.watch(nutritionPreferencesProvider).currentProteinTarget;
        if (eaten == null) return base(empty: true, unit: 'g');
        final hasGoal = (goal ?? 0) > 0;
        final pct = hasGoal ? (eaten / goal!).clamp(0.0, 1.0) : null;
        return base(
          value: eaten.toDouble(),
          unit: 'g',
          goal: goal?.toDouble(),
          pct: pct,
          deltaLabel: hasGoal ? 'of ${goal}g' : null,
        );
      }
    case RingKind.zoneMinutes:
      {
        final z = ref.watch(zoneMinutesSignalProvider);
        if (z.moderateMinutes == null && z.vigorousMinutes == null) {
          return base(empty: true, unit: 'min');
        }
        // WHO equivalence: 1 vigorous min counts as 2 moderate min.
        final effective =
            (z.moderateMinutes ?? 0) + 2 * (z.vigorousMinutes ?? 0);
        const weeklyGoal = 150.0;
        return base(
          value: effective.toDouble(),
          unit: 'min',
          goal: weeklyGoal,
          pct: (effective / weeklyGoal).clamp(0.0, 1.0),
          deltaLabel: 'of 150 / wk',
        );
      }
    case RingKind.mindfulMinutes:
      {
        final m = ref.watch(mindfulnessTodayProvider).valueOrNull;
        if (m == null) return base(empty: true, unit: 'min');
        final pct =
            m.targetMinutes > 0 ? (m.minutes / m.targetMinutes).clamp(0.0, 1.0) : null;
        return base(
          value: m.minutes.toDouble(),
          unit: 'min',
          goal: m.targetMinutes.toDouble(),
          pct: pct,
          deltaLabel: m.targetMinutes > 0 ? 'of ${m.targetMinutes} min' : null,
        );
      }
    case RingKind.stepStreak:
      {
        final s = ref.watch(stepStreakSignalProvider);
        if (s.streakDays == null) return base(empty: true, unit: 'days');
        final pct = (s.goal > 0 && s.todaySteps != null)
            ? (s.todaySteps! / s.goal).clamp(0.0, 1.0)
            : null;
        return base(
          value: s.streakDays!.toDouble(),
          unit: s.streakDays == 1 ? 'day' : 'days',
          pct: pct,
          deltaLabel: s.todaySteps != null ? '${s.todaySteps} today' : null,
        );
      }
    case RingKind.bodyFat:
      {
        final pts = ref
            .watch(trendSeriesProvider(
              TrendSeriesKey(TrendMetric.bodyFat, _trendRangeFor(layout.range)),
            ))
            .valueOrNull
            ?.points;
        if (pts == null || pts.isEmpty) return base(empty: true, unit: '%');
        final last = pts.last.value;
        String? delta;
        if (pts.length >= 2) {
          final d = last - pts.first.value;
          delta = '${d >= 0 ? '↑' : '↓'} ${d.abs().toStringAsFixed(1)}';
        }
        return base(
          value: last,
          displayValue: last.toStringAsFixed(1),
          unit: '%',
          deltaLabel: delta,
        );
      }
    case RingKind.cardioDistance:
      {
        final pts = ref
            .watch(trendSeriesProvider(
              TrendSeriesKey(
                  TrendMetric.cardioDistance, _trendRangeFor(layout.range)),
            ))
            .valueOrNull
            ?.points;
        if (pts == null || pts.isEmpty) return base(empty: true, unit: 'km');
        final last = pts.last.value;
        return base(
          value: last,
          displayValue: last.toStringAsFixed(1),
          unit: 'km',
        );
      }
    case RingKind.hrv:
    case RingKind.stress:
    case RingKind.cycle:
      // Surfaced only when the user adds them and data exists; otherwise empty.
      return base(empty: true);
  }
});
