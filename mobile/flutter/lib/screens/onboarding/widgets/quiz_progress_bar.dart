import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'onboarding_theme.dart';

/// Glassmorphic animated progress bar for quiz screens.
class QuizProgressBar extends StatelessWidget {
  final double progress;
  final Duration duration;

  const QuizProgressBar({
    super.key,
    required this.progress,
    this.duration = const Duration(milliseconds: 400),
  });

  @override
  Widget build(BuildContext context) {
    final t = OnboardingTheme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: progress),
        duration: duration,
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Container(
            height: 6,
            decoration: BoxDecoration(
              color: t.cardFill,
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value,
              child: Container(
                decoration: BoxDecoration(
                  // Warm orange brand gradient — same hues used across the
                  // pre-auth funnel CTAs so the progress bar reads as part
                  // of the same visual system. Light → deep orange so the
                  // bar visibly "warms up" as the user gets closer to done.
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFFB366), // light orange
                      AppColors.orange,  // brand orange
                      Color(0xFFFF6B00), // deep orange
                    ],
                    stops: [0.0, 0.55, 1.0],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.orange.withValues(alpha: 0.35),
                      blurRadius: 10,
                      spreadRadius: 0,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
