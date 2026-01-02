import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../data/models/progress_charts.dart';

/// Bar chart displaying weekly training volume
class VolumeChart extends StatelessWidget {
  final VolumeProgressionData data;

  const VolumeChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sortedData = data.sortedData;

    if (sortedData.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculate max value for Y axis
    final maxVolume = sortedData
        .map((e) => e.totalVolumeKg)
        .reduce((a, b) => a > b ? a : b);
    final yMax = (maxVolume * 1.2).ceilToDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Weekly Volume (kg)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: yMax,
                minY: 0,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) =>
                        colorScheme.inverseSurface.withOpacity(0.9),
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final weekData = sortedData[group.x.toInt()];
                      return BarTooltipItem(
                        '${weekData.weekLabel}\n${weekData.totalVolumeKg.toStringAsFixed(0)} kg\n${weekData.workoutsCompleted} workouts',
                        TextStyle(
                          color: colorScheme.onInverseSurface,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= sortedData.length) {
                          return const SizedBox.shrink();
                        }
                        // Show every nth label to avoid crowding
                        final showEvery = sortedData.length > 8 ? 2 : 1;
                        if (index % showEvery != 0) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            sortedData[index].weekLabel,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
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
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                      reservedSize: 40,
                      interval: yMax / 4,
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
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: yMax / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: colorScheme.outline.withOpacity(0.1),
                    strokeWidth: 1,
                  ),
                ),
                barGroups: List.generate(sortedData.length, (index) {
                  final weekData = sortedData[index];
                  final isHighest = weekData.totalVolumeKg == maxVolume;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: weekData.totalVolumeKg,
                        width: sortedData.length > 8 ? 12 : 20,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                        gradient: LinearGradient(
                          colors: isHighest
                              ? [
                                  Colors.amber.shade400,
                                  Colors.amber.shade600,
                                ]
                              : [
                                  colorScheme.primary.withOpacity(0.7),
                                  colorScheme.primary,
                                ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Weekly Volume',
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Peak Week',
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatYLabel(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(0);
  }
}
