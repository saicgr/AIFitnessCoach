/// F3.101 — Pre-workout warm-up suggestion card.
///
/// Shows a tailored warm-up routine (e.g. "5 min row + dynamic stretches")
/// in the T-30 pre-workout band. Self-collapses if no workout is scheduled
/// today or the window has closed.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/providers/today_workout_provider.dart';
import '../../../../data/services/haptic_service.dart';

class PreWorkoutWarmupCard extends ConsumerWidget {
  const PreWorkoutWarmupCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayWorkoutProvider).valueOrNull?.todayWorkout;
    if (today == null) return const SizedBox.shrink();

    final hour = DateTime.now().hour;
    if (hour < 16 || hour >= 20) return const SizedBox.shrink();

    final c = ThemeColors.of(context);
    // Pull the first 3 exercises from today's plan so the user sees what
    // they're actually about to do, not a generic template. Backend does
    // not yet flag warm-up sets at the exercise level — we surface the
    // opening lifts as the implicit warm-up cue.
    // TODO(backend): expose explicit warm-up block on today_workout payload.
    final names = today.exercises
        .map((e) => (e.nameValue ?? '').trim())
        .where((n) => n.isNotEmpty)
        .take(3)
        .toList(growable: false);
    if (names.isEmpty) return const SizedBox.shrink();
    final flow = (
      title: 'Warm up to today',
      body: 'Easy sets of: ${names.join(' · ')}.',
    );

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
          border: Border.all(color: c.cardBorder),
        ),
        child: Row(
          children: [
            const Text('🔥', style: TextStyle(fontSize: 26)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    flow.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    flow.body,
                    style: TextStyle(fontSize: 12, color: c.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
