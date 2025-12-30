import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/scores.dart';

/// Large hero display for the overall fitness score.
class OverallScoreHero extends StatelessWidget {
  final int overallScore;
  final FitnessLevel level;
  final String? trend;
  final int? previousScore;

  const OverallScoreHero({
    super.key,
    required this.overallScore,
    required this.level,
    this.trend,
    this.previousScore,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final scoreColor = _getScoreColor(overallScore);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scoreColor.withOpacity(0.3),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scoreColor.withOpacity(0.08),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        children: [
          // Level badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: scoreColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getLevelIcon(),
                  color: scoreColor,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  level.displayName.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Large score circle
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      scoreColor.withOpacity(0.2),
                      scoreColor.withOpacity(0.05),
                      Colors.transparent,
                    ],
                    stops: const [0.5, 0.75, 1.0],
                  ),
                ),
              ),
              // Progress ring
              SizedBox(
                width: 140,
                height: 140,
                child: CircularProgressIndicator(
                  value: overallScore / 100,
                  strokeWidth: 8,
                  backgroundColor: scoreColor.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                ),
              ),
              // Score text
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$overallScore',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  Text(
                    'OVERALL',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: textMuted,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Trend indicator
          if (trend != null && previousScore != null)
            _buildTrendIndicator(textMuted),
          // Description
          const SizedBox(height: 12),
          Text(
            _getLevelDescription(),
            style: TextStyle(
              fontSize: 14,
              color: textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTrendIndicator(Color textMuted) {
    final change = overallScore - (previousScore ?? overallScore);
    final isImproving = trend == 'improving' || change > 0;
    final isDecreasing = trend == 'declining' || change < 0;

    IconData icon;
    Color color;
    String label;

    if (isImproving) {
      icon = Icons.trending_up;
      color = AppColors.green;
      label = '+$change from last week';
    } else if (isDecreasing) {
      icon = Icons.trending_down;
      color = Colors.orange;
      label = '$change from last week';
    } else {
      icon = Icons.trending_flat;
      color = textMuted;
      label = 'Same as last week';
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: color,
            fontWeight: FontWeight.w500,
          ),
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

  IconData _getLevelIcon() {
    switch (level) {
      case FitnessLevel.elite:
        return Icons.star;
      case FitnessLevel.athletic:
        return Icons.emoji_events;
      case FitnessLevel.fit:
        return Icons.fitness_center;
      case FitnessLevel.developing:
        return Icons.trending_up;
      case FitnessLevel.beginner:
        return Icons.directions_walk;
    }
  }

  String _getLevelDescription() {
    switch (level) {
      case FitnessLevel.elite:
        return 'Outstanding! You\'re performing at an elite level.';
      case FitnessLevel.athletic:
        return 'Excellent work! Your fitness is at an athletic level.';
      case FitnessLevel.fit:
        return 'Great progress! You\'re maintaining a fit lifestyle.';
      case FitnessLevel.developing:
        return 'Keep it up! Your fitness is developing nicely.';
      case FitnessLevel.beginner:
        return 'You\'re just getting started. Every workout counts!';
    }
  }
}
