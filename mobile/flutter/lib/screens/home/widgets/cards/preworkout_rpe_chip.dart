/// F3.102 — Pre-workout RPE expectation chip.
///
/// Compact chip in the T-30 band: "Expect RPE 7-8 today" so the user
/// calibrates effort before walking in. Tapping opens chat with context.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/providers/recovery_provider.dart';
import '../../../../data/providers/today_workout_provider.dart';
import '../../../../data/services/haptic_service.dart';

class PreWorkoutRpeChip extends ConsumerWidget {
  const PreWorkoutRpeChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayWorkoutProvider).valueOrNull?.todayWorkout;
    if (today == null) return const SizedBox.shrink();
    final hour = DateTime.now().hour;
    if (hour < 16 || hour >= 20) return const SizedBox.shrink();

    final c = ThemeColors.of(context);
    // Coarse target band derived from objective recovery score:
    //   ≥80 (Excellent) → push it (RPE 8-9)
    //   60-79 (Good)    → standard intensity (7-8)
    //   <60 (Fair/Poor) → pull back (6-7)
    // Self-collapses when Health Connect isn't wired so we don't fabricate.
    final recovery = ref.watch(recoveryProvider).valueOrNull;
    if (recovery == null) return const SizedBox.shrink();
    final String target;
    if (recovery.score >= 80) {
      target = '8-9';
    } else if (recovery.score >= 60) {
      target = '7-8';
    } else {
      target = '6-7';
    }

    return GestureDetector(
      onTap: () {
        HapticService.light();
        context.push('/chat?source=rpe_explain');
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.cardBorder),
        ),
        child: Row(
          children: [
            Icon(Icons.speed, size: 18, color: c.accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: TextStyle(fontSize: 13, color: c.textSecondary),
                  children: [
                    const TextSpan(text: 'Today aim for '),
                    TextSpan(
                      text: 'RPE $target',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: c.textPrimary,
                      ),
                    ),
                    const TextSpan(text: ' — hard, but a clean rep in reserve.'),
                  ],
                ),
              ),
            ),
            Icon(Icons.info_outline, color: c.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}
