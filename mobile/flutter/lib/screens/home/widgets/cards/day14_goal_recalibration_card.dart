/// F3.87 — Day-14 goal recalibration card.
///
/// On day 14 (and not before), prompt the user to re-tune their goal based
/// on the first two weeks of real adherence. Surfaces once, dismissible,
/// hides after the recalibration flow completes.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/services/haptic_service.dart';

class Day14GoalRecalibrationSignal {
  final int adherencePct; // 0-100
  final String goalLabel; // "lose 0.5 kg/wk"
  final bool shouldShow; // pre-resolved by provider (day == 14 AND not done)
  const Day14GoalRecalibrationSignal({
    required this.adherencePct,
    required this.goalLabel,
    required this.shouldShow,
  });
}

// TODO(backend): GET /api/v1/insights/two-week-checkin — returns
// {adherence_pct, goal_label, completed} for the user. We can derive the
// day-14 trigger locally from auth user `created_at`, but adherencePct and
// goalLabel come from server-side aggregation (workouts logged vs planned,
// macros vs target, weight trend) and must not be faked here.
final day14GoalRecalibrationProvider =
    Provider.autoDispose<Day14GoalRecalibrationSignal?>((ref) => null);

class Day14GoalRecalibrationCard extends ConsumerWidget {
  const Day14GoalRecalibrationCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Day14GoalRecalibrationSignal? signal;
    try {
      signal = ref.watch(day14GoalRecalibrationProvider);
    } catch (_) {
      return const SizedBox.shrink();
    }
    if (signal == null || !signal.shouldShow) {
      return const SizedBox.shrink();
    }

    final c = ThemeColors.of(context);
    final tooAggressive = signal.adherencePct < 60;
    final tooEasy = signal.adherencePct > 95;
    final tone = tooAggressive
        ? 'Your goal may be a touch aggressive — adherence is ${signal.adherencePct}%.'
        : tooEasy
            ? 'You\'re crushing this (${signal.adherencePct}% adherence). Want to push harder?'
            : 'Two weeks in at ${signal.adherencePct}% adherence — a good moment to confirm or tune.';

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
            Icon(Icons.tune_rounded, size: 18, color: c.accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Two-week check-in',
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
            'Goal: ${signal.goalLabel}. $tone',
            style: TextStyle(fontSize: 12.5, height: 1.4, color: c.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  HapticService.medium();
                  context.push('/profile/goals/recalibrate');
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
                  'Recalibrate goal',
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
