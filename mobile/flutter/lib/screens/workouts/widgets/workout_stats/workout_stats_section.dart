import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/user_provider.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/widgets/skeleton/skeleton_box.dart';
import '../../../../data/models/consistency.dart';
import '../../../../data/models/e1rm_trend.dart';
import '../../../../data/models/scores.dart';
import '../../../../data/models/training_insight.dart';
import '../../../../data/providers/consistency_provider.dart';
import '../../../../data/providers/e1rm_trend_provider.dart';
import '../../../../data/providers/fueling_split_provider.dart';
import '../../../../data/providers/milestones_provider.dart';
import '../../../../data/providers/scores_provider.dart';
import '../../../../data/providers/training_insight_provider.dart';
import '../../../../data/providers/trend_series_provider.dart';
import '../../../../data/providers/workout_volume_trend_provider.dart';
import '../../../../data/repositories/training_load_repository.dart';
import '../../../../data/services/haptic_service.dart';
import '../../../../shareables/widgets/anatomical_figure.dart';
import '../../../../widgets/activity_heatmap.dart';
import '../../../../widgets/charts/mini_sparkline.dart';
import '../../../../widgets/stats/big_stat.dart';
import '../../../../widgets/stats/fueling_split_card.dart';
import '../../../../widgets/stats/stat_delta_chip.dart';
import '../../../../widgets/stats/stat_section_shell.dart';
import '../../../../widgets/workout_day_detail_sheet.dart';

part 'workout_stats_ai_insight.dart';
part 'workout_stats_scalar_strip.dart';
part 'workout_stats_trend_chart.dart';
part 'workout_stats_muscle_balance.dart';
part 'workout_stats_strength_eta.dart';
part 'workout_stats_timing.dart';
part 'workout_stats_activity_heatmap.dart';
part 'workout_stats_recent_prs.dart';
part 'workout_stats_body_heatmap.dart';

/// The "TRAINING STATS" section on the Workout tab.
///
/// This is the orchestrator: it lays out every card top-to-bottom inside a
/// single [Column] (each block padded horizontally 16, with 16px vertical gaps)
/// and kicks off the data loads its cards need. The Workout tab does NOT load
/// the scores / milestones / consistency notifiers on its own (those are owned
/// by the Stats screen), so this section primes them once on mount. The actual
/// rendering is delegated to small [ConsumerWidget]s in the `part` files, each
/// of which handles its own loading / empty / error state so one missing
/// provider can never blank the whole section.
///
/// No fabricated numbers anywhere: every card shows real provider data, an
/// explicit empty state, or a skeleton.
class WorkoutStatsSection extends ConsumerStatefulWidget {
  const WorkoutStatsSection({super.key});

  @override
  ConsumerState<WorkoutStatsSection> createState() =>
      _WorkoutStatsSectionState();
}

class _WorkoutStatsSectionState extends ConsumerState<WorkoutStatsSection> {
  bool _primed = false;

