part of 'neat_dashboard_screen.dart';


// ============================================
// NEAT Score Card Widget
// ============================================

class _NeatScoreCard extends StatelessWidget {
  final NeatScore score;
  final Animation<double> animation;
  final bool isDark;
  final Color elevatedColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color cardBorder;

  const _NeatScoreCard({
    required this.score,
    required this.animation,
    required this.isDark,
    required this.elevatedColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.cardBorder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: score.scoreColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: score.scoreColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.insights,
                  color: AppColors.cyan,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'NEAT Score',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: score.scoreColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getScoreLabel(score.score),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: score.scoreColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Large Circular Score
          AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return _CircularScoreIndicator(
                score: (score.score * animation.value).round(),
                maxScore: 100,
                scoreColor: score.scoreColor,
                size: 140,
                strokeWidth: 12,
                textPrimary: textPrimary,
                textMuted: textMuted,
              );
            },
          ),

          const SizedBox(height: 20),

          // Quick stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _QuickStat(
                icon: Icons.directions_walk,
                value: _formatNumber(score.steps),
                label: 'Steps',
                color: AppColors.cyan,
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
              Container(
                height: 40,
                width: 1,
                color: cardBorder,
              ),
              _QuickStat(
                icon: Icons.schedule,
                value: '${score.activeHours}',
                label: 'Active Hours',
                color: AppColors.success,
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
              Container(
                height: 40,
                width: 1,
                color: cardBorder,
              ),
              _QuickStat(
                icon: Icons.local_fire_department,
                value: '${((score.steps * 0.04).round())}',
                label: 'Calories',
                color: AppColors.orange,
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getScoreLabel(int score) {
    if (score >= 90) return 'EXCELLENT';
    if (score >= 75) return 'GREAT';
    if (score >= 50) return 'GOOD';
    if (score >= 25) return 'FAIR';
    return 'LOW';
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }
}


// ============================================
// Circular Score Indicator
// ============================================

class _CircularScoreIndicator extends StatelessWidget {
  final int score;
  final int maxScore;
  final Color scoreColor;
  final double size;
  final double strokeWidth;
  final Color textPrimary;
  final Color textMuted;

  const _CircularScoreIndicator({
    required this.score,
    required this.maxScore,
    required this.scoreColor,
    required this.size,
    required this.strokeWidth,
    required this.textPrimary,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    final progress = score / maxScore;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: strokeWidth,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation(textMuted.withOpacity(0.2)),
            ),
          ),
          // Progress circle
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              strokeWidth: strokeWidth,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation(scoreColor),
              strokeCap: StrokeCap.round,
            ),
          ),
          // Score text
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              Text(
                'of $maxScore',
                style: TextStyle(
                  fontSize: 14,
                  color: textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


// ============================================
// Quick Stat Widget
// ============================================

class _QuickStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color textPrimary;
  final Color textMuted;

  const _QuickStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.textPrimary,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: textMuted,
          ),
        ),
      ],
    );
  }
}


// ============================================
// Step Goal Card
// ============================================

class _StepGoalCard extends StatelessWidget {
  final int steps;
  final int goal;
  final bool isProgressiveGoal;
  final bool isDark;
  final Color elevatedColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color cardBorder;

