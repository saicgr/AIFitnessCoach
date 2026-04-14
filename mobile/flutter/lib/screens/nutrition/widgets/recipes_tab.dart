import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Placeholder for the upcoming Recipes tab. The full feature (recipe browser,
/// builder, mealprep planner) lives on a separate track — this keeps the tab
/// slot occupied so users see the roadmap instead of a missing section.
class RecipesPlaceholderTab extends StatelessWidget {
  final bool isDark;
  const RecipesPlaceholderTab({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accent = isDark ? AppColors.purple : AppColorsLight.purple;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.menu_book_rounded,
              size: 72,
              color: accent.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 24),
            Text(
              'Recipes are coming',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Browse and log full recipes, save your favorites, and plan your meal prep from one place. Launching soon.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
