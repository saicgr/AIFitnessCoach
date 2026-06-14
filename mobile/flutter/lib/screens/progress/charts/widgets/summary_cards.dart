import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../data/models/progress_charts.dart';

import '../../../../l10n/generated/app_localizations.dart';

/// Summary stat row — restyled to the v2 MEASUREMENT DETAIL `.pg-stat3`
/// archetype: hairline-divided cells with Anton numerals and a Barlow
/// uppercase kicker under each, no boxed card. The volume-trend cell keeps
/// its semantic green/red verdict colour; PRs + streak read in the accent.
class SummaryCards extends StatelessWidget {
  final ProgressSummary summary;

  const SummaryCards({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.hairline),
          bottom: BorderSide(color: AppColors.hairline),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _statCell(
              context,
              value: '${summary.totalWorkouts}',
              label: AppLocalizations.of(context).workoutListTitle,
              valueColor: tc.textPrimary,
            ),
            _divider(),
            _statCell(
              context,
              value: '${summary.totalPRs}',
              label: AppLocalizations.of(context).weeklyWrappedPrs,
              valueColor: tc.accent,
            ),
            _divider(),
            _statCell(
              context,
              value:
                  '${summary.volumeIncreasePercent >= 0 ? '+' : ''}${summary.volumeIncreasePercent.toStringAsFixed(1)}%',
              label: AppLocalizations.of(context).workoutSummaryAdvancedVolume,
              valueColor: _getTrendColor(context, summary.volumeIncreasePercent),
            ),
            _divider(),
            _statCell(
              context,
              value: '${summary.currentStreak}',
              label: AppLocalizations.of(context).xpProgressCardStreak,
              valueColor: tc.accent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() => const ZealovaRuleVertical();

  Widget _statCell(
    BuildContext context, {
    required String value,
    required String label,
    required Color valueColor,
  }) {
    final tc = ThemeColors.of(context);
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ZType.disp(20, color: valueColor),
          ),
          const SizedBox(height: 5),
          Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ZType.lbl(8.5, color: tc.textMuted, letterSpacing: 1.5),
          ),
        ],
      ),
    );
  }

  Color _getTrendColor(BuildContext context, double percent) {
    final tc = ThemeColors.of(context);
    if (percent > 5) return tc.success;
    if (percent < -5) return tc.error;
    return tc.textSecondary;
  }
}

/// Vertical hairline matching `.pg-stat3 .s` cell dividers.
class ZealovaRuleVertical extends StatelessWidget {
  const ZealovaRuleVertical({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, color: AppColors.hairline);
  }
}
