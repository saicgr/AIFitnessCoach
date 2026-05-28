/// F3.122 — Post-workout progress-photo prompt.
///
/// Gentle CTA after a session to capture a weekly progress photo. Only
/// surfaces on the user's preferred check-in day-of-week (Monday by
/// default) and after a completed workout.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/providers/today_workout_provider.dart';
import '../../../../data/services/haptic_service.dart';

class PostWorkoutProgressPhotoPrompt extends ConsumerWidget {
  const PostWorkoutProgressPhotoPrompt({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayWorkoutProvider).valueOrNull;
    final completed = today?.completedToday ?? false;
    if (!completed) return const SizedBox.shrink();
    final now = DateTime.now();
    if (now.weekday != DateTime.monday) return const SizedBox.shrink();

    final c = ThemeColors.of(context);
    return GestureDetector(
      onTap: () {
        HapticService.light();
        context.push('/profile?tab=photos');
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
            const Text('📸', style: TextStyle(fontSize: 26)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weekly progress photo',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Same time, same light — 10 seconds and you\'re done.',
                    style: TextStyle(fontSize: 12, color: c.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
