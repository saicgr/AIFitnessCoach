part of 'workout_stats_section.dart';

/// 2. SCALAR STRIP — four big numbers: Workouts, Streak, Strength, Time trained.
///
/// Sources (all real, no estimates):
///  - Workouts: `ROIMetrics.totalWorkoutsCompleted` (milestonesProvider).
///  - Streak: `ROIMetrics.currentStreakDays`, falling back to the consistency
///    insights `currentStreak` if ROI has not loaded yet.
///  - Strength: overall strength score from the fitness breakdown, with a delta
///    chip built from `scoreChange`.
///  - Time trained: `ROIMetrics.totalWorkoutTimeHours` formatted as "96h" /
///    "3h 40m". This is REAL recorded time, not a `count * 45` estimate.
///
/// Renders responsively: a [Wrap] of fixed-min-width tiles so it reads as a 4-up
/// row on wide screens and reflows to 2x2 on an iPhone SE without overflow.
class _ScalarStrip extends ConsumerWidget {
  final bool isDark;
  final Color accent;

  const _ScalarStrip({required this.isDark, required this.accent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roi = ref.watch(milestonesProvider.select((s) => s.roiMetrics));
    final consistency = ref.watch(consistencyProvider);
    final fitness = ref.watch(fitnessScoreBreakdownProvider);
    final scoresLoading = ref.watch(scoresLoadingProvider);
    final milestonesLoading =
        ref.watch(milestonesProvider.select((s) => s.isLoading));

    // Resolve the streak from whichever source has real data first.
    final streak = roi?.currentStreakDays ?? consistency.currentStreak;

    // Strength score + delta.
    final overallStrength = fitness?.overallScore;
    final scoreChange = fitness?.scoreChange;

    final hasRoi = roi != null;
    final stillLoading = (roi == null && milestonesLoading) ||
        (fitness == null && scoresLoading);

    // If literally nothing has loaded yet, show a skeleton row.
    if (roi == null && fitness == null && consistency.currentStreak == 0 &&
        stillLoading) {
      return StatCardShell(
        isDark: isDark,
        child: Wrap(
          spacing: 24,
          runSpacing: 18,
          children: List.generate(
            4,
            (_) => const SizedBox(
              width: 120,
              child: _CardSkeleton(height: 52),
            ),
          ),
        ),
      );
    }

    // If everything is genuinely empty (brand-new user), show one empty state.
    final noData = !hasRoi &&
        fitness == null &&
        consistency.currentStreak == 0 &&
        !stillLoading;
    if (noData) {
      final textMuted =
          isDark ? AppColors.textMuted : AppColorsLight.textMuted;
      return StatCardShell(
        isDark: isDark,
        child: Row(
          children: [
            Icon(Icons.fitness_center, size: 22, color: textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Log your first workout to see your training totals here.',
                style: TextStyle(
                    fontSize: 13, height: 1.35, color: textMuted),
              ),
            ),
          ],
        ),
      );
    }

    StatDeltaChip? strengthDelta;
    if (overallStrength != null && scoreChange != null && scoreChange != 0) {
      strengthDelta = StatDeltaChip(
        value: scoreChange.toDouble(),
        magnitudeLabel: scoreChange.abs().toString(),
        isDark: isDark,
        positiveIsGood: true,
      );
    }

    final tiles = <Widget>[
      _ScalarTile(
        child: BigStat(
          value: hasRoi ? roi.totalWorkoutsCompleted.toString() : '--',
          label: 'workouts',
          icon: Icons.check_circle_outline,
          isDark: isDark,
          accent: accent,
        ),
      ),
      _ScalarTile(
        child: BigStat(
          value: streak > 0 ? streak.toString() : '0',
          // Streak fire emoji is the one allowed warm accent per the UX deck.
          label: '🔥 day streak',
          icon: Icons.local_fire_department,
          isDark: isDark,
          accent: accent,
        ),
      ),
      _ScalarTile(
        child: BigStat(
          value: overallStrength != null && overallStrength > 0
              ? overallStrength.toString()
              : '--',
          label: 'strength',
          icon: Icons.bolt,
          isDark: isDark,
          accent: accent,
          delta: strengthDelta,
        ),
      ),
      _ScalarTile(
        child: BigStat(
          value: hasRoi ? _formatHours(roi.totalWorkoutTimeHours) : '--',
          label: 'time trained',
          icon: Icons.timer_outlined,
          isDark: isDark,
          accent: accent,
        ),
      ),
    ];

    return StatCardShell(
      isDark: isDark,
      child: Wrap(
        spacing: 24,
        runSpacing: 18,
        children: tiles,
      ),
    );
  }
}

/// A scalar tile constrained to a sensible min width so [Wrap] reflows to 2x2
/// on small screens (two ~120px tiles + 24 spacing fits an SE's ~328px body).
class _ScalarTile extends StatelessWidget {
  final Widget child;
  const _ScalarTile({required this.child});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 120, maxWidth: 160),
      child: child,
    );
  }
}
