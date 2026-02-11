import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:simple_circular_progress_bar/simple_circular_progress_bar.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../data/providers/xp_provider.dart';
import '../../data/models/xp_event.dart';
import '../../data/models/user_xp.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/dismissed_banners_section.dart';
import '../../widgets/segmented_tab_bar.dart';

/// Full-screen XP Goals page showing daily, weekly, and monthly XP goals with tabs
class XPGoalsScreen extends ConsumerStatefulWidget {
  const XPGoalsScreen({super.key});

  @override
  ConsumerState<XPGoalsScreen> createState() => _XPGoalsScreenState();
}

class _XPGoalsScreenState extends ConsumerState<XPGoalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.background : AppColorsLight.background;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    // Get dynamic accent color
    final accentEnum = ref.watch(accentColorProvider);
    final accentColor = accentEnum.getColor(isDark);

    final loginStreak = ref.watch(loginStreakProvider);
    final hasDoubleXP = ref.watch(hasDoubleXPProvider);
    final multiplier = ref.watch(xpMultiplierProvider);
    final xpState = ref.watch(xpProvider);
    final userXp = xpState.userXp;

    // Card colors
    final cardBg = isDark ? AppColors.elevated : Colors.grey.shade100;
    final borderColor = isDark ? cardBorder : Colors.grey.shade300;

    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // Tab bar widget used in both the sliver header and for measuring height
    final tabBar = SegmentedTabBar(
      controller: _tabController,
      showIcons: false,
      tabs: const [
        SegmentedTabItem(label: 'Daily', icon: Icons.today),
        SegmentedTabItem(label: 'Weekly', icon: Icons.date_range),
        SegmentedTabItem(label: 'Monthly', icon: Icons.calendar_month),
      ],
    );

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          Column(
            children: [
              // Safe area
              SizedBox(height: MediaQuery.of(context).padding.top),

              // Fixed top bar with back button + title
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        HapticService.light();
                        context.pop();
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.6)
                              : Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(Icons.arrow_back, color: textColor, size: 22),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.bolt,
                        color: accentColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'XP Goals',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          if (hasDoubleXP)
                            Row(
                              children: [
                                const Icon(
                                  Icons.bolt,
                                  color: Colors.amber,
                                  size: 12,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '${multiplier.toInt()}x XP Active!',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.amber,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // NestedScrollView: header scrolls away, tabs pin, tab content fills
              Expanded(
                child: NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) => [
                    // Level Progress (scrolls away)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                        child: _buildLevelProgressSection(
                          context,
                          userXp,
                          textColor,
                          textMuted,
                          cardBg,
                          borderColor,
                          accentColor,
                        ),
                      ),
                    ),
                    // Login Streak Banner (scrolls away)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: _buildStreakBanner(
                          context,
                          loginStreak,
                          textColor,
                          textMuted,
                          cardBg,
                          borderColor,
                          accentColor,
                        ),
                      ),
                    ),
                    // Dismissed Banners (if any)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: DismissedBannersSection(),
                      ),
                    ),
                    // Pinned tab bar
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _StickyTabBarDelegate(
                        child: Container(
                          color: bgColor,
                          child: tabBar,
                        ),
                      ),
                    ),
                  ],
                  body: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDailyTab(
                        context,
                        ref,
                        loginStreak,
                        textColor,
                        textMuted,
                        cardBg,
                        borderColor,
                        multiplier,
                        accentColor,
                        bottomPadding: bottomPadding + 70,
                      ),
                      _buildWeeklyTab(
                        context,
                        ref,
                        textColor,
                        textMuted,
                        cardBg,
                        borderColor,
                        accentColor,
                        bottomPadding: bottomPadding + 70,
                      ),
                      _buildMonthlyTab(
                        context,
                        ref,
                        textColor,
                        textMuted,
                        cardBg,
                        borderColor,
                        accentColor,
                        bottomPadding: bottomPadding + 70,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Floating bottom buttons
          Positioned(
            left: 16,
            right: 16,
            bottom: bottomPadding + 12,
            child: Row(
              children: [
                Expanded(
                  child: _buildTrophyRoomButton(
                    context,
                    textColor,
                    textMuted,
                    cardBg,
                    borderColor,
                    accentColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInventoryButton(
                    context,
                    ref,
                    textColor,
                    textMuted,
                    cardBg,
                    borderColor,
                    accentColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  /// Daily tab content
  Widget _buildDailyTab(
    BuildContext context,
    WidgetRef ref,
    LoginStreakInfo? loginStreak,
    Color textColor,
    Color textMuted,
    Color cardBg,
    Color borderColor,
    double multiplier,
    Color accentColor, {
    double bottomPadding = 16,
  }) {
    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Daily Goals Card
                _buildDailyGoalsCard(
                  context,
                  ref,
                  loginStreak,
                  textColor,
                  textMuted,
                  cardBg,
                  borderColor,
                  multiplier,
                  accentColor,
                ),
                const SizedBox(height: 16),
                // First-Time Bonuses section
                _buildSectionHeader(
                  'First-Time Bonuses',
                  Icons.star_outline,
                  textColor,
                  textMuted,
                ),
                const SizedBox(height: 8),
                _buildFirstTimeBonusesCard(
                  context,
                  ref,
                  textColor,
                  textMuted,
                  cardBg,
                  borderColor,
                  accentColor,
                ),
                SizedBox(height: bottomPadding),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Weekly tab content
  Widget _buildWeeklyTab(
    BuildContext context,
    WidgetRef ref,
    Color textColor,
    Color textMuted,
    Color cardBg,
    Color borderColor,
    Color accentColor, {
    double bottomPadding = 16,
  }) {
    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildExtendedWeeklyProgressCard(
                  context,
                  ref,
                  textColor,
                  textMuted,
                  cardBg,
                  borderColor,
                  accentColor,
                ),
                SizedBox(height: bottomPadding),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Monthly tab content
  Widget _buildMonthlyTab(
    BuildContext context,
    WidgetRef ref,
    Color textColor,
    Color textMuted,
    Color cardBg,
    Color borderColor,
    Color accentColor, {
    double bottomPadding = 16,
  }) {
    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMonthlyAchievementsCard(
                  context,
                  ref,
                  textColor,
                  textMuted,
                  cardBg,
                  borderColor,
                  accentColor,
                ),
                SizedBox(height: bottomPadding),
              ],
            ),
          ),
        ],
      ),
    );
  }

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

  Widget _buildStreakBanner(
    BuildContext context,
    LoginStreakInfo? streak,
    Color textColor,
    Color textMuted,
    Color cardBg,
    Color borderColor,
    Color accentColor,
  ) {
    final currentStreak = streak?.currentStreak ?? 0;
    final hasLoggedInToday = streak?.hasLoggedInToday ?? false;
    const dailyLoginXP = 5;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade400,
            Colors.deepOrange.shade500,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    color: Colors.white,
                    size: 20,
                  ),
                  Text(
                    '$currentStreak',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Login Streak',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  hasLoggedInToday
                      ? '+$dailyLoginXP XP earned today'
                      : '+$dailyLoginXP XP available',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    IconData icon,
    Color textColor,
    Color textMuted, {
    String? subtitle,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: textMuted),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        if (subtitle != null) ...[
          const Spacer(),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: textMuted,
            ),
          ),
        ],
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

  Widget _buildStatColumn(
    String value,
    String label,
    Color textColor,
    Color textMuted,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildGoalRow(
    _DailyGoal goal,
    Color textColor,
    Color textMuted,
    double multiplier,
    Color accentColor,
    bool isDark,
  ) {
    final effectiveXP = (goal.xp * multiplier).round();
    final dividerColor = isDark ? textMuted.withValues(alpha: 0.1) : Colors.grey.shade300;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: dividerColor),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: goal.isComplete
                  ? AppColors.green.withValues(alpha: isDark ? 0.15 : 0.12)
                  : (isDark ? textMuted.withValues(alpha: 0.1) : Colors.grey.shade200),
              shape: BoxShape.circle,
            ),
            child: Icon(
              goal.isComplete ? Icons.check : goal.icon,
              size: 15,
              color: goal.isComplete ? AppColors.green : (isDark ? textMuted : Colors.grey.shade600),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              goal.title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: goal.isComplete ? textMuted : textColor,
                decoration: goal.isComplete ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          Text(
            '+$effectiveXP XP',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: goal.isComplete ? AppColors.green : accentColor,
            ),
          ),
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
                              : Text(
                                  achievement.icon.isNotEmpty ? achievement.icon : '🏆',
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

  Widget _buildTrophyRoomButton(
    BuildContext context,
    Color textColor,
    Color textMuted,
    Color cardBg,
    Color borderColor,
    Color accentColor,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final strongBorder = isDark
        ? accentColor.withValues(alpha: 0.3)
        : accentColor.withValues(alpha: 0.5);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/trophy-room');
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
            Icon(
              Icons.emoji_events,
              color: accentColor,
              size: 18,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Trophy Room',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? textColor : Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              color: accentColor,
              size: 16,
            ),
          ],
        ),
      ),
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

  Widget _buildFirstTimeBonusesCard(
    BuildContext context,
    WidgetRef ref,
    Color textColor,
    Color textMuted,
    Color cardBg,
    Color borderColor,
    Color accentColor,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final awardedBonuses = ref.watch(awardedBonusesProvider);

    final dividerColor = isDark ? textMuted.withValues(alpha: 0.1) : Colors.grey.shade300;

    // First-time bonuses list
    final bonuses = [
      _FirstTimeBonus(
        type: 'first_workout',
        title: 'Complete First Workout',
        xp: 150,
        icon: Icons.fitness_center,
        isAwarded: awardedBonuses.contains('first_workout'),
      ),
      _FirstTimeBonus(
        type: 'first_meal_log',
        title: 'Log First Meal',
        xp: 50,
        icon: Icons.restaurant,
        isAwarded: awardedBonuses.contains('first_breakfast') ||
            awardedBonuses.contains('first_lunch') ||
            awardedBonuses.contains('first_dinner') ||
            awardedBonuses.contains('first_snack'),
      ),
      _FirstTimeBonus(
        type: 'first_weight_log',
        title: 'Log First Weight',
        xp: 50,
        icon: Icons.monitor_weight_outlined,
        isAwarded: awardedBonuses.contains('first_weight_log'),
      ),
      _FirstTimeBonus(
        type: 'first_protein_goal',
        title: 'Hit First Protein Goal',
        xp: 100,
        icon: Icons.egg_alt,
        isAwarded: awardedBonuses.contains('first_protein_goal'),
      ),
      _FirstTimeBonus(
        type: 'first_chat',
        title: 'Chat with AI Coach',
        xp: 50,
        icon: Icons.chat_bubble_outline,
        isAwarded: awardedBonuses.contains('first_chat'),
      ),
      _FirstTimeBonus(
        type: 'first_pr',
        title: 'Set First Personal Record',
        xp: 100,
        icon: Icons.emoji_events,
        isAwarded: awardedBonuses.contains('first_pr'),
      ),
    ];

    final earnedCount = bonuses.where((b) => b.isAwarded).length;
    final totalXPEarned = bonuses.where((b) => b.isAwarded).fold(0, (sum, b) => sum + b.xp);
    final totalXPAvailable = bonuses.fold(0, (sum, b) => sum + b.xp);

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
              color: Colors.amber.withValues(alpha: isDark ? 0.08 : 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(
                  '$earnedCount/${bonuses.length}',
                  'Bonuses',
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
                  'of $totalXPAvailable XP',
                  isDark ? textColor : Colors.black87,
                  isDark ? textMuted : Colors.black54,
                ),
              ],
            ),
          ),

          // Bonuses list
          ...bonuses.map((bonus) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: dividerColor),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: bonus.isAwarded
                            ? Colors.amber.withValues(alpha: isDark ? 0.15 : 0.12)
                            : (isDark ? textMuted.withValues(alpha: 0.1) : Colors.grey.shade200),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        bonus.isAwarded ? Icons.check : bonus.icon,
                        size: 15,
                        color: bonus.isAwarded ? Colors.amber : (isDark ? textMuted : Colors.grey.shade600),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        bonus.title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: bonus.isAwarded ? textMuted : textColor,
                          decoration: bonus.isAwarded ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: bonus.isAwarded
                            ? Colors.amber.withValues(alpha: isDark ? 0.15 : 0.12)
                            : Colors.amber.withValues(alpha: isDark ? 0.1 : 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!bonus.isAwarded)
                            const Icon(Icons.star, size: 11, color: Colors.amber),
                          if (!bonus.isAwarded) const SizedBox(width: 3),
                          Text(
                            '+${bonus.xp} XP',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: bonus.isAwarded ? Colors.amber.shade700 : Colors.amber.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _FirstTimeBonus {
  final String type;
  final String title;
  final int xp;
  final IconData icon;
  final bool isAwarded;

  _FirstTimeBonus({
    required this.type,
    required this.title,
    required this.xp,
    required this.icon,
    required this.isAwarded,
  });
}

class _DailyGoal {
  final String title;
  final int xp;
  final bool isComplete;
  final IconData icon;

  _DailyGoal({
    required this.title,
    required this.xp,
    required this.isComplete,
    required this.icon,
  });
}

/// Shows the XP calculation info dialog
void _showXPInfoDialog(BuildContext context, bool isDark) {
  HapticFeedback.lightImpact();
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(
            Icons.stars_rounded,
            color: isDark ? const Color(0xFF00D9FF) : const Color(0xFF0099CC),
          ),
          const SizedBox(width: 8),
          Text(
            'How XP Works',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildXPInfoSection(
              'Daily Goals',
              [
                'Login: +5 XP',
                'Complete Workout: +100 XP',
                'Log Meal: +25 XP',
                'Log Weight: +15 XP',
                'Hit Protein Goal: +50 XP',
                'Log Body Measurements: +20 XP',
              ],
              isDark,
            ),
            const SizedBox(height: 16),
            _buildXPInfoSection(
              'First-Time Bonuses',
              [
                'First Workout: +150 XP',
                'First Protein Goal: +100 XP',
                'First PR: +100 XP',
                'First Progress Photo: +75 XP',
                'First Meal/Weight/Chat/Measurements: +50 XP each',
              ],
              isDark,
            ),
            const SizedBox(height: 16),
            _buildXPInfoSection(
              'Streaks & Milestones',
              [
                '7-Day Streak: +100 XP',
                '30-Day Streak: +500 XP',
                '100-Day Streak: +2000 XP',
                '365-Day Streak: +10000 XP',
              ],
              isDark,
            ),
            const SizedBox(height: 16),
            _buildXPInfoSection(
              'Special Bonuses',
              [
                'First Login: +250 XP',
                'Early Adopter (First 100): +525 XP',
                'Weekly/Monthly Checkpoints: +100-200 XP',
              ],
              isDark,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Got it!',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFF00D9FF) : const Color(0xFF0099CC),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildXPInfoSection(String title, List<String> items, bool isDark) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white70 : Colors.black87,
        ),
      ),
      const SizedBox(height: 6),
      ...items.map((item) => Padding(
        padding: const EdgeInsets.only(left: 8, bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '\u2022 ',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
            Expanded(
              child: Text(
                item,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ),
          ],
        ),
      )),
    ],
  );
}

