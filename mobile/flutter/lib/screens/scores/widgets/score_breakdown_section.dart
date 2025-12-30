import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Section showing breakdown of all score components.
class ScoreBreakdownSection extends StatelessWidget {
  final int strengthScore;
  final int nutritionScore;
  final int consistencyScore;
  final int readinessScore;

  const ScoreBreakdownSection({
    super.key,
    required this.strengthScore,
    required this.nutritionScore,
    required this.consistencyScore,
    required this.readinessScore,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Score Breakdown',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _ScoreBreakdownItem(
                icon: Icons.fitness_center,
                label: 'Strength',
                score: strengthScore,
                weight: '40%',
                color: _getScoreColor(strengthScore),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ScoreBreakdownItem(
                icon: Icons.restaurant,
                label: 'Nutrition',
                score: nutritionScore,
                weight: '20%',
                color: _getScoreColor(nutritionScore),
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ScoreBreakdownItem(
                icon: Icons.trending_up,
                label: 'Consistency',
                score: consistencyScore,
                weight: '30%',
                color: _getScoreColor(consistencyScore),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ScoreBreakdownItem(
                icon: Icons.local_fire_department,
                label: 'Readiness',
                score: readinessScore,
                weight: '10%',
                color: _getScoreColor(readinessScore),
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return AppColors.green;
    if (score >= 60) return AppColors.cyan;
    if (score >= 40) return AppColors.yellow;
    return Colors.orange;
  }
}

class _ScoreBreakdownItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int score;
  final String weight;
  final Color color;
  final bool isDark;

  const _ScoreBreakdownItem({
    required this.icon,
    required this.label,
    required this.score,
    required this.weight,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  weight,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$score',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: textMuted,
            ),
          ),
          const SizedBox(height: 8),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}
