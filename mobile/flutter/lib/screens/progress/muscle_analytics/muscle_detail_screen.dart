import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/posthog_service.dart';
import '../../../core/widgets/skeleton/skeleton.dart';
import '../../../data/models/muscle_analytics.dart';
import '../../../data/models/muscle_status.dart';
import '../../../data/providers/muscle_analytics_provider.dart';
import '../../../data/providers/scores_provider.dart';
import '../../../data/repositories/muscle_analytics_repository.dart';
import '../../../widgets/pill_app_bar.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/design_system/zealova.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../common/app_refresh_indicator.dart';
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
    ref.read(posthogServiceProvider).capture(
      eventName: 'muscle_detail_viewed',
      properties: <String, Object>{'muscle_name': widget.muscleGroup},
    );
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
    final exercisesAsync = ref.watch(muscleExercisesProvider(widget.muscleGroup));
    final historyAsync = ref.watch(muscleHistoryProvider(widget.muscleGroup));
    final frequencyAsync = ref.watch(muscleFrequencyProvider);
    final balanceAsync = ref.watch(muscleBalanceProvider);

    return Scaffold(
      appBar: PillAppBar(
        title: _formatMuscleName(widget.muscleGroup),
      ),
      body: AppRefreshIndicator(
        onRefresh: () async {
          ref.invalidate(muscleExercisesProvider(widget.muscleGroup));
          ref.invalidate(muscleHistoryProvider(widget.muscleGroup));
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Training status badge
              _MuscleStatusBadge(muscleGroup: widget.muscleGroup),
              const SizedBox(height: 16),

              // AI Insights Card
              _InsightsCard(
                muscleGroup: widget.muscleGroup,
                frequencyAsync: frequencyAsync,
                balanceAsync: balanceAsync,
              ),
              const SizedBox(height: 16),

              // Volume Trend Chart
              historyAsync.when(
                loading: () => const _LoadingCard(),
                error: (_, __) => const SizedBox.shrink(),
                data: (history) => _VolumeHistorySection(history: history),
              ),

              const SizedBox(height: 24),

              // Exercises Section
              ZealovaSectionKicker(AppLocalizations.of(context).authIntroExercises),
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
                      // Summary — hairline-divided stat tiles.
                      _StatRow(
                        items: [
                          _StatItemData(
                            label: AppLocalizations.of(context).authIntroExercises,
                            value: '${exerciseData.totalExercises ?? exerciseData.exercises.length}',
                          ),
                          _StatItemData(
                            label: AppLocalizations.of(context).volumeHistoryTotalVolume,
                            value: exerciseData.formattedTotalVolume,
                          ),
                          _StatItemData(
                            label: AppLocalizations.of(context).muscleDetailTotalSets,
                            value: '${exerciseData.totalSets ?? 0}',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Exercise list
                      ...exerciseData.sortedByVolume.map((exercise) => _ExerciseCard(
                        exercise: exercise,
                        totalVolume: exerciseData.totalVolumeKg ?? 1,
                        onTap: () {
                          context.push('/stats/exercise-history/${Uri.encodeComponent(exercise.exerciseName)}');
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
    if (!history.hasData) {
      return const _EmptyCard(message: 'Not enough data for volume chart.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ZealovaSectionKicker(AppLocalizations.of(context).progressChartsVolumeTrend),
            if (history.summary != null)
              _TrendBadge(
                trend: history.summary!.volumeTrend ?? 'stable',
                change: history.summary!.volumeChangeDisplay,
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Summary stats — hairline-divided tiles.
        if (history.summary != null)
          _StatRow(
            items: [
              _StatItemData(
                label: AppLocalizations.of(context).workoutListTitle,
                value: '${history.summary!.totalWorkouts}',
              ),
              _StatItemData(
                label: AppLocalizations.of(context).volumeHistoryTotalVolume,
                value: history.summary!.formattedTotalVolume,
              ),
              _StatItemData(
                label: AppLocalizations.of(context).muscleDetailMaxWeight,
                value: history.summary!.formattedMaxWeight,
              ),
            ],
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
    final tc = ThemeColors.of(context);

    IconData icon;
    Color color;

    // Trend is semantic (success/error/muted), NOT the screen accent.
    switch (trend) {
      case 'increasing':
        icon = Icons.trending_up;
        color = tc.success;
        break;
      case 'decreasing':
        icon = Icons.trending_down;
        color = tc.error;
        break;
      default:
        icon = Icons.trending_flat;
        color = tc.textMuted;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            change.toUpperCase(),
            style: ZType.lbl(10, color: color, letterSpacing: 1.0),
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
    final tc = ThemeColors.of(context);

    if (dataPoints.length < 2) {
      return Center(
        child: Text(
          AppLocalizations.of(context).muscleDetailNeedMoreDataFor,
          textAlign: TextAlign.center,
          style: ZType.ser(14, color: tc.textSecondary),
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
                color: tc.accent,
                width: 14,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
              ),
            ],
          );
        }).toList(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: AppColors.hairline, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                final label = value >= 1000
                    ? '${(value / 1000).toStringAsFixed(1)}K'
                    : '${value.toInt()}';
                return Text(
                  label,
                  style: ZType.lbl(9, color: tc.textMuted, letterSpacing: 0.8),
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
                    dataPoints[index].axisLabel.toUpperCase(),
                    style: ZType.lbl(9, color: tc.textMuted, letterSpacing: 0.8),
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
                  ZType.data(11, color: tc.accentContrast),
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
    final tc = ThemeColors.of(context);
    final contribution = totalVolume > 0
        ? ((exercise.totalVolumeKg ?? 0) / totalVolume).clamp(0.0, 1.0)
        : 0.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.hairline)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      exercise.exerciseName.toUpperCase(),
                      style: ZType.lbl(13,
                          color: tc.textPrimary, letterSpacing: 1.2),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${(contribution * 100).toStringAsFixed(0)}%',
                    style: ZType.disp(15, color: tc.textPrimary),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 18, color: tc.textMuted),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _MiniStat(
                    label: AppLocalizations.of(context).muscleDetailTimes,
                    value: '${exercise.timesPerformed}',
                  ),
                  const SizedBox(width: 18),
                  _MiniStat(
                    label: AppLocalizations.of(context).workoutSummaryAdvancedVolume,
                    value: exercise.formattedVolume,
                  ),
                  const SizedBox(width: 18),
                  _MiniStat(
                    label: AppLocalizations.of(context).strengthOverviewCardMax,
                    value: exercise.formattedMaxWeight,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: contribution,
                  minHeight: 4,
                  backgroundColor: AppColors.hairlineStrong,
                  valueColor: AlwaysStoppedAnimation(tc.accent),
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
    final tc = ThemeColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: ZType.lbl(9, color: tc.textMuted, letterSpacing: 1.0),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: ZType.data(13, color: tc.textPrimary),
        ),
      ],
    );
  }
}

/// Immutable spec for one tile in [_StatRow].
class _StatItemData {
  final String label;
  final String value;
  const _StatItemData({required this.label, required this.value});
}

/// A row of summary stats laid out as hairline-divided tiles (Anton numeral
/// over a Barlow uppercase label) — replaces the boxed Material summary `Card`.
class _StatRow extends StatelessWidget {
  final List<_StatItemData> items;

  const _StatRow({required this.items});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: tc.surface,
        border: Border.all(color: tc.cardBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) Container(width: 1, color: AppColors.hairline),
              Expanded(child: _StatItem(data: items[i])),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final _StatItemData data;

  const _StatItem({required this.data});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            data.label.toUpperCase(),
            style: ZType.lbl(9, color: tc.textMuted, letterSpacing: 1.2),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            data.value,
            style: ZType.disp(20, color: tc.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Layout-matched loading placeholder for the muscle-detail sections. Replaces
/// the old centered spinner with shimmer skeletons — a summary-stat row and a
/// tall chart/list block — so the load -> content swap is reflow-free.
class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        // Summary-stat row placeholder.
        SkeletonBox(height: 72, radius: 12),
        SizedBox(height: 12),
        // Chart / exercise-list block placeholder.
        SkeletonBox(height: 180, radius: 12),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    return ZealovaCard(
      variant: ZealovaCardVariant.outlined,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 20, color: tc.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: ZType.ser(14, color: tc.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;

  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    return ZealovaCard(
      variant: ZealovaCardVariant.outlined,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: ZType.ser(14, color: tc.textSecondary),
        ),
      ),
    );
  }
}

class _InsightsCard extends StatefulWidget {
  final String muscleGroup;
  final AsyncValue<MuscleTrainingFrequency> frequencyAsync;
  final AsyncValue<MuscleBalanceData> balanceAsync;

  const _InsightsCard({
    required this.muscleGroup,
    required this.frequencyAsync,
    required this.balanceAsync,
  });

  @override
  State<_InsightsCard> createState() => _InsightsCardState();
}

class _InsightsCardState extends State<_InsightsCard> {
  bool _expanded = true;

  // Memoized insight list. `_generateInsights()` iterates the frequency and
  // balance async values — recomputing it on every `setState(_expanded)`
  // toggle is wasted work, so it is cached and rebuilt only when inputs change.
  late List<String> _insights;

  @override
  void initState() {
    super.initState();
    _insights = _generateInsights();
  }

  @override
  void didUpdateWidget(covariant _InsightsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.frequencyAsync != widget.frequencyAsync ||
        oldWidget.balanceAsync != widget.balanceAsync ||
        oldWidget.muscleGroup != widget.muscleGroup) {
      _insights = _generateInsights();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final insights = _insights;

    if (insights.isEmpty) return const SizedBox.shrink();

    return ZealovaCard(
      variant: ZealovaCardVariant.hero,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Header with collapse toggle
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, size: 18, color: tc.accent),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context).muscleDetailInsights.toUpperCase(),
                    style: ZType.lbl(12, color: tc.textPrimary, letterSpacing: 1.4),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      size: 20,
                      color: tc.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Collapsible content
          AnimatedCrossFade(
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: insights.map((insight) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 4, right: 10),
                        child: Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: tc.accent,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          insight,
                          style: ZType.ser(14, color: tc.textPrimary),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),
            secondChild: const SizedBox.shrink(),
            crossFadeState: _expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  List<String> _generateInsights() {
    final insights = <String>[];
    final muscleName = widget.muscleGroup.replaceAll('_', ' ');
    final capitalizedName = muscleName.split(' ').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');

    // Frequency insights
    widget.frequencyAsync.whenData((frequency) {
      for (final freq in frequency.frequencies) {
        if (freq.muscleGroup == widget.muscleGroup) {
          if (freq.isUndertrained) {
            final recommended = freq.recommendedFrequency?.toStringAsFixed(1) ?? '2.0';
            insights.add('$capitalizedName is undertrained (${freq.frequencyDisplay}) — try adding sessions to reach ${recommended}x/week');
          } else if (freq.isOvertrained) {
            insights.add('$capitalizedName may be overtrained (${freq.frequencyDisplay}) — consider adding a rest day');
          } else if (freq.isOptimal) {
            insights.add('$capitalizedName training frequency is optimal (${freq.frequencyDisplay})');
          }

          if (freq.daysSinceTrained != null && freq.daysSinceTrained! > 7) {
            insights.add('Last trained ${freq.formattedLastTrained} — consider scheduling a session soon');
          }
          break;
        }
      }
    });

    // Balance insights
    widget.balanceAsync.whenData((balance) {
      if (balance.recommendations != null) {
        for (final rec in balance.recommendations!) {
          // Only add recommendations relevant to this muscle group
          if (rec.toLowerCase().contains(muscleName.toLowerCase()) ||
              rec.toLowerCase().contains('push') ||
              rec.toLowerCase().contains('pull') ||
              rec.toLowerCase().contains('ratio')) {
            insights.add(rec);
          }
        }
      }

      // Push/pull ratio insight if relevant
      if (balance.pushPullRatio != null) {
        final ratio = balance.pushPullRatio!;
        final isPushMuscle = ['chest', 'shoulders', 'triceps'].contains(widget.muscleGroup);
        final isPullMuscle = ['lats', 'upper_back', 'biceps', 'traps'].contains(widget.muscleGroup);

        if (isPushMuscle && ratio > 1.5) {
          insights.add('Push/pull ratio is ${ratio.toStringAsFixed(1)}:1 — consider more pulling exercises for balance');
        } else if (isPullMuscle && ratio < 0.7) {
          insights.add('Push/pull ratio is ${ratio.toStringAsFixed(1)}:1 — consider more pushing exercises for balance');
        }
      }
    });

    return insights;
  }
}

class _MuscleStatusBadge extends ConsumerWidget {
  final String muscleGroup;

  const _MuscleStatusBadge({required this.muscleGroup});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Select just this muscle's data + readiness — avoids rebuilds on
    // unrelated scores mutations.
    final (muscleData, readiness) = ref.watch(scoresProvider.select((s) => (
          s.strengthScores?.muscleScores[muscleGroup],
          s.todayReadiness ?? s.overview?.todayReadiness,
        )));
    if (muscleData == null) return const SizedBox.shrink();
    final status = determineMuscleStatus(
      muscleData: muscleData,
      readiness: readiness,
    );
    final tc = ThemeColors.of(context);

    // `status.color` is the model's semantic readiness color — kept for the
    // icon + label, but the surface itself is a hairline-outlined matte tile.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: tc.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tc.cardBorder),
      ),
      child: Row(
        children: [
          Icon(status.icon, size: 18, color: status.color),
          const SizedBox(width: 8),
          Text(
            status.label.toUpperCase(),
            style: ZType.lbl(12, color: status.color, letterSpacing: 1.4),
          ),
          const Spacer(),
          Text(
            AppLocalizations.of(context)!.muscleDetailScreenSetsWk(muscleData.weeklySets).toUpperCase(),
            style: ZType.lbl(10, color: tc.textMuted, letterSpacing: 1.2),
          ),
        ],
      ),
    );
  }
}
