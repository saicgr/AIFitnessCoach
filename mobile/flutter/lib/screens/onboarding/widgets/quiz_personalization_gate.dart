import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import 'onboarding_theme.dart';

/// Glassmorphic gate screen asking user if they want to personalize further.
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
    final t = OnboardingTheme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Want better results?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: t.textPrimary,
              height: 1.2,
            ),
          ).animate().fadeIn(delay: 100.ms).slideY(begin: -0.1),
          const SizedBox(height: 8),
          Text(
            'Optional — takes about 2 minutes',
            style: TextStyle(
              fontSize: 15,
              color: t.textSecondary,
              height: 1.5,
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.05),
          const SizedBox(height: 32),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildBenefitItem(
                    t: t,
                    icon: Icons.fitness_center,
                    title: 'Muscle targeting',
                    description: 'Focus on the muscle groups you want to develop most',
                    microValue: 'Prioritize triceps, lats, etc.',
                    delay: 300.ms,
                  ),
                  const SizedBox(height: 16),
                  _buildBenefitItem(
                    t: t,
                    icon: Icons.tune,
                    title: 'Training style',
                    description: 'Choose your preferred split and workout structure',
                    microValue: 'Choose PPL / Upper-Lower / Full Body',
                    delay: 400.ms,
                  ),
                  const SizedBox(height: 16),
                  _buildBenefitItem(
                    t: t,
                    icon: Icons.trending_up,
                    title: 'Progression',
                    description: 'Set how quickly you want to increase difficulty',
                    microValue: 'Slow / Medium / Fast increases',
                    delay: 500.ms,
                  ),
                  const SizedBox(height: 16),
                  _buildBenefitItem(
                    t: t,
                    icon: Icons.health_and_safety_outlined,
                    title: 'Injury accommodations',
                    description: 'Flag any injuries or joint issues to work around',
                    microValue: 'Knees / Shoulders / Lower back / etc.',
                    delay: 600.ms,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Column(
            children: [
              // Primary: Personalize — glassmorphic
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  onPersonalize();
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: t.buttonGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: t.buttonBorder),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: t.accent,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 20, color: t.accent),
                        ],
                      ),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),
              const SizedBox(height: 12),
              // Secondary: Skip
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onSkip();
                },
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: Center(
                    child: Text(
                      'Skip for now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: t.textMuted,
                        decoration: TextDecoration.underline,
                        decorationColor: t.textDisabled,
                      ),
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
    required OnboardingTheme t,
    required IconData icon,
    required String title,
    required String description,
    required Duration delay,
    String? microValue,
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
            border: Border.all(color: t.borderDefault),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: t.cardFill,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: t.textPrimary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: t.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(fontSize: 14, color: t.textSecondary, height: 1.4),
                    ),
                    if (microValue != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        microValue,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: t.textMuted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
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
