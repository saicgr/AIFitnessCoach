import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/skill_progression.dart';

/// Summary card showing user's overall skill progression stats
class SkillProgressSummaryCard extends StatelessWidget {
  final SkillProgressionSummary summary;

  const SkillProgressSummaryCard({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cyan.withOpacity(0.15),
            elevated,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cyan.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.trending_up_rounded,
                  color: cyan,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Your Progress',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Stats row
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  value: summary.totalChainsStarted.toString(),
                  label: 'Skills Started',
                  icon: Icons.play_arrow_rounded,
                  color: AppColors.purple,
                ),
              ),
              Expanded(
                child: _StatItem(
                  value: summary.totalChainsCompleted.toString(),
                  label: 'Mastered',
                  icon: Icons.emoji_events_rounded,
                  color: AppColors.orange,
                ),
              ),
              Expanded(
                child: _StatItem(
                  value: summary.totalStepsUnlocked.toString(),
                  label: 'Steps Unlocked',
                  icon: Icons.lock_open_rounded,
                  color: AppColors.green,
                ),
              ),
            ],
          ),

          if (summary.totalAttempts > 0) ...[
            const SizedBox(height: 16),
            Divider(color: cardBorder),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.fitness_center_rounded,
                  size: 16,
                  color: textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  '${summary.totalAttempts} total practice sessions',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: textSecondary,
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
