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

/// Overview-tab "Strength Score" card (Gravl Image #5, top-left tile).
///
/// A tappable [GlassCard] with a glowing [HexagonBadge] holding the user's
/// overall strength score, the level label ("Elite"/"Advanced"/…) and a small
/// "Strength Score" caption beneath. Tapping deep-links to the Score tab of the
/// stats screen (`/stats?tab=2`).
///
/// Self-contained: it watches [scoresProvider] directly and renders its own
/// skeleton (never a spinner) until the overview slice is populated. The parent
/// stats screen kicks off `loadScoresOverview` when the Overview tab opens, so
/// this card only needs to react to the resulting state.
///
/// Height-flexible by design (no fixed large height) so it can sit 2-up in a
/// Row alongside [WeeklyScoreCard] without overflowing on an iPhone SE.
class StrengthScoreCard extends ConsumerWidget {
  const StrengthScoreCard({super.key});

  /// Human label for a [StrengthLevel] (the enum carries no displayName).
  static String _levelLabel(StrengthLevel level) {
    switch (level) {
      case StrengthLevel.elite:
        return 'Elite';
      case StrengthLevel.advanced:
        return 'Advanced';
      case StrengthLevel.intermediate:
        return 'Intermediate';
      case StrengthLevel.novice:
        return 'Novice';
      case StrengthLevel.beginner:
        return 'Beginner';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ThemeColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = colors.accent;

    // Watch only the slices this card needs so it doesn't rebuild on unrelated
    // score mutations (readiness/nutrition/etc.).
    final overview =
        ref.watch(scoresProvider.select((s) => s.overview));
    final score = ref.watch(
      scoresProvider.select((s) => s.overallStrengthScore),
    );
    // True only on the very first load with nothing cached to paint.
    final isInitialLoad = ref.watch(
      scoresProvider.select((s) => s.isLoading && s.overview == null),
    );

    final hasData = overview != null;

    return ZealovaCard(
      variant: ZealovaCardVariant.outlined,
      radius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () {
        HapticService.instance.tap();
        context.push('/stats?tab=2');
      },
      child: (!hasData && isInitialLoad)
          ? _buildSkeleton(context)
          : _buildContent(context, accent, isDark, score, overview),
    );
  }

  Widget _buildContent(
    BuildContext context,
    Color accent,
    bool isDark,
    int score,
    ScoresOverview? overview,
  ) {
    final colors = ThemeColors.of(context);
    final level = overview?.strengthLevel ?? StrengthLevel.beginner;
    // Score 0 with no overview yet → an honest "—" rather than a fake 0.
    final badgeValue = overview == null ? '—' : '$score';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ZealovaSectionKicker('Strength Score'),
        const SizedBox(height: AppSpacing.sm),
        // Big Anton numeral carries the score (accent = the one accent element).
        Text(
          badgeValue,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ZType.disp(48, color: accent),
        ),
        const SizedBox(height: 6),
        ZealovaRule(margin: const EdgeInsets.only(bottom: AppSpacing.sm)),
        Text(
          _levelLabel(level).toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ZType.lbl(12, color: colors.textSecondary, letterSpacing: 1.5),
        ),
      ],
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        SkeletonBox(width: 90, height: 11),
        SizedBox(height: AppSpacing.sm),
        SkeletonBox(width: 70, height: 44),
        SizedBox(height: AppSpacing.md),
        SkeletonBox(width: 100, height: 12),
      ],
    );
  }
}
