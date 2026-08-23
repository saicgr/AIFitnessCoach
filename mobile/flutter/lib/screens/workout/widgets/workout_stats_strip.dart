// Active-workout live stats strip.
//
// Renders the 3-column header bar seen on the workout detail / active
// screen: Duration ● Calories ● Volume. Rebuilds every second off the
// timer + every set-log append, so the numbers tick up live as the
// user works.
//
// Volume is summed from completed `SetLog.weight` (always kg) × reps.
// Calories use a simple MET estimate (moderate strength training ≈ 5.0)
// against the user's body weight, falling back to 70 kg when the user
// profile hasn't loaded yet.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/stat_typography.dart';
import '../../../core/providers/user_provider.dart';
import '../../../data/providers/heart_rate_stream_provider.dart';
import '../models/workout_state.dart';

import '../../../l10n/generated/app_localizations.dart';
/// MET value for moderate-vigorous resistance training. Source: Compendium
/// of Physical Activities (Ainsworth et al.) — entry 02050 "resistance
/// training, multiple exercises, 8–15 repetitions at varied resistance".
const double _kStrengthMET = 5.0;

/// Fallback body weight when the user profile hasn't loaded yet.
const double _kFallbackBodyWeightKg = 70.0;

class WorkoutStatsStrip extends ConsumerWidget {
  final int workoutSeconds;
  final List<SetLog> setLogs;
  final bool useKg;
  final bool isDark;

  /// When true, inserts an EFFORT column (live heart rate from a connected
  /// wearable via [heartRateStreamProvider]) between Duration and Calories.
  /// Shows "—" when no wearable HR is streaming — never a fabricated number.
  final bool showEffort;

