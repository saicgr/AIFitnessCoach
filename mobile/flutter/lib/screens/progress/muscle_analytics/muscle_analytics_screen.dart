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
import 'widgets/muscle_heatmap_widget.dart';
import 'widgets/muscle_balance_chart.dart';
import 'widgets/muscle_frequency_chart.dart';
import 'package:fitwiz/core/constants/branding.dart';

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
    final theme = Theme.of(context);
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
    final theme = Theme.of(context);
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

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(muscleHeatmapProvider),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary cards
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: l10n.muscleAnalyticsMostTrained,
                        value: _formatMuscleName(sorted.first.muscleId),
                        icon: Icons.local_fire_department,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: l10n.muscleAnalyticsLeastTrained,
                        value: _formatMuscleName(sorted.last.muscleId),
                        icon: Icons.warning_outlined,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Muscle heatmap visualization
                Text(
                  l10n.muscleAnalyticsTrainingIntensity,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                MuscleHeatmapWidget(
                  heatmap: heatmap,
                  onMuscleTap: (muscleId) {
                    context.push('/stats/muscle-analytics/${Uri.encodeComponent(muscleId)}');
                  },
                ),

                const SizedBox(height: 24),

                // Top muscles list
                Text(
                  l10n.muscleAnalyticsMuscleBreakdown,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
    final theme = Theme.of(context);
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

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(muscleFrequencyProvider),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary cards
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: l10n.muscleAnalyticsUndertrained,
                        value: '${undertrained.length}',
                        subtitle: 'muscles',
                        icon: Icons.arrow_downward,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: l10n.muscleAnalyticsOvertrained,
                        value: '${overtrained.length}',
                        subtitle: 'muscles',
                        icon: Icons.arrow_upward,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Frequency chart
                Text(
                  l10n.muscleAnalyticsWeeklyTrainingFrequency,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                MuscleFrequencyChart(frequency: frequency),

                const SizedBox(height: 24),

                // Recommendations
                if (undertrained.isNotEmpty || overtrained.isNotEmpty) ...[
                  Text(
                    l10n.muscleAnalyticsRecommendations,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (undertrained.isNotEmpty)
                    _RecommendationCard(
                      title: l10n.muscleAnalyticsTrainMore,
                      muscles: undertrained.map((f) => f.formattedMuscleGroup).toList(),
                      icon: Icons.add_circle_outline,
                      color: Colors.orange,
                    ),
                  if (overtrained.isNotEmpty)
                    _RecommendationCard(
                      title: l10n.muscleAnalyticsAllowRecovery,
                      muscles: overtrained.map((f) => f.formattedMuscleGroup).toList(),
                      icon: Icons.remove_circle_outline,
                      color: Colors.red,
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
    final theme = Theme.of(context);
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

        return RefreshIndicator(
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
                Text(
                  l10n.muscleAnalyticsBalanceRatios,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                  Text(
                    l10n.muscleAnalyticsRecommendations,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...balance.recommendations!.map((rec) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.lightbulb_outline, color: Colors.amber),
                      title: Text(rec),
                    ),
                  )),
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

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
  });

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
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
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
    final theme = Theme.of(context);
    final progress = maxIntensity > 0 ? muscle.intensity / maxIntensity : 0.0;

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
                  Text(
                    muscle.formattedMuscleName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    muscle.formattedVolume,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '${muscle.workoutCount ?? 0} workouts',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    muscle.formattedLastTrained,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final String title;
  final List<String> muscles;
  final IconData icon;
  final Color color;

  const _RecommendationCard({
    required this.title,
    required this.muscles,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: muscles.map((m) => Chip(label: Text(m))).toList(),
            ),
          ],
        ),
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
    final theme = Theme.of(context);
    final isGood = score >= 75;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isGood ? Colors.green : Colors.orange).withOpacity(0.1),
                border: Border.all(
                  color: isGood ? Colors.green : Colors.orange,
                  width: 4,
                ),
              ),
              child: Center(
                child: Text(
                  '${score.toInt()}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isGood ? Colors.green : Colors.orange,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.muscleAnalyticsBalanceScore,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: isGood ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isBalanced ? Colors.green : Colors.orange).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isBalanced ? AppLocalizations.of(context)!.muscleAnalyticsBalanced : AppLocalizations.of(context)!.muscleAnalyticsImbalanced,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isBalanced ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(side1Label, style: theme.textTheme.bodySmall),
                      Text(
                        side1Value,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  ratio,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(side2Label, style: theme.textTheme.bodySmall),
                      Text(
                        side2Value,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
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
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(message, style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