/// Shows the "View All Levels" sheet
void _showAllLevelsSheet(BuildContext context, int currentLevel, Color accentColor) {
  HapticFeedback.lightImpact();
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useRootNavigator: true,
    builder: (context) => _AllLevelsSheet(
      currentLevel: currentLevel,
      accentColor: accentColor,
    ),
  );
}

/// Level data model
class _LevelInfo {
  final int level;
  final int xpRequired;
  final String title;
  final String levelName;
  final String? reward;
  final String? rewardIcon;
  final bool isMilestone;

  const _LevelInfo({
    required this.level,
    required this.xpRequired,
    required this.title,
    required this.levelName,
    this.reward,
    this.rewardIcon,
    this.isMilestone = false,
  });

  static String getLevelName(int level) {
    const levelNames = <int, String>{
      1: 'First Steps', 2: 'Awakening', 3: 'Foundation', 4: 'Momentum',
      5: 'Rising Star', 6: 'Steadfast', 7: 'Determined', 8: 'Resilient',
      9: 'Breakthrough', 10: 'Iron Will',
      11: 'Pathfinder', 12: 'Trailblazer', 13: 'Forged', 14: 'Unyielding',
      15: 'Disciplined', 16: 'Focused', 17: 'Driven', 18: 'Relentless',
      19: 'Unstoppable', 20: 'Silver Strength', 21: 'Tempered', 22: 'Hardened',
      23: 'Unbreakable', 24: 'Tenacious', 25: 'Dedicated',
      26: 'Competitor', 27: 'Challenger', 28: 'Fierce', 29: 'Powerhouse',
      30: 'Gold Standard', 31: 'Peak Form', 32: 'Dynamo', 33: 'Juggernaut',
      34: 'Titan', 35: 'Colossus', 36: 'Champion', 37: 'Conqueror',
      38: 'Dominator', 39: 'Crusher', 40: 'Diamond Core', 41: 'Invincible',
      42: 'Supreme', 43: 'Almighty', 44: 'Transcendent', 45: 'Mythic Rise',
      46: 'Ascended', 47: 'Immortal', 48: 'Paragon', 49: 'Zenith', 50: 'Veteran',
      51: 'Elite Guard', 52: 'Vanguard', 53: 'Sentinel', 54: 'Warden',
      55: 'Gladiator', 56: 'Spartan', 57: 'Berserker', 58: 'Valkyrie',
      59: 'Phoenix', 60: 'Elite Force', 61: 'Apex', 62: 'Sovereign',
      63: 'Overlord', 64: 'Commander', 65: 'General', 66: 'Warlord',
      67: 'Conqueror II', 68: 'Destroyer', 69: 'Annihilator', 70: 'Purple Heart',
      71: 'Harbinger', 72: 'Omega', 73: 'Absolute', 74: 'Supreme II', 75: 'Elite',
      76: 'Grandmaster', 77: 'Sage', 78: 'Oracle', 79: 'Prophet', 80: 'Master',
      81: 'Virtuoso', 82: 'Prodigy', 83: 'Genius', 84: 'Mastermind',
      85: 'Legendary Rise', 86: 'Architect', 87: 'Creator', 88: 'Worldbreaker',
      89: 'Godslayer', 90: 'Cosmic', 91: 'Celestial', 92: 'Divine',
      93: 'Eternal', 94: 'Infinite', 95: 'Ultimate', 96: 'Omega II',
      97: 'Alpha', 98: 'Primordial', 99: 'Apex Predator', 100: 'Legend',
    };
    return levelNames[level] ?? 'Level $level';
  }
}

