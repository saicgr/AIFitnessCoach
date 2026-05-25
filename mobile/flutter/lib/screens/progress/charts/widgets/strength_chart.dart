import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../data/models/progress_charts.dart';

import '../../../../l10n/generated/app_localizations.dart';
/// Strength Trends — multi-series line chart of strength progression per
/// muscle group.
///
/// This chart is kept bespoke (NOT migrated to the shared [TrendChart])
/// because TrendChart only models a primary + single secondary series, while
/// strength progression plots up to five muscle groups at once. It is themed
/// via [ThemeColors] and keeps an interactive touch tooltip so it still feels
/// consistent with the rest of the Trends system (Phase G5a/G5c).
class StrengthChart extends ConsumerWidget {
  final StrengthProgressionData data;

  const StrengthChart({super.key, required this.data});

  /// Distinct hues for the muscle-group series. These are deliberately
  /// multi-colour (one per series) — a monochrome accent can't disambiguate
  /// five overlapping lines.
  static const List<Color> _muscleColors = [
    Color(0xFF3B82F6), // blue
    Color(0xFF22C55E), // green
    Color(0xFFF97316), // orange
    Color(0xFFA855F7), // purple
    Color(0xFFEF4444), // red
    Color(0xFF14B8A6), // teal
    Color(0xFFEC4899), // pink
    Color(0xFF6366F1), // indigo
    Color(0xFFF59E0B), // amber
    Color(0xFF06B6D4), // cyan
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.colors(context);

    if (data.data.isEmpty) {
      return const SizedBox.shrink();
    }

    // Get unique muscle groups and their data
    final muscleGroups = data.muscleGroups.take(5).toList(); // Limit to 5
    final sortedWeeks = data.sortedWeeks;

    if (sortedWeeks.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculate max volume for Y axis
    double maxVolume = 0;
    for (final entry in data.data) {
      if (entry.totalVolumeKg > maxVolume) {
        maxVolume = entry.totalVolumeKg;
      }
    }
    // Floor to ≥ 1.0 — fl_chart's iterateThroughAxis divides by the tick
    // interval, which is 0 when yMax is 0 ("Infinity or NaN toInt").
    final yMax = ((maxVolume * 1.2).ceilToDouble()).clamp(1.0, double.infinity);

    // Build line data for each muscle group
    final lineBarsData = <LineChartBarData>[];
    for (int i = 0; i < muscleGroups.length; i++) {
      final muscleGroup = muscleGroups[i];
      final muscleData = data.getDataForMuscleGroup(muscleGroup);
      final color = _muscleColors[i % _muscleColors.length];

      // Create spots for this muscle group
      final spots = <FlSpot>[];
      for (int weekIndex = 0; weekIndex < sortedWeeks.length; weekIndex++) {
        final week = sortedWeeks[weekIndex];
        final weekData = muscleData.where((d) => d.weekStart == week).toList();
        if (weekData.isNotEmpty) {
          spots.add(FlSpot(
            weekIndex.toDouble(),
            weekData.first.totalVolumeKg,
          ));
        }
      }

      if (spots.isNotEmpty) {
        lineBarsData.add(
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                radius: 4,
                color: color,
                strokeWidth: 2,
                strokeColor: colors.background,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.1),
            ),
          ),
        );
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart, color: colors.accent),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).strengthChartStrengthTrends,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            // Isolate the chart's painting layer so it doesn't re-rasterize
            // every time the surrounding scroll view paints a new pixel.
            child: RepaintBoundary(
              child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => colors.elevated,
                    tooltipBorder: BorderSide(color: colors.cardBorder),
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipMargin: 8,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final muscleGroup =
                            muscleGroups[spot.barIndex % muscleGroups.length];
                        return LineTooltipItem(
                          '${_formatMuscleGroup(muscleGroup)}\n${spot.y.toStringAsFixed(0)} kg',
                          TextStyle(
                            color: _muscleColors[
                                spot.barIndex % _muscleColors.length],
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: yMax > 0 ? yMax / 4 : 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: colors.cardBorder.withValues(alpha: 0.5),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= sortedWeeks.length) {
                          return const SizedBox.shrink();
                        }
                        // Show every nth label to avoid crowding
                        final showEvery = sortedWeeks.length > 8 ? 2 : 1;
                        if (index % showEvery != 0) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _formatWeekLabel(sortedWeeks[index]),
                            style: TextStyle(
                              color: colors.textMuted,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                      reservedSize: 32,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.max || value == meta.min) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            _formatYLabel(value),
                            style: TextStyle(
                              color: colors.textMuted,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                      reservedSize: 40,
                      interval: yMax > 0 ? yMax / 4 : 1,
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (sortedWeeks.length - 1).toDouble(),
                minY: 0,
                maxY: yMax,
                lineBarsData: lineBarsData,
              ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: List.generate(muscleGroups.length, (index) {
              final color = _muscleColors[index % _muscleColors.length];
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatMuscleGroup(muscleGroups[index]),
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  String _formatMuscleGroup(String name) {
    return name
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) =>
            word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  String _formatWeekLabel(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[date.month - 1]} ${date.day}';
    } catch (_) {
      return dateStr;
    }
  }

  String _formatYLabel(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(0);
  }
}
