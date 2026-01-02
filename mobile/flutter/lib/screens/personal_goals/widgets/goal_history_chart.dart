import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/personal_goals_service.dart';

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
      currentValue: json['current_value'] as int? ?? 0,
      targetValue: json['target_value'] as int?,
      isPr: json['is_pr_beaten'] as bool? ?? false,
      status: json['status'] as String? ?? 'completed',
    );
  }
}

/// Line chart displaying goal progress over past weeks with PR markers
class GoalHistoryChart extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    if (data.isEmpty) {
      return _buildEmptyState(elevated, textSecondary, textMuted, cardBorder);
    }

    // Sort data by week start date
    final sortedData = List<GoalHistoryDataPoint>.from(data)
      ..sort((a, b) => a.weekStart.compareTo(b.weekStart));

    // Calculate max value for Y axis
    double maxValue = 0;
    for (final point in sortedData) {
      if (point.currentValue > maxValue) {
        maxValue = point.currentValue.toDouble();
      }
    }
    if (allTimeBest != null && allTimeBest! > maxValue) {
      maxValue = allTimeBest!.toDouble();
    }
    final yMax = (maxValue * 1.2).ceilToDouble();

    // Find indices of PR points
    final prIndices = <int>{};
    for (int i = 0; i < sortedData.length; i++) {
      if (sortedData[i].isPr) {
        prIndices.add(i);
      }
    }

    // Create spots for the line
    final spots = <FlSpot>[];
    for (int i = 0; i < sortedData.length; i++) {
      spots.add(FlSpot(i.toDouble(), sortedData[i].currentValue.toDouble()));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.show_chart, color: AppColors.cyan, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Progress Over Time',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ),
              if (allTimeBest != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.emoji_events, size: 14, color: AppColors.orange),
                      const SizedBox(width: 4),
                      Text(
                        'Best: $allTimeBest',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Chart
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) =>
                        (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface)
                            .withValues(alpha: 0.95),
                    tooltipPadding: const EdgeInsets.all(10),
                    tooltipMargin: 8,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final index = spot.x.toInt();
                        if (index < 0 || index >= sortedData.length) {
                          return null;
                        }
                        final point = sortedData[index];
                        final label = _formatWeekLabel(point.weekStart);
                        final isPr = point.isPr;

                        return LineTooltipItem(
                          isPr ? '$label\n${spot.y.toInt()} reps (PR!)' : '$label\n${spot.y.toInt()} reps',
                          TextStyle(
                            color: isPr ? AppColors.orange : AppColors.cyan,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: yMax > 0 ? yMax / 4 : 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: cardBorder.withValues(alpha: 0.5),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= sortedData.length) {
                          return const SizedBox.shrink();
                        }
                        // Show every nth label to avoid crowding
                        final showEvery = sortedData.length > 6 ? 2 : 1;
                        if (index % showEvery != 0 && index != sortedData.length - 1) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _formatWeekLabel(sortedData[index].weekStart),
                            style: TextStyle(
                              color: textMuted,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                      reservedSize: 32,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.max || value == meta.min) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              color: textMuted,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                      reservedSize: 40,
                      interval: yMax > 0 ? yMax / 4 : 1,
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (sortedData.length - 1).toDouble().clamp(0, double.infinity),
                minY: 0,
                maxY: yMax,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: AppColors.cyan,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        final isPr = prIndices.contains(index);
                        if (isPr) {
                          // PR marker - orange star-like dot
                          return FlDotCirclePainter(
                            radius: 8,
                            color: AppColors.orange,
                            strokeWidth: 3,
                            strokeColor: Colors.white,
                          );
                        }
                        // Regular dot
                        return FlDotCirclePainter(
                          radius: 4,
                          color: AppColors.cyan,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.cyan.withValues(alpha: 0.3),
                          AppColors.cyan.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // All-time best horizontal line
                  if (allTimeBest != null)
                    LineChartBarData(
                      spots: [
                        FlSpot(0, allTimeBest!.toDouble()),
                        FlSpot((sortedData.length - 1).toDouble().clamp(0, double.infinity), allTimeBest!.toDouble()),
                      ],
                      isCurved: false,
                      color: AppColors.orange.withValues(alpha: 0.5),
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      dashArray: [8, 4],
                    ),
                ],
                extraLinesData: ExtraLinesData(
                  horizontalLines: allTimeBest != null
                      ? [
                          HorizontalLine(
                            y: allTimeBest!.toDouble(),
                            color: AppColors.orange.withValues(alpha: 0.3),
                            strokeWidth: 1,
                            dashArray: [8, 4],
                            label: HorizontalLineLabel(
                              show: true,
                              alignment: Alignment.topRight,
                              padding: const EdgeInsets.only(right: 4, bottom: 2),
                              style: TextStyle(
                                color: AppColors.orange.withValues(alpha: 0.7),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                              labelResolver: (line) => 'All-Time Best',
                            ),
                          ),
                        ]
                      : [],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.cyan,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                goalType == PersonalGoalType.singleMax ? 'Best Attempt' : 'Weekly Volume',
                style: TextStyle(
                  fontSize: 11,
                  color: textSecondary,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.orange,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Personal Record',
                style: TextStyle(
                  fontSize: 11,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color elevated, Color textSecondary, Color textMuted, Color cardBorder) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timeline_outlined,
            size: 48,
            color: textMuted,
          ),
          const SizedBox(height: 12),
          Text(
            'No History Yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Complete more weeks to see your progress over time',
            style: TextStyle(
              fontSize: 13,
              color: textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatWeekLabel(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[date.month - 1]} ${date.day}';
    } catch (_) {
      return dateStr;
    }
  }
}
