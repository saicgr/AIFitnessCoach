import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/user_provider.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/utils/weight_utils.dart';
import '../../../core/widgets/skeleton/skeleton.dart';
import '../../../data/models/exercise_history.dart' show ExerciseHistoryTimeRange;
import '../../../data/models/overload_dashboard.dart';
import '../../../data/providers/gym_profile_provider.dart';
import '../../../data/providers/overload_dashboard_provider.dart';
import '../../../widgets/design_system/section_header.dart';
import '../../../widgets/design_system/zealova.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../widgets/trends/trend_chart.dart';
import '../../../widgets/trends/trend_correlation.dart';

/// =========================================================================
/// Progressive Overload Dashboard (T1 hero / T2 radar / T3 per-exercise)
/// =========================================================================
///
/// A read-only progress surface that answers "am I actually getting stronger?"
/// in three tiers:
///   T1  Overall strength score hero — big Anton numeral, level + DOTS
///       percentile, 30d/365d deltas, sparkline, and a "last workout moved …"
///       line from the post-workout muscle deltas.
///   T2  16-axis muscle radar + a tappable legend list. Tapping a muscle opens
///       a glass drill-down sheet listing its contributing exercises.
///   T3  Per top-exercise cards: an EWMA-smoothed e1RM trend with start /
///       current / all-time-best reference lines, weight delta, and a volume
///       trend.
///
/// No mock / fallback data (project rule): loading → skeleton, error → retry,
/// empty → an explicit hint. Stale-while-revalidate via
/// [overloadDashboardProvider] (instant from cache, silent refresh).
///
/// Hosted as a tab inside `ComprehensiveStatsScreen` (so it has no app bar of
/// its own — just the body), and reachable via the hero entry card on the
/// Stats overview tab.
class ProgressiveOverloadDashboardScreen extends ConsumerStatefulWidget {
  const ProgressiveOverloadDashboardScreen({super.key});

  @override
  ConsumerState<ProgressiveOverloadDashboardScreen> createState() =>
      _ProgressiveOverloadDashboardScreenState();
}

/// Canonical 16 muscle groups in radar render order (front chain → back chain →
/// arms → legs → trunk). Every axis is always present (zero-filled where the
/// payload omits it) — RadarChart needs ≥3 axes and a stable axis count.
const List<String> _kMuscleOrder = [
  'chest',
  'shoulders',
  'rear_delts',
  'back',
  'traps',
  'biceps',
  'triceps',
  'forearms',
  'quads',
  'hamstrings',
  'glutes',
  'adductors',
  'calves',
  'core',
  'obliques',
  'lower_back',
];

