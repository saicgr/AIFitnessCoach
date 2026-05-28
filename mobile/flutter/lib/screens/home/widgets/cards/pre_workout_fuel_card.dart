/// F3.73 — Pre-workout fuel card.
///
/// Sub-card variant of the pre-workout-fuel nudge. Renders only inside the
/// 60-90 min pre-workout band; the ranker decides eligibility based on
/// schedule + last meal. Pure presentation.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/providers/home_signals_providers.dart';
import '../../../../data/services/haptic_service.dart';

// Schedule-aware fuel nudge. Card fires inside a 60-90 min pre-workout band
// computed from `workouts.scheduled_local_time` (exposed via
// `GET /api/v1/workouts/today/schedule`). The suggestion text is a static
// rule-of-thumb until a true nutrition planner endpoint lands — we do not
// invent timing data when no schedule is set.

class PreWorkoutFuelCard extends ConsumerWidget {
  final bool show;
  final int minutesUntilWorkout;
  final String suggestion;

  const PreWorkoutFuelCard({
    super.key,
    this.show = true,
    this.minutesUntilWorkout = 75,
    this.suggestion =
        '30g carbs + 15g protein — banana + Greek yogurt is the lazy classic.',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!show) return const SizedBox.shrink();
    // When a schedule is available, recompute minutes-until live and
    // self-collapse outside the 60-90 min pre-workout band.
    final schedule = ref.watch(todayWorkoutScheduleProvider).valueOrNull;
    int liveMinutes = minutesUntilWorkout;
    if (schedule?.scheduledLocalTime != null) {
      final m = minutesUntilLocal(schedule!.scheduledLocalTime, DateTime.now());
      if (m == null) return const SizedBox.shrink();
      if (m < 60 || m > 90) return const SizedBox.shrink();
      liveMinutes = m;
    }
    final c = ThemeColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('🍌', style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  'PRE-WORKOUT FUEL',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: c.textMuted,
                  ),
                ),
                const Spacer(),
                Text(
                  'in ${liveMinutes}m',
                  style: TextStyle(
                      fontSize: 11.5,
                      color: c.textSecondary,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              suggestion,
              style: TextStyle(
                  fontSize: 13,
                  color: c.textPrimary,
                  height: 1.35,
                  fontWeight: FontWeight.w600),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  HapticService.light();
                  context.push('/nutrition?action=quick_log');
                },
                style: TextButton.styleFrom(
                  backgroundColor: c.accent,
                  foregroundColor: c.accentContrast,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  minimumSize: const Size(0, 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: const Text(
                  'Log fuel',
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
