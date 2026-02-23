/// Feel Results Screen - Subjective Results Tracking
///
/// Shows users how exercise is improving their mood, energy, and confidence
/// over time with motivational insights and trend charts.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../widgets/app_loading.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/subjective_feedback.dart';
import '../../data/providers/subjective_feedback_provider.dart';

/// Main screen for viewing subjective results/feel results
class FeelResultsScreen extends ConsumerStatefulWidget {
  const FeelResultsScreen({super.key});

  @override
  ConsumerState<FeelResultsScreen> createState() => _FeelResultsScreenState();
}

class _FeelResultsScreenState extends ConsumerState<FeelResultsScreen> {
  int _selectedPeriodDays = 30;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final notifier = ref.read(subjectiveFeedbackProvider.notifier);
    notifier.loadFeelResults();
    notifier.loadTrends(days: _selectedPeriodDays);
  }

  void _changePeriod(int days) {
    setState(() {
      _selectedPeriodDays = days;
    });
    ref.read(subjectiveFeedbackProvider.notifier).loadTrends(days: days);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    final feedbackState = ref.watch(subjectiveFeedbackProvider);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Feel Results'),
        centerTitle: true,
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
      ),
      body: feedbackState.isLoading
          ? AppLoading.fullScreen()
          : RefreshIndicator(
              onRefresh: () async => _loadData(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Headline insight card
                      _buildHeadlineCard(feedbackState.feelResults, isDark),

                      const SizedBox(height: 24),

                      // Period selector
                      _buildPeriodSelector(elevated, textPrimary, textSecondary),

                      const SizedBox(height: 24),

                      // Mood before vs after chart
                      _buildMoodComparisonCard(feedbackState.trends, isDark, elevated, textPrimary, textSecondary),

                      const SizedBox(height: 20),

                      // Key metrics grid
                      _buildMetricsGrid(feedbackState.trends, elevated, textPrimary, textSecondary),

                      const SizedBox(height: 24),

                      // Weekly trends chart
                      _buildWeeklyTrendsCard(feedbackState.trends, isDark, elevated, textPrimary, textSecondary),

                      const SizedBox(height: 24),

                      // Feeling stronger stats
                      _buildFeelingStrongerCard(feedbackState.trends, isDark, elevated, textPrimary, textSecondary),

                      const SizedBox(height: 24),

                      // Tips card
                      _buildTipsCard(feedbackState.trends, elevated, textSecondary),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  /// Build the headline insight card
  Widget _buildHeadlineCard(FeelResultsSummary? summary, bool isDark) {
    if (summary == null || !summary.hasData) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.cyan.withOpacity(0.15),
              AppColors.purple.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cyan.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.mood,
              size: 48,
              color: AppColors.cyan,
            ),
            const SizedBox(height: 16),
            const Text(
              'Start Tracking Your Progress!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.cyan,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Complete workouts with mood check-ins to see how exercise improves how you feel.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95));
    }

    final isImproving = summary.moodImprovementPercent > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isImproving
              ? [
                  AppColors.success.withOpacity(0.2),
                  AppColors.cyan.withOpacity(0.1),
                ]
              : [
                  AppColors.cyan.withOpacity(0.15),
                  AppColors.purple.withOpacity(0.1),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isImproving
              ? AppColors.success.withOpacity(0.4)
              : AppColors.cyan.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          // Improvement badge
          if (isImproving)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.trending_up,
                    size: 16,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '+${summary.moodImprovementPercent.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: -0.2),

          const SizedBox(height: 16),

          // Headline
          Text(
            summary.insightHeadline,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isImproving ? AppColors.success : AppColors.cyan,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 8),

          // Detail
          Text(
            summary.insightDetail,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 20),

          // Key stat
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSmallStat(
                'Workouts',
                '${summary.totalWorkoutsTracked}',
                Icons.fitness_center,
              ),
              const SizedBox(width: 24),
              _buildSmallStat(
                'Avg Mood',
                '${summary.avgPostWorkoutMood.toStringAsFixed(1)}/5',
                Icons.mood,
              ),
              const SizedBox(width: 24),
              _buildSmallStat(
                'Feel Stronger',
                '${summary.feelingStrongerPercent.toStringAsFixed(0)}%',
                Icons.trending_up,
              ),
            ],
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildSmallStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.cyan.withOpacity(0.7)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  /// Build period selector chips
  Widget _buildPeriodSelector(Color elevated, Color textPrimary, Color textSecondary) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildPeriodChip('7 Days', 7, elevated, textPrimary, textSecondary),
        const SizedBox(width: 8),
        _buildPeriodChip('30 Days', 30, elevated, textPrimary, textSecondary),
        const SizedBox(width: 8),
        _buildPeriodChip('90 Days', 90, elevated, textPrimary, textSecondary),
      ],
    );
  }

  Widget _buildPeriodChip(String label, int days, Color elevated, Color textPrimary, Color textSecondary) {
    final isSelected = _selectedPeriodDays == days;
    return GestureDetector(
      onTap: () => _changePeriod(days),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.cyan.withOpacity(0.2) : elevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.cyan : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? AppColors.cyan : textSecondary,
          ),
        ),
      ),
    );
  }

  /// Build mood comparison card (before vs after)
  Widget _buildMoodComparisonCard(
    SubjectiveTrendsResponse? trends,
    bool isDark,
    Color elevated,
    Color textPrimary,
    Color textSecondary,
  ) {
    if (trends == null || trends.totalWorkouts == 0) {
      return const SizedBox.shrink();
    }

    final moodChange = trends.avgMoodAfter - trends.avgMoodBefore;
    final isPositive = moodChange > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.compare_arrows, size: 20, color: textSecondary),
              const SizedBox(width: 8),
              Text(
                'Mood Before vs After',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Visual comparison
          Row(
            children: [
              Expanded(
                child: _buildMoodBlock(
                  'Before',
                  trends.avgMoodBefore,
                  AppColors.orange.withOpacity(0.2),
                  AppColors.orange,
                ),
              ),
              const SizedBox(width: 16),
              // Change indicator
              Column(
                children: [
                  Icon(
                    isPositive ? Icons.arrow_forward : Icons.remove,
                    color: isPositive ? AppColors.success : textSecondary,
                    size: 24,
                  ),
                  Text(
                    isPositive ? '+${moodChange.toStringAsFixed(1)}' : moodChange.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isPositive ? AppColors.success : textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMoodBlock(
                  'After',
                  trends.avgMoodAfter,
                  AppColors.success.withOpacity(0.2),
                  AppColors.success,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Insight text
          Center(
            child: Text(
              isPositive
                  ? 'Exercise improves your mood by ${(moodChange * 20).toStringAsFixed(0)}%!'
                  : 'Keep tracking to see your improvement over time',
              style: TextStyle(
                fontSize: 13,
                color: textSecondary,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildMoodBlock(String label, double value, Color bgColor, Color accentColor) {
    final level = value.round().clamp(1, 5);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: accentColor.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            level.moodEmoji,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(height: 4),
          Text(
            value.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Build metrics grid
  Widget _buildMetricsGrid(
    SubjectiveTrendsResponse? trends,
    Color elevated,
    Color textPrimary,
    Color textSecondary,
  ) {
    if (trends == null) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Avg Energy',
            trends.avgEnergyAfter.toStringAsFixed(1),
            '/5',
            Icons.bolt,
            AppColors.orange,
            elevated,
            textPrimary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            'Avg Sleep',
            trends.avgSleepQuality.toStringAsFixed(1),
            '/5',
            Icons.bedtime,
            AppColors.purple,
            elevated,
            textPrimary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            'Confidence',
            trends.avgConfidence.toStringAsFixed(1),
            '/5',
            Icons.psychology,
            AppColors.cyan,
            elevated,
            textPrimary,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildMetricCard(
    String label,
    String value,
    String suffix,
    IconData icon,
    Color accentColor,
    Color elevated,
    Color textPrimary,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: accentColor),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
              children: [
                TextSpan(text: value),
                TextSpan(
                  text: suffix,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Build weekly trends chart
  Widget _buildWeeklyTrendsCard(
    SubjectiveTrendsResponse? trends,
    bool isDark,
    Color elevated,
    Color textPrimary,
    Color textSecondary,
  ) {
    if (trends == null || trends.weeklyData.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart, size: 20, color: textSecondary),
              const SizedBox(width: 8),
              Text(
                'Weekly Trends',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Chart
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: textSecondary.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value == 1 || value == 3 || value == 5) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              fontSize: 10,
                              color: textSecondary,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < trends.weeklyData.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'W${trends.weeklyData[index].week}',
                              style: TextStyle(
                                fontSize: 10,
                                color: textSecondary,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (trends.weeklyData.length - 1).toDouble(),
                minY: 0,
                maxY: 5,
                lineBarsData: [
                  // Mood line
                  LineChartBarData(
                    spots: trends.weeklyData.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value.avgMood);
                    }).toList(),
                    isCurved: true,
                    color: AppColors.cyan,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
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
                      color: AppColors.cyan.withOpacity(0.1),
                    ),
                  ),
                  // Energy line
                  LineChartBarData(
                    spots: trends.weeklyData.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value.avgEnergy);
                    }).toList(),
                    isCurved: true,
                    color: AppColors.orange,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: AppColors.orange,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Mood', AppColors.cyan),
              const SizedBox(width: 24),
              _buildLegendItem('Energy', AppColors.orange),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// Build feeling stronger card
  Widget _buildFeelingStrongerCard(
    SubjectiveTrendsResponse? trends,
    bool isDark,
    Color elevated,
    Color textPrimary,
    Color textSecondary,
  ) {
    if (trends == null) return const SizedBox.shrink();

    final percent = trends.feelingStrongerPercent;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.success.withOpacity(0.15),
            AppColors.success.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Progress circle
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: percent / 100,
                  strokeWidth: 8,
                  backgroundColor: AppColors.success.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                ),
              ),
              Text(
                '${percent.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      '\u{1F4AA}',
                      style: TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Feeling Stronger',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'You felt stronger after ${trends.feelingStrongerCount} of ${trends.totalWorkouts} workouts!',
                  style: TextStyle(
                    fontSize: 13,
                    color: textSecondary,
                  ),
                ),
                if (percent >= 50) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Your training is working!',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  /// Build tips card
  Widget _buildTipsCard(SubjectiveTrendsResponse? trends, Color elevated, Color textSecondary) {
    String tip;
    IconData icon;

    if (trends == null || trends.totalWorkouts < 5) {
      tip = 'Complete more workouts with mood check-ins to see patterns and insights about how exercise affects your well-being.';
      icon = Icons.lightbulb_outline;
    } else if (trends.avgMoodChange > 0.5) {
      tip = 'Exercise is clearly boosting your mood! Keep up the consistency for even better results.';
      icon = Icons.star;
    } else if (trends.avgSleepQuality < 3) {
      tip = 'Your sleep quality is affecting your workouts. Try improving sleep hygiene for better results.';
      icon = Icons.bedtime_outlined;
    } else {
      tip = 'Track your mood before and after each workout to see how exercise is improving your well-being.';
      icon = Icons.lightbulb_outline;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cyan.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.cyan,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                fontSize: 13,
                color: textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms);
  }
}
