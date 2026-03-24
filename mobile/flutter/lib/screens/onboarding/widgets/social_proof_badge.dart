import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A small pulsing badge/chip widget that looks like a sticker.
///
/// Used in the Feature Showcase onboarding screen to highlight
/// social-proof callouts on each feature card (e.g. "Most Popular").
class SocialProofBadge extends StatelessWidget {
  final String text;
  final Color? color;

  const SocialProofBadge({super.key, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    final badgeColor = color ?? const Color(0xFF2ECC71);

    return Transform.rotate(
      angle: -0.087, // ~-5 degrees
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: badgeColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: badgeColor.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.star_rounded,
              color: Colors.white,
              size: 13,
            ),
            const SizedBox(width: 4),
            Text(
              text,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.3,
                height: 1.0,
              ),
            ),
          ],
        ),
      )
          .animate(
            onPlay: (controller) => controller.repeat(reverse: true),
          )
          .scale(
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.05, 1.05),
            duration: 1200.ms,
            curve: Curves.easeInOut,
          ),
    );
  }
}
