import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/providers/milestones_provider.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/services/haptic_service.dart';

/// ROI Summary Card for home screen.
/// Shows "Your Fitness Journey" with key ROI metrics.
/// Taps to navigate to the full milestones screen.
class ROISummaryCard extends ConsumerStatefulWidget {
  const ROISummaryCard({super.key});

  @override
  ConsumerState<ROISummaryCard> createState() => _ROISummaryCardState();
}

class _ROISummaryCardState extends ConsumerState<ROISummaryCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;
    if (userId != null) {
      ref.read(milestonesProvider.notifier).loadROISummary(userId: userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(milestonesProvider);
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    // Show loading state if no data yet
    if (state.isLoading && state.roiSummary == null) {
      return _buildLoadingCard(isDark);
    }

    final roi = state.roiSummary;
    if (roi == null) {
      // No data yet, show empty state
      return _buildEmptyCard(isDark);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            HapticService.light();
            context.push('/progress/milestones');
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.purple.withOpacity(0.3),
              ),
              gradient: LinearGradient(
                colors: [
                  AppColors.purple.withOpacity(0.05),
                  Colors.transparent,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.purple.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.trending_up,
                        color: AppColors.purple,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            roi.headline,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          if (roi.motivationalMessage.isNotEmpty)
                            Text(
                              roi.motivationalMessage,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.purple,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: textMuted,
                      size: 24,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Stats row
                Row(
                  children: [
                    _StatItem(
                      icon: Icons.fitness_center,
                      value: '${roi.totalWorkouts}',
                      label: 'Workouts',
                      iconColor: AppColors.cyan,
                      isDark: isDark,
                    ),
                    _StatDivider(isDark: isDark),
                    _StatItem(
                      icon: Icons.schedule,
                      value: '${roi.totalHoursInvested.toStringAsFixed(1)}h',
                      label: 'Invested',
                      iconColor: AppColors.orange,
                      isDark: isDark,
                    ),
                    _StatDivider(isDark: isDark),
                    _StatItem(
                      icon: Icons.local_fire_department,
                      value: _formatCalories(roi.estimatedCaloriesBurned),
                      label: 'Calories',
                      iconColor: AppColors.coral,
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Secondary stats row
                Row(
                  children: [
                    if (roi.totalWeightLifted.isNotEmpty) ...[
                      _SmallStat(
                        icon: Icons.speed,
                        text: roi.totalWeightLifted,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 16),
                    ],
                    if (roi.prsCount > 0) ...[
                      _SmallStat(
                        icon: Icons.emoji_events,
                        text: '${roi.prsCount} PRs',
                        isDark: isDark,
                      ),
                      const SizedBox(width: 16),
                    ],
                    if (roi.currentStreak > 0)
                      _SmallStat(
                        icon: Icons.local_fire_department,
                        text: '${roi.currentStreak} day streak',
                        isDark: isDark,
                        highlighted: roi.currentStreak >= 7,
                      ),
                  ],
                ),
                // Strength increase badge
                if (roi.strengthIncreaseText.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.arrow_upward,
                          size: 14,
                          color: AppColors.green,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "You're ${roi.strengthIncreaseText} since you started!",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatCalories(int calories) {
    if (calories >= 1000) {
      return '${(calories / 1000).toStringAsFixed(1)}K';
    }
    return '$calories';
  }

  Widget _buildLoadingCard(bool isDark) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.purple.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.purple),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Loading your progress...',
                style: TextStyle(
                  fontSize: 13,
                  color: textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCard(bool isDark) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            HapticService.light();
            context.push('/progress/milestones');
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.purple.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.rocket_launch,
                    color: AppColors.purple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start Your Journey',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Complete your first workout to begin tracking your progress!',
                        style: TextStyle(
                          fontSize: 13,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Single stat item in the stats row
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;
  final bool isDark;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.iconColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            color: iconColor.withOpacity(0.8),
            size: 20,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Vertical divider between stats
class _StatDivider extends StatelessWidget {
  final bool isDark;

  const _StatDivider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: 1,
      color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
    );
  }
}

/// Small stat pill for secondary stats
class _SmallStat extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;
  final bool highlighted;

  const _SmallStat({
    required this.icon,
    required this.text,
    required this.isDark,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final glassSurface =
        isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;

    final color = highlighted ? AppColors.orange : textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.orange.withOpacity(0.1) : glassSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: highlighted ? FontWeight.w600 : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
