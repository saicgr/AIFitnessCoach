import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/posthog_service.dart';
import '../../../data/models/progress_charts.dart';
import '../../../widgets/app_loading.dart';
import '../../../data/providers/progress_charts_provider.dart';
import '../../../data/providers/gym_progress_filter_provider.dart';
import '../../../data/services/api_client.dart';
import 'widgets/volume_chart.dart';
import 'widgets/strength_chart.dart';
import 'widgets/summary_cards.dart';
import 'widgets/time_range_selector.dart';
import 'widgets/muscle_group_filter.dart';
import '../widgets/gym_progress_filter.dart';
import '../../../widgets/design_system/zealova.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/line_icon.dart';

import '../../../l10n/generated/app_localizations.dart';
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
    ref.read(posthogServiceProvider).capture(eventName: 'progress_charts_viewed');
    _loadData();
  }

  @override
  void dispose() {
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
      // Seed the gym filter to "All gyms" (combined) on first load — strength
      // trends pool free weights fine; users opt into a specific gym. Only
      // applies while the selection is still unresolved (no persisted pick).
      ref
          .read(gymProgressFilterProvider('progress_charts_strength').notifier)
          .seedDefault(perGym: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final state = ref.watch(progressChartsProvider);

    return Scaffold(
      backgroundColor: tc.background,
      appBar: ZealovaAppBar(
        title: AppLocalizations.of(context).progressChartsTrends,
        actions: [
          GestureDetector(
            onTap: () => context.push('/trends/custom'),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: LineIcon(
                'custom_trend',
                size: 20,
                color: tc.textSecondary,
              ),
            ),
          ),
          if (!state.isLoading)
            GestureDetector(
              onTap: () => ref
                  .read(progressChartsProvider.notifier)
                  .refresh(userId: _userId),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.refresh, size: 20, color: tc.textSecondary),
              ),
            ),
        ],
      ),
      body: _userId == null || state.isLoading
          ? AppLoading.fullScreen()
          : state.error != null
              ? _buildErrorState(state.error!)
              : Column(
                  children: [
                    // Tab Bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                      child: AnimatedBuilder(
                        animation: _tabController,
                        builder: (context, _) => ZealovaTextTabs(
                          tabs: [
                            AppLocalizations.of(context).volumeChartVolumeTrends,
                            AppLocalizations.of(context)
                                .strengthChartStrengthTrends,
                          ],
                          activeIndex: _tabController.index,
                          onChanged: (i) => _tabController.animateTo(i),
                        ),
                      ),
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
      return AppLoading.fullScreen();
    }

    if (!state.hasVolumeData) {
      return _buildEmptyState(
        icon: Icons.bar_chart_outlined,
        title: AppLocalizations.of(context).progressChartsNoVolumeDataYet,
        message: AppLocalizations.of(context).progressChartsCompleteSomeWorkoutsTo,
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
      return AppLoading.fullScreen();
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gym progress filter — sits beside the muscle/time filters. Hides
          // itself when ≤1 gym so single-gym users see no change. Selecting a
          // chip re-scopes BOTH trend charts to that gym (null = all gyms).
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GymProgressFilter(
              surfaceKey: 'progress_charts_strength',
              padding: EdgeInsets.zero,
              onChanged: (selection) {
                final uid = _userId;
                if (uid == null) return;
                ref.read(progressChartsProvider.notifier).setGymFilter(
                      selection.isAllGyms ? null : selection.gymProfileId,
                      userId: uid,
                    );
              },
            ),
          ),
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
              title: AppLocalizations.of(context).strengthOverviewCardNoStrengthDataYet,
              message:
                  AppLocalizations.of(context).progressChartsCompleteWeightedExercisesTo,
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
    final tc = ThemeColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: tc.error,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)
                  .strainDashboardFailedToLoadData
                  .toUpperCase(),
              textAlign: TextAlign.center,
              style: ZType.disp(22, color: tc.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: tc.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () =>
                  ref.read(progressChartsProvider.notifier).refresh(userId: _userId),
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context).buttonRetry),
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
    final tc = ThemeColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: tc.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              title.toUpperCase(),
              textAlign: TextAlign.center,
              style: ZType.disp(22, color: tc.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: tc.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVolumeTrendCard(VolumeProgressionData data) {
    final tc = ThemeColors.of(context);
    final isPositive = data.percentChange >= 0;
    final trendColor = isPositive ? tc.success : tc.error;

    return ZealovaCard(
      variant: ZealovaCardVariant.outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(Icons.trending_up,
              AppLocalizations.of(context).progressChartsVolumeTrend),
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
                tc.accent,
              ),
              _buildTrendStat(
                'Peak',
                '${data.peakVolumeKg.toStringAsFixed(0)} kg',
                tc.textPrimary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Signature card header — accent icon + Barlow uppercase title.
  Widget _cardHeader(IconData icon, String title) {
    final tc = ThemeColors.of(context);
    return Row(
      children: [
        Icon(icon, color: tc.accent, size: 18),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: ZType.lbl(13, color: tc.textPrimary, letterSpacing: 1.5),
        ),
      ],
    );
  }

  Widget _buildTrendStat(String label, String value, Color color) {
    final tc = ThemeColors.of(context);
    return Column(
      children: [
        Text(
          value,
          style: ZType.disp(18, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: ZType.lbl(9, color: tc.textMuted, letterSpacing: 1.2),
        ),
      ],
    );
  }

  Widget _buildVolumeBreakdownCard(VolumeProgressionData data) {
    return ZealovaCard(
      variant: ZealovaCardVariant.outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(Icons.analytics,
              AppLocalizations.of(context).progressChartsPeriodSummary),
          const SizedBox(height: 12),
          _buildBreakdownRow('Total Volume', '${data.totalVolumeKg.toStringAsFixed(0)} kg'),
          _buildBreakdownRow('Total Workouts', '${data.totalWorkouts}'),
          _buildBreakdownRow('Total Sets', '${data.sortedData.fold(0, (sum, w) => sum + w.totalSets)}'),
          _buildBreakdownRow('Total Reps', '${data.sortedData.fold(0, (sum, w) => sum + w.totalReps)}'),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, String value) {
    final tc = ThemeColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label.toUpperCase(),
            style: ZType.lbl(11, color: tc.textMuted, letterSpacing: 1),
          ),
          Text(
            value,
            style: ZType.data(13, color: tc.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildStrengthSummaryCard(StrengthProgressionData data) {
    final tc = ThemeColors.of(context);

    return ZealovaCard(
      variant: ZealovaCardVariant.outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(Icons.fitness_center,
              AppLocalizations.of(context).progressChartsStrengthSummary),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTrendStat(
                'Total Volume',
                '${(data.totalVolumeKg / 1000).toStringAsFixed(1)}t',
                tc.accent,
              ),
              _buildTrendStat(
                'Total Sets',
                '${data.totalSets}',
                tc.textPrimary,
              ),
              _buildTrendStat(
                'Avg Weekly',
                '${data.avgWeeklyVolumeKg.toStringAsFixed(0)} kg',
                tc.textPrimary,
              ),
            ],
          ),
          if (data.topMuscleGroup != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: tc.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.hairlineStrong),
              ),
              child: Row(
                children: [
                  Icon(Icons.star, color: tc.accent, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)
                        .progressChartsTopMuscle
                        .toUpperCase(),
                    style:
                        ZType.lbl(10, color: tc.textMuted, letterSpacing: 1.2),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatMuscleGroup(data.topMuscleGroup!).toUpperCase(),
                    style: ZType.lbl(11, color: tc.accent, letterSpacing: 1.2),
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

    final tc = ThemeColors.of(context);

    return ZealovaCard(
      variant: ZealovaCardVariant.outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(Icons.pie_chart,
              AppLocalizations.of(context).progressChartsMuscleGroupBreakdown),
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
                        _formatMuscleGroup(entry.key).toUpperCase(),
                        style: ZType.lbl(11,
                            color: tc.textSecondary, letterSpacing: 1),
                      ),
                      Text(
                        AppLocalizations.of(context)!.progressChartsScreenKg(entry.value.toStringAsFixed(0)),
                        style: ZType.data(12, color: tc.accent),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppColors.hairlineStrong,
                      valueColor: AlwaysStoppedAnimation<Color>(tc.accent),
                      minHeight: 6,
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
