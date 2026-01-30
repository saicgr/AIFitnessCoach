import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

/// Continue button for quiz screens.
class QuizContinueButton extends StatelessWidget {
  final bool canProceed;
  final bool isLastQuestion;
  final VoidCallback onPressed;
  final VoidCallback? onSkip;
  final String? skipText;

  const QuizContinueButton({
    super.key,
    required this.canProceed,
    required this.isLastQuestion,
    required this.onPressed,
    this.onSkip,
    this.skipText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Skip button (if provided)
          if (onSkip != null)
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: onSkip,
                child: Container(
                  height: 56,
                  alignment: Alignment.center,
                  child: Text(
                    skipText ?? 'Skip',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          if (onSkip != null) const SizedBox(width: 12),
          // Continue button
          Expanded(
            flex: onSkip != null ? 5 : 1,
            child: SizedBox(
              height: 56,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: ElevatedButton(
                  onPressed: canProceed ? onPressed : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canProceed
                        ? AppColors.orange // Use orange accent for visibility
                        : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
                    foregroundColor: canProceed
                        ? Colors.white
                        : (isDark ? AppColors.textMuted : AppColorsLight.textMuted),
                    elevation: canProceed ? 4 : 0,
                    shadowColor: canProceed ? AppColors.orange.withValues(alpha: 0.4) : Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isLastQuestion ? 'See My Plan' : 'Continue',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (canProceed) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
  }
}
