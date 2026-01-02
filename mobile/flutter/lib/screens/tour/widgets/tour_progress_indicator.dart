import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Horizontal row of dots indicating tour progress
class TourProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const TourProgressIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (index) {
        final isActive = index == currentStep;
        final isCompleted = index < currentStep;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            width: isActive ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.cyan
                  : isCompleted
                      ? AppColors.cyan.withOpacity(0.5)
                      : elevated,
              borderRadius: BorderRadius.circular(4),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppColors.cyan.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
        );
      }),
    );
  }
}
