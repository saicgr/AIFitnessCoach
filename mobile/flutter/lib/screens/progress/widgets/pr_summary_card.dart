import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../data/models/scores.dart';
import '../../../data/providers/scores_provider.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../widgets/design_system/zealova.dart';

import '../../../l10n/generated/app_localizations.dart';
/// Card showing personal records summary.
///
/// STATS HUB redesign: the PR ledger renders as hairline rows
/// (`.pg-pr` in signature-v2) — a desaturated trophy, the exercise name in
/// Barlow uppercase with a date·equipment subtext, an Anton lift numeral with
/// `×reps`, and a green `+%` delta. Hairline dividers, not boxed cards.
class PRSummaryCard extends ConsumerStatefulWidget {
  final String userId;

  const PRSummaryCard({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<PRSummaryCard> createState() => _PRSummaryCardState();
}

class _PRSummaryCardState extends ConsumerState<PRSummaryCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(scoresProvider.notifier).loadPersonalRecords(userId: widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    // Select just the slices read here — avoids rebuilds on unrelated
    // scores mutations (readiness, nutrition, strength).
    final (prStats, isLoading) = ref.watch(
      scoresProvider.select((s) => (s.prStats, s.isLoading)),
    );

    return ZealovaCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section kicker (Barlow) — no boxed header bar.
          ZealovaSectionKicker(
            AppLocalizations.of(context).workoutSummaryGeneralPersonalRecords,
          ),
          const SizedBox(height: 12),

          if (isLoading && prStats == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (prStats == null || prStats.totalPrs == 0)
            _buildEmptyState(tc)
          else
            _buildContent(prStats, tc),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildEmptyState(ThemeColors tc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 40,
            color: tc.textMuted,
          ),
          const SizedBox(height: 14),
          Text(
            AppLocalizations.of(context).prSummaryCardNoPersonalRecordsYet,
            style: ZType.lbl(15, color: tc.textPrimary, letterSpacing: 0.5),
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context).prSummaryCardLogYourWorkoutsAnd,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: tc.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(PRStats stats, ThemeColors tc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Recent PRs — hairline ledger rows (.pg-pr).
        if (stats.recentPrs.isNotEmpty) ...[
          Text(
            AppLocalizations.of(context).prSummaryCardRecentPrs,
            style: ZType.lbl(10, color: tc.textMuted, letterSpacing: 1.8),
          ),
          const SizedBox(height: 4),
          ...() {
            final prs = stats.recentPrs.take(5).toList();
            return List.generate(prs.length, (i) {
              return Column(
                children: [
                  _buildPRRow(prs[i], tc),
                  if (i < prs.length - 1)
                    const ZealovaRule(margin: EdgeInsets.symmetric(vertical: 0)),
                ],
              );
            });
          }(),
          const SizedBox(height: 14),
        ],

        // Closing tiles row — hairline-divided cells (.pg-tiles).
        _buildStatTilesRow(stats, tc),
      ],
    );
  }

  /// A single PR ledger row (.pg-pr): desaturated trophy · Barlow uppercase
  /// name + date·equipment subtext · Anton lift numeral with ×reps · green +%.
  Widget _buildPRRow(PersonalRecordScore pr, ThemeColors tc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          // Trophy — desaturated, never accent. All-time PRs read slightly
          // brighter (textSecondary) than incremental ones (textMuted).
          Icon(
            pr.isAllTimePr
                ? Icons.emoji_events_outlined
                : Icons.trending_up,
            size: 18,
            color: pr.isAllTimePr ? tc.textSecondary : tc.textMuted,
          ),
          const SizedBox(width: 11),
          // Exercise name + subtext.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  pr.exerciseDisplayName.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ZType.lbl(13,
                      color: tc.textPrimary,
                      weight: FontWeight.w800,
                      letterSpacing: 1),
                ),
                const SizedBox(height: 2),
                Text(
                  _subText(pr),
                  style: ZType.data(10, color: tc.textMuted)
                      .copyWith(fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Anton lift numeral with ×reps.
          _buildLiftNumeral(pr, tc),
          // Green improvement delta.
          if (pr.improvementPercent != null) ...[
            const SizedBox(width: 9),
            Text(
              AppLocalizations.of(context)
                  .prSummaryCardValue(pr.improvementPercent!.toStringAsFixed(1)),
              style: ZType.lbl(10,
                  color: tc.success,
                  weight: FontWeight.w800,
                  letterSpacing: 0.5),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLiftNumeral(PersonalRecordScore pr, ThemeColors tc) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: pr.weightKg.toStringAsFixed(pr.weightKg % 1 == 0 ? 0 : 1),
            style: ZType.disp(18, color: tc.textPrimary, letterSpacing: 0.5),
          ),
          TextSpan(
            text: ' ×${pr.reps}',
            style: ZType.lbl(10,
                color: tc.textMuted,
                weight: FontWeight.w700,
                letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  /// Closing tiles row (.pg-tiles): Total · 30d · Streak, hairline-divided
  /// cells. Exactly one accent (the running PR streak earns it here).
  Widget _buildStatTilesRow(PRStats stats, ThemeColors tc) {
    final divider = Container(width: 1, height: 30, color: tc.cardBorder);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Expanded(
          child: Center(
            child: ZealovaStatTile(
              value: '${stats.totalPrs}',
              label: 'Total PRs',
              align: CrossAxisAlignment.center,
            ),
          ),
        ),
        divider,
        Expanded(
          child: Center(
            child: ZealovaStatTile(
              value: '${stats.prsThisPeriod}',
              label: 'Last 30d',
              align: CrossAxisAlignment.center,
            ),
          ),
        ),
        divider,
        Expanded(
          child: Center(
            child: ZealovaStatTile(
              value: '${stats.currentPrStreak}',
              label: 'PR Streak',
              accentValue: true,
              align: CrossAxisAlignment.center,
            ),
          ),
        ),
      ],
    );
  }

  String _subText(PersonalRecordScore pr) {
    final date = _formatDate(pr.achievedAt);
    final equip = (pr.setType.isNotEmpty && pr.setType != 'working')
        ? ' · ${pr.setType}'
        : '';
    return '$date$equip';
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays == 0) {
        return 'Today';
      } else if (diff.inDays == 1) {
        return 'Yesterday';
      } else if (diff.inDays < 7) {
        return '${diff.inDays} days ago';
      } else {
        return DateFormat('MMM d').format(date);
      }
    } catch (e) {
      return dateString;
    }
  }
}
