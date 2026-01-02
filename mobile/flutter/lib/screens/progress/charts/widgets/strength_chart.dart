import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../data/models/progress_charts.dart';

/// Line chart displaying strength progression per muscle group
class StrengthChart extends StatelessWidget {
  final StrengthProgressionData data;

  const StrengthChart({super.key, required this.data});

  // Predefined colors for muscle groups
  static const List<Color> _muscleColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.amber,
    Colors.cyan,
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
    final yMax = (maxVolume * 1.2).ceilToDouble();

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
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: color.withOpacity(0.1),
            ),
          ),
        );
      }
    }

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
              Icon(Icons.show_chart, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Strength Over Time',
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
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) =>
                        colorScheme.inverseSurface.withOpacity(0.9),
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
                    color: colorScheme.outline.withOpacity(0.1),
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
                      color: colorScheme.onSurfaceVariant,
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
