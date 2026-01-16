import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/fasting.dart';
import '../../../data/repositories/fasting_repository.dart';

/// Card showing fasting statistics, score, and streak
class FastingStatsCard extends StatelessWidget {
  final FastingStats stats;
  final FastingStreak? streak;
  final FastingScore? score;
  final FastingScoreTrend? scoreTrend;
  final WeightCorrelationSummary? weightCorrelation;
  final bool isDark;
  final VoidCallback? onScoreTap;

  const FastingStatsCard({
    super.key,
    required this.stats,
    this.streak,
    this.score,
    this.scoreTrend,
    this.weightCorrelation,
    required this.isDark,
    this.onScoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final accentColor = isDark ? AppColors.accent : AppColorsLight.accent;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top section: Streak + Score
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Current Streak
                Expanded(
                  child: _buildStreakSection(textPrimary, textMuted),
                ),
                const SizedBox(width: 12),
                // Score
                if (score != null)
                  Expanded(
                    child: _buildScoreSection(textPrimary, textMuted),
                  ),
              ],
            ),
          ),

          // Weekly Progress
          if (streak != null && streak!.weeklyGoalEnabled) ...[
            Divider(color: cardBorder, height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildWeeklyProgress(textPrimary, textMuted, accentColor),
            ),
          ],

          // Stats Grid
          Divider(color: cardBorder, height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildStatsGrid(textPrimary, textMuted),
          ),

          // Weight Correlation (if available)
          if (weightCorrelation != null &&
              weightCorrelation!.totalLogs >= 5) ...[
            Divider(color: cardBorder, height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildWeightCorrelation(textPrimary, textMuted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStreakSection(Color textPrimary, Color textMuted) {
    final currentStreak = streak?.currentStreak ?? 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.coral.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.coral.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Text('🔥', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$currentStreak day${currentStreak != 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                Text(
                  'Current Streak',
                  style: TextStyle(
                    fontSize: 11,
                    color: textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreSection(Color textPrimary, Color textMuted) {
    return GestureDetector(
      onTap: onScoreTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: score!.tierColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: score!.tierColor,
              ),
              child: Center(
                child: Text(
                  '${score!.score}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          score!.tierLabel,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (scoreTrend != null && scoreTrend!.scoreChange != 0) ...[
                        const SizedBox(width: 4),
                        Icon(
                          scoreTrend!.isUp
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          size: 12,
                          color: scoreTrend!.isUp
                              ? AppColors.success
                              : AppColors.coral,
                        ),
                      ],
                    ],
                  ),
                  Text(
                    'Fasting Score',
                    style: TextStyle(
                      fontSize: 11,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyProgress(Color textPrimary, Color textMuted, Color accentColor) {
    final fastsThisWeek = streak?.fastsThisWeek ?? 0;
    final weeklyGoal = streak?.weeklyGoalFasts ?? 5;
    final progress = weeklyGoal > 0 ? (fastsThisWeek / weeklyGoal).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: accentColor,
            ),
            const SizedBox(width: 8),
            Text(
              'This Week',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              '$fastsThisWeek / $weeklyGoal fasts',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: progress >= 1.0 ? AppColors.success : textPrimary,
              ),
            ),
            if (progress >= 1.0) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.check_circle,
                size: 14,
                color: AppColors.success,
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
            valueColor: AlwaysStoppedAnimation<Color>(
              progress >= 1.0 ? AppColors.success : accentColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(Color textPrimary, Color textMuted) {
    return Row(
      children: [
        Expanded(
          child: _MiniStat(
            label: 'Total',
            value: '${stats.totalFasts}',
            isDark: isDark,
          ),
        ),
        _buildDivider(),
        Expanded(
          child: _MiniStat(
            label: 'Avg',
            value: _formatDuration(stats.avgDurationMinutes.toInt()),
            isDark: isDark,
          ),
        ),
        _buildDivider(),
        Expanded(
          child: _MiniStat(
            label: 'Longest',
            value: _formatDuration(stats.longestFastMinutes),
            isDark: isDark,
          ),
        ),
        _buildDivider(),
        Expanded(
          child: _MiniStat(
            label: 'Hours',
            value: '${stats.totalFastingHours}',
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 32,
      color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildWeightCorrelation(Color textPrimary, Color textMuted) {
    final avgFasting = weightCorrelation!.avgWeightFastingDays;
    final avgNonFasting = weightCorrelation!.avgWeightNonFastingDays;
    final monoAccent = isDark ? AppColors.accent : AppColorsLight.accent;

    // Determine if fasting helps with weight
    String correlationText;
    Color correlationColor;
    IconData correlationIcon;

    if (avgFasting != null && avgNonFasting != null) {
      final diff = avgFasting - avgNonFasting;
      if (diff < -0.1) {
        correlationText = 'Fasting helps';
        correlationColor = AppColors.success;
        correlationIcon = Icons.trending_down_rounded;
      } else if (diff > 0.1) {
        correlationText = 'Mixed results';
        correlationColor = AppColors.warning;
        correlationIcon = Icons.trending_flat_rounded;
      } else {
        correlationText = 'Neutral';
        correlationColor = textMuted;
        correlationIcon = Icons.trending_flat_rounded;
      }
    } else {
      correlationText = 'Need more data';
      correlationColor = textMuted;
      correlationIcon = Icons.help_outline;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.monitor_weight_outlined,
              size: 16,
              color: monoAccent,
            ),
            const SizedBox(width: 8),
            Text(
              'Weight & Fasting',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: correlationColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(correlationIcon, size: 14, color: correlationColor),
                  const SizedBox(width: 4),
                  Text(
                    correlationText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: correlationColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (avgFasting != null && avgNonFasting != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _WeightStat(
                  label: 'Fasting days',
                  value: avgFasting,
                  isPositive: avgFasting < avgNonFasting,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _WeightStat(
                  label: 'Non-fasting',
                  value: avgNonFasting,
                  isPositive: false,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) return '${hours}h';
    return '${hours}h${mins}m';
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 2),
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

class _WeightStat extends StatelessWidget {
  final String label;
  final double value;
  final bool isPositive;
  final bool isDark;

  const _WeightStat({
    required this.label,
    required this.value,
    required this.isPositive,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: (isPositive ? AppColors.success : textMuted).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: textMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${value.toStringAsFixed(1)} kg',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
