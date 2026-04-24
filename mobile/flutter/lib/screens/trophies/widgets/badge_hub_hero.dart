import 'package:flutter/material.dart';

import '../../../data/services/haptic_service.dart';

/// Teal→green gradient hero banner at the top of the Badge Hub.
/// Matches the reference art — stacked badges illustration on the right
/// and a "How it works >" pill on the left. The right-side badges are
/// rendered as text emoji (no image asset needed) so the banner stays
/// distinctive without blocking on art pipeline.
class BadgeHubHero extends StatelessWidget {
  final VoidCallback onHowItWorksTap;

  const BadgeHubHero({super.key, required this.onHowItWorksTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        HapticService.light();
        onHowItWorksTap();
      },
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFF14B8A6), // teal-500
              Color(0xFF22D3EE), // cyan-400
              Color(0xFF86EFAC), // green-300
            ],
            stops: [0.0, 0.55, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF22D3EE).withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Decorative badge emojis spilling out
            Positioned(
              right: -6,
              top: 24,
              child: Opacity(
                opacity: 0.9,
                child: Row(
                  children: const [
                    _HeroBadge(emoji: '🏆', size: 46, rotation: -0.22),
                    SizedBox(width: 2),
                    _HeroBadge(emoji: '🎖️', size: 52, rotation: 0.06),
                    SizedBox(width: 2),
                    _HeroBadge(emoji: '🥇', size: 44, rotation: 0.18),
                  ],
                ),
              ),
            ),

            // Copy
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 150, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reward Your Progress',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Earn badges for every milestone, streak, and PB.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Text(
                        'How it works',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white.withValues(alpha: 0.95),
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _HeroBadge extends StatelessWidget {
  final String emoji;
  final double size;
  final double rotation; // radians

  const _HeroBadge({
    required this.emoji,
    required this.size,
    required this.rotation,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: Text(
        emoji,
        style: TextStyle(
          fontSize: size,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
      ),
    );
  }
}
