import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/posthog_service.dart';
import '../../../core/widgets/skeleton/skeleton.dart';
import '../../../data/models/exercise_history.dart';
import '../../../data/models/gym_profile.dart';
import '../../../data/providers/exercise_history_provider.dart';
import '../../../data/providers/gym_profile_provider.dart';
import '../../../data/providers/gym_progress_filter_provider.dart';
import '../../../data/repositories/exercise_history_repository.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../widgets/exercise_stats_widgets.dart';
import '../../../widgets/glass_back_button.dart';
import '../../../widgets/segmented_tab_bar.dart';
import '../../workout/widgets/exercise_strength_score_card.dart';
import '../widgets/gym_progress_filter.dart';
import 'widgets/ai_progress_pros_cons_card.dart';
import '../../common/app_refresh_indicator.dart';

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
  // Cache the repo in initState — Riverpod invalidates `ref` before dispose()
  // runs, so reading the provider from inside dispose throws
  // "Cannot use ref after the widget was disposed".
  late final ExerciseHistoryRepository _historyRepo;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _screenOpenTime = DateTime.now();
    _historyRepo = ref.read(exerciseHistoryRepositoryProvider);
    ref.read(posthogServiceProvider).capture(
      eventName: 'exercise_progress_detail_viewed',
      properties: <String, Object>{'exercise_name': widget.exerciseName},
    );
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
      _historyRepo.logView(
        exerciseName: widget.exerciseName,
        sessionDurationSeconds: duration,
      );
    }
  }

  /// Stable per-exercise surface key for the gym progress filter selection.
  String get _surfaceKey => 'exercise:${widget.exerciseName}';

  @override
  Widget build(BuildContext context) {
    final timeRange = ref.watch(exerciseHistoryTimeRangeProvider);
    final selection = ref.watch(gymProgressFilterProvider(_surfaceKey));

    // Gym-filtered history: the args carry the selected gym + scope. While the
    // selection is unresolved (first open, no persisted pick), gymProfileId +
    // scope are null so the backend applies its equipment-aware default and
    // tells us (via resolved_scope) which gym to seed the filter to.
    final args = GymExerciseHistoryArgs(
      exerciseName: widget.exerciseName,
      timeRange: timeRange.value,
      gymProfileId: selection.isAllGyms ? null : selection.gymProfileId,
      scope: selection.scope,
    );
    final resultAsync = ref.watch(gymExerciseHistoryProvider(args));

    // Seed the filter's default from the endpoint's resolved_scope the first
    // time we get a result (per_gym → active gym, combined → All gyms). Only
    // applies while the selection is still unresolved.
    if (!selection.resolved) {
      final result = resultAsync.valueOrNull;
      if (result != null) {
        final activeGymId = ref.read(activeGymProfileIdProvider);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ref
              .read(gymProgressFilterProvider(_surfaceKey).notifier)
              .seedDefault(
                perGym: result.isPerGym,
                activeGymProfileId: result.gymProfileId ?? activeGymId,
              );
        });
      }
    }

    // Adapt the gym-filtered result into the AsyncValue<ExerciseHistoryData>
    // the existing tab widgets consume, while keeping the rich result around
    // for the gym filter + multi-series chart.
    final historyAsync = resultAsync.whenData((r) => r.data);
    final result = resultAsync.valueOrNull;
    final prsAsync = ref.watch(
      gymExercisePRsProvider((
        exerciseName: widget.exerciseName,
        gymProfileId: selection.isAllGyms ? null : selection.gymProfileId,
        scope: selection.scope,
      )),
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Header with title
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(56, 12, 16, 8),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      widget.exerciseName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                SegmentedTabBar(
                  controller: _tabController,
                  showIcons: false,
                  tabs: [
                    SegmentedTabItem(label: AppLocalizations.of(context)!.exerciseProgressDetailProgress),
                    SegmentedTabItem(label: AppLocalizations.of(context)!.exerciseProgressDetailHistory),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Progress Tab
                      _ProgressTab(
                        exerciseName: widget.exerciseName,
                        surfaceKey: _surfaceKey,
                        historyAsync: historyAsync,
                        prsAsync: prsAsync,
                        result: result,
                        selection: selection,
                        args: args,
                      ),
                      // History Tab
                      _HistoryTab(
                        exerciseName: widget.exerciseName,
                        surfaceKey: _surfaceKey,
                        historyAsync: historyAsync,
                        result: result,
                        args: args,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Floating glass back button
            PositionedDirectional(top: 12,
              start: 12,
              child: GlassBackButton(
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tab showing progression charts and PRs
class _ProgressTab extends ConsumerWidget {
  final String exerciseName;
  final String surfaceKey;
  final AsyncValue<ExerciseHistoryData> historyAsync;
  final AsyncValue<List<ExercisePersonalRecord>> prsAsync;

  /// Full gym-filtered result (breakdown + tagged sessions) for the gym filter
  /// + multi-series chart. Null while the first fetch is in flight.
  final ExerciseHistoryResult? result;
  final GymProgressSelection selection;
  final GymExerciseHistoryArgs args;

  const _ProgressTab({
    required this.exerciseName,
    required this.surfaceKey,
    required this.historyAsync,
    required this.prsAsync,
    required this.result,
    required this.selection,
    required this.args,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final timeRange = ref.watch(exerciseHistoryTimeRangeProvider);
    final chartType = ref.watch(exerciseChartTypeProvider);
    final breakdown = result?.gymBreakdown ?? const <GymBreakdownEntry>[];

    // Cache-first: the exercise-history FutureProvider is not autoDispose, so
    // a return visit renders instantly; the cold load shows a layout-matched
    // skeleton (selectors + summary + chart) instead of a blocking spinner.
    return CacheFirstView<ExerciseHistoryData>(
      value: historyAsync,
      isFirstEver: !historyAsync.hasValue,
      traceLabel: 'exercise_progress_tab',
      skeletonBuilder: (_) => const _ProgressTabSkeleton(),
      errorBuilder: (_, error, __) => Center(child: Text('Error: $error')),
      contentBuilder: (context, history) {
        // Gym filter sits at the very top of Progress (the headline surface).
        // It hides itself when ≤1 gym is relevant. Empty per-gym history shows
        // a friendly empty state below — NOT a spinner.
        final gymFilter = GymProgressFilter(
          surfaceKey: surfaceKey,
          breakdown: breakdown,
          onChanged: (_) {
            // Refetch is automatic: the host's build re-watches
            // gymExerciseHistoryProvider with the new selection.
          },
        );

        if (!history.hasData) {
          return AppRefreshIndicator(
            onRefresh: () async => ref.invalidate(gymExerciseHistoryProvider(args)),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                gymFilter,
                const SizedBox(height: 16),
                _buildEmptyState(context, theme),
              ],
            ),
          );
        }

        // In "All gyms" mode for a per_gym exercise with ≥2 contributing gyms,
        // plot one gym-colored series per gym instead of a misleading merged
        // line. Otherwise the single-series ExerciseProgressionChart is fine.
        final perGymContributors =
            breakdown.where((b) => b.gymProfileId != null).length;
        final showMultiSeries = selection.isAllGyms &&
            result != null &&
            result!.isPerGym &&
            perGymContributors >= 2;

        return AppRefreshIndicator(
          onRefresh: () async {
            ref.invalidate(gymExerciseHistoryProvider(args));
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gym progress filter (headline differentiation).
                Padding(
                  padding: const EdgeInsets.only(left: 0, right: 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: gymFilter,
                  ),
                ),
                if (breakdown.length > 1) const SizedBox(height: 12),

                // Per-exercise strength score card (Surface 2) — the Gravl-style
                // hexagon score + best-lift grid, pinned to the top of Progress.
                ExerciseStrengthScoreCard(exerciseName: exerciseName),
                const SizedBox(height: 24),

                // Time range selector
                ExerciseTimeRangeSelector(
                  selected: timeRange,
                  onChanged: (value) {
                    ref.read(exerciseHistoryTimeRangeProvider.notifier).state = value;
                  },
                ),
                const SizedBox(height: 24),

                // Summary stats
                if (history.summary != null)
                  ExerciseSummaryCard(summary: history.summary!),
                const SizedBox(height: 24),

                // AI Progress Report (Gravl-style pros & cons) — the richer,
                // on-demand LLM layer. Fetches only when the user taps "Analyze
                // with AI" so there's no per-open model cost. Sits ABOVE the
                // always-instant deterministic insights card below.
                AiProgressProsConsCard(
                  exerciseName: exerciseName,
                  gymProfileId:
                      selection.isAllGyms ? null : selection.gymProfileId,
                  window: _windowForTimeRange(timeRange),
                ),
                const SizedBox(height: 16),

                // AI Insights (deterministic, instant fallback / summary).
                _ExerciseInsightsCard(
                  summary: history.summary,
                  chartData: history.weightChartData,
                  prsAsync: prsAsync,
                  exerciseName: exerciseName,
                ),
                const SizedBox(height: 16),

                // Chart type selector
                ExerciseChartTypeSelector(
                  selected: chartType,
                  onChanged: (value) {
                    ref.read(exerciseChartTypeProvider.notifier).state = value;
                  },
                ),
                const SizedBox(height: 16),

                // Progression chart — multi-series (one colored line per gym)
                // when pooling per-gym history, else the standard single line.
                if (showMultiSeries)
                  _MultiSeriesGymChart(
                    taggedSessions: result!.taggedSessions,
                    breakdown: breakdown,
                    chartType: chartType,
                  )
                else
                  ExerciseProgressionChart(
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
                    return ExercisePersonalRecordsSection(records: prs);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Maps the screen's fine-grained time-range selector onto the four windows
  /// the progress-analysis endpoint accepts (`'8w'`/`'6m'`/`'1y'`/`'all'`).
  /// Anything shorter than 8 weeks defaults to `'8w'` — the AI report needs a
  /// meaningful span to read a trend from.
  String _windowForTimeRange(ExerciseHistoryTimeRange range) {
    switch (range) {
      case ExerciseHistoryTimeRange.sixMonths:
        return '6m';
      case ExerciseHistoryTimeRange.oneYear:
        return '1y';
      case ExerciseHistoryTimeRange.allTime:
        return 'all';
      case ExerciseHistoryTimeRange.oneDay:
      case ExerciseHistoryTimeRange.threeDays:
      case ExerciseHistoryTimeRange.sevenDays:
      case ExerciseHistoryTimeRange.fourWeeks:
      case ExerciseHistoryTimeRange.eightWeeks:
      case ExerciseHistoryTimeRange.twelveWeeks:
        return '8w';
    }
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    // When a specific gym is selected but it has no history yet, say so plainly
    // (per the "No history at this gym yet" rule) rather than the generic copy.
    final isGymScoped = !selection.isAllGyms && selection.gymProfileId != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
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
              isGymScoped
                  ? 'No history at this gym yet'
                  : AppLocalizations.of(context)!
                      .exerciseProgressDetailNoDataForThis,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (isGymScoped) ...[
              const SizedBox(height: 6),
              Text(
                'Switch to "All gyms" to see your pooled history.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Multi-series progression chart: one gym-colored line per gym, used for the
/// "All gyms" view of a per_gym (machine/cable) exercise so the two machines
/// stay visually separate instead of pooling into one misleading line.
class _MultiSeriesGymChart extends StatelessWidget {
  final List<GymTaggedSession> taggedSessions;
  final List<GymBreakdownEntry> breakdown;
  final String chartType;

  const _MultiSeriesGymChart({
    required this.taggedSessions,
    required this.breakdown,
    required this.chartType,
  });

  double _valueFor(GymTaggedSession t) {
    switch (chartType) {
      case 'volume':
        return t.session.totalVolumeKg;
      case '1rm':
        return t.session.estimated1rmKg ?? 0;
      default:
        return t.session.weightKg;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Group sessions by gym, oldest → newest, dropping empty points.
    final byGym = <String, List<GymTaggedSession>>{};
    for (final t in taggedSessions) {
      final id = t.gymProfileId;
      if (id == null) continue;
      if (chartType == '1rm' && (t.session.estimated1rmKg ?? 0) <= 0) continue;
      byGym.putIfAbsent(id, () => []).add(t);
    }
    for (final list in byGym.values) {
      list.sort((a, b) => a.session.workoutDate.compareTo(b.session.workoutDate));
    }

    // A shared x-axis across all gyms keyed by sorted unique dates so the lines
    // align in time.
    final allDates = taggedSessions
        .where((t) => t.gymProfileId != null)
        .map((t) => t.session.workoutDate)
        .toSet()
        .toList()
      ..sort();
    final dateIndex = {for (var i = 0; i < allDates.length; i++) allDates[i]: i};

    if (allDates.length < 2) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            AppLocalizations.of(context).exerciseStatsWidgetsNotEnoughDataTo,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    // Resolve each gym's color from the breakdown.
    Color gymColor(String id) {
      final entry = breakdown.firstWhere(
        (b) => b.gymProfileId == id,
        orElse: () => const GymBreakdownEntry(
          gymProfileId: null,
          gymName: '',
          gymColor: null,
          sessionCount: 0,
        ),
      );
      final hex = entry.gymColor;
      if (hex != null && hex.isNotEmpty) {
        return GymProfileColors.fromHex(hex);
      }
      return theme.colorScheme.primary;
    }

    String gymName(String id) {
      final entry = breakdown.firstWhere(
        (b) => b.gymProfileId == id,
        orElse: () => GymBreakdownEntry(
          gymProfileId: id,
          gymName: 'Gym',
          gymColor: null,
          sessionCount: 0,
        ),
      );
      return entry.gymName;
    }

    final bars = <LineChartBarData>[];
    double minY = double.infinity;
    double maxY = -double.infinity;
    byGym.forEach((id, list) {
      final spots = <FlSpot>[];
      for (final t in list) {
        final x = dateIndex[t.session.workoutDate]?.toDouble();
        if (x == null) continue;
        final y = _valueFor(t);
        spots.add(FlSpot(x, y));
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
      if (spots.isEmpty) return;
      final color = gymColor(id);
      bars.add(
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
              radius: 3.5,
              color: color,
              strokeWidth: 2,
              strokeColor: theme.colorScheme.surface,
            ),
          ),
          belowBarData: BarAreaData(show: false),
        ),
      );
    });

    if (bars.isEmpty || !minY.isFinite || !maxY.isFinite) {
      return const SizedBox.shrink();
    }
    final pad = (maxY - minY).abs() < 0.01 ? 1.0 : (maxY - minY) * 0.1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: ((maxY - minY).abs() < 0.01)
                    ? 1
                    : (maxY - minY) / 4,
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    getTitlesWidget: (value, meta) => Text(
                      '${value.toInt()}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: (allDates.length / 4).ceilToDouble(),
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i >= 0 && i < allDates.length) {
                        final dt = DateTime.tryParse(allDates[i]);
                        return Text(
                          dt != null
                              ? '${dt.month}/${dt.day}'
                              : '',
                          style: theme.textTheme.bodySmall,
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              minY: minY - pad,
              maxY: maxY + pad,
              lineBarsData: bars,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Legend: one swatch per gym, color-coded.
        Wrap(
          spacing: 14,
          runSpacing: 6,
          children: byGym.keys.map((id) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: gymColor(id),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  gymName(id),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Tab showing list of all workout sessions
class _HistoryTab extends ConsumerWidget {
  final String exerciseName;
  final String surfaceKey;
  final AsyncValue<ExerciseHistoryData> historyAsync;
  final ExerciseHistoryResult? result;
  final GymExerciseHistoryArgs args;

  const _HistoryTab({
    required this.exerciseName,
    required this.surfaceKey,
    required this.historyAsync,
    required this.result,
    required this.args,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final breakdown = result?.gymBreakdown ?? const <GymBreakdownEntry>[];

    // Cache-first: skeleton list on cold load, instant on return visits.
    return CacheFirstView<ExerciseHistoryData>(
      value: historyAsync,
      isFirstEver: !historyAsync.hasValue,
      traceLabel: 'exercise_history_tab',
      skeletonBuilder: (_) => const SkeletonList(
        itemCount: 8,
        padding: EdgeInsets.all(16),
        scrollable: true,
      ),
      errorBuilder: (_, error, __) => Center(child: Text('Error: $error')),
      contentBuilder: (context, history) {
        final sessions = history.sortedSessionsNewestFirst;
        final gymFilter = GymProgressFilter(
          surfaceKey: surfaceKey,
          breakdown: breakdown,
        );

        if (sessions.isEmpty) {
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              gymFilter,
              const SizedBox(height: 32),
              Center(
                child: Text(
                  AppLocalizations.of(context)!
                      .exerciseProgressDetailNoSessionsRecorded,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ],
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 16, bottom: 16),
          itemCount: sessions.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: gymFilter,
              );
            }
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ExerciseSessionCard(session: sessions[index - 1]),
            );
          },
        );
      },
    );
  }
}

/// Layout-matched skeleton for the exercise Progress tab. Mirrors the real
/// content order — time-range selector, summary card, chart-type selector,
/// chart block — so the skeleton -> content cross-fade is reflow-free.
class _ProgressTabSkeleton extends StatelessWidget {
  const _ProgressTabSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: const [
        // Time-range selector.
        SkeletonBox(height: 36, radius: 18),
        SizedBox(height: 24),
        // Summary card.
        SkeletonBox(height: 110, radius: 16),
        SizedBox(height: 24),
        // Chart-type selector.
        SkeletonBox(height: 36, radius: 18),
        SizedBox(height: 16),
        // Progression chart block.
        SkeletonBox(height: 220, radius: 16),
      ],
    );
  }
}

class _ExerciseInsightsCard extends StatefulWidget {
  final ExerciseProgressionSummary? summary;
  final List<ExerciseChartDataPoint> chartData;
  final AsyncValue<List<ExercisePersonalRecord>> prsAsync;
  final String exerciseName;

  const _ExerciseInsightsCard({
    required this.summary,
    required this.chartData,
    required this.prsAsync,
    required this.exerciseName,
  });

  @override
  State<_ExerciseInsightsCard> createState() => _ExerciseInsightsCardState();
}

class _ExerciseInsightsCardState extends State<_ExerciseInsightsCard> {
  bool _expanded = true;

  // Memoized insight list. `_generateInsights()` walks the summary, chart data
  // and PR async value — recomputing it on every `setState(_expanded)` toggle
  // is wasted work, so it is cached and only rebuilt when the inputs change.
  late List<String> _insights;

  @override
  void initState() {
    super.initState();
    _insights = _generateInsights();
  }

  @override
  void didUpdateWidget(covariant _ExerciseInsightsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Inputs that feed _generateInsights() changed → recompute.
    if (oldWidget.summary != widget.summary ||
        oldWidget.prsAsync != widget.prsAsync ||
        oldWidget.chartData != widget.chartData) {
      _insights = _generateInsights();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final insights = _insights;

    if (insights.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.exerciseProgressDetailInsights,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: insights.map((insight) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('•  ', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(
                          insight,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
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
    final summary = widget.summary;

    if (summary == null) return insights;

    // Weight change insight
    if (summary.weightIncreaseKg != null && summary.weightIncreaseKg != 0) {
      final sign = summary.weightIncreaseKg! > 0 ? '+' : '';
      final weightStr = summary.weightIncreaseKg == summary.weightIncreaseKg!.toInt()
          ? '${summary.weightIncreaseKg!.toInt()}'
          : summary.weightIncreaseKg!.toStringAsFixed(1);

      if (summary.firstSessionDate != null) {
        try {
          final firstDate = DateTime.parse(summary.firstSessionDate!);
          final monthName = _monthName(firstDate.month);
          insights.add('Weight ${summary.weightIncreaseKg! > 0 ? 'up' : 'down'} $sign${weightStr}kg since $monthName ${firstDate.year}');
        } catch (_) {
          insights.add('Weight change: $sign${weightStr}kg');
        }
      }
    }

    // Sessions and frequency
    if (summary.totalSessions > 0) {
      final freqStr = summary.avgFrequencyPerWeek != null
          ? ', avg ${summary.avgFrequencyPerWeek!.toStringAsFixed(1)}x/week'
          : '';
      insights.add('${summary.totalSessions} sessions logged$freqStr');
    }

    // 1RM improvement
    if (summary.oneRmIncreaseKg != null && summary.oneRmIncreaseKg! > 0) {
      insights.add('Estimated 1RM improved by +${summary.oneRmIncreaseKg!.toStringAsFixed(1)}kg (${summary.formattedOneRmIncrease})');
    }

    // PR count
    if (summary.prCount != null && summary.prCount! > 0) {
      insights.add('${summary.prCount} personal records set');
    }

    // Recent PRs from async data
    widget.prsAsync.whenData((prs) {
      if (prs.isNotEmpty) {
        final latest = prs.first;
        try {
          final prDate = DateTime.parse(latest.achievedDate);
          final daysDiff = DateTime.now().difference(prDate).inDays;
          if (daysDiff <= 7) {
            insights.add('New PR! ${latest.formattedValue} (${daysDiff == 0 ? 'today' : daysDiff == 1 ? 'yesterday' : '$daysDiff days ago'})');
          }
        } catch (_) {}
      }
    });

    // Trend insight
    if (summary.trend != null) {
      switch (summary.trend!) {
        case 'improving':
          insights.add('Performance is trending upward — keep it up!');
          break;
        case 'declining':
          insights.add('Performance has been declining — consider adjusting volume or recovery');
          break;
        case 'maintaining':
          if (summary.totalSessions > 5) {
            insights.add('Performance is stable — try progressive overload to break through');
          }
          break;
      }
    }

    return insights;
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
