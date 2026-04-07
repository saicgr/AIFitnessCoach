import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'onboarding_theme.dart';

/// A compact animated "Did you know?" hint chip for the onboarding quiz.
///
/// Shows a lightbulb icon with a contextual fact about the app.
/// Animates in with fade + slide when it appears.
/// Uses glassmorphic styling adapted for light and dark modes.
class DidYouKnowChip extends StatelessWidget {
  final String text;

  const DidYouKnowChip({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final t = OnboardingTheme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: t.cardFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: t.borderDefault),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, size: 18, color: t.textPrimary)
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      begin: const Offset(1.0, 1.0),
                      end: const Offset(1.15, 1.15),
                      duration: 1200.ms,
                      curve: Curves.easeInOut,
                    ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Did you know?  ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: t.textPrimary,
                          ),
                        ),
                        TextSpan(
                          text: text,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: t.textSecondary,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 600.ms)
        .slideY(begin: 0.3, end: 0, duration: 400.ms, delay: 600.ms, curve: Curves.easeOutCubic);
  }
}
