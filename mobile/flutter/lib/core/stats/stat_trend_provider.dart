import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/trend_series_provider.dart';
import '../../widgets/trends/trend_correlation.dart' show TrendPoint;
import 'stat_trend.dart';

/// Everything a stat tile needs to show a glanceable delta + sparkline for a
/// metric, derived from the app's unified trend engine ([trendSeriesProvider]).
///
/// This is the bridge requested by "integrate custom trends into stats": any
/// tile mapped to a [TrendMetric] gets a real first-vs-last change, the metric's
/// own unit, its [GoodDirection] (for coloring), and the raw points for a
/// [Sparkline] — all from one cache-first source, no per-screen recomputation.
class StatTrendData {
  final List<TrendPoint> points;

  /// First-vs-last change over the window. Null when <2 points (tile then
  /// hides the delta + sparkline rather than fabricate a flat line).
  final StatChange? change;
  final String unit;
  final GoodDirection goodDirection;

  const StatTrendData({
    required this.points,
    required this.change,
    required this.unit,
    required this.goodDirection,
  });

  bool get hasTrend => points.length >= 2 && change != null;
}

/// Derived, cache-first stat-trend data for one (metric, range).
///
/// Usage in a tile:
/// ```dart
/// final t = ref.watch(statTrendProvider(TrendSeriesKey(TrendMetric.bodyFat, TrendRange.d30)));
/// t.maybeWhen(
///   data: (d) => d.hasTrend
///       ? StatDeltaLine(change: d.change!, good: d.goodDirection, unit: d.unit)
///       : const SizedBox.shrink(),
///   orElse: () => const SizedBox.shrink(),
/// );
/// ```
final statTrendProvider = Provider.autoDispose
    .family<AsyncValue<StatTrendData>, TrendSeriesKey>((ref, key) {
  final async = ref.watch(trendSeriesProvider(key));
  return async.whenData(
    (series) => StatTrendData(
      points: series.points,
      change: StatChange.fromPoints(series.points),
      unit: series.unit,
      goodDirection: series.metric.goodDirection,
    ),
  );
});
