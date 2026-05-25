/// Strain Coach card — daily intensity recommendation surfaced as a thin
/// home sliver between the Coach Hero and the Today Score (per plan §12).
///
/// Pure presentation; the decision tree lives in
/// `services/strain_recommendation_service.dart` so it stays unit-testable.
///
/// Data sources:
///   * [sleepScoreProvider]              — last night's [SleepScore].
///   * [userHistorySnapshotProvider]    — gives `priorTwoDaysHardCount`
///     when available. If the snapshot is null (call failed / brand-new
///     user / health not connected), the card renders a placeholder
///     "Connect health for an intensity call" rather than a fabricated tier.
///
/// Tap → `/chat?prefill=...` so the user can ask the coach to go deeper.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/theme_colors.dart';
import '../../../data/providers/sleep_score_provider.dart';
import '../../../data/providers/user_history_snapshot_provider.dart';
import '../../../data/services/haptic_service.dart';
import '../../../services/strain_recommendation_service.dart';
import '../../../widgets/health_connect_sheet.dart';
import 'home/unified_home_widgets.dart' show kHomeHPad;

import '../../../l10n/generated/app_localizations.dart';
class StrainCoachCard extends ConsumerWidget {
  const StrainCoachCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ThemeColors.of(context);

    final sleepAsync = ref.watch(sleepScoreProvider);
    final historyAsync = ref.watch(userHistorySnapshotProvider);

    // While the providers are first loading, render a thin skeleton — same
    // height as the loaded card so the layout doesn't jump (see kHomeCrossFade
    // pattern in unified_home_widgets).
    if (sleepAsync.isLoading || historyAsync.isLoading) {
      return _skeleton(c);
    }

    final sleepScore = sleepAsync.valueOrNull?.score?.total;
    final history = historyAsync.valueOrNull;

    // Graceful placeholder when we genuinely don't have enough signal to
    // make a call. We require EITHER sleep OR the history snapshot — having
    // exactly one is enough for the algorithm to produce a useful tier.
    if (sleepScore == null && history == null) {
      return _placeholder(c, context, ref);
    }

    // priorTwoDaysHardCount is the strongest single signal — backend now
    // computes this server-side (count of yesterday + day-before where
    // volume >= 1.2 * 30d median). Default 0 if the snapshot is missing.
    final priorHard = history?.priorTwoDaysHardCount ?? 0;

    // Real per-day strain ratio: yesterday's completed-workout volume divided
    // by the 30d non-zero median. Backend supplies both as kg-reps. If the
    // median is 0 (brand-new user, no logged volume yet) we degrade to 0.0,
    // which makes the algorithm's yesterday-strain branches NO-OP — exactly
    // the desired behavior per feedback_no_silent_fallbacks.md (don't
    // fabricate a baseline). Sleep remains the dominant signal in that case.
    final median = history?.volume30dMedianKg ?? 0.0;
    final yesterdayVolume = history?.yesterdayVolumeKg ?? 0.0;
    final yesterdayStrainRatio =
        median > 0 ? yesterdayVolume / median : 0.0;

    final rec = chooseStrainRecommendation(
      sleepScore: sleepScore,
      yesterdayStrainRatio: yesterdayStrainRatio,
      priorTwoDaysHardCount: priorHard,
    );

    return Padding(
      padding: kHomeHPad,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticService.light();
          // Pre-fill the chat with the rationale so the coach can riff on the
          // exact same signal the user just tapped. The leading "Strain
          // Coach:" prefix gives the LLM clean context without leaking
          // implementation details.
          final prefill = Uri.encodeComponent(
              'Strain Coach says: ${rec.rationale} — can you explain?');
          context.push('/chat?source=strain_coach&prefill=$prefill');
        },
        child: Container(
          decoration: BoxDecoration(
            color: c.elevated,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: c.cardBorder),
          ),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).strainCoachCardTodaySIntensity,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: c.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _TierChip(tier: rec.tier, c: c),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      rec.rationale,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: c.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      size: 18, color: c.textMuted),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _skeleton(ThemeColors c) {
    return Padding(
      padding: kHomeHPad,
      child: Container(
        height: 76,
        decoration: BoxDecoration(
          color: c.elevated,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.cardBorder),
        ),
      ),
    );
  }

  Widget _placeholder(ThemeColors c, BuildContext context, WidgetRef ref) {
    return Padding(
      padding: kHomeHPad,
      child: Container(
        decoration: BoxDecoration(
          color: c.elevated,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.cardBorder),
        ),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            Icon(Icons.bolt_outlined, size: 18, color: c.textMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                AppLocalizations.of(context).strainCoachCardConnectHealthForAn,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: c.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                backgroundColor: c.accent.withValues(alpha: 0.12),
                foregroundColor: c.accent,
              ),
              onPressed: () {
                HapticService.light();
                showHealthConnectSheet(context, ref);
              },
              child: Text(
                AppLocalizations.of(context).unifiedHomeWidgetsConnect,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tier chip — one of REST / LIGHT / MODERATE / HARD with a tier-specific
/// color hint. Uses theme accent for "hard" (it's the encouraging tier) and
/// semantic colors for the cautionary tiers so a user scanning the card sees
/// the call at a glance.
class _TierChip extends StatelessWidget {
  final StrainTier tier;
  final ThemeColors c;
  const _TierChip({required this.tier, required this.c});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (tier) {
      // Soft red — clear "stop today". Not alarmist, just a flag.
      StrainTier.rest => (
          'REST',
          const Color(0xFFE5567B).withValues(alpha: 0.18),
          const Color(0xFFE5567B),
        ),
      // Amber-ish — "go easy".
      StrainTier.light => (
          'LIGHT',
          const Color(0xFFE89A3E).withValues(alpha: 0.18),
          const Color(0xFFC96E18),
        ),
      // Neutral — "train normally".
      StrainTier.moderate => (
          'MODERATE',
          c.textMuted.withValues(alpha: 0.16),
          c.textSecondary,
        ),
      // Theme accent — "green light".
      StrainTier.hard => (
          'HARD',
          c.accent.withValues(alpha: 0.18),
          c.accent,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.7,
          color: fg,
        ),
      ),
    );
  }
}
