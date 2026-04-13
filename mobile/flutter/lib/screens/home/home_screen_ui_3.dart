part of 'home_screen.dart';

/// UI builder methods extracted from _HomeScreenState
extension _HomeScreenStateUI3 on _HomeScreenState {

  /// Build default tiles when no layout is available
  List<Widget> _buildDefaultTiles(
    BuildContext context,
    bool isDark,
    AsyncValue workoutsState,
    WorkoutsNotifier workoutsNotifier,
    dynamic nextWorkout,
    bool isAIGenerating,
    (int, int) weeklyProgress,
    List upcomingWorkouts,
  ) {
    return [
      // Fitness Score Card
      const SliverToBoxAdapter(child: FitnessScoreCard()),

      // Mood Picker Card
      const SliverToBoxAdapter(child: MoodPickerCard()),

      // Daily Activity Card
      const SliverToBoxAdapter(child: DailyActivityCard()),

      // Next Workout Card
      SliverToBoxAdapter(
        child: _buildNextWorkoutSection(
          context,
          workoutsState,
          workoutsNotifier,
          nextWorkout,
          isAIGenerating,
        ),
      ),

      // Reports & Insights entry — mirrors the placement in the dynamic tile
      // renderer so the card is consistently visible in both default and
      // customized home layouts.
      SliverToBoxAdapter(child: WeeklyReportCard(isDark: isDark)),

      // Quick Actions Row
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: const QuickActionsRow(),
        ),
      ),

      // Free-tier usage counters (hidden for premium)
      const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: UsageCounterStrip(),
        ),
      ),

      // Section: YOUR WEEK
      const SliverToBoxAdapter(
        child: SectionHeader(title: 'YOUR WEEK'),
      ),

      // Week Changes Card
      const SliverToBoxAdapter(child: WeekChangesCard()),

      // Weekly Progress
      SliverToBoxAdapter(
        child: WeeklyProgressCard(
          completed: weeklyProgress.$1,
          total: weeklyProgress.$2,
          isDark: isDark,
        ).animateSlideRotate(delay: const Duration(milliseconds: 50)),
      ),

      // Weekly Goals Card
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: WeeklyGoalsCard(isDark: isDark)
              .animateSlideRotate(delay: const Duration(milliseconds: 100)),
        ),
      ),

      // Section: UPCOMING
      if (upcomingWorkouts.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: SectionHeader(
            title: 'UPCOMING',
            subtitle: '${upcomingWorkouts.length} workouts',
            actionText: 'View Schedule',
            onAction: () {
              HapticService.light();
              context.push('/schedule');
            },
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index >= upcomingWorkouts.length) return null;
              final workout = upcomingWorkouts[index];
              return AnimationConfiguration.staggeredList(
                position: index,
                duration: AppAnimations.listItem,
                child: SlideAnimation(
                  verticalOffset: 20,
                  curve: AppAnimations.fastOut,
                  child: FadeInAnimation(
                    curve: AppAnimations.fastOut,
                    child: UpcomingWorkoutCard(
                      workout: workout,
                      onTap: () => context.push('/workout/${workout.id}', extra: workout),
                    ),
                  ),
                ),
              );
            },
            childCount: upcomingWorkouts.length.clamp(0, 3),
          ),
        ),
      ],
    ];
  }


  Widget _buildNextWorkoutSection(
    BuildContext context,
    AsyncValue workoutsState,
    WorkoutsNotifier workoutsNotifier,
    dynamic nextWorkout,
    bool isAIGenerating,
  ) {
    // Show loading card during initial app load
    if (_isInitializing) {
      return const GeneratingWorkoutsCard(
        message: 'Loading your workouts...',
        subtitle: 'Preparing your personalized fitness plan',
      );
    }

    return workoutsState.when(
      loading: () => const GeneratingWorkoutsCard(
        message: 'Loading workouts...',
        subtitle: 'Please wait a moment',
      ),
      error: (e, _) => ErrorCard(
        message: 'Failed to load workouts',
        onRetry: () => workoutsNotifier.refresh(),
      ),
      data: (_) => (isAIGenerating && nextWorkout == null)
          ? const GeneratingWorkoutsCard(
              message: 'AI is generating your workout...',
            )
          : nextWorkout != null
              ? NextWorkoutCard(
                  workout: nextWorkout,
                  onStart: () => context.push('/workout/${nextWorkout.id}', extra: nextWorkout),
                )
              : (_isCheckingWorkouts || _isStreamingGeneration)
                  ? const GeneratingWorkoutsCard(
                      message: 'Generating your personalized workouts...',
                    )
                  : EmptyWorkoutCard(
                      onGenerate: () {
                        // Navigate to Workouts tab where user can generate more
                        context.go('/workouts');
                      },
                    ),
    );
  }


  Widget _buildTodaySectionHeader(bool isDark) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        children: [
          Text(
            'TODAY',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textMuted,
              letterSpacing: 1.5,
            ),
          ),
          const Spacer(),
          CustomizeProgramButton(isDark: isDark),
        ],
      ),
    );
  }

}
