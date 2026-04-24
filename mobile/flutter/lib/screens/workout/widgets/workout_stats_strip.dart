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
import '../../../core/providers/user_provider.dart';
import '../models/workout_state.dart';

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

  const WorkoutStatsStrip({
    super.key,
    required this.workoutSeconds,
    required this.setLogs,
    required this.useKg,
    required this.isDark,
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

    final totalVolumeKg = _computeVolumeKg(setLogs);
    final calories = _computeCalories(
      seconds: workoutSeconds,
      bodyWeightKg: bodyWeightKg,
    );

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
      child: Row(
        children: [
          Expanded(
            child: _StatColumn(
              label: 'Duration',
              value: _formatDuration(workoutSeconds),
              leadingDot: true,
              textPrimary: textPrimary,
              textMuted: textMuted,
            ),
          ),
          Expanded(
            child: _StatColumn(
              label: 'Calories',
              value: '$calories kcal',
              textPrimary: textPrimary,
              textMuted: textMuted,
            ),
          ),
          Expanded(
            child: _StatColumn(
              label: 'Volume',
              value: _formatVolume(totalVolumeKg, useKg: useKg),
              textPrimary: textPrimary,
              textMuted: textMuted,
            ),
          ),
        ],
      ),
    );
  }

  static double _computeVolumeKg(List<SetLog> logs) {
    double total = 0;
    for (final s in logs) {
      // Skip warmup sets so the number matches what lifters think of as
      // "working volume" — the same convention the post-workout summary
      // uses (see workout_summary_advanced.dart → _VolumeBreakdownSection).
      if (s.setType.toLowerCase() == 'warmup') continue;
      total += s.weight * s.reps;
    }
    return total;
  }

  static int _computeCalories({
    required int seconds,
    required double bodyWeightKg,
  }) {
    if (seconds <= 0) return 0;
    // kcal = MET × body_weight_kg × hours.
    final kcal = _kStrengthMET * bodyWeightKg * (seconds / 3600.0);
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
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: textPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
