import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Tab displaying skill progressions
class SkillsTab extends StatelessWidget {
  const SkillsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon container
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cyan.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.route_rounded,
                size: 64,
                color: cyan,
              ),
            ),
            const SizedBox(height: 32),

            // Title
            Text(
              'Skill Progressions',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),

            // Description
            Text(
              'Master bodyweight skills step by step with guided progression chains.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: textSecondary,
                    height: 1.5,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Feature preview cards
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: elevated,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorder),
              ),
              child: Column(
                children: [
                  _buildFeatureRow(
                    context,
                    Icons.fitness_center_rounded,
                    'Progressive exercises',
                    textSecondary,
                    cyan,
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureRow(
                    context,
                    Icons.trending_up_rounded,
                    'Track your progress',
                    textSecondary,
                    cyan,
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureRow(
                    context,
                    Icons.emoji_events_rounded,
                    'Unlock new skills',
                    textSecondary,
                    cyan,
                  ),
                ],
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
    String text,
    Color textColor,
    Color iconColor,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 12),
        Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: textColor,
              ),
        ),
      ],
    );
  }
}
