import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/fasting.dart';

/// Card displaying the fasting score with breakdown
class FastingScoreCard extends StatelessWidget {
  final FastingScore score;
  final FastingScoreTrend? trend;
  final bool isDark;
  final VoidCallback? onTap;

  const FastingScoreCard({
    super.key,
    required this.score,
    this.trend,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  size: 20,
                  color: score.tierColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Fasting Score',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const Spacer(),
                // Tier badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: score.tierColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    score.tierLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: score.tierColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Score display
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Big score number
                Text(
                  '${score.score}',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: score.tierColor,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '/ 100',
                    style: TextStyle(
                      fontSize: 16,
                      color: textMuted,
                    ),
                  ),
                ),
                const Spacer(),
                // Trend indicator
                if (trend != null) _buildTrendIndicator(trend!, textMuted),
              ],
            ),
            const SizedBox(height: 16),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: score.score / 100,
                minHeight: 8,
                backgroundColor: cardBorder,
                valueColor: AlwaysStoppedAnimation<Color>(score.tierColor),
              ),
            ),
            const SizedBox(height: 16),

            // Breakdown
            _buildBreakdownSection(textPrimary, textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendIndicator(FastingScoreTrend trend, Color textMuted) {
    final isUp = trend.isUp;
    final isDown = trend.isDown;

    Color trendColor;
    IconData trendIcon;

    if (isUp) {
      trendColor = AppColors.success;
      trendIcon = Icons.trending_up_rounded;
    } else if (isDown) {
      trendColor = AppColors.coral;
      trendIcon = Icons.trending_down_rounded;
    } else {
      trendColor = textMuted;
      trendIcon = Icons.trending_flat_rounded;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(trendIcon, size: 18, color: trendColor),
            const SizedBox(width: 4),
            Text(
              trend.scoreChange != 0
                  ? '${trend.scoreChange > 0 ? '+' : ''}${trend.scoreChange}'
                  : '—',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: trendColor,
              ),
            ),
          ],
        ),
        Text(
          'vs last week',
          style: TextStyle(
            fontSize: 10,
            color: textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildBreakdownSection(Color textPrimary, Color textMuted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Breakdown',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textMuted,
          ),
        ),
        const SizedBox(height: 8),
        _buildBreakdownItem(
          'Completion Rate',
          score.completionComponent,
          30,
          Icons.check_circle_outline,
          AppColors.success,
          textPrimary,
          textMuted,
        ),
        const SizedBox(height: 6),
        _buildBreakdownItem(
          'Streak Bonus',
          score.streakComponent,
          25,
          Icons.local_fire_department_outlined,
          AppColors.coral,
          textPrimary,
          textMuted,
        ),
        const SizedBox(height: 6),
        _buildBreakdownItem(
          'Avg Duration',
          score.durationComponent,
          20,
          Icons.timer_outlined,
          AppColors.purple,
          textPrimary,
          textMuted,
        ),
        const SizedBox(height: 6),
        _buildBreakdownItem(
          'Weekly Goal',
          score.weeklyComponent,
          15,
          Icons.calendar_today_outlined,
          AppColors.cyan,
          textPrimary,
          textMuted,
        ),
        const SizedBox(height: 6),
        _buildBreakdownItem(
          'Protocol Level',
          score.protocolComponent,
          10,
          Icons.speed_outlined,
          AppColors.yellow,
          textPrimary,
          textMuted,
        ),
      ],
    );
  }

  Widget _buildBreakdownItem(
    String label,
    double value,
    int weight,
    IconData icon,
    Color color,
    Color textPrimary,
    Color textMuted,
  ) {
    final weightedValue = (value * weight / 100).round();

    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: textPrimary,
            ),
          ),
        ),
        Text(
          '${value.round()}%',
          style: TextStyle(
            fontSize: 12,
            color: textMuted,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 32,
          child: Text(
            '+$weightedValue',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

/// Compact version of the score card for displaying in a row
class FastingScoreCompact extends StatelessWidget {
  final FastingScore score;
  final FastingScoreTrend? trend;
  final bool isDark;

  const FastingScoreCompact({
    super.key,
    required this.score,
    this.trend,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Score circle
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  score.tierColor,
                  score.tierColor.withValues(alpha: 0.7),
                ],
              ),
            ),
            child: Center(
              child: Text(
                '${score.score}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Score',
                style: TextStyle(
                  fontSize: 11,
                  color: textMuted,
                ),
              ),
              Row(
                children: [
                  Text(
                    score.tierLabel,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  if (trend != null && trend!.scoreChange != 0) ...[
                    const SizedBox(width: 4),
                    Icon(
                      trend!.isUp
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size: 12,
                      color: trend!.isUp ? AppColors.success : AppColors.coral,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
