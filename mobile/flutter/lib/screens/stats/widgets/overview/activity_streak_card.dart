import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/widgets/skeleton/skeleton_box.dart';
import '../../../../data/providers/consistency_provider.dart';
import '../../../../widgets/design_system/zealova.dart';

/// Overview-tab "Activity Streak" card (Gravl Image #5, bottom-left tile).
///
/// A tappable [GlassCard] with a flame glyph, the current day-streak as a big
/// number + "day streak" label, and a "{completed}/{scheduled} days" sub for the
/// current month. Tapping deep-links to the dedicated streaks screen
/// (`/streaks`).
///
/// Data: [consistencyProvider] — `currentStreak` (consecutive-day streak from
/// `ConsistencyInsights.current_streak`) for the headline, and
/// `monthWorkoutsCompleted` / `monthWorkoutsScheduled` for the "X/Y days" sub.
/// The parent stats screen loads consistency insights + calendar when the
/// Overview tab opens, and the provider also disk-seeds insights on cold start,
/// so this card simply reacts to whatever's in state and shows a skeleton only
/// on a truly empty first load.
///
/// Height-flexible so it can sit 2-up next to [MonthHighlightCard].
class ActivityStreakCard extends ConsumerWidget {
  const ActivityStreakCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ThemeColors.of(context);
    final accent = colors.accent;

    final streak =
        ref.watch(consistencyProvider.select((s) => s.currentStreak));
    final hasInsights = ref.watch(
      consistencyProvider.select((s) => s.insights != null),
    );
    final completed = ref.watch(consistencyProvider
        .select((s) => s.insights?.monthWorkoutsCompleted ?? 0));
    final scheduled = ref.watch(consistencyProvider
        .select((s) => s.insights?.monthWorkoutsScheduled ?? 0));
    final isInitialLoad = ref.watch(consistencyProvider
        .select((s) => s.isLoading && s.insights == null));

    return ZealovaCard(
      variant: ZealovaCardVariant.outlined,
      radius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () {
        HapticService.instance.tap();
        context.push('/streaks');
      },
      child: (!hasInsights && isInitialLoad)
          ? _buildSkeleton()
          : _buildContent(
              context, colors, accent, streak, completed, scheduled),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ThemeColors colors,
    Color accent,
    int streak,
    int completed,
    int scheduled,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ZealovaSectionKicker('Day Streak'),
        const SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // The flame is the single accent element; the numeral stays primary.
            Icon(
              Icons.local_fire_department_rounded,
              size: 26,
              color: streak > 0 ? accent : colors.textMuted,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                '$streak',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ZType.disp(44, color: colors.textPrimary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ZealovaRule(margin: const EdgeInsets.only(bottom: AppSpacing.sm)),
        Text(
          // Scheduled may be 0 early in a month → just show completed count.
          (scheduled > 0
                  ? '$completed/$scheduled days this month'
                  : '$completed days this month')
              .toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ZType.lbl(11, color: colors.textMuted, letterSpacing: 1.3),
        ),
      ],
    );
  }

  Widget _buildSkeleton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        SkeletonBox(width: 80, height: 11),
        SizedBox(height: AppSpacing.sm),
        SkeletonBox(width: 100, height: 40),
        SizedBox(height: AppSpacing.md),
        SkeletonBox(width: 110, height: 11),
      ],
    );
  }
}
