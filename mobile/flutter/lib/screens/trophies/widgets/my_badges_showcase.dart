import 'package:flutter/material.dart';

import '../../../data/models/trophy.dart';

/// Colourful gradient tile showcasing up to 6 recently-earned trophies as
/// an artful cluster (not a grid). Matches the purple→pink→red reference
/// and stays alive even when the user has no trophies yet (renders an
/// illustration placeholder instead).
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
    final hasBadges = earned.isNotEmpty;
    final recent = earned.take(6).toList();

    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8B5CF6), // violet-500
            Color(0xFFEC4899), // pink-500
            Color(0xFFF97316), // orange-500
          ],
          stops: [0.0, 0.55, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEC4899).withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (hasBadges)
            _BadgeCluster(recent: recent)
          else
            _EmptyShowcase(total: totalTrophies),

          // Earned count pill, bottom-left
          if (hasBadges)
            Positioned(
              left: 14,
              bottom: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  totalTrophies > 0
                      ? '${earned.length} earned / $totalTrophies'
                      : '${earned.length} earned',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}


class _BadgeCluster extends StatelessWidget {
  final List<TrophyProgress> recent;

  const _BadgeCluster({required this.recent});

  @override
  Widget build(BuildContext context) {
    // Arrange up to 6 badges in a staggered cluster. Positions are
    // normalised fractions so the layout scales cleanly across devices.
    const positions = [
      Offset(0.22, 0.45),
      Offset(0.40, 0.30),
      Offset(0.60, 0.40),
      Offset(0.78, 0.25),
      Offset(0.32, 0.68),
      Offset(0.68, 0.70),
    ];
    const sizes = [44.0, 60.0, 56.0, 48.0, 46.0, 50.0];

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return Stack(
          children: [
            for (int i = 0; i < recent.length && i < positions.length; i++)
              Positioned(
                left: positions[i].dx * w - sizes[i] / 2,
                top: positions[i].dy * h - sizes[i] / 2,
                child: _Emblem(
                  icon: recent[i].trophy.icon,
                  size: sizes[i],
                  tier: recent[i].trophy.tier,
                ),
              ),
          ],
        );
      },
    );
  }
}


class _Emblem extends StatelessWidget {
  final String icon;
  final double size;
  final String tier;

  const _Emblem({
    required this.icon,
    required this.size,
    required this.tier,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          icon,
          style: TextStyle(
            fontSize: size * 0.55,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _EmptyShowcase extends StatelessWidget {
  final int total;
  const _EmptyShowcase({required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '🏆',
            style: TextStyle(fontSize: 44),
          ),
          const SizedBox(height: 8),
          const Text(
            'Log your first workout to earn your first badge',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (total > 0) ...[
            const SizedBox(height: 4),
            Text(
              '$total badges available',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
