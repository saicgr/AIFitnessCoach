import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/widgets/skeleton/skeleton.dart';
import '../../data/models/achievement.dart';
import '../../data/repositories/achievements_repository.dart';
import '../../data/services/api_client.dart';
import '../../widgets/lottie_animations.dart';
import '../../widgets/design_system/zealova.dart';
import '../../core/services/posthog_service.dart';

import '../../l10n/generated/app_localizations.dart';
class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(posthogServiceProvider).capture(eventName: 'achievements_viewed');
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final userId = await ref.read(apiClientProvider).getUserId();
    if (userId != null) {
      ref.read(achievementsProvider.notifier).loadSummary(userId);
      ref.read(achievementsProvider.notifier).loadAchievements(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(achievementsProvider);
    final c = ThemeColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: c.background,
      appBar: ZealovaAppBar(
        title: AppLocalizations.of(context).youAchievements,
        kicker: 'Trophies & PRs',
      ),
      body: Column(
        children: [
          // Signature text tabs — Summary / Badges / PRs
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: AnimatedBuilder(
                animation: _tabController,
                builder: (_, __) => ZealovaTextTabs(
                  tabs: [
                    AppLocalizations.of(context).workoutCompleteSummary,
                    AppLocalizations.of(context).badgeHubBadges,
                    AppLocalizations.of(context).weeklyWrappedPrs,
                  ],
                  activeIndex: _tabController.index,
                  onChanged: (i) => _tabController.animateTo(i),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          const ZealovaRule(margin: EdgeInsets.symmetric(horizontal: 20)),
          Expanded(
            // Cache-first: a warm start has `hasLoaded == true` (the notifier
            // emitted a disk-cached summary/badge list before any network I/O)
            // so content renders instantly. The layout-matched skeleton is
            // shown ONLY on a genuine first-ever open while the first fetch
            // is still in flight — never a blocking full-screen spinner.
            child: (!state.hasLoaded && state.isLoading)
                ? const _AchievementsSkeleton()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _SummaryTab(summary: state.summary, isDark: isDark),
                      _BadgesTab(achievements: state.achievements, isDark: isDark),
                      _PersonalRecordsTab(
                        records: state.summary?.personalRecords ?? [],
                        isDark: isDark,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// First-open skeleton — layout-matched to the Summary tab so the
// skeleton → content cross-fade does not reflow.
// ─────────────────────────────────────────────────────────────────

class _AchievementsSkeleton extends StatelessWidget {
  const _AchievementsSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      // Disable scroll — a placeholder should not move under the user.
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          // Points hero placeholder (matches the compact _PointsCard header).
          SkeletonBox(height: 72, radius: 16),
          SizedBox(height: 24),
          // Section header line.
          SkeletonBox(width: 140, height: 12, radius: 6),
          SizedBox(height: 12),
          // Stacked achievement-row placeholders (matches _AchievementCard).
          SkeletonList(itemCount: 4, spacing: 12),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Summary Tab
// ─────────────────────────────────────────────────────────────────

class _SummaryTab extends StatelessWidget {
  final AchievementsSummary? summary;
  final bool isDark;

  const _SummaryTab({this.summary, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (summary == null) {
      return _EmptyState(
        icon: Icons.emoji_events,
        title: AppLocalizations.of(context).overviewNoAchievementsYet,
        subtitle: AppLocalizations.of(context).achievementsCompleteWorkoutsToEarn,
        isDark: isDark,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Points card
          _PointsCard(
            totalPoints: summary!.totalPoints,
            totalAchievements: summary!.totalAchievements,
            isDark: isDark,
          ).animate().fadeIn().slideY(begin: 0.1),

          const SizedBox(height: 24),

          // Streaks
          if (summary!.currentStreaks.isNotEmpty) ...[
            _SectionHeader(title: AppLocalizations.of(context).achievementsCurrentStreaks, isDark: isDark),
            const SizedBox(height: 12),
            ...summary!.currentStreaks.map((streak) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _StreakCard(streak: streak, isDark: isDark),
              );
            }),
            const SizedBox(height: 24),
          ],

          // Recent achievements
          if (summary!.recentAchievements.isNotEmpty) ...[
            _SectionHeader(title: AppLocalizations.of(context).achievementsRecentAchievements, isDark: isDark),
            const SizedBox(height: 12),
            ...summary!.recentAchievements.asMap().entries.map((entry) {
              return _AchievementCard(achievement: entry.value, isDark: isDark)
                  .animate()
                  .fadeIn(delay: (100 * entry.key).ms);
            }),
          ],

          // Categories
          if (summary!.achievementsByCategory.isNotEmpty) ...[
            const SizedBox(height: 24),
            _SectionHeader(title: AppLocalizations.of(context).achievementsByCategory, isDark: isDark),
            const SizedBox(height: 12),
            _CategoriesGrid(
                categories: summary!.achievementsByCategory, isDark: isDark),
          ],

          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Badges Tab
// ─────────────────────────────────────────────────────────────────

class _BadgesTab extends StatelessWidget {
  final List<UserAchievement> achievements;
  final bool isDark;

  const _BadgesTab({required this.achievements, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (achievements.isEmpty) {
      return _EmptyState(
        icon: Icons.military_tech,
        title: AppLocalizations.of(context).achievementsNoBadgesEarned,
        subtitle: AppLocalizations.of(context).achievementsKeepWorkingOutTo,
        isDark: isDark,
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        return _BadgeTile(achievement: achievement, isDark: isDark)
            .animate()
            .fadeIn(delay: (50 * index).ms)
            .scale(delay: (50 * index).ms);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Personal Records Tab
// ─────────────────────────────────────────────────────────────────

class _PersonalRecordsTab extends StatelessWidget {
  final List<PersonalRecord> records;
  final bool isDark;

  const _PersonalRecordsTab({required this.records, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return _EmptyState(
        icon: Icons.trending_up,
        title: AppLocalizations.of(context).achievementsNoPersonalRecords,
        subtitle: AppLocalizations.of(context).achievementsLiftHeavierToSet,
        isDark: isDark,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _PRCard(record: record, isDark: isDark)
              .animate()
              .fadeIn(delay: (50 * index).ms)
              .slideX(begin: 0.1, delay: (50 * index).ms),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Supporting Widgets
// ─────────────────────────────────────────────────────────────────

class _PointsCard extends StatelessWidget {
  final int totalPoints;
  final int totalAchievements;
  final bool isDark;

  const _PointsCard({
    required this.totalPoints,
    required this.totalAchievements,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Gold rarity-ring trophy badge (radial glow, no solid fill)
            Container(
              width: 60,
              height: 60,
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
              child: LottieAchievement(
                size: 40,
                color: AppColors.gamGold,
              ),
            ),
            const SizedBox(width: 16),
            // Anton hero points numeral + Barlow label
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$totalPoints',
                    style: ZType.disp(46, color: c.textPrimary, height: 0.9),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context).achievementsTotalPoints.toUpperCase(),
                    style: ZType.lbl(10, color: c.textMuted, letterSpacing: 2),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '$totalAchievements Achievements Earned'.toUpperCase(),
          style: ZType.lbl(9.5, color: AppColors.gamGold, letterSpacing: 1.5),
        ),
      ],
    );
  }
}

class _StreakCard extends StatelessWidget {
  final UserStreak streak;
  final bool isDark;

  const _StreakCard({required this.streak, required this.isDark});

  IconData get _icon {
    switch (streak.streakType) {
      case 'workout':
        return Icons.fitness_center;
      case 'hydration':
        return Icons.water_drop;
      case 'protein':
        return Icons.restaurant;
      case 'sleep':
        return Icons.bedtime;
      default:
        return Icons.local_fire_department;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.hairline)),
      ),
      child: Row(
        children: [
          // Framed glyph — hairline, gold streak accent
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.surface,
              border: Border.all(color: c.cardBorder),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(_icon, color: AppColors.gamGold, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatStreakType(streak.streakType),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Best: ${streak.longestStreak} days'.toUpperCase(),
                  style: ZType.lbl(9, color: c.textMuted, letterSpacing: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Current streak — gold flame + Anton numeral
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.local_fire_department,
                color: AppColors.gamGold,
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                '${streak.currentStreak}',
                style: ZType.disp(22, color: AppColors.gamGold, height: 0.9),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatStreakType(String type) {
    return type.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }
}

class _AchievementCard extends StatelessWidget {
  final UserAchievement achievement;
  final bool isDark;

  const _AchievementCard({required this.achievement, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final type = achievement.achievement;
    if (type == null) return const SizedBox.shrink();

    final c = ThemeColors.of(context);
    final metal = _tierColor(type.tier);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.hairline)),
      ),
      child: Row(
        children: [
          // Emblem with rarity radial glow
          SizedBox(
            width: 40,
            height: 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [metal.withValues(alpha: 0.26), Colors.transparent],
                      stops: const [0.0, 0.7],
                    ),
                  ),
                ),
                Text(type.icon, style: const TextStyle(fontSize: 22)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  type.description.toUpperCase(),
                  style: ZType.lbl(9, color: c.textMuted, letterSpacing: 1.2),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '+${type.points}',
            style: ZType.lbl(12, color: metal, weight: FontWeight.w800, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }
}

/// Maps an achievement rarity tier to its Signature metal accent.
Color _tierColor(String tier) {
  switch (tier.toLowerCase()) {
    case 'bronze':
      return AppColors.rarityBronze;
    case 'silver':
      return AppColors.raritySilver;
    case 'gold':
      return AppColors.rarityGold;
    case 'platinum':
      return AppColors.rarityPlatinum;
    default:
      return AppColors.gamGold;
  }
}

class _BadgeTile extends StatelessWidget {
  final UserAchievement achievement;
  final bool isDark;

  const _BadgeTile({required this.achievement, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final type = achievement.achievement;
    if (type == null) return const SizedBox.shrink();

    final c = ThemeColors.of(context);
    final metal = _tierColor(type.tier);

    // Rarity tile — hairline top rule, radial-glow emblem, metal rarity chip
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 11, 4, 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.hairline)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [metal.withValues(alpha: 0.3), Colors.transparent],
                      stops: const [0.0, 0.7],
                    ),
                  ),
                ),
                Text(type.icon, style: const TextStyle(fontSize: 26)),
              ],
            ),
          ),
          const SizedBox(height: 7),
          // Flexible: on narrow grids (320-360dp → ~103px cells) the 2-line
          // name is what must yield — it drops to 1 line instead of striping
          // the cell bottom.
          Flexible(
            child: Text(
              type.name,
              style: TextStyle(
                fontSize: 11,
                height: 1.15,
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              border: Border.all(color: metal.withValues(alpha: 0.4)),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              type.tier.toUpperCase(),
              style: ZType.lbl(8, color: metal, weight: FontWeight.w800, letterSpacing: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _PRCard extends StatelessWidget {
  final PersonalRecord record;
  final bool isDark;

  const _PRCard({required this.record, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    final success = isDark ? AppColors.success : AppColorsLight.success;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.hairline)),
      ),
      child: Row(
        children: [
          // Framed glyph — hairline, gold PR accent
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.surface,
              border: Border.all(color: c.cardBorder),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.trending_up,
              color: AppColors.gamGold,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.exerciseName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _formatDate(record.achievedAt).toUpperCase(),
                  style: ZType.lbl(9, color: c.textMuted, letterSpacing: 1.2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${record.recordValue.toStringAsFixed(1)} ${record.recordUnit}',
                style: ZType.data(15, color: AppColors.gamGold),
              ),
              if (record.improvementPercentage != null) ...[
                const SizedBox(height: 2),
                Text(
                  '+${record.improvementPercentage!.toStringAsFixed(1)}%',
                  style: ZType.lbl(9.5, color: success, letterSpacing: 0.5),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _CategoriesGrid extends StatelessWidget {
  final Map<String, int> categories;
  final bool isDark;

  const _CategoriesGrid({required this.categories, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.entries.map((entry) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: c.surface,
            border: Border.all(color: c.cardBorder),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getCategoryIcon(entry.key),
                size: 14,
                color: c.textMuted,
              ),
              const SizedBox(width: 7),
              Text(
                _formatCategory(entry.key).toUpperCase(),
                style: ZType.lbl(10, color: c.textSecondary, letterSpacing: 1.3),
              ),
              const SizedBox(width: 6),
              Text(
                '${entry.value}',
                style: ZType.data(10, color: AppColors.gamGold),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'strength':
        return Icons.fitness_center;
      case 'consistency':
        return Icons.calendar_today;
      case 'weight':
        return Icons.monitor_weight;
      case 'cardio':
        return Icons.directions_run;
      case 'habit':
        return Icons.repeat;
      default:
        return Icons.star;
    }
  }

  String _formatCategory(String category) {
    return category.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    return Text(
      title.toUpperCase(),
      style: ZType.lbl(11, color: c.textMuted, letterSpacing: 2),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LottieEmpty(size: 120, color: c.textMuted),
            const SizedBox(height: 16),
            Text(
              title.toUpperCase(),
              style: ZType.disp(18, color: c.textPrimary, height: 0.98),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: c.textMuted,
                height: 1.35,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