  const _StepGoalCard({
    required this.steps,
    required this.goal,
    required this.isProgressiveGoal,
    required this.isDark,
    required this.elevatedColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.cardBorder,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (steps / goal).clamp(0.0, 1.0);
    final percentage = (progress * 100).round();
    final isComplete = steps >= goal;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.flag,
                color: isComplete ? AppColors.success : AppColors.cyan,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Step Goal',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              if (isProgressiveGoal) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'PROGRESSIVE',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: AppColors.purple,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (isComplete)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'COMPLETE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Steps display
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatNumber(steps),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '/ ${_formatNumber(goal)} steps',
                  style: TextStyle(
                    fontSize: 16,
                    color: textSecondary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: textMuted.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation(
                isComplete ? AppColors.success : AppColors.cyan,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Percentage and motivation
          Row(
            children: [
              Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isComplete ? AppColors.success : AppColors.cyan,
                ),
              ),
              const Spacer(),
              Text(
                _getMotivationalMessage(percentage),
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }

  String _getMotivationalMessage(int percentage) {
    if (percentage >= 100) return 'Goal achieved! Amazing!';
    if (percentage >= 75) return 'Almost there! Keep going!';
    if (percentage >= 50) return 'Halfway there!';
    if (percentage >= 25) return 'Great start!';
    return 'Let\'s get moving!';
  }
}


// ============================================
// Hourly Activity Card
// ============================================

class _HourlyActivityCard extends StatelessWidget {
  final List<HourlyActivity> hourlyActivity;
  final bool isDark;
  final Color elevatedColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color cardBorder;

  const _HourlyActivityCard({
    required this.hourlyActivity,
    required this.isDark,
    required this.elevatedColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.cardBorder,
  });

  @override
  Widget build(BuildContext context) {
    final currentHour = DateTime.now().hour;
    final maxSteps = hourlyActivity.fold(
        1, (max, h) => h.steps > max ? h.steps : max);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.timeline,
                color: AppColors.purple,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Hourly Activity',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const Spacer(),
              // Legend
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LegendItem(
                    color: AppColors.success,
                    label: '250+',
                    textMuted: textMuted,
                  ),
                  const SizedBox(width: 12),
                  _LegendItem(
                    color: AppColors.error,
                    label: '<250',
                    textMuted: textMuted,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Horizontal scrollable bar chart
          SizedBox(
            height: 100,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: hourlyActivity.map((activity) {
                  final barHeight = maxSteps > 0
                      ? (activity.steps / maxSteps * 70).clamp(4.0, 70.0)
                      : 4.0;
                  final isCurrentHour = activity.hour == currentHour;
                  final isActive = activity.isActive;
                  final isSedentary = activity.isSedentary;

                  Color barColor;
                  if (activity.steps == 0) {
                    barColor = textMuted.withOpacity(0.3);
                  } else if (isActive) {
                    barColor = AppColors.success;
                  } else if (isSedentary) {
                    barColor = AppColors.error;
                  } else {
                    barColor = textMuted.withOpacity(0.5);
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Current hour indicator
                        if (isCurrentHour)
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(
                              color: AppColors.cyan,
                              shape: BoxShape.circle,
                            ),
                          )
                        else
                          const SizedBox(height: 10),

                        // Bar
                        Container(
                          width: 12,
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: barColor,
                            borderRadius: BorderRadius.circular(4),
                            border: isCurrentHour
                                ? Border.all(color: AppColors.cyan, width: 2)
                                : null,
                          ),
                        ),

                        const SizedBox(height: 4),

                        // Hour label
                        Text(
                          _formatHour(activity.hour),
                          style: TextStyle(
                            fontSize: 9,
                            color:
                                isCurrentHour ? AppColors.cyan : textMuted,
                            fontWeight: isCurrentHour
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatHour(int hour) {
    if (hour == 0) return '12a';
    if (hour == 12) return '12p';
    if (hour < 12) return '${hour}a';
    return '${hour - 12}p';
  }
}


class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final Color textMuted;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: textMuted,
          ),
        ),
      ],
    );
  }
}


// ============================================
// Active Hours Card
// ============================================

class _ActiveHoursCard extends StatelessWidget {
  final int activeHours;
  final int goal;
  final List<HourlyActivity> hourlyActivity;
  final bool isDark;
  final Color elevatedColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color cardBorder;

  const _ActiveHoursCard({
    required this.activeHours,
    required this.goal,
    required this.hourlyActivity,
    required this.isDark,
    required this.elevatedColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.cardBorder,
  });

  @override
  Widget build(BuildContext context) {
    final isGoalMet = activeHours >= goal;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGoalMet
              ? AppColors.success.withOpacity(0.3)
              : cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.schedule,
                color: AppColors.success,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Active Hours',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                'Goal: $goal+',
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Large active hours display
          Row(
            children: [
              Text(
                '$activeHours',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: isGoalMet ? AppColors.success : textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Active Hours\nToday',
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                  height: 1.3,
                ),
              ),
              const Spacer(),
              // Hour dots visualization
              SizedBox(
                width: 140,
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: List.generate(24, (hour) {
                    final activity = hourlyActivity.firstWhere(
                      (h) => h.hour == hour,
                      orElse: () => HourlyActivity(hour: hour, steps: 0),
                    );
                    return Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: activity.isActive
                            ? AppColors.success
                            : activity.steps > 0
                                ? textMuted.withOpacity(0.3)
                                : textMuted.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Recommendation
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isGoalMet ? AppColors.success : AppColors.info)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  isGoalMet ? Icons.check_circle : Icons.info_outline,
                  color: isGoalMet ? AppColors.success : AppColors.info,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isGoalMet
                        ? 'Great job! You\'ve met your active hours goal today.'
                        : 'Try to move at least 250 steps every hour for better health.',
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

