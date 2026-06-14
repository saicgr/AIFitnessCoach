import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/models/skill_progression.dart';
import '../../../widgets/design_system/zealova.dart';

import '../../../l10n/generated/app_localizations.dart';
/// Summary card showing user's overall skill progression stats
class SkillProgressSummaryCard extends StatelessWidget {
  final SkillProgressionSummary summary;

  const SkillProgressSummaryCard({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    return ZealovaCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.trending_up_rounded,
                color: tc.accent,
                size: 18,
              ),
              const SizedBox(width: 10),
              Text(
                AppLocalizations.of(context).skillProgressSummaryYourProgress.toUpperCase(),
                style: ZType.lbl(12, color: tc.textPrimary, letterSpacing: 1.6),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Stats row
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  value: summary.totalChainsStarted.toString(),
                  label: AppLocalizations.of(context).skillProgressSummarySkillsStarted,
                  icon: Icons.play_arrow_rounded,
                  color: AppColors.purple,
                ),
              ),
              Expanded(
                child: _StatItem(
                  value: summary.totalChainsCompleted.toString(),
                  label: AppLocalizations.of(context).skillProgressSummaryMastered,
                  icon: Icons.emoji_events_rounded,
                  color: AppColors.orange,
                ),
              ),
              Expanded(
                child: _StatItem(
                  value: summary.totalStepsUnlocked.toString(),
                  label: AppLocalizations.of(context).skillProgressSummaryStepsUnlocked,
                  icon: Icons.lock_open_rounded,
                  color: AppColors.green,
                ),
              ),
            ],
          ),

          if (summary.totalAttempts > 0) ...[
            const SizedBox(height: 16),
            const ZealovaRule(),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.fitness_center_rounded,
                  size: 14,
                  color: tc.textMuted,
                ),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.skillProgressSummaryCardTotalPracticeSessions(summary.totalAttempts),
                  style: ZType.lbl(11, color: tc.textMuted, letterSpacing: 0.8),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 18,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: ZType.disp(28, color: tc.textPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: ZType.lbl(9.5, color: tc.textMuted, letterSpacing: 1.2),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
