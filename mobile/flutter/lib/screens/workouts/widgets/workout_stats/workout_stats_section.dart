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
    WidgetsBinding.instance.addPostFrameCallback((_) => _primeLoads());
  }

  void _primeLoads() {
    if (_primed || !mounted) return;
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    _primed = true;

    // Scores: overview + strength + PRs + fitness + readiness overview.
    ref.read(scoresProvider.notifier).loadAllScores(userId: userId);
    // Readiness history powers the trend-chart overlay line.
    ref
        .read(scoresProvider.notifier)
        .loadReadinessHistory(userId: userId, days: 30);
    // Consistency: insights (streak / best day / patterns) + weekly metrics.
    ref.read(consistencyProvider.notifier).loadInsights(userId: userId);
    // Milestones: ROI metrics drive the scalar strip (workouts / time / weight).
    ref.read(milestonesProvider.notifier).loadROIMetrics(userId: userId);
    ref.read(milestonesProvider.notifier).loadMilestoneProgress(userId: userId);
  }

  @override
  Widget build(BuildContext context) {
    // Retry priming if the user id was not ready on the first frame (e.g. cold
    // start where auth resolves slightly after this widget mounts).
    if (!_primed) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _primeLoads());
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = ref.colors(context).accent;

    Widget pad(Widget child) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: child,
        );

    const gap = SizedBox(height: 16);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StatSectionHeader(
          title: 'Training stats',
          isDark: isDark,
          onSeeAll: () => context.push('/stats'),
          // Custom-trends entry, collapsed from the old full-width card into a
          // compact icon beside "See all". Seeds with whatever metric the
          // trend chart is currently showing (Volume / Sessions / Time).
          trendsAccent: accent,
          onTrendsTap: () => context.push(
            '/trends/custom',
            extra: ref.read(_trendSegmentProvider).trendMetric,
          ),
        ),
        const SizedBox(height: 8),

        // 1. AI insight strip (hides itself when empty).
        pad(_AiInsightStrip(isDark: isDark, accent: accent)),

        // 2. Scalar strip (workouts / streak / strength / time).
        gap,
        pad(_ScalarStrip(isDark: isDark, accent: accent)),

        // 3. Trend chart (volume / sessions / time + readiness overlay + ACWR).
        gap,
        pad(RepaintBoundary(
          child: _TrendChartCard(isDark: isDark, accent: accent),
        )),

        // 4. Push / pull / legs / core muscle balance.
        gap,
        pad(RepaintBoundary(
          child: _MuscleBalanceCard(isDark: isDark, accent: accent),
        )),

        // 5. Fueling: training vs rest day (shared card).
        gap,
        pad(RepaintBoundary(
          child: FuelingSplitCard(
            fueling: ref.watch(fuelingSplitProvider),
            isDark: isDark,
            accent: accent,
          ),
        )),

        // 6. Strength level by muscle + e1RM.
        gap,
        pad(RepaintBoundary(
          child: _StrengthEtaCard(isDark: isDark, accent: accent),
        )),

        // 7. Best training time + streak-risk nudge.
        gap,
        pad(_TimingCard(isDark: isDark, accent: accent)),

        // 8. Body-diagram heatmap (reuses the shared AnatomicalFigure).
        gap,
        pad(RepaintBoundary(
          child: _BodyHeatmapCard(isDark: isDark, accent: accent),
        )),

        // 9. Activity heatmap (reuses the shared ActivityHeatmap widget).
        gap,
        pad(RepaintBoundary(
          child: _ActivityHeatmapCard(isDark: isDark),
        )),

        // 10. Recent PRs (horizontal scroll of chips).
        // Custom trends now lives as a compact icon in the section header
        // (beside "See all"), not a full-width card here.
        gap,
        _RecentPrsRow(isDark: isDark, accent: accent),
      ],
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
