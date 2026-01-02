import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../data/models/muscle_analytics.dart';

/// Horizontal bar chart showing training frequency per muscle group
class MuscleFrequencyChart extends StatelessWidget {
  final MuscleTrainingFrequency frequency;

  const MuscleFrequencyChart({
    super.key,
    required this.frequency,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sortedFrequencies = frequency.sortedByFrequency;

    if (sortedFrequencies.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('No frequency data available')),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendItem(color: Colors.green, label: 'Optimal (1-3x/wk)'),
                const SizedBox(width: 12),
                _LegendItem(color: Colors.orange, label: 'Low (<1x/wk)'),
                const SizedBox(width: 12),
                _LegendItem(color: Colors.red, label: 'High (>4x/wk)'),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // Bar list
            ...sortedFrequencies.map((f) => _FrequencyBar(
              muscleGroup: f.formattedMuscleGroup,
              frequency: f.timesPerWeek,
              status: f.frequencyStatus ?? 'optimal',
              lastTrained: f.formattedLastTrained,
            )),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
          label,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _FrequencyBar extends StatelessWidget {
  final String muscleGroup;
  final double frequency;
  final String status;
  final String lastTrained;

  const _FrequencyBar({
    required this.muscleGroup,
    required this.frequency,
    required this.status,
    required this.lastTrained,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color barColor;
    switch (status) {
      case 'undertrained':
        barColor = Colors.orange;
        break;
      case 'overtrained':
        barColor = Colors.red;
        break;
      default:
        barColor = Colors.green;
    }

    // Max frequency for bar width calculation (cap at 5)
    final maxFreq = 5.0;
    final barWidth = (frequency / maxFreq).clamp(0.05, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // Muscle name - responsive width
          Builder(
            builder: (context) {
              final screenWidth = MediaQuery.of(context).size.width;
              final labelWidth = screenWidth < 380 ? 80.0 : 100.0;
              return SizedBox(
                width: labelWidth,
                child: Text(
                  muscleGroup,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: screenWidth < 380 ? 12 : 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
          ),
          const SizedBox(width: 8),

          // Bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    // Background
                    Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    // Filled bar
                    FractionallySizedBox(
                      widthFactor: barWidth,
                      child: Container(
                        height: 20,
                        decoration: BoxDecoration(
                          color: barColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: frequency >= 0.5
                              ? Text(
                                  '${frequency.toStringAsFixed(1)}x',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Frequency value if bar too small
          if (frequency < 0.5)
            SizedBox(
              width: 40,
              child: Text(
                '${frequency.toStringAsFixed(1)}x',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: barColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          // Status icon
          SizedBox(
            width: 24,
            child: Icon(
              status == 'optimal'
                  ? Icons.check_circle
                  : status == 'undertrained'
                      ? Icons.arrow_downward
                      : Icons.arrow_upward,
              size: 18,
              color: barColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Alternative chart view using fl_chart horizontal bar chart
class MuscleFrequencyBarChart extends StatelessWidget {
  final MuscleTrainingFrequency frequency;

  const MuscleFrequencyBarChart({
    super.key,
    required this.frequency,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sortedFrequencies = frequency.sortedByFrequency.take(10).toList();

    if (sortedFrequencies.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxFreq = sortedFrequencies.map((f) => f.timesPerWeek).reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: sortedFrequencies.length * 40.0,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (maxFreq * 1.2).clamp(4, 10),
          barGroups: sortedFrequencies.asMap().entries.map((entry) {
            final f = entry.value;
            Color color;
            switch (f.frequencyStatus) {
              case 'undertrained':
                color = Colors.orange;
                break;
              case 'overtrained':
                color = Colors.red;
                break;
              default:
                color = Colors.green;
            }

            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: f.timesPerWeek,
                  color: color,
                  width: 20,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 80,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < sortedFrequencies.length) {
                    return Text(
                      sortedFrequencies[index].formattedMuscleGroup,
                      style: theme.textTheme.bodySmall,
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}x/wk',
                    style: theme.textTheme.bodySmall,
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}
