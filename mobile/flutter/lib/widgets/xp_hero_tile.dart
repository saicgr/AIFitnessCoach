import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/theme_colors.dart';
import '../data/providers/xp_provider.dart';

/// Slim XP hero tile used on the You hub (Overview + Stats & Rewards).
///
/// Surface 5.A.4 rewrite. Previously this was a 3-row card with an
/// accent-tinted surface, a 7-day sparkline, a reward preview chip and a
/// streak nudge — far above the 10% accent budget for a tile that lives
/// alongside the gamification grid. The redesign:
///   • Neutral card surface (no accent fill).
///   • Single headline row: `Lvl 9 · 590 / 2100 XP`.
///   • Compact progress bar underneath.
///   • Tap routes to `/xp-goals` for the full sparkline, weekly delta,
///     reward preview and nudge (those details live in the detail screen,
///     not the at-a-glance tile).
///
/// The [muted] parameter is preserved so Serious Mode can dim the tile
/// further; it now only affects opacity, not the surface tint.
class XpHeroTile extends ConsumerWidget {
  final bool muted;

  const XpHeroTile({super.key, this.muted = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ThemeColors.of(context);
    final userXp = ref.watch(userXpProvider);

    final level = userXp?.currentLevel ?? 1;
    final progress = userXp?.progressFraction ?? 0.0;
    final xpInLevel = userXp?.xpInCurrentLevel ?? 0;
    final xpToNext = userXp?.xpToNextLevel ?? 150;

    final opacity = muted ? 0.7 : 1.0;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        // TODO: when the dedicated level-detail route ships, route there
        // instead of /xp-goals. /xp-goals currently hosts the full
        // sparkline + reward preview that this tile used to inline, so
        // it's the correct destination for the moved content.
        context.push('/xp-goals');
      },
      child: Opacity(
        opacity: opacity,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            // Neutral surface only — accent is reserved for primary CTAs
            // per the redesign's color budget.
            color: c.elevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Lvl $level · $xpInLevel / $xpToNext XP',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: c.textPrimary,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: c.textMuted, size: 20),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: c.textMuted.withValues(alpha: 0.18),
                  valueColor: AlwaysStoppedAnimation<Color>(c.accent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
