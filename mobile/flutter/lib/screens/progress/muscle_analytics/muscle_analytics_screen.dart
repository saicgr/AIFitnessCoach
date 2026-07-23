import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/posthog_service.dart';
import '../../../core/widgets/skeleton/skeleton.dart';
import '../../../data/models/muscle_analytics.dart';
import '../../../data/providers/muscle_analytics_provider.dart';
import '../../../data/repositories/muscle_analytics_repository.dart';
import '../../../utils/share_report_helper.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../widgets/pill_app_bar.dart';
import '../../../widgets/segmented_tab_bar.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/design_system/zealova.dart';
import '../widgets/gym_progress_filter.dart';
import 'widgets/muscle_heatmap_widget.dart';
import 'widgets/muscle_balance_chart.dart';
import 'widgets/muscle_frequency_chart.dart';
import 'package:fitwiz/core/constants/branding.dart';
import '../../common/app_refresh_indicator.dart';

/// Main muscle analytics dashboard with tabs for heatmap, frequency, and balance
class MuscleAnalyticsScreen extends ConsumerStatefulWidget {
  const MuscleAnalyticsScreen({super.key});

  @override
  ConsumerState<MuscleAnalyticsScreen> createState() => _MuscleAnalyticsScreenState();
}

class _MuscleAnalyticsScreenState extends ConsumerState<MuscleAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey _reportKey = GlobalKey();
  DateTime? _screenOpenTime;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _screenOpenTime = DateTime.now();
    ref.read(posthogServiceProvider).capture(eventName: 'muscle_analytics_viewed');
  }

  @override
  void dispose() {
    _logViewDuration();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      ref.read(muscleAnalyticsTabProvider.notifier).state = _tabController.index;
    }
  }

  void _logViewDuration() {
    if (_screenOpenTime == null) return;
    final duration = DateTime.now().difference(_screenOpenTime!).inSeconds;
    // Called from `dispose()`, where `ref` may already be invalidated if
    // the route was popped under teardown. The fire-and-forget log isn't
    // worth crashing the app for — swallow scope errors and move on.
    try {
      ref.read(muscleAnalyticsRepositoryProvider).logView(
        viewType: 'dashboard',
        sessionDurationSeconds: duration,
      );
    } catch (e) {
      debugPrint('⚠️ [MuscleAnalytics] view-duration log skipped: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeRange = ref.watch(muscleAnalyticsTimeRangeProvider);

    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: PillAppBar(
        title: l10n.muscleAnalyticsMuscleTrends,
        actions: [
          PillAppBarAction(
            icon: Icons.ios_share_rounded,
            onTap: () => shareReportScreen(
              context: context,
              repaintKey: _reportKey,
              caption: 'My ${Branding.appName} muscle strength report',
              subject: 'My Muscle Report',
            ),
          ),
          PillAppBarAction(
            icon: Icons.calendar_today,
            onTap: () {
              // Anchor below the right-side action pill instead of the
              // fixed (100,100) coords that previously dropped the menu
              // mid-screen on every device size.
              final size = MediaQuery.of(context).size;
              final top = MediaQuery.of(context).padding.top + 60;
              showMenu(
                context: context,
                position: RelativeRect.fromLTRB(size.width - 220, top, 16, 0),
                items: [
                  _buildTimeRangeItem('1_day', '1D', timeRange),
                  _buildTimeRangeItem('3_days', '3D', timeRange),
                  _buildTimeRangeItem('7_days', '7D', timeRange),
                  _buildTimeRangeItem('2_weeks', '2W', timeRange),
                  _buildTimeRangeItem('4_weeks', '4W', timeRange),
                  _buildTimeRangeItem('8_weeks', '8W', timeRange),
                  _buildTimeRangeItem('12_weeks', '12W', timeRange),
                ],
              ).then((value) {
                if (value != null) {
                  ref.read(muscleAnalyticsTimeRangeProvider.notifier).state = value;
                }
              });
            },
          ),
        ],
      ),
      body: RepaintBoundary(
        key: _reportKey,
        child: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Column(
        children: [
          SegmentedTabBar(
            controller: _tabController,
            showIcons: false,
            tabs: [
              SegmentedTabItem(label: l10n.muscleAnalyticsHeatmap),
              SegmentedTabItem(label: l10n.muscleAnalyticsFrequency),
              SegmentedTabItem(label: l10n.muscleAnalyticsBalance),
            ],
          ),
          // Gym progress filter — hides itself when ≤1 gym. The heatmap /
          // frequency / balance providers watch this same surface's selection
          // (via muscleAnalyticsGymProfileIdProvider), so tapping a chip
          // re-scopes all three tabs automatically. onChanged invalidates them
          // belt-and-suspenders so a refetch fires even on a re-tap of the same
          // resolved value.
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: GymProgressFilter(
              surfaceKey: muscleAnalyticsGymSurfaceKey,
              onChanged: (_) {
                ref.invalidate(muscleHeatmapProvider);
                ref.invalidate(muscleFrequencyProvider);
                ref.invalidate(muscleBalanceProvider);
              },
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _HeatmapTab(),
                _FrequencyTab(),
                _BalanceTab(),
              ],
            ),
          ),
        ],
      ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildTimeRangeItem(String value, String label, String selected) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          if (value == selected) const Icon(Icons.check, size: 18),
          if (value == selected) const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

/// Heatmap tab showing muscle training intensity
class _HeatmapTab extends ConsumerWidget {
  const _HeatmapTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final heatmapAsync = ref.watch(muscleHeatmapProvider);

    // Cache-first: render a layout-matched skeleton on a cold load; once data
    // exists keep it on screen during silent revalidation / transient errors.
    return CacheFirstView<MuscleHeatmapData>(
      value: heatmapAsync,
      isFirstEver: !heatmapAsync.hasValue,
      traceLabel: 'muscle_heatmap_tab',
      skeletonBuilder: (_) => const _AnalyticsTabSkeleton(),
      errorBuilder: (_, __, ___) => _ErrorWidget(
        message: 'Failed to load muscle data',
        onRetry: () => ref.invalidate(muscleHeatmapProvider),
      ),
      contentBuilder: (context, heatmap) {
        if (!heatmap.hasData) {
          return _EmptyWidget(
            icon: Icons.fitness_center_outlined,
            title: l10n.muscleAnalyticsNoTrainingData,
            message: l10n.muscleAnalyticsCompleteSomeWorkoutsTo,
          );
        }

        // Memoize the sorted list once per build — `sortedByIntensity` does a
        // full copy + sort and was previously evaluated three times
        // (.first, .last, .map) in this chart-heavy tree.
        final sorted = heatmap.sortedByIntensity;

        return AppRefreshIndicator(
          onRefresh: () async => ref.invalidate(muscleHeatmapProvider),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary tiles — hairline-divided Anton numerals.
                _StatTileRow(
                  tiles: [
                    _StatTileData(
                      label: l10n.muscleAnalyticsMostTrained,
                      value: _formatMuscleName(sorted.first.muscleId),
                      icon: Icons.local_fire_department_outlined,
                      accentValue: true,
                    ),
                    _StatTileData(
                      label: l10n.muscleAnalyticsLeastTrained,
                      value: _formatMuscleName(sorted.last.muscleId),
                      icon: Icons.trending_down_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Muscle heatmap visualization
                ZealovaSectionKicker(l10n.muscleAnalyticsTrainingIntensity),
                const SizedBox(height: 16),
                MuscleHeatmapWidget(
                  heatmap: heatmap,
                  onMuscleTap: (muscleId) {
                    context.push('/stats/muscle-analytics/${Uri.encodeComponent(muscleId)}');
                  },
                ),

                const SizedBox(height: 24),

                // Top muscles list
                ZealovaSectionKicker(l10n.muscleAnalyticsMuscleBreakdown),
                const SizedBox(height: 12),
                ...sorted.map((muscle) => _MuscleListItem(
                  muscle: muscle,
                  maxIntensity: heatmap.maxIntensity ?? 1,
                  onTap: () {
                    context.push('/stats/muscle-analytics/${Uri.encodeComponent(muscle.muscleId)}');
                  },
                )),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatMuscleName(String name) {
    return name
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}

/// Frequency tab showing training frequency per muscle
class _FrequencyTab extends ConsumerWidget {
  const _FrequencyTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final frequencyAsync = ref.watch(muscleFrequencyProvider);

    // Cache-first: skeleton on cold load, content kept during revalidation.
    return CacheFirstView<MuscleTrainingFrequency>(
      value: frequencyAsync,
      isFirstEver: !frequencyAsync.hasValue,
      traceLabel: 'muscle_frequency_tab',
      skeletonBuilder: (_) => const _AnalyticsTabSkeleton(),
      errorBuilder: (_, __, ___) => _ErrorWidget(
        message: 'Failed to load frequency data',
        onRetry: () => ref.invalidate(muscleFrequencyProvider),
      ),
      contentBuilder: (context, frequency) {
        if (!frequency.hasData) {
          return _EmptyWidget(
            icon: Icons.calendar_today,
            title: l10n.muscleAnalyticsNoFrequencyData,
            message: l10n.muscleAnalyticsCompleteWorkoutsOverMultipl,
          );
        }

        final undertrained = frequency.frequencies.where((f) => f.isUndertrained).toList();
        final overtrained = frequency.frequencies.where((f) => f.isOvertrained).toList();

        return AppRefreshIndicator(
          onRefresh: () async => ref.invalidate(muscleFrequencyProvider),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary tiles — hairline-divided Anton numerals.
                _StatTileRow(
                  tiles: [
                    _StatTileData(
                      label: l10n.muscleAnalyticsUndertrained,
                      value: '${undertrained.length}',
                      unit: 'muscles',
                      icon: Icons.arrow_downward,
                    ),
                    _StatTileData(
                      label: l10n.muscleAnalyticsOvertrained,
                      value: '${overtrained.length}',
                      unit: 'muscles',
                      icon: Icons.arrow_upward,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Frequency chart
                ZealovaSectionKicker(l10n.muscleAnalyticsWeeklyTrainingFrequency),
                const SizedBox(height: 16),
                MuscleFrequencyChart(frequency: frequency),

                const SizedBox(height: 24),

                // Recommendations
                if (undertrained.isNotEmpty || overtrained.isNotEmpty) ...[
                  ZealovaSectionKicker(l10n.muscleAnalyticsRecommendations),
                  const SizedBox(height: 12),
                  if (undertrained.isNotEmpty)
                    _RecommendationCard(
                      title: l10n.muscleAnalyticsTrainMore,
                      muscles: undertrained.map((f) => f.formattedMuscleGroup).toList(),
                      icon: Icons.add_circle_outline,
                      semantic: _RecSemantic.under,
                    ),
                  if (overtrained.isNotEmpty)
                    _RecommendationCard(
                      title: l10n.muscleAnalyticsAllowRecovery,
                      muscles: overtrained.map((f) => f.formattedMuscleGroup).toList(),
                      icon: Icons.remove_circle_outline,
                      semantic: _RecSemantic.over,
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Balance tab showing push/pull and upper/lower ratios
class _BalanceTab extends ConsumerWidget {
  const _BalanceTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final balanceAsync = ref.watch(muscleBalanceProvider);

    // Cache-first: skeleton on cold load, content kept during revalidation.
    return CacheFirstView<MuscleBalanceData>(
      value: balanceAsync,
      isFirstEver: !balanceAsync.hasValue,
      traceLabel: 'muscle_balance_tab',
      skeletonBuilder: (_) => const _AnalyticsTabSkeleton(),
      errorBuilder: (_, __, ___) => _ErrorWidget(
        message: 'Failed to load balance data',
        onRetry: () => ref.invalidate(muscleBalanceProvider),
      ),
      contentBuilder: (context, balance) {
        if (!balance.hasData) {
          return _EmptyWidget(
            icon: Icons.balance,
            title: l10n.muscleAnalyticsNoBalanceData,
            message: l10n.muscleAnalyticsCompleteMoreWorkoutsTo,
          );
        }

        return AppRefreshIndicator(
          onRefresh: () async => ref.invalidate(muscleBalanceProvider),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Balance score
                _BalanceScoreCard(
                  score: balance.balanceScore ?? 0,
                  status: balance.isPushPullBalanced && balance.isUpperLowerBalanced
                      ? l10n.muscleAnalyticsBalanced
                      : l10n.muscleAnalyticsNeedsWork,
                ),
                const SizedBox(height: 24),

                // Balance ratios
                ZealovaSectionKicker(l10n.muscleAnalyticsBalanceRatios),
                const SizedBox(height: 16),
                MuscleBalanceChart(balance: balance),

                const SizedBox(height: 24),

                // Detailed ratios
                _RatioCard(
                  title: l10n.muscleAnalyticsPushPull,
                  ratio: balance.formattedPushPullRatio,
                  side1Label: l10n.muscleBalanceChartPush,
                  side1Value: balance.formattedPushVolume,
                  side2Label: l10n.muscleBalanceChartPull,
                  side2Value: balance.formattedPullVolume,
                  isBalanced: balance.isPushPullBalanced,
                ),
                const SizedBox(height: 12),
                _RatioCard(
                  title: l10n.muscleAnalyticsUpperLower,
                  ratio: balance.formattedUpperLowerRatio,
                  side1Label: l10n.muscleBalanceChartUpper,
                  side1Value: balance.upperVolumeKg != null ? '${balance.upperVolumeKg!.toInt()} kg' : '-',
                  side2Label: l10n.muscleBalanceChartLower,
                  side2Value: balance.lowerVolumeKg != null ? '${balance.lowerVolumeKg!.toInt()} kg' : '-',
                  isBalanced: balance.isUpperLowerBalanced,
                ),

                // Recommendations
                if (balance.recommendations != null && balance.recommendations!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  ZealovaSectionKicker(l10n.muscleAnalyticsRecommendations),
                  const SizedBox(height: 12),
                  ...balance.recommendations!.map((rec) => _RecommendationRow(text: rec)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// Helper Widgets
// ============================================================================

/// Immutable spec for one hairline stat tile in [_StatTileRow].
class _StatTileData {
  final String label;
  final String value;
  final String? unit;
  final IconData icon;
  final bool accentValue;

  const _StatTileData({
    required this.label,
    required this.value,
    required this.icon,
    this.unit,
    this.accentValue = false,
  });
}

/// Two summary stats laid out as hairline-outlined tiles (Anton numeral over a
/// Barlow uppercase label) split by a vertical hairline — the v2 STATS HUB
/// tile language, replacing the old boxed Material `Card` pair.
class _StatTileRow extends StatelessWidget {
  final List<_StatTileData> tiles;

  const _StatTileRow({required this.tiles});

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
            for (var i = 0; i < tiles.length; i++) ...[
              if (i > 0) Container(width: 1, color: AppColors.hairline),
              Expanded(child: _StatTile(data: tiles[i])),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final _StatTileData data;

  const _StatTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(data.icon,
                  size: 16,
                  color: data.accentValue ? tc.accent : tc.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  data.label.toUpperCase(),
                  style: ZType.lbl(10, color: tc.textMuted, letterSpacing: 1.4),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            data.value,
            style: ZType.disp(22,
                color: data.accentValue ? tc.accent : tc.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (data.unit != null) ...[
            const SizedBox(height: 2),
            Text(
              data.unit!.toUpperCase(),
              style: ZType.lbl(9, color: tc.textMuted, letterSpacing: 1.2),
            ),
          ],
        ],
      ),
    );
  }
}

class _MuscleListItem extends StatelessWidget {
  final MuscleIntensity muscle;
  final double maxIntensity;
  final VoidCallback onTap;

  const _MuscleListItem({
    required this.muscle,
    required this.maxIntensity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final progress =
        maxIntensity > 0 ? (muscle.intensity / maxIntensity).clamp(0.0, 1.0) : 0.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.hairline)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // pg-hb row: Barlow label · 4px hairline track + accent fill · Anton numeral.
              Row(
                children: [
                  Expanded(
                    child: Text(
                      muscle.formattedMuscleName.toUpperCase(),
                      style: ZType.lbl(12,
                          color: tc.textPrimary, letterSpacing: 1.4),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 4,
                        backgroundColor: AppColors.hairlineStrong,
                        valueColor: AlwaysStoppedAnimation(tc.accent),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    muscle.formattedVolume,
                    style: ZType.disp(15, color: tc.textPrimary),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.chevron_right, size: 18, color: tc.textMuted),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${muscle.workoutCount ?? 0} workouts · ${muscle.formattedLastTrained}',
                style: ZType.lbl(9, color: tc.textMuted, letterSpacing: 1.0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _RecSemantic { under, over }

class _RecommendationCard extends StatelessWidget {
  final String title;
  final List<String> muscles;
  final IconData icon;
  final _RecSemantic semantic;

  const _RecommendationCard({
    required this.title,
    required this.muscles,
    required this.icon,
    required this.semantic,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    // Semantic tint (under/over) is NOT the screen accent — warning/error.
    final semColor = semantic == _RecSemantic.under ? tc.warning : tc.error;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ZealovaCard(
        variant: ZealovaCardVariant.outlined,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: semColor),
                const SizedBox(width: 8),
                Text(
                  title.toUpperCase(),
                  style: ZType.lbl(12, color: tc.textPrimary, letterSpacing: 1.4),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: muscles
                  .map((m) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          border: Border.all(color: tc.cardBorder),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          m.toUpperCase(),
                          style: ZType.lbl(10,
                              color: tc.textSecondary, letterSpacing: 1.2),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Single balance-recommendation line — hairline-led, outlined `lightbulb`
/// icon + Fraunces body, no boxed Material `ListTile`.
class _RecommendationRow extends StatelessWidget {
  final String text;

  const _RecommendationRow({required this.text});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.hairline)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, size: 18, color: tc.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: ZType.ser(14, color: tc.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceScoreCard extends StatelessWidget {
  final double score;
  final String status;

  const _BalanceScoreCard({
    required this.score,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final isGood = score >= 75;
    // Good/needs-work is semantic (success/warning), not the screen accent.
    final semColor = isGood ? tc.success : tc.warning;

    return ZealovaCard(
      variant: ZealovaCardVariant.outlined,
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Hero balance score — Anton numeral over a Barlow kicker, with a
          // hairline-thin readiness ring routed through the semantic color.
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${score.toInt()}',
                style: ZType.disp(54, color: tc.textPrimary, height: 0.9),
              ),
              const SizedBox(height: 2),
              Text(
                AppLocalizations.of(context)!.muscleAnalyticsBalanceScore
                    .toUpperCase(),
                style: ZType.lbl(10, color: tc.textMuted, letterSpacing: 1.6),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Container(width: 1, height: 56, color: AppColors.hairline),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      isGood
                          ? Icons.check_circle_outline
                          : Icons.warning_amber_outlined,
                      size: 18,
                      color: semColor,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        status.toUpperCase(),
                        style: ZType.lbl(13,
                            color: semColor, letterSpacing: 1.4),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: (score / 100).clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: AppColors.hairlineStrong,
                    valueColor: AlwaysStoppedAnimation(semColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RatioCard extends StatelessWidget {
  final String title;
  final String ratio;
  final String side1Label;
  final String side1Value;
  final String side2Label;
  final String side2Value;
  final bool isBalanced;

  const _RatioCard({
    required this.title,
    required this.ratio,
    required this.side1Label,
    required this.side1Value,
    required this.side2Label,
    required this.side2Value,
    required this.isBalanced,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    // Balanced/imbalanced is semantic (success/warning), not the screen accent.
    final semColor = isBalanced ? tc.success : tc.warning;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ZealovaCard(
        variant: ZealovaCardVariant.outlined,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title.toUpperCase(),
                  style: ZType.lbl(12, color: tc.textPrimary, letterSpacing: 1.4),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: semColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    (isBalanced
                            ? AppLocalizations.of(context)!.muscleAnalyticsBalanced
                            : AppLocalizations.of(context)!
                                .muscleAnalyticsImbalanced)
                        .toUpperCase(),
                    style: ZType.lbl(9, color: semColor, letterSpacing: 1.2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _RatioSide(
                    label: side1Label,
                    value: side1Value,
                    align: CrossAxisAlignment.start,
                  ),
                ),
                Text(
                  ratio,
                  style: ZType.disp(26, color: tc.accent),
                ),
                Expanded(
                  child: _RatioSide(
                    label: side2Label,
                    value: side2Value,
                    align: CrossAxisAlignment.end,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RatioSide extends StatelessWidget {
  final String label;
  final String value;
  final CrossAxisAlignment align;

  const _RatioSide({
    required this.label,
    required this.value,
    required this.align,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Column(
      crossAxisAlignment: align,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: ZType.lbl(9, color: tc.textMuted, letterSpacing: 1.2),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: ZType.disp(18, color: tc.textPrimary),
        ),
      ],
    );
  }
}

/// Layout-matched skeleton for the three muscle-analytics tabs. Mirrors the
/// shared shape — a row of two summary cards, a section header, a chart block,
/// and a short list of breakdown rows — so the skeleton -> content cross-fade
/// is reflow-free.
class _AnalyticsTabSkeleton extends StatelessWidget {
  const _AnalyticsTabSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: const [
        // Two summary-stat cards side by side.
        Row(
          children: [
            Expanded(child: SkeletonBox(height: 96, radius: 12)),
            SizedBox(width: 12),
            Expanded(child: SkeletonBox(height: 96, radius: 12)),
          ],
        ),
        SizedBox(height: 24),
        // Section header.
        SkeletonBox(width: 160, height: 18),
        SizedBox(height: 16),
        // Chart / visualization block.
        SkeletonBox(height: 200, radius: 16),
        SizedBox(height: 24),
        // Breakdown list rows.
        SkeletonList(itemCount: 4),
      ],
    );
  }
}

class _EmptyWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyWidget({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: tc.textMuted),
            const SizedBox(height: 12),
            ZealovaRule(margin: const EdgeInsets.symmetric(horizontal: 48)),
            const SizedBox(height: 16),
            Text(
              title.toUpperCase(),
              textAlign: TextAlign.center,
              style: ZType.lbl(15, color: tc.textPrimary, letterSpacing: 1.6),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: ZType.ser(15, color: tc.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorWidget({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 56, color: tc.error),
            const SizedBox(height: 12),
            ZealovaRule(margin: const EdgeInsets.symmetric(horizontal: 48)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: ZType.ser(15, color: tc.textPrimary),
            ),
            const SizedBox(height: 16),
            ZealovaButton(
              label: 'Retry',
              trailingIcon: Icons.refresh,
              expand: false,
              onTap: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
