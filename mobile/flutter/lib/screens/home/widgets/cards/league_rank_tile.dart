/// F3.49 — League rank tile. Surfaces the user's current league + rank
/// based on weekly XP. Reads xpProvider for current level/title as a
/// proxy until a dedicated league endpoint ships.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/providers/xp_provider.dart';
import '../../../../data/services/haptic_service.dart';

class LeagueRankTile extends ConsumerWidget {
  const LeagueRankTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ThemeColors.of(context);

    int level = 0;
    int totalXp = 0;
    try {
      level = ref.watch(xpProvider).currentLevel;
      totalXp = ref.watch(xpProvider).totalXp;
    } catch (_) {
      return const SizedBox.shrink();
    }
    if (level <= 0 && totalXp <= 0) return const SizedBox.shrink();

    final league = _leagueForLevel(level);

    return GestureDetector(
      onTap: () {
        HapticService.light();
        context.push('/profile?tab=leaderboard');
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: league.tint.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(league.emoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${league.name} league',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Level $level · $totalXp XP',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: c.textSecondary,
                    ),
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

  _League _leagueForLevel(int level) {
    if (level >= 40) return const _League('Diamond', '💎', Color(0xFF7FD8FF));
    if (level >= 25) return const _League('Gold', '🥇', Color(0xFFFFD27A));
    if (level >= 12) return const _League('Silver', '🥈', Color(0xFFCBCBCB));
    return const _League('Bronze', '🥉', Color(0xFFCD9367));
  }
}

class _League {
  final String name;
  final String emoji;
  final Color tint;
  const _League(this.name, this.emoji, this.tint);
}
