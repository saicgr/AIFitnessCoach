import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/widgets/skeleton/skeleton_box.dart';
import '../../../../data/models/scores.dart';
import '../../../../data/providers/scores_provider.dart';
import '../../../../widgets/design_system/zealova.dart';

/// Overview-tab "Weekly Score" card (Gravl Image #5, top-right tile).
///
/// A tappable [GlassCard] showing the change in the user's overall fitness score
/// since the previous calculation as a signed delta ("+N" / "-N") with an
/// up/down trend arrow, plus a "Weekly Score" caption. Tapping deep-links to the
/// progress charts screen (`/progress-charts`).
///
/// Data: [scoresProvider] → `fitnessScore` ([FitnessScoreBreakdown]) →
/// `scoreChange` (backend `score_change` on `fitness_scores`). The backend
/// recomputes the fitness score on a weekly cadence, so `score_change` is the
/// most recent week-over-week delta — there is no separate "weekly delta" field.
/// (Assumption documented in the report.)
///
/// The Overview tab loader only fetches the lightweight scores *overview*, which
/// has no change field, so this card self-triggers `loadFitnessScore()` once (it
/// reuses the user id the overview load already cached on the notifier). Renders
/// a skeleton until the breakdown arrives — never a spinner.
class WeeklyScoreCard extends ConsumerStatefulWidget {
  const WeeklyScoreCard({super.key});

  @override
  ConsumerState<WeeklyScoreCard> createState() => _WeeklyScoreCardState();
}

class _WeeklyScoreCardState extends ConsumerState<WeeklyScoreCard> {
  bool _requested = false;

  @override
  void initState() {
    super.initState();
    // Fire after the first frame so the notifier's `_currentUserId` (set by the
    // parent's overview load) is available. Guarded so it runs at most once.
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureLoaded());
  }

  void _ensureLoaded() {
    if (_requested || !mounted) return;
    final state = ref.read(scoresProvider);
    // Only fetch when we have no breakdown yet and aren't mid-calculation.
    if (state.fitnessScore != null || state.isCalculatingFitness) return;
    _requested = true;
    // No userId arg → notifier falls back to its cached `_currentUserId`.
    ref.read(scoresProvider.notifier).loadFitnessScore();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final accent = colors.accent;

    final breakdown =
        ref.watch(scoresProvider.select((s) => s.fitnessScore));
    final overviewFitness = ref.watch(
      scoresProvider.select((s) => s.overview?.overallFitnessScore),
    );
    // Initial load = no breakdown, no overview fitness, still calculating/loading.
    final isInitialLoad = ref.watch(scoresProvider.select(
      (s) =>
          s.fitnessScore == null &&
          s.overview?.overallFitnessScore == null &&
          (s.isLoading || s.isCalculatingFitness),
    ));

    final hasAny = breakdown != null || overviewFitness != null;

    return ZealovaCard(
      variant: ZealovaCardVariant.outlined,
      radius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () {
        HapticService.instance.tap();
        context.push('/progress-charts');
      },
      child: (!hasAny && isInitialLoad)
          ? _buildSkeleton()
          : _buildContent(context, accent, colors, breakdown),
    );
  }

  Widget _buildContent(
    BuildContext context,
    Color accent,
    ThemeColors colors,
    FitnessScoreBreakdown? breakdown,
  ) {
    // `scoreChange` is the week-over-week delta. Null (no prior calc yet) → 0.
    final change = breakdown?.scoreChange ?? 0;
    final isUp = change > 0;
    final isDown = change < 0;
    final isFlat = change == 0;

    final deltaColor = isUp
        ? colors.success
        : isDown
            ? colors.error
            : colors.textSecondary;

    final arrow = isUp
        ? Icons.arrow_upward_rounded
        : isDown
            ? Icons.arrow_downward_rounded
            : Icons.trending_flat_rounded;

    // Signed display: "+5" / "-3" / "0".
    final deltaText = isFlat
        ? '0'
        : (isUp ? '+$change' : '$change'); // negative already carries its sign

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ZealovaSectionKicker('Weekly Score'),
        const SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Anton delta numeral carries the hierarchy; the up/down semantic
            // color is the single accent element on this card.
            Flexible(
              child: Text(
                deltaText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ZType.disp(48, color: deltaColor),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(arrow, size: 22, color: deltaColor),
          ],
        ),
        const SizedBox(height: 6),
        ZealovaRule(margin: const EdgeInsets.only(bottom: AppSpacing.sm)),
        Text(
          'WEEK OVER WEEK',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ZType.lbl(11, color: colors.textMuted, letterSpacing: 1.5),
        ),
      ],
    );
  }

  Widget _buildSkeleton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        SkeletonBox(width: 90, height: 11),
        SizedBox(height: AppSpacing.sm),
        SkeletonBox(width: 64, height: 44),
        SizedBox(height: AppSpacing.md),
        SkeletonBox(width: 100, height: 11),
      ],
    );
  }
}
