/// F3.99 — Fasting streak tile.
///
/// Surfaces the consecutive-days fasting streak (and best-ever) as a small
/// tile. Self-collapses if streak is 0 (no point shouting about zero).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/providers/fasting_provider.dart';
import '../../../../data/services/haptic_service.dart';

class FastStreakTile extends ConsumerWidget {
  const FastStreakTile({super.key});

  ({int current, int best}) _readStreak(WidgetRef ref) {
    final streak = ref.watch(fastingStreakProvider);
    if (streak == null) return (current: 0, best: 0);
    return (current: streak.currentStreak, best: streak.longestStreak);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = _readStreak(ref);
    if (s.current == 0) return const SizedBox.shrink();
    final c = ThemeColors.of(context);

    return GestureDetector(
      onTap: () {
        HapticService.light();
        context.push('/fasting?tab=streak');
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
            const Text('🔥', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${s.current}-day fast streak',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Best: ${s.best} days',
                    style: TextStyle(fontSize: 12, color: c.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: c.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
