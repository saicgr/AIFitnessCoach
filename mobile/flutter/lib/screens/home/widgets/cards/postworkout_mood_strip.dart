/// F3.119 — Post-workout mood strip.
///
/// 5 emoji buttons (😫 / 😕 / 😐 / 🙂 / 😄) for a one-tap "how did that
/// feel" log right after a completed session. Self-collapses outside the
/// post-workout window.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/providers/today_workout_provider.dart';
import '../../../../data/services/haptic_service.dart';

class PostWorkoutMoodStrip extends ConsumerWidget {
  const PostWorkoutMoodStrip({super.key});

  static const _faces = ['😫', '😕', '😐', '🙂', '😄'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayWorkoutProvider).valueOrNull;
    final completed = today?.completedToday ?? false;
    if (!completed) return const SizedBox.shrink();

    final c = ThemeColors.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
          Text(
            'How did that feel?',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < _faces.length; i++)
                InkWell(
                  onTap: () {
                    HapticService.light();
                    context.push('/chat?source=workout_mood&value=${i + 1}');
                  },
                  borderRadius: BorderRadius.circular(99),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: c.cardBorder.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: Text(_faces[i],
                        style: const TextStyle(fontSize: 22)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
