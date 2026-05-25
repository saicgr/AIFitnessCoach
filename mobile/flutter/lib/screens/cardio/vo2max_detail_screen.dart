import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/accent_color_provider.dart';
import '../../data/repositories/vo2max_repository.dart';
import '../../widgets/glass_back_button.dart';
import '../pillar/widgets/ask_coach_button.dart';

import '../../l10n/generated/app_localizations.dart';
/// VO2max trend detail screen.
///
/// Wave 2 (SLICE_VO2MAX). Self-contained — when MetricDetailScreen lands
/// in a later wave, refactor onto the shared base. Data is read-only from
/// the `cardio_metrics` table; SLICE_GPS owns the HealthKit import that
/// fills it. Route registration is deferred to a later wave.
class Vo2MaxDetailScreen extends ConsumerWidget {
  const Vo2MaxDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final latestAsync = ref.watch(vo2MaxLatestProvider);
    final historyAsync = ref.watch(vo2MaxHistoryProvider);

    return Scaffold(
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
                      AppLocalizations.of(context).vo2maxDetailVo2max,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  // Invalidate both — providers re-fetch in parallel.
                  ref.invalidate(vo2MaxLatestProvider);
                  ref.invalidate(vo2MaxHistoryProvider);
                  await Future.wait([
                    ref.read(vo2MaxLatestProvider.future),
                    ref.read(vo2MaxHistoryProvider.future),
                  ]);
                },
                child: _Body(
                  latestAsync: latestAsync,
                  historyAsync: historyAsync,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------------

class _Body extends StatelessWidget {
  final AsyncValue<Vo2MaxLatest> latestAsync;
  final AsyncValue<List<Vo2MaxPoint>> historyAsync;

  const _Body({required this.latestAsync, required this.historyAsync});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Anchor pull-to-refresh even when content is short by forcing the
    // ListView to always be scrollable.
    final loading =
        latestAsync.isLoading || historyAsync.isLoading;
    final error = latestAsync.hasError ? latestAsync.error : historyAsync.error;

    if (loading && !latestAsync.hasValue && !historyAsync.hasValue) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (error != null && !latestAsync.hasValue) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          Text(
            'Could not load VO2max.\n$error',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    final latest = latestAsync.valueOrNull ?? const Vo2MaxLatest();
    final history = historyAsync.valueOrNull ?? const <Vo2MaxPoint>[];

    // Empty state — neither a latest reading nor any historical points.
    if (!latest.hasData && history.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        children: [
          const SizedBox(height: 48),
          Icon(
            Icons.favorite_rounded,
            size: 48,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).vo2maxDetailNoVo2maxYet,
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Run outdoors a few times — Apple Health will start logging '
            'your VO2max.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _LatestHero(latest: latest, history: history),
        const SizedBox(height: 20),
        _TrendCard(history: history),
        const SizedBox(height: 16),
        _StatRow(history: history, latest: latest),
        const SizedBox(height: 20),
        _AskCoachFooter(latest: latest, history: history),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Hero — latest VO2max + fitness-age delta + source
// ---------------------------------------------------------------------------

class _LatestHero extends StatelessWidget {
  final Vo2MaxLatest latest;
  final List<Vo2MaxPoint> history;
  const _LatestHero({required this.latest, required this.history});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final onSurface = theme.colorScheme.onSurface;

    // Resolve the value to show. Prefer `latest` (view-backed, most
    // authoritative) but fall back to the most recent history point if
    // the view's row is a non-VO2max row.
    final value = latest.mlPerKgPerMin ??
        (history.isNotEmpty ? history.last.mlPerKgPerMin : null);
    final recordedAt = latest.recordedAt ??
        (history.isNotEmpty ? history.last.recordedAt : null);
    final sourceLabel =
        latest.sourceLabel ?? (history.isNotEmpty ? history.last.sourceLabel : null);

    final whenStr = recordedAt == null
        ? ''
        : DateFormat.yMMMd().format(recordedAt);

    final fitnessAge = latest.fitnessAge;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.18),
            accent.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).vo2maxDetailLatestVo2max,
            style: theme.textTheme.labelMedium?.copyWith(
              color: onSurface.withValues(alpha: 0.6),
              letterSpacing: 0.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value == null ? '--' : value.toStringAsFixed(1),
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: accent,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                AppLocalizations.of(context).vo2maxDetailMlKgMin,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: onSurface.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (fitnessAge != null)
                _Chip(
                  label: 'Fitness age $fitnessAge',
                  color: accent,
                ),
              if (sourceLabel != null)
                _Chip(label: sourceLabel, color: onSurface),
              if (whenStr.isNotEmpty)
                Text(
                  'as of $whenStr',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: onSurface.withValues(alpha: 0.55),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sparkline — 180-day VO2max trend
// ---------------------------------------------------------------------------

class _TrendCard extends StatelessWidget {
  final List<Vo2MaxPoint> history;
  const _TrendCard({required this.history});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final onSurface = theme.colorScheme.onSurface;

    if (history.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: onSurface.withValues(alpha: 0.08)),
        ),
        child: Text(
          AppLocalizations.of(context).vo2maxDetailTrendWillAppearAfter,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: onSurface.withValues(alpha: 0.6),
          ),
        ),
      );
    }

    // Convert recorded_at → x as "days since first sample" for the
    // x-axis. This makes irregular sampling visually accurate.
    final firstMs = history.first.recordedAt.millisecondsSinceEpoch;
    final lastMs = history.last.recordedAt.millisecondsSinceEpoch;
    final spanMs = (lastMs - firstMs).clamp(1, 1 << 62);

    final spots = <FlSpot>[
      for (final p in history)
        FlSpot(
          (p.recordedAt.millisecondsSinceEpoch - firstMs) / spanMs,
          p.mlPerKgPerMin,
        ),
    ];

    final values = history.map((p) => p.mlPerKgPerMin).toList();
    final minY = (values.reduce((a, b) => a < b ? a : b) - 2).clamp(0, 100).toDouble();
    final maxY = (values.reduce((a, b) => a > b ? a : b) + 2).clamp(0, 100).toDouble();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: onSurface.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context).vo2maxDetailLast180Days,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${history.length} pts',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: onSurface.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                minX: 0,
                maxX: 1,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: ((maxY - minY) / 3).clamp(1, 100).toDouble(),
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: onSurface.withValues(alpha: 0.08),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 0.5,
                      getTitlesWidget: (value, meta) {
                        final ms = firstMs + (value * spanMs).round();
                        final dt =
                            DateTime.fromMillisecondsSinceEpoch(ms);
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            DateFormat.MMMd().format(dt),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: ((maxY - minY) / 3).clamp(1, 100).toDouble(),
                      getTitlesWidget: (value, meta) => Text(
                        value.toStringAsFixed(0),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.25,
                    barWidth: 2.5,
                    color: accent,
                    dotData: FlDotData(
                      show: spots.length <= 30,
                      getDotPainter: (s, _, __, ___) => FlDotCirclePainter(
                        radius: 2.5,
                        color: accent,
                        strokeWidth: 0,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: accent.withValues(alpha: 0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stat row — current / 30-day avg / all-time best
// ---------------------------------------------------------------------------

class _StatRow extends StatelessWidget {
  final List<Vo2MaxPoint> history;
  final Vo2MaxLatest latest;
  const _StatRow({required this.history, required this.latest});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    final current = latest.mlPerKgPerMin ??
        (history.isNotEmpty ? history.last.mlPerKgPerMin : null);

    // 30-day average over the trailing window of `history` (already
    // capped at 180 days by the API). Empty when no qualifying points.
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final recent =
        history.where((p) => p.recordedAt.isAfter(cutoff)).toList();
    final avg30 = recent.isEmpty
        ? null
        : recent.map((p) => p.mlPerKgPerMin).reduce((a, b) => a + b) /
            recent.length;

    final best = history.isEmpty
        ? null
        : history.map((p) => p.mlPerKgPerMin).reduce((a, b) => a > b ? a : b);

    // Use Wrap so the stat row never overflows on small screens
    // (iPhone SE) — per feedback_no_overflow_adaptive_screens.
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _StatTile(label: AppLocalizations.of(context).workoutPlanDrawerCurrent, value: current, color: onSurface),
        _StatTile(label: AppLocalizations.of(context).vo2maxDetail30DayAvg, value: avg30, color: onSurface),
        _StatTile(label: AppLocalizations.of(context).vo2maxDetailAllTimeBest, value: best, color: onSurface),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final double? value;
  final Color color;
  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 100),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color.withValues(alpha: 0.6),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value == null ? '--' : value!.toStringAsFixed(1),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ask Coach footer
// ---------------------------------------------------------------------------

class _AskCoachFooter extends StatelessWidget {
  final Vo2MaxLatest latest;
  final List<Vo2MaxPoint> history;
  const _AskCoachFooter({required this.latest, required this.history});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AskCoachButton(
          contextLabel: 'VO2max trend',
          statSnapshot: {
            'source': 'vo2max',
            'latest_ml_per_kg_per_min': latest.mlPerKgPerMin,
            'latest_source': latest.source,
            'latest_recorded_at': latest.recordedAt?.toIso8601String(),
            'fitness_age': latest.fitnessAge,
            'history_points': history.length,
            'history_min': history.isEmpty
                ? null
                : history
                    .map((p) => p.mlPerKgPerMin)
                    .reduce((a, b) => a < b ? a : b),
            'history_max': history.isEmpty
                ? null
                : history
                    .map((p) => p.mlPerKgPerMin)
                    .reduce((a, b) => a > b ? a : b),
          },
        ),
        const SizedBox(width: 10),
        Text(
          AppLocalizations.of(context).workoutShowcaseAskCoach,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
