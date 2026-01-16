import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/repositories/achievements_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/haptic_service.dart';

/// Achievements section for home screen
/// Shows recent achievements and total points
class AchievementsSection extends ConsumerStatefulWidget {
  const AchievementsSection({super.key});

  @override
  ConsumerState<AchievementsSection> createState() => _AchievementsSectionState();
}

class _AchievementsSectionState extends ConsumerState<AchievementsSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAchievements();
    });
  }

  void _loadAchievements() {
    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;
    if (userId != null) {
      ref.read(achievementsProvider.notifier).loadSummary(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final accentColorEnum = ref.watch(accentColorProvider);
    final accentColor = accentColorEnum.getColor(isDark);

    final achievementsState = ref.watch(achievementsProvider);
    final summary = achievementsState.summary;
    final totalPoints = summary?.totalPoints ?? 0;
    final totalAchievements = summary?.totalAchievements ?? 0;
    final recentAchievements = summary?.recentAchievements ?? [];

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header with "See All" button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Achievements',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    HapticService.light();
                    context.push('/achievements');
                  },
                  child: Text(
                    'See All',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Stats summary row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorder),
              ),
              child: Row(
                children: [
                  // Total Points
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.stars_rounded,
                      value: '$totalPoints',
                      label: 'Total Points',
                      accentColor: accentColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ),
                  Container(
                    height: 40,
                    width: 1,
                    color: cardBorder,
                  ),
                  // Total Achievements
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.emoji_events_rounded,
                      value: '$totalAchievements',
                      label: 'Unlocked',
                      accentColor: accentColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Recent achievements
          if (recentAchievements.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: recentAchievements.length.clamp(0, 5),
                itemBuilder: (context, index) {
                  final achievement = recentAchievements[index];
                  return Padding(
                    padding: EdgeInsets.only(right: index < recentAchievements.length - 1 ? 8 : 0),
                    child: _buildAchievementBadge(
                      name: achievement.achievement?.name ?? 'Achievement',
                      icon: _getAchievementIcon(achievement.achievement?.icon),
                      tier: achievement.achievement?.tier ?? 'bronze',
                      accentColor: accentColor,
                      cardBg: cardBg,
                      cardBorder: cardBorder,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  );
                },
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cardBorder),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.emoji_events_outlined,
                      size: 24,
                      color: textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Complete workouts to earn achievements!',
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color accentColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: accentColor),
            const SizedBox(width: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementBadge({
    required String name,
    required IconData icon,
    required String tier,
    required Color accentColor,
    required Color cardBg,
    required Color cardBorder,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final tierColor = _getTierColor(tier, accentColor);

    return Container(
      width: 72,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tierColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: tierColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 20,
              color: tierColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Color _getTierColor(String tier, Color accentColor) {
    switch (tier.toLowerCase()) {
      case 'gold':
        return const Color(0xFFFFD700);
      case 'silver':
        return const Color(0xFFC0C0C0);
      case 'bronze':
        return const Color(0xFFCD7F32);
      case 'platinum':
        return const Color(0xFFE5E4E2);
      default:
        return accentColor;
    }
  }

  IconData _getAchievementIcon(String? iconName) {
    switch (iconName?.toLowerCase()) {
      case 'trophy':
        return Icons.emoji_events_rounded;
      case 'fire':
        return Icons.local_fire_department;
      case 'star':
        return Icons.star_rounded;
      case 'medal':
        return Icons.military_tech;
      case 'fitness':
        return Icons.fitness_center;
      case 'heart':
        return Icons.favorite;
      case 'lightning':
        return Icons.bolt;
      case 'target':
        return Icons.gps_fixed;
      case 'crown':
        return Icons.workspace_premium;
      default:
        return Icons.emoji_events_rounded;
    }
  }
}
