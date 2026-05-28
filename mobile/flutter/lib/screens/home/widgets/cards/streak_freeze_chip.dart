/// F3.47 — Banked streak-freeze chip. Surfaces how many freeze tokens the
/// user has available. Tap routes to the streaks/profile surface.
/// Collapses when zero freezes are banked.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/providers/xp_provider.dart';
import '../../../../data/services/haptic_service.dart';

class StreakFreezeChip extends ConsumerWidget {
  const StreakFreezeChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ThemeColors.of(context);

    int freezes = 0;
    try {
      freezes = ref.watch(xpFreezesAvailableProvider);
    } catch (_) {
      return const SizedBox.shrink();
    }
    if (freezes <= 0) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        HapticService.light();
        context.push('/profile?tab=streaks');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🧊', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$freezes streak freeze${freezes == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Protects a missed day.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
