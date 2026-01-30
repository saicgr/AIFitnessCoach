import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

/// Gate screen asking user if they want to personalize their plan further.
///
/// This screen is shown AFTER the plan preview (Screen 5) and before
/// the personalization questions (Screens 7-9).
///
/// User options:
/// - "Yes, Personalize" → Continue to Screen 7 (Muscle Focus)
/// - "Skip for Now" → Jump to Screen 10 (Nutrition Opt-In)
class QuizPersonalizationGate extends StatelessWidget {
  final VoidCallback onPersonalize;
  final VoidCallback onSkip;

  const QuizPersonalizationGate({
    super.key,
    required this.onPersonalize,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final textSecondary = isDark ? const Color(0xFFD4D4D8) : const Color(0xFF52525B);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // Title
          Text(
            'Want better results?',  // ← UPDATED: More compelling, shorter
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textPrimary,
              height: 1.2,
            ),
          ).animate().fadeIn(delay: 100.ms).slideY(begin: -0.1),
          const SizedBox(height: 8),
          // Subtitle
          Text(
            'Optional — takes about 2 minutes',  // ← UPDATED: "Optional" moved earlier
            style: TextStyle(
              fontSize: 15,
              color: textSecondary,
              height: 1.5,
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.05),
          const SizedBox(height: 32),
          // Benefits list - scrollable if needed
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildBenefitItem(
                    icon: Icons.fitness_center,
                    title: 'Muscle targeting',  // ← SHORTENED from "Muscle-specific targeting"
                    description: 'Focus on the muscle groups you want to develop most',
                    microValue: 'Prioritize triceps, lats, etc.',  // ← ADDED
                    isDark: isDark,
                    delay: 300.ms,
                  ),
                  const SizedBox(height: 16),
                  _buildBenefitItem(
                    icon: Icons.tune,
                    title: 'Training style',  // ← SHORTENED from "Training style customization"
                    description: 'Choose your preferred split and workout structure',
                    microValue: 'Choose PPL / Upper-Lower / Full Body',  // ← ADDED
                    isDark: isDark,
                    delay: 400.ms,
                  ),
                  const SizedBox(height: 16),
                  _buildBenefitItem(
                    icon: Icons.trending_up,
                    title: 'Progression',  // ← SHORTENED from "Progression control"
                    description: 'Set how quickly you want to increase difficulty',
                    microValue: 'Slow / Medium / Fast increases',  // ← ADDED
                    isDark: isDark,
                    delay: 500.ms,
                  ),
                  const SizedBox(height: 16),
                  _buildBenefitItem(
                    icon: Icons.health_and_safety_outlined,
                    title: 'Injury accommodations',
                    description: 'Flag any injuries or joint issues to work around',
                    microValue: 'Knees / Shoulders / Lower back / etc.',
                    isDark: isDark,
                    delay: 600.ms,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Action buttons
          Column(
            children: [
              // Primary: Personalize
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    onPersonalize();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: AppColors.orange.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),
              const SizedBox(height: 12),
              // Secondary: Skip
              SizedBox(
                width: double.infinity,
                height: 56,
                child: TextButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    onSkip();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: textSecondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Skip for now',  // ← lowercase "for now"
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textSecondary,
                      decoration: TextDecoration.underline,  // ← ADDED underline
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.1),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String description,
    required bool isDark,
    required Duration delay,
    String? microValue,  // ← ADDED optional micro-value parameter
  }) {
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final textSecondary = isDark ? const Color(0xFFD4D4D8) : const Color(0xFF52525B);
    final cardBackground = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.glassBorder : AppColorsLight.cardBorder,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppColors.orange,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                    height: 1.4,
                  ),
                ),
                // NEW: Micro-value line
                if (microValue != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    microValue,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.orange.withValues(alpha: 0.8),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: delay).slideX(begin: -0.05);
  }
}
