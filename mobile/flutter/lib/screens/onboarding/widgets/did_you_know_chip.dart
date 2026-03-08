import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

/// A compact animated "Did you know?" hint chip for the onboarding quiz.
///
/// Shows a lightbulb icon with a contextual fact about the app.
/// Animates in with fade + slide when it appears.
class DidYouKnowChip extends StatelessWidget {
  final String text;

  const DidYouKnowChip({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline, size: 18, color: accentColor)
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
                      color: accentColor,
                    ),
                  ),
                  TextSpan(
                    text: text,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.textSecondary
                          : AppColorsLight.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 600.ms)
        .slideY(begin: 0.3, end: 0, duration: 400.ms, delay: 600.ms, curve: Curves.easeOutCubic);
  }
}
