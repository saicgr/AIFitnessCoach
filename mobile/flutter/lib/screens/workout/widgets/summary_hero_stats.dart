/// Compact hero stats for the workout Summary tab.
///
/// Replaces the old 8-tile 2×N grid that rendered '--' for every metric the
/// session didn't capture. Rule here: a stat renders ONLY when it has a real
/// value — primary stats as MetricGrid cells, secondary stats as a Wrap of
/// small chips. Nothing in this widget ever prints '--'.
library;

import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/stat_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/models/workout.dart';
import '../../../widgets/metric_grid.dart';

class SummaryHeroStats extends StatelessWidget {
  final WorkoutSummaryResponse summary;
  final Map<String, dynamic>? metadata;
  final List<Map<String, dynamic>> exercises;

  const SummaryHeroStats({
    super.key,
    required this.summary,
    required this.metadata,
    this.exercises = const [],
  });

  // ─── Aggregation (mirrors what the active client wrote) ─────────

  /// Aggregate per-set logs into (volumeKg, sets, reps). Counts only sets
  /// that were actually completed (or that recorded reps > 0 — older logs
  /// don't carry the is_completed flag).
  ({double volumeKg, int sets, int reps}) _aggregateSetLogs() {
    double volume = 0;
    int sets = 0;
    int reps = 0;
    for (final log in summary.setLogs) {
      final isCompleted = log.isCompleted ?? (log.repsCompleted > 0);
      if (!isCompleted) continue;
      sets += 1;
      reps += log.repsCompleted;
      volume += log.weightKg * log.repsCompleted;
    }
    return (volumeKg: volume, sets: sets, reps: reps);
  }

  /// Aggregate metadata['sets_json'] (richest source — written by the
  /// active-workout client). Survives even if performance_logs rows weren't
  /// written.
  ({double volumeKg, int sets, int reps})? _aggregateSetsJson() {
    final raw = metadata?['sets_json'];
    if (raw == null) return null;
    List<dynamic>? list;
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) list = decoded;
      } catch (_) {}
    } else if (raw is List) {
      list = raw;
    }
    if (list == null || list.isEmpty) return null;
    double volume = 0;
    int sets = 0;
    int reps = 0;
    for (final item in list) {
      if (item is! Map) continue;
      final completedRaw = item['is_completed'];
      final repsCompleted = (item['reps_completed'] as num?)?.toInt() ?? 0;
      final isCompleted =
          completedRaw is bool ? completedRaw : repsCompleted > 0;
      if (!isCompleted) continue;
      final weightKg = (item['weight_kg'] as num?)?.toDouble() ?? 0;
      sets += 1;
      reps += repsCompleted;
      volume += weightKg * repsCompleted;
    }
    return (volumeKg: volume, sets: sets, reps: reps);
  }

  /// Median rest (seconds) across metadata['rest_intervals']. Null when no
  /// positive rest samples were tracked — the chip is hidden, never '--'.
  double? _medianRestSeconds() {
    final raw = metadata?['rest_intervals'];
    if (raw is! List || raw.isEmpty) return null;
    final values = <int>[];
    for (final e in raw) {
      if (e is Map) {
        final s = (e['rest_seconds'] as num?)?.toInt() ?? 0;
        if (s > 0) values.add(s);
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

  String _formatVolumeLbs(double kg) {
    final lbs = kg * 2.20462;
    if (lbs >= 1000) {
      return '${(lbs / 1000).toStringAsFixed(1)}k';
    }
    return lbs.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    final accent = c.accent;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final wc = summary.performanceComparison?.workoutComparison;

    // Backend aggregates can be 0 (or wc itself null) for older workouts
    // whose workout_performance_summary row was never written. Fall back to
    // per-set data so the stats always reflect what was actually logged.
    final fallback =
        _aggregateSetsJson() ?? (summary.setLogs.isNotEmpty ? _aggregateSetLogs() : null);

    final volumeKg = (wc?.currentTotalVolumeKg ?? 0) > 0
        ? wc!.currentTotalVolumeKg
        : (fallback?.volumeKg ?? 0);
    final sets = (wc?.currentTotalSets ?? 0) > 0
        ? wc!.currentTotalSets
        : (fallback?.sets ?? 0);
    final reps = (wc?.currentTotalReps ?? 0) > 0
        ? wc!.currentTotalReps
        : (fallback?.reps ?? 0);

    // Actual tracked time: prefer the new top-level field (read straight from
    // workout_logs.total_time_seconds), then the comparison row, then the
    // workout-log metadata. A 0 here means "not tracked" → cell hidden, the
    // old "0m" lie is gone.
    final durationSeconds = summary.durationSeconds > 0
        ? summary.durationSeconds
        : ((wc?.currentDurationSeconds ?? 0) > 0
            ? wc!.currentDurationSeconds
            : ((metadata?['total_time_seconds'] as num?)?.toInt() ?? 0));

    final records = summary.personalRecords.length;

    final caloriesKcal = summary.caloriesKcal ??
        ((wc?.currentCalories ?? 0) > 0 ? wc!.currentCalories : null);
    final caloriesEstimated = summary.caloriesSource == 'planned_estimate';

    final medianRest = _medianRestSeconds();
    final exerciseCount = (wc?.currentExercises ?? 0) > 0
        ? wc!.currentExercises
        : exercises.length;

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
          value: _formatVolumeLbs(volumeKg),
          unit: 'lb',
          icon: Icons.show_chart,
          accent: accent,
        ),
      if (sets > 0)
        MetricCell(
          label: 'Sets · Reps',
          value: '$sets · $reps',
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
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
