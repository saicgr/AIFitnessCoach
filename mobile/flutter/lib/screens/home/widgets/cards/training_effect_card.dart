/// F3.111 — Training Effect card.
///
/// Garmin-style post-workout summary: Aerobic + Anaerobic training effect
/// on a 1-5 scale, plus strain delta vs the user's 14-day mean.
/// Self-collapses while no completed workout / no signal is wired.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/providers/today_workout_provider.dart';
import '../../../../data/providers/training_effect_provider.dart';

class TrainingEffectCard extends ConsumerWidget {
  const TrainingEffectCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayWorkoutProvider).valueOrNull;
    final completed = today?.completedToday ?? false;
    if (!completed) return const SizedBox.shrink();

    // The training-effect endpoint keys on `workouts.id` (parent), which is
    // what `completedWorkout.id` carries. Without an id we have nothing to
    // ask for — collapse silently.
    final workoutId = today?.completedWorkout?.id ?? today?.todayWorkout?.id;
    if (workoutId == null || workoutId.isEmpty) {
      return const SizedBox.shrink();
    }

    final effectAsync = ref.watch(trainingEffectProvider(workoutId));
    final effect = effectAsync.valueOrNull;
    if (effect == null) return const SizedBox.shrink();

    final c = ThemeColors.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
              Icon(Icons.bolt_outlined, size: 18, color: c.accent),
              const SizedBox(width: 6),
              Text(
                'Training effect',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: c.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: c.accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  effect.primaryBenefit.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: c.accent,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _Score(
                label: 'Aerobic',
                value: effect.aerobic,
                tint: const Color(0xFF60A5FA),
              ),
              const SizedBox(width: 14),
              _Score(
                label: 'Anaerobic',
                value: effect.anaerobic,
                tint: const Color(0xFFFB7185),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            effect.strainDelta == 0
                ? 'On par with your 14-day average'
                : (effect.strainDelta > 0
                    ? '+${effect.strainDelta.toStringAsFixed(0)}m vs 14-day avg'
                    : '${effect.strainDelta.toStringAsFixed(0)}m vs 14-day avg'),
            style: TextStyle(fontSize: 12, color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _Score extends StatelessWidget {
  final String label;
  final double? value;
  final Color tint;
  const _Score({required this.label, required this.value, required this.tint});

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    final v = value;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: tint.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tint.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: c.textSecondary)),
            const SizedBox(height: 2),
            Text(
              v == null ? '—' : v.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: c.textPrimary,
              ),
            ),
            Text(
              v == null ? 'no HR data' : 'of 5.0',
              style: TextStyle(fontSize: 10, color: c.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