/// All Levels Sheet
class _AllLevelsSheet extends StatelessWidget {
  final int currentLevel;
  final Color accentColor;

  const _AllLevelsSheet({
    required this.currentLevel,
    required this.accentColor,
  });

  static List<_LevelInfo> getAllLevels() {
    final levels = <_LevelInfo>[];

    final noviceLevelXP = [50, 100, 150, 200, 300, 400, 500, 750, 1000];
    for (int i = 0; i < noviceLevelXP.length; i++) {
      final level = i + 2;
      String? reward;
      String? rewardIcon;
      bool isMilestone = false;
      if (level == 5) { reward = '+1% XP Bonus'; rewardIcon = '⚡'; isMilestone = true; }
      else if (level == 10) { reward = 'Bronze Frame + 2x XP Tokens'; rewardIcon = '🎁'; isMilestone = true; }
      else if (level % 2 == 0) { reward = '+1% XP Bonus'; rewardIcon = '⚡'; }
      else { reward = 'Streak Shield'; rewardIcon = '🛡️'; }
      levels.add(_LevelInfo(level: level, xpRequired: noviceLevelXP[i], title: 'Novice', levelName: _LevelInfo.getLevelName(level), reward: reward, rewardIcon: rewardIcon, isMilestone: isMilestone));
    }

    for (int level = 11; level <= 25; level++) {
      String? reward; String? rewardIcon; bool isMilestone = false;
      if (level == 15) { reward = 'Apprentice Badge + Green Theme'; rewardIcon = '🎖️'; isMilestone = true; }
      else if (level == 20) { reward = 'Silver Frame + 3x XP Tokens'; rewardIcon = '🎁'; isMilestone = true; }
      else if (level == 25) { reward = 'Dedicated Badge + Blue Theme'; rewardIcon = '🏅'; isMilestone = true; }
      else if (level % 2 == 0) { reward = '+1% XP Bonus'; rewardIcon = '⚡'; }
      else { reward = 'Streak Shield'; rewardIcon = '🛡️'; }
      levels.add(_LevelInfo(level: level, xpRequired: 1500, title: 'Apprentice', levelName: _LevelInfo.getLevelName(level), reward: reward, rewardIcon: rewardIcon, isMilestone: isMilestone));
    }

    for (int level = 26; level <= 50; level++) {
      String? reward; String? rewardIcon; bool isMilestone = false;
      if (level == 30) { reward = 'Gold Frame + Animated Border'; rewardIcon = '🎁'; isMilestone = true; }
      else if (level == 50) { reward = 'Veteran Badge + FREE T-Shirt!'; rewardIcon = '👕'; isMilestone = true; }
      else if (level % 5 == 0) { reward = 'Fitness Crate'; rewardIcon = '📦'; isMilestone = true; }
      else if (level % 2 == 0) { reward = '+1% XP Bonus'; rewardIcon = '⚡'; }
      else { reward = '2x XP Token'; rewardIcon = '✨'; }
      levels.add(_LevelInfo(level: level, xpRequired: 5000, title: 'Athlete', levelName: _LevelInfo.getLevelName(level), reward: reward, rewardIcon: rewardIcon, isMilestone: isMilestone));
    }

    for (int level = 51; level <= 75; level++) {
      String? reward; String? rewardIcon; bool isMilestone = false;
      if (level == 60) { reward = 'Elite Badge + Purple Theme'; rewardIcon = '🎖️'; isMilestone = true; }
      else if (level == 75) { reward = 'Elite Badge + FREE Shaker!'; rewardIcon = '🥤'; isMilestone = true; }
      else if (level % 5 == 0) { reward = 'Diamond Crate'; rewardIcon = '💎'; isMilestone = true; }
      else if (level % 2 == 0) { reward = '+1% XP Bonus'; rewardIcon = '⚡'; }
      else { reward = '3x XP Token'; rewardIcon = '✨'; }
      levels.add(_LevelInfo(level: level, xpRequired: 10000, title: 'Elite', levelName: _LevelInfo.getLevelName(level), reward: reward, rewardIcon: rewardIcon, isMilestone: isMilestone));
    }

    for (int level = 76; level <= 99; level++) {
      String? reward; String? rewardIcon; bool isMilestone = false;
      if (level == 80) { reward = 'Master Badge + Orange Theme'; rewardIcon = '🎖️'; isMilestone = true; }
      else if (level == 90) { reward = 'Particle Effects'; rewardIcon = '✨'; isMilestone = true; }
      else if (level % 5 == 0) { reward = 'Legendary Crate'; rewardIcon = '🎁'; isMilestone = true; }
      else if (level % 2 == 0) { reward = '+1% XP Bonus'; rewardIcon = '⚡'; }
      else { reward = '5x Streak Shields'; rewardIcon = '🛡️'; }
      levels.add(_LevelInfo(level: level, xpRequired: 25000, title: 'Master', levelName: _LevelInfo.getLevelName(level), reward: reward, rewardIcon: rewardIcon, isMilestone: isMilestone));
    }

    levels.add(_LevelInfo(level: 100, xpRequired: 75000, title: 'Legend', levelName: _LevelInfo.getLevelName(100), reward: 'LEGEND Badge + Hoodie + Merch Kit!', rewardIcon: '🏆', isMilestone: true));

    return levels;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textColorStrong = isDark ? textColor : Colors.black.withValues(alpha: 0.85);
    final textMutedStrong = isDark ? textMuted : Colors.black.withValues(alpha: 0.55);
    final cardBg = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.15);

