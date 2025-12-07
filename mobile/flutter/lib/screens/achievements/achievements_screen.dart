import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/achievement.dart';
import '../../data/repositories/achievements_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/api_client.dart';

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

    return Scaffold(
      backgroundColor: AppColors.pureBlack,
      appBar: AppBar(
        backgroundColor: AppColors.pureBlack,
        title: const Text('Achievements'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.cyan,
          labelColor: AppColors.cyan,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(text: 'Summary'),
            Tab(text: 'Badges'),
            Tab(text: 'PRs'),
          ],
        ),
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.cyan),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _SummaryTab(summary: state.summary),
                _BadgesTab(achievements: state.achievements),
                _PersonalRecordsTab(
                  records: state.summary?.personalRecords ?? [],
                ),
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

  const _SummaryTab({this.summary});

  @override
  Widget build(BuildContext context) {
    if (summary == null) {
      return _EmptyState(
        icon: Icons.emoji_events,
        title: 'No achievements yet',
        subtitle: 'Complete workouts to earn achievements!',
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
          ).animate().fadeIn().slideY(begin: 0.1),

          const SizedBox(height: 24),

          // Streaks
          if (summary!.currentStreaks.isNotEmpty) ...[
            _SectionHeader(title: 'CURRENT STREAKS'),
            const SizedBox(height: 12),
            ...summary!.currentStreaks.map((streak) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _StreakCard(streak: streak),
              );
            }).toList(),
            const SizedBox(height: 24),
          ],

          // Recent achievements
          if (summary!.recentAchievements.isNotEmpty) ...[
            _SectionHeader(title: 'RECENT ACHIEVEMENTS'),
            const SizedBox(height: 12),
            ...summary!.recentAchievements.asMap().entries.map((entry) {
              return _AchievementCard(achievement: entry.value)
                  .animate()
                  .fadeIn(delay: (100 * entry.key).ms);
            }).toList(),
          ],

          // Categories
          if (summary!.achievementsByCategory.isNotEmpty) ...[
            const SizedBox(height: 24),
            _SectionHeader(title: 'BY CATEGORY'),
            const SizedBox(height: 12),
            _CategoriesGrid(categories: summary!.achievementsByCategory),
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

  const _BadgesTab({required this.achievements});

  @override
  Widget build(BuildContext context) {
    if (achievements.isEmpty) {
      return _EmptyState(
        icon: Icons.military_tech,
        title: 'No badges earned',
        subtitle: 'Keep working out to unlock badges!',
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
        return _BadgeTile(achievement: achievement)
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

  const _PersonalRecordsTab({required this.records});

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return _EmptyState(
        icon: Icons.trending_up,
        title: 'No personal records',
        subtitle: 'Lift heavier to set new PRs!',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _PRCard(record: record)
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

  const _PointsCard({
    required this.totalPoints,
    required this.totalAchievements,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.purple.withOpacity(0.3),
            AppColors.cyan.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cyan.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.emoji_events,
            size: 48,
            color: AppColors.orange,
          ),
          const SizedBox(height: 12),
          Text(
            '$totalPoints',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const Text(
            'Total Points',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.glassSurface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$totalAchievements Achievements Earned',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final UserStreak streak;

  const _StreakCard({required this.streak});

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

  Color get _color {
    switch (streak.streakType) {
      case 'workout':
        return AppColors.cyan;
      case 'hydration':
        return AppColors.electricBlue;
      case 'protein':
        return AppColors.purple;
      case 'sleep':
        return AppColors.magenta;
      default:
        return AppColors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.elevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_icon, color: _color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatStreakType(streak.streakType),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Best: ${streak.longestStreak} days',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    color: AppColors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${streak.currentStreak}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.orange,
                    ),
                  ),
                ],
              ),
              const Text(
                'days',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
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

  const _AchievementCard({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final type = achievement.achievement;
    if (type == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getTierColor(type.tier).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getTierColor(type.tier).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                type.icon,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  type.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _getTierColor(type.tier).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '+${type.points}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _getTierColor(type.tier),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'bronze':
        return const Color(0xFFCD7F32);
      case 'silver':
        return const Color(0xFFC0C0C0);
      case 'gold':
        return AppColors.orange;
      case 'platinum':
        return AppColors.cyan;
      default:
        return AppColors.textSecondary;
    }
  }
}

class _BadgeTile extends StatelessWidget {
  final UserAchievement achievement;

  const _BadgeTile({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final type = achievement.achievement;
    if (type == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getTierColor(type.tier).withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  _getTierColor(type.tier).withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                type.icon,
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            type.name,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _getTierColor(type.tier).withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              type.tier.toUpperCase(),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: _getTierColor(type.tier),
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'bronze':
        return const Color(0xFFCD7F32);
      case 'silver':
        return const Color(0xFFC0C0C0);
      case 'gold':
        return AppColors.orange;
      case 'platinum':
        return AppColors.cyan;
      default:
        return AppColors.textSecondary;
    }
  }
}

class _PRCard extends StatelessWidget {
  final PersonalRecord record;

  const _PRCard({required this.record});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.trending_up,
              color: AppColors.orange,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.exerciseName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  _formatDate(record.achievedAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${record.recordValue.toStringAsFixed(1)} ${record.recordUnit}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.orange,
                ),
              ),
              if (record.improvementPercentage != null)
                Text(
                  '+${record.improvementPercentage!.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _CategoriesGrid extends StatelessWidget {
  final Map<String, int> categories;

  const _CategoriesGrid({required this.categories});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: categories.entries.map((entry) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.elevated,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getCategoryIcon(entry.key),
                size: 18,
                color: _getCategoryColor(entry.key),
              ),
              const SizedBox(width: 8),
              Text(
                '${_formatCategory(entry.key)}: ${entry.value}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
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

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'strength':
        return AppColors.purple;
      case 'consistency':
        return AppColors.cyan;
      case 'weight':
        return AppColors.orange;
      case 'cardio':
        return AppColors.coral;
      case 'habit':
        return AppColors.teal;
      default:
        return AppColors.textSecondary;
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

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
        letterSpacing: 1.5,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
