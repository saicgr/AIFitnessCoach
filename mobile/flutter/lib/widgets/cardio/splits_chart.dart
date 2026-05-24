import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme/accent_color_provider.dart';
import '../../core/theme/theme_colors.dart';
import 'pace_chart.dart' show CardioChartCard, PaceChart;

/// One completed lap/split (per km or per mi).
typedef SplitSample = ({int kmOrMiIndex, int durationSec, double distanceM});

/// Bar chart of per-unit splits with average pace overlay.
///
/// Bar color = AccentColorScope primary. Faster-than-avg splits get a green
/// tint; slower get a red tint. The overlay line is the average pace.
/// Card chrome mirrors `_Card` in `pillar_detail_screen.dart:1178`.
class SplitsChart extends StatelessWidget {
  final List<SplitSample> splits;
  final String distanceUnit;
  final VoidCallback? onExpand;

  const SplitsChart({
    super.key,
    required this.splits,
    required this.distanceUnit,
    this.onExpand,
  });

  /// Per-unit pace (sec/unit) for a split. Splits shorter than ~1 unit are
  /// scaled to a per-unit pace via `durationSec * unit / distance` so they
  /// remain comparable to full splits. Exposed for tests.
  static double splitPaceSecPerUnit(SplitSample s, String unit) {
    if (s.distanceM <= 0) return 0;
    final unitMeters = unit == 'mi' ? 1609.344 : 1000.0;
    return s.durationSec * unitMeters / s.distanceM;
  }

  /// Tints [base] toward green when [pace] is faster than [avg], toward red
  /// when slower. Magnitude scales with relative deviation, capped at ±20%.
  /// Faster pace = LOWER sec/unit. Exposed for tests.
  static Color tintForPace({
    required Color base,
    required double pace,
    required double avg,
  }) {
    if (avg <= 0 || pace <= 0) return base;
    final delta = (pace - avg) / avg; // <0 faster, >0 slower
    final clamped = delta.clamp(-0.2, 0.2);
    final t = (clamped.abs() / 0.2).clamp(0.0, 1.0);
    final target = clamped < 0
        ? const Color(0xFF22C55E) // green-500
        : const Color(0xFFEF4444); // red-500
    return Color.lerp(base, target, t * 0.55)!;
  }

  @override
  Widget build(BuildContext context) {
    // Need at least one full unit of distance to render meaningful per-unit
    // splits. A 0.4 mi jog has nothing to chart here.
    final unitMeters = distanceUnit == 'mi' ? 1609.344 : 1000.0;
    final totalDistance =
        splits.fold<double>(0, (acc, s) => acc + s.distanceM);
    if (totalDistance < unitMeters) return const SizedBox.shrink();
    if (splits.isEmpty) return const SizedBox.shrink();

    final colors = ThemeColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);

    final paces = splits
        .map((s) => splitPaceSecPerUnit(s, distanceUnit))
        .toList();
    final avg = paces.reduce((a, b) => a + b) / paces.length;
    final maxPace = paces.reduce((a, b) => a > b ? a : b);
    final minPace = paces.reduce((a, b) => a < b ? a : b);
    final pad = ((maxPace - minPace).abs() * 0.18).clamp(10.0, 90.0);

    final barGroups = <BarChartGroupData>[];
    for (var i = 0; i < splits.length; i++) {
      final color = tintForPace(base: accent, pace: paces[i], avg: avg);
      barGroups.add(
        BarChartGroupData(
          x: splits[i].kmOrMiIndex,
          barRods: [
            BarChartRodData(
              toY: paces[i],
              color: color,
              width: 18,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(6),
                bottom: Radius.zero,
              ),
            ),
          ],
        ),
      );
    }

    return CardioChartCard(
      title: 'Splits',
      onExpand: onExpand,
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          minY: (minPace - pad).clamp(0, double.infinity),
          maxY: maxPace + pad,
          barGroups: barGroups,
          // Average-pace reference line overlaid on the bar chart.
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: avg,
                color: colors.textMuted.withValues(alpha: 0.7),
                strokeWidth: 1.2,
                dashArray: const [5, 4],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  padding: const EdgeInsets.only(right: 4, bottom: 2),
                  style: TextStyle(
                    fontSize: 9,
                    color: colors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                  labelResolver: (_) =>
                      'avg ${PaceChart.formatPace(avg)}/$distanceUnit',
                ),
              ),
            ],
          ),
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
                reservedSize: 48,
                getTitlesWidget: (value, meta) {
                  if (value == meta.min || value == meta.max) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      PaceChart.formatPace(value),
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
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${value.toInt()}',
                      style:
                          TextStyle(fontSize: 9, color: colors.textMuted),
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              tooltipRoundedRadius: 8,
              getTooltipColor: (_) => colors.elevated,
              tooltipBorder: BorderSide(color: colors.cardBorder),
              getTooltipItem: (group, groupIdx, rod, rodIdx) {
                return BarTooltipItem(
                  '#${group.x}  ${PaceChart.formatPace(rod.toY)}/$distanceUnit',
                  TextStyle(
                    color: colors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
