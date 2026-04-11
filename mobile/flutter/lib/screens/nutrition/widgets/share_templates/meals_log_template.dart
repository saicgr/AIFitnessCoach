import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/nutrition.dart';
import '../../../workout/widgets/share_templates/app_watermark.dart';

/// Meals log template - Shows what was eaten today across all meals
class NutritionMealsLogTemplate extends StatelessWidget {
  final List<FoodLog> meals;
  final int totalCalories;
  final String dateLabel;
  final bool showWatermark;

  const NutritionMealsLogTemplate({
    super.key,
    required this.meals,
    required this.totalCalories,
    required this.dateLabel,
    this.showWatermark = true,
  });

  static const _mealConfig = {
    'breakfast': ('Breakfast', '\u{1F373}'),
    'lunch': ('Lunch', '\u{1F957}'),
    'dinner': ('Dinner', '\u{1F37D}\u{FE0F}'),
    'snack': ('Snacks', '\u{1F34E}'),
  };

  @override
  Widget build(BuildContext context) {
    // Group by meal type
    final mealsByType = <String, List<FoodLog>>{};
    for (final meal in meals) {
      mealsByType.putIfAbsent(meal.mealType, () => []).add(meal);
    }

    return Container(
      width: 320,
      height: 440,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1C1917), Color(0xFF292524), Color(0xFF1C1917)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MY MEALS',
                      style: TextStyle(
                        color: AppColors.orange,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateLabel,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$totalCalories kcal',
                    style: TextStyle(
                      color: AppColors.orange,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Meal sections
            Expanded(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  children: ['breakfast', 'lunch', 'dinner', 'snack'].map((type) {
                    final config = _mealConfig[type]!;
                    final typeMeals = mealsByType[type] ?? [];
                    final typeCalories = typeMeals.fold<int>(0, (s, m) => s + m.totalCalories);

                    if (typeMeals.isEmpty) return const SizedBox.shrink();

                    final foodNames = typeMeals
                        .expand((m) => m.foodItems.map((f) => f.name))
                        .take(3)
                        .toList();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(config.$2, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      config.$1,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '$typeCalories kcal',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.6),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  foodNames.join(', '),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    fontSize: 11,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${meals.length} ${meals.length == 1 ? 'meal' : 'meals'} logged',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
                ),
                if (showWatermark) const AppWatermark(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
