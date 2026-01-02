import 'package:flutter/material.dart';
import '../../../data/models/flexibility_assessment.dart';

/// Card showing overall flexibility score and summary
class FlexibilityScoreCard extends StatelessWidget {
  final FlexibilitySummary summary;

  const FlexibilityScoreCard({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scoreColor = _getScoreColor(summary.overallScore);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Score Circle
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: summary.overallScore / 100,
                        strokeWidth: 8,
                        backgroundColor: scoreColor.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation(scoreColor),
                      ),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              summary.overallScore.toInt().toString(),
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: scoreColor,
                              ),
                            ),
                            Text(
                              '/100',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),

                // Summary Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overall Flexibility',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildRatingBadge(summary.overallRating, theme),
                      const SizedBox(height: 8),
                      Text(
                        '${summary.testsCompleted} tests completed',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      if (summary.totalAssessments > summary.testsCompleted)
                        Text(
                          '${summary.totalAssessments} total assessments',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            // Category Ratings
            if (summary.categoryRatings.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                'By Area',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: summary.categoryRatings.entries.map((entry) {
                  return _buildCategoryChip(
                    _formatMuscle(entry.key),
                    entry.value,
                    theme,
                  );
                }).toList(),
              ),
            ],

            // Improvement Areas
            if (summary.areasNeedingImprovement.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.trending_up,
                    size: 18,
                    color: Colors.amber.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Focus Areas',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                summary.areasNeedingImprovement.map(_formatTestType).join(', '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRatingBadge(String rating, ThemeData theme) {
    final color = _getScoreColor(_ratingToScore(rating));
    final displayRating = rating == 'not_assessed' ? 'Not Assessed' : rating.toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        displayRating,
        style: theme.textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String muscle, String rating, ThemeData theme) {
    final color = _getRatingColor(rating);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            muscle,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 75) return Colors.green;
    if (score >= 50) return Colors.lightGreen;
    if (score >= 25) return Colors.amber;
    return Colors.red;
  }

  Color _getRatingColor(String rating) {
    switch (rating.toLowerCase()) {
      case 'excellent':
        return Colors.green;
      case 'good':
        return Colors.lightGreen;
      case 'fair':
        return Colors.amber;
      case 'poor':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  double _ratingToScore(String rating) {
    switch (rating.toLowerCase()) {
      case 'excellent':
        return 87.5;
      case 'good':
        return 62.5;
      case 'fair':
        return 37.5;
      case 'poor':
        return 12.5;
      default:
        return 0;
    }
  }

  String _formatMuscle(String muscle) {
    return muscle
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
        .join(' ');
  }

  String _formatTestType(String testType) {
    return testType
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
        .join(' ');
  }
}
