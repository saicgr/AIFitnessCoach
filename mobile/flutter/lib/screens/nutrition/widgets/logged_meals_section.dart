import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/nutrition.dart';
import '../../../widgets/glass_sheet.dart';

class LoggedMealsSection extends StatelessWidget {
  final List<FoodLog> meals;
  final void Function(String) onDeleteMeal;
  final void Function(String mealId, String targetMealType) onCopyMeal;
  final void Function(String? mealType) onLogMeal;
  final bool isDark;
  final String userId;
  final VoidCallback onFoodSaved;
  final int? calorieTarget;
  final int totalCaloriesEaten;

  const LoggedMealsSection({
    super.key,
    required this.meals,
    required this.onDeleteMeal,
    required this.onCopyMeal,
    required this.onLogMeal,
    required this.isDark,
    required this.userId,
    required this.onFoodSaved,
    this.calorieTarget,
    required this.totalCaloriesEaten,
  });

  static const _mealTypes = [
    {'id': 'breakfast', 'label': 'Breakfast', 'emoji': '\u{1F373}'},
    {'id': 'lunch', 'label': 'Lunch', 'emoji': '\u{1F957}'},
    {'id': 'dinner', 'label': 'Dinner', 'emoji': '\u{1F37D}\u{FE0F}'},
    {'id': 'snack', 'label': 'Snacks', 'emoji': '\u{1F34E}'},
  ];

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    // Group meals by type
    final mealsByType = <String, List<FoodLog>>{};
    for (final meal in meals) {
      final type = meal.mealType ?? 'snack';
      mealsByType.putIfAbsent(type, () => []).add(meal);
    }

