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
import '../../widgets/glass_back_button.dart';
import '../../widgets/glass_sheet.dart';
import '../../widgets/level_up_catch_up_banner.dart';
import '../../widgets/segmented_tab_bar.dart';

part 'xp_goals_screen_part_first_time_bonus.dart';

part 'xp_goals_screen_ui_1.dart';
part 'xp_goals_screen_ui_2.dart';


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
                    GlassBackButton(
                      onTap: () {
                        HapticService.light();
                        context.pop();
                      },
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
                    // Retroactive level-up banner (only visible if unacked events exist)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
                        child: LevelUpCatchUpBanner(),
                      ),
                    ),
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


  /// Maps backend icon name strings to Material IconData for monthly achievements.
  IconData _monthlyIcon(String name) {
    const map = <String, IconData>{
      'calendar': Icons.calendar_today,
      'flag': Icons.flag,
      'restaurant': Icons.restaurant,
      'check_circle': Icons.check_circle_outline,
      'water_drop': Icons.water_drop,
      'monitor': Icons.monitor_weight,
      'checklist': Icons.checklist,
      'emoji_events': Icons.emoji_events,
      'share': Icons.share,
      'favorite': Icons.favorite,
      'star': Icons.star,
      'fitness_center': Icons.fitness_center,
      'local_fire_department': Icons.local_fire_department,
      'trending_up': Icons.trending_up,
      'bolt': Icons.bolt,
    };
    return map[name] ?? Icons.emoji_events;
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
              'Daily Goals (6 total)',
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
                'First Meal/Weight/Measurements: +50 XP each',
                'First Chat with AI Coach: +15 XP',
              ],
              isDark,
            ),
            const SizedBox(height: 16),
            _buildXPInfoSection(
              'Levels',
              [
                '250 levels across 11 tiers',
                'Beginner (1-10) to Transcendent (226-250)',
                'Milestone rewards at key levels',
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
  showGlassSheet(
    context: context,
    builder: (context) => _AllLevelsSheet(
      currentLevel: currentLevel,
      accentColor: accentColor,
    ),
  );
}
