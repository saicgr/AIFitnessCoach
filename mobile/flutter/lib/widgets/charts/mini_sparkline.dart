import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Tiny axis-less trend visualisations for stat tiles.
///
/// [MiniSparkline] is a smoothed line with an optional gradient fill;
/// [MiniBars] is a compact bar series. Both are intentionally chrome-free
/// (no grid, axes, border, touch) so they read as a glanceable trend inside
/// a small card — distinct from the full interactive charts on the Stats
/// screen.
///
/// Neither widget fabricates data: pass the real series. With fewer than two
/// points they render an empty placeholder of the requested height so the
/// surrounding layout never reflows.
class MiniSparkline extends StatelessWidget {
  /// The series to plot, oldest → newest. Values are plotted by index.
  final List<double> values;

  /// Line + fill tint. Usually the screen accent.
  final Color color;

  final double height;
  final double strokeWidth;

  /// When true, paints a soft gradient below the line.
  final bool filled;

  const MiniSparkline({
    super.key,
    required this.values,
    required this.color,
    this.height = 36,
    this.strokeWidth = 2,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (values.length < 2) {
      return SizedBox(height: height);
    }

    double minY = values.first;
    double maxY = values.first;
    for (final v in values) {
      if (v < minY) minY = v;
      if (v > maxY) maxY = v;
    }
    // A flat series would collapse to a zero-height line; give it headroom so
    // the stroke stays vertically centred.
    final span = (maxY - minY).abs();
    final pad = span < 1e-9 ? (maxY.abs() * 0.1 + 1) : span * 0.18;

    final spots = <FlSpot>[
      for (var i = 0; i < values.length; i++)
        FlSpot(i.toDouble(), values[i]),
    ];

    return SizedBox(
      height: height,
      child: RepaintBoundary(
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: (values.length - 1).toDouble(),
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
                barWidth: strokeWidth,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: filled,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      color.withValues(alpha: 0.22),
                      color.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact axis-less bar series. The most recent bar is emphasised; earlier
/// bars are dimmed so the eye lands on "now".
class MiniBars extends StatelessWidget {
  final List<double> values;
  final Color color;
  final double height;

  /// Emphasise the final (most recent) bar at full opacity.
  final bool highlightLast;

  const MiniBars({
    super.key,
    required this.values,
    required this.color,
    this.height = 36,
    this.highlightLast = true,
  });

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return SizedBox(height: height);
    }

    double maxY = 0;
    for (final v in values) {
      if (v > maxY) maxY = v;
    }
    final chartMax = maxY > 0 ? maxY * 1.15 : 1.0;
    final last = values.length - 1;

    return SizedBox(
      height: height,
      child: RepaintBoundary(
        child: BarChart(
          BarChartData(
            maxY: chartMax,
            alignment: BarChartAlignment.spaceBetween,
            gridData: const FlGridData(show: false),
            titlesData: const FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            barTouchData: BarTouchData(enabled: false),
            barGroups: [
              for (var i = 0; i < values.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: values[i],
                      color: color.withValues(
                        alpha: (highlightLast && i == last) || !highlightLast
                            ? 0.95
                            : 0.40,
                      ),
                      width: 5,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(2),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
