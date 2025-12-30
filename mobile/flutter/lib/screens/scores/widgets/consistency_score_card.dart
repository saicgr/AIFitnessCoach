import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/scores.dart';

/// Card showing workout consistency score and stats.
class ConsistencyScoreCard extends StatelessWidget {
  final int consistencyScore;
  final ScoresOverview? overview;
  final bool isDark;
  final int? weeklyCompleted;
  final int? weeklyTotal;
  final int? currentStreak;

  const ConsistencyScoreCard({
    super.key,
    required this.consistencyScore,
    required this.overview,
    required this.isDark,
    this.weeklyCompleted,
    this.weeklyTotal,
    this.currentStreak,
  });

  @override
  Widget build(BuildContext context) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final scoreColor = _getScoreColor(consistencyScore);

    // Use passed values or calculate from consistency percentage
    final weeklyCompletedValue = weeklyCompleted ?? (consistencyScore * 7 / 100).round();
    final weeklyTotalValue = weeklyTotal ?? 7;
    final currentStreakValue = currentStreak ?? 0;
    final prCount = overview?.prCount30Days ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scoreColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.trending_up,
                color: scoreColor,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Consistency Score',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    Text(
                      'Workout completion rate',
                      style: TextStyle(
                        fontSize: 11,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$consistencyScore%',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: scoreColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: consistencyScore / 100,
              backgroundColor: scoreColor.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 20),
          // Stats row
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  icon: Icons.check_circle_outline,
                  label: 'This Week',
                  value: '$weeklyCompletedValue/$weeklyTotalValue',
                  isDark: isDark,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: textMuted.withOpacity(0.2),
              ),
              Expanded(
                child: _StatItem(
                  icon: Icons.local_fire_department,
                  label: 'Streak',
                  value: '$currentStreakValue days',
                  isDark: isDark,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: textMuted.withOpacity(0.2),
              ),
              Expanded(
                child: _StatItem(
                  icon: Icons.emoji_events,
                  label: 'PRs (30d)',
                  value: '$prCount',
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Tip
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scoreColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: scoreColor,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _getTip(),
                    style: TextStyle(
                      fontSize: 12,
                      color: textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTip() {
    if (consistencyScore >= 90) {
      return 'Amazing consistency! You\'re building great habits.';
    } else if (consistencyScore >= 70) {
      return 'Great work! Keep showing up and you\'ll see results.';
    } else if (consistencyScore >= 50) {
      return 'You\'re on the right track. Try to complete one more workout this week!';
    } else {
      return 'Consistency is key. Start with 2-3 workouts per week.';
    }
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return AppColors.green;
    if (score >= 60) return AppColors.cyan;
    if (score >= 40) return AppColors.yellow;
    return Colors.orange;
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Column(
      children: [
        Icon(
          icon,
          color: textMuted,
          size: 18,
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: textMuted,
          ),
        ),
      ],
    );
  }
}
