/// F3.100 — Pre-workout T-30 minute band card.
///
/// Surfaces a countdown 30 minutes before today's scheduled workout starts.
/// Self-collapses outside the T-30 window or when no workout is scheduled.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/providers/home_signals_providers.dart';
import '../../../../data/providers/today_workout_provider.dart';
import '../../../../data/services/haptic_service.dart';

class PreWorkoutT30Card extends ConsumerWidget {
  const PreWorkoutT30Card({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayWorkoutProvider).valueOrNull?.todayWorkout;
    if (today == null) return const SizedBox.shrink();

    // Real schedule from `GET /api/v1/workouts/today/schedule`. Self-collapses
    // when the user hasn't set a `scheduled_local_time` for today's workout.
    final schedule = ref.watch(todayWorkoutScheduleProvider).valueOrNull;
    final hhmm = schedule?.scheduledLocalTime;
    if (hhmm == null) return const SizedBox.shrink();
    final now = DateTime.now();
    final minsUntil = minutesUntilLocal(hhmm, now);
    if (minsUntil == null || minsUntil <= 0 || minsUntil > 30) {
      return const SizedBox.shrink();
    }

    final c = ThemeColors.of(context);
    return GestureDetector(
      onTap: () {
        HapticService.light();
        context.push('/workout/${today.id}', extra: today);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.accent.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.bolt, size: 28, color: c.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Workout in $minsUntil min',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Hydrate, fuel, warm up.',
                    style: TextStyle(fontSize: 12, color: c.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: c.textMuted),
          ],
        ),
      ),
    );
  }
}
