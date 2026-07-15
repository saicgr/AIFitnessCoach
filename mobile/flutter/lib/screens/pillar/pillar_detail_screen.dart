import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/today_score.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../data/providers/nutrition_preferences_provider.dart';
import '../../data/providers/pillar_history_provider.dart';
import '../../data/providers/today_score_provider.dart';
import '../../data/providers/today_workout_provider.dart';
import '../../data/repositories/nutrition_repository.dart';
import '../../data/services/health_goals_service.dart';
import '../../data/services/health_service.dart';
import '../../widgets/date_strip.dart';
import '../../widgets/glass_back_button.dart';
import '../../widgets/metric_detail/metric_card_chrome.dart';
import '../home/widgets/score_colors.dart';
import 'full_screen_chart_screen.dart';
import 'widgets/ask_coach_button.dart';

/// Per-pillar detail screen — route `/pillar/<train|nourish|move>`.
///
/// Modelled on `sleep_detail_screen.dart`: a date strip drives the selected
/// day, a hero block shows the pillar's 0-100 completion, a component
/// breakdown surfaces the three drivers, then four graph cards (sparkline /
/// calendar heatmap / band / pillar-specific creative). Each row carries its
/// own Ask Coach button.
class PillarDetailScreen extends ConsumerStatefulWidget {
  final PillarKind kind;

  const PillarDetailScreen({super.key, required this.kind});

  @override
  ConsumerState<PillarDetailScreen> createState() =>
      _PillarDetailScreenState();
}

