import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/theme_colors.dart';
import '../data/models/home_layout.dart';
import '../data/models/user_xp.dart';
import '../data/providers/xp_provider.dart';
import '../data/services/haptic_service.dart';
import 'xp_goals_sheet.dart';

/// XP and Level progress card for home screen
/// Shows current level, XP progress bar, and title
class XPProgressCard extends ConsumerWidget {
  final TileSize size;
  final bool isDark;

  const XPProgressCard({
    super.key,
    this.size = TileSize.full,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final accentColor = ref.colors(context).accent;

    final xpState = ref.watch(xpProvider);
    final userXp = xpState.userXp;
    final isLoading = xpState.isLoading;

    if (size == TileSize.compact) {
      return _buildCompactLayout(
        context,
        ref,
        userXp: userXp,
        isLoading: isLoading,
        elevatedColor: elevatedColor,
        textColor: textColor,
        textMuted: textMuted,
        cardBorder: cardBorder,
        accentColor: accentColor,
      );
    }

    return InkWell(
      onTap: () {
        HapticService.light();
        // Open XP Goals Sheet instead of Trophy Room
        showXPGoalsSheet(context, ref);
      },
      onLongPress: () {
        HapticService.medium();
        // Long press to go to Trophy Room
        context.push('/trophy-room');
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
            : userXp == null
                ? _buildEmptyState(textMuted, accentColor)
                : _buildContentState(
                    context,
                    ref,
                    userXp: userXp,
                    textColor: textColor,
                    textMuted: textMuted,
                    accentColor: accentColor,
                  ),
      ),
    );
  }

  Widget _buildCompactLayout(
    BuildContext context,
    WidgetRef ref, {
    required UserXP? userXp,
    required bool isLoading,
    required Color elevatedColor,
    required Color textColor,
    required Color textMuted,
    required Color cardBorder,
    required Color accentColor,
  }) {
    return InkWell(
      onTap: () {
        HapticService.light();
        // Open XP Goals Sheet
        showXPGoalsSheet(context, ref);
      },
      onLongPress: () {
        HapticService.medium();
        // Long press to go to Trophy Room
        context.push('/trophy-room');
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
            _buildLevelBadge(
              userXp?.currentLevel ?? 1,
              userXp?.xpTitle ?? XPTitle.novice,
              size: 24,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isLoading ? '...' : 'Lvl ${userXp?.currentLevel ?? 1}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Text(
                  userXp?.title ?? 'Novice',
                  style: TextStyle(
                    fontSize: 10,
                    color: textMuted,
                  ),
                ),
              ],
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
          'Loading XP...',
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
            _buildLevelBadge(1, XPTitle.novice),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Level 1 • Novice',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Start your fitness journey!',
                    style: TextStyle(
                      fontSize: 12,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContentState(
    BuildContext context,
    WidgetRef ref, {
    required UserXP userXp,
    required Color textColor,
    required Color textMuted,
    required Color accentColor,
  }) {
    final xpTitle = userXp.xpTitle;
    final progressFraction = userXp.progressFraction;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header with level badge and info
        Row(
          children: [
            _buildLevelBadge(userXp.currentLevel, xpTitle),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Level ${userXp.currentLevel}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Color(xpTitle.colorValue).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Color(xpTitle.colorValue).withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          xpTitle.displayName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(xpTitle.colorValue),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${userXp.formattedTotalXp} XP Total',
                    style: TextStyle(
                      fontSize: 12,
                      color: textMuted,
                    ),
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

        const SizedBox(height: 16),

        // XP Progress bar
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Next Level',
                  style: TextStyle(
                    fontSize: 12,
                    color: textMuted,
                  ),
                ),
                Text(
                  userXp.formattedProgress,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Animated progress bar
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progressFraction),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return Stack(
                  children: [
                    // Background
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: textMuted.withValues(alpha: 0.2),
                      ),
                    ),
                    // Progress with gradient
                    FractionallySizedBox(
                      widthFactor: value.clamp(0.0, 1.0),
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          gradient: LinearGradient(
                            colors: [
                              Color(xpTitle.colorValue),
                              Color(xpTitle.colorValue).withValues(alpha: 0.7),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(xpTitle.colorValue).withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 4),
            Text(
              '${userXp.progressPercent}% to Level ${userXp.currentLevel + 1}',
              style: TextStyle(
                fontSize: 10,
                color: textMuted,
              ),
            ),
          ],
        ),

        // Prestige indicator (if applicable)
        if (userXp.prestigeLevel > 0) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFE040FB),
                  Color(0xFF7C4DFF),
                  Color(0xFF00BCD4),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.auto_awesome,
                  size: 14,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  'Prestige ${userXp.prestigeLevel}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],

        // Goals Preview Row
        const SizedBox(height: 12),
        _GoalsPreviewRow(
          textColor: textColor,
          textMuted: textMuted,
          accentColor: accentColor,
        ),
      ],
    );
  }

  /// Build level badge with title-appropriate styling
  Widget _buildLevelBadge(int level, XPTitle title, {double size = 48}) {
    final color = Color(title.colorValue);
    final isPrestige = title == XPTitle.mythic;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isPrestige
            ? const LinearGradient(
                colors: [
                  Color(0xFFE040FB),
                  Color(0xFF7C4DFF),
                  Color(0xFF00BCD4),
                  Color(0xFFE040FB),
                ],
                stops: [0.0, 0.33, 0.66, 1.0],
              )
            : LinearGradient(
                colors: [
                  color,
                  color.withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          level.toString(),
          style: TextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Minimal XP bar for inline display (e.g., in header)
class XPProgressBar extends ConsumerWidget {
  final double height;
  final bool showLabel;

  const XPProgressBar({
    super.key,
    this.height = 6,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final xpState = ref.watch(xpProvider);
    final userXp = xpState.userXp;

    if (userXp == null) {
      return const SizedBox.shrink();
    }

    final xpTitle = userXp.xpTitle;
    final color = Color(xpTitle.colorValue);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabel)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Lvl ${userXp.currentLevel} ${xpTitle.displayName}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                Text(
                  '${userXp.progressPercent}%',
                  style: TextStyle(
                    fontSize: 10,
                    color: color.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: userXp.progressFraction),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return Container(
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(height / 2),
                color: color.withValues(alpha: 0.2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: value.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(height / 2),
                    color: color,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Level badge widget for use anywhere
class LevelBadge extends StatelessWidget {
  final int level;
  final String title;
  final double size;

  const LevelBadge({
    super.key,
    required this.level,
    required this.title,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    final xpTitle = _getXPTitle(level);
    final color = Color(xpTitle.colorValue);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          level.toString(),
          style: TextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  XPTitle _getXPTitle(int level) {
    if (level <= 10) return XPTitle.novice;
    if (level <= 25) return XPTitle.apprentice;
    if (level <= 50) return XPTitle.athlete;
    if (level <= 75) return XPTitle.elite;
    if (level <= 99) return XPTitle.master;
    if (level == 100) return XPTitle.legend;
    return XPTitle.mythic;
  }
}

/// Goals preview row showing daily/weekly progress
class _GoalsPreviewRow extends ConsumerWidget {
  final Color textColor;
  final Color textMuted;
  final Color accentColor;

  const _GoalsPreviewRow({
    required this.textColor,
    required this.textMuted,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasLoggedInToday = ref.watch(hasLoggedInTodayProvider);
    final weeklyProgress = ref.watch(weeklyCheckpointsProvider);
    final hasDoubleXP = ref.watch(hasDoubleXPProvider);
    final currentStreak = ref.watch(xpCurrentStreakProvider);

    // Calculate daily goals (1/4 if logged in, 0/4 if not)
    final dailyCompleted = hasLoggedInToday ? 1 : 0;
    const dailyTotal = 4;

    // Weekly checkpoints progress
    final weeklyCompleted = weeklyProgress?.earnedCount ?? 0;
    final weeklyTotal = weeklyProgress?.totalCheckpoints ?? 8;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: textMuted.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Daily goals
          Expanded(
            child: _buildGoalItem(
              icon: Icons.today,
              label: 'Daily',
              value: '$dailyCompleted/$dailyTotal',
              color: accentColor,
              progress: dailyCompleted / dailyTotal,
            ),
          ),

          // Divider
          Container(
            width: 1,
            height: 32,
            color: textMuted.withValues(alpha: 0.2),
          ),

          // Weekly goals
          Expanded(
            child: _buildGoalItem(
              icon: Icons.date_range,
              label: 'Weekly',
              value: '$weeklyCompleted/$weeklyTotal',
              color: AppColors.orange,
              progress: weeklyTotal > 0 ? weeklyCompleted / weeklyTotal : 0,
            ),
          ),

          // Divider
          Container(
            width: 1,
            height: 32,
            color: textMuted.withValues(alpha: 0.2),
          ),

          // Streak
          Expanded(
            child: _buildStreakItem(
              streak: currentStreak,
              hasDoubleXP: hasDoubleXP,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required double progress,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 4),
        // Mini progress bar
        SizedBox(
          width: 50,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 3,
              backgroundColor: textMuted.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStreakItem({
    required int streak,
    required bool hasDoubleXP,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_fire_department,
              size: 14,
              color: streak > 0 ? Colors.orange : textMuted,
            ),
            const SizedBox(width: 4),
            Text(
              'Streak',
              style: TextStyle(
                fontSize: 10,
                color: textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              streak > 0 ? '$streak' : '-',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: streak > 0 ? textColor : textMuted,
              ),
            ),
            if (hasDoubleXP) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt, size: 10, color: Colors.amber),
                    Text(
                      '2x',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          streak > 0 ? 'days' : 'none',
          style: TextStyle(
            fontSize: 9,
            color: textMuted,
          ),
        ),
      ],
    );
  }
}
