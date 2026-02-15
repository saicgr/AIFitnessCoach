import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/flexibility_assessment.dart';
import '../../data/providers/flexibility_provider.dart';
import '../../widgets/glass_sheet.dart';

/// Screen showing flexibility assessment history
class FlexibilityHistoryScreen extends ConsumerStatefulWidget {
  final String userId;

  const FlexibilityHistoryScreen({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<FlexibilityHistoryScreen> createState() => _FlexibilityHistoryScreenState();
}

class _FlexibilityHistoryScreenState extends ConsumerState<FlexibilityHistoryScreen> {
  String? _selectedTestType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(flexibilityProvider.notifier).loadAssessmentHistory(
        userId: widget.userId,
        limit: 100,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(flexibilityProvider);

    // Get unique test types for filter
    final testTypes = state.assessmentHistory
        .map((a) => a.testType)
        .toSet()
        .toList()
      ..sort();

    // Filter history
    final filteredHistory = _selectedTestType != null
        ? state.assessmentHistory.where((a) => a.testType == _selectedTestType).toList()
        : state.assessmentHistory;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assessment History'),
      ),
      body: Column(
        children: [
          // Filter chips
          if (testTypes.length > 1) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _selectedTestType == null,
                    onSelected: (_) {
                      setState(() => _selectedTestType = null);
                    },
                  ),
                  const SizedBox(width: 8),
                  ...testTypes.map((type) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(_formatTestType(type)),
                        selected: _selectedTestType == type,
                        onSelected: (_) {
                          setState(() => _selectedTestType = type);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
            const Divider(height: 1),
          ],

          // History list
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredHistory.isEmpty
                    ? _buildEmptyState(theme)
                    : RefreshIndicator(
                        onRefresh: () async {
                          await ref.read(flexibilityProvider.notifier).loadAssessmentHistory(
                            userId: widget.userId,
                            limit: 100,
                          );
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredHistory.length,
                          itemBuilder: (context, index) {
                            final assessment = filteredHistory[index];
                            final previousAssessment = index < filteredHistory.length - 1
                                ? filteredHistory[index + 1]
                                : null;

                            return _buildHistoryItem(assessment, previousAssessment, theme);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Assessments Yet',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Complete some flexibility tests to see your history here',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(
    FlexibilityAssessment assessment,
    FlexibilityAssessment? previousAssessment,
    ThemeData theme,
  ) {
    final ratingColor = _getRatingColor(assessment.rating ?? 'fair');

    // Calculate improvement if same test type
    double? improvement;
    bool? isImprovement;
    if (previousAssessment != null && previousAssessment.testType == assessment.testType) {
      improvement = assessment.measurement - previousAssessment.measurement;
      // Need to know if higher is better for this test
      final test = ref.read(flexibilityProvider).tests
          .where((t) => t.id == assessment.testType)
          .firstOrNull;
      if (test != null) {
        isImprovement = test.higherIsBetter ? improvement > 0 : improvement < 0;
        improvement = improvement.abs();
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showAssessmentDetails(assessment, theme),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Rating indicator
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: ratingColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    (assessment.rating ?? 'F')[0].toUpperCase(),
                    style: TextStyle(
                      color: ratingColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatTestType(assessment.testType),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          assessment.formattedMeasurement,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (improvement != null && isImprovement != null) ...[
                          const SizedBox(width: 8),
                          Icon(
                            isImprovement ? Icons.trending_up : Icons.trending_down,
                            size: 16,
                            color: isImprovement ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            improvement.toStringAsFixed(1),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isImprovement ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(assessment.assessedAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),

              // Percentile
              if (assessment.percentile != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Top ${100 - assessment.percentile!}%',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAssessmentDetails(FlexibilityAssessment assessment, ThemeData theme) {
    showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => GlassSheet(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatTestType(assessment.testType),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Measurement', assessment.formattedMeasurement, theme),
              _buildDetailRow('Rating', (assessment.rating ?? 'Unknown').toUpperCase(), theme),
              if (assessment.percentile != null)
                _buildDetailRow('Percentile', 'Top ${100 - assessment.percentile!}%', theme),
              _buildDetailRow('Date', _formatDateFull(assessment.assessedAt), theme),
              if (assessment.notes != null && assessment.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Notes',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  assessment.notes!,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    final confirmed = await _confirmDelete(context);
                    if (confirmed == true) {
                      await ref.read(flexibilityProvider.notifier).deleteAssessment(
                        assessment.id,
                        userId: widget.userId,
                      );
                    }
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text('Delete Assessment', style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Assessment?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
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

  String _formatTestType(String testType) {
    return testType
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

  String _formatDateFull(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