class _ProgressiveOverloadDashboardScreenState
    extends ConsumerState<ProgressiveOverloadDashboardScreen> {
  bool _kickedOff = false;

  @override
  void initState() {
    super.initState();
    // Seed-from-disk then refresh after the first frame (so we never read a
    // provider mid-build). Guarded so a rebuild doesn't re-fire.
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    if (_kickedOff || !mounted) return;
    _kickedOff = true;
    final range = ref.read(overloadTimeRangeProvider);
    final gymId = ref.read(activeGymProfileIdProvider);
    final notifier = ref.read(overloadDashboardProvider.notifier);
    await notifier.seedFromDisk(range, gymProfileId: gymId);
    if (!mounted) return;
    await notifier.load(range, gymProfileId: gymId);
  }

  Future<void> _onRangeChanged(ExerciseHistoryTimeRange range) async {
    ref.read(overloadTimeRangeProvider.notifier).state = range;
    final gymId = ref.read(activeGymProfileIdProvider);
    final notifier = ref.read(overloadDashboardProvider.notifier);
    await notifier.seedFromDisk(range, gymProfileId: gymId);
    if (!mounted) return;
    await notifier.load(range, gymProfileId: gymId);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(overloadDashboardProvider);
    final range = ref.watch(overloadTimeRangeProvider);
    final colors = ThemeColors.of(context);
    final dashboard = state.dashboard;

    // Error with NO data to fall back on → retry surface (no silent fallback).
    if (dashboard == null && state.error != null) {
      return _ErrorRetry(
        message: state.error!,
        onRetry: _bootstrap,
      );
    }

    // First-ever load (no cache) → layout-matched skeleton.
    if (dashboard == null) {
      return _DashboardSkeleton(range: range, onRangeChanged: _onRangeChanged);
    }

    // Real data present but genuinely empty → explicit hint (not an all-zero
    // dashboard that reads as broken).
    if (dashboard.isEmpty) {
      return Column(
        children: [
          _RangeBar(range: range, onChanged: _onRangeChanged),
          Expanded(
            child: _EmptyHint(
              icon: Icons.trending_up_rounded,
              title: 'No overload data yet',
              body: 'Log a few weighted workouts and your strength trend, '
                  'muscle radar, and lift progress will build here.',
            ),
          ),
        ],
      );
    }

    final useKg = ref.watch(useKgForWorkoutProvider);

    return Column(
      children: [
        _RangeBar(range: range, onChanged: _onRangeChanged),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            children: [
              // ── T1: HERO ──────────────────────────────────────────────
              _OverallHeroCard(overall: dashboard.overall, colors: colors),
              if (dashboard.lastWorkout != null &&
                  dashboard.lastWorkout!.muscleDeltas.isNotEmpty) ...[
                const SizedBox(height: 10),
                _LastWorkoutLine(lastWorkout: dashboard.lastWorkout!),
              ],

              // ── T2: MUSCLE RADAR ──────────────────────────────────────
              const SectionHeader(
                label: 'Strength by muscle',
                padding: EdgeInsets.only(top: 26, bottom: 10),
              ),
              _MuscleRadarCard(
                muscles: dashboard.muscles,
                colors: colors,
                onTapMuscle: _openMuscleSheet,
              ),

              // ── T3: PER-EXERCISE ──────────────────────────────────────
              if (dashboard.topExercises.isNotEmpty) ...[
                const SectionHeader(
                  label: 'Lift progress',
                  padding: EdgeInsets.only(top: 26, bottom: 10),
                ),
                for (final ex in dashboard.topExercises) ...[
                  _ExerciseProgressCard(
                    exercise: ex,
                    useKg: useKg,
                    colors: colors,
                  ),
                  const SizedBox(height: 12),
                ],
              ],

              // ── Recent PRs (compact ledger) ───────────────────────────
              if (dashboard.recentPrs.isNotEmpty) ...[
                const SectionHeader(
                  label: 'Recent PRs',
                  padding: EdgeInsets.only(top: 12, bottom: 10),
                ),
                _RecentPrsCard(prs: dashboard.recentPrs, useKg: useKg),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openMuscleSheet(OverloadMuscle muscle) async {
    final gymId = ref.read(activeGymProfileIdProvider);
    final useKg = ref.read(useKgForWorkoutProvider);
    await showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (_) => GlassSheet(
        child: _MuscleDetailSheet(
          muscle: muscle,
          gymProfileId: gymId,
          useKg: useKg,
          // Capture the notifier reference up-front; the sheet builds in the
          // root navigator's context where our ref isn't available.
          loadDetail: (mg) => ref
              .read(overloadDashboardProvider.notifier)
              .loadMuscleDetail(mg, gymProfileId: gymId),
        ),
      ),
    );
  }
}

// ============================================================================
// Time-range bar
// ============================================================================

/// Compact range bar restricted to the dashboard's meaningful spans. Maps the
/// human labels to [ExerciseHistoryTimeRange] (whose `.value` already matches
/// the backend `time_range` params).
class _RangeBar extends StatelessWidget {
  final ExerciseHistoryTimeRange range;
  final ValueChanged<ExerciseHistoryTimeRange> onChanged;
  const _RangeBar({required this.range, required this.onChanged});

  static const _options = <(ExerciseHistoryTimeRange, String)>[
    (ExerciseHistoryTimeRange.fourWeeks, '1M'),
    (ExerciseHistoryTimeRange.twelveWeeks, '3M'),
    (ExerciseHistoryTimeRange.sixMonths, '6M'),
    (ExerciseHistoryTimeRange.oneYear, '1Y'),
    (ExerciseHistoryTimeRange.allTime, 'All'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Row(
        children: [
          for (final opt in _options) ...[
            ZealovaChip(
              label: opt.$2,
              selected: opt.$1 == range,
              onTap: () => onChanged(opt.$1),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// T1 — Overall hero
// ============================================================================

class _OverallHeroCard extends StatelessWidget {
  final OverloadOverall overall;
  final ThemeColors colors;
  const _OverallHeroCard({required this.overall, required this.colors});

  @override
  Widget build(BuildContext context) {
    final spark = [
      for (final p in overall.sparkline)
        TrendPoint(date: p.date, value: p.score.toDouble()),
    ];

    return ZealovaCard(
      variant: ZealovaCardVariant.hero,
      padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('OVERALL STRENGTH',
              style: ZType.lbl(11, color: colors.textMuted, letterSpacing: 2)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${overall.score}',
                style: ZType.disp(56, color: colors.textPrimary),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LevelChip(level: overall.level, colors: colors),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _DeltaChip(delta: overall.delta30d, period: '30d', colors: colors),
                        const SizedBox(width: 6),
                        _DeltaChip(delta: overall.delta365d, period: '1y', colors: colors),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (overall.percentile > 0) ...[
            const SizedBox(height: 6),
            Text(
              'Stronger than ${overall.percentile.round()}% of comparable lifters',
              style: TextStyle(
                fontSize: 12.5,
                color: colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (spark.length >= 2) ...[
            const SizedBox(height: 14),
            TrendChart(
              primary: TrendChartSeries(
                label: 'Strength',
                unit: 'pts',
                points: spark,
                color: colors.accent,
                smoothingAlpha: 0.3,
              ),
              accent: colors.accent,
              showBuiltInChrome: false,
              height: 96,
            ),
          ],
        ],
      ),
    );
  }
}

/// Small-caps level chip (beginner/intermediate/advanced/elite).
class _LevelChip extends StatelessWidget {
  final String level;
  final ThemeColors colors;
  const _LevelChip({required this.level, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: colors.accent.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        level.replaceAll('_', ' ').toUpperCase(),
        style: ZType.lbl(10, color: colors.accent, letterSpacing: 1.4),
      ),
    );
  }
}

/// 30d / 1y delta chip. Up → success green, flat/down → muted (never alarming
/// red for a maintained score; declines read muted per the spec).
class _DeltaChip extends StatelessWidget {
  final int delta;
  final String period;
  final ThemeColors colors;
  const _DeltaChip({
    required this.delta,
    required this.period,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final isUp = delta > 0;
    final col = isUp ? colors.success : colors.textMuted;
    final sign = delta > 0 ? '+' : '';
    final icon = isUp
        ? Icons.arrow_upward_rounded
        : (delta < 0 ? Icons.arrow_downward_rounded : Icons.remove_rounded);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: col),
        const SizedBox(width: 1),
        Text(
          '$sign$delta',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: col,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          period,
          style: ZType.lbl(9, color: colors.textMuted, letterSpacing: 1),
        ),
      ],
    );
  }
}

/// "Last workout moved Chest +3, Back +1" line under the hero.
class _LastWorkoutLine extends StatelessWidget {
  final OverloadLastWorkout lastWorkout;
  const _LastWorkoutLine({required this.lastWorkout});

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    // Rank by absolute change, keep the top 3 movers.
    final deltas = [...lastWorkout.muscleDeltas]
      ..sort((a, b) => b.scoreChange.abs().compareTo(a.scoreChange.abs()));
    final top = deltas.where((d) => d.scoreChange != 0).take(3).toList();
    if (top.isEmpty) return const SizedBox.shrink();

    final parts = top
        .map((d) =>
            '${_prettyMuscle(d.muscleGroup)} ${d.scoreChange > 0 ? '+' : ''}${d.scoreChange}')
        .join(', ');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.bolt_rounded, size: 15, color: colors.accent),
        const SizedBox(width: 6),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 12.5, color: colors.textSecondary),
              children: [
                const TextSpan(text: 'Last workout moved '),
                TextSpan(
                  text: parts,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// T2 — Muscle radar + legend
// ============================================================================

class _MuscleRadarCard extends StatelessWidget {
  final List<OverloadMuscle> muscles;
  final ThemeColors colors;
  final ValueChanged<OverloadMuscle> onTapMuscle;
  const _MuscleRadarCard({
    required this.muscles,
    required this.colors,
    required this.onTapMuscle,
  });

  @override
  Widget build(BuildContext context) {
    // Index the payload by muscle so we can zero-fill the full 16-axis set.
    final byGroup = {for (final m in muscles) m.muscleGroup: m};
    final values = [
      for (final mg in _kMuscleOrder)
        (byGroup[mg]?.currentScore ?? 0).toDouble(),
    ];
    final labels = [for (final mg in _kMuscleOrder) _shortMuscle(mg)];
    final accent = colors.accent;

    // "No shape yet" guard — every axis < 5% of full. fl_chart otherwise draws
    // a tiny regular polygon at the origin that reads as a real shape.
    final isFlat = values.every((v) => v < 5);
    // Stable scale anchor so the shape doesn't rescale between renders.
    final anchorMax =
        [...values, 100.0].reduce((a, b) => a > b ? a : b);

    return ZealovaCard(
      variant: ZealovaCardVariant.outlined,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
      child: Column(
        children: [
          SizedBox(
            height: 260,
            child: Stack(
              alignment: Alignment.center,
              children: [
                RadarChart(
                  RadarChartData(
                    radarShape: RadarShape.polygon,
                    tickCount: 4,
                    ticksTextStyle: const TextStyle(
                      color: Colors.transparent,
                      fontSize: 1,
                    ),
                    gridBorderData: BorderSide(
                      color: colors.cardBorder.withValues(alpha: 0.5),
                      width: 0.6,
                    ),
                    radarBorderData: BorderSide(
                      color: colors.cardBorder.withValues(alpha: 0.7),
                      width: 0.7,
                    ),
                    tickBorderData: BorderSide(
                      color: colors.cardBorder.withValues(alpha: 0.3),
                      width: 0.4,
                    ),
                    titleTextStyle: TextStyle(
                      color: colors.textMuted,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                    ),
                    titlePositionPercentageOffset: 0.13,
                    getTitle: (index, angle) =>
                        RadarChartTitle(text: labels[index], angle: 0),
                    dataSets: [
                      // Hidden anchor — pins max scale (Issue 9 pattern from
                      // the discover radar).
                      RadarDataSet(
                        fillColor: Colors.transparent,
                        borderColor: Colors.transparent,
                        borderWidth: 0,
                        entryRadius: 0,
                        dataEntries: List.generate(
                          labels.length,
                          (_) => RadarEntry(value: anchorMax),
                        ),
                      ),
                      if (!isFlat)
                        RadarDataSet(
                          fillColor: accent.withValues(alpha: 0.28),
                          borderColor: accent,
                          borderWidth: 2.4,
                          entryRadius: 2.5,
                          dataEntries:
                              values.map((v) => RadarEntry(value: v)).toList(),
                        )
                      else
                        RadarDataSet(
                          fillColor: Colors.transparent,
                          borderColor: Colors.transparent,
                          borderWidth: 0,
                          entryRadius: 0,
                          dataEntries: values
                              .map((_) => const RadarEntry(value: 0))
                              .toList(),
                        ),
                    ],
                  ),
                ),
                if (isFlat)
                  IgnorePointer(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.insights_rounded,
                              size: 30,
                              color: colors.textMuted.withValues(alpha: 0.6)),
                          const SizedBox(height: 8),
                          Text(
                            'Your muscle map builds as you log lifts',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Legend list — tappable rows (radar axis taps are finicky, so the
          // drill-down affordance lives here).
          _MuscleLegend(
            order: _kMuscleOrder,
            byGroup: byGroup,
            colors: colors,
            onTap: onTapMuscle,
          ),
        ],
      ),
    );
  }
}

class _MuscleLegend extends StatelessWidget {
  final List<String> order;
  final Map<String, OverloadMuscle> byGroup;
  final ThemeColors colors;
  final ValueChanged<OverloadMuscle> onTap;
  const _MuscleLegend({
    required this.order,
    required this.byGroup,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Show the muscles that actually have a score, ranked by score desc; the
    // rest collapse into a muted "+N more" affordance below.
    final present = [
      for (final mg in order)
        if (byGroup[mg] != null && byGroup[mg]!.currentScore > 0) byGroup[mg]!,
    ]..sort((a, b) => b.currentScore.compareTo(a.currentScore));

    if (present.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        for (final m in present)
          InkWell(
            onTap: () => onTap(m),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _prettyMuscle(m.muscleGroup),
                      style: TextStyle(
                        fontSize: 13.5,
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (m.isEstablishing)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        'EST.',
                        style: ZType.lbl(8.5,
                            color: colors.textMuted, letterSpacing: 1),
                      ),
                    ),
                  _MiniDelta(change: m.scoreChange, colors: colors),
                  const SizedBox(width: 10),
                  Text(
                    '${m.currentScore}',
                    style: ZType.data(15, color: colors.textPrimary),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded,
                      size: 18, color: colors.textMuted),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _MiniDelta extends StatelessWidget {
  final int change;
  final ThemeColors colors;
  const _MiniDelta({required this.change, required this.colors});

  @override
  Widget build(BuildContext context) {
    if (change == 0) {
      return Text('—',
          style: TextStyle(fontSize: 12, color: colors.textMuted));
    }
    final isUp = change > 0;
    final col = isUp ? colors.success : colors.textMuted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 11, color: col),
        Text(
          '${change.abs()}',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: col),
        ),
      ],
    );
  }
}

// ============================================================================
// T2 — Per-muscle drill-down sheet
// ============================================================================

class _MuscleDetailSheet extends StatefulWidget {
  final OverloadMuscle muscle;
  final String? gymProfileId;
  final bool useKg;
  final Future<OverloadMuscleDetail?> Function(String muscleGroup) loadDetail;

  const _MuscleDetailSheet({
    required this.muscle,
    required this.gymProfileId,
    required this.useKg,
    required this.loadDetail,
  });

  @override
  State<_MuscleDetailSheet> createState() => _MuscleDetailSheetState();
}

class _MuscleDetailSheetState extends State<_MuscleDetailSheet> {
  OverloadMuscleDetail? _detail;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    final detail = await widget.loadDetail(widget.muscle.muscleGroup);
    if (!mounted) return;
    setState(() {
      _detail = detail;
      _loading = false;
      _failed = detail == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final m = widget.muscle;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  _prettyMuscle(m.muscleGroup),
                  style: ZType.disp(26, color: colors.textPrimary),
                ),
              ),
              Text('${m.currentScore}',
                  style: ZType.disp(30, color: colors.accent)),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('PTS',
                    style: ZType.lbl(9,
                        color: colors.textMuted, letterSpacing: 1)),
              ),
            ],
          ),
          if (m.populationPercentile > 0) ...[
            const SizedBox(height: 4),
            Text(
              'Stronger than ${m.populationPercentile.round()}% of lifters',
              style: TextStyle(fontSize: 12.5, color: colors.textSecondary),
            ),
          ],
          const SizedBox(height: 16),
          Text('CONTRIBUTING EXERCISES',
              style: ZType.lbl(10.5,
                  color: colors.textMuted, letterSpacing: 1.6)),
          const SizedBox(height: 10),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  SkeletonBox(height: 44, radius: 10),
                  SizedBox(height: 8),
                  SkeletonBox(height: 44, radius: 10),
                  SizedBox(height: 8),
                  SkeletonBox(height: 44, radius: 10),
                ],
              ),
            )
          else if (_failed)
            _SheetMessage(
              icon: Icons.cloud_off_rounded,
              text: "Couldn't load this muscle's detail.",
              actionLabel: 'Retry',
              onAction: _fetch,
              colors: colors,
            )
          else if ((_detail?.contributingExercises.isEmpty ?? true))
            _SheetMessage(
              icon: Icons.fitness_center_rounded,
              text: _detail?.emptyStateHint ??
                  'No exercises feed this muscle yet. Log a few sets that '
                      'train it and they will appear here.',
              colors: colors,
            )
          else
            ..._detail!.contributingExercises.map(
              (e) => _ContributingRow(
                exercise: e,
                useKg: widget.useKg,
                colors: colors,
              ),
            ),
        ],
      ),
    );
  }
}

class _ContributingRow extends StatelessWidget {
  final ContributingExercise exercise;
  final bool useKg;
  final ThemeColors colors;
  const _ContributingRow({
    required this.exercise,
    required this.useKg,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final e1rm = WeightUtils.formatWorkoutWeight(
      exercise.bestE1rmKg,
      useKg: useKg,
    );
    final sets = exercise.weeklySets;
    final setsStr = sets == sets.roundToDouble()
        ? sets.toInt().toString()
        : sets.toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  exercise.exerciseName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${exercise.contributionPct.round()}%',
                style: ZType.data(13, color: colors.accent),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Text(
                '$e1rm e1RM',
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
              ),
              const SizedBox(width: 12),
              Text(
                '$setsStr sets/wk',
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
              ),
            ],
          ),
          if (exercise.isMachineDerived) ...[
            const SizedBox(height: 2),
            Text(
              '(machine-assisted)',
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: colors.textMuted,
              ),
            ),
          ],
          const SizedBox(height: 8),
          // Contribution bar.
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: (exercise.contributionPct / 100).clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: colors.cardBorder.withValues(alpha: 0.4),
              valueColor: AlwaysStoppedAnimation(colors.accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetMessage extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;
  final ThemeColors colors;
  const _SheetMessage({
    required this.icon,
    required this.text,
    required this.colors,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Icon(icon, size: 30, color: colors.textMuted),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// T3 — Per-exercise progress card
// ============================================================================

class _ExerciseProgressCard extends StatelessWidget {
  final OverloadTopExercise exercise;
  final bool useKg;
  final ThemeColors colors;
  const _ExerciseProgressCard({
    required this.exercise,
    required this.useKg,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final e1rmPoints = [
      for (final p in exercise.e1rmSeries)
        TrendPoint(date: p.date, value: p.e1rmKg),
    ];
    final volPoints = [
      for (final p in exercise.e1rmSeries)
        TrendPoint(date: p.date, value: p.volumeKg),
    ];

    final startW = WeightUtils.formatWorkoutWeight(
      exercise.startingWeight,
      useKg: useKg,
    );
    final curW = WeightUtils.formatWorkoutWeight(
      exercise.currentWeight,
      useKg: useKg,
    );
    final pct = exercise.weightChangePct;
    final pctUp = pct > 0.5;
    final pctCol = pctUp
        ? colors.success
        : (pct < -0.5 ? colors.textMuted : colors.textMuted);

    // e1RM reference lines: starting / current / all-time best.
    final bands = <TrendZoneBand>[
      if (exercise.startingE1rm > 0)
        TrendZoneBand(
          value: exercise.startingE1rm,
          label: 'Start',
          color: colors.textMuted,
        ),
      if (exercise.allTimeBestE1rm > 0)
        TrendZoneBand(
          value: exercise.allTimeBestE1rm,
          label: 'Best',
          color: colors.accent,
        ),
    ];

    return ZealovaCard(
      variant: ZealovaCardVariant.outlined,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  exercise.exerciseName,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              _TrendBadge(trend: exercise.trend, colors: colors),
            ],
          ),
          const SizedBox(height: 10),
          // Start → current working weight + % change.
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(startW,
                  style: ZType.data(15, color: colors.textMuted)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_right_alt_rounded,
                    size: 18, color: colors.textMuted),
              ),
              Text(curW, style: ZType.disp(22, color: colors.textPrimary)),
              const Spacer(),
              if (pct.abs() >= 0.5)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      pctUp
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size: 13,
                      color: pctCol,
                    ),
                    Text(
                      '${pct.abs().toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: pctCol,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (e1rmPoints.length >= 2) ...[
            const SizedBox(height: 8),
            Text('EST. 1RM',
                style: ZType.lbl(9.5, color: colors.textMuted, letterSpacing: 1.4)),
            const SizedBox(height: 4),
            TrendChart(
              primary: TrendChartSeries(
                label: 'e1RM',
                unit: useKg ? 'kg' : 'lb',
                points: e1rmPoints,
                color: colors.accent,
                smoothingAlpha: 0.3,
                zoneBands: bands,
              ),
              accent: colors.accent,
              showBuiltInChrome: false,
              height: 150,
            ),
          ],
          if (volPoints.length >= 2 &&
              volPoints.any((p) => p.value > 0)) ...[
            const SizedBox(height: 12),
            Text('VOLUME',
                style: ZType.lbl(9.5, color: colors.textMuted, letterSpacing: 1.4)),
            const SizedBox(height: 4),
            TrendChart(
              primary: TrendChartSeries(
                label: 'Volume',
                unit: useKg ? 'kg' : 'lb',
                points: volPoints,
                color: colors.textSecondary,
                smoothingAlpha: 0.3,
              ),
              accent: colors.textSecondary,
              showBuiltInChrome: false,
              height: 110,
            ),
          ],
        ],
      ),
    );
  }
}

class _TrendBadge extends StatelessWidget {
  final String trend;
  final ThemeColors colors;
  const _TrendBadge({required this.trend, required this.colors});

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color col, String label) = switch (trend) {
      'improving' => (Icons.trending_up_rounded, colors.success, 'IMPROVING'),
      'declining' => (
          Icons.trending_down_rounded,
          colors.textMuted,
          'DECLINING'
        ),
      _ => (Icons.trending_flat_rounded, colors.textMuted, 'STEADY'),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: col),
        const SizedBox(width: 4),
        Text(label, style: ZType.lbl(9.5, color: col, letterSpacing: 1.2)),
      ],
    );
  }
}

