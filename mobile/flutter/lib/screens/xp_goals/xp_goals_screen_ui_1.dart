part of 'xp_goals_screen.dart';

/// UI builder methods extracted from _XPGoalsScreenState
extension _XPGoalsScreenStateUI1 on _XPGoalsScreenState {

  Widget _buildLevelProgressSection(
    BuildContext context,
    UserXP? userXp,
    Color textColor,
    Color textMuted,
    Color cardBg,
    Color borderColor,
    Color accentColor,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tc = ThemeColors.of(context);
    final surface = tc.surface;
    final hairBorder = tc.cardBorder;
    final textSecondary = tc.textSecondary;
    final currentLevel = userXp?.currentLevel ?? 1;
    // Ensure XP values are never negative (data corruption safeguard)
    final xpInCurrentLevel = (userXp?.xpInCurrentLevel ?? 0).clamp(0, 999999);
    final xpToNextLevel = (userXp?.xpToNextLevel ?? 50).clamp(1, 100000);
    final progressFraction = (userXp?.progressFraction ?? 0.0).clamp(0.0, 1.0);
    final xpTitle = userXp?.xpTitle ?? XPTitle.novice;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LEVEL header — gold radial-ring badge + Anton level number,
        // Barlow title, Space Mono XP total, plus the info affordance.
        Row(
          children: [
            // Level Badge — gold rarity ring, no solid gradient fill
            Container(
              width: 54,
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Color(0x38FBBF24), Colors.transparent],
                  stops: [0.0, 0.7],
                  center: Alignment(-0.3, -0.4),
                ),
                border: Border.all(
                  color: AppColors.gamGold.withValues(alpha: 0.55),
                  width: 1.5,
                ),
              ),
              child: Text(
                '$currentLevel',
                style: ZType.disp(currentLevel >= 100 ? 18 : 24,
                    color: AppColors.gamGold),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    xpTitle.displayName.toUpperCase(),
                    style: ZType.disp(19, color: textColor, height: 0.96),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${userXp?.formattedTotalXp ?? "0"} XP TOTAL',
                    style: ZType.data(11, color: textMuted),
                  ),
                ],
              ),
            ),
            // Info button
            GestureDetector(
              onTap: () => _showXPInfoDialog(context, isDark),
              child: Icon(
                Icons.info_outline_rounded,
                size: 20,
                color: textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // LEVEL PROGRESS — pure hairline bar, no ring (the number leads)
        Row(
          children: [
            Expanded(
              child: ZealovaSectionKicker(
                '${AppLocalizations.of(context).xpGoalsScreenLevelProgress} · ${xpTitle.displayName}',
              ),
            ),
            Text(
              '${(progressFraction * 100).round()}%',
              style: ZType.data(11, color: AppColors.gamGold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: progressFraction,
            minHeight: 6,
            backgroundColor: AppColors.hairlineStrong,
            valueColor: const AlwaysStoppedAnimation(AppColors.gamGold),
          ),
        ),
        const SizedBox(height: 7),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$xpInCurrentLevel / $xpToNextLevel XP',
              style: ZType.lbl(9.5, color: textMuted, letterSpacing: 1),
            ),
            Text(
              'LVL ${currentLevel + 1}',
              style: ZType.lbl(9.5, color: textMuted, letterSpacing: 1),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // View All Levels — hairline row affordance
        GestureDetector(
          onTap: () => _showAllLevelsSheet(context, currentLevel, accentColor),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: hairBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.stairs,
                  color: AppColors.gamGold,
                  size: 17,
                ),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context).xpGoalsScreenViewAllLevelsRewards.toUpperCase(),
                  style: ZType.lbl(11, color: textSecondary, letterSpacing: 1.5),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  color: textMuted,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildDailyGoalsCard(
    BuildContext context,
    WidgetRef ref,
    LoginStreakInfo? streak,
    Color textColor,
    Color textMuted,
    Color cardBg,
    Color borderColor,
    double multiplier,
    Color accentColor,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const dailyLoginXP = 5;

    // Get actual daily goals state
    final dailyGoalsState = ref.watch(dailyGoalsProvider);

    // Check multiple sources for login status
    final xpState = ref.watch(xpProvider);
    final hasLoggedInToday = streak?.hasLoggedInToday ??
                              dailyGoalsState?.loggedIn ??
                              xpState.lastDailyLoginResult != null;

    final dailyGoals = [
      _DailyGoal(
        title: AppLocalizations.of(context).xpGoalsScreenLogInToday,
        xp: dailyLoginXP,
        isComplete: hasLoggedInToday,
        icon: Icons.login,
      ),
      _DailyGoal(
        title: AppLocalizations.of(context).xpGoalsScreenComplete1Workout,
        xp: 100,
        isComplete: dailyGoalsState?.completedWorkout ?? false,
        icon: Icons.fitness_center,
      ),
      _DailyGoal(
        title: AppLocalizations.of(context).homeLogMeal,
        xp: 25,
        isComplete: dailyGoalsState?.loggedMeal ?? false,
        icon: Icons.restaurant,
      ),
      _DailyGoal(
        title: AppLocalizations.of(context).xpGoalsScreenLogWeight,
        xp: 15,
        isComplete: dailyGoalsState?.loggedWeight ?? false,
        icon: Icons.monitor_weight_outlined,
      ),
      _DailyGoal(
        title: AppLocalizations.of(context).xpGoalsScreenHitProteinGoal,
        xp: 50,
        isComplete: dailyGoalsState?.hitProteinGoal ?? false,
        icon: Icons.egg_alt,
      ),
      _DailyGoal(
        title: AppLocalizations.of(context).xpGoalsScreenLogBodyMeasurements,
        xp: 20,
        isComplete: dailyGoalsState?.loggedBodyMeasurements ?? false,
        icon: Icons.straighten,
      ),
      _DailyGoal(
        title: AppLocalizations.of(context).xpGoalsScreenHit10kSteps,
        xp: 100,
        isComplete: dailyGoalsState?.hitStepsGoal ?? false,
        icon: Icons.directions_walk,
      ),
      _DailyGoal(
        title: AppLocalizations.of(context).xpGoalsScreenHitHydrationGoal,
        xp: 40,
        isComplete: dailyGoalsState?.hitHydrationGoal ?? false,
        icon: Icons.water_drop_outlined,
      ),
      _DailyGoal(
        title: AppLocalizations.of(context).xpGoalsScreenHitCalorieGoal,
        xp: 60,
        isComplete: dailyGoalsState?.hitCalorieGoal ?? false,
        icon: Icons.local_fire_department_outlined,
      ),
    ];

    final completedCount = dailyGoals.where((g) => g.isComplete).length;
    final totalXPEarned = dailyGoals
        .where((g) => g.isComplete)
        .fold(0, (sum, g) => sum + g.xp);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary meta line — Anton hero counts + Barlow labels on a hairline
        Container(
          padding: const EdgeInsets.only(bottom: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.hairline)),
          ),
          child: Row(
            children: [
              _buildXpStatColumn(
                '$completedCount/${dailyGoals.length}',
                'Goals',
                textColor,
                textMuted,
              ),
              const SizedBox(width: 28),
              _buildXpStatColumn(
                '+$totalXPEarned',
                'XP Today',
                textColor,
                textMuted,
                heroColor: AppColors.gamGold,
              ),
            ],
          ),
        ),

        // Goals list
        ...dailyGoals.map((goal) => _buildGoalRow(
              goal,
              isDark ? textColor : Colors.black87,
              isDark ? textMuted : Colors.black54,
              multiplier,
              accentColor,
              isDark,
            )),
      ],
    );
  }

  /// Anton hero numeral + Barlow uppercase label, used in the daily/bonus
  /// summary meta lines.
  Widget _buildXpStatColumn(
    String value,
    String label,
    Color textColor,
    Color textMuted, {
    Color? heroColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: ZType.disp(24, color: heroColor ?? textColor, height: 0.9),
        ),
        const SizedBox(height: 3),
        Text(
          label.toUpperCase(),
          style: ZType.lbl(9, color: textMuted, letterSpacing: 1.5),
        ),
      ],
    );
  }


  Widget _buildExtendedWeeklyProgressCard(
    BuildContext context,
    WidgetRef ref,
    Color textColor,
    Color textMuted,
    Color cardBg,
    Color borderColor,
    Color accentColor,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surface : AppColorsLight.surface;
    final hairBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final extendedProgress = ref.watch(extendedWeeklyProgressProvider);

    return extendedProgress.when(
      // Layout-matched skeleton instead of a blocking spinner: the weekly
      // progress card is a single fixed-height surface, so a same-sized
      // SkeletonBox keeps the swap reflow-free.
      loading: () => const SkeletonBox(height: 100, radius: 16),
      error: (e, _) => Text(
        AppLocalizations.of(context).xpGoalsScreenErrorLoadingWeeklyProgress,
        style: TextStyle(color: textMuted),
      ),
      data: (progress) {
        final earnedXP = progress.totalXpEarned;
        final maxXP = progress.totalXpPossible;
        final percentage = maxXP > 0 ? (earnedXP / maxXP).clamp(0.0, 1.0) : 0.0;
        final checkpoints = progress.checkpoints;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // XP Progress header — hero earned XP + hairline gold bar
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$earnedXP',
                  style: ZType.disp(30, color: AppColors.gamGold, height: 0.9),
                ),
                const SizedBox(width: 5),
                Text(
                  '/ $maxXP XP',
                  style: ZType.data(12, color: textMuted),
                ),
              ],
            ),
            const SizedBox(height: 9),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: percentage,
                minHeight: 6,
                backgroundColor: AppColors.hairlineStrong,
                valueColor: const AlwaysStoppedAnimation(AppColors.gamGold),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${progress.completedCount}/${checkpoints.length} checkpoints complete'.toUpperCase(),
              style: ZType.lbl(9, color: textMuted, letterSpacing: 1.3),
            ),
            const SizedBox(height: 6),

            // Checkpoints list — hairline rows
            ...checkpoints.map((cp) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.hairline),
                  ),
                ),
                child: Row(
                  children: [
                    // Status glyph
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: cp.completed
                            ? AppColors.green
                            : surface,
                        shape: BoxShape.circle,
                        border: cp.completed
                            ? null
                            : Border.all(color: hairBorder),
                      ),
                      child: cp.completed
                          ? const Icon(Icons.check, size: 15, color: Colors.black)
                          : Text(
                              cp.icon.isNotEmpty ? cp.icon : '📋',
                              style: const TextStyle(fontSize: 12),
                            ),
                    ),
                    const SizedBox(width: 11),
                    // Name and progress
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cp.name,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: cp.completed ? textMuted : textColor,
                              decoration: cp.completed ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          if (!cp.completed) ...[
                            const SizedBox(height: 2),
                            Text(
                              '${cp.current}/${cp.target}',
                              style: ZType.data(9.5, color: textMuted),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // XP reward
                    Text(
                      '+${cp.xpReward}',
                      style: ZType.lbl(11,
                          color: cp.completed ? AppColors.green : AppColors.gamGold,
                          weight: FontWeight.w800,
                          letterSpacing: 0.5),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }


  Widget _buildMonthlyAchievementsCard(
    BuildContext context,
    WidgetRef ref,
    Color textColor,
    Color textMuted,
    Color cardBg,
    Color borderColor,
    Color accentColor,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surface : AppColorsLight.surface;
    final hairBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final monthlyProgress = ref.watch(monthlyAchievementsProgressProvider);

    return monthlyProgress.when(
      // Layout-matched skeleton instead of a blocking spinner — see the
      // weekly card above for rationale.
      loading: () => const SkeletonBox(height: 100, radius: 16),
      error: (e, _) => Text(
        AppLocalizations.of(context).xpGoalsScreenErrorLoadingMonthlyAchievem,
        style: TextStyle(color: textMuted),
      ),
      data: (progress) {
        final earnedXP = progress.totalXpEarned;
        final maxXP = progress.totalXpPossible;
        final percentage = maxXP > 0 ? (earnedXP / maxXP).clamp(0.0, 1.0) : 0.0;
        final achievements = progress.achievements;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month header with XP progress — hairline-led
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (progress.monthName.isNotEmpty ? progress.monthName : 'This Month').toUpperCase(),
                      style: ZType.disp(19, color: textColor, height: 0.96),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${progress.daysRemaining} days remaining'.toUpperCase(),
                      style: ZType.lbl(9, color: textMuted, letterSpacing: 1.3),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$earnedXP / $maxXP XP',
                      style: ZType.data(12, color: AppColors.gamGold),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${progress.completedCount}/${achievements.length} complete'.toUpperCase(),
                      style: ZType.lbl(9, color: textMuted, letterSpacing: 1.3),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: percentage,
                minHeight: 6,
                backgroundColor: AppColors.hairlineStrong,
                valueColor: const AlwaysStoppedAnimation(AppColors.gamGold),
              ),
            ),
            const SizedBox(height: 6),

            // Achievements list — hairline rows
            ...achievements.map((achievement) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.hairline),
                  ),
                ),
                child: Row(
                  children: [
                    // Status glyph
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: achievement.completed ? AppColors.green : surface,
                        shape: BoxShape.circle,
                        border: achievement.completed
                            ? null
                            : Border.all(color: hairBorder),
                      ),
                      child: achievement.completed
                          ? const Icon(Icons.check, size: 15, color: Colors.black)
                          : Icon(
                              _monthlyIcon(achievement.icon),
                              size: 14,
                              color: textMuted,
                            ),
                    ),
                    const SizedBox(width: 11),
                    // Name and progress
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            achievement.name,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: achievement.completed ? textMuted : textColor,
                              decoration: achievement.completed ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          if (!achievement.completed)
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 3,
                                    margin: const EdgeInsets.only(top: 5),
                                    decoration: BoxDecoration(
                                      color: AppColors.hairlineStrong,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    child: FractionallySizedBox(
                                      widthFactor: achievement.progress,
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: AppColors.gamGold,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${achievement.currentInt}/${achievement.target}',
                                  style: ZType.data(9, color: textMuted),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // XP reward
                    Text(
                      '+${achievement.xpReward}',
                      style: ZType.lbl(11,
                          color: achievement.completed ? AppColors.green : AppColors.gamGold,
                          weight: FontWeight.w800,
                          letterSpacing: 0.5),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }


  Widget _buildInventoryButton(
    BuildContext context,
    WidgetRef ref,
    Color textColor,
    Color textMuted,
    Color cardBg,
    Color borderColor,
    Color accentColor,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surface : AppColorsLight.surface;
    final hairBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final consumables = ref.watch(consumablesProvider);
    final totalItems = (consumables?.streakShield ?? 0) +
        (consumables?.xpToken2x ?? 0) +
        (consumables?.fitnessCrate ?? 0) +
        (consumables?.premiumCrate ?? 0);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/inventory');
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: hairBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              color: AppColors.gamGold,
              size: 17,
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                AppLocalizations.of(context).xpGoalsScreenInventory.toUpperCase(),
                style: ZType.lbl(11, color: textSecondary, letterSpacing: 1.3),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (totalItems > 0) ...[
              const SizedBox(width: 6),
              Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.gamGold,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$totalItems',
                  style: ZType.data(10, color: Colors.black),
                ),
              ),
            ],
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              color: textMuted,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }


}
