import 'package:flutter/material.dart';
import '../../../data/models/flexibility_assessment.dart';

/// Card widget showing a flexibility test with optional assessment result
class FlexibilityTestCard extends StatelessWidget {
  final FlexibilityTest test;
  final FlexibilityAssessment? assessment;
  final VoidCallback? onTap;
  final VoidCallback? onRecord;

  const FlexibilityTestCard({
    super.key,
    required this.test,
    this.assessment,
    this.onTap,
    this.onRecord,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasAssessment = assessment != null;
    final rating = assessment?.rating?.toLowerCase();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getRatingColor(rating).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getIconForTest(test.id),
                  color: _getRatingColor(rating),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      test.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (hasAssessment) ...[
                      Row(
                        children: [
                          _buildRatingBadge(rating!, theme),
                          const SizedBox(width: 8),
                          Text(
                            assessment!.formattedMeasurement,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          if (assessment!.percentile != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              assessment!.percentileDisplay,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ] else ...[
                      Text(
                        'Not yet assessed',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Record button
              IconButton(
                onPressed: onRecord,
                icon: Icon(
                  hasAssessment ? Icons.update : Icons.add_circle_outline,
                  color: theme.colorScheme.primary,
                ),
                tooltip: hasAssessment ? 'Update Assessment' : 'Record Assessment',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingBadge(String rating, ThemeData theme) {
    final color = _getRatingColor(rating);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        rating.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getRatingColor(String? rating) {
    switch (rating?.toLowerCase()) {
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

  IconData _getIconForTest(String testId) {
    if (testId.contains('shoulder')) return Icons.accessibility_new;
    if (testId.contains('hip') || testId.contains('groin')) return Icons.airline_seat_legroom_extra;
    if (testId.contains('hamstring') || testId.contains('sit_and_reach')) return Icons.airline_seat_recline_normal;
    if (testId.contains('ankle') || testId.contains('calf')) return Icons.directions_walk;
    if (testId.contains('thoracic')) return Icons.rotate_right;
    if (testId.contains('neck')) return Icons.face;
    if (testId.contains('quad')) return Icons.directions_run;
    return Icons.self_improvement;
  }
}
