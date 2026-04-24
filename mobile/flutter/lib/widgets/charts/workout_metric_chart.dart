import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// A single `(t_seconds, value)` sample.
class MetricSample {
  final double t; // seconds from workout start
  final double v;
  const MetricSample(this.t, this.v);
}

typedef MetricValueFormatter = String Function(double value);

/// Reusable single-series line chart for workout time-series metrics such as
/// speed, pace, cadence, or elevation.
///
/// Callers pass raw `(t, value)` samples in any unit (mps, spm, metres). The
/// chart handles formatting via [formatValue] and tooltips via
/// [formatTooltip]; stat chips at the top show the caller-provided `avg` /
/// `max` strings.
class WorkoutMetricChart extends StatelessWidget {
  final List<MetricSample> samples;
  final String label;
  final Color color;
  final double height;

  /// Summary strings shown above the chart ("Avg 2.31 mph", etc).
  final List<String> stats;

  /// Converts a raw value into the display string for axis / tooltips.
  final MetricValueFormatter formatValue;

  /// Whether lower values are "better" (e.g. pace). Inverts y-axis visuals.
  final bool yAxisInverted;

  const WorkoutMetricChart({
    super.key,
    required this.samples,
    required this.label,
    required this.color,
    required this.stats,
    required this.formatValue,
    this.height = 160,
    this.yAxisInverted = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted =
        isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final gridColor = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04);

    if (samples.length < 2) {
      return _buildEmpty(textMuted);
    }

    final spots = samples.map((s) => FlSpot(s.t, s.v)).toList();
    final maxX = samples.last.t;
    final values = samples.map((s) => s.v).toList();
    final rawMin = values.reduce((a, b) => a < b ? a : b);
    final rawMax = values.reduce((a, b) => a > b ? a : b);
    final pad = ((rawMax - rawMin).abs() * 0.1).clamp(1.0, double.infinity);
    final minY = (rawMin - pad).clamp(0.0, double.infinity);
    final maxY = rawMax + pad;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stat chips
        if (stats.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: stats.map((s) => _statChip(s, color, isDark)).toList(),
            ),
          ),

        SizedBox(
          height: height,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: maxX,
              minY: minY,
              maxY: maxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: gridColor, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 38,
                    getTitlesWidget: (value, meta) {
                      if (value == minY || value == maxY) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Text(
                          formatValue(value),
                          style: TextStyle(
                              fontSize: 10, color: textMuted),
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval: _timeInterval(maxX),
                    getTitlesWidget: (value, meta) {
                      if (value == 0 || value == maxX) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _formatTime(value),
                          style: TextStyle(
                              fontSize: 10, color: textMuted),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) =>
                      (isDark ? Colors.black : Colors.white).withValues(alpha: 0.9),
                  tooltipBorder: BorderSide(
                    color: color.withValues(alpha: 0.4),
                    width: 1,
                  ),
                  tooltipRoundedRadius: 8,
                  getTooltipItems: (touched) => touched.map((t) {
                    return LineTooltipItem(
                      'at ${_formatTime(t.x)}\n${formatValue(t.y)} $label',
                      TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    );
                  }).toList(),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.3,
                  color: color,
                  barWidth: 2.2,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        color.withValues(alpha: 0.30),
                        color.withValues(alpha: 0.02),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty(Color textMuted) {
    return SizedBox(
      height: height,
      child: Center(
        child: Text(
          'Not enough $label data to chart.',
          style: TextStyle(fontSize: 12, color: textMuted),
        ),
      ),
    );
  }

  Widget _statChip(String text, Color fg, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }

  double _timeInterval(double maxX) {
    if (maxX <= 300) return 60;       // 5 min → 1-min ticks
    if (maxX <= 1800) return 300;     // 30 min → 5-min ticks
    if (maxX <= 3600) return 600;     // 1 h → 10-min ticks
    return 1800;                       // longer → 30-min ticks
  }

  String _formatTime(double secondsFromStart) {
    final s = secondsFromStart.toInt();
    final m = s ~/ 60;
    final sec = s % 60;
    return '$m:${sec.toString().padLeft(2, '0')}';
  }
}