class _PillarDetailScreenState extends ConsumerState<PillarDetailScreen> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppColorsLight.background;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    final pillarColor = _pillarColor(widget.kind);
    final score = ref.watch(todayScoreProvider);
    final contributor = score.contributor(widget.kind.contributorKind);
    final historyAsync = ref.watch(pillarHistoryProvider(
      PillarHistoryKey(kind: widget.kind, days: 30),
    ));

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 16, 4),
              child: Row(
                children: [
                  const GlassBackButton(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.kind.label,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                children: [
                  DateStrip(
                    selectedDate: _selectedDate,
                    loggedDateKeys: _loggedKeys(historyAsync.valueOrNull),
                    weeksBack: 6,
                    onDaySelected: (d) =>
                        setState(() => _selectedDate = d),
                  ),
                  const SizedBox(height: 8),
                  _HeroBlock(
                    kind: widget.kind,
                    contributor: contributor,
                    color: pillarColor,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _ComponentBreakdownCard(
                    kind: widget.kind,
                    isDark: isDark,
                    color: pillarColor,
                  ),
                  const SizedBox(height: 12),
                  _HeadlineSparklineCard(
                    kind: widget.kind,
                    history: historyAsync,
                    color: pillarColor,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _HeatmapCard(
                    kind: widget.kind,
                    history: historyAsync,
                    color: pillarColor,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _BandCard(
                    kind: widget.kind,
                    history: historyAsync,
                    color: pillarColor,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _CreativeCard(
                    kind: widget.kind,
                    color: pillarColor,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _CustomTrendsButton(isDark: isDark),
                  const SizedBox(height: 12),
                  _PrimaryCtas(kind: widget.kind, isDark: isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Set<String> _loggedKeys(List<PillarDayScore>? history) {
    if (history == null) return const {};
    return {
      for (final p in history)
        '${p.date.year.toString().padLeft(4, '0')}-'
            '${p.date.month.toString().padLeft(2, '0')}-'
            '${p.date.day.toString().padLeft(2, '0')}',
    };
  }
}

// ════════════════════════════════════════════════════════════════════════
// Hero block
// ════════════════════════════════════════════════════════════════════════

class _HeroBlock extends StatelessWidget {
  final PillarKind kind;
  final ScoreContributor contributor;
  final Color color;
  final bool isDark;
  const _HeroBlock({
    required this.kind,
    required this.contributor,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted =
        isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final score = contributor.applicable
        ? (contributor.completion * 100).round()
        : 0;
    final tier = tierFor(score);

    return _Card(
      isDark: isDark,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contributor.applicable
                      ? "Today's ${kind.label}"
                      : '${kind.label} · not active today',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textMuted,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$score',
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                        height: 1.0,
                        letterSpacing: -1.6,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        '/ 100',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: tier.color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tier.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: tier.color,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  contributor.statusText,
                  style: TextStyle(
                    fontSize: 12,
                    color: textMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          AskCoachButton(
            contextLabel: "${kind.label} · today's score",
            statSnapshot: {
              'pillar': kind.name,
              'score': score,
              'tier': tier.label,
              'applicable': contributor.applicable,
              'statusText': contributor.statusText,
            },
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// Component breakdown (3 labeled bars)
// ════════════════════════════════════════════════════════════════════════

class _ComponentBreakdownCard extends ConsumerWidget {
  final PillarKind kind;
  final bool isDark;
  final Color color;
  const _ComponentBreakdownCard({
    required this.kind,
    required this.isDark,
    required this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final rows = _components(context, ref);

    return _Card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            icon: Icons.dashboard_customize_rounded,
            color: color,
            title: AppLocalizations.of(context)!.pillarDetailComponents,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _ComponentRow(row: rows[i], color: color, isDark: isDark, kind: kind),
          ],
        ],
      ),
    );
  }

  /// Three per-pillar components. Sleep gets a single "duration" row in v1 —
  /// the existing sleep_detail_screen owns the richer breakdown.
  List<_ComponentData> _components(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    switch (kind) {
      case PillarKind.train:
        final workout = ref.watch(todayWorkoutProvider).valueOrNull;
        final hasToday = workout?.hasWorkoutToday ?? false;
        final completed = workout?.completedToday ?? false;
        return [
          _ComponentData(
            label: l10n.pillarDetailCompletion,
            valueLabel: completed ? '100%' : (hasToday ? '0%' : '—'),
            fraction: completed ? 1.0 : 0.0,
          ),
          _ComponentData(
            label: l10n.pillarDetailVolume,
            valueLabel: workout?.todayWorkout?.exerciseCount != null
                ? '${workout!.todayWorkout!.exerciseCount} ex'
                : '—',
            fraction: completed ? 1.0 : 0.0,
          ),
          _ComponentData(
            label: l10n.pillarDetailIntensity,
            // TODO(pillar-train): expose per-set RPE / load progression
            // once today_workout_provider surfaces an in-session signal.
            valueLabel: completed
                ? AppLocalizations.of(context)!.pillarDetailLogged
                : AppLocalizations.of(context)!.pillarDetailPending,
            fraction: completed ? 0.8 : 0.0,
          ),
        ];
      case PillarKind.nourish:
        final summary = ref.watch(dailyNutritionProvider(todayNutritionKey())).summary;
        final prefs = ref.watch(nutritionPreferencesProvider);
        final cal = (summary?.totalCalories ?? 0).toDouble();
        final prot = (summary?.totalProteinG ?? 0).toDouble();
        final calGoal = (prefs.currentCalorieTarget ?? 0).toDouble();
        final protGoal = prefs.currentProteinTarget ?? 0;
        final calHit = calGoal > 0 ? (cal / calGoal).clamp(0.0, 1.0) : 0.0;
        final protHit = protGoal > 0 ? (prot / protGoal).clamp(0.0, 1.0) : 0.0;
        // Variety placeholder — daily distinct-food count isn't exposed yet.
        // TODO(pillar-nourish): wire variety from /food-patterns endpoint.
        final variety = (summary?.totalCalories ?? 0) > 0 ? 0.5 : 0.0;
        return [
          _ComponentData(
            label: l10n.pillarDetailCalorieHit,
            valueLabel: calGoal > 0
                ? '${(calHit * 100).round()}%'
                : AppLocalizations.of(context)!.pillarDetailSetAGoal,
            fraction: calHit.toDouble(),
          ),
          _ComponentData(
            label: l10n.pillarDetailProteinHit,
            valueLabel: protGoal > 0
                ? '${(protHit * 100).round()}%'
                : AppLocalizations.of(context)!.pillarDetailSetAGoal,
            fraction: protHit.toDouble(),
          ),
          _ComponentData(
            label: l10n.pillarDetailVariety,
            valueLabel: variety > 0 ? l10n.pillarDetailTracking : '—',
            fraction: variety,
          ),
        ];
      case PillarKind.move:
        final activity = ref.watch(dailyActivityProvider).today;
        final stepGoal =
            ref.watch(healthGoalsProvider).valueOrNull?.stepGoal ?? 10000;
        final steps = activity?.steps ?? 0;
        final activeMin = activity?.activeMinutes ?? 0;
        final cal = (activity?.caloriesBurned ?? 0).round();
        final stepHit = stepGoal > 0 ? (steps / stepGoal).clamp(0.0, 1.0) : 0.0;
        // No explicit goal for active min / kcal; show as fill vs 60 min /
        // 600 kcal benchmark — better than 0 with a TODO to source from goals.
        // TODO(pillar-move): expose activeMinutesGoal + kcalGoal in
        // healthGoalsProvider and replace the 60 / 600 placeholders.
        return [
          _ComponentData(
            label: l10n.pillarDetailSteps,
            valueLabel: '$steps / $stepGoal',
            fraction: stepHit.toDouble(),
          ),
          _ComponentData(
            label: l10n.pillarDetailActiveMin,
            valueLabel: activeMin > 0 ? '$activeMin min' : '—',
            fraction: (activeMin / 60).clamp(0.0, 1.0),
          ),
          _ComponentData(
            label: l10n.pillarDetailCaloriesBurned,
            valueLabel: cal > 0 ? '$cal kcal' : '—',
            fraction: (cal / 600).clamp(0.0, 1.0),
          ),
        ];
      case PillarKind.sleep:
        // The sleep detail screen is the source of truth — this pillar entry
        // is a lightweight pointer.
        return [
          _ComponentData(
            label: l10n.pillarDetailDuration,
            valueLabel: l10n.pillarDetailOpenSleep,
            fraction: 0.0,
          ),
        ];
    }
  }
}

class _ComponentData {
  final String label;
  final String valueLabel;
  final double fraction;
  const _ComponentData({
    required this.label,
    required this.valueLabel,
    required this.fraction,
  });
}

class _ComponentRow extends StatelessWidget {
  final _ComponentData row;
  final Color color;
  final bool isDark;
  final PillarKind kind;
  const _ComponentRow({
    required this.row,
    required this.color,
    required this.isDark,
    required this.kind,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final track = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.05);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      row.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textMuted,
                      ),
                    ),
                  ),
                  Text(
                    row.valueLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: row.fraction.clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: track,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        AskCoachButton(
          contextLabel: '${kind.label} · ${row.label}',
          statSnapshot: {
            'pillar': kind.name,
            'component': row.label,
            'value': row.valueLabel,
            'fraction': row.fraction,
          },
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// Graph cards
// ════════════════════════════════════════════════════════════════════════

class _GraphCardHeader extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final bool isDark;
  final String chartId;
  final PillarKind kind;
  final ChartDataLoader loader;
  const _GraphCardHeader({
    required this.icon,
    required this.color,
    required this.title,
    required this.isDark,
    required this.chartId,
    required this.kind,
    required this.loader,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.open_in_full_rounded, size: 18),
          tooltip: AppLocalizations.of(context)!.pillarDetailOpenFullScreen,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => FullScreenChartScreen(
                  chartId: chartId,
                  title: title,
                  pillarKind: kind,
                  loadData: loader,
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 4),
        AskCoachButton(
          contextLabel: '${kind.label} · $title',
          statSnapshot: {'pillar': kind.name, 'chart': chartId},
        ),
      ],
    );
  }
}

class _HeadlineSparklineCard extends ConsumerWidget {
  final PillarKind kind;
  final AsyncValue<List<PillarDayScore>> history;
  final Color color;
  final bool isDark;
  const _HeadlineSparklineCard({
    required this.kind,
    required this.history,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _Card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GraphCardHeader(
            icon: Icons.show_chart_rounded,
            color: color,
            title: AppLocalizations.of(context)!.pillarDetail7DayCompletion,
            isDark: isDark,
            chartId: 'sparkline-7d',
            kind: kind,
            loader: (days) async {
              return await ref.read(pillarHistoryProvider(
                PillarHistoryKey(kind: kind, days: days),
              ).future);
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            child: history.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, __) => _emptyChartText(AppLocalizations.of(context)!.pillarDetailCouldNotLoad, isDark),
              data: (all) {
                final last7 = _last(all, 7);
                if (last7.length < 2) {
                  return _emptyChartText(
                    AppLocalizations.of(context)!.pillarDetailTwoOrMoreLoggedDays,
                    isDark,
                  );
                }
                return _MiniSparkline(points: last7, color: color, isDark: isDark);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniSparkline extends StatelessWidget {
  final List<PillarDayScore> points;
  final Color color;
  final bool isDark;
  const _MiniSparkline({
    required this.points,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = [...points]..sort((a, b) => a.date.compareTo(b.date));
    final spots = <FlSpot>[
      for (var i = 0; i < sorted.length; i++)
        FlSpot(i.toDouble(), sorted[i].completion * 100),
    ];
    final todayIdx = sorted.length - 1;
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (sorted.length - 1).toDouble(),
        minY: 0,
        maxY: 100,
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            barWidth: 2.6,
            color: color,
            dotData: FlDotData(
              show: true,
              checkToShowDot: (spot, _) => spot.x == todayIdx.toDouble(),
              getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                radius: 4.5,
                color: color,
                strokeWidth: 2,
                strokeColor:
                    isDark ? AppColors.background : AppColorsLight.background,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withValues(alpha: 0.25),
                  color.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
        lineTouchData: const LineTouchData(enabled: false),
      ),
    );
  }
}

class _HeatmapCard extends ConsumerWidget {
  final PillarKind kind;
  final AsyncValue<List<PillarDayScore>> history;
  final Color color;
  final bool isDark;
  const _HeatmapCard({
    required this.kind,
    required this.history,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _Card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GraphCardHeader(
            icon: Icons.calendar_view_month_rounded,
            color: color,
            title: AppLocalizations.of(context)!.pillarDetailLast30Days,
            isDark: isDark,
            chartId: 'heatmap-30d',
            kind: kind,
            loader: (days) async => await ref.read(pillarHistoryProvider(
              PillarHistoryKey(kind: kind, days: days),
            ).future),
          ),
          const SizedBox(height: 14),
          history.when(
            loading: () => const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator())),
            error: (_, __) =>
                _emptyChartText(AppLocalizations.of(context)!.pillarDetailCouldNotLoad, isDark),
            data: (all) {
              if (all.isEmpty) {
                return _emptyChartText(
                  AppLocalizations.of(context)!.pillarDetailNoHistoryYet,
                  isDark,
                );
              }
              return _Heatmap(points: all, color: color, isDark: isDark);
            },
          ),
        ],
      ),
    );
  }
}

class _Heatmap extends StatelessWidget {
  final List<PillarDayScore> points;
  final Color color;
  final bool isDark;
  const _Heatmap({
    required this.points,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final emptyCell = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.04);

    // 5 rows × 7 cols (35 days, oldest top-left → newest bottom-right).
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final cells = [
      for (var i = 34; i >= 0; i--) today.subtract(Duration(days: i)),
    ];
    final byDay = {
      for (final p in points)
        DateTime(p.date.year, p.date.month, p.date.day): p,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 1.0,
          ),
          itemCount: cells.length,
          itemBuilder: (_, i) {
            final d = cells[i];
            final p = byDay[d];
            final frac = p?.completion ?? 0.0;
            final cellColor = p == null
                ? emptyCell
                : color.withValues(alpha: 0.18 + frac * 0.62);
            return Tooltip(
              message: '${DateFormat('MMM d').format(d)} · '
                  '${p == null ? '—' : '${(frac * 100).round()}%'}',
              child: Container(
                decoration: BoxDecoration(
                  color: cellColor,
                  borderRadius: BorderRadius.circular(6),
                  border: p?.atGoal == true
                      ? Border.all(color: color, width: 1)
                      : null,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context)!.pillarDetailDarkerCloserToGoal,
          style: TextStyle(fontSize: 11, color: textMuted),
        ),
      ],
    );
  }
}

class _BandCard extends ConsumerWidget {
  final PillarKind kind;
  final AsyncValue<List<PillarDayScore>> history;
  final Color color;
  final bool isDark;
  const _BandCard({
    required this.kind,
    required this.history,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _Card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GraphCardHeader(
            icon: Icons.compress_rounded,
            color: color,
            title: AppLocalizations.of(context)!.pillarDetailTodayVsYour30,
            isDark: isDark,
            chartId: 'band-30d',
            kind: kind,
            loader: (days) async => await ref.read(pillarHistoryProvider(
              PillarHistoryKey(kind: kind, days: days),
            ).future),
          ),
          const SizedBox(height: 14),
          history.when(
            loading: () => const SizedBox(
                height: 64,
                child: Center(child: CircularProgressIndicator())),
            error: (_, __) =>
                _emptyChartText(AppLocalizations.of(context)!.pillarDetailCouldNotLoad, isDark),
            data: (all) {
              if (all.length < 5) {
                return _emptyChartText(
                  AppLocalizations.of(context)!.pillarDetailFiveOrMoreLoggedDays,
                  isDark,
                );
              }
              return _BandRow(points: all, color: color, isDark: isDark);
            },
          ),
        ],
      ),
    );
  }
}

class _BandRow extends StatelessWidget {
  final List<PillarDayScore> points;
  final Color color;
  final bool isDark;
  const _BandRow({
    required this.points,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    final values = [for (final p in points) p.completion * 100]..sort();
    final p10 = values[(values.length * 0.10).floor()];
    final p90 = values[(values.length * 0.90).floor().clamp(0, values.length - 1)];
    final median = values[values.length ~/ 2];
    final today = (points.last.completion * 100);
    final trackColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 28,
          child: LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              double pos(double v) => (v / 100).clamp(0.0, 1.0) * w;
              return Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: trackColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Positioned(
                    left: pos(p10),
                    width: (pos(p90) - pos(p10)).clamp(2.0, w),
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Positioned(
                    left: pos(median) - 1,
                    child: Container(
                        width: 2, height: 18, color: color.withValues(alpha: 0.7)),
                  ),
                  Positioned(
                    left: (pos(today) - 7).clamp(0.0, w - 14),
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? AppColors.background
                              : AppColorsLight.background,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Today ${today.round()}% · median ${median.round()}% · '
          'range ${p10.round()}–${p90.round()}%',
          style: TextStyle(fontSize: 12, color: textPrimary),
        ),
        const SizedBox(height: 2),
        Text(
          AppLocalizations.of(context)!.pillarDetailBandShowsThe10th,
          style: TextStyle(fontSize: 11, color: textMuted),
        ),
      ],
    );
  }
}

// Pillar-specific creative card — v1 placeholders that read well and ship
// today; the plan calls out richer second-pass versions per pillar.
class _CreativeCard extends ConsumerWidget {
  final PillarKind kind;
  final Color color;
  final bool isDark;
  const _CreativeCard({
    required this.kind,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (icon, title, body) = _creativeMeta(context, kind);
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return _Card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GraphCardHeader(
            icon: icon,
            color: color,
            title: title,
            isDark: isDark,
            chartId: 'creative',
            kind: kind,
            // Reuse the headline data — the creative chart is per-pillar but
            // every variant starts from the same completion series for v1.
            loader: (days) async => await ref.read(pillarHistoryProvider(
              PillarHistoryKey(kind: kind, days: days),
            ).future),
          ),
          const SizedBox(height: 12),
          // TODO(pillar-creative): replace with the richer per-pillar view —
          // Train = time-of-day × duration bubble; Nourish = stacked macro
          // stream; Move = hourly activity ribbon.
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.18)),
            ),
            child: Text(
              body,
              style: TextStyle(fontSize: 12, color: textMuted, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  (IconData, String, String) _creativeMeta(BuildContext context, PillarKind kind) {
    final l10n = AppLocalizations.of(context)!;
    switch (kind) {
      case PillarKind.train:
        return (
          Icons.bubble_chart_rounded,
          l10n.pillarDetailWhenYouTrain,
          l10n.pillarDetailWhenYouTrainBody,
        );
      case PillarKind.nourish:
        return (
          Icons.stacked_line_chart_rounded,
          l10n.pillarDetailMacroStream,
          l10n.pillarDetailMacroStreamBody,
        );
      case PillarKind.move:
        return (
          Icons.line_axis_rounded,
          l10n.pillarDetailHourlyActivityRibbon,
          l10n.pillarDetailHourlyActivityRibbonBody,
        );
      case PillarKind.sleep:
        return (
          Icons.bedtime_rounded,
          l10n.pillarDetailSleepStages,
          l10n.pillarDetailSleepStagesBody,
        );
    }
  }
}

// ════════════════════════════════════════════════════════════════════════
// Footer CTAs
// ════════════════════════════════════════════════════════════════════════

class _CustomTrendsButton extends StatelessWidget {
  final bool isDark;
  const _CustomTrendsButton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          // TODO(pillar-trends): once TrendMetric.pillarTrain / pillarNourish
          // / pillarMove / pillarSleep entries exist, pass them via `extra`
          // so the Custom Trends screen opens pre-seeded with this pillar.
          context.push('/trends/custom', extra: null);
        },
        icon: const Icon(Icons.tune_rounded, size: 18),
        label: Text(AppLocalizations.of(context)!.pillarDetailCustomTrends),
      ),
    );
  }
}

class _PrimaryCtas extends StatelessWidget {
  final PillarKind kind;
  final bool isDark;
  const _PrimaryCtas({required this.kind, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (primaryLabel, primaryRoute, statsTab) = _ctaTargets(context, kind);
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => context.go(primaryRoute),
            child: Text(primaryLabel),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => context.push('/stats?tab=$statsTab'),
            child: Text(l10n.pillarDetailViewFullStats),
          ),
        ),
      ],
    );
  }

  /// Returns: (button label, primary route, /stats tab index).
  ///   Train  → Workout screen, stats Overview (0)
  ///   Nourish → Nutrition screen, stats Nutrition (5, post-Overload-tab insert)
  ///   Move    → Health/activity hub, stats Overview (0)
  ///   Sleep   → Sleep detail screen, stats Overview (0)
  (String, String, int) _ctaTargets(BuildContext context, PillarKind kind) {
    final l10n = AppLocalizations.of(context)!;
    switch (kind) {
      case PillarKind.train:
        return (l10n.pillarDetailOpenWorkouts, '/workouts', 0);
      case PillarKind.nourish:
        // Stats Nutrition tab is index 5 (Overload was inserted at index 1).
        return (l10n.pillarDetailOpenNutrition, '/nutrition', 5);
      case PillarKind.move:
        // Combined health hub holds the activity detail.
        return (l10n.pillarDetailOpenActivity, '/health', 0);
      case PillarKind.sleep:
        return (l10n.pillarDetailOpenSleep, '/health/sleep', 0);
    }
  }
}

// ════════════════════════════════════════════════════════════════════════
// Shared scaffolding
// ════════════════════════════════════════════════════════════════════════

Color _pillarColor(PillarKind kind) {
  switch (kind) {
    case PillarKind.train:
      return kTrainColor;
    case PillarKind.nourish:
      return kFuelColor;
    case PillarKind.move:
      return kMoveColor;
    case PillarKind.sleep:
      return kSleepColor;
  }
}

List<PillarDayScore> _last(List<PillarDayScore> all, int n) {
  if (all.length <= n) return all;
  return all.sublist(all.length - n);
}

Widget _emptyChartText(String msg, bool isDark) {
  final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Text(msg, style: TextStyle(fontSize: 12, color: textMuted, height: 1.4)),
  );
}

// Phase A.5 — `_Card` and `_CardHeader` were extracted to
// `lib/widgets/metric_detail/metric_card_chrome.dart` so the new cardio
// detail screens (race predictor / training load / VO2max) and any
// future metric detail can reuse the same chrome without duplicating
// the ~50 LOC of styling. These thin private wrappers preserve every
// call site in this file (`_Card(isDark: ..., child: ...)`) with byte-
// identical output, so the pillar screens render pixel-for-pixel the
// same as before — no visual regression risk.
class _Card extends StatelessWidget {
  final Widget child;
  final bool isDark;
  const _Card({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) =>
      MetricCardChrome(isDark: isDark, child: child);
}

class _CardHeader extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final bool isDark;
  const _CardHeader({
    required this.icon,
    required this.color,
    required this.title,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) => MetricCardHeader(
        icon: icon,
        color: color,
        title: title,
        isDark: isDark,
      );
}