    final levels = getAllLevels();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, dragScrollController) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.6),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.1),
                  width: 0.5,
                ),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: textMuted.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                  child: Row(
                    children: [
                      Icon(Icons.stairs, color: accentColor, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('All Levels', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColorStrong)),
                            Text('Level $currentLevel • ${levels.length} levels total', style: TextStyle(fontSize: 12, color: textMutedStrong)),
                          ],
                        ),
                      ),
                      IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close, color: textMutedStrong, size: 22)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      _buildLegendItem('🎁', 'Milestone', textMutedStrong),
                      const SizedBox(width: 16),
                      _buildLegendItem('⚡', 'XP Bonus', textMutedStrong),
                      const SizedBox(width: 16),
                      _buildLegendItem('🛡️', 'Consumable', textMutedStrong),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    controller: dragScrollController,
                    padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).padding.bottom + 16),
                    itemCount: levels.length,
                    itemBuilder: (context, index) {
                      final level = levels[index];
                      return _buildLevelRow(level, level.level == currentLevel, level.level < currentLevel, textColorStrong, textMutedStrong, cardBg, borderColor, accentColor, isDark);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String icon, String label, Color textMuted) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, color: textMuted)),
      ],
    );
  }

  Widget _buildLevelRow(_LevelInfo level, bool isCurrentLevel, bool isCompleted, Color textColor, Color textMuted, Color cardBg, Color borderColor, Color accentColor, bool isDark) {
    final titleColor = _getTitleColor(level.title);

    Color getRewardColor() {
      if (level.reward == null) return Colors.grey;
      if (level.reward!.contains('Crate') || level.reward!.contains('crate')) {
        if (level.reward!.contains('Diamond')) return const Color(0xFF00BCD4);
        if (level.reward!.contains('Legendary')) return const Color(0xFFFF9800);
        if (level.reward!.contains('Fitness')) return const Color(0xFF4CAF50);
        return const Color(0xFF9C27B0);
      }
      if (level.reward!.contains('Frame')) return const Color(0xFFFF8F00);
      if (level.reward!.contains('Badge')) return titleColor;
      if (level.reward!.contains('Theme')) return const Color(0xFF9C27B0);
      if (level.reward!.contains('T-Shirt') || level.reward!.contains('Hoodie') || level.reward!.contains('Shaker')) return const Color(0xFFE91E63);
      if (level.reward!.contains('XP')) return const Color(0xFFFF8F00);
      if (level.reward!.contains('Shield')) return const Color(0xFF2196F3);
      if (level.reward!.contains('Token')) return const Color(0xFF9C27B0);
      return accentColor;
    }

    final rewardColor = getRewardColor();
    final isBigMilestone = level.level == 10 || level.level == 25 || level.level == 50 || level.level == 75 || level.level == 100;

    final cardBackground = isCurrentLevel
        ? (isDark ? const Color(0xFF1A3A5C) : const Color(0xFFE3F2FD))
        : isCompleted
            ? (isDark ? const Color(0xFF1B4332) : const Color(0xFFE8F5E9))
            : isBigMilestone
                ? (isDark ? const Color(0xFF3E2723) : const Color(0xFFFFF8E1))
                : isDark ? cardBg : Colors.grey.shade100;
    final strongBorder = isCurrentLevel
        ? accentColor.withValues(alpha: isDark ? 0.7 : 0.8)
        : isCompleted
            ? AppColors.green.withValues(alpha: isDark ? 0.5 : 0.6)
            : isBigMilestone
                ? rewardColor.withValues(alpha: isDark ? 0.6 : 0.7)
                : isDark ? borderColor : Colors.grey.shade300;
    final badgeColor = isCompleted || isCurrentLevel ? null : isBigMilestone ? null : (isDark ? textMuted.withValues(alpha: 0.2) : Colors.grey.shade300);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(isBigMilestone ? 14 : 12),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: strongBorder, width: isCurrentLevel ? 2.5 : isBigMilestone ? 2 : 1.5),
        boxShadow: isBigMilestone ? [BoxShadow(color: rewardColor.withValues(alpha: isDark ? 0.2 : 0.15), blurRadius: 8, offset: const Offset(0, 2))]
            : isDark ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: isBigMilestone ? 50 : 44, height: isBigMilestone ? 50 : 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isCompleted || isCurrentLevel || isBigMilestone
                      ? LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                          colors: isCurrentLevel ? [accentColor, accentColor.withValues(alpha: 0.7)]
                              : isCompleted ? [titleColor, titleColor.withValues(alpha: 0.7)]
                              : [rewardColor, rewardColor.withValues(alpha: 0.7)])
                      : null,
                  color: badgeColor,
                  boxShadow: isBigMilestone ? [BoxShadow(color: rewardColor.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 2))] : null,
                ),
                child: Center(
                  child: isCompleted && !isCurrentLevel
                      ? const Icon(Icons.check, color: Colors.white, size: 22)
                      : Text(level.level.toString(), style: TextStyle(fontSize: level.level >= 100 ? 14 : isBigMilestone ? 18 : 15, fontWeight: FontWeight.bold, color: isCurrentLevel || isCompleted || isBigMilestone ? Colors.white : (isDark ? textMuted : Colors.grey.shade600))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(child: Text(level.levelName, style: TextStyle(fontSize: isBigMilestone ? 15 : 14, fontWeight: FontWeight.w600, color: isDark ? textColor : Colors.black87), overflow: TextOverflow.ellipsis)),
                        if (isCurrentLevel) ...[const SizedBox(width: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(4)), child: const Text('YOU', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white)))],
                        if (isBigMilestone && !isCurrentLevel) ...[const SizedBox(width: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.amber.shade600, Colors.orange.shade600]), borderRadius: BorderRadius.circular(4)), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.star, size: 10, color: Colors.white), const SizedBox(width: 2), Text(level.level == 100 ? 'LEGENDARY' : 'MILESTONE', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white))]))],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1), decoration: BoxDecoration(color: titleColor.withValues(alpha: isDark ? 0.2 : 0.15), borderRadius: BorderRadius.circular(4)), child: Text(level.title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: titleColor))),
                        const SizedBox(width: 8),
                        Text('${_formatNumber(level.xpRequired)} XP', style: TextStyle(fontSize: 11, color: isDark ? textMuted : Colors.black54)),
                      ],
                    ),
                  ],
                ),
              ),
              if (level.reward != null && !isBigMilestone)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: rewardColor.withValues(alpha: isDark ? 0.2 : 0.15), borderRadius: BorderRadius.circular(10), border: Border.all(color: rewardColor.withValues(alpha: isDark ? 0.4 : 0.35))),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [if (level.rewardIcon != null) Text(level.rewardIcon!, style: const TextStyle(fontSize: 14))]),
                ),
            ],
          ),
          if (level.reward != null && isBigMilestone) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity, padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? rewardColor.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: rewardColor.withValues(alpha: isDark ? 0.4 : 0.5), width: 1.5),
                boxShadow: isDark ? null : [BoxShadow(color: rewardColor.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Row(
                children: [
                  Container(width: 40, height: 40, decoration: BoxDecoration(color: rewardColor.withValues(alpha: isDark ? 0.25 : 0.15), borderRadius: BorderRadius.circular(10), border: Border.all(color: rewardColor.withValues(alpha: 0.3))), child: Center(child: Text(level.rewardIcon ?? '🎁', style: const TextStyle(fontSize: 22)))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('REWARD', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: rewardColor, letterSpacing: 1)), const SizedBox(height: 2), Text(level.reward!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? textColor : Colors.black87))])),
                  if (!isCompleted) Icon(Icons.lock_outline, size: 18, color: isDark ? textMuted.withValues(alpha: 0.5) : Colors.grey.shade500),
                  if (isCompleted) const Icon(Icons.check_circle, size: 18, color: AppColors.green),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getTitleColor(String title) {
    switch (title) {
      case 'Novice': return const Color(0xFF9E9E9E);
      case 'Apprentice': return const Color(0xFF4CAF50);
      case 'Athlete': return const Color(0xFF2196F3);
      case 'Elite': return const Color(0xFF9C27B0);
      case 'Master': return const Color(0xFFFF9800);
      case 'Legend': return const Color(0xFFFFD700);
      default: return const Color(0xFF9E9E9E);
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(number % 1000 == 0 ? 0 : 1)}K';
    }
    return number.toString();
  }
}

/// Delegate for pinning the tab bar at the top when scrolled
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyTabBarDelegate({required this.child});

  // SegmentedTabBar height: padding(8+8) + containerPadding(4+4) + buttonPadding(12+12) + text(~16) = ~64
  // Adding a bit extra to prevent clipping
  @override
  double get minExtent => 68;
  @override
  double get maxExtent => 68;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant _StickyTabBarDelegate oldDelegate) {
    return child != oldDelegate.child;
  }
}
