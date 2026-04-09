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
    final currentLevel = userXp?.currentLevel ?? 1;
    // Ensure XP values are never negative (data corruption safeguard)
    final xpInCurrentLevel = (userXp?.xpInCurrentLevel ?? 0).clamp(0, 999999);
    final xpToNextLevel = (userXp?.xpToNextLevel ?? 50).clamp(1, 100000);
    final progressFraction = (userXp?.progressFraction ?? 0.0).clamp(0.0, 1.0);
    final xpTitle = userXp?.xpTitle ?? XPTitle.novice;
    final titleColor = Color(xpTitle.colorValue);

    final progressBgColor = isDark
        ? textMuted.withValues(alpha: 0.2)
        : Colors.grey.shade300;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header row with title, total XP, and info button
          Row(
            children: [
              Text(
                'Level Progress',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              // Total XP badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: isDark ? 0.15 : 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.stars_rounded,
                      size: 14,
                      color: accentColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${userXp?.formattedTotalXp ?? "0"} XP',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Info button
              GestureDetector(
                onTap: () => _showXPInfoDialog(context, isDark),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: textMuted.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Level badges with circular progress
          Row(
            children: [
              // Current level with circular progress
              Stack(
                alignment: Alignment.center,
                children: [
                  SimpleCircularProgressBar(
                    size: 64,
                    progressStrokeWidth: 5,
                    backStrokeWidth: 4,
                    valueNotifier: ValueNotifier(progressFraction * 100),
                    progressColors: [
                      accentColor.withValues(alpha: 0.7),
                      accentColor,
                      accentColor.withValues(alpha: 0.9),
                    ],
                    backColor: progressBgColor,
                    mergeMode: true,
                    animationDuration: 1,
                    startAngle: -90,
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          titleColor,
                          titleColor.withValues(alpha: 0.7),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: titleColor.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        currentLevel.toString(),
                        style: TextStyle(
                          fontSize: currentLevel >= 100 ? 14 : 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 16),

              // XP Progress info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: titleColor.withValues(alpha: isDark ? 0.15 : 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: titleColor.withValues(alpha: isDark ? 0.3 : 0.4),
                            ),
                          ),
                          child: Text(
                            xpTitle.displayName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? titleColor : titleColor.withValues(alpha: 0.9),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${(progressFraction * 100).round()}%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Progress bar
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: progressBgColor,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: LinearProgressIndicator(
                          value: progressFraction,
                          minHeight: 10,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation(accentColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$xpInCurrentLevel / $xpToNextLevel XP',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? textColor : Colors.black87,
                          ),
                        ),
                        Text(
                          'Lvl ${currentLevel + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark ? textMuted : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // View All Levels button
          GestureDetector(
            onTap: () => _showAllLevelsSheet(context, currentLevel, accentColor),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: isDark ? 0.15 : 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: accentColor.withValues(alpha: isDark ? 0.3 : 0.4),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.stairs,
                    color: accentColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'View All Levels & Rewards',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    color: accentColor,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
        title: 'Log in today',
        xp: dailyLoginXP,
        isComplete: hasLoggedInToday,
        icon: Icons.login,
      ),
      _DailyGoal(
        title: 'Complete 1 workout',
        xp: 100,
        isComplete: dailyGoalsState?.completedWorkout ?? false,
        icon: Icons.fitness_center,
      ),
      _DailyGoal(
        title: 'Log a meal',
        xp: 25,
        isComplete: dailyGoalsState?.loggedMeal ?? false,
        icon: Icons.restaurant,
      ),
      _DailyGoal(
        title: 'Log weight',
        xp: 15,
        isComplete: dailyGoalsState?.loggedWeight ?? false,
        icon: Icons.monitor_weight_outlined,
      ),
      _DailyGoal(
        title: 'Hit protein goal',
        xp: 50,
        isComplete: dailyGoalsState?.hitProteinGoal ?? false,
        icon: Icons.egg_alt,
      ),
      _DailyGoal(
        title: 'Log body measurements',
        xp: 20,
        isComplete: dailyGoalsState?.loggedBodyMeasurements ?? false,
        icon: Icons.straighten,
      ),
    ];

    final completedCount = dailyGoals.where((g) => g.isComplete).length;
    final totalXPEarned = dailyGoals
        .where((g) => g.isComplete)
        .fold(0, (sum, g) => sum + g.xp);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Summary row
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: isDark ? 0.08 : 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(
                  '$completedCount/${dailyGoals.length}',
                  'Goals',
                  isDark ? textColor : Colors.black87,
                  isDark ? textMuted : Colors.black54,
                ),
                Container(
                  width: 1,
                  height: 28,
                  color: isDark ? textMuted.withValues(alpha: 0.2) : Colors.grey.shade400,
                ),
                _buildStatColumn(
                  '+$totalXPEarned',
                  'XP Today',
                  isDark ? textColor : Colors.black87,
                  isDark ? textMuted : Colors.black54,
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
      ),
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
    final extendedProgress = ref.watch(extendedWeeklyProgressProvider);

    final dividerColor = isDark ? textMuted.withValues(alpha: 0.1) : Colors.grey.shade300;
    final progressBgColor = isDark ? textMuted.withValues(alpha: 0.2) : Colors.grey.shade300;

    return extendedProgress.when(
      loading: () => Container(
        height: 100,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Text('Error loading weekly progress', style: TextStyle(color: textMuted)),
      ),
      data: (progress) {
        final earnedXP = progress.totalXpEarned;
        final maxXP = progress.totalXpPossible;
        final percentage = maxXP > 0 ? (earnedXP / maxXP).clamp(0.0, 1.0) : 0.0;
        final checkpoints = progress.checkpoints;

        return Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: isDark ? null : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // XP Progress header
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$earnedXP XP',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? textColor : Colors.black87,
                          ),
                        ),
                        Text(
                          '/ $maxXP XP',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? textMuted : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: progressBgColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percentage,
                          minHeight: 8,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation(accentColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${progress.completedCount}/${checkpoints.length} checkpoints complete',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? textMuted : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),

              // Checkpoints list
              ...checkpoints.map((cp) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: dividerColor),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Icon
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: cp.completed
                              ? AppColors.green.withValues(alpha: isDark ? 0.15 : 0.12)
                              : (isDark ? textMuted.withValues(alpha: 0.1) : Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: cp.completed
                              ? Icon(Icons.check, size: 14, color: AppColors.green)
                              : Text(
                                  cp.icon.isNotEmpty ? cp.icon : '📋',
                                  style: const TextStyle(fontSize: 12),
                                ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Name and progress
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cp.name,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: cp.completed
                                    ? (isDark ? textMuted : Colors.black45)
                                    : (isDark ? textColor : Colors.black87),
                                decoration: cp.completed ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            if (!cp.completed)
                              Text(
                                '${cp.current}/${cp.target}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark ? textMuted : Colors.black54,
                                ),
                              ),
                          ],
                        ),
                      ),
                      // XP reward
                      Text(
                        '+${cp.xpReward} XP',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: cp.completed ? AppColors.green : accentColor,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
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
    final monthlyProgress = ref.watch(monthlyAchievementsProgressProvider);

    final dividerColor = isDark ? textMuted.withValues(alpha: 0.1) : Colors.grey.shade300;
    final progressBgColor = isDark ? textMuted.withValues(alpha: 0.2) : Colors.grey.shade300;

    return monthlyProgress.when(
      loading: () => Container(
        height: 100,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Text('Error loading monthly achievements', style: TextStyle(color: textMuted)),
      ),
      data: (progress) {
        final earnedXP = progress.totalXpEarned;
        final maxXP = progress.totalXpPossible;
        final percentage = maxXP > 0 ? (earnedXP / maxXP).clamp(0.0, 1.0) : 0.0;
        final achievements = progress.achievements;

        return Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: isDark ? null : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Month header with XP progress
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: isDark ? 0.08 : 0.1),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              progress.monthName.isNotEmpty ? progress.monthName : 'This Month',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isDark ? textColor : Colors.black87,
                              ),
                            ),
                            Text(
                              '${progress.daysRemaining} days remaining',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? textMuted : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$earnedXP / $maxXP XP',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? textColor : Colors.black87,
                              ),
                            ),
                            Text(
                              '${progress.completedCount}/${achievements.length} complete',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? textMuted : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: progressBgColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percentage,
                          minHeight: 8,
                          backgroundColor: Colors.transparent,
                          valueColor: const AlwaysStoppedAnimation(Colors.purple),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Achievements list
              ...achievements.map((achievement) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: dividerColor),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Icon
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: achievement.completed
                              ? Colors.purple.withValues(alpha: isDark ? 0.15 : 0.12)
                              : (isDark ? textMuted.withValues(alpha: 0.1) : Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: achievement.completed
                              ? const Icon(Icons.check, size: 14, color: Colors.purple)
                              : Icon(
                                  _monthlyIcon(achievement.icon),
                                  size: 14,
                                  color: isDark ? textMuted : Colors.grey.shade600,
                                ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Name and progress
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              achievement.name,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: achievement.completed
                                    ? (isDark ? textMuted : Colors.black45)
                                    : (isDark ? textColor : Colors.black87),
                                decoration: achievement.completed ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            if (!achievement.completed)
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 3,
                                      margin: const EdgeInsets.only(top: 4),
                                      decoration: BoxDecoration(
                                        color: progressBgColor,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                      child: FractionallySizedBox(
                                        widthFactor: achievement.progress,
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.purple,
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${achievement.currentInt}/${achievement.target}',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: isDark ? textMuted : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // XP reward
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: achievement.completed
                              ? Colors.purple.withValues(alpha: isDark ? 0.15 : 0.12)
                              : Colors.purple.withValues(alpha: isDark ? 0.1 : 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '+${achievement.xpReward} XP',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: achievement.completed ? Colors.purple.shade700 : Colors.purple.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
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
    final consumables = ref.watch(consumablesProvider);
    final totalItems = (consumables?.streakShield ?? 0) +
        (consumables?.xpToken2x ?? 0) +
        (consumables?.fitnessCrate ?? 0) +
        (consumables?.premiumCrate ?? 0);

    const purpleAccent = Color(0xFF9C27B0);
    final strongBorder = isDark
        ? purpleAccent.withValues(alpha: 0.3)
        : purpleAccent.withValues(alpha: 0.5);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/inventory');
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: strongBorder, width: 1.5),
          boxShadow: isDark ? null : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.inventory_2,
              color: purpleAccent,
              size: 18,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Inventory',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? textColor : Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (totalItems > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: purpleAccent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$totalItems',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right,
              color: purpleAccent,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

}
