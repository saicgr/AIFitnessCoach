import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'onboarding_theme.dart';

import '../../../l10n/generated/app_localizations.dart';
/// Gate screen asking user if they want nutrition guidance.
///
/// This screen is shown AFTER personalization (or after skipping personalization).
/// Shows "Recommended" label if user has weight loss or nutrition-related goals.
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
    final t = OnboardingTheme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          // Recommendation badge
          if (isRecommended)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: t.cardFill,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: t.checkBorderUnselected,
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
                        AppLocalizations.of(context).quizNutritionGateRecommendedForYou,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: t.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 100.ms).scale(begin: const Offset(0.8, 0.8))
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: t.cardFill,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: t.borderDefault,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context).quizNutritionGateOptional,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: t.textSecondary,
                    ),
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 100.ms).scale(begin: const Offset(0.8, 0.8)),
          const SizedBox(height: 20),
          // Title
          Text(
            AppLocalizations.of(context).quizNutritionGateWantNutritionGuidanceToo,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: t.textPrimary,
              height: 1.2,
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.1),
          const SizedBox(height: 12),
          // Subtitle
          Text(
            AppLocalizations.of(context).quizNutritionGateGetPersonalizedCalorieAnd,
            style: TextStyle(
              fontSize: 16,
              color: t.textSecondary,
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
                    t: t,
                    icon: Icons.restaurant_menu,
                    title: AppLocalizations.of(context).quizNutritionGateCalorieMacroTargets,
                    description: AppLocalizations.of(context).quizNutritionGateTailoredToYourGoals,
                    delay: 400.ms,
                  ),
                  const SizedBox(height: 16),
                  _buildBenefitItem(
                    t: t,
                    icon: Icons.schedule,
                    title: AppLocalizations.of(context).quizNutritionGateMealTimingGuidance,
                    description: AppLocalizations.of(context).quizNutritionGateOptimizeWhenYouEat,
                    delay: 500.ms,
                  ),
                  const SizedBox(height: 16),
                  _buildBenefitItem(
                    t: t,
                    icon: Icons.local_dining,
                    title: AppLocalizations.of(context).quizNutritionGateDietaryPreferences,
                    description: AppLocalizations.of(context).quizNutritionGateRespectsYourRestrictionsAnd,
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
              // Primary: Set Nutrition - glassmorphic button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          onSetNutrition();
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: t.buttonGradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: t.buttonBorder,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                AppLocalizations.of(context).quizNutritionGateYesSetNutrition,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: t.buttonText,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, size: 20, color: t.textPrimary),
                            ],
                          ),
                        ),
                      ),
                    ),
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
                    foregroundColor: t.textSecondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context).watchInstallBannerNotNow,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: t.textSecondary,
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
    required OnboardingTheme t,
    required IconData icon,
    required String title,
    required String description,
    required Duration delay,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: t.cardFill,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: t.borderDefault,
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
                  color: t.cardFill,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: t.textPrimary,
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
                        color: t.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: t.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: delay).slideX(begin: -0.05);
  }
}
