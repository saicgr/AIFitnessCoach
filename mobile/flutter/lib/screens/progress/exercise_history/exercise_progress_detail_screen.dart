import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/posthog_service.dart';
import '../../../data/models/exercise_history.dart';
import '../../../data/providers/exercise_history_provider.dart';
import '../../../data/repositories/exercise_history_repository.dart';
import '../../../widgets/exercise_stats_widgets.dart';
import '../../../widgets/glass_back_button.dart';
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

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(exerciseHistoryProvider(widget.exerciseName));
    final prsAsync = ref.watch(exercisePRsProvider(widget.exerciseName));

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
                  padding: const EdgeInsets.fromLTRB(56, 12, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
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
            // Floating glass back button
            Positioned(
              top: 12,
              left: 12,
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

                // AI Insights
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

                // Progression chart
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
            return ExerciseSessionCard(session: sessions[index]);
          },
        );
      },
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final insights = _generateInsights();

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
                    'Insights',
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