  @override
  void initState() {
    super.initState();
    // Prime the StateNotifier-backed providers after first frame. FutureProvider
    // cards (volume trend, fueling, training insight, training load) self-fetch
    // when first watched, so they need no priming here.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _primeLoads();
    });
  }

  Future<void> _primeLoads() async {
    if (_primed || !mounted) return;
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    _primed = true;

    // Cache-first: seed the StateNotifiers from disk so the section paints the
    // last-known numbers INSTANTLY (no skeleton wall), then only fire the
    // network calls for slices that are still cold. Re-entering the Workouts
    // tab with warm caches skips the full fan-out entirely.
    await ref.read(scoresProvider.notifier).seedFromDisk(userId: userId);
    await ref.read(milestonesProvider.notifier).seedFromDisk(userId: userId);
    if (!mounted) return;

    final scores = ref.read(scoresProvider);
    final milestones = ref.read(milestonesProvider);

    // Scores: overview + strength + PRs + fitness. Skip when overview is warm.
    if (scores.overview == null) {
      ref.read(scoresProvider.notifier).loadAllScores(userId: userId);
    }
    // Readiness history powers the trend-chart overlay line.
    if (scores.readinessHistory == null) {
      ref
          .read(scoresProvider.notifier)
          .loadReadinessHistory(userId: userId, days: 30);
    }
    // Consistency: insights (streak / best day / patterns) + weekly metrics.
    // Owned elsewhere — let its own cache-first logic decide; prime as before.
    ref.read(consistencyProvider.notifier).loadInsights(userId: userId);
    // Milestones: ROI metrics drive the scalar strip (workouts / time / weight).
    if (milestones.roiMetrics == null) {
      ref.read(milestonesProvider.notifier).loadROIMetrics(userId: userId);
    }
    if (milestones.milestones == null) {
      ref
          .read(milestonesProvider.notifier)
          .loadMilestoneProgress(userId: userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Retry priming if the user id was not ready on the first frame (e.g. cold
    // start where auth resolves slightly after this widget mounts).
    if (!_primed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _primeLoads();
      });
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = ref.colors(context).accent;

    Widget pad(Widget child) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: child,
        );

    const gap = SizedBox(height: 16);

    // Zero-data gate. A brand-new user (no logged workouts) would otherwise see
    // a stack of near-identical grey "log a workout to unlock this" cards.
    // Instead, show ONE consolidated empty state until we KNOW there is data.
    //
    // The gate fires when ROI is null (still loading / unknown) OR reports zero
    // completed workouts. Showing the single zero-state while loading (rather
    // than the per-card wall) is the correct first impression: a returning user
    // with cached data sees their strip instantly (roi is primed cache-first),
    // and a genuinely-empty user never sees a "wall of nulls". Once ROI loads
    // with >=1 completed workout, the curated card set renders.
    final roi = ref.watch(
      milestonesProvider.select((s) => s.roiMetrics),
    );
    final bool hasNoSessions = roi == null || roi.totalWorkoutsCompleted == 0;

    // Curated inline card set (research-backed, progressive disclosure):
    //   A. Compact stat strip (always shown for a user with sessions)
    //   B. Muscle balance with 10-20 sets/muscle/week productive band
    //   C. AI insight strip (self-hides when empty)
    //   D. Activity heatmap (consistency)
    //   E. Recent PRs (renders nothing until the first PR exists)
    // Each card collapses to SizedBox.shrink() when its own data is empty, and
    // we build the children list dynamically so a collapsed card never leaves
    // an orphaned 16px gap behind it. The deep-dive cards (trend chart, fueling,
    // timing, body heatmap, detailed strength ETA) now live on /stats only (see
    // WorkoutStatsDeepDive) so nothing is lost.
    //
    // Emptiness is computed from the same public providers the cards read, so
    // the section can decide whether to insert the leading gap before each card
    // without duplicating card-internal logic.
    final muscleScores = ref.watch(muscleScoresProvider);
    final muscleTotalSets =
        muscleScores.values.fold<int>(0, (sum, m) => sum + m.weeklySets);
    final hasMuscleBalance = muscleTotalSets > 0;

    final recentPrs = ref.watch(prStatsProvider)?.recentPrs ?? const [];
    final hasPrs = recentPrs.isNotEmpty;

    final children = <Widget>[
      StatSectionHeader(
        title: 'Training stats',
        isDark: isDark,
        onSeeAll: () => context.push('/stats'),
        // Custom-trends entry, collapsed from the old full-width card into a
        // compact icon beside "See all". Seeds with whatever metric the trend
        // chart would show (Volume / Sessions / Time). The trend chart itself
        // now lives on /stats, but custom trends stays reachable here.
        trendsAccent: accent,
        onTrendsTap: () => context.push(
          '/trends/custom',
          extra: ref.read(_trendSegmentProvider).trendMetric,
        ),
      ),
      const SizedBox(height: 8),
    ];

    if (hasNoSessions) {
      children
        ..add(pad(_StatsZeroState(isDark: isDark, accent: accent)))
        ..add(const SizedBox(height: 8));
    } else {
      // C. AI insight strip first (self-hides when empty; when it hides it is
      // the only always-first element, so no orphan gap before A).
      children.add(pad(_AiInsightStrip(isDark: isDark, accent: accent)));

      // A. Compact stat strip — the one always-present element for a user with
      // sessions (sets/volume this week · consistency · top-lift e1RM delta).
      children
        ..add(gap)
        ..add(pad(_ScalarStrip(isDark: isDark, accent: accent)));

      // B. Muscle balance with the productive band — only when there are sets.
      if (hasMuscleBalance) {
        children
          ..add(gap)
          ..add(pad(RepaintBoundary(
            child: _MuscleBalanceCard(isDark: isDark, accent: accent),
          )));
      }

      // D. Activity heatmap (consistency) — always shown for a user with
      // sessions; it self-loads and renders its own grid + states.
      children
        ..add(gap)
        ..add(pad(RepaintBoundary(
          child: _ActivityHeatmapCard(isDark: isDark),
        )));

      // E. Recent PRs — only when at least one real PR exists.
      if (hasPrs) {
        children
          ..add(gap)
          ..add(_RecentPrsRow(isDark: isDark, accent: accent));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

/// The deep-dive training-stats stack, relocated off the Workout tab to the
/// /stats Overview tab. Renders the cards that were curated OUT of the inline
/// section (trend chart, fueling split, detailed strength-by-muscle + e1RM,
/// best training time, body-diagram heatmap) using the EXACT same part-file
/// widgets, so there is zero divergence between the two surfaces. It primes the
/// StateNotifier-backed providers itself (the /stats screen also primes them,
/// but priming twice is idempotent and keeps this widget self-contained).
class WorkoutStatsDeepDive extends ConsumerStatefulWidget {
  final bool isDark;
  final Color accent;

  const WorkoutStatsDeepDive({
    super.key,
    required this.isDark,
    required this.accent,
  });

  @override
  ConsumerState<WorkoutStatsDeepDive> createState() =>
      _WorkoutStatsDeepDiveState();
}

class _WorkoutStatsDeepDiveState extends ConsumerState<WorkoutStatsDeepDive> {
  bool _primed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _primeLoads());
  }

  void _primeLoads() {
    if (_primed || !mounted) return;
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    _primed = true;
    ref.read(scoresProvider.notifier).loadAllScores(userId: userId);
    ref
        .read(scoresProvider.notifier)
        .loadReadinessHistory(userId: userId, days: 30);
    ref.read(consistencyProvider.notifier).loadInsights(userId: userId);
    ref.read(milestonesProvider.notifier).loadROIMetrics(userId: userId);
  }

  @override
  Widget build(BuildContext context) {
    if (!_primed) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _primeLoads());
    }

    final isDark = widget.isDark;
    final accent = widget.accent;
    const gap = SizedBox(height: 16);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Trend chart (volume / sessions / time + readiness overlay + ACWR).
        RepaintBoundary(child: _TrendChartCard(isDark: isDark, accent: accent)),
        // Fueling: training vs rest day (shared card).
        gap,
        RepaintBoundary(
          child: FuelingSplitCard(
            fueling: ref.watch(fuelingSplitProvider),
            isDark: isDark,
            accent: accent,
          ),
        ),
        // Strength level by muscle + e1RM (detailed).
        gap,
        RepaintBoundary(child: _StrengthEtaCard(isDark: isDark, accent: accent)),
        // Best training time + streak-risk nudge.
        gap,
        _TimingCard(isDark: isDark, accent: accent),
        // Body-diagram heatmap (reuses the shared AnatomicalFigure).
        gap,
        RepaintBoundary(child: _BodyHeatmapCard(isDark: isDark, accent: accent)),
      ],
    );
  }
}

