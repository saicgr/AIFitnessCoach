import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/theme_colors.dart';
import '../../../data/models/today_workout.dart';
import '../../../data/providers/today_workout_provider.dart';
import '../../../data/services/haptic_service.dart';

/// Slim secondary row rendered beneath the hero carousel for TODAY's other
/// workouts — program ADD-ONs (e.g. "+ Today's add-on: 7-Minute Core · 7
/// min") as well as any other same-day workout that isn't the hero (row
/// 269: a program session, a Quick Generate, and a Builder session could
/// all land on today with no indication more than one existed — only the
/// hero-picked one was ever visible). Sourced from `extraTodayWorkouts`
/// (every non-primary today row, regardless of `generation_source`), a
/// superset of the old add-on-only `addonTodayWorkouts`.
///
/// The primary plan stays the hero; the rest stack here as one tappable pill
/// each — an already-completed extra opens its summary instead of starting
/// it. Renders nothing when today has nothing else, so callers can mount it
/// unconditionally below the carousel.
class TodayAddonsRow extends ConsumerWidget {
  const TodayAddonsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read the live today response — same source the carousel uses, so this
    // row appears/disappears in lock-step with the hero.
    final today = ref.watch(todayWorkoutProvider).valueOrNull;
    final extras = today?.extraTodayWorkouts ?? const <TodayWorkoutSummary>[];
    if (extras.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (extras.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 6, left: 4),
              child: Text(
                '${extras.length} more today',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: ThemeColors.of(context).textSecondary,
                ),
              ),
            ),
          for (final e in extras) ...[
            _ExtraWorkoutPill(workout: e),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _ExtraWorkoutPill extends StatelessWidget {
  final TodayWorkoutSummary workout;
  const _ExtraWorkoutPill({required this.workout});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final accent = tc.accent;
    final isAddon = workout.isProgramAddon;
    final isCompleted = workout.isCompleted;

    // "7-Minute Core · 7 min · 4 exercises" — period-separated meta.
    final meta = <String>[
      if (workout.durationMinutes > 0) '${workout.durationMinutes} min',
      if (workout.exerciseCount > 0) '${workout.exerciseCount} exercises',
    ].join(' · ');

    final label = isAddon
        ? "Today's add-on · ${workout.name}"
        : (isCompleted ? 'Completed · ${workout.name}' : workout.name);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          HapticService.medium();
          if (isCompleted) {
            // A completed extra has nothing left to start — open it for
            // review instead of relaunching it as a fresh session.
            context.push('/workout/${workout.id}', extra: workout.toWorkout());
            return;
          }
          // Launch it like any workout (same as the hero START path).
          context.push('/active-workout', extra: workout.toWorkout());
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: tc.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accent.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Icon(
                isCompleted
                    ? Icons.check_circle_outline
                    : Icons.add_circle_outline,
                size: 18,
                color: accent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: tc.textPrimary,
                      ),
                    ),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: tc.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isCompleted ? Icons.chevron_right : Icons.play_arrow_rounded,
                size: 22,
                color: accent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
