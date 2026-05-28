/// F3.114 — Planned vs actual card.
///
/// Compares planned volume/duration vs actual for today's completed
/// session, sourced from `GET /api/v1/workouts/{id}/planned-vs-actual`.
/// Self-collapses while there's no actuals signal.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/providers/home_signals_providers.dart';
import '../../../../data/providers/today_workout_provider.dart';

class PlannedVsActualCard extends ConsumerWidget {
  const PlannedVsActualCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayWorkoutProvider).valueOrNull;
    final completed = today?.completedToday ?? false;
    final workoutId = today?.todayWorkout?.id;
    if (!completed || workoutId == null) return const SizedBox.shrink();

    final pva = ref.watch(plannedVsActualProvider(workoutId)).valueOrNull;
    if (pva == null || !pva.hasAnySignal) return const SizedBox.shrink();

    final c = ThemeColors.of(context);

    final plannedSetsLabel = pva.plannedSets?.toString() ?? '–';
    final actualSetsLabel = pva.actualSets?.toString() ?? '–';
    final plannedMinLabel =
        pva.plannedDurationMin != null ? '${pva.plannedDurationMin}m' : '–';
    final actualMinLabel =
        pva.actualDurationMin != null ? '${pva.actualDurationMin}m' : '–';
    final delta = pva.deltaPct;
    final deltaLabel = delta == null
        ? null
        : (delta >= 0 ? '+${delta.toStringAsFixed(0)}%' : '${delta.toStringAsFixed(0)}%');
    final deltaColor =
        delta == null ? c.textSecondary : (delta >= 0 ? c.success : c.warning);

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
                Icon(Icons.compare_arrows, size: 18, color: c.accent),
                const SizedBox(width: 8),
                Text(
                  'Planned vs actual',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary,
                  ),
                ),
                const Spacer(),
                if (deltaLabel != null)
                  Text(
                    deltaLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: deltaColor,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _statBlock(c, 'Sets',
                      '$actualSetsLabel / $plannedSetsLabel'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _statBlock(c, 'Duration',
                      '$actualMinLabel / $plannedMinLabel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statBlock(ThemeColors c, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: c.elevated,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: c.textMuted,
                  letterSpacing: 0.5)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: c.textPrimary)),
        ],
      ),
    );
  }
}
