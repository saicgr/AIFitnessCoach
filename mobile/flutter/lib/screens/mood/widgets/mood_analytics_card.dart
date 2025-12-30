import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/mood.dart';

/// Card showing mood analytics and distribution
class MoodAnalyticsCard extends StatelessWidget {
  final MoodAnalyticsResponse analytics;

  const MoodAnalyticsCard({
    super.key,
    required this.analytics,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surface : AppColorsLight.surface;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    final distribution = analytics.moodDistribution;
    final summary = analytics.summary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary stats row
          Row(
            children: [
              _buildStatItem(
                value: summary.totalCheckins.toString(),
                label: 'Check-ins',
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              _buildStatItem(
                value: summary.workoutsGenerated.toString(),
                label: 'Workouts',
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              _buildStatItem(
                value: '${summary.completionRate.toInt()}%',
                label: 'Completed',
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                valueColor: _getCompletionColor(summary.completionRate),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Most frequent mood
          if (summary.mostFrequentMood != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: summary.mostFrequentMood!.colorValue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(
                    summary.mostFrequentMood!.emoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Most Common Mood',
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                          ),
                        ),
                        Text(
                          '${_capitalizeFirst(summary.mostFrequentMood!.mood)} (${summary.mostFrequentMood!.count}x)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: summary.mostFrequentMood!.colorValue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Mood distribution bars
          Text(
            'Mood Distribution',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...distribution.map((item) => _buildDistributionBar(
                item,
                textPrimary,
                textSecondary,
              )),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String value,
    required String label,
    required Color textPrimary,
    required Color textSecondary,
    Color? valueColor,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: valueColor ?? textPrimary,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionBar(
    MoodDistribution item,
    Color textPrimary,
    Color textSecondary,
  ) {
    final moodColor = Mood.fromString(item.mood).color;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              item.emoji,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: Text(
              _capitalizeFirst(item.mood),
              style: TextStyle(
                fontSize: 13,
                color: textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 20,
              decoration: BoxDecoration(
                color: moodColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: item.percentage / 100,
                child: Container(
                  decoration: BoxDecoration(
                    color: moodColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 45,
            child: Text(
              '${item.percentage.toInt()}%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: textPrimary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCompletionColor(double rate) {
    if (rate >= 75) return Colors.green;
    if (rate >= 50) return Colors.orange;
    if (rate >= 25) return Colors.amber;
    return Colors.grey;
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
