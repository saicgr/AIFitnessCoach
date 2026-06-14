import 'package:flutter/material.dart';
import 'package:fitwiz/widgets/design_system/zealova.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/models/fasting.dart';
import '../../../data/repositories/fasting_repository.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Card showing fasting statistics, score, and streak — Signature dark re-skin.
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
    final l10n = AppLocalizations.of(context)!;
    final tc = ThemeColors.of(context);

    return ZealovaCard(
      variant: ZealovaCardVariant.outlined,
      padding: EdgeInsets.zero,
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
                  child: _buildStreakSection(tc, l10n),
                ),
                const SizedBox(width: 12),
                // Score
                if (score != null)
                  Expanded(
                    child: _buildScoreSection(tc, l10n),
                  ),
              ],
            ),
          ),

          // Weekly Progress
          if (streak != null && streak!.weeklyGoalEnabled) ...[
            const ZealovaRule(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildWeeklyProgress(tc, l10n),
            ),
          ],

          // Stats Grid
          const ZealovaRule(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildStatsGrid(tc, l10n),
          ),

          // Weight Correlation (if available)
          if (weightCorrelation != null &&
              weightCorrelation!.totalLogs >= 5) ...[
            const ZealovaRule(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildWeightCorrelation(tc, l10n),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStreakSection(ThemeColors tc, AppLocalizations l10n) {
    final currentStreak = streak?.currentStreak ?? 0;

    return Row(
      children: [
        const Text('🔥', style: TextStyle(fontSize: 22)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.fastingStatsCardStreakDays(currentStreak),
                style: ZType.disp(26, color: tc.textPrimary),
              ),
              const SizedBox(height: 3),
              Text(
                l10n.fastingStatsCardCurrentStreak.toUpperCase(),
                style: ZType.lbl(9, color: tc.textMuted, letterSpacing: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScoreSection(ThemeColors tc, AppLocalizations l10n) {
    final tierColor = score!.tierColor;
    return GestureDetector(
      onTap: onScoreTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${score!.score}',
                style: ZType.disp(28, color: tierColor),
              ),
              const SizedBox(height: 3),
              Text(
                l10n.fastingStatsCardFastingScore.toUpperCase(),
                style: ZType.lbl(9, color: tc.textMuted, letterSpacing: 1.3),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    score!.tierLabel.toUpperCase(),
                    style: ZType.lbl(11, color: tierColor, letterSpacing: 1.2),
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
                    color:
                        scoreTrend!.isUp ? AppColors.success : AppColors.coral,
                  ),
                ],
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: tc.textMuted,
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyProgress(ThemeColors tc, AppLocalizations l10n) {
    final fastsThisWeek = streak?.fastsThisWeek ?? 0;
    final weeklyGoal = streak?.weeklyGoalFasts ?? 5;
    final progress =
        weeklyGoal > 0 ? (fastsThisWeek / weeklyGoal).clamp(0.0, 1.0) : 0.0;
    final complete = progress >= 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 15,
              color: tc.textMuted,
            ),
            const SizedBox(width: 8),
            Text(
              l10n.fastingStatsCardThisWeek.toUpperCase(),
              style: ZType.lbl(11, color: tc.textSecondary, letterSpacing: 1.2),
            ),
            const Spacer(),
            Text(
              l10n.fastingStatsCardFastsProgress(fastsThisWeek, weeklyGoal),
              style: ZType.data(
                13,
                color: complete ? AppColors.success : tc.textPrimary,
              ),
            ),
            if (complete) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.check_circle,
                size: 14,
                color: AppColors.success,
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.hairlineStrong,
            valueColor: AlwaysStoppedAnimation<Color>(
              complete ? AppColors.success : tc.accent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(ThemeColors tc, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: Center(
            child: ZealovaStatTile(
              label: l10n.fastingStatsCardTotal,
              value: '${stats.totalFasts}',
              valueSize: 22,
              align: CrossAxisAlignment.center,
            ),
          ),
        ),
        _buildDivider(),
        Expanded(
          child: Center(
            child: ZealovaStatTile(
              label: l10n.fastingStatsCardAvg,
              value: _formatDuration(stats.avgDurationMinutes.toInt()),
              valueSize: 22,
              align: CrossAxisAlignment.center,
            ),
          ),
        ),
        _buildDivider(),
        Expanded(
          child: Center(
            child: ZealovaStatTile(
              label: l10n.fastingStatsCardLongest,
              value: _formatDuration(stats.longestFastMinutes),
              valueSize: 22,
              align: CrossAxisAlignment.center,
            ),
          ),
        ),
        _buildDivider(),
        Expanded(
          child: Center(
            child: ZealovaStatTile(
              label: l10n.fastingStatsCardHours,
              value: '${stats.totalFastingHours}',
              valueSize: 22,
              align: CrossAxisAlignment.center,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 32,
      color: AppColors.hairline,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildWeightCorrelation(ThemeColors tc, AppLocalizations l10n) {
    final avgFasting = weightCorrelation!.avgWeightFastingDays;
    final avgNonFasting = weightCorrelation!.avgWeightNonFastingDays;

    // Determine if fasting helps with weight
    String correlationText;
    Color correlationColor;
    IconData correlationIcon;

    if (avgFasting != null && avgNonFasting != null) {
      final diff = avgFasting - avgNonFasting;
      if (diff < -0.1) {
        correlationText = l10n.fastingStatsCardFastingHelps;
        correlationColor = AppColors.success;
        correlationIcon = Icons.trending_down_rounded;
      } else if (diff > 0.1) {
        correlationText = l10n.fastingStatsCardMixedResults;
        correlationColor = AppColors.warning;
        correlationIcon = Icons.trending_flat_rounded;
      } else {
        correlationText = l10n.fastingStatsCardNeutral;
        correlationColor = tc.textMuted;
        correlationIcon = Icons.trending_flat_rounded;
      }
    } else {
      correlationText = l10n.fastingStatsCardNeedMoreData;
      correlationColor = tc.textMuted;
      correlationIcon = Icons.help_outline;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.monitor_weight_outlined,
              size: 15,
              color: tc.textMuted,
            ),
            const SizedBox(width: 8),
            Text(
              l10n.fastingStatsCardWeightFasting.toUpperCase(),
              style: ZType.lbl(11, color: tc.textSecondary, letterSpacing: 1.2),
            ),
            const Spacer(),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(correlationIcon, size: 14, color: correlationColor),
                const SizedBox(width: 4),
                Text(
                  correlationText.toUpperCase(),
                  style: ZType.lbl(10,
                      color: correlationColor, letterSpacing: 1.0),
                ),
              ],
            ),
          ],
        ),
        if (avgFasting != null && avgNonFasting != null) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _WeightStat(
                  label: l10n.fastingStatsCardFastingDays,
                  value: avgFasting,
                  isPositive: avgFasting < avgNonFasting,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _WeightStat(
                  label: l10n.fastingStatsCardNonFasting,
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
    final tc = ThemeColors.of(context);
    final accentColor = isPositive ? AppColors.success : tc.textPrimary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tc.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: ZType.lbl(9, color: tc.textMuted, letterSpacing: 1.2),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context)!
                .fastingStatsCardKg(value.toStringAsFixed(1)),
            style: ZType.data(15, color: accentColor),
          ),
        ],
      ),
    );
  }
}
