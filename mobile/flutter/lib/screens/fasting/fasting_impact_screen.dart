import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/fasting_impact.dart';
import '../../data/providers/fasting_impact_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/context_logging_service.dart';
import 'widgets/fasting_calendar_widget.dart';
import 'widgets/fasting_impact_card.dart';
import 'widgets/weight_fasting_chart.dart';

/// Screen showing fasting impact analysis on goals
class FastingImpactScreen extends ConsumerStatefulWidget {
  const FastingImpactScreen({super.key});

  @override
  ConsumerState<FastingImpactScreen> createState() =>
      _FastingImpactScreenState();
}

class _FastingImpactScreenState extends ConsumerState<FastingImpactScreen> {
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;
    if (userId != null) {
      setState(() => _userId = userId);
      ref.read(fastingImpactProvider.notifier).loadImpactData(userId: userId);

      // Log screen view for context tracking
      _logScreenOpened();
    }
  }

  /// Log when the fasting impact screen is opened
  void _logScreenOpened() {
    final state = ref.read(fastingImpactProvider);
    ref.read(contextLoggingServiceProvider).logFastingImpactViewed(
          period: state.selectedPeriod.apiValue,
          correlationScore: state.data?.overallCorrelationScore,
          insightType: state.data?.overallCorrelation.name,
          fastingDaysAnalyzed: state.data?.comparison.fastingDaysCount,
          nonFastingDaysAnalyzed: state.data?.comparison.nonFastingDaysCount,
        );
  }

  /// Log when period is changed
  void _logPeriodChanged(FastingImpactPeriod newPeriod) {
    ref.read(contextLoggingServiceProvider).logFeatureInteraction(
          feature: 'fasting_impact',
          action: 'period_changed',
          data: {
            'new_period': newPeriod.apiValue,
            'period_days': newPeriod.days,
          },
        );
  }

  /// Log when calendar section is scrolled into view
  void _logCalendarViewed() {
    final state = ref.read(fastingImpactProvider);
    if (state.data != null) {
      final now = DateTime.now();
      ref.read(contextLoggingServiceProvider).logFastingCalendarViewed(
            month: now.month,
            year: now.year,
            fastingDaysInMonth: state.data!.comparison.fastingDaysCount,
            weightLogsInMonth: state.data!.dailyData
                .where((d) => d.weight != null)
                .length,
          );
    }
  }

  /// Log when AI insight is viewed
  void _logInsightViewed(FastingInsight insight) {
    ref.read(contextLoggingServiceProvider).logFastingInsightReceived(
          insightType: insight.insightType,
          insightTitle: insight.title,
          recommendation: insight.actionText,
          correlationScore: insight.confidence,
          wasAIGenerated: true,
        );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    final state = ref.watch(fastingImpactProvider);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Fasting Impact',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: textMuted),
            onPressed: state.isLoading || _userId == null
                ? null
                : () => ref
                    .read(fastingImpactProvider.notifier)
                    .refresh(_userId!),
          ),
        ],
      ),
      body: state.isLoading
          ? Center(child: CircularProgressIndicator(color: purple))
          : state.error != null
              ? _buildErrorState(state.error!, textPrimary, textMuted, purple)
              : !state.hasData
                  ? _buildEmptyState(textPrimary, textMuted, purple)
                  : _buildContent(context, state, isDark),
    );
  }

  Widget _buildContent(
      BuildContext context, FastingImpactState state, bool isDark) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final data = state.data!;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period Selector
          _buildPeriodSelector(state, purple, textMuted, elevated, isDark),

          // Not enough data warning
          if (!state.hasEnoughData)
            _buildNotEnoughDataBanner(isDark)
                .animate()
                .fadeIn(duration: 300.ms),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Overall Correlation Score Card
                _buildCorrelationSummary(data, isDark)
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: 0.1, end: 0),

                const SizedBox(height: 24),

                // Weight Trend Chart
                Text(
                  'Weight Trend',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Fasting days marked with purple dots',
                  style: TextStyle(fontSize: 13, color: textMuted),
                ),
                const SizedBox(height: 12),
                WeightFastingChart(
                  dailyData: data.dailyData,
                  isDark: isDark,
                ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

                const SizedBox(height: 24),

                // Impact Comparison Cards
                Text(
                  'Fasting vs Non-Fasting Days',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                FastingImpactCard(
                  title: 'Weight Impact',
                  fastingValue:
                      '${data.comparison.weightLossFastingDays?.toStringAsFixed(2) ?? "N/A"} kg',
                  nonFastingValue:
                      '${data.comparison.weightLossNonFastingDays?.toStringAsFixed(2) ?? "N/A"} kg',
                  fastingLabel: 'Avg daily change on fasting days',
                  nonFastingLabel: 'Avg daily change on non-fasting days',
                  correlation: data.weightCorrelation,
                  icon: Icons.monitor_weight_outlined,
                  isDark: isDark,
                ).animate().fadeIn(delay: 150.ms, duration: 300.ms),

                const SizedBox(height: 12),

                FastingImpactCard(
                  title: 'Goal Achievement',
                  fastingValue:
                      '${(data.comparison.goalCompletionRateFasting * 100).round()}%',
                  nonFastingValue:
                      '${(data.comparison.goalCompletionRateNonFasting * 100).round()}%',
                  fastingLabel: 'Completion rate on fasting days',
                  nonFastingLabel: 'Completion rate on non-fasting days',
                  correlation: data.goalCorrelation,
                  icon: Icons.flag_outlined,
                  isDark: isDark,
                ).animate().fadeIn(delay: 200.ms, duration: 300.ms),

                const SizedBox(height: 12),

                if (data.comparison.avgWorkoutPerformanceFasting != null)
                  FastingImpactCard(
                    title: 'Workout Performance',
                    fastingValue:
                        '${((data.comparison.avgWorkoutPerformanceFasting ?? 0) * 100).round()}%',
                    nonFastingValue:
                        '${((data.comparison.avgWorkoutPerformanceNonFasting ?? 0) * 100).round()}%',
                    fastingLabel: 'Avg performance on fasting days',
                    nonFastingLabel: 'Avg performance on non-fasting days',
                    correlation: data.workoutCorrelation,
                    icon: Icons.fitness_center,
                    isDark: isDark,
                  ).animate().fadeIn(delay: 250.ms, duration: 300.ms),

                const SizedBox(height: 24),

                // Calendar View
                Text(
                  'Activity Calendar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                FastingCalendarWidget(
                  dailyData: data.dailyData,
                  isDark: isDark,
                  userId: _userId,
                  onDayMarked: () {
                    // Refresh data when a day is marked
                    if (_userId != null) {
                      ref.read(fastingImpactProvider.notifier).refresh(_userId!);
                    }
                  },
                ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

                const SizedBox(height: 24),

                // AI Insights Section
                if (data.insights.isNotEmpty) ...[
                  Text(
                    'AI Insights',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...data.insights.asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildInsightCard(entry.value, isDark)
                          .animate()
                          .fadeIn(
                              delay: Duration(milliseconds: 350 + entry.key * 50),
                              duration: 300.ms),
                    );
                  }),
                ],

                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(
    FastingImpactState state,
    Color purple,
    Color textMuted,
    Color elevated,
    bool isDark,
  ) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: FastingImpactPeriod.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final period = FastingImpactPeriod.values[index];
          final isSelected = period == state.selectedPeriod;

          return ChoiceChip(
            label: Text(period.displayName),
            selected: isSelected,
            onSelected: (_userId != null && !state.isLoading)
                ? (_) {
                    _logPeriodChanged(period);
                    ref
                        .read(fastingImpactProvider.notifier)
                        .setPeriod(period, _userId!);
                  }
                : null,
            selectedColor: purple,
            labelStyle: TextStyle(
              color: isSelected
                  ? Colors.white
                  : (isDark
                      ? AppColors.textSecondary
                      : AppColorsLight.textSecondary),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            backgroundColor: elevated,
            side: BorderSide(
              color: isSelected
                  ? purple
                  : (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          );
        },
      ),
    );
  }

  Widget _buildCorrelationSummary(FastingImpactData data, bool isDark) {
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    final correlation = data.overallCorrelation;
    final score = data.overallCorrelationScore;

    Color getCorrelationColor() {
      if (correlation.isPositive) return AppColors.success;
      if (correlation.isNegative) return AppColors.coral;
      return AppColors.warning;
    }

    IconData getCorrelationIcon() {
      if (correlation.isPositive) return Icons.trending_up;
      if (correlation.isNegative) return Icons.trending_down;
      return Icons.trending_flat;
    }

    String getCorrelationText() {
      if (score >= 0.5) {
        return 'Strong positive impact on your goals';
      } else if (score >= 0.2) {
        return 'Moderate positive impact on your goals';
      } else if (score >= -0.2) {
        return 'Neutral impact on your goals';
      } else if (score >= -0.5) {
        return 'Slight negative impact on goals';
      } else {
        return 'Consider adjusting your fasting approach';
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            purple.withOpacity(0.15),
            purple.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: purple.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: getCorrelationColor().withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  getCorrelationIcon(),
                  color: getCorrelationColor(),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overall Impact Score',
                      style: TextStyle(
                        fontSize: 14,
                        color: textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${(score.abs() * 100).round()}',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          '%',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: textMuted,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: getCorrelationColor().withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            correlation.displayName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: getCorrelationColor(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar visualization
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (score.abs()).clamp(0.0, 1.0),
              backgroundColor: (isDark ? Colors.white : Colors.black)
                  .withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(getCorrelationColor()),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            getCorrelationText(),
            style: TextStyle(
              fontSize: 14,
              color: textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          if (data.summaryText != null) ...[
            const SizedBox(height: 8),
            Text(
              data.summaryText!,
              style: TextStyle(
                fontSize: 13,
                color: textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInsightCard(FastingInsight insight, bool isDark) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    Color getInsightColor() {
      switch (insight.insightType) {
        case 'positive':
          return AppColors.success;
        case 'warning':
          return AppColors.coral;
        case 'suggestion':
          return AppColors.cyan;
        default:
          return isDark ? AppColors.purple : AppColorsLight.purple;
      }
    }

    IconData getInsightIcon() {
      switch (insight.icon) {
        case 'scale':
          return Icons.monitor_weight_outlined;
        case 'target':
          return Icons.flag_outlined;
        case 'clock':
          return Icons.schedule;
        case 'fire':
          return Icons.local_fire_department;
        case 'workout':
          return Icons.fitness_center;
        default:
          if (insight.isPositive) return Icons.check_circle_outline;
          if (insight.isWarning) return Icons.warning_amber_outlined;
          return Icons.lightbulb_outline;
      }
    }

    final color = getInsightColor();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              getInsightIcon(),
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: textMuted,
                    height: 1.4,
                  ),
                ),
                if (insight.actionText != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    insight.actionText!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (insight.confidence != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${(insight.confidence! * 100).round()}%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotEnoughDataBanner(bool isDark) {
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.warning,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Limited Data Available',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textPrimary
                        : AppColorsLight.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Complete more fasts to get accurate impact analysis. We recommend at least 7 fasting days.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.textMuted
                        : AppColorsLight.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
      String error, Color textPrimary, Color textMuted, Color purple) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.coral,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to Load Data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: textMuted),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _userId != null
                  ? () => ref
                      .read(fastingImpactProvider.notifier)
                      .refresh(_userId!)
                  : null,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: purple,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color textPrimary, Color textMuted, Color purple) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 80,
              color: purple.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No Impact Data Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Complete some fasts and log your weight to see how fasting impacts your goals.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.timer),
              label: const Text('Start a Fast'),
              style: ElevatedButton.styleFrom(
                backgroundColor: purple,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