    final remaining = (calorieTarget ?? 0) - totalCaloriesEaten;

    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Meal type sections
          ..._mealTypes.asMap().entries.map((entry) {
            final index = entry.key;
            final mealInfo = entry.value;
            final mealId = mealInfo['id']!;
            final typeMeals = mealsByType[mealId] ?? [];
            final totalCal = typeMeals.fold<int>(0, (sum, m) => sum + m.totalCalories);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section header
                InkWell(
                  onTap: () => onLogMeal(mealId),
                  borderRadius: index == 0
                      ? const BorderRadius.vertical(top: Radius.circular(12))
                      : BorderRadius.zero,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        Text(mealInfo['emoji']!, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text(
                          mealInfo['label']!,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        const Spacer(),
                        if (totalCal > 0)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              '$totalCal kcal',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: teal,
                              ),
                            ),
                          ),
                        Icon(Icons.add_circle_outline, size: 20, color: teal),
                      ],
                    ),
                  ),
                ),
                // Divider below header
                Divider(height: 1, color: cardBorder, indent: 14, endIndent: 14),
                // Food items or empty state
                if (typeMeals.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Text(
                      'No foods logged',
                      style: TextStyle(fontSize: 12, color: textMuted),
                    ),
                  )
                else
                  ...typeMeals.expand((meal) {
                    // Expand each FoodLog's items as individual rows
                    if (meal.foodItems.isEmpty) {
                      return [_buildFoodItemRow(
                        context: context,
                        meal: meal,
                        foodName: 'Food',
                        calories: meal.totalCalories,
                        time: meal.loggedAt,
                        textPrimary: textPrimary,
                        textMuted: textMuted,
                        teal: teal,
                      )];
                    }
                    return meal.foodItems.map((food) => _buildFoodItemRow(
                      context: context,
                      meal: meal,
                      foodName: food.name,
                      calories: food.calories ?? 0,
                      amount: food.amount,
                      time: meal.loggedAt,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      teal: teal,
                    ));
                  }),
                // Section bottom spacing (except last)
                if (index < _mealTypes.length - 1)
                  Divider(height: 1, thickness: 1, color: cardBorder),
              ],
            );
          }),
          // Summary row
          if (calorieTarget != null && calorieTarget! > 0) ...[
            Divider(height: 1, thickness: 1, color: cardBorder),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Text(
                    'Eaten',
                    style: TextStyle(
                      fontSize: 12,
                      color: textMuted,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$totalCaloriesEaten',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Remaining',
                    style: TextStyle(
                      fontSize: 12,
                      color: textMuted,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${remaining.abs()}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: remaining >= 0 ? teal : AppColors.error,
                    ),
                  ),
                  if (remaining < 0)
                    Text(
                      ' over',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.error,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFoodItemRow({
    required BuildContext context,
    required FoodLog meal,
    required String foodName,
    required int calories,
    String? amount,
    required DateTime time,
    required Color textPrimary,
    required Color textMuted,
    required Color teal,
  }) {
    final timeStr = '${time.hour % 12 == 0 ? 12 : time.hour % 12}:${time.minute.toString().padLeft(2, '0')} ${time.hour < 12 ? 'AM' : 'PM'}';

    return Dismissible(
      key: ValueKey('${meal.id}_$foodName'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: AppColors.error.withValues(alpha: 0.9),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 4),
            Icon(Icons.delete_outline, color: Colors.white, size: 18),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        final messenger = ScaffoldMessenger.of(context);
        bool undone = false;
        messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(
            content: const Text('Meal deleted'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                undone = true;
              },
            ),
            duration: const Duration(seconds: 4),
          ),
        );
        await Future.delayed(const Duration(seconds: 4));
        if (!undone) {
          onDeleteMeal(meal.id);
        }
        return !undone;
      },
      child: InkWell(
        onTap: () => _showMealDetails(context, meal),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      foodName,
                      style: TextStyle(
                        fontSize: 13,
                        color: textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (amount != null)
                      Text(
                        amount,
                        style: TextStyle(fontSize: 11, color: textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Text(
                timeStr,
                style: TextStyle(fontSize: 11, color: textMuted),
              ),
              const SizedBox(width: 12),
              Text(
                '$calories',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              Text(
                ' kcal',
                style: TextStyle(fontSize: 11, color: textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMealDetails(BuildContext context, FoodLog meal) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDarkTheme ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDarkTheme ? AppColors.textMuted : AppColorsLight.textMuted;
    final teal = isDarkTheme ? AppColors.teal : AppColorsLight.teal;
    final cardBorder = isDarkTheme ? AppColors.cardBorder : AppColorsLight.cardBorder;

    showGlassSheet(
      context: context,
      builder: (ctx) => GlassSheet(
        maxHeightFraction: 0.6,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    _getMealEmoji(meal.mealType),
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meal.mealType.substring(0, 1).toUpperCase() +
                              meal.mealType.substring(1),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          '${meal.totalCalories} kcal',
                          style: TextStyle(
                            fontSize: 14,
                            color: teal,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _copyMealTo(ctx, meal),
                    icon: Icon(Icons.content_copy, color: teal, size: 20),
                    tooltip: 'Copy to...',
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      onDeleteMeal(meal.id);
                    },
                    icon: Icon(Icons.delete_outline, color: AppColors.error),
                    tooltip: 'Delete meal',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Food items list
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: meal.foodItems.length,
                itemBuilder: (context, index) {
                  final food = meal.foodItems[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cardBorder.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          food.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _MacroChip(label: 'Cal', value: '${food.calories ?? 0}', color: teal),
                            const SizedBox(width: 8),
                            _MacroChip(label: 'P', value: '${(food.proteinG ?? 0).toStringAsFixed(0)}g', color: AppColors.macroProtein),
                            const SizedBox(width: 8),
                            _MacroChip(label: 'C', value: '${(food.carbsG ?? 0).toStringAsFixed(0)}g', color: AppColors.macroCarbs),
                            const SizedBox(width: 8),
                            _MacroChip(label: 'F', value: '${(food.fatG ?? 0).toStringAsFixed(0)}g', color: AppColors.macroFat),
                          ],
                        ),
                        if (food.amount != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Amount: ${food.amount}',
                            style: TextStyle(
                              fontSize: 11,
                              color: textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            // Macros summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: cardBorder)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MacroSummaryItem(
                    label: 'Protein',
                    value: '${meal.proteinG.toStringAsFixed(0)}g',
                    color: AppColors.purple,
                    isDark: isDarkTheme,
                  ),
                  _MacroSummaryItem(
                    label: 'Carbs',
                    value: '${meal.carbsG.toStringAsFixed(0)}g',
                    color: AppColors.orange,
                    isDark: isDarkTheme,
                  ),
                  _MacroSummaryItem(
                    label: 'Fat',
                    value: '${meal.fatG.toStringAsFixed(0)}g',
                    color: AppColors.error,
                    isDark: isDarkTheme,
                  ),
                ],
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  String _getMealEmoji(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return '\u{1F373}';
      case 'lunch':
        return '\u{1F957}';
      case 'dinner':
        return '\u{1F37D}\u{FE0F}';
      case 'snack':
        return '\u{1F34E}';
      default:
        return '\u{1F374}';
    }
  }

  void _copyMealTo(BuildContext sheetContext, FoodLog meal) {
    final isDarkTheme = Theme.of(sheetContext).brightness == Brightness.dark;
    final textPrimary = isDarkTheme ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final teal = isDarkTheme ? AppColors.teal : AppColorsLight.teal;

    final mealTypes = [
      {'id': 'breakfast', 'label': 'Breakfast', 'emoji': '\u{1F373}'},
      {'id': 'lunch', 'label': 'Lunch', 'emoji': '\u{2600}\u{FE0F}'},
      {'id': 'dinner', 'label': 'Dinner', 'emoji': '\u{1F319}'},
      {'id': 'snack', 'label': 'Snack', 'emoji': '\u{1F34E}'},
    ];

    showGlassSheet(
      context: sheetContext,
      builder: (ctx) => GlassSheet(
        child: Padding(
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 16,
            bottom: MediaQuery.of(ctx).padding.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Copy to...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ...mealTypes.map((type) => ListTile(
                leading: Text(type['emoji']!, style: const TextStyle(fontSize: 20)),
                title: Text(
                  type['label']!,
                  style: TextStyle(color: textPrimary, fontWeight: FontWeight.w500),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                tileColor: meal.mealType == type['id'] ? teal.withValues(alpha: 0.1) : null,
                trailing: meal.mealType == type['id']
                    ? Text('Current', style: TextStyle(fontSize: 12, color: teal))
                    : null,
                onTap: () {
                  Navigator.pop(ctx);       // close picker
                  Navigator.pop(sheetContext); // close meal details
                  onCopyMeal(meal.id, type['id']!);
                },
              )),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper widget for macro chips in meal details
class _MacroChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MacroChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// Helper widget for macro summary in meal details
class _MacroSummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _MacroSummaryItem({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: textMuted,
          ),
        ),
      ],
    );
  }
}
