import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/skeleton/skeleton.dart';
import '../../data/models/fasting_impact.dart';
import '../../data/providers/fasting_impact_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/context_logging_service.dart';
import '../../data/services/data_cache_service.dart';
import '../../widgets/pill_app_bar.dart';
import 'widgets/fasting_calendar_widget.dart';
import 'widgets/fasting_impact_card.dart';
import 'widgets/weight_fasting_chart.dart';

import '../../l10n/generated/app_localizations.dart';
/// Screen showing fasting impact analysis on goals
class FastingImpactScreen extends ConsumerStatefulWidget {
  const FastingImpactScreen({super.key});

  @override
  ConsumerState<FastingImpactScreen> createState() =>
      _FastingImpactScreenState();
}

class _FastingImpactScreenState extends ConsumerState<FastingImpactScreen> {
  String? _userId;

  /// Base SharedPreferences key for the cached impact analysis. The real key
  /// is per-period (see [_cacheKeyFor]) so switching Week/Month/3-Months each
  /// keeps its own instant-load snapshot.
  static const String _kImpactCacheBaseKey = 'cache_fasting_impact';

  /// Disk-hydrated impact snapshot for the CURRENTLY selected period. Used
  /// only to render real content while `fastingImpactProvider` is still
  /// loading on a cold start — once the network payload lands the provider's
  /// `state.data` wins. Null on a genuine first-ever open / cache miss.
  FastingImpactData? _cachedData;

  /// De-dupes the write-through so an unchanged payload is not re-serialized
  /// on every rebuild.
  String? _lastPersistedSignature;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Per-period cache key — keeps Week / Month / 3-Months snapshots distinct.
  String _cacheKeyFor(FastingImpactPeriod period) =>
      '${_kImpactCacheBaseKey}_${period.apiValue}';

  Future<void> _loadData() async {
    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;
    if (userId != null) {
      setState(() => _userId = userId);
      // Cache-first: hydrate the disk snapshot for the default period BEFORE
      // the network call so a cold start renders real content instantly
      // instead of a blocking spinner. Non-blocking, best-effort.
      _hydrateImpactFromCache(ref.read(fastingImpactProvider).selectedPeriod);
      ref.read(fastingImpactProvider.notifier).loadImpactData(userId: userId);

      // Log screen view for context tracking
      _logScreenOpened();
    }
  }

  /// Read the persisted [FastingImpactData] for [period] off disk and seed
  /// [_cachedData]. Best-effort: any miss / expiry / corruption simply leaves
  /// the field null and the screen shows its skeleton until the network
  /// resolves. Never throws.
  Future<void> _hydrateImpactFromCache(FastingImpactPeriod period) async {
    final userId = _userId;
    if (userId == null || userId.isEmpty) return;
    try {
      final cached = await DataCacheService.instance.getCached(
        _cacheKeyFor(period),
        userId: userId,
      );
      if (cached == null || !mounted) return;
      final data = FastingImpactData.fromJson(cached);
      setState(() => _cachedData = data);
    } catch (e) {
      debugPrint('🍽️ [FastingImpact] cache hydrate failed: $e');
    }
  }

  /// Persist the fresh [FastingImpactData] so the next cold start is instant.
  /// De-duplicated via [_lastPersistedSignature]. Best-effort — never throws.
  void _persistImpactSnapshot(FastingImpactData data) {
    final userId = _userId;
    if (userId == null || userId.isEmpty) return;
    final signature = '${data.period.apiValue}:${data.analysisDate}:'
        '${data.dailyData.length}:${data.overallCorrelationScore}';
    if (signature == _lastPersistedSignature) return;
    _lastPersistedSignature = signature;
    try {
      DataCacheService.instance.cache(
        _cacheKeyFor(data.period),
        data.toJson(),
        userId: userId,
      );
    } catch (e) {
      debugPrint('🍽️ [FastingImpact] cache write failed: $e');
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

    // Cache-first write-through: persist whenever the provider yields fresh
    // data so the next cold start is instant.
    ref.listen<FastingImpactState>(fastingImpactProvider, (_, next) {
      final data = next.data;
      if (data != null) _persistImpactSnapshot(data);
    });

    // The provider state is authoritative once it has data; otherwise fall
    // back to the disk snapshot so a cold start renders real content rather
    // than a blocking spinner.
    final effectiveData = state.data ?? _cachedData;
    // True first-ever open: loading, and nothing cached to show.
    final showSkeleton =
        state.data == null && _cachedData == null && state.error == null;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: PillAppBar(
        title: AppLocalizations.of(context).fastingImpactFastingImpact,
        actions: [
          PillAppBarAction(
            icon: Icons.refresh,
            visible: !state.isLoading && _userId != null,
            onTap: () => ref.read(fastingImpactProvider.notifier).refresh(_userId!),
          ),
        ],
      ),
      body: showSkeleton
          // Layout-matched skeleton instead of a blocking centered spinner.
          ? _buildSkeleton(context)
          : state.error != null && effectiveData == null
              ? _buildErrorState(state.error!, textPrimary, textMuted, purple)
              : effectiveData == null || effectiveData.dailyData.isEmpty
                  ? _buildEmptyState(textPrimary, textMuted, purple)
                  : _buildContent(context, state, isDark, effectiveData),
    );
  }

