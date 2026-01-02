import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../data/models/strain_prevention.dart';

/// Line chart showing weekly volume trends for strain prevention
class StrainVolumeChart extends StatelessWidget {
  final VolumeHistoryData data;
  final String? selectedMuscleGroup;
  final Color? primaryColor;

  const StrainVolumeChart({
    super.key,
    required this.data,
    this.selectedMuscleGroup,
    this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sortedWeeks = data.sortedWeeks;

    if (sortedWeeks.isEmpty) {
      return _buildEmptyState(colorScheme);
    }

    // Calculate max value for Y axis
    final maxVolume = sortedWeeks
        .map((e) => e.totalVolumeKg)
        .reduce((a, b) => a > b ? a : b);
    final yMax = (maxVolume * 1.2).ceilToDouble();

    final chartColor = primaryColor ?? colorScheme.primary;

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
              Icon(Icons.show_chart, color: chartColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  selectedMuscleGroup != null
                      ? '${_formatMuscleGroup(selectedMuscleGroup!)} Volume'
                      : 'Weekly Volume Trend',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              if (data.dangerousWeeksCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber,
                        size: 14,
                        color: Colors.red.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${data.dangerousWeeksCount} risky',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: yMax,
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) =>
                        colorScheme.inverseSurface.withValues(alpha: 0.95),
                    tooltipPadding: const EdgeInsets.all(10),
                    tooltipMargin: 8,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final weekData = sortedWeeks[spot.x.toInt()];
                        return LineTooltipItem(
                          '${weekData.weekLabel}\n${weekData.totalVolumeKg.toStringAsFixed(0)} kg',
                          TextStyle(
                            color: colorScheme.onInverseSurface,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                          children: [
                            if (weekData.isDangerousIncrease)
                              TextSpan(
                                text: '\n+${weekData.percentChange?.toStringAsFixed(0) ?? 0}% increase',
                                style: TextStyle(
                                  color: Colors.red.shade300,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        );
                      }).toList();
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
                            sortedWeeks[index].weekLabel,
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
                    color: colorScheme.outline.withValues(alpha: 0.1),
                    strokeWidth: 1,
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      sortedWeeks.length,
                      (index) => FlSpot(
                        index.toDouble(),
                        sortedWeeks[index].totalVolumeKg,
                      ),
                    ),
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: chartColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        final weekData = sortedWeeks[index];
                        return FlDotCirclePainter(
                          radius: weekData.isDangerousIncrease ? 6 : 4,
                          color: weekData.isDangerousIncrease
                              ? Colors.red
                              : chartColor,
                          strokeWidth: weekData.isDangerousIncrease ? 2 : 0,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          chartColor.withValues(alpha: 0.3),
                          chartColor.withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Volume', chartColor, colorScheme),
              const SizedBox(width: 20),
              _buildLegendItem('Dangerous Increase', Colors.red, colorScheme),
            ],
          ),
          const SizedBox(height: 12),
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Average',
                '${data.avgWeeklyVolume.toStringAsFixed(0)} kg',
                colorScheme,
              ),
              _buildStatItem(
                'Peak',
                '${data.peakVolume.toStringAsFixed(0)} kg',
                colorScheme,
              ),
              _buildStatItem(
                'Weeks',
                '${sortedWeeks.length}',
                colorScheme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart_outlined,
            size: 48,
            color: colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No Volume Data',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete some workouts to see your volume trends.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, ColorScheme colorScheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, ColorScheme colorScheme) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  String _formatYLabel(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(0);
  }

  String _formatMuscleGroup(String name) {
    return name
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) =>
            word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}
