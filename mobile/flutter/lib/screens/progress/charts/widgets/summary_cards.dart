import 'package:flutter/material.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../data/models/progress_charts.dart';
import '../../../../widgets/design_system/zealova.dart';

import '../../../../l10n/generated/app_localizations.dart';
/// Summary cards displaying key progress metrics
class SummaryCards extends StatelessWidget {
  final ProgressSummary summary;

  const SummaryCards({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: _buildCard(
              context,
              icon: Icons.fitness_center,
              value: '${summary.totalWorkouts}',
              label: AppLocalizations.of(context).workoutListTitle,
              accentValue: false,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildCard(
              context,
              icon: Icons.emoji_events,
              value: '${summary.totalPRs}',
              label: AppLocalizations.of(context).weeklyWrappedPrs,
              accentValue: true,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildCard(
              context,
              icon: _getTrendIcon(summary.volumeIncreasePercent),
              value: '${summary.volumeIncreasePercent >= 0 ? '+' : ''}${summary.volumeIncreasePercent.toStringAsFixed(1)}%',
              label: AppLocalizations.of(context).workoutSummaryAdvancedVolume,
              valueColor: _getTrendColor(context, summary.volumeIncreasePercent),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildCard(
              context,
              icon: Icons.local_fire_department,
              value: '${summary.currentStreak}',
              label: AppLocalizations.of(context).xpProgressCardStreak,
              accentValue: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    bool accentValue = false,
    Color? valueColor,
  }) {
    final tc = ThemeColors.of(context);
    final iconColor =
        valueColor ?? (accentValue ? tc.accent : tc.textSecondary);

    return ZealovaCard(
      variant: ZealovaCardVariant.outlined,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ZType.disp(
              18,
              color: valueColor ?? (accentValue ? tc.accent : tc.textPrimary),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ZType.lbl(9, color: tc.textMuted, letterSpacing: 1.2),
          ),
        ],
      ),
    );
  }

  IconData _getTrendIcon(double percent) {
    if (percent > 5) return Icons.trending_up;
    if (percent < -5) return Icons.trending_down;
    return Icons.trending_flat;
  }

  Color _getTrendColor(BuildContext context, double percent) {
    final tc = ThemeColors.of(context);
    if (percent > 5) return tc.success;
    if (percent < -5) return tc.error;
    return tc.textMuted;
  }
}
