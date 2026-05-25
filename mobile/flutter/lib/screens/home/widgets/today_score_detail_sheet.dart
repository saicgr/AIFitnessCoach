import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_colors.dart';
import '../../../data/models/today_score.dart';
import '../../../data/providers/today_score_provider.dart';
import '../../../services/score_history_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../widgets/glass_sheet.dart';
import 'ring_catalog.dart';
import 'score_colors.dart';
import 'segmented_score_ring.dart';

/// Localization helper for [ContributorKind] labels.
extension ContributorKindI18n on ContributorKind {
  String localizedLabel(BuildContext context) => label;
}

/// Open the Today Score breakdown as a modal bottom sheet.
void showTodayScoreDetailSheet(BuildContext context) {
  showGlassSheet<void>(
    context: context,
    builder: (_) => const GlassSheet(child: _TodayScoreDetailSheet()),
  );
}

/// The score breakdown — the ring, momentum, and every contributor explained
/// in plain language (including why one may not be counted today).
class _TodayScoreDetailSheet extends ConsumerWidget {
  const _TodayScoreDetailSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final c = ref.colors(context);
    final score = ref.watch(todayScoreProvider);
    final history = ref.watch(scoreHistoryProvider);

    final segments = score.applicableContributors
        .map((cc) => ScoreRingSegment(
              weight: cc.effectiveWeight,
              completion: cc.completion,
              color: colorForContributor(cc.kind),
              trackColor:
                  colorForContributor(cc.kind).withValues(alpha: 0.16),
            ))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
              Text(
                l10n.todayScoreDetailTodayScore,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 18),
              if (score.isSetupState)
                _setup(c, l10n)
              else ...[
                Center(
                  child: SegmentedScoreRing(
                    size: 156,
                    strokeWidth: 19,
                    segments: segments,
                    center: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${score.score}',
                          style: TextStyle(
                            fontSize: 50,
                            fontWeight: FontWeight.w800,
                            height: 0.95,
                            letterSpacing: -2,
                            color: c.textPrimary,
                          ),
                        ),
                        Text(
                          score.stateLabel.toUpperCase(),
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                            color: c.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(child: _momentumLine(c, history, l10n)),
                const SizedBox(height: 18),
                for (final cc in score.contributors) _contributorTile(context, c, cc, l10n),
                const SizedBox(height: 14),
                _howItWorks(context, c, score, l10n),
              ],
        ],
      ),
    );
  }

  Widget _momentumLine(ThemeColors c, ScoreHistory history, AppLocalizations l10n) {
    final delta = history.todayDelta;
    final avg = history.recentAverage();
    final String momentum;
    if (delta > 0) {
      momentum = l10n.todayScoreDetailUp(delta);
    } else if (delta < 0) {
      momentum = l10n.todayScoreDetailDown(-delta);
    } else {
      momentum = l10n.todayScoreDetailSteady;
    }
    return Text(
      avg != null ? l10n.todayScoreDetailMomentumWithAvg(momentum, avg) : momentum,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: delta > 0 ? const Color(0xFF2C8A54) : c.textSecondary,
      ),
    );
  }

  Widget _contributorTile(BuildContext context, ThemeColors c, ScoreContributor cc, AppLocalizations l10n) {
    final color = colorForContributor(cc.kind);
    final weightPct = (cc.effectiveWeight * 100).round();
    final earned = cc.points.round();
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: c.elevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: cc.applicable ? color : c.textMuted,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cc.kind.localizedLabel(context),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: cc.applicable ? c.textPrimary : c.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  cc.statusText,
                  style: TextStyle(fontSize: 11.5, color: c.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            cc.applicable ? l10n.todayScoreDetailEarnedPts(earned, weightPct) : l10n.todayScoreDetailNotCounted,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: cc.applicable ? c.textPrimary : c.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _howItWorks(BuildContext context, ThemeColors c, TodayScore score, AppLocalizations l10n) {
    final inactive = score.contributors.where((cc) => !cc.applicable).toList();
    final String body;
    if (inactive.isEmpty) {
      body = l10n.todayScoreDetailHowItWorks;
    } else {
      final names = inactive.map((cc) => cc.kind.localizedLabel(context)).join(' and ');
      body = l10n.todayScoreDetailInactiveExplanation(names, inactive.length);
    }
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: c.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: c.accent),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              body,
              style: TextStyle(
                fontSize: 11.5,
                height: 1.4,
                color: c.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _setup(ThemeColors c, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.elevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.cardBorder),
      ),
      child: Text(
        l10n.todayScoreDetailSetupText,
        style: TextStyle(fontSize: 12.5, height: 1.45, color: c.textSecondary),
      ),
    );
  }
}
