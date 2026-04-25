import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../data/models/home_layout.dart';
import '../../../../data/providers/nutrition_preferences_provider.dart';
import '../../../../data/repositories/nutrition_repository.dart';
import '../../../../data/services/haptic_service.dart';

/// Compact "Today's Calories" tile — calories consumed vs target with a
/// progress bar. Tapping it opens the nutrition dashboard.
///
/// Kept deliberately lightweight so it composes with other half-width tiles
/// like Macro Rings side by side. The full macro breakdown lives in the
/// HeroNutritionCard at the top of the Nutrition hero tab.
class CaloriesSummaryCard extends ConsumerWidget {
  final TileSize size;
  final bool isDark;

  const CaloriesSummaryCard({
    super.key,
    this.size = TileSize.half,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final accent = ref.colors(context).accent;

    final summary = ref.watch(nutritionProvider).todaySummary;
    final calorieTarget = ref.watch(nutritionPreferencesProvider).currentCalorieTarget;
    final consumed = summary?.totalCalories ?? 0;
    final remaining = calorieTarget - consumed;
    final progress = calorieTarget > 0
        ? (consumed / calorieTarget).clamp(0.0, 1.0)
        : 0.0;
    final isOver = consumed > calorieTarget;
    final progressColor = isOver ? AppColors.error : accent;

    return GestureDetector(
      onTap: () {
        HapticService.light();
        context.go('/nutrition');
      },
      child: Container(
        margin: size == TileSize.full
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 4)
            : null,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_fire_department,
                  size: 16,
                  color: AppColors.macroFat,
                ),
                const SizedBox(width: 6),
                Text(
                  'Calories',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: Text(
                    isOver ? '+${(remaining).abs()}' : '$remaining',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isOver ? AppColors.error : textColor,
                      height: 1.0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  isOver ? 'over' : 'left',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$consumed / $calorieTarget kcal',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
