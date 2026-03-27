import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../data/models/exercise_history.dart';

/// Time range selection chips
class ExerciseTimeRangeSelector extends StatelessWidget {
  final ExerciseHistoryTimeRange selected;
  final ValueChanged<ExerciseHistoryTimeRange> onChanged;

  const ExerciseTimeRangeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ExerciseHistoryTimeRange.values.map((range) {
          final isSelected = range == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(range.displayName),
              selected: isSelected,
              onSelected: (_) => onChanged(range),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Chart type selection chips
class ExerciseChartTypeSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const ExerciseChartTypeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final options = ['weight', 'volume', '1rm'];
    final labels = {'weight': 'Weight', 'volume': 'Volume', '1rm': 'Est. 1RM'};

    return Row(
      children: options.map((option) {
        final isSelected = option == selected;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(labels[option]!),
            selected: isSelected,
            onSelected: (_) => onChanged(option),
          ),
        );
      }).toList(),
    );
  }
}

/// Summary statistics card
class ExerciseSummaryCard extends StatelessWidget {
  final ExerciseProgressionSummary summary;

  const ExerciseSummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Summary',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (summary.trend != null)
                  ExerciseTrendBadge(trend: summary.trend!),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ExerciseStatItem(
                    label: 'Sessions',
                    value: '${summary.totalSessions}',
                  ),
                ),
                Expanded(
                  child: ExerciseStatItem(
                    label: 'Total Volume',
                    value: summary.formattedTotalVolume,
                  ),
                ),
                Expanded(
                  child: ExerciseStatItem(
                    label: 'Weight Change',
                    value: summary.formattedWeightIncrease,
                    isPositive: (summary.weightIncreaseKg ?? 0) > 0,
                  ),
                ),
              ],
            ),
            if (summary.avgFrequencyPerWeek != null) ...[
              const Divider(height: 24),
              Text(
                'Training frequency: ${summary.formattedFrequency}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ExerciseStatItem extends StatelessWidget {
  final String label;
  final String value;
  final bool? isPositive;

  const ExerciseStatItem({
    super.key,
    required this.label,
    required this.value,
    this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color? valueColor;
    if (isPositive == true) {
      valueColor = Colors.green;
    } else if (isPositive == false) {
      valueColor = Colors.red;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class ExerciseTrendBadge extends StatelessWidget {
  final String trend;

  const ExerciseTrendBadge({super.key, required this.trend});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    IconData icon;
    Color color;
    String label;

    switch (trend) {
      case 'improving':
        icon = Icons.trending_up;
        color = Colors.green;
        label = 'Improving';
        break;
      case 'declining':
        icon = Icons.trending_down;
        color = Colors.red;
        label = 'Declining';
        break;
      default:
        icon = Icons.trending_flat;
        color = theme.colorScheme.onSurfaceVariant;
        label = 'Stable';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

/// Progression line chart
class ExerciseProgressionChart extends StatelessWidget {
  final ExerciseHistoryData history;
  final String chartType;

  const ExerciseProgressionChart({
    super.key,
    required this.history,
    required this.chartType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    List<ExerciseChartDataPoint> dataPoints;
    switch (chartType) {
      case 'volume':
        dataPoints = history.volumeChartData;
        break;
      case '1rm':
        dataPoints = history.oneRmChartData;
        break;
      default:
        dataPoints = history.weightChartData;
    }

    if (dataPoints.length < 2) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'Not enough data to show chart',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final spots = dataPoints.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();

    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) * 0.9;
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.1;

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (maxY - minY) / 4,
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}',
                    style: theme.textTheme.bodySmall,
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: (dataPoints.length / 4).ceilToDouble(),
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < dataPoints.length) {
                    return Text(
                      dataPoints[index].axisLabel,
                      style: theme.textTheme.bodySmall,
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minY: minY,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: theme.colorScheme.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: theme.colorScheme.primary,
                    strokeWidth: 2,
                    strokeColor: theme.colorScheme.surface,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final index = spot.spotIndex;
                  if (index >= 0 && index < dataPoints.length) {
                    return LineTooltipItem(
                      '${dataPoints[index].label}\n${dataPoints[index].tooltipDate}',
                      theme.textTheme.bodySmall!.copyWith(color: Colors.white),
                    );
                  }
                  return null;
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Personal records section
class ExercisePersonalRecordsSection extends StatelessWidget {
  final List<ExercisePersonalRecord> records;

  const ExercisePersonalRecordsSection({super.key, required this.records});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personal Records',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...records.map((pr) => ExercisePRCard(record: pr)),
      ],
    );
  }
}

class ExercisePRCard extends StatelessWidget {
  final ExercisePersonalRecord record;

  const ExercisePRCard({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.emoji_events, color: Colors.amber),
        ),
        title: Text(record.prTypeDisplayName),
        subtitle: Text('Achieved ${record.formattedAchievedDate}'),
        trailing: Text(
          record.formattedValue,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

/// Single session card
class ExerciseSessionCard extends StatelessWidget {
  final ExerciseWorkoutSession session;

  const ExerciseSessionCard({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.formattedDate,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (session.workoutName != null)
                        Text(
                          session.workoutName!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      session.relativeDateDisplay,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (session.hadPr)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, size: 12, color: Colors.amber),
                              const SizedBox(width: 3),
                              Text(
                                session.prBadge ?? 'PR',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.amber.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ExerciseSessionStat(label: 'Sets × Reps', value: session.setsRepsDisplay),
                const SizedBox(width: 24),
                ExerciseSessionStat(label: 'Weight', value: session.formattedWeight),
                const SizedBox(width: 24),
                ExerciseSessionStat(label: 'Volume', value: session.formattedVolume),
                if (session.estimated1rmKg != null) ...[
                  const SizedBox(width: 24),
                  ExerciseSessionStat(label: 'Est. 1RM', value: session.formatted1rm),
                ],
              ],
            ),
            if (session.notes != null && session.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                session.notes!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ExerciseSessionStat extends StatelessWidget {
  final String label;
  final String value;

  const ExerciseSessionStat({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
