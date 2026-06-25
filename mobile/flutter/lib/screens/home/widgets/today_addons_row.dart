import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/theme_colors.dart';
import '../../../data/models/today_workout.dart';
import '../../../data/providers/today_workout_provider.dart';
import '../../../data/services/haptic_service.dart';

/// Slim secondary row rendered beneath the hero carousel for TODAY's program
/// ADD-ON workouts (e.g. "+ Today's add-on: 7-Minute Core · 7 min").
///
/// The primary plan stays the hero; add-ons stack here as one tappable pill
/// each. Tapping launches the add-on like any workout (active-workout). Renders
/// nothing when today has no add-ons, so the home screen can mount it
/// unconditionally below the carousel.
class TodayAddonsRow extends ConsumerWidget {
  const TodayAddonsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read the live today response — same source the carousel uses, so add-ons
    // appear/disappear in lock-step with the hero.
    final today = ref.watch(todayWorkoutProvider).valueOrNull;
    final addons = today?.addonTodayWorkouts ?? const <TodayWorkoutSummary>[];
    if (addons.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final a in addons) ...[
            _AddonPill(addon: a),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _AddonPill extends StatelessWidget {
  final TodayWorkoutSummary addon;
  const _AddonPill({required this.addon});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final accent = tc.accent;

    // "7-Minute Core · 7 min · 4 exercises" — period-separated meta.
    final meta = <String>[
      if (addon.durationMinutes > 0) '${addon.durationMinutes} min',
      if (addon.exerciseCount > 0) '${addon.exerciseCount} exercises',
    ].join(' · ');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          HapticService.medium();
          // Launch the add-on like any workout (same as the hero START path).
          context.push('/active-workout', extra: addon.toWorkout());
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
              Icon(Icons.add_circle_outline, size: 18, color: accent),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Today's add-on · ${addon.name}",
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
              Icon(Icons.play_arrow_rounded, size: 22, color: accent),
            ],
          ),
        ),
      ),
    );
  }
}
