/// F3.78 — Return-to-exercise card.
///
/// After ≥7 days of no logged sessions, surface a "welcome back" card with a
/// downscaled re-entry workout suggestion (NSCA detraining guidance: drop
/// volume ~30-50% on first session back). Collapses silently if the user
/// has trained recently.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/services/haptic_service.dart';

class ReturnToExerciseSignal {
  final int daysSinceLastWorkout;
  final int suggestedVolumePct; // 50, 70, etc.
  const ReturnToExerciseSignal({
    required this.daysSinceLastWorkout,
    required this.suggestedVolumePct,
  });
}

// TODO(backend): GET /api/v1/insights/return-to-exercise — needs a
// last-session-timestamp endpoint (no workout-history provider exists yet on
// the Flutter side; today_workout_provider is plan-only, not history) plus
// the deterministic NSCA volume-pct rule (>=14d: 50%, 7-13d: 70%).
final returnToExerciseSignalProvider =
    Provider.autoDispose<ReturnToExerciseSignal?>((ref) => null);

class ReturnToExerciseCard extends ConsumerWidget {
  const ReturnToExerciseCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ReturnToExerciseSignal? signal;
    try {
      signal = ref.watch(returnToExerciseSignalProvider);
    } catch (_) {
      return const SizedBox.shrink();
    }
    if (signal == null || signal.daysSinceLastWorkout < 7) {
      return const SizedBox.shrink();
    }

    final c = ThemeColors.of(context);
    final weeks = (signal.daysSinceLastWorkout / 7).floor();
    final timeAway = weeks >= 2
        ? '$weeks weeks'
        : '${signal.daysSinceLastWorkout} days';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.waving_hand_rounded, size: 18, color: c.accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Welcome back',
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
            "It's been $timeAway. Today's session is dialled to ${signal.suggestedVolumePct}% so you can ease back without trashing tomorrow.",
            style: TextStyle(fontSize: 12.5, height: 1.4, color: c.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  HapticService.medium();
                  context.push('/workout/active');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Start re-entry workout',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}
