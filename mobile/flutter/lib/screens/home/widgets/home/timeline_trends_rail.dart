import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/providers/user_provider.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/widgets/line_icon.dart';
import '../../../../data/models/nutrition_preferences.dart' show WeightLog;
import '../../../../data/models/timeline_entry.dart';
import '../../../../data/providers/nutrition_preferences_provider.dart';
import '../../../../data/providers/sleep_detail_provider.dart';
import '../../../../data/providers/timeline_provider.dart';
import '../../../../data/services/haptic_service.dart';

/// Horizontal rail of compact metric trend charts shown at the top of the Home
/// timeline card — the "graphs like weight log, sleep, and more" the redesign
/// adds.
///
/// Each card plots a short sparkline (14-day window) plus the latest value and
/// a delta vs the window start. Data:
///   - **Weight**  ← `nutritionPreferencesProvider.weightHistory` (body unit)
///   - **Sleep**   ← `sleepHistoryProvider` (real Health Connect / HealthKit
///     nightly history — the timeline `summary.sleep_minutes` is NOT a reliable
///     source, since the backend aggregator has no sleep table)
///   - **Calories / Water** ← `timelineTrendsProvider` (per-day summary)
///
/// A metric self-hides when it has no data; with exactly one point it shows a
/// value-only card (a single point can't draw a line). The whole rail hides
/// when nothing has data, and shows shimmer placeholders while loading. The
/// trends fetch failing hides the rail silently — it is secondary chrome and
/// the event feed below owns the retry surface.
class TimelineTrendsRail extends ConsumerWidget {
  const TimelineTrendsRail({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.colors(context);
    final trends = ref.watch(timelineTrendsProvider);
    final prefs = ref.watch(nutritionPreferencesProvider);
    final weightUnit = ref.watch(weightUnitProvider); // 'kg' | 'lbs'
    final sleepHistory = ref.watch(sleepHistoryProvider);

    // Sleep series from real Health data (last 14 nights with data, oldest→
    // newest). x = day-offset from the first plotted night so gaps stay honest.
    final sleepPoints = <Offset>[];
    final nights = sleepHistory.valueOrNull?.nights ?? const [];
    if (nights.isNotEmpty) {
      // nights is newest-first; take the most recent 14 with data, ascending.
      final withData = [
        for (final n in nights)
          if (n.hasData) n
      ].take(14).toList().reversed.toList();
      if (withData.isNotEmpty) {
        final first = withData.first.date;
        for (final n in withData) {
          sleepPoints.add(Offset(
            n.date.difference(first).inDays.toDouble(),
            n.totalAsleepMinutes.toDouble(),
          ));
        }
      }
    }

    final specs = _buildSpecs(
      context: context,
      c: c,
      trendDays: trends.days,
      weightHistory: prefs.weightHistory,
      weightUnit: weightUnit,
      sleepPoints: sleepPoints,
    );

    final stillLoading = (trends.isLoading && trends.days.isEmpty) ||
        sleepHistory.isLoading;

    // Cold start with nothing cached → shimmer placeholders (no flash).
    if (specs.isEmpty) {
      if (stillLoading) {
        return _SkeletonRail(c: c);
      }
      // No data anywhere (or trends errored) → take no vertical space.
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: specs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => _TrendCard(spec: specs[i], c: c),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Spec assembly
  // --------------------------------------------------------------------------

  List<_TrendSpec> _buildSpecs({
    required BuildContext context,
    required ThemeColors c,
    required List<TimelineDay> trendDays,
    required List<WeightLog> weightHistory,
    required String weightUnit,
    required List<Offset> sleepPoints,
  }) {
    final specs = <_TrendSpec>[];

    // --- Weight (own provider; body-weight unit) ---------------------------
    final isKg = weightUnit == 'kg';
    final unitLabel = isKg ? 'kg' : 'lb';
    // weightHistory is newest-first; take up to the last 10 logs, oldest→newest.
    final recentWeights = weightHistory.take(10).toList().reversed.toList();
    if (recentWeights.isNotEmpty) {
      final values = [
        for (final w in recentWeights) isKg ? w.weightKg : w.weightLbs
      ];
      final latest = values.last;
      final first = values.first;
      final delta = latest - first;
      specs.add(_TrendSpec(
        key: 'weight',
        iconName: 'activity',
        label: 'Weight',
        color: c.info,
        valueText: '${latest.toStringAsFixed(1)} $unitLabel',
        // Body-weight loss is the common goal → a drop reads as positive.
        deltaText: values.length < 2
            ? null
            : '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)}',
        deltaColor: delta.abs() < 0.05
            ? c.textMuted
            : (delta < 0 ? c.success : c.error),
        points: [for (var i = 0; i < values.length; i++) Offset(i.toDouble(), values[i])],
        onTap: () => context.push('/measurements'),
      ));
    }

    // --- Sleep (real Health Connect nightly history; passed in pre-reduced) -
    if (sleepPoints.isNotEmpty) {
      final latest = sleepPoints.last.dy.round();
      final delta = (sleepPoints.last.dy - sleepPoints.first.dy).round();
      specs.add(_TrendSpec(
        key: 'sleep',
        iconName: 'sleep',
        label: 'Sleep',
        color: c.cyan,
        valueText: _fmtDuration(latest),
        deltaText: sleepPoints.length < 2
            ? null
            : '${delta >= 0 ? '+' : '-'}${_fmtDuration(delta.abs(), short: true)}',
        deltaColor: delta == 0
            ? c.textMuted
            : (delta > 0 ? c.success : c.warning),
        points: sleepPoints,
        onTap: () => context.push('/measurements'),
      ));
    }

    // --- Calories / Water (per-day summaries, oldest→newest) ---------------
    final asc = trendDays.reversed.toList(); // provider gives newest-first
    DateTime? parseDay(String d) => DateTime.tryParse(d);
    final firstDate = asc.isNotEmpty ? parseDay(asc.first.date) : null;

    List<Offset> series(int? Function(TimelineSummary s) pick) {
      if (firstDate == null) return const [];
      final out = <Offset>[];
      for (final day in asc) {
        final v = pick(day.summary);
        if (v == null || v <= 0) continue; // skip un-logged days (0 craters the line)
        final dt = parseDay(day.date);
        if (dt == null) continue;
        out.add(Offset(dt.difference(firstDate).inDays.toDouble(), v.toDouble()));
      }
      return out;
    }

    // Calories eaten — neutral delta vs window start.
    final cals = series((s) => s.caloriesEaten);
    if (cals.isNotEmpty) {
      final latest = cals.last.dy.round();
      final delta = (cals.last.dy - cals.first.dy).round();
      specs.add(_TrendSpec(
        key: 'calories',
        iconName: 'nutrition',
        label: 'Calories',
        color: c.success,
        valueText: _fmtThousands(latest),
        deltaText: cals.length < 2
            ? null
            : '${delta >= 0 ? '+' : ''}${_fmtThousands(delta.abs())}',
        deltaColor: c.textMuted,
        points: cals,
        onTap: () => context.push('/nutrition'),
      ));
    }

    // Water — latest vs goal as the value; trend is the sparkline.
    final water = series((s) => s.waterMl);
    if (water.isNotEmpty) {
      final latestMl = water.last.dy.round();
      final goalMl = asc.last.summary.waterGoalMl;
      specs.add(_TrendSpec(
        key: 'water',
        iconName: 'water',
        label: 'Water',
        color: c.info,
        valueText: goalMl > 0
            ? '${(latestMl / 1000).toStringAsFixed(1)}/${(goalMl / 1000).toStringAsFixed(1)}L'
            : '${(latestMl / 1000).toStringAsFixed(1)}L',
        deltaText: null,
        deltaColor: c.textMuted,
        points: water,
        onTap: () => context.push('/nutrition'),
      ));
    }

    return specs;
  }

  static String _fmtDuration(int minutes, {bool short = false}) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '${h}h';
    return short ? '${h}h${m}m' : '${h}h ${m}m';
  }

  static String _fmtThousands(int v) {
    final s = v.abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return '${v < 0 ? '-' : ''}$buf';
  }
}

/// Display model for a single trend card.
class _TrendSpec {
  final String key;
  final String iconName;
  final String label;
  final Color color;
  final String valueText;
  final String? deltaText;
  final Color deltaColor;

  /// (x = day-offset, y = value) — sorted ascending by x. 1 point = no line.
  final List<Offset> points;
  final VoidCallback onTap;

  const _TrendSpec({
    required this.key,
    required this.iconName,
    required this.label,
    required this.color,
    required this.valueText,
    required this.deltaText,
    required this.deltaColor,
    required this.points,
    required this.onTap,
  });
}

class _TrendCard extends StatelessWidget {
  final _TrendSpec spec;
  final ThemeColors c;
  const _TrendCard({required this.spec, required this.c});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticService.selection();
        spec.onTap();
      },
      child: Container(
        width: 148,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                LineIcon(spec.iconName, size: 13, color: spec.color),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    spec.label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: c.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: Text(
                    spec.valueText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: c.textPrimary,
                    ),
                  ),
                ),
                if (spec.deltaText != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    spec.deltaText!,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: spec.deltaColor,
                    ),
                  ),
                ],
              ],
            ),
            // Sparkline — only when there are ≥2 points to connect.
            SizedBox(
              height: 30,
              child: spec.points.length >= 2
                  ? _Sparkline(points: spec.points, color: spec.color)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

/// fl_chart sparkline — mirrors the home weight-trend card's `LineChart`
/// config (no axes/grid/border, touch disabled, smooth curve, soft fill).
class _Sparkline extends StatelessWidget {
  final List<Offset> points;
  final Color color;
  const _Sparkline({required this.points, required this.color});

  @override
  Widget build(BuildContext context) {
    final spots = [for (final p in points) FlSpot(p.dx, p.dy)];
    final ys = [for (final p in points) p.dy];
    var minY = ys.reduce((a, b) => a < b ? a : b);
    var maxY = ys.reduce((a, b) => a > b ? a : b);
    // Flat series guard — give the line vertical breathing room so it doesn't
    // hug an edge or divide by a zero range.
    if ((maxY - minY).abs() < 0.001) {
      minY -= 1;
      maxY += 1;
    } else {
      final pad = (maxY - minY) * 0.18;
      minY -= pad;
      maxY += pad;
    }
    // Isolate the fl_chart raster into its own layer (mirrors MiniSparkline) so
    // the sparkline doesn't re-rasterise with the surrounding trend rail.
    return RepaintBoundary(
      child: LineChart(
        LineChartData(
          minX: spots.first.x,
          maxX: spots.last.x,
          minY: minY,
          maxY: maxY,
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: color,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: color.withValues(alpha: 0.10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer placeholders sized to the loaded cards, so the rail cross-fades in
/// without a layout shift.
class _SkeletonRail extends StatelessWidget {
  final ThemeColors c;
  const _SkeletonRail({required this.c});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).dividerColor.withValues(alpha: 0.30);
    final highlight = Theme.of(context).dividerColor.withValues(alpha: 0.12);
    return SizedBox(
      height: 112,
      child: Shimmer.fromColors(
        baseColor: base,
        highlightColor: highlight,
        period: const Duration(milliseconds: 1200),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, __) => Container(
            width: 148,
            decoration: BoxDecoration(
              color: base,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }
}
