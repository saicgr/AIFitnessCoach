import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/services/haptic_service.dart';

import '../../../l10n/generated/app_localizations.dart';
/// Empty state widget for when user has no custom exercises — signature-v2:
/// orange accent, hairline-bordered feature panel, Anton title, Barlow CTA.
class EmptyCustomExercises extends StatelessWidget {
  final VoidCallback? onCreatePressed;

  const EmptyCustomExercises({
    super.key,
    this.onCreatePressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final surface = isDark ? AppColors.surface2 : AppColorsLight.surface;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.orange.withValues(alpha: 0.3)),
              ),
              child: const Center(
                child: Icon(
                  Icons.add_circle_outline,
                  size: 54,
                  color: AppColors.orange,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              AppLocalizations.of(context).emptyCustomExercisesCreateYourOwnExercises.toUpperCase(),
              style: ZType.disp(24, color: textPrimary, letterSpacing: 0.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              AppLocalizations.of(context).emptyCustomExercisesBuildCustomExercisesTailore,
              style: ZType.sans(14,
                  color: textSecondary, weight: FontWeight.w500, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Features list
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cardBorder),
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
                  backgroundColor: AppColors.orange,
                  foregroundColor: const Color(0xFF160B03),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add, color: Color(0xFF160B03), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context).emptyCustomExercisesCreateYourFirstExercise.toUpperCase(),
                      style: ZType.lbl(14,
                          color: const Color(0xFF160B03), letterSpacing: 1.2),
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
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.orange.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.orange.withValues(alpha: 0.3)),
          ),
          child: Icon(
            icon,
            color: AppColors.orange,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: ZType.lbl(13, color: textPrimary, letterSpacing: 1.2),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: ZType.sans(12.5,
                    color: textSecondary, weight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
