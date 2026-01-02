import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/muscle_analytics.dart';
import '../../../data/providers/muscle_analytics_provider.dart';
import '../../../data/repositories/muscle_analytics_repository.dart';

/// Detail screen showing analytics for a specific muscle group
class MuscleDetailScreen extends ConsumerStatefulWidget {
  final String muscleGroup;

  const MuscleDetailScreen({
    super.key,
    required this.muscleGroup,
  });

  @override
  ConsumerState<MuscleDetailScreen> createState() => _MuscleDetailScreenState();
}

class _MuscleDetailScreenState extends ConsumerState<MuscleDetailScreen> {
  DateTime? _screenOpenTime;

  @override
  void initState() {
    super.initState();
    _screenOpenTime = DateTime.now();
  }

  @override
  void dispose() {
    _logViewDuration();
    super.dispose();
  }

  void _logViewDuration() {
    if (_screenOpenTime != null) {
      final duration = DateTime.now().difference(_screenOpenTime!).inSeconds;
      ref.read(muscleAnalyticsRepositoryProvider).logView(
        viewType: 'muscle_detail',
        muscleGroup: widget.muscleGroup,
        sessionDurationSeconds: duration,
      );
    }
  }

  String _formatMuscleName(String name) {
    return name
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final exercisesAsync = ref.watch(muscleExercisesProvider(widget.muscleGroup));
    final historyAsync = ref.watch(muscleHistoryProvider(widget.muscleGroup));

    return Scaffold(
      appBar: AppBar(
        title: Text(_formatMuscleName(widget.muscleGroup)),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(muscleExercisesProvider(widget.muscleGroup));
          ref.invalidate(muscleHistoryProvider(widget.muscleGroup));
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Volume Trend Chart
              historyAsync.when(
                loading: () => const _LoadingCard(),
                error: (_, __) => const SizedBox.shrink(),
                data: (history) => _VolumeHistorySection(history: history),
              ),

              const SizedBox(height: 24),

              // Exercises Section
              Text(
                'Exercises',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              exercisesAsync.when(
                loading: () => const _LoadingCard(),
                error: (error, _) => _ErrorCard(message: error.toString()),
                data: (exerciseData) {
                  if (!exerciseData.hasData) {
                    return const _EmptyCard(
                      message: 'No exercises recorded for this muscle.',
                    );
                  }

                  return Column(
                    children: [
                      // Summary
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: _StatItem(
                                  label: 'Exercises',
                                  value: '${exerciseData.totalExercises ?? exerciseData.exercises.length}',
                                ),
                              ),
                              Expanded(
                                child: _StatItem(
                                  label: 'Total Volume',
                                  value: exerciseData.formattedTotalVolume,
                                ),
                              ),
                              Expanded(
                                child: _StatItem(
                                  label: 'Total Sets',
                                  value: '${exerciseData.totalSets ?? 0}',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Exercise list
                      ...exerciseData.sortedByVolume.map((exercise) => _ExerciseCard(
                        exercise: exercise,
                        totalVolume: exerciseData.totalVolumeKg ?? 1,
                        onTap: () {
                          context.push('/progress/exercise-history/${Uri.encodeComponent(exercise.exerciseName)}');
                        },
                      )),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Volume history chart section
class _VolumeHistorySection extends StatelessWidget {
  final MuscleHistoryData history;

  const _VolumeHistorySection({required this.history});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!history.hasData) {
      return const _EmptyCard(message: 'Not enough data for volume chart.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Volume Trend',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (history.summary != null)
              _TrendBadge(
                trend: history.summary!.volumeTrend ?? 'stable',
                change: history.summary!.volumeChangeDisplay,
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Summary stats
        if (history.summary != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _StatItem(
                      label: 'Workouts',
                      value: '${history.summary!.totalWorkouts}',
                    ),
                  ),
                  Expanded(
                    child: _StatItem(
                      label: 'Total Volume',
                      value: history.summary!.formattedTotalVolume,
                    ),
                  ),
                  Expanded(
                    child: _StatItem(
                      label: 'Max Weight',
                      value: history.summary!.formattedMaxWeight,
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 16),

        // Chart
        SizedBox(
          height: 200,
          child: _VolumeChart(dataPoints: history.volumeChartData),
        ),
      ],
    );
  }
}

class _TrendBadge extends StatelessWidget {
  final String trend;
  final String change;

  const _TrendBadge({required this.trend, required this.change});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    IconData icon;
    Color color;

    switch (trend) {
      case 'increasing':
        icon = Icons.trending_up;
        color = Colors.green;
        break;
      case 'decreasing':
        icon = Icons.trending_down;
        color = Colors.red;
        break;
      default:
        icon = Icons.trending_flat;
        color = theme.colorScheme.onSurfaceVariant;
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
            change,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _VolumeChart extends StatelessWidget {
  final List<MuscleChartDataPoint> dataPoints;

  const _VolumeChart({required this.dataPoints});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (dataPoints.length < 2) {
      return Center(
        child: Text(
          'Need more data for chart',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final spots = dataPoints.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();

    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.1;
    final minY = 0.0;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        minY: minY,
        barGroups: spots.map((spot) {
          return BarChartGroupData(
            x: spot.x.toInt(),
            barRods: [
              BarChartRodData(
                toY: spot.y,
                color: theme.colorScheme.primary,
                width: 16,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                if (value >= 1000) {
                  return Text(
                    '${(value / 1000).toStringAsFixed(1)}k',
                    style: theme.textTheme.bodySmall,
                  );
                }
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
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              if (groupIndex >= 0 && groupIndex < dataPoints.length) {
                return BarTooltipItem(
                  dataPoints[groupIndex].label ?? '${rod.toY.toInt()} kg',
                  theme.textTheme.bodySmall!.copyWith(color: Colors.white),
                );
              }
              return null;
            },
          ),
        ),
      ),
    );
  }
}

/// Exercise card showing stats
class _ExerciseCard extends StatelessWidget {
  final MuscleExerciseStats exercise;
  final double totalVolume;
  final VoidCallback onTap;

  const _ExerciseCard({
    required this.exercise,
    required this.totalVolume,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contribution = totalVolume > 0
        ? (exercise.totalVolumeKg ?? 0) / totalVolume
        : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      exercise.exerciseName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _MiniStat(
                    label: 'Times',
                    value: '${exercise.timesPerformed}',
                  ),
                  const SizedBox(width: 16),
                  _MiniStat(
                    label: 'Volume',
                    value: exercise.formattedVolume,
                  ),
                  const SizedBox(width: 16),
                  _MiniStat(
                    label: 'Max',
                    value: exercise.formattedMaxWeight,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: contribution,
                  minHeight: 6,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${(contribution * 100).toStringAsFixed(0)}% of total volume',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

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

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

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
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;

  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