  const WorkoutStatsStrip({
    super.key,
    required this.workoutSeconds,
    required this.setLogs,
    required this.useKg,
    required this.isDark,
    this.showEffort = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Pull body weight off the user profile for a per-user kcal estimate.
    // AsyncValue.when keeps the fallback quiet while the profile loads —
    // we don't surface "--" here because the strip should never look empty.
    final bodyWeightKg = ref.watch(currentUserProvider).maybeWhen(
          data: (u) => (u?.weightKg != null && u!.weightKg! > 0)
              ? u.weightKg!
              : _kFallbackBodyWeightKg,
          orElse: () => _kFallbackBodyWeightKg,
        );

    final totalVolumeKg = _computeVolumeKg(setLogs, bodyWeightKg: bodyWeightKg);
    final calories = _computeCalories(
      seconds: workoutSeconds,
      bodyWeightKg: bodyWeightKg,
      totalVolumeKg: totalVolumeKg,
      totalSets: setLogs.where((s) => s.setType.toLowerCase() != 'warmup').length,
    );

    // Live heart rate (EFFORT) — only when requested AND a wearable is
    // actively streaming samples. No data → "—" (honest, never faked).
    final int? liveHr = showEffort
        ? ref.watch(heartRateStreamProvider).maybeWhen(
              data: (bpm) => bpm > 0 ? bpm : null,
              orElse: () => null,
            )
        : null;

    final textPrimary = isDark ? AppColors.textPrimary : Colors.black87;
    final textMuted = isDark ? AppColors.textMuted : Colors.grey.shade600;
    final divider = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: divider, width: 0.5),
        ),
      ),
      // E2E #134 — a bare Row of Expanded(_StatColumn) with zero gap or
      // divider let two long centered values in adjacent narrow columns
      // (e.g. "161 kcal" / "666 kg") run hard against each other at the
      // column boundary. IntrinsicHeight + a hairline VerticalDivider
      // between every column gives each stat clear separation.
      child: IntrinsicHeight(
        child: Row(
          children: _statColumns(
            context: context,
            divider: divider,
            liveHr: liveHr,
            calories: calories,
            totalVolumeKg: totalVolumeKg,
            textPrimary: textPrimary,
            textMuted: textMuted,
          ),
        ),
      ),
    );
  }

  List<Widget> _statColumns({
    required BuildContext context,
    required Color divider,
    required int? liveHr,
    required int calories,
    required double totalVolumeKg,
    required Color textPrimary,
    required Color textMuted,
  }) {
    Widget sep() => VerticalDivider(color: divider, width: 17, thickness: 1);

    final columns = <_StatColumn>[
      _StatColumn(
        label: AppLocalizations.of(context).workoutSummaryGeneralDuration,
        value: _formatDuration(workoutSeconds),
        leadingDot: true,
        textPrimary: textPrimary,
        textMuted: textMuted,
      ),
      if (showEffort)
        _StatColumn(
          label: 'EFFORT',
          value: liveHr != null ? '$liveHr ♥' : '—',
          textPrimary: textPrimary,
          textMuted: textMuted,
        ),
      _StatColumn(
        label: AppLocalizations.of(context).workoutSummaryGeneralCalories,
        value: AppLocalizations.of(context)!.workoutStatsStripKcal(calories),
        textPrimary: textPrimary,
        textMuted: textMuted,
      ),
      _StatColumn(
        label: AppLocalizations.of(context).workoutSummaryAdvancedVolume,
        value: _formatVolume(totalVolumeKg, useKg: useKg),
        textPrimary: textPrimary,
        textMuted: textMuted,
      ),
    ];

    final row = <Widget>[];
    for (var i = 0; i < columns.length; i++) {
      row.add(Expanded(child: columns[i]));
      if (i != columns.length - 1) row.add(sep());
    }
    return row;
  }

  /// Bodyweight "load" fraction used when a working set has no external load,
  /// so a bodyweight set isn't counted as 0 volume (which read as "Volume 0"
  /// mid-workout while the completion summary showed a non-zero number). This
  /// mirrors the backend default in `bodyweight_proxy_load_kg`
  /// (`_BW_FRACTION_DEFAULT = 0.60`). The live strip can't see each set's
  /// exercise (SetLog carries no name/pattern), so it uses the single default
  /// fraction; the post-workout summary remains authoritative with the finer
  /// per-movement-pattern fractions.
  static const double _kBodyweightVolumeFraction = 0.60;

  static double _computeVolumeKg(List<SetLog> logs, {required double bodyWeightKg}) {
    double total = 0;
    for (final s in logs) {
      // Skip warmup sets so the number matches what lifters think of as
      // "working volume" — the same convention the post-workout summary
      // uses (see workout_summary_advanced.dart → _VolumeBreakdownSection).
      if (s.setType.toLowerCase() == 'warmup') continue;
      final load = s.weight > 0
          ? s.weight
          : (bodyWeightKg > 0 ? bodyWeightKg * _kBodyweightVolumeFraction : 0);
      total += load * s.reps;
    }
    return total;
  }

  static int _computeCalories({
    required int seconds,
    required double bodyWeightKg,
    double totalVolumeKg = 0,
    int totalSets = 0,
  }) {
    if (seconds <= 0) return 0;
    // Row 139 — a flat MET ignored logged volume/sets entirely, so the live
    // header (127 kcal at 18m37s) and the completion summary's MET-based
    // estimate (which DOES factor in volume/sets/reps/etc. — see backend
    // `_calculate_completion_calories`) could read nearly double one another
    // for the identical session. Scaling MET with the same volume/sets
    // signal the backend uses brings the live number in line with what the
    // summary will actually show, instead of two independently-diverging
    // formulas for "the same" number.
    double met = _kStrengthMET;
    if (totalSets >= 15) met += 0.3;
    if (totalSets >= 25) met += 0.3;
    if (totalVolumeKg > 5000) met += 0.3;
    if (totalVolumeKg > 15000) met += 0.3;
    // kcal = MET × body_weight_kg × hours.
    final kcal = met * bodyWeightKg * (seconds / 3600.0);
    return kcal.round();
  }

  static String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    if (mins < 60) {
      return secs == 0 ? '${mins}m' : '${mins}m ${secs}s';
    }
    final hours = mins ~/ 60;
    final remMins = mins % 60;
    return remMins == 0 ? '${hours}h' : '${hours}h ${remMins}m';
  }

  static String _formatVolume(double volumeKg, {required bool useKg}) {
    final value = useKg ? volumeKg : volumeKg * 2.20462;
    final unit = useKg ? 'kg' : 'lb';
    if (value >= 1000) {
      // Thousands separator keeps long lifts readable (e.g. "12,340 lb").
      final whole = value.round();
      final str = whole.toString();
      final withCommas = str.replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
      return '$withCommas $unit';
    }
    return '${value.toStringAsFixed(0)} $unit';
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final bool leadingDot;
  final Color textPrimary;
  final Color textMuted;

  const _StatColumn({
    required this.label,
    required this.value,
    this.leadingDot = false,
    required this.textPrimary,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: textMuted,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leadingDot) ...[
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.success,  // accent-allowlist: success/positive state — must stay green regardless of accent
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            // Big, glanceable live metric. Wrapped in Flexible so the
            // FittedBox(scaleDown) inside StatNumber gets a bounded width from
            // the Expanded column and shrinks long values (e.g. "12,340 lb")
            // rather than overflowing the strip. Tabular figures keep the
            // per-second tick from jittering horizontally.
            Flexible(
              child: StatNumber(
                value: value,
                size: StatType.secondary,
                color: textPrimary,
                alignment: Alignment.center,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
