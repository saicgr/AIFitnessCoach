import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/stat_typography.dart';
import '../../widgets/trends/trend_correlation.dart' show TrendPoint, ewmaPoints;

/// Generic trend math + presentation for the "glanceable stats" redesign.
///
/// A big number is only half of what makes the reference screen readable — the
/// other half is the small line under it ("0.6 kg lost over period"), the trend
/// arrow, and the mini sparkline. This file centralises that so every stat
/// tile (built-in metrics, the trend engine, personal goals, user-defined
/// custom metrics) computes change + direction + color the same way, instead
/// of each screen re-deriving it (it was duplicated in `_getTrend`,
/// `measurement_tile_grid`, `reports_adapter`, ...).
///
/// Nothing here is hardcoded per metric: callers pass the metric's
/// [GoodDirection] (which way is "good"), so a custom metric whose direction is
/// unknown simply uses [GoodDirection.neutral] and shows a factual arrow with
/// no green/red judgment.

/// Which way is "good" for a metric. `lower` = a decrease is an improvement
/// (weight cut, resting HR, body fat); `higher` = an increase is (1RM, steps);
/// `neutral` = we don't judge (a user-defined metric with no stated direction).
enum GoodDirection { higher, lower, neutral }

/// The factual direction of a change, independent of whether it's "good".
enum TrendDirection { up, down, flat }

/// A computed change between two points in a metric's series.
class StatChange {
  /// Signed `current - previous`, in the metric's display unit.
  final double diff;

  /// Percent change vs the earlier value; null when the earlier value is ~0.
  final double? percent;
  final TrendDirection direction;

  const StatChange({
    required this.diff,
    required this.percent,
    required this.direction,
  });

  bool get isFlat => direction == TrendDirection.flat;
  double get absDiff => diff.abs();

  /// Computes the change between [previous] and [current]. Returns null when
  /// either side is missing — callers hide the delta rather than fabricate one.
  ///
  /// [threshold] is the minimum absolute change to count as movement; anything
  /// smaller reads as [TrendDirection.flat] (kills body-weight water-noise
  /// flicker, matching the old `_getTrend` 0.1 default behaviour).
  static StatChange? compute(
    double? current,
    double? previous, {
    double threshold = 0.05,
  }) {
    if (current == null || previous == null) return null;
    final diff = current - previous;
    final TrendDirection dir;
    if (diff.abs() < threshold) {
      dir = TrendDirection.flat;
    } else {
      dir = diff > 0 ? TrendDirection.up : TrendDirection.down;
    }
    final pct = previous.abs() < 1e-9 ? null : (diff / previous.abs()) * 100;
    return StatChange(diff: diff, percent: pct, direction: dir);
  }

  /// First-vs-last change across a time series. Returns null for <2 points so
  /// the UI hides the delta + sparkline instead of inventing a flat line.
  static StatChange? fromPoints(
    List<TrendPoint> points, {
    double threshold = 0.05,
  }) {
    if (points.length < 2) return null;
    return compute(points.last.value, points.first.value, threshold: threshold);
  }
}

/// Trend helpers that need a [BuildContext] (theme-aware colors).
class StatTrend {
  StatTrend._();

