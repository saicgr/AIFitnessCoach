import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Animated progress bar for quiz screens.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              color: isDark ? AppColors.glassSurface : AppColorsLight.glassSurface,
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.cyanGradient,
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cyan.withOpacity(0.4),
                      blurRadius: 8,
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
