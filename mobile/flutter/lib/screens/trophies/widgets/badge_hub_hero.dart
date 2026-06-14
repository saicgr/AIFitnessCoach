import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/services/haptic_service.dart';

import '../../../l10n/generated/app_localizations.dart';
/// Signature hairline-led Badge Hub hero. No boxed teal gradient — an Anton
/// masthead with a floating gold badge cluster and a Fraunces subline. Gold
/// is the trophy accent (the one colored accent the gamification surfaces are
/// allowed); the "How it works" affordance stays muted.
class BadgeHubHero extends StatelessWidget {
  final VoidCallback onHowItWorksTap;

  const BadgeHubHero({super.key, required this.onHowItWorksTap});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        HapticService.light();
        onHowItWorksTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Floating gold badge cluster
            const SizedBox(
              width: 64,
              height: 56,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  PositionedDirectional(start: 0, top: 4, child: _HeroBadge(emoji: '🏆', gold: true)),
                  PositionedDirectional(end: 0, top: 0, child: _HeroBadge(emoji: '🥇')),
                  PositionedDirectional(start: 14, bottom: 0, child: _HeroBadge(emoji: '🔥')),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.of(context).badgeHubRewardYourProgress.toUpperCase(),
                    style: ZType.disp(21, color: tc.textPrimary, height: 0.96),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    AppLocalizations.of(context).badgeHubHeroEarnBadgesForEvery,
                    style: ZType.ser(13, color: tc.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.info_outline, size: 18, color: tc.textMuted),
          ],
        ),
      ),
    );
  }
}


class _HeroBadge extends StatelessWidget {
  final String emoji;
  final bool gold;

  const _HeroBadge({required this.emoji, this.gold = false});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: gold
            ? AppColors.gamGold.withValues(alpha: 0.08)
            : tc.surface,
        border: Border.all(
          color: gold
              ? AppColors.gamGold.withValues(alpha: 0.5)
              : AppColors.cardBorder,
        ),
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 15)),
    );
  }
}
