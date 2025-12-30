import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/haptic_service.dart';

/// Empty state widget for when user has no custom exercises
class EmptyCustomExercises extends StatelessWidget {
  final VoidCallback? onCreatePressed;

  const EmptyCustomExercises({
    super.key,
    this.onCreatePressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: cyan.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.add_circle_outline,
                  size: 60,
                  color: cyan,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              'Create Your Own Exercises',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              'Build custom exercises tailored to your needs, or combine multiple movements into powerful combos.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Features list
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: elevated,
                borderRadius: BorderRadius.circular(16),
                border: isDark ? null : Border.all(color: AppColorsLight.cardBorder),
              ),
              child: Column(
                children: [
                  _buildFeatureRow(
                    context,
                    Icons.fitness_center,
                    'Simple Exercises',
                    'Create single-movement exercises',
                    isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureRow(
                    context,
                    Icons.layers,
                    'Combo Exercises',
                    'Supersets, complexes & more',
                    isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureRow(
                    context,
                    Icons.history,
                    'Usage Tracking',
                    'See how often you use them',
                    isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Create button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  HapticService.light();
                  onCreatePressed?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: cyan,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.add),
                    SizedBox(width: 8),
                    Text(
                      'Create Your First Exercise',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    bool isDark,
  ) {
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: cyan.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: cyan,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
