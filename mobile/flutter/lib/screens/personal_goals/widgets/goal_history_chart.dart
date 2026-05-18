import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/services/personal_goals_service.dart';
import '../../../widgets/trends/trend_chart.dart';
import '../../../widgets/trends/trend_correlation.dart';

/// Model for a single history data point
class GoalHistoryDataPoint {
  final String weekStart;
  final int currentValue;
  final int? targetValue;
  final bool isPr;
  final String status;

  GoalHistoryDataPoint({
    required this.weekStart,
    required this.currentValue,
    this.targetValue,
    this.isPr = false,
    required this.status,
  });

  factory GoalHistoryDataPoint.fromJson(Map<String, dynamic> json) {
    return GoalHistoryDataPoint(
      weekStart: json['week_start'] as String,
      currentValue: (json['current_value'] as num?)?.toInt() ?? 0,
      targetValue: (json['target_value'] as num?)?.toInt(),
      isPr: json['is_pr_beaten'] as bool? ?? false,
      status: json['status'] as String? ?? 'completed',
    );
  }
}

/// Goal Trends — weekly goal progression rendered through the shared
/// [TrendChart] engine (Phase G5a) so it shares the EWMA smoothing, scrub
/// tooltip, pinch-zoom and theming used everywhere else. The all-time best
/// is drawn as a horizontal zone band.
class GoalHistoryChart extends ConsumerWidget {
  final List<GoalHistoryDataPoint> data;
  final int? allTimeBest;
  final PersonalGoalType goalType;
  final String exerciseName;

  const GoalHistoryChart({
    super.key,
    required this.data,
    this.allTimeBest,
    required this.goalType,
    required this.exerciseName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.colors(context);

    if (data.isEmpty) {
      return _buildEmptyState(colors);
    }

    // Sort + build TrendPoints, skipping any unparseable week_start.
    final sortedData = List<GoalHistoryDataPoint>.from(data)
      ..sort((a, b) => a.weekStart.compareTo(b.weekStart));

    final points = <TrendPoint>[
      for (final p in sortedData)
        if (DateTime.tryParse(p.weekStart) != null)
          TrendPoint(
            date: DateTime.parse(p.weekStart),
            value: p.currentValue.toDouble(),
          ),
    ];

    if (points.length < 2) {
      return _buildEmptyState(colors);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.show_chart, color: colors.accent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Goal Trends',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              if (allTimeBest != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.emoji_events,
                          size: 14, color: colors.warning),
                      const SizedBox(width: 4),
                      Text(
                        'Best: $allTimeBest',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          RepaintBoundary(
            child: TrendChart(
              accent: colors.accent,
              primary: TrendChartSeries(
                label: 'Goal Trends',
                unit: 'reps',
                points: points,
                zoneBands: [
                  if (allTimeBest != null)
                    TrendZoneBand(
                      value: allTimeBest!.toDouble(),
                      label: 'All-Time Best',
                      color: colors.warning,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timeline_outlined,
            size: 48,
            color: colors.textMuted,
          ),
          const SizedBox(height: 12),
          Text(
            'No History Yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Complete more weeks to see your goal trends over time',
            style: TextStyle(
              fontSize: 13,
              color: colors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
