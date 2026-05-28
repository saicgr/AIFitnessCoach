/// F3.75 — Workout / sleep correlation card.
///
/// Surfaces a 2-4 week pattern: "On days you train, you sleep X min more"
/// (or fewer). Pulls from a future correlation provider; collapses if the
/// provider can't make a confident call (low N, error, or |delta| < 10 min).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/providers/workout_sleep_correlation_provider.dart';
import '../../../../data/services/haptic_service.dart';

class WorkoutSleepCorrelation {
  /// Relative REM drop (0..1) on nights following late (>=8 PM local)
  /// workouts vs the 28-day baseline. Always positive — the API only returns
  /// the value when there's a meaningful REM *drop*.
  final double remDropPct;

  /// Number of late-workout nights backing the finding (N >= 3 to surface).
  final int sampleDays;

  const WorkoutSleepCorrelation({
    required this.remDropPct,
    required this.sampleDays,
  });
}

/// Server-backed late-workout / REM correlation —
/// `GET /insights/workout-sleep-correlation`. Returns null when no signal.
final workoutSleepCorrelationProvider =
    Provider.autoDispose<WorkoutSleepCorrelation?>((ref) {
  final async = ref.watch(workoutSleepCorrelationApiProvider);
  return async.when(
    data: (api) {
      if (!api.hasFinding) return null;
      return WorkoutSleepCorrelation(
        remDropPct: api.remDropPct!,
        sampleDays: api.sampleSize,
      );
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

class WorkoutSleepCorrelationCard extends ConsumerWidget {
  const WorkoutSleepCorrelationCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WorkoutSleepCorrelation? data;
    try {
      data = ref.watch(workoutSleepCorrelationProvider);
    } catch (_) {
      return const SizedBox.shrink();
    }
    // Server gates by N>=3 and >=10% relative drop; double-check here so a
    // stale provider value still self-collapses on a bad payload.
    if (data == null || data.sampleDays < 3 || data.remDropPct < 0.10) {
      return const SizedBox.shrink();
    }

    final c = ThemeColors.of(context);
    // remDropPct is always a *drop* — present as "Late workouts cost you X%
    // REM" so the card is unambiguously a warning, not a positive note.
    final dropPct = (data.remDropPct * 100).round();
    final headline = 'Late workouts cost you $dropPct% REM';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 18,
              color: c.accent,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                headline,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Text(
            'Across ${data.sampleDays} late-night sessions (after 8 PM), '
            'your REM drops $dropPct% vs your 4-week baseline. '
            'Consider moving sessions earlier.',
            style: TextStyle(fontSize: 12.5, height: 1.4, color: c.textSecondary),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              HapticService.light();
              context.push('/insights/sleep');
            },
            child: Text(
              'View sleep insights →',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: c.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
