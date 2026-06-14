import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/models/trophy.dart';

import '../../../l10n/generated/app_localizations.dart';
/// Signature MY BADGES showcase — earned trophies as rarity tiles on a
/// hairline, each emblem ringed in its own metal (Gold / Plat / Silver /
/// Bronze). Replaces the purple→pink gradient panel. Stays alive with an
/// empty state when the user has earned nothing yet.
class MyBadgesShowcase extends StatelessWidget {
  final List<TrophyProgress> earned;
  final int totalTrophies;

  const MyBadgesShowcase({
    super.key,
    required this.earned,
    required this.totalTrophies,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final hasBadges = earned.isNotEmpty;
    final recent = earned.take(4).toList();

    if (!hasBadges) {
      return _EmptyShowcase(total: totalTrophies);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // count meta line
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${earned.length}',
              style: ZType.disp(28, color: tc.textPrimary, height: 0.9),
            ),
            if (totalTrophies > 0)
              Padding(
                padding: const EdgeInsets.only(left: 2, bottom: 3),
                child: Text(
                  '/$totalTrophies',
                  style: ZType.data(13, color: tc.textMuted),
                ),
              ),
            const Spacer(),
            Text(
              AppLocalizations.of(context).badgeHubMyBadges.toUpperCase(),
              style: ZType.lbl(9.5, color: tc.textMuted, letterSpacing: 1.5),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (int i = 0; i < recent.length; i++) ...[
              Expanded(
                child: _RarityTile(
                  icon: recent[i].trophy.icon,
                  name: recent[i].trophy.name,
                  tier: recent[i].trophy.trophyTier,
                ),
              ),
              if (i != recent.length - 1) const SizedBox(width: 10),
            ],
            // pad out to keep tiles equal width when < 4 earned
            for (int i = recent.length; i < 4; i++) ...[
              const Expanded(child: SizedBox()),
              if (i != 3) const SizedBox(width: 10),
            ],
          ],
        ),
      ],
    );
  }
}


class _RarityTile extends StatelessWidget {
  final String icon;
  final String name;
  final TrophyTier tier;

  const _RarityTile({
    required this.icon,
    required this.name,
    required this.tier,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final metal = tier.primaryColor;
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 11, 4, 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.hairline)),
      ),
      child: Column(
        children: [
          // emblem with rarity radial glow
          SizedBox(
            width: 46,
            height: 46,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        metal.withValues(alpha: 0.26),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.7],
                    ),
                  ),
                ),
                Text(icon, style: const TextStyle(fontSize: 23)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 9.5, height: 1.15, color: tc.textPrimary),
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              border: Border.all(color: metal.withValues(alpha: 0.4)),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              tier.displayName.toUpperCase(),
              style: ZType.lbl(8, color: metal, weight: FontWeight.w800, letterSpacing: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}


class _EmptyShowcase extends StatelessWidget {
  final int total;
  const _EmptyShowcase({required this.total});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.hairline)),
      ),
      child: Column(
        children: [
          const Text('🏆', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 10),
          Text(
            AppLocalizations.of(context).myBadgesShowcaseLogYourFirstWorkout,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: tc.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (total > 0) ...[
            const SizedBox(height: 6),
            Text(
              '$total badges available'.toUpperCase(),
              style: ZType.lbl(9.5, color: tc.textMuted, letterSpacing: 1.3),
            ),
          ],
        ],
      ),
    );
  }
}