  /// Layout-matched loading placeholder — mirrors the period selector, the
  /// correlation summary card, the weight-trend chart and a couple of impact
  /// cards so the skeleton → content swap does not reflow. Shown only on a
  /// genuine first-ever open (no cached snapshot yet).
  Widget _buildSkeleton(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period selector row.
            Row(
              children: List.generate(
                3,
                (i) => Padding(
                  padding: EdgeInsetsDirectional.only(end: i == 2 ? 0 : 8),
                  child: const SkeletonBox(width: 72, height: 32, radius: 16),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Correlation summary card.
            SkeletonBox(
              height: 150,
              radius: 16,
              width: MediaQuery.of(context).size.width,
            ),
            const SizedBox(height: 24),
            SkeletonText(lines: 1, lineHeight: 16, radius: 6),
            const SizedBox(height: 12),
            // Weight-trend chart placeholder.
            SkeletonBox(
              height: 180,
              radius: 16,
              width: MediaQuery.of(context).size.width,
            ),
            const SizedBox(height: 24),
            // Impact comparison cards.
            const SkeletonCard(showLeading: false, lines: 3, height: 96),
            const SizedBox(height: 12),
            const SkeletonCard(showLeading: false, lines: 3, height: 96),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    FastingImpactState state,
    bool isDark,
    FastingImpactData data,
  ) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    // `data` is the effective payload — provider data when present, else the
    // disk snapshot. `hasEnoughData` is derived from it directly so the
    // not-enough-data banner is correct even while rendering from cache.
    final hasEnoughData = data.comparison.fastingDaysCount >= 3;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period Selector
          _buildPeriodSelector(state, purple, textMuted, elevated, isDark),

          // Not enough data warning
          if (!hasEnoughData)
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
                  AppLocalizations.of(context).fastingImpactWeightTrend,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context).fastingImpactFastingDaysMarkedWith,
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
                  AppLocalizations.of(context).fastingImpactFastingVsNonFasting,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                FastingImpactCard(
                  title: AppLocalizations.of(context).fastingImpactWeightImpact,
                  fastingValue:
                      AppLocalizations.of(context)!.fastingImpactScreenKg(data.comparison.weightLossFastingDays?.toStringAsFixed(2) ?? "N/A"),
                  nonFastingValue:
                      AppLocalizations.of(context)!.fastingImpactScreenKg2(data.comparison.weightLossNonFastingDays?.toStringAsFixed(2) ?? "N/A"),
                  fastingLabel: 'Avg daily change on fasting days',
                  nonFastingLabel: 'Avg daily change on non-fasting days',
                  correlation: data.weightCorrelation,
                  icon: Icons.monitor_weight_outlined,
                  isDark: isDark,
                ).animate().fadeIn(delay: 150.ms, duration: 300.ms),

                const SizedBox(height: 12),

                FastingImpactCard(
                  title: AppLocalizations.of(context).fastingImpactGoalAchievement,
                  fastingValue:
                      AppLocalizations.of(context)!.fastingImpactScreenValue((data.comparison.goalCompletionRateFasting * 100).round()),
                  nonFastingValue:
                      AppLocalizations.of(context)!.fastingImpactScreenValue2((data.comparison.goalCompletionRateNonFasting * 100).round()),
                  fastingLabel: 'Completion rate on fasting days',
                  nonFastingLabel: 'Completion rate on non-fasting days',
                  correlation: data.goalCorrelation,
                  icon: Icons.flag_outlined,
                  isDark: isDark,
                ).animate().fadeIn(delay: 200.ms, duration: 300.ms),

                const SizedBox(height: 12),

                if (data.comparison.avgWorkoutPerformanceFasting != null)
                  FastingImpactCard(
                    title: AppLocalizations.of(context).fastingImpactWorkoutPerformance,
                    fastingValue:
                        AppLocalizations.of(context)!.fastingImpactScreenValue3(((data.comparison.avgWorkoutPerformanceFasting ?? 0) * 100).round()),
                    nonFastingValue:
                        AppLocalizations.of(context)!.fastingImpactScreenValue4(((data.comparison.avgWorkoutPerformanceNonFasting ?? 0) * 100).round()),
                    fastingLabel: 'Avg performance on fasting days',
                    nonFastingLabel: 'Avg performance on non-fasting days',
                    correlation: data.workoutCorrelation,
                    icon: Icons.fitness_center,
                    isDark: isDark,
                  ).animate().fadeIn(delay: 250.ms, duration: 300.ms),

                const SizedBox(height: 24),

                // Calendar View
                Text(
                  AppLocalizations.of(context).fastingImpactActivityCalendar,
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
                    AppLocalizations.of(context).fastingImpactAiInsights,
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
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
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
                      AppLocalizations.of(context).fastingImpactOverallImpactScore,
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
                  AppLocalizations.of(context).fastingImpactLimitedDataAvailable,
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
                  AppLocalizations.of(context).fastingImpactCompleteMoreFastsTo,
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
              AppLocalizations.of(context).strainDashboardFailedToLoadData,
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
              label: Text(AppLocalizations.of(context).buttonRetry),
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
              AppLocalizations.of(context).fastingImpactNoImpactDataYet,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context).fastingImpactCompleteSomeFastsAnd,
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
              label: Text(AppLocalizations.of(context).startFastStartAFast),
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
