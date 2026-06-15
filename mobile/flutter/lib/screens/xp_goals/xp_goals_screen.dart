import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../core/widgets/skeleton/skeleton.dart';
import '../../data/providers/xp_provider.dart';
import '../../data/models/xp_event.dart';
import '../../data/models/user_xp.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/dismissed_banners_section.dart';
import '../../widgets/glass_back_button.dart';
import '../../widgets/glass_sheet.dart';
import '../../widgets/level_up_catch_up_banner.dart';
import '../../widgets/segmented_tab_bar.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../core/theme/theme_colors.dart';
import '../../widgets/design_system/zealova.dart';

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
    // Force a fresh server fetch on every visit to this screen. The XP
    // provider hangs onto a static in-memory cache (`_xpInMemoryCache`)
    // so pre-level-up state can survive an app restart and produce the
    // contradiction the user reported (orange "you leveled up to 9" banner
    // while the Level Progress card still ringed Level 8). Refetching
    // silently keeps the screen instant but always truthful.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(xpProvider.notifier).loadUserXP(showLoading: false);
      }
    });
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
    final l10n = AppLocalizations.of(context)!;
    final tabBar = SegmentedTabBar(
      controller: _tabController,
      showIcons: false,
      tabs: [
        SegmentedTabItem(label: l10n.xpGoalsDaily, icon: Icons.today),
        SegmentedTabItem(label: l10n.xpGoalsWeekly, icon: Icons.date_range),
        SegmentedTabItem(label: l10n.xpGoalsMonthly, icon: Icons.calendar_month),
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
                            l10n.xpGoalsXpGoals.toUpperCase(),
                            style: ZType.disp(22, color: textColor),
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
                                  AppLocalizations.of(context)!.xpGoalsXpMultiplierActive(multiplier.toInt()),
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
                  AppLocalizations.of(context)!.xpGoalsFirstTimeBonuses,
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

    // v2 strips the boxed orange/teal hero: the streak reads as a hairline
    // row — a gold-ringed flame disc with an Anton day-count over it, a Barlow
    // kicker + Fraunces status line, and a gold XP chip on the right. Orange is
    // reserved for the single CLAIM elsewhere; status colour here is gold.
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.hairline),
          bottom: BorderSide(color: AppColors.hairline),
        ),
      ),
      child: Row(
        children: [
          // Flame disc — gold rarity ring, no solid gradient fill
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Color(0x33FBBF24), Colors.transparent],
                stops: [0.0, 0.72],
                center: Alignment(-0.3, -0.4),
              ),
              border: Border.all(
                color: AppColors.gamGold.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.local_fire_department_outlined,
                  color: AppColors.gamGold,
                  size: 17,
                ),
                Text(
                  '$currentStreak',
                  style: ZType.disp(13, color: AppColors.gamGold, height: 1.0),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.xpGoalsLoginStreak.toUpperCase(),
                  style: ZType.lbl(12, color: textColor, letterSpacing: 1.5),
                ),
                const SizedBox(height: 3),
                Text(
                  hasLoggedInToday
                      ? AppLocalizations.of(context)!.xpGoalsXpEarnedToday(dailyLoginXP)
                      : AppLocalizations.of(context)!.xpGoalsXpAvailable(dailyLoginXP),
                  style: ZType.ser(12.5, color: textMuted),
                ),
              ],
            ),
          ),
          // Gold XP chip — status/earned colour, never orange
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: AppColors.gamGold.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              hasLoggedInToday ? '+$dailyLoginXP' : '+$dailyLoginXP XP',
              style: ZType.lbl(11,
                  color: AppColors.gamGold,
                  weight: FontWeight.w800,
                  letterSpacing: 0.5),
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
    // v2 `gm-kick`: a Barlow uppercase grey kicker with a leading outlined
    // glyph, sitting on a hairline rule (no boxed card header).
    return Row(
      children: [
        Icon(icon, size: 15, color: textMuted),
        const SizedBox(width: 7),
        Text(
          title.toUpperCase(),
          style: ZType.lbl(11, color: textMuted, letterSpacing: 2.5),
        ),
        if (subtitle != null) ...[
          const Spacer(),
          Text(
            subtitle,
            style: ZType.data(11, color: textMuted),
          ),
        ],
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
          // Round status check — green filled when done, gold hairline when open
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: goal.isComplete ? AppColors.success : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: goal.isComplete ? AppColors.success : AppColors.gamGold,
                width: 1.5,
              ),
            ),
            child: goal.isComplete
                ? const Icon(Icons.check, size: 12, color: Colors.black)
                : Icon(goal.icon, size: 10, color: AppColors.gamGold),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              goal.title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: goal.isComplete ? textMuted : textColor,
                decoration: goal.isComplete ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          Text(
            '+$effectiveXP',
            style: ZType.lbl(11,
                color: goal.isComplete ? AppColors.success : AppColors.gamGold,
                weight: FontWeight.w800,
                letterSpacing: 0.5),
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
    final surface = isDark ? AppColors.surface : AppColorsLight.surface;
    final hairBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    // v2: trophy iconography is GOLD (status domain), not the user accent.
    // Matched to the Inventory button as a paired hairline tile.
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/trophy-room');
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
              Icons.emoji_events_outlined,
              color: AppColors.gamGold,
              size: 17,
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                AppLocalizations.of(context)!.xpGoalsTrophyRoom.toUpperCase(),
                style: ZType.lbl(11, color: textSecondary, letterSpacing: 1.3),
                overflow: TextOverflow.ellipsis,
              ),
            ),
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
            color: AppColors.gamGold,
          ),
          const SizedBox(width: 8),
          Text(
            AppLocalizations.of(context)!.xpGoalsHowXpWorks,
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
              AppLocalizations.of(context)!.xpGoalsDialogDailyGoals,
              [
                AppLocalizations.of(context)!.xpGoalsDialogLoginXp,
                AppLocalizations.of(context)!.xpGoalsDialogCompleteWorkoutXp,
                AppLocalizations.of(context)!.xpGoalsDialogLogMealXp,
                AppLocalizations.of(context)!.xpGoalsDialogLogWeightXp,
                AppLocalizations.of(context)!.xpGoalsDialogHitProteinGoalXp,
                AppLocalizations.of(context)!.xpGoalsDialogLogBodyMeasurementsXp,
              ],
              isDark,
            ),
            const SizedBox(height: 16),
            _buildXPInfoSection(
              AppLocalizations.of(context)!.xpGoalsFirstTimeBonuses,
              [
                AppLocalizations.of(context)!.xpGoalsDialogFirstWorkoutXp,
                AppLocalizations.of(context)!.xpGoalsDialogFirstProteinGoalXp,
                AppLocalizations.of(context)!.xpGoalsDialogFirstPrXp,
                AppLocalizations.of(context)!.xpGoalsDialogFirstProgressPhotoXp,
                AppLocalizations.of(context)!.xpGoalsDialogFirstMealWeightMeasurementsXp,
                AppLocalizations.of(context)!.xpGoalsDialogFirstChatWithAiCoachXp,
              ],
              isDark,
            ),
            const SizedBox(height: 16),
            _buildXPInfoSection(
              AppLocalizations.of(context)!.xpGoalsDialogLevels,
              [
                AppLocalizations.of(context)!.xpGoalsDialog250LevelsAcross11Tiers,
                AppLocalizations.of(context)!.xpGoalsDialogBeginnerToTranscendent,
                AppLocalizations.of(context)!.xpGoalsDialogMilestoneRewards,
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
            AppLocalizations.of(context)!.xpGoalsGotIt,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.gamGold,
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
