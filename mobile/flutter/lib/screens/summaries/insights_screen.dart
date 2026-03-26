import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/insights_report.dart';
import '../../data/models/weekly_summary.dart';
import '../../data/providers/insights_provider.dart';
import '../../data/repositories/weekly_summary_repository.dart';
import '../../data/services/api_client.dart';
import '../../widgets/pill_app_bar.dart';

// ---------------------------------------------------------------------------
// InsightsScreen — main Insights tab replacing the old WeeklySummaryScreen.
// Shows period-selectable data cards and a list of past weekly reports.
// ---------------------------------------------------------------------------

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final userId = await ref.read(apiClientProvider).getUserId();
    if (!mounted || userId == null) return;
    setState(() => _userId = userId);
    ref.read(insightsProvider.notifier).loadReport(userId);
    ref.read(weeklySummaryProvider.notifier).loadSummaries(userId);
  }

  Future<void> _refresh() async {
    if (_userId == null) return;
    await Future.wait([
      ref.read(insightsProvider.notifier).loadReport(_userId!),
      ref.read(weeklySummaryProvider.notifier).loadSummaries(_userId!),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final insightsState = ref.watch(insightsProvider);
    final summaryState = ref.watch(weeklySummaryProvider);

    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: const PillAppBar(title: 'Insights'),
      body: Column(
        children: [
          // Period selector
          _PeriodSelector(
            selected: insightsState.selectedPeriod,
            isDark: isDark,
            onSelect: (period) {
              if (_userId == null) return;
              ref
                  .read(insightsProvider.notifier)
                  .selectPeriod(period, _userId!);
            },
          ),

          // Main content
          Expanded(
            child: insightsState.isLoadingReport
                ? _LoadingState(isDark: isDark)
                : insightsState.error != null && insightsState.report == null
                    ? _ErrorState(
                        error: insightsState.error!,
                        isDark: isDark,
                        onRetry: _refresh,
                      )
                    : RefreshIndicator(
                        onRefresh: _refresh,
                        color: purple,
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 8),

                            // Data cards
                            if (insightsState.report != null) ...[
                              _OverviewCard(
                                totals: insightsState.report!.totals,
                                previousTotals:
                                    insightsState.report!.previousTotals,
                                isDark: isDark,
                              )
                                  .animate()
                                  .fadeIn(delay: 50.ms)
                                  .slideY(begin: 0.1),
                              _NutritionCard(
                                totals: insightsState.report!.totals,
                                previousTotals:
                                    insightsState.report!.previousTotals,
                                isDark: isDark,
                              )
                                  .animate()
                                  .fadeIn(delay: 100.ms)
                                  .slideY(begin: 0.1),
                              _RecoveryCard(
                                totals: insightsState.report!.totals,
                                previousTotals:
                                    insightsState.report!.previousTotals,
                                isDark: isDark,
                              )
                                  .animate()
                                  .fadeIn(delay: 150.ms)
                                  .slideY(begin: 0.1),
                              _BodyCard(
                                totals: insightsState.report!.totals,
                                isDark: isDark,
                              )
                                  .animate()
                                  .fadeIn(delay: 200.ms)
                                  .slideY(begin: 0.1),
                            ],

                            // AI Narrative section
                            _AiNarrativeSection(
                              narrative: insightsState.narrative,
                              isGenerating: insightsState.isGeneratingNarrative,
                              hasReport: insightsState.report != null,
                              isDark: isDark,
                              onGenerate: () {
                                if (_userId == null) return;
                                ref
                                    .read(insightsProvider.notifier)
                                    .generateNarrative(_userId!);
                              },
                            )
                                .animate()
                                .fadeIn(delay: 250.ms)
                                .slideY(begin: 0.1),

                            const SizedBox(height: 24),

                            // Past Reports section
                            _SectionHeader(
                              title: 'Past Reports',
                              isDark: isDark,
                            ),
                            const SizedBox(height: 12),

                            if (summaryState.isLoading)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 32),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: purple,
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            else if (summaryState.summaries.isEmpty)
                              _EmptyPastReports(isDark: isDark)
                            else
                              ...summaryState.summaries
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                return _PastReportCard(
                                  summary: entry.value,
                                  isDark: isDark,
                                  onTap: () {
                                    context.push(
                                      '/insights/detail',
                                      extra: entry.value,
                                    );
                                  },
                                )
                                    .animate()
                                    .fadeIn(delay: (300 + 50 * entry.key).ms)
                                    .slideY(begin: 0.1);
                              }),

                            // Bottom padding for safe area
                            SizedBox(
                              height:
                                  MediaQuery.of(context).padding.bottom + 24,
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Period Selector — horizontal scrolling pill buttons
// ---------------------------------------------------------------------------

class _PeriodSelector extends StatelessWidget {
  final InsightsPeriod selected;
  final bool isDark;
  final ValueChanged<InsightsPeriod> onSelect;

  const _PeriodSelector({
    required this.selected,
    required this.isDark,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: InsightsPeriod.values.map((period) {
            final isSelected = period == selected;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onSelect(period),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? purple : elevated,
                    borderRadius: BorderRadius.circular(20),
                    border: isSelected
                        ? null
                        : Border.all(
                            color: isDark
                                ? AppColors.cardBorder
                                : AppColorsLight.cardBorder,
                          ),
                  ),
                  child: Text(
                    period.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : textMuted,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading State
// ---------------------------------------------------------------------------

class _LoadingState extends StatelessWidget {
  final bool isDark;

  const _LoadingState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final shimmerBase = isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.black.withOpacity(0.04);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(4, (index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: index == 0 ? 180 : 120,
          decoration: BoxDecoration(
            color: elevated,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [shimmerBase, shimmerBase.withOpacity(0), shimmerBase],
              ),
            ),
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .shimmer(
              duration: 1200.ms,
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.04),
            );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// Error State
// ---------------------------------------------------------------------------

class _ErrorState extends StatelessWidget {
  final String error;
  final bool isDark;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.error,
    required this.isDark,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final errorColor = isDark ? AppColors.error : AppColorsLight.error;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: errorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 48,
                color: errorColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Failed to load insights',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your connection and try again.',
              style: TextStyle(fontSize: 14, color: textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: OutlinedButton.styleFrom(
                foregroundColor: errorColor,
                side: BorderSide(color: errorColor),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Trend Chip — shows delta vs previous period with arrow
// ---------------------------------------------------------------------------

class _TrendChip extends StatelessWidget {
  final double current;
  final double previous;
  final String suffix;

  /// When true, a positive delta is good (green). When false, a negative
  /// delta is good (e.g. body fat decrease).
  final bool positiveIsGood;

  const _TrendChip({
    required this.current,
    required this.previous,
    this.suffix = '',
    this.positiveIsGood = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final delta = current - previous;
    if (delta == 0) return const SizedBox.shrink();

    final isPositive = delta > 0;
    final isGood = positiveIsGood ? isPositive : !isPositive;
    final color = isGood
        ? (isDark ? AppColors.success : AppColorsLight.success)
        : (isDark ? AppColors.coral : AppColorsLight.coral);

    final displayDelta = delta.abs();
    final deltaText = displayDelta == displayDelta.roundToDouble()
        ? '${displayDelta.toInt()}'
        : displayDelta.toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.arrow_upward : Icons.arrow_downward,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            '$deltaText$suffix',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Overview Card — workouts, time, calories, streak, PRs
// ---------------------------------------------------------------------------

class _OverviewCard extends StatelessWidget {
  final InsightsTotals totals;
  final InsightsTotals? previousTotals;
  final bool isDark;

  const _OverviewCard({
    required this.totals,
    this.previousTotals,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final orange = isDark ? AppColors.orange : AppColorsLight.orange;
    final success = isDark ? AppColors.success : AppColorsLight.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            purple.withOpacity(0.15),
            cyan.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: purple.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: purple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.fitness_center, color: purple, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Workouts completed / scheduled
          Row(
            children: [
              Text(
                '${totals.workoutsCompleted}',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
              ),
              Text(
                ' / ${totals.workoutsScheduled}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: textMuted,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'workouts',
                style: TextStyle(fontSize: 14, color: textSecondary),
              ),
              const Spacer(),
              if (previousTotals != null)
                _TrendChip(
                  current: totals.workoutsCompleted.toDouble(),
                  previous: previousTotals!.workoutsCompleted.toDouble(),
                ),
            ],
          ),

          // Completion rate bar
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: totals.completionRate / 100,
              backgroundColor: elevated,
              valueColor: AlwaysStoppedAnimation(purple),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${totals.completionRate.toStringAsFixed(0)}% completion rate',
            style: TextStyle(fontSize: 12, color: textMuted),
          ),

          const SizedBox(height: 16),

          // Stats row: time, calories, streak, PRs
          Row(
            children: [
              _MiniStat(
                icon: Icons.timer_outlined,
                value: _formatTime(totals.totalTimeMinutes),
                label: 'time',
                color: cyan,
                isDark: isDark,
                trend: previousTotals != null
                    ? _TrendChip(
                        current: totals.totalTimeMinutes.toDouble(),
                        previous: previousTotals!.totalTimeMinutes.toDouble(),
                        suffix: 'm',
                      )
                    : null,
              ),
              _MiniStat(
                icon: Icons.local_fire_department_outlined,
                value: _formatNumber(totals.totalCalories),
                label: 'kcal',
                color: orange,
                isDark: isDark,
                trend: previousTotals != null
                    ? _TrendChip(
                        current: totals.totalCalories.toDouble(),
                        previous: previousTotals!.totalCalories.toDouble(),
                      )
                    : null,
              ),
              _MiniStat(
                icon: Icons.whatshot_outlined,
                value: '${totals.maxStreak}',
                label: 'streak',
                color: orange,
                isDark: isDark,
              ),
              _MiniStat(
                icon: Icons.trending_up,
                value: '${totals.totalPrs}',
                label: 'PRs',
                color: success,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }

  String _formatNumber(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}

// ---------------------------------------------------------------------------
// Mini Stat — used inside the overview card stats row
// ---------------------------------------------------------------------------

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool isDark;
  final Widget? trend;

  const _MiniStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.isDark,
    this.trend,
  });

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: textMuted),
          ),
          if (trend != null) ...[
            const SizedBox(height: 4),
            trend!,
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Nutrition Card
// ---------------------------------------------------------------------------

class _NutritionCard extends StatelessWidget {
  final InsightsTotals totals;
  final InsightsTotals? previousTotals;
  final bool isDark;

  const _NutritionCard({
    required this.totals,
    this.previousTotals,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final success = isDark ? AppColors.success : AppColorsLight.success;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    final adherence = totals.avgNutritionAdherence;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            success.withOpacity(0.15),
            success.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: success.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: success.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    Icon(Icons.restaurant_outlined, color: success, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Nutrition',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (adherence != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${adherence.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    'adherence',
                    style: TextStyle(fontSize: 14, color: textSecondary),
                  ),
                ),
                const Spacer(),
                if (previousTotals?.avgNutritionAdherence != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _TrendChip(
                      current: adherence,
                      previous: previousTotals!.avgNutritionAdherence!,
                      suffix: '%',
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (adherence / 100).clamp(0.0, 1.0),
                backgroundColor: elevated,
                valueColor: AlwaysStoppedAnimation(success),
                minHeight: 6,
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Start tracking nutrition to see insights here',
                style: TextStyle(fontSize: 14, color: textMuted),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recovery Card — readiness score + mood distribution
// ---------------------------------------------------------------------------

class _RecoveryCard extends StatelessWidget {
  final InsightsTotals totals;
  final InsightsTotals? previousTotals;
  final bool isDark;

  const _RecoveryCard({
    required this.totals,
    this.previousTotals,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final orange = isDark ? AppColors.orange : AppColorsLight.orange;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    final readiness = totals.avgReadiness;
    final moods = totals.moodDistribution;
    final hasData = readiness != null || (moods != null && moods.isNotEmpty);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            orange.withOpacity(0.15),
            orange.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.battery_charging_full_outlined,
                    color: orange, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Recovery',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (!hasData)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Log your readiness and mood to see recovery insights',
                style: TextStyle(fontSize: 14, color: textMuted),
              ),
            )
          else ...[
            if (readiness != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    readiness.toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      ' / 100',
                      style: TextStyle(fontSize: 16, color: textMuted),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      'readiness',
                      style: TextStyle(fontSize: 14, color: textSecondary),
                    ),
                  ),
                  const Spacer(),
                  if (previousTotals?.avgReadiness != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _TrendChip(
                        current: readiness,
                        previous: previousTotals!.avgReadiness!,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (readiness / 100).clamp(0.0, 1.0),
                  backgroundColor: elevated,
                  valueColor: AlwaysStoppedAnimation(orange),
                  minHeight: 6,
                ),
              ),
            ],

            // Mood distribution chips
            if (moods != null && moods.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Mood Distribution',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: moods.entries.map((entry) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: elevated,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${_moodIcon(entry.key)} ${entry.value}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: textPrimary,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _moodIcon(String mood) {
    switch (mood.toLowerCase()) {
      case 'great':
      case 'amazing':
        return 'Great';
      case 'good':
        return 'Good';
      case 'okay':
      case 'neutral':
        return 'Okay';
      case 'tired':
      case 'low':
        return 'Tired';
      case 'bad':
      case 'terrible':
        return 'Bad';
      default:
        return mood;
    }
  }
}

// ---------------------------------------------------------------------------
// Body Card — weight and body fat changes
// ---------------------------------------------------------------------------

class _BodyCard extends StatelessWidget {
  final InsightsTotals totals;
  final bool isDark;

  const _BodyCard({
    required this.totals,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final coral = isDark ? AppColors.coral : AppColorsLight.coral;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final hasWeight = totals.weightChangeKg != null;
    final hasBodyFat = totals.bodyFatChange != null;

    if (!hasWeight && !hasBodyFat) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              coral.withOpacity(0.15),
              coral.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: coral.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: coral.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.monitor_weight_outlined,
                      color: coral, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Body',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Log your measurements to track body composition changes',
              style: TextStyle(fontSize: 14, color: textMuted),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            coral.withOpacity(0.15),
            coral.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: coral.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: coral.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.monitor_weight_outlined,
                    color: coral, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Body',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              if (hasWeight)
                Expanded(
                  child: _BodyMetric(
                    label: 'Weight',
                    value: totals.weightChangeKg!,
                    unit: 'kg',
                    isDark: isDark,
                  ),
                ),
              if (hasWeight && hasBodyFat) const SizedBox(width: 16),
              if (hasBodyFat)
                Expanded(
                  child: _BodyMetric(
                    label: 'Body Fat',
                    value: totals.bodyFatChange!,
                    unit: '%',
                    isDark: isDark,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BodyMetric extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final bool isDark;

  const _BodyMetric({
    required this.label,
    required this.value,
    required this.unit,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    // For body metrics, a decrease is typically desirable (losing weight/fat),
    // but this is context-dependent. Show neutral colors and let the user interpret.
    final isPositive = value > 0;
    final success = isDark ? AppColors.success : AppColorsLight.success;
    final coral = isDark ? AppColors.coral : AppColorsLight.coral;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                size: 18,
                color: isPositive ? coral : success,
              ),
              const SizedBox(width: 4),
              Text(
                '${value.abs().toStringAsFixed(1)} $unit',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AI Narrative Section
// ---------------------------------------------------------------------------

class _AiNarrativeSection extends StatelessWidget {
  final InsightsAiNarrative? narrative;
  final bool isGenerating;
  final bool hasReport;
  final bool isDark;
  final VoidCallback onGenerate;

  const _AiNarrativeSection({
    this.narrative,
    required this.isGenerating,
    required this.hasReport,
    required this.isDark,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;
    final orange = isDark ? AppColors.orange : AppColorsLight.orange;
    final success = isDark ? AppColors.success : AppColorsLight.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cyan.withOpacity(0.15),
            cyan.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cyan.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cyan.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.auto_awesome, color: cyan, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'AI Insights',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (isGenerating)
            // Shimmer loading state
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(4, (i) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  height: 14,
                  width: i == 3 ? 180 : double.infinity,
                  decoration: BoxDecoration(
                    color: elevated,
                    borderRadius: BorderRadius.circular(7),
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .shimmer(
                      duration: 1200.ms,
                      color: isDark
                          ? Colors.white.withOpacity(0.06)
                          : Colors.black.withOpacity(0.04),
                    );
              }),
            )
          else if (narrative != null) ...[
            // Summary
            Text(
              narrative!.summary,
              style: TextStyle(
                fontSize: 15,
                color: textPrimary,
                height: 1.5,
              ),
            ),

            // Highlights
            if (narrative!.highlights.isNotEmpty) ...[
              const SizedBox(height: 16),
              ...narrative!.highlights.map((highlight) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.star_rounded, color: orange, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          highlight,
                          style: TextStyle(
                            fontSize: 14,
                            color: textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],

            // Encouragement
            if (narrative!.encouragement.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: success.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.favorite_rounded, color: success, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        narrative!.encouragement,
                        style: TextStyle(
                          fontSize: 14,
                          color: textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Tips
            if (narrative!.tips.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Tips',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              ...narrative!.tips.asMap().entries.map((entry) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: elevated,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: purple.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${entry.key + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: purple,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            fontSize: 14,
                            color: textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ] else ...[
            // Generate button
            Text(
              hasReport
                  ? 'Get personalized AI analysis of your training data for this period.'
                  : 'Load your report data first, then generate AI insights.',
              style: TextStyle(fontSize: 14, color: textMuted),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: hasReport ? onGenerate : null,
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: const Text('Generate AI Insight'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cyan,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: elevated,
                  disabledForegroundColor: textMuted,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section Header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Past Report Card — compact card for weekly summary history
// ---------------------------------------------------------------------------

class _PastReportCard extends StatelessWidget {
  final WeeklySummary summary;
  final bool isDark;
  final VoidCallback onTap;

  const _PastReportCard({
    required this.summary,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
          ),
        ),
        child: Row(
          children: [
            // Date icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: purple.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _monthAbbr(summary.weekStart),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: purple,
                    ),
                  ),
                  Text(
                    _dayNumber(summary.weekStart),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: purple,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatWeekRange(summary.weekStart, summary.weekEnd),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${summary.workoutsCompleted}/${summary.workoutsScheduled} workouts  |  ${summary.totalTimeMinutes}min  |  ${summary.caloriesBurnedEstimate} kcal',
                    style: TextStyle(
                      fontSize: 12,
                      color: textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Completion badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _completionColor(summary.completionRate)
                    .withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${summary.completionRate.toInt()}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _completionColor(summary.completionRate),
                ),
              ),
            ),

            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Color _completionColor(double rate) {
    if (rate >= 80) return isDark ? AppColors.success : AppColorsLight.success;
    if (rate >= 50) return isDark ? AppColors.warning : AppColorsLight.warning;
    return isDark ? AppColors.error : AppColorsLight.error;
  }

  String _monthAbbr(String dateStr) {
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[date.month - 1];
  }

  String _dayNumber(String dateStr) {
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    return '${date.day}';
  }

  String _formatWeekRange(String start, String end) {
    final startDate = DateTime.tryParse(start);
    final endDate = DateTime.tryParse(end);
    if (startDate == null || endDate == null) return '$start - $end';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    if (startDate.month == endDate.month) {
      return '${months[startDate.month - 1]} ${startDate.day} - ${endDate.day}';
    }
    return '${months[startDate.month - 1]} ${startDate.day} - ${months[endDate.month - 1]} ${endDate.day}';
  }
}

// ---------------------------------------------------------------------------
// Empty Past Reports
// ---------------------------------------------------------------------------

class _EmptyPastReports extends StatelessWidget {
  final bool isDark;

  const _EmptyPastReports({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.history_outlined,
            size: 40,
            color: textMuted,
          ),
          const SizedBox(height: 12),
          Text(
            'No past reports yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color:
                  isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Weekly reports will appear here as they are generated.',
            style: TextStyle(fontSize: 13, color: textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
