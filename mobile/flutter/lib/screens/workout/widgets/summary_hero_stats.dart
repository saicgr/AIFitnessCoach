/// Compact hero stats for the workout Summary tab.
///
/// Replaces the old 8-tile 2×N grid that rendered '--' for every metric the
/// session didn't capture. Rule here: a stat renders ONLY when it has a real
/// value — primary stats as MetricGrid cells, secondary stats as a Wrap of
/// small chips. Nothing in this widget ever prints '--'.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/stat_typography.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/utils/weight_utils.dart';
import '../../../data/models/workout.dart';
import '../../../widgets/metric_grid.dart';
import 'summary_exercise_table.dart'
    show formatSetDistanceMeters, formatSetDurationSeconds;
import 'summary_session_totals.dart';

class SummaryHeroStats extends ConsumerWidget {
  final WorkoutSummaryResponse summary;
  final Map<String, dynamic>? metadata;
  final List<Map<String, dynamic>> exercises;

  const SummaryHeroStats({
    super.key,
    required this.summary,
    required this.metadata,
    this.exercises = const [],
  });

  // Aggregation now lives in ONE place — SummarySessionTotals — so the
  // share card and this ledger can never disagree (E2E #78).

  /// Median rest (seconds) across metadata['rest_intervals']. Null when no
  /// positive rest samples were tracked — the chip is hidden, never '--'.
  double? _medianRestSeconds() {
    final raw = metadata?['rest_intervals'];
    if (raw is! List || raw.isEmpty) return null;
    final values = <int>[];
    for (final e in raw) {
      if (e is Map) {
        // Row 139 — `rest_seconds` is a real 0 when the user hit Skip Rest
        // almost immediately (timer_rest_mixin.dart's handleRestComplete
        // overwrites it with the actual elapsed rest for both a normal
        // finish AND a skip). Dropping `s == 0` here treated "skipped every
        // rest" the same as "no rest data at all", blanking MEDIAN REST on a
        // session where rests genuinely ran (and were skipped) throughout.
        if (e.containsKey('rest_seconds')) {
          values.add((e['rest_seconds'] as num?)?.toInt() ?? 0);
        }
      }
    }
    if (values.isEmpty) return null;
    values.sort();
    final mid = values.length ~/ 2;
    if (values.length.isOdd) return values[mid].toDouble();
    return (values[mid - 1] + values[mid]) / 2.0;
  }

  // ─── Formatting ──────────────────────────────────────────────────

  String _formatMmSs(num seconds) {
    final total = seconds.round();
    final m = total ~/ 60;
    final s = total % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m';
    return '${seconds}s';
  }

  /// Volume in the user's LIFTED-weight unit, abbreviated past 1,000.
  String _formatVolume(double kg, {required bool useKg}) {
    final value = useKg ? kg : WeightUtils.kgToLbs(kg);
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // E2E #18: the Volume cell hardcoded 'lb' — a kg user saw pounds under a
    // kg-free label. Resolve through the LIFTED-weight preference.
    final useKg = ref.watch(useKgForWorkoutProvider);
    final c = ThemeColors.of(context);
    final accent = c.accent;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final totals = SummarySessionTotals.resolve(
      summary: summary,
      metadata: metadata,
      exerciseCount: exercises.length,
    );
    final volumeKg = totals.volumeKg;
    final sets = totals.sets;
    final reps = totals.reps;
    final distanceMeters = totals.distanceMeters;
    final timedOnlySeconds = totals.timedOnlySeconds;
    // A 0 duration means "not tracked" → the cell is hidden; the old "0m" lie
    // is gone.
    final durationSeconds = totals.durationSeconds;
    final records = totals.records;
    final caloriesKcal = totals.caloriesKcal;
    final caloriesEstimated = totals.caloriesEstimated;

    final medianRest = _medianRestSeconds();
    final exerciseCount = totals.exercises;

    // ── Primary cells — only stats this session actually has ──
    final cells = <MetricCell>[
      if (durationSeconds > 0)
        MetricCell(
          label: 'Duration',
          value: _formatDuration(durationSeconds),
          icon: Icons.timer_outlined,
          accent: accent,
        ),
      if (volumeKg > 0)
        MetricCell(
          label: 'Volume',
          value: _formatVolume(volumeKg, useKg: useKg),
          unit: WeightUtils.workoutUnitLabel(useKg),
          icon: Icons.show_chart,
          accent: accent,
        ),
      // A distance/timed session legitimately logs 0 reps for every set
      // (easy_active_workout_state.dart zeroes reps for a timed/distance
      // set) — showing "$sets · 0" reads as "0 reps", a real number that
      // never happened. `reps == 0` here means "not applicable", so the
      // cell shows whatever real metric the session DOES have instead of
      // fabricating a rep count. A mixed session (some rep sets, some
      // distance/timed) already has reps > 0 from its real rep sets, so it
      // keeps the ordinary Sets · Reps reading — that number is true.
      if (sets > 0)
        if (reps > 0)
          MetricCell(
            label: 'Sets · Reps',
            value: '$sets · $reps',
            icon: Icons.layers_outlined,
            accent: accent,
          )
        else if (distanceMeters > 0)
          MetricCell(
            label: 'Sets · Distance',
            value: '$sets · ${formatSetDistanceMeters(distanceMeters)}',
            icon: Icons.layers_outlined,
            accent: accent,
          )
        else if (timedOnlySeconds > 0)
          MetricCell(
            label: 'Sets · Time',
            value: '$sets · ${formatSetDurationSeconds(timedOnlySeconds)}',
            icon: Icons.layers_outlined,
            accent: accent,
          )
        else
          MetricCell(
            label: 'Sets',
            value: '$sets',
            icon: Icons.layers_outlined,
            accent: accent,
          ),
      MetricCell(
        label: 'Records',
        value: '$records',
        icon: Icons.emoji_events_outlined,
        accent: records > 0 ? c.success : accent,
      ),
    ];

    // ── Secondary chips — hidden entirely when the value is unknown ──
    final chips = <Widget>[
      if (caloriesKcal != null && caloriesKcal > 0)
        _StatChip(
          icon: Icons.local_fire_department_outlined,
          label: caloriesEstimated
              ? '~$caloriesKcal kcal'
              : '$caloriesKcal kcal',
          isDark: isDark,
        ),
      if (medianRest != null)
        _StatChip(
          icon: Icons.av_timer_outlined,
          label: 'Median rest ${_formatMmSs(medianRest)}',
          isDark: isDark,
        ),
      if (exerciseCount > 0)
        _StatChip(
          icon: Icons.fitness_center,
          label: exerciseCount == 1 ? '1 exercise' : '$exerciseCount exercises',
          isDark: isDark,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MetricGrid(
          items: cells,
          columns: 2,
          spacing: 10,
          numberSize: StatType.secondary,
        ),
        if (chips.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: chips),
        ],
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? AppColors.textSecondary : Colors.grey.shade700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.elevated : AppColorsLight.elevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 5),
          // Flexible, not a bare Text: these chips sit in a Wrap that hands
          // each one the full row width as its max. On a 320pt phone at 130%
          // text a long label ("Median rest 1:45", localized strings) exceeds
          // it and the Row overflowed on the right. Letting the label shrink
          // and ellipsize keeps the chip inside its line.
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
