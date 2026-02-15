import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/progress_charts.dart';
import '../../../data/providers/progress_charts_provider.dart';
import '../../../data/services/api_client.dart';
import 'widgets/volume_chart.dart';
import 'widgets/strength_chart.dart';
import 'widgets/summary_cards.dart';
import 'widgets/time_range_selector.dart';
import 'widgets/muscle_group_filter.dart';
import '../../../widgets/glass_back_button.dart';
import '../../../widgets/segmented_tab_bar.dart';

/// Visual Progress Charts Screen
/// Displays line and bar charts showing strength and volume progression over time
class ProgressChartsScreen extends ConsumerStatefulWidget {
  const ProgressChartsScreen({super.key});

  @override
  ConsumerState<ProgressChartsScreen> createState() =>
      _ProgressChartsScreenState();
}

class _ProgressChartsScreenState extends ConsumerState<ProgressChartsScreen>
    with SingleTickerProviderStateMixin {
  String? _userId;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    // Log exit analytics
    ref.read(progressChartsProvider.notifier).onScreenExit();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final userId = await ref.read(apiClientProvider).getUserId();
    if (userId != null && mounted) {
      setState(() {
        _userId = userId;
      });
      ref.read(progressChartsProvider.notifier).setUserId(userId);
      ref.read(progressChartsProvider.notifier).loadAllData(userId: userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(progressChartsProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Progress Charts'),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leading: const GlassBackButton(),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: state.isLoading
                ? null
                : () =>
                    ref.read(progressChartsProvider.notifier).refresh(userId: _userId),
          ),
        ],
      ),
      body: _userId == null || state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? _buildErrorState(state.error!)
              : Column(
                  children: [
                    // Tab Bar
                    SegmentedTabBar(
                      controller: _tabController,
                      showIcons: false,
                      tabs: const [
                        SegmentedTabItem(label: 'Volume'),
                        SegmentedTabItem(label: 'Strength'),
                      ],
                    ),

                    // Time Range Selector
                    TimeRangeSelector(
                      selectedRange: state.selectedTimeRange,
                      onRangeSelected: (range) {
                        ref
                            .read(progressChartsProvider.notifier)
                            .setTimeRange(range);
                      },
                    ),

                    // Summary Cards
                    if (state.summary != null)
                      SummaryCards(summary: state.summary!)
                          .animate()
                          .fadeIn(duration: 300.ms)
                          .slideY(begin: -0.1, end: 0),

                    // Tab Content
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Volume Tab
                          _buildVolumeTab(state),
                          // Strength Tab
                          _buildStrengthTab(state),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildVolumeTab(ProgressChartsState state) {
    if (state.isLoadingVolume) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!state.hasVolumeData) {
      return _buildEmptyState(
        icon: Icons.bar_chart_outlined,
        title: 'No Volume Data Yet',
        message: 'Complete some workouts to see your volume progression over time.',
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VolumeChart(data: state.volumeData!)
              .animate()
              .fadeIn(delay: 100.ms, duration: 400.ms),
          const SizedBox(height: 24),
          _buildVolumeTrendCard(state.volumeData!),
          const SizedBox(height: 24),
          _buildVolumeBreakdownCard(state.volumeData!),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildStrengthTab(ProgressChartsState state) {
    if (state.isLoadingStrength) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Muscle Group Filter
          MuscleGroupFilter(
            muscleGroups: state.availableMuscleGroupsList,
            selectedMuscleGroup: state.selectedMuscleGroup,
            onMuscleGroupSelected: (muscleGroup) {
              ref
                  .read(progressChartsProvider.notifier)
                  .setMuscleGroupFilter(muscleGroup);
            },
          ),
          const SizedBox(height: 16),

          if (!state.hasStrengthData)
            _buildEmptyState(
              icon: Icons.show_chart_outlined,
              title: 'No Strength Data Yet',
              message:
                  'Complete weighted exercises to see your strength progression.',
            )
          else ...[
            StrengthChart(data: state.strengthData!)
                .animate()
                .fadeIn(delay: 100.ms, duration: 400.ms),
            const SizedBox(height: 24),
            _buildStrengthSummaryCard(state.strengthData!),
            const SizedBox(height: 24),
            _buildMuscleGroupBreakdown(state.strengthData!),
            const SizedBox(height: 80),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to Load Data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () =>
                  ref.read(progressChartsProvider.notifier).refresh(userId: _userId),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVolumeTrendCard(VolumeProgressionData data) {
    final colorScheme = Theme.of(context).colorScheme;
    final isPositive = data.percentChange >= 0;
    final trendColor = isPositive ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Volume Trend',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTrendStat(
                'Change',
                '${isPositive ? '+' : ''}${data.percentChange.toStringAsFixed(1)}%',
                trendColor,
              ),
              _buildTrendStat(
                'Avg Weekly',
                '${data.avgWeeklyVolumeKg.toStringAsFixed(0)} kg',
                colorScheme.primary,
              ),
              _buildTrendStat(
                'Peak',
                '${data.peakVolumeKg.toStringAsFixed(0)} kg',
                Colors.amber,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendStat(String label, String value, Color color) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildVolumeBreakdownCard(VolumeProgressionData data) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Period Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildBreakdownRow('Total Volume', '${data.totalVolumeKg.toStringAsFixed(0)} kg'),
          _buildBreakdownRow('Total Workouts', '${data.totalWorkouts}'),
          _buildBreakdownRow('Total Sets', '${data.sortedData.fold(0, (sum, w) => sum + w.totalSets)}'),
          _buildBreakdownRow('Total Reps', '${data.sortedData.fold(0, (sum, w) => sum + w.totalReps)}'),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrengthSummaryCard(StrengthProgressionData data) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fitness_center, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Strength Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTrendStat(
                'Total Volume',
                '${(data.totalVolumeKg / 1000).toStringAsFixed(1)}t',
                colorScheme.primary,
              ),
              _buildTrendStat(
                'Total Sets',
                '${data.totalSets}',
                Colors.blue,
              ),
              _buildTrendStat(
                'Avg Weekly',
                '${data.avgWeeklyVolumeKg.toStringAsFixed(0)} kg',
                Colors.purple,
              ),
            ],
          ),
          if (data.topMuscleGroup != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.star, color: colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Top Muscle: ',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                  Text(
                    _formatMuscleGroup(data.topMuscleGroup!),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMuscleGroupBreakdown(StrengthProgressionData data) {
    final colorScheme = Theme.of(context).colorScheme;

    // Group data by muscle group
    final muscleVolumes = <String, double>{};
    for (final entry in data.data) {
      muscleVolumes[entry.muscleGroup] =
          (muscleVolumes[entry.muscleGroup] ?? 0) + entry.totalVolumeKg;
    }

    // Sort by volume
    final sortedMuscles = muscleVolumes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedMuscles.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Muscle Group Breakdown',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...sortedMuscles.take(5).map((entry) {
            final maxVolume = sortedMuscles.first.value;
            final progress = entry.value / maxVolume;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatMuscleGroup(entry.key),
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '${entry.value.toStringAsFixed(0)} kg',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: colorScheme.outline.withOpacity(0.2),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(colorScheme.primary),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _formatMuscleGroup(String name) {
    return name
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) =>
            word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}
