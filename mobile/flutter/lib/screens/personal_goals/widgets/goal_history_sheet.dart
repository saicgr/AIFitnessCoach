import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/personal_goals_service.dart';
import 'goal_history_chart.dart';

/// Bottom sheet displaying goal history with a progress chart
class GoalHistorySheet extends ConsumerStatefulWidget {
  final String exerciseName;
  final PersonalGoalType goalType;
  final int? currentValue;
  final int? personalBest;

  const GoalHistorySheet({
    super.key,
    required this.exerciseName,
    required this.goalType,
    this.currentValue,
    this.personalBest,
  });

  @override
  ConsumerState<GoalHistorySheet> createState() => _GoalHistorySheetState();
}

class _GoalHistorySheetState extends ConsumerState<GoalHistorySheet> {
  late PersonalGoalsService _goalsService;
  String? _userId;
  List<GoalHistoryDataPoint> _historyData = [];
  int? _allTimeBest;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initAndLoadData();
  }

  Future<void> _initAndLoadData() async {
    final apiClient = ref.read(apiClientProvider);
    _goalsService = PersonalGoalsService(apiClient);
    _userId = await apiClient.getUserId();

    if (_userId != null) {
      await _loadHistory();
    } else {
      setState(() {
        _isLoading = false;
        _error = 'User not logged in';
      });
    }
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _goalsService.getGoalHistory(
        userId: _userId!,
        exerciseName: widget.exerciseName,
        goalType: widget.goalType,
        limit: 12, // Last 12 weeks
      );

      final historyList = (response['history'] as List?) ?? [];
      final allTimeBest = response['all_time_best'] as int?;

      if (mounted) {
        setState(() {
          _historyData = historyList
              .map((e) => GoalHistoryDataPoint.fromJson(e as Map<String, dynamic>))
              .toList();
          _allTimeBest = allTimeBest ?? widget.personalBest;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.cyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.timeline,
                      color: AppColors.cyan,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.exerciseName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.goalType == PersonalGoalType.singleMax
                              ? 'Max Reps Progress'
                              : 'Weekly Volume Progress',
                          style: TextStyle(
                            fontSize: 13,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current stats summary
                    if (widget.currentValue != null || _allTimeBest != null)
                      _buildStatsSummary(textPrimary, textSecondary, cardBorder),

                    const SizedBox(height: 20),

                    // Chart or loading/error state
                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_error != null)
                      _buildErrorState(textSecondary)
                    else
                      GoalHistoryChart(
                        data: _historyData,
                        allTimeBest: _allTimeBest,
                        goalType: widget.goalType,
                        exerciseName: widget.exerciseName,
                      ),

                    const SizedBox(height: 20),

                    // Tips section
                    _buildTipsSection(textPrimary, textSecondary, cardBorder),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSummary(Color textPrimary, Color textSecondary, Color cardBorder) {
    return Row(
      children: [
        if (widget.currentValue != null)
          Expanded(
            child: _buildStatCard(
              label: 'This Week',
              value: '${widget.currentValue}',
              unit: 'reps',
              color: AppColors.cyan,
              cardBorder: cardBorder,
            ),
          ),
        if (widget.currentValue != null && _allTimeBest != null)
          const SizedBox(width: 12),
        if (_allTimeBest != null)
          Expanded(
            child: _buildStatCard(
              label: 'All-Time Best',
              value: '$_allTimeBest',
              unit: 'reps',
              color: AppColors.orange,
              cardBorder: cardBorder,
            ),
          ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required String unit,
    required Color color,
    required Color cardBorder,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: TextStyle(
                    fontSize: 14,
                    color: color.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Color textSecondary) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: AppColors.error.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'Could not load history',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadHistory,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsSection(Color textPrimary, Color textSecondary, Color cardBorder) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 18, color: AppColors.yellow),
              const SizedBox(width: 8),
              Text(
                'Tips for beating your PR',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTipItem(
            'Rest well before attempting a max effort',
            textSecondary,
          ),
          _buildTipItem(
            'Focus on form - quality reps count more',
            textSecondary,
          ),
          _buildTipItem(
            'Progressive overload: aim for +1-2 reps each week',
            textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text, Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '\u2022 ',
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper function to show the goal history sheet
void showGoalHistorySheet(
  BuildContext context, {
  required String exerciseName,
  required PersonalGoalType goalType,
  int? currentValue,
  int? personalBest,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => GoalHistorySheet(
        exerciseName: exerciseName,
        goalType: goalType,
        currentValue: currentValue,
        personalBest: personalBest,
      ),
    ),
  );
}
