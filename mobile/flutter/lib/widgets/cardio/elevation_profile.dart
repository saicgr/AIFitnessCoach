import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme/accent_color_provider.dart';
import '../../core/theme/theme_colors.dart';
import 'pace_chart.dart' show CardioChartCard;

/// One altitude sample referenced to the route's cumulative distance.
typedef AltitudeSample = ({double meters, double cumulativeDistanceM});

/// Cumulative-distance elevation profile (filled area chart).
///
/// X = cumulative distance (converted to user's distanceUnit).
/// Y = altitude in meters (always — converting feet/meters is a host concern;
/// most cardio detail UIs render meters here, but unit-agnostic labels make it
/// safe either way).
///
/// Total ascent badge in the top-right sums positive deltas across the series.
/// Card chrome mirrors `_Card` in `pillar_detail_screen.dart:1178`.
class ElevationProfile extends StatelessWidget {
  final List<AltitudeSample> altitudeSeries;
  final String distanceUnit;
  final VoidCallback? onExpand;

  const ElevationProfile({
    super.key,
    required this.altitudeSeries,
    required this.distanceUnit,
    this.onExpand,
  });

  /// Sum of positive altitude deltas across the series, in meters.
  /// Exposed for tests; a flat or descending series returns 0.
  static double totalAscentMeters(List<AltitudeSample> series) {
    if (series.length < 2) return 0;
    double sum = 0;
    for (var i = 1; i < series.length; i++) {
      final d = series[i].meters - series[i - 1].meters;
      if (d > 0) sum += d;
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    if (altitudeSeries.isEmpty) return const SizedBox.shrink();

    final colors = ThemeColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);

    // Convert cumulative distance to display unit.
    final unitDivisor = distanceUnit == 'mi' ? 1609.344 : 1000.0;
    final spots = [
      for (final s in altitudeSeries)
        FlSpot(s.cumulativeDistanceM / unitDivisor, s.meters),
    ];
    final ys = altitudeSeries.map((s) => s.meters).toList();
    final yMin = ys.reduce((a, b) => a < b ? a : b);
    final yMax = ys.reduce((a, b) => a > b ? a : b);
    final pad = ((yMax - yMin).abs() * 0.15).clamp(5.0, 100.0);

    final ascent = totalAscentMeters(altitudeSeries);

    return CardioChartCard(
      title: 'Elevation',
      onExpand: onExpand,
      height: 140,
      trailing: Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '+${ascent.round()} m',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        ),
      ),
      child: LineChart(
        LineChartData(
          minY: yMin - pad,
          maxY: yMax + pad,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.25,
              color: accent,
              barWidth: 1.8,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    accent.withValues(alpha: 0.32),
                    accent.withValues(alpha: 0.02),
                  ],
                ),
              ),
            ),
          ],
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: colors.cardBorder.withValues(alpha: 0.5),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (value, meta) {
                  if (value == meta.min || value == meta.max) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      '${value.round()} m',
                      style:
                          TextStyle(fontSize: 9, color: colors.textMuted),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (value, meta) {
                  if (value == meta.min) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${value.toStringAsFixed(1)} $distanceUnit',
                      style:
                          TextStyle(fontSize: 9, color: colors.textMuted),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
