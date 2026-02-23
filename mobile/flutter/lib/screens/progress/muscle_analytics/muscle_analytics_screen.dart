import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/muscle_analytics.dart';
import '../../../widgets/app_loading.dart';
import '../../../data/providers/muscle_analytics_provider.dart';
import '../../../data/repositories/muscle_analytics_repository.dart';
import '../../../widgets/segmented_tab_bar.dart';
import 'widgets/muscle_heatmap_widget.dart';
import 'widgets/muscle_balance_chart.dart';
import 'widgets/muscle_frequency_chart.dart';

/// Main muscle analytics dashboard with tabs for heatmap, frequency, and balance
class MuscleAnalyticsScreen extends ConsumerStatefulWidget {
  const MuscleAnalyticsScreen({super.key});

  @override
  ConsumerState<MuscleAnalyticsScreen> createState() => _MuscleAnalyticsScreenState();
}

class _MuscleAnalyticsScreenState extends ConsumerState<MuscleAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime? _screenOpenTime;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _screenOpenTime = DateTime.now();
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
    if (_screenOpenTime != null) {
      final duration = DateTime.now().difference(_screenOpenTime!).inSeconds;
      ref.read(muscleAnalyticsRepositoryProvider).logView(
        viewType: 'dashboard',
        sessionDurationSeconds: duration,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeRange = ref.watch(muscleAnalyticsTimeRangeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Muscle Analytics'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Time Range',
            onSelected: (value) {
              ref.read(muscleAnalyticsTimeRangeProvider.notifier).state = value;
            },
            itemBuilder: (context) => [
              _buildTimeRangeItem('1_week', '1 Week', timeRange),
              _buildTimeRangeItem('2_weeks', '2 Weeks', timeRange),
              _buildTimeRangeItem('4_weeks', '4 Weeks', timeRange),
              _buildTimeRangeItem('8_weeks', '8 Weeks', timeRange),
              _buildTimeRangeItem('12_weeks', '12 Weeks', timeRange),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          SegmentedTabBar(
            controller: _tabController,
            showIcons: false,
            tabs: const [
              SegmentedTabItem(label: 'Heatmap'),
              SegmentedTabItem(label: 'Frequency'),
              SegmentedTabItem(label: 'Balance'),
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
    final theme = Theme.of(context);
    final heatmapAsync = ref.watch(muscleHeatmapProvider);

    return heatmapAsync.when(
      loading: () => AppLoading.fullScreen(),
      error: (error, _) => _ErrorWidget(
        message: 'Failed to load muscle data',
        onRetry: () => ref.invalidate(muscleHeatmapProvider),
      ),
      data: (heatmap) {
        if (!heatmap.hasData) {
          return const _EmptyWidget(
            icon: Icons.fitness_center_outlined,
            title: 'No Training Data',
            message: 'Complete some workouts to see your muscle training heatmap.',
          );
        }

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
                        title: 'Most Trained',
                        value: _formatMuscleName(heatmap.sortedByIntensity.first.muscleId),
                        icon: Icons.local_fire_department,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Least Trained',
                        value: _formatMuscleName(heatmap.sortedByIntensity.last.muscleId),
                        icon: Icons.warning_outlined,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Muscle heatmap visualization
                Text(
                  'Training Intensity',
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
                  'Muscle Breakdown',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...heatmap.sortedByIntensity.map((muscle) => _MuscleListItem(
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
    final theme = Theme.of(context);
    final frequencyAsync = ref.watch(muscleFrequencyProvider);

    return frequencyAsync.when(
      loading: () => AppLoading.fullScreen(),
      error: (error, _) => _ErrorWidget(
        message: 'Failed to load frequency data',
        onRetry: () => ref.invalidate(muscleFrequencyProvider),
      ),
      data: (frequency) {
        if (!frequency.hasData) {
          return const _EmptyWidget(
            icon: Icons.calendar_today,
            title: 'No Frequency Data',
            message: 'Complete workouts over multiple weeks to see training frequency.',
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
                        title: 'Undertrained',
                        value: '${undertrained.length}',
                        subtitle: 'muscles',
                        icon: Icons.arrow_downward,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Overtrained',
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
                  'Weekly Training Frequency',
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
                    'Recommendations',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (undertrained.isNotEmpty)
                    _RecommendationCard(
                      title: 'Train More',
                      muscles: undertrained.map((f) => f.formattedMuscleGroup).toList(),
                      icon: Icons.add_circle_outline,
                      color: Colors.orange,
                    ),
                  if (overtrained.isNotEmpty)
                    _RecommendationCard(
                      title: 'Allow Recovery',
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
    final theme = Theme.of(context);
    final balanceAsync = ref.watch(muscleBalanceProvider);

    return balanceAsync.when(
      loading: () => AppLoading.fullScreen(),
      error: (error, _) => _ErrorWidget(
        message: 'Failed to load balance data',
        onRetry: () => ref.invalidate(muscleBalanceProvider),
      ),
      data: (balance) {
        if (!balance.hasData) {
          return const _EmptyWidget(
            icon: Icons.balance,
            title: 'No Balance Data',
            message: 'Complete more workouts to see your muscle balance analysis.',
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
                      ? 'Balanced'
                      : 'Needs Work',
                ),
                const SizedBox(height: 24),

                // Balance ratios
                Text(
                  'Balance Ratios',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                MuscleBalanceChart(balance: balance),

                const SizedBox(height: 24),

                // Detailed ratios
                _RatioCard(
                  title: 'Push / Pull',
                  ratio: balance.formattedPushPullRatio,
                  side1Label: 'Push',
                  side1Value: balance.formattedPushVolume,
                  side2Label: 'Pull',
                  side2Value: balance.formattedPullVolume,
                  isBalanced: balance.isPushPullBalanced,
                ),
                const SizedBox(height: 12),
                _RatioCard(
                  title: 'Upper / Lower',
                  ratio: balance.formattedUpperLowerRatio,
                  side1Label: 'Upper',
                  side1Value: balance.upperVolumeKg != null ? '${balance.upperVolumeKg!.toInt()} kg' : '-',
                  side2Label: 'Lower',
                  side2Value: balance.lowerVolumeKg != null ? '${balance.lowerVolumeKg!.toInt()} kg' : '-',
                  isBalanced: balance.isUpperLowerBalanced,
                ),

                // Recommendations
                if (balance.recommendations != null && balance.recommendations!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Recommendations',
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
                    'Balance Score',
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
                    isBalanced ? 'Balanced' : 'Imbalanced',
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
