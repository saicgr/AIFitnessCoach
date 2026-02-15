import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../data/models/exercise_history.dart';
import '../../../data/providers/exercise_history_provider.dart';
import '../../../data/repositories/exercise_history_repository.dart';
import '../../../widgets/segmented_tab_bar.dart';

/// Detail screen showing progression and history for a specific exercise
class ExerciseProgressDetailScreen extends ConsumerStatefulWidget {
  final String exerciseName;

  const ExerciseProgressDetailScreen({
    super.key,
    required this.exerciseName,
  });

  @override
  ConsumerState<ExerciseProgressDetailScreen> createState() => _ExerciseProgressDetailScreenState();
}

class _ExerciseProgressDetailScreenState extends ConsumerState<ExerciseProgressDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime? _screenOpenTime;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _screenOpenTime = DateTime.now();
  }

  @override
  void dispose() {
    _logViewDuration();
    _tabController.dispose();
    super.dispose();
  }

  void _logViewDuration() {
    if (_screenOpenTime != null) {
      final duration = DateTime.now().difference(_screenOpenTime!).inSeconds;
      ref.read(exerciseHistoryRepositoryProvider).logView(
        exerciseName: widget.exerciseName,
        sessionDurationSeconds: duration,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final historyAsync = ref.watch(exerciseHistoryProvider(widget.exerciseName));
    final prsAsync = ref.watch(exercisePRsProvider(widget.exerciseName));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exerciseName),
      ),
      body: Column(
        children: [
          SegmentedTabBar(
            controller: _tabController,
            showIcons: false,
            tabs: const [
              SegmentedTabItem(label: 'Progress'),
              SegmentedTabItem(label: 'History'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Progress Tab
                _ProgressTab(
                  exerciseName: widget.exerciseName,
                  historyAsync: historyAsync,
                  prsAsync: prsAsync,
                ),
                // History Tab
                _HistoryTab(
                  exerciseName: widget.exerciseName,
                  historyAsync: historyAsync,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tab showing progression charts and PRs
class _ProgressTab extends ConsumerWidget {
  final String exerciseName;
  final AsyncValue<ExerciseHistoryData> historyAsync;
  final AsyncValue<List<ExercisePersonalRecord>> prsAsync;

  const _ProgressTab({
    required this.exerciseName,
    required this.historyAsync,
    required this.prsAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final timeRange = ref.watch(exerciseHistoryTimeRangeProvider);
    final chartType = ref.watch(exerciseChartTypeProvider);

    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (history) {
        if (!history.hasData) {
          return _buildEmptyState(theme);
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(exerciseHistoryProvider(exerciseName));
            ref.invalidate(exercisePRsProvider(exerciseName));
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time range selector
                _TimeRangeSelector(
                  selected: timeRange,
                  onChanged: (value) {
                    ref.read(exerciseHistoryTimeRangeProvider.notifier).state = value;
                  },
                ),
                const SizedBox(height: 24),

                // Summary stats
                if (history.summary != null)
                  _SummaryCard(summary: history.summary!),
                const SizedBox(height: 24),

                // Chart type selector
                _ChartTypeSelector(
                  selected: chartType,
                  onChanged: (value) {
                    ref.read(exerciseChartTypeProvider.notifier).state = value;
                  },
                ),
                const SizedBox(height: 16),

                // Progression chart
                _ProgressionChart(
                  history: history,
                  chartType: chartType,
                ),
                const SizedBox(height: 24),

                // Personal Records
                prsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (prs) {
                    if (prs.isEmpty) return const SizedBox.shrink();
                    return _PersonalRecordsSection(records: prs);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timeline_outlined,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No data for this exercise yet',
            style: theme.textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

/// Tab showing list of all workout sessions
class _HistoryTab extends ConsumerWidget {
  final String exerciseName;
  final AsyncValue<ExerciseHistoryData> historyAsync;

  const _HistoryTab({
    required this.exerciseName,
    required this.historyAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (history) {
        final sessions = history.sortedSessionsNewestFirst;

        if (sessions.isEmpty) {
          return Center(
            child: Text('No sessions recorded', style: theme.textTheme.bodyLarge),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sessions.length,
          itemBuilder: (context, index) {
            return _SessionCard(session: sessions[index]);
          },
        );
      },
    );
  }
}

/// Time range selection chips
class _TimeRangeSelector extends StatelessWidget {
  final ExerciseHistoryTimeRange selected;
  final ValueChanged<ExerciseHistoryTimeRange> onChanged;

  const _TimeRangeSelector({
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
class _ChartTypeSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _ChartTypeSelector({
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
class _SummaryCard extends StatelessWidget {
  final ExerciseProgressionSummary summary;

  const _SummaryCard({required this.summary});

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
                  _TrendBadge(trend: summary.trend!),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    label: 'Sessions',
                    value: '${summary.totalSessions}',
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    label: 'Total Volume',
                    value: summary.formattedTotalVolume,
                  ),
                ),
                Expanded(
                  child: _StatItem(
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

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final bool? isPositive;

  const _StatItem({
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

class _TrendBadge extends StatelessWidget {
  final String trend;

  const _TrendBadge({required this.trend});

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
        color: color.withOpacity(0.1),
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
class _ProgressionChart extends StatelessWidget {
  final ExerciseHistoryData history;
  final String chartType;

  const _ProgressionChart({
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
                color: theme.colorScheme.primary.withOpacity(0.1),
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
class _PersonalRecordsSection extends StatelessWidget {
  final List<ExercisePersonalRecord> records;

  const _PersonalRecordsSection({required this.records});

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
        ...records.map((pr) => _PRCard(record: pr)),
      ],
    );
  }
}

class _PRCard extends StatelessWidget {
  final ExercisePersonalRecord record;

  const _PRCard({required this.record});

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
            color: Colors.amber.withOpacity(0.2),
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
class _SessionCard extends StatelessWidget {
  final ExerciseWorkoutSession session;

  const _SessionCard({required this.session});

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
                Text(
                  session.formattedDate,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (session.hadPr)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          session.prBadge ?? 'PR',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.amber.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            if (session.workoutName != null) ...[
              const SizedBox(height: 4),
              Text(
                session.workoutName!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                _SessionStat(label: 'Sets × Reps', value: session.setsRepsDisplay),
                const SizedBox(width: 24),
                _SessionStat(label: 'Weight', value: session.formattedWeight),
                const SizedBox(width: 24),
                _SessionStat(label: 'Volume', value: session.formattedVolume),
                if (session.estimated1rmKg != null) ...[
                  const SizedBox(width: 24),
                  _SessionStat(label: 'Est. 1RM', value: session.formatted1rm),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionStat extends StatelessWidget {
  final String label;
  final String value;

  const _SessionStat({required this.label, required this.value});

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
