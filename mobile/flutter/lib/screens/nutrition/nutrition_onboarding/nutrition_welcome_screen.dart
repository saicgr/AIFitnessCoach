import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/haptic_service.dart';

/// Welcome screen shown before nutrition onboarding.
/// Explains what the user will set up and what to expect.
class NutritionWelcomeScreen extends StatelessWidget {
  final VoidCallback onGetStarted;
  final VoidCallback? onSkip;

  const NutritionWelcomeScreen({
    super.key,
    required this.onGetStarted,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final green = isDark ? AppColors.green : AppColorsLight.success;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button (optional) - fixed at top
            if (onSkip != null)
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16, top: 8),
                  child: TextButton(
                    onPressed: () {
                      HapticService.light();
                      onSkip!();
                    },
                    child: Text(
                      'Skip for now',
                      style: TextStyle(color: textMuted, fontSize: 14),
                    ),
                  ),
                ),
              )
            else
              const SizedBox(height: 48),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 24),

                    // Icon/illustration
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            green.withValues(alpha: 0.2),
                            green.withValues(alpha: 0.1),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.restaurant_menu,
                        size: 48,
                        color: green,
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .scale(begin: const Offset(0.8, 0.8)),

                    const SizedBox(height: 24),

                    // Title
                    Text(
                      'Welcome to Nutrition Tracking',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    )
                        .animate()
                        .fadeIn(delay: 100.ms, duration: 400.ms)
                        .slideY(begin: 0.2, end: 0),

                    const SizedBox(height: 12),

                    // Subtitle
                    Text(
                      'Let\'s personalize your nutrition goals and preferences to help you eat better.',
                      style: TextStyle(
                        fontSize: 15,
                        color: textMuted,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    )
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 400.ms)
                        .slideY(begin: 0.2, end: 0),

                    const SizedBox(height: 32),

                    // Features list
                    _buildFeatureItem(
                      icon: Icons.track_changes,
                      title: 'Personalized Targets',
                      description: 'Calories, protein, carbs, and fat tailored to your goals',
                      color: green,
                      elevated: elevated,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      delay: 300,
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureItem(
                      icon: Icons.restaurant,
                      title: 'Diet Preferences',
                      description: 'Vegetarian, keto, flexitarian, or your own custom diet',
                      color: const Color(0xFFFF9500),
                      elevated: elevated,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      delay: 400,
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureItem(
                      icon: Icons.schedule,
                      title: 'Meal Patterns',
                      description: 'Intermittent fasting, OMAD, or traditional meals',
                      color: isDark ? AppColors.purple : AppColorsLight.purple,
                      elevated: elevated,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      delay: 500,
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Fixed bottom section with button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Get Started button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticService.medium();
                        onGetStarted();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Get Started',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 600.ms, duration: 400.ms)
                      .slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 12),

                  // Time estimate
                  Text(
                    'Takes about 2 minutes',
                    style: TextStyle(fontSize: 14, color: textMuted),
                  )
                      .animate()
                      .fadeIn(delay: 700.ms, duration: 400.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required Color elevated,
    required Color textPrimary,
    required Color textMuted,
    required int delay,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
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
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(fontSize: 13, color: textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay), duration: 400.ms)
        .slideX(begin: 0.1, end: 0);
  }
}