  static bool _isDark(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark;

  static Color _success(BuildContext c) =>
      _isDark(c) ? AppColors.success : AppColorsLight.success;
  static Color _error(BuildContext c) =>
      _isDark(c) ? AppColors.error : AppColorsLight.error;
  static Color _muted(BuildContext c) =>
      _isDark(c) ? AppColors.textMuted : AppColorsLight.textMuted;

  /// Resolves the color for a change given which direction is good.
  /// Flat or neutral-goodness → muted (no judgment); good → success; bad → error.
  static Color color(
    BuildContext context,
    TrendDirection dir,
    GoodDirection good,
  ) {
    if (dir == TrendDirection.flat || good == GoodDirection.neutral) {
      return _muted(context);
    }
    final isGood =
        good == GoodDirection.higher ? dir == TrendDirection.up : dir == TrendDirection.down;
    return isGood ? _success(context) : _error(context);
  }

  static IconData icon(TrendDirection dir) {
    switch (dir) {
      case TrendDirection.up:
        return Icons.trending_up_rounded;
      case TrendDirection.down:
        return Icons.trending_down_rounded;
      case TrendDirection.flat:
        return Icons.trending_flat_rounded;
    }
  }

  /// Formats a number for copy: drops a trailing `.0`, keeps one decimal for
  /// small fractional values, thousands-separates large integers.
  static String fmt(double v) {
    final a = v.abs();
    if (a >= 1000) {
      final s = a.round().toString();
      final buf = StringBuffer();
      for (var i = 0; i < s.length; i++) {
        if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
        buf.write(s[i]);
      }
      return buf.toString();
    }
    if (a == a.roundToDouble()) return a.round().toString();
    return a.toStringAsFixed(1);
  }

  /// A short, human, non-robotic change line (the reference's subtitle).
  /// Picks from a variant pool keyed deterministically off the value so two
  /// adjacent tiles don't read identically, but the same value is stable.
  /// No em dashes (marketing/voice rule).
  static String plainLanguage(
    StatChange change, {
    String unit = '',
    String period = 'over period',
  }) {
    final v = fmt(change.absDiff);
    final u = unit.isEmpty ? '' : ' $unit';
    final seed = (change.absDiff * 100).round();
    List<String> pool;
    switch (change.direction) {
      case TrendDirection.up:
        pool = [
          'up $v$u $period',
          '+$v$u $period',
          '$v$u higher $period',
          'climbed $v$u $period',
        ];
        break;
      case TrendDirection.down:
        pool = [
          'down $v$u $period',
          '$v$u lower $period',
          'dropped $v$u $period',
          'off $v$u $period',
        ];
        break;
      case TrendDirection.flat:
        pool = [
          'holding steady $period',
          'no change $period',
          'flat $period',
          'unchanged $period',
        ];
        break;
    }
    return pool[seed % pool.length];
  }
}

/// The reference's subtitle: a colored arrow + plain-language change line.
/// Render only when [change] is non-null (caller hides it otherwise).
class StatDeltaLine extends StatelessWidget {
  final StatChange change;
  final GoodDirection good;
  final String unit;
  final String period;
  final double fontSize;

  const StatDeltaLine({
    super.key,
    required this.change,
    this.good = GoodDirection.neutral,
    this.unit = '',
    this.period = 'over period',
    this.fontSize = StatType.labelSm,
  });

  @override
  Widget build(BuildContext context) {
    final color = StatTrend.color(context, change.direction, good);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(StatTrend.icon(change.direction), size: fontSize + 3, color: color),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            StatTrend.plainLanguage(change, unit: unit, period: period),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

/// Compact trend pill for tight rows: arrow + percent (falls back to abs diff).
class StatTrendChip extends StatelessWidget {
  final StatChange change;
  final GoodDirection good;
  final String unit;

  const StatTrendChip({
    super.key,
    required this.change,
    this.good = GoodDirection.neutral,
    this.unit = '',
  });

  @override
  Widget build(BuildContext context) {
    if (change.isFlat) return const SizedBox.shrink();
    final color = StatTrend.color(context, change.direction, good);
    final label = change.percent != null
        ? '${StatTrend.fmt(change.percent!)}%'
        : '${StatTrend.fmt(change.absDiff)}${unit.isEmpty ? '' : ' $unit'}';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(StatTrend.icon(change.direction), size: 13, color: color),
        const SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// A lightweight inline sparkline (no axes, grid, or labels). For a quick
/// visual trend beside a number, the way the reference shows a mini graph.
///
/// Renders nothing when there are fewer than 2 points (never a fabricated
/// flat line — honors the no-silent-fallback rule).
class Sparkline extends StatelessWidget {
  final List<TrendPoint> points;
  final Color color;
  final double height;
  final bool showLastDot;

  /// Smooth with EWMA so the line reads as a trend, not jagged daily noise.
  final bool smooth;

  const Sparkline({
    super.key,
    required this.points,
    required this.color,
    this.height = 36,
    this.showLastDot = true,
    this.smooth = true,
  });

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) return SizedBox(height: height);

    final series = smooth ? ewmaPoints(points) : points;
    final values = series.map((p) => p.value).toList();
    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    // Pad a flat-ish range so the line isn't pinned to an edge.
    final span = (maxY - minY).abs();
    final pad = span < 1e-6 ? 1.0 : span * 0.15;

    final spots = <FlSpot>[
      for (var i = 0; i < series.length; i++)
        FlSpot(i.toDouble(), series[i].value),
    ];

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: minY - pad,
          maxY: maxY + pad,
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: color,
              barWidth: 2,
              dotData: FlDotData(
                show: showLastDot,
                checkToShowDot: (spot, _) => spot.x == spots.last.x,
                getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                  radius: 2.5,
                  color: color,
                  strokeWidth: 0,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: color.withValues(alpha: 0.10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
