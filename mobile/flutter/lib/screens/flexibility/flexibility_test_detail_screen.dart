import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/flexibility_assessment.dart';
import '../../data/providers/flexibility_provider.dart';
import 'widgets/flexibility_progress_chart.dart';
import 'widgets/record_assessment_sheet.dart';

/// Detailed view of a specific flexibility test with progress tracking
class FlexibilityTestDetailScreen extends ConsumerStatefulWidget {
  final FlexibilityTest test;
  final String userId;

  const FlexibilityTestDetailScreen({
    super.key,
    required this.test,
    required this.userId,
  });

  @override
  ConsumerState<FlexibilityTestDetailScreen> createState() => _FlexibilityTestDetailScreenState();
}

class _FlexibilityTestDetailScreenState extends ConsumerState<FlexibilityTestDetailScreen> {
  @override
  void initState() {
    super.initState();

    // Load progress data for this test
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(flexibilityProvider.notifier).loadTestProgress(
        testType: widget.test.id,
        userId: widget.userId,
      );
      ref.read(flexibilityProvider.notifier).loadAssessmentHistory(
        testType: widget.test.id,
        userId: widget.userId,
        limit: 10,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(flexibilityProvider);
    final latestAssessment = state.getLatestForTest(widget.test.id);
    final trend = state.selectedTestTrend;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.test.name),
        actions: [
          IconButton(
            onPressed: () => _showRecordSheet(),
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Record Assessment',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(flexibilityProvider.notifier).loadTestProgress(
            testType: widget.test.id,
            userId: widget.userId,
          );
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Current Status Card
            _buildStatusCard(latestAssessment, theme),
            const SizedBox(height: 20),

            // Progress Chart
            if (trend != null && trend.trendData.length > 1) ...[
              Text(
                'Progress',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: FlexibilityProgressChart(trend: trend),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Description
            Text(
              'About This Test',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.test.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 20),

            // Target Muscles
            if (widget.test.targetMuscles.isNotEmpty) ...[
              Text(
                'Target Muscles',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.test.targetMuscles.map((muscle) {
                  return Chip(
                    label: Text(_formatMuscle(muscle)),
                    backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.5),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],

            // Instructions
            Text(
              'Instructions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...widget.test.instructions.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          '${entry.key + 1}',
                          style: TextStyle(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          entry.value,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),

            // Equipment Needed
            if (widget.test.equipmentNeeded.isNotEmpty) ...[
              Text(
                'Equipment Needed',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: widget.test.equipmentNeeded.map((equipment) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(equipment),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Tips
            if (widget.test.tips.isNotEmpty) ...[
              Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Colors.amber.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tips',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Column(
                  children: widget.test.tips.map((tip) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '\u2022 ',
                            style: TextStyle(
                              color: Colors.amber.shade800,
                              fontSize: 16,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              tip,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Common Mistakes
            if (widget.test.commonMistakes.isNotEmpty) ...[
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_outlined,
                    color: Colors.red.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Common Mistakes to Avoid',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  children: widget.test.commonMistakes.map((mistake) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.red.shade700,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              mistake,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Recent History
            if (state.assessmentHistory.isNotEmpty) ...[
              Text(
                'Recent Assessments',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...state.assessmentHistory.take(5).map((assessment) {
                return _buildHistoryItem(assessment, theme);
              }),
            ],

            const SizedBox(height: 80), // Space for FAB
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRecordSheet(),
        icon: const Icon(Icons.add),
        label: Text(latestAssessment != null ? 'Update' : 'Take Test'),
      ),
    );
  }

  Widget _buildStatusCard(FlexibilityAssessment? assessment, ThemeData theme) {
    if (assessment == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.self_improvement,
                size: 48,
                color: theme.colorScheme.primary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Not Yet Assessed',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Take this test to get your flexibility rating and personalized recommendations',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _showRecordSheet(),
                child: const Text('Start Assessment'),
              ),
            ],
          ),
        ),
      );
    }

    final ratingColor = _getRatingColor(assessment.rating ?? 'fair');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Score Circle
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: ratingColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(36),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      assessment.formattedMeasurement,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: ratingColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: ratingColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          (assessment.rating ?? 'fair').toUpperCase(),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: ratingColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (assessment.percentile != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          assessment.percentileDisplay,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Last assessed ${_formatDate(assessment.assessedAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(FlexibilityAssessment assessment, ThemeData theme) {
    final ratingColor = _getRatingColor(assessment.rating ?? 'fair');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: ratingColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              (assessment.rating ?? 'F')[0].toUpperCase(),
              style: TextStyle(
                color: ratingColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(assessment.formattedMeasurement),
        subtitle: Text(_formatDate(assessment.assessedAt)),
        trailing: assessment.percentile != null
            ? Text(
                assessment.percentileDisplay,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              )
            : null,
      ),
    );
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

  String _formatMuscle(String muscle) {
    return muscle
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
        .join(' ');
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  void _showRecordSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) => RecordAssessmentSheet(
        test: widget.test,
        userId: widget.userId,
      ),
    );
  }
}
