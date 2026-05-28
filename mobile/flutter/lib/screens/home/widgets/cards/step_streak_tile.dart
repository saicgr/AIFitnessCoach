/// F3.23 — Step streak tile.
///
/// Shows current consecutive-days-hitting-step-goal streak. Collapses when
/// streak is unknown or 0.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/providers/combined_health_provider.dart';
import '../../../../data/providers/neat_provider.dart';

/// (streakDays, todaySteps, goal) derived from real providers:
///   • `combinedHealthHistoryProvider.activityStreak(goal)` — consecutive
///     days hitting the step goal, computed off the same `/activity/history`
///     rows the Combined Health hub uses (independent of workout completion).
///   • `currentStepsProvider` / `stepGoalProvider` — live NEAT step state.
/// Returns (null, _, goal) until at least one streak day exists.
final stepStreakSignalProvider =
    Provider.autoDispose<({int? streakDays, int? todaySteps, int goal})>((ref) {
  final goal = ref.watch(stepGoalProvider);
  final today = ref.watch(currentStepsProvider);
  final historyAsync = ref.watch(combinedHealthHistoryProvider);
  final streak = historyAsync.maybeWhen(
    data: (h) {
      if (!h.hasData) return null;
      final s = h.activityStreak(goal);
      return s > 0 ? s : null;
    },
    orElse: () => null,
  );
  return (
    streakDays: streak,
    todaySteps: today > 0 ? today : null,
    goal: goal > 0 ? goal : 8000,
  );
});

class StepStreakTile extends ConsumerWidget {
  /// Days in current streak. Null or zero → collapsed.
  final int? streakDays;

  /// Today's step count (optional secondary display).
  final int? todaySteps;

  /// Step goal (default 8000 — common Apple Watch default).
  final int goal;

  const StepStreakTile({
    super.key,
    this.streakDays,
    this.todaySteps,
    this.goal = 8000,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signal = ref.watch(stepStreakSignalProvider);
    final s = streakDays ?? signal.streakDays;
    if (s == null || s <= 0) return const SizedBox.shrink();
    final c = ThemeColors.of(context);
    final effGoal = streakDays != null ? goal : signal.goal;
    final effTodaySteps = todaySteps ?? signal.todaySteps;
    final pct = effTodaySteps == null
        ? null
        : (effTodaySteps / effGoal).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () => context.go('/progress'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.directions_walk, size: 16, color: c.accent),
                const SizedBox(width: 6),
                Text(
                  'Step streak',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$s',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary,
                    height: 1.0,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  s == 1 ? 'day' : 'days',
                  style: TextStyle(fontSize: 12, color: c.textMuted),
                ),
              ],
            ),
            if (pct != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 6,
                  backgroundColor: c.cardBorder,
                  valueColor: AlwaysStoppedAnimation<Color>(c.accent),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$effTodaySteps / $effGoal today',
                style: TextStyle(fontSize: 11.5, color: c.textMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
