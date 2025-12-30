import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/scores.dart';

/// Card showing detailed nutrition score breakdown.
class NutritionScoreCard extends StatelessWidget {
  final NutritionScoreData? score;
  final NutritionLevel level;
  final bool isDark;

  const NutritionScoreCard({
    super.key,
    required this.score,
    required this.level,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final scoreColor = _getLevelColor(level);

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
                Icons.restaurant,
                color: scoreColor,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nutrition Score',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    Text(
                      'Weekly nutrition adherence',
                      style: TextStyle(
                        fontSize: 11,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  level.displayName.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Overall score
          Row(
            children: [
              Text(
                '${score?.overallScore ?? 0}',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '/ 100',
                style: TextStyle(
                  fontSize: 16,
                  color: textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Breakdown items
          if (score != null) ...[
            _buildAdherenceItem(
              'Logging Adherence',
              score!.loggingAdherencePercent,
              '${score!.daysLogged}/7 days',
              textMuted,
            ),
            const SizedBox(height: 12),
            _buildAdherenceItem(
              'Calorie Adherence',
              (score!.calorieAdherencePercent * 100).round(),
              null,
              textMuted,
            ),
            const SizedBox(height: 12),
            _buildAdherenceItem(
              'Protein Adherence',
              (score!.proteinAdherencePercent * 100).round(),
              null,
              textMuted,
            ),
            if (score!.avgHealthScore > 0) ...[
              const SizedBox(height: 12),
              _buildAdherenceItem(
                'Avg Health Score',
                (score!.avgHealthScore * 10).round(), // Convert 0-10 to 0-100
                null,
                textMuted,
              ),
            ],
          ] else
            Text(
              'Log your meals to see your nutrition score breakdown.',
              style: TextStyle(
                fontSize: 13,
                color: textMuted,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAdherenceItem(
    String label,
    int percent,
    String? detail,
    Color textMuted,
  ) {
    final color = _getPercentColor(percent);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: textMuted,
                ),
              ),
            ),
            if (detail != null)
              Text(
                detail,
                style: TextStyle(
                  fontSize: 12,
                  color: textMuted,
                ),
              ),
            const SizedBox(width: 8),
            Text(
              '$percent%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: percent / 100,
            backgroundColor: color.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Color _getLevelColor(NutritionLevel level) {
    switch (level) {
      case NutritionLevel.excellent:
        return AppColors.green;
      case NutritionLevel.good:
        return AppColors.cyan;
      case NutritionLevel.fair:
        return AppColors.yellow;
      case NutritionLevel.needsWork:
        return Colors.orange;
    }
  }

  Color _getPercentColor(int percent) {
    if (percent >= 80) return AppColors.green;
    if (percent >= 60) return AppColors.cyan;
    if (percent >= 40) return AppColors.yellow;
    return Colors.orange;
  }
}
