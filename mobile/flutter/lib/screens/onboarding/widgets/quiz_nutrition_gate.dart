import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

/// Gate screen asking user if they want nutrition guidance.
///
/// This screen is shown AFTER personalization (or after skipping personalization).
/// Shows "Recommended ⭐" label if user has weight loss or nutrition-related goals.
///
/// User options:
/// - "Yes, Set Nutrition" → Continue to Screen 11 (Nutrition Details)
/// - "Not Now" → Finish onboarding → Coach Selection
class QuizNutritionGate extends StatelessWidget {
  final List<String> goals;
  final VoidCallback onSetNutrition;
  final VoidCallback onSkip;

  const QuizNutritionGate({
    super.key,
    required this.goals,
    required this.onSetNutrition,
    required this.onSkip,
  });

  /// Returns true if nutrition is recommended based on user goals
  bool get isRecommended {
    return goals.contains('lose_weight') ||
           goals.contains('lose_fat') ||
           goals.contains('eat_healthier') ||
           goals.contains('improve_energy');
  }

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
          const SizedBox(height: 24),
          // Recommendation badge
          if (isRecommended)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.orange.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '⭐',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Recommended for you',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.orange,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms).scale(begin: const Offset(0.8, 0.8))
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? AppColors.glassSurface : AppColorsLight.glassSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.glassBorder : AppColorsLight.cardBorder,
                  width: 1,
                ),
              ),
              child: Text(
                'Optional',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: textSecondary,
                ),
              ),
            ).animate().fadeIn(delay: 100.ms).scale(begin: const Offset(0.8, 0.8)),
          const SizedBox(height: 20),
          // Title
          Text(
            'Want nutrition guidance too?',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: textPrimary,
              height: 1.2,
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.1),
          const SizedBox(height: 12),
          // Subtitle
          Text(
            'Get personalized calorie and macro targets to support your fitness goals',
            style: TextStyle(
              fontSize: 16,
              color: textSecondary,
              height: 1.5,
            ),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: -0.05),
          const SizedBox(height: 32),
          // Benefits list - scrollable
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildBenefitItem(
                    icon: Icons.restaurant_menu,
                    title: 'Calorie & macro targets',
                    description: 'Tailored to your goals and activity level',
                    isDark: isDark,
                    delay: 400.ms,
                  ),
                  const SizedBox(height: 16),
                  _buildBenefitItem(
                    icon: Icons.schedule,
                    title: 'Meal timing guidance',
                    description: 'Optimize when you eat for better results',
                    isDark: isDark,
                    delay: 500.ms,
                  ),
                  const SizedBox(height: 16),
                  _buildBenefitItem(
                    icon: Icons.local_dining,
                    title: 'Dietary preferences',
                    description: 'Respects your restrictions and preferences',
                    isDark: isDark,
                    delay: 600.ms,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Action buttons
          Column(
            children: [
              // Primary: Set Nutrition
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    onSetNutrition();
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
                        'Yes, Set Nutrition',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.1),
              const SizedBox(height: 16),
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
                    'Not Now',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textSecondary,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.1),
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
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: delay).slideX(begin: -0.05);
  }
}
