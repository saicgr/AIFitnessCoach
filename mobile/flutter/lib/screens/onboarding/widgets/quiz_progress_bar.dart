import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'onboarding_theme.dart';

/// Animated progress bar for quiz screens.
///
/// v7 redesign: when [segments] + [currentStep] are provided the bar renders
/// as discrete orange ticks (one per quiz step — the approved "System A"
/// segmented progress). Without them it falls back to the continuous
/// gradient bar, so any other consumer keeps working unchanged.
class QuizProgressBar extends StatelessWidget {
  final double progress;
  final Duration duration;

  /// Total number of discrete steps to render (e.g. 11 quiz questions).
  final int? segments;

  /// Zero-based index of the current step; ticks 0..currentStep light up.
  final int? currentStep;

  const QuizProgressBar({
    super.key,
    required this.progress,
    this.duration = const Duration(milliseconds: 400),
    this.segments,
    this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    final t = OnboardingTheme.of(context);

    if (segments != null && currentStep != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: List.generate(segments!, (i) {
            final on = i <= currentStep!;
            return Expanded(
              child: AnimatedContainer(
                duration: duration,
                curve: Curves.easeOutCubic,
                height: 4,
                margin: EdgeInsetsDirectional.only(
                  end: i == segments! - 1 ? 0 : 5,
                ),
                decoration: BoxDecoration(
                  color: on ? t.selectionAccent : t.cardFill,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: on
                      ? [
                          BoxShadow(
                            color: t.selectionAccent.withValues(alpha: 0.5),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
              ),
            );
          }),
        ),
      );
    }

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
              alignment: AlignmentDirectional.centerStart,
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
                    begin: AlignmentDirectional.centerStart,
                    end: AlignmentDirectional.centerEnd,
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
