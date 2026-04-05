part of 'milestones_screen.dart';

/// UI builder methods extracted from _MilestonesScreenState
extension _MilestonesScreenStateUI on _MilestonesScreenState {

  Widget _buildMilestonesTab(bool isDark, MilestonesState state) {
    final categories = MilestoneCategory.values;

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(milestonesProvider.notifier).refresh();
      },
      child: CustomScrollView(
        slivers: [
          // Summary card
          SliverToBoxAdapter(
            child: _buildSummaryCard(isDark, state),
          ),

          // Category filter
          SliverToBoxAdapter(
            child: _buildCategoryFilter(isDark, categories),
          ),

          // Next milestone progress
          if (state.nextMilestone != null)
            SliverToBoxAdapter(
              child: _buildNextMilestoneCard(isDark, state.nextMilestone!),
            ),

          // Section: Achieved
          if (state.achieved.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Achieved (${state.totalAchieved})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                  ),
                ),
              ),
            ),

          // Achieved milestones grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.85,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final filtered = _filterByCategory(state.achieved);
                  if (index >= filtered.length) return null;
                  return _buildMilestoneBadge(isDark, filtered[index], true);
                },
                childCount: _filterByCategory(state.achieved).length,
              ),
            ),
          ),

          // Section: Upcoming
          if (state.upcoming.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(
                  'Upcoming',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                  ),
                ),
              ),
            ),

          // Upcoming milestones grid
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.85,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final filtered = _filterByCategory(state.upcoming);
                  if (index >= filtered.length) return null;
                  return _buildMilestoneBadge(isDark, filtered[index], false);
                },
                childCount: _filterByCategory(state.upcoming).length,
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildROITab(bool isDark, MilestonesState state) {
    final roi = state.roiMetrics;
    final summary = state.roiSummary;

    if (roi == null && summary == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 64,
              color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'No data yet',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete workouts to see your ROI',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final userId = ref.read(authStateProvider).user?.id;
        if (userId != null) {
          await ref.read(milestonesProvider.notifier).loadROIMetrics(
            userId: userId,
            recalculate: true,
          );
        }
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (roi != null) ...[
            _buildROIHeader(isDark, roi),
            const SizedBox(height: 16),
            _buildROIMetricCard(
              isDark,
              'Time Invested',
              '${roi.totalWorkoutTimeHours.toStringAsFixed(1)} hours',
              Icons.schedule,
              AppColors.orange,
              subtitle: 'Average: ${roi.averageWorkoutDurationMinutes} min/workout',
            ),
            const SizedBox(height: 12),
            _buildROIMetricCard(
              isDark,
              'Total Weight Lifted',
              roi.formattedWeightLifted,
              Icons.fitness_center,
              AppColors.purple,
              subtitle: '${roi.totalWeightLiftedKg.toStringAsFixed(0)} kg',
            ),
            const SizedBox(height: 12),
            _buildROIMetricCard(
              isDark,
              'Estimated Calories Burned',
              '${roi.estimatedCaloriesBurned}',
              Icons.local_fire_department,
              AppColors.coral,
              subtitle: 'Based on workout duration',
            ),
            const SizedBox(height: 12),
            _buildROIMetricCard(
              isDark,
              'Personal Records',
              '${roi.prsAchievedCount}',
              Icons.emoji_events,
              AppColors.yellow,
              subtitle: 'PRs achieved so far',
            ),
            if (roi.strengthIncreasePercentage > 0) ...[
              const SizedBox(height: 12),
              _buildROIMetricCard(
                isDark,
                'Strength Increase',
                '+${roi.strengthIncreasePercentage.toStringAsFixed(0)}%',
                Icons.trending_up,
                AppColors.green,
                subtitle: 'Since you started',
              ),
            ],
            const SizedBox(height: 24),
            // Journey stats
            _buildJourneyStats(isDark, roi),
          ],
        ],
      ),
    );
  }

}
