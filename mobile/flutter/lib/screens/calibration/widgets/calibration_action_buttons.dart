import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

/// Action buttons for accepting or declining calibration suggestions
class CalibrationActionButtons extends StatelessWidget {
  final bool hasChanges;
  final bool isProcessing;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final bool isDark;

  const CalibrationActionButtons({
    super.key,
    required this.hasChanges,
    required this.isProcessing,
    required this.onAccept,
    required this.onDecline,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final success = isDark ? AppColors.success : AppColorsLight.success;

    return Column(
      children: [
        // Primary action button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isProcessing ? null : () {
              HapticFeedback.mediumImpact();
              onAccept();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: hasChanges ? success : cyan,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: isProcessing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        hasChanges ? Icons.check_circle : Icons.arrow_forward,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        hasChanges
                            ? 'Accept Suggestions'
                            : 'Continue with Current Settings',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

        // Secondary action button (only show if there are changes)
        if (hasChanges) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: isProcessing ? null : () {
                HapticFeedback.lightImpact();
                onDecline();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: textSecondary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                side: BorderSide(
                  color: isDark
                      ? AppColors.cardBorder
                      : AppColorsLight.cardBorder,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.close,
                    size: 20,
                    color: textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Keep My Original Settings',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
        ],

        // Explanation text
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (isDark ? AppColors.elevated : AppColorsLight.elevated)
                .withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hasChanges
                          ? 'Accepting will update your workout settings based on AI recommendations. You can always adjust these later in Settings.'
                          : 'Your current settings will be used for generating your workouts. No changes needed!',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
              if (hasChanges) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.undo,
                      size: 16,
                      color: textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Declining will keep your original settings. You can re-run the calibration test anytime from Settings.',
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ).animate().fadeIn(delay: 300.ms),
      ],
    );
  }
}
