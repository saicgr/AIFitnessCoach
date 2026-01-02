import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Navigation buttons for the app tour (Back and Next/Get Started)
class TourNavigationButtons extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final bool isLoading;

  const TourNavigationButtons({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.onBack,
    required this.onNext,
    this.isLoading = false,
  });

  bool get isFirstStep => currentStep == 0;
  bool get isLastStep => currentStep == totalSteps - 1;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Row(
        children: [
          // Back button - hidden on first step
          if (!isFirstStep)
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: isLoading ? null : onBack,
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: textSecondary,
                    size: 20,
                  ),
                  label: Text(
                    'Back',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: cardBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),

          // Spacer between buttons
          if (!isFirstStep) const SizedBox(width: 12),

          // Next/Get Started button
          Expanded(
            flex: isFirstStep ? 1 : 1,
            child: SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : onNext,
                icon: isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDark ? Colors.black : Colors.white,
                          ),
                        ),
                      )
                    : Icon(
                        isLastStep ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded,
                        size: 20,
                      ),
                label: Text(
                  isLastStep ? 'Get Started' : 'Next',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cyan,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: AppColors.cyan.withOpacity(0.5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