// ============================================================================
// Recent PRs
// ============================================================================

class _RecentPrsCard extends StatelessWidget {
  final List<OverloadPr> prs;
  final bool useKg;
  const _RecentPrsCard({required this.prs, required this.useKg});

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    return ZealovaCard(
      variant: ZealovaCardVariant.outlined,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: [
          for (var i = 0; i < prs.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.emoji_events_rounded,
                      size: 16, color: colors.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prs[i].exerciseName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                        if (prs[i].achievedAt != null)
                          Text(
                            DateFormat('MMM d').format(prs[i].achievedAt!),
                            style:
                                TextStyle(fontSize: 11, color: colors.textMuted),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${WeightUtils.formatWorkoutWeight(prs[i].weightKg, useKg: useKg, withUnit: false)} × ${prs[i].reps}',
                        style: ZType.data(14, color: colors.textPrimary),
                      ),
                      Text(
                        '${WeightUtils.formatWorkoutWeight(prs[i].estimated1rmKg, useKg: useKg)} e1RM',
                        style:
                            TextStyle(fontSize: 11, color: colors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (i != prs.length - 1)
              Divider(height: 1, color: colors.cardBorder),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// Loading / error / empty surfaces
// ============================================================================

class _DashboardSkeleton extends StatelessWidget {
  final ExerciseHistoryTimeRange range;
  final ValueChanged<ExerciseHistoryTimeRange> onRangeChanged;
  const _DashboardSkeleton({required this.range, required this.onRangeChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _RangeBar(range: range, onChanged: onRangeChanged),
        const Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SkeletonBox(height: 168, radius: 14),
                SizedBox(height: 26),
                SkeletonBox(height: 320, radius: 14),
                SizedBox(height: 26),
                SkeletonBox(height: 220, radius: 14),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorRetry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 44, color: colors.textMuted),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: colors.textSecondary),
            ),
            const SizedBox(height: 18),
            ZealovaButton(
              label: 'Retry',
              onTap: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _EmptyHint({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 46, color: colors.textMuted),
            const SizedBox(height: 16),
            Text(title,
                style: ZType.disp(20, color: colors.textPrimary),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: colors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Muscle-name helpers
// ============================================================================

String _prettyMuscle(String mg) => mg
    .replaceAll('_', ' ')
    .split(' ')
    .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
    .join(' ');

/// Short label for the radar axes (tight space — abbreviate the long ones).
String _shortMuscle(String mg) {
  switch (mg) {
    case 'rear_delts':
      return 'R.Delt';
    case 'lower_back':
      return 'Lo.Back';
    case 'hamstrings':
      return 'Hams';
    case 'shoulders':
      return 'Delts';
    case 'adductors':
      return 'Adduct';
    case 'forearms':
      return 'F.arm';
    default:
      return _prettyMuscle(mg);
  }
}
