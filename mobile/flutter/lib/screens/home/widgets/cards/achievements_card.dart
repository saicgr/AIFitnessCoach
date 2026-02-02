import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../data/models/home_layout.dart';
import '../../../../data/models/milestone.dart';
import '../../../../data/providers/milestones_provider.dart';
import '../../../../data/services/haptic_service.dart';

/// Achievements Tile - Shows recent achievement and next milestone
/// Displays last earned badge with progress to next one
class AchievementsCard extends ConsumerWidget {
  final TileSize size;
  final bool isDark;

  const AchievementsCard({
    super.key,
    this.size = TileSize.half,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final accentColor = ref.colors(context).accent;

    final milestonesState = ref.watch(milestonesProvider);
    final achieved = milestonesState.achieved;
    final nextMilestone = milestonesState.nextMilestone;
    final isLoading = milestonesState.isLoading;
    final totalPoints = milestonesState.totalPoints;

    // Get most recent achievement
    final recentAchievement = achieved.isNotEmpty ? achieved.first : null;

    // Build the appropriate layout based on size
    if (size == TileSize.compact) {
      return _buildCompactLayout(
        context,
        ref,
        elevatedColor: elevatedColor,
        textColor: textColor,
        textMuted: textMuted,
        cardBorder: cardBorder,
        totalAchieved: achieved.length,
        totalPoints: totalPoints,
        isLoading: isLoading,
      );
    }

    return InkWell(
      onTap: () {
        HapticService.light();
        context.push('/stats');
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: size == TileSize.full
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 4)
            : null,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder),
        ),
        child: isLoading
            ? _buildLoadingState(textMuted)
            : achieved.isEmpty && nextMilestone == null
                ? _buildEmptyState(textMuted, accentColor)
                : _buildContentState(
                    textColor: textColor,
                    textMuted: textMuted,
                    accentColor: accentColor,
                    recentAchievement: recentAchievement,
                    nextMilestone: nextMilestone,
                    totalPoints: totalPoints,
                  ),
      ),
    );
  }

  Widget _buildCompactLayout(
    BuildContext context,
    WidgetRef ref, {
    required Color elevatedColor,
    required Color textColor,
    required Color textMuted,
    required Color cardBorder,
    required int totalAchieved,
    required int totalPoints,
    required bool isLoading,
  }) {
    final accentColor = ref.colors(context).accent;
    return InkWell(
      onTap: () {
        HapticService.light();
        context.push('/stats');
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events,
              color: accentColor,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              isLoading ? '...' : '$totalAchieved badges',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(Color textMuted) {
    return Row(
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: textMuted,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Loading achievements...',
          style: TextStyle(
            fontSize: 14,
            color: textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(Color textMuted, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.emoji_events, color: accentColor, size: 20),
            const SizedBox(width: 8),
            Text(
              'Achievements',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Complete workouts to unlock badges!',
          style: TextStyle(
            fontSize: 14,
            color: textMuted,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Start your journey',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: accentColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContentState({
    required Color textColor,
    required Color textMuted,
    required Color accentColor,
    required MilestoneProgress? recentAchievement,
    required MilestoneProgress? nextMilestone,
    required int totalPoints,
  }) {
    // Use accent color for milestone tier colors
    Color getTierColor(MilestoneTier tier) {
      // Return accent color with varying opacity based on tier
      return accentColor;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(Icons.emoji_events, color: accentColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Achievements',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textMuted,
                    ),
                  ),
                  // Large points number with animation
                  TweenAnimationBuilder<int>(
                    tween: IntTween(begin: 0, end: totalPoints),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, animatedValue, _) {
                      return Text(
                        '$animatedValue pts',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                          height: 1.0,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: textMuted,
              size: 20,
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Recent achievement
        if (recentAchievement != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: getTierColor(recentAchievement.milestone.tier).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: getTierColor(recentAchievement.milestone.tier).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: getTierColor(recentAchievement.milestone.tier).withValues(alpha: 0.2),
                  ),
                  child: Icon(
                    _getMilestoneIcon(recentAchievement.milestone.icon),
                    color: getTierColor(recentAchievement.milestone.tier),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recentAchievement.milestone.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        recentAchievement.milestone.tier.displayName,
                        style: TextStyle(
                          fontSize: 11,
                          color: getTierColor(recentAchievement.milestone.tier),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.check_circle,
                  color: accentColor,
                  size: 20,
                ),
              ],
            ),
          ),
        ],

        // Next milestone (full size only)
        if (size == TileSize.full && nextMilestone != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.flag_outlined,
                size: 14,
                color: textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                'Next: ',
                style: TextStyle(
                  fontSize: 12,
                  color: textMuted,
                ),
              ),
              Expanded(
                child: Text(
                  nextMilestone.milestone.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: textMuted.withValues(alpha: 0.2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: nextMilestone.progressFraction.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: getTierColor(nextMilestone.milestone.tier),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(nextMilestone.progressPercentage ?? 0).round()}%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: textMuted,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  IconData _getMilestoneIcon(String? iconName) {
    switch (iconName) {
      case 'fitness_center':
        return Icons.fitness_center;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'emoji_events':
        return Icons.emoji_events;
      case 'speed':
        return Icons.speed;
      case 'schedule':
        return Icons.schedule;
      case 'monitor_weight':
        return Icons.monitor_weight;
      case 'military_tech':
        return Icons.military_tech;
      case 'stars':
        return Icons.stars;
      case 'flash_on':
        return Icons.flash_on;
      default:
        return Icons.emoji_events;
    }
  }
}