/// Single consolidated empty state shown when the user has zero logged
/// workouts, replacing the column of ~7 individual "no data yet" cards.
/// Polished M3 card: accent-tinted icon badge + title + supporting line.
class _StatsZeroState extends StatelessWidget {
  final bool isDark;
  final Color accent;

  const _StatsZeroState({required this.isDark, required this.accent});

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final border = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.insights_rounded, color: accent, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            'Your training stats unlock here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Log your first workout to start tracking volume, streaks, '
            'strength, and more.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Shared small helpers used across the part files.
// ─────────────────────────────────────────────────────────────────────────

/// A one-line shimmer placeholder sized to a card body.
class _CardSkeleton extends StatelessWidget {
  final double height;
  const _CardSkeleton({this.height = 56});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: const Align(
        alignment: Alignment.centerLeft,
        child: SkeletonBox(height: 16),
      ),
    );
  }
}

/// kg → lbs. Lifted volume is always shown in lbs per project rule.
double _kgToLbs(double kg) => kg * 2.20462;

/// Hours → "96h" or "3h 40m". Real ROI time only; never an estimate.
String _formatHours(double hours) {
  if (hours <= 0) return '0m';
  final totalMinutes = (hours * 60).round();
  final h = totalMinutes ~/ 60;
  final m = totalMinutes % 60;
  if (h == 0) return '${m}m';
  if (m == 0) return '${h}h';
  if (h >= 100) return '${h}h';
  return '${h}h ${m}m';
}
