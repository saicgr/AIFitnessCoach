import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/mood.dart';

/// Card showing mood check-in streaks
class MoodStreakCard extends StatelessWidget {
  final MoodStreaks streaks;

  const MoodStreakCard({
    super.key,
    required this.streaks,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surface : AppColorsLight.surface;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Current streak
          Expanded(
            child: _buildStreakItem(
              icon: Icons.local_fire_department,
              iconColor: streaks.currentStreak > 0 ? Colors.orange : textSecondary,
              value: streaks.currentStreak.toString(),
              label: 'Current Streak',
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              isHighlighted: streaks.currentStreak > 0,
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color: textSecondary.withValues(alpha: 0.2),
          ),
          // Longest streak
          Expanded(
            child: _buildStreakItem(
              icon: Icons.emoji_events,
              iconColor: streaks.longestStreak > 0 ? Colors.amber : textSecondary,
              value: streaks.longestStreak.toString(),
              label: 'Best Streak',
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              isHighlighted: streaks.longestStreak > 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakItem({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    required Color textPrimary,
    required Color textSecondary,
    bool isHighlighted = false,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 28,
          color: iconColor,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isHighlighted ? iconColor : textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'days',
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
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
}
