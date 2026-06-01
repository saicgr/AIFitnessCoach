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
    final muscleScores = ref.watch(muscleScoresProvider);
    final scoresLoading = ref.watch(scoresLoadingProvider);
    final milestonesLoading =
        ref.watch(milestonesProvider.select((s) => s.isLoading));

    // Resolve the streak from whichever source has real data first.
    final streak = roi?.currentStreakDays ?? consistency.currentStreak;

    // --- Acts-on numbers (lead with these per the research-backed restructure) ---
    // This-week hard sets across all tracked muscles (real, summed; 0 = omit).
    final weekSets =
        muscleScores.values.fold<int>(0, (sum, m) => sum + m.weeklySets);
    // Consistency tile. The consistency insights expose a MONTH completion
    // pair (`monthWorkoutsCompleted` of `monthWorkoutsScheduled`) — a real,
    // honest "X of N" the loadInsights() call already populates. (There is no
    // weekly count field on the model, and the weekly calendar is not loaded on
    // this tab, so we surface the month figure rather than fabricate a weekly
    // one.) Shown only when there is a real schedule denominator.
    final monthDone = consistency.insights?.monthWorkoutsCompleted ?? 0;
    final monthTarget = consistency.insights?.monthWorkoutsScheduled ?? 0;
    // Top lift e1RM = best estimated 1RM among the strongest muscle group.
    final rankedMuscles = muscleScores.values
        .where((m) => (m.bestEstimated1rmKg ?? 0) > 0)
        .toList()
      ..sort((a, b) =>
          (b.bestEstimated1rmKg ?? 0).compareTo(a.bestEstimated1rmKg ?? 0));
    final topLift = rankedMuscles.isNotEmpty ? rankedMuscles.first : null;
    final topLiftE1rmLbs = topLift?.bestEstimated1rmKg != null
        ? _kgToLbs(topLift!.bestEstimated1rmKg!)
        : null;

    // Strength score + delta (delta chip rides on the top-lift tile).
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

    // Build tiles dynamically: lead with the three acts-on numbers (this-week
    // sets, this-week workouts, top-lift e1RM + delta), then streak and total
    // time as secondary context. Any sub-metric with no real value is OMITTED
    // entirely (no '--' placeholder, no fabricated zero), per the curated
    // policy. At least one will have data because the section only renders this
    // strip for users with >=1 completed workout.
    final tiles = <Widget>[
      if (weekSets > 0)
        _ScalarTile(
          child: BigStat(
            value: weekSets.toString(),
            label: 'sets this week',
            icon: Icons.fitness_center,
            isDark: isDark,
            accent: accent,
          ),
        ),
      if (monthDone > 0)
        _ScalarTile(
          child: BigStat(
            value:
                monthTarget > 0 ? '$monthDone of $monthTarget' : '$monthDone',
            label: 'this month',
            icon: Icons.event_available_outlined,
            isDark: isDark,
            accent: accent,
          ),
        ),
      if (topLiftE1rmLbs != null)
        _ScalarTile(
          child: BigStat(
            value: '${topLiftE1rmLbs.round()} lbs',
            label: 'top e1RM · ${topLift!.muscleGroupDisplayName}',
            icon: Icons.bolt,
            isDark: isDark,
            accent: accent,
            delta: strengthDelta,
          ),
        ),
      if (streak > 0)
        _ScalarTile(
          child: BigStat(
            value: streak.toString(),
            // Streak fire emoji is the one allowed warm accent per the UX deck.
            label: '🔥 day streak',
            icon: Icons.local_fire_department,
            isDark: isDark,
            accent: accent,
          ),
        ),
      if (hasRoi && roi.totalWorkoutTimeHours > 0)
        _ScalarTile(
          child: BigStat(
            value: _formatHours(roi.totalWorkoutTimeHours),
            label: 'time trained',
            icon: Icons.timer_outlined,
            isDark: isDark,
            accent: accent,
          ),
        ),
    ];

    // If every acts-on metric is empty (e.g. sessions exist but scores haven't
    // computed weekly sets yet), fall back to the lifetime totals so the strip
    // is never blank for a user with sessions.
    if (tiles.isEmpty) {
      tiles.add(
        _ScalarTile(
          child: BigStat(
            value: hasRoi ? roi.totalWorkoutsCompleted.toString() : '--',
            label: 'workouts',
            icon: Icons.check_circle_outline,
            isDark: isDark,
            accent: accent,
          ),
        ),
      );
    }

    return StatCardShell(
      isDark: isDark,
      // The whole strip is a tap target into the full Stats screen, matching
      // the section's "See all" affordance. InkWell sits inside the card so the
      // ripple is clipped to the card's rounded shape by StatCardShell.
      child: InkWell(
        onTap: () {
          HapticService.light();
          context.push('/stats');
        },
        borderRadius: BorderRadius.circular(16),
        child: Wrap(
          spacing: 24,
          runSpacing: 18,
          children: tiles,
        ),
      ),
    );
  }
}

/// A scalar tile that fills the available width so the strip reads as a single
/// full-width card (matching the cards above it) rather than a cluster of
/// narrow chips. The [Wrap] then lays the tiles out one per row.
class _ScalarTile extends StatelessWidget {
  final Widget child;
  const _ScalarTile({required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SizedBox(
        width: constraints.maxWidth,
        child: child,
      ),
    );
  }
}
