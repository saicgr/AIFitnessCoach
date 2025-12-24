import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

/// Continue button for quiz screens.
class QuizContinueButton extends StatelessWidget {
  final bool canProceed;
  final bool isLastQuestion;
  final VoidCallback onPressed;

  const QuizContinueButton({
    super.key,
    required this.canProceed,
    required this.isLastQuestion,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: ElevatedButton(
            onPressed: canProceed ? onPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: canProceed
                  ? AppColors.cyan
                  : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
              foregroundColor: canProceed
                  ? Colors.white
                  : (isDark ? AppColors.textMuted : AppColorsLight.textMuted),
              elevation: canProceed ? 4 : 0,
              shadowColor: canProceed ? AppColors.cyan.withOpacity(0.4) : Colors.transparent,
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
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
  }
}
