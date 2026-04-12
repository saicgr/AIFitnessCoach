import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/models/nutrition.dart';
import '../../../data/services/api_client.dart';
import '../../../widgets/glass_sheet.dart';
import 'food_report_dialog.dart';

class LoggedMealsSection extends StatelessWidget {
  final List<FoodLog> meals;
  final void Function(String) onDeleteMeal;
  final void Function(String mealId, String targetMealType) onCopyMeal;
  final void Function(String mealId, String targetMealType) onMoveMeal;
  final void Function(String logId, int calories, double proteinG, double carbsG, double fatG, {double? weightG}) onUpdateMeal;
  final void Function(String logId, DateTime newTime) onUpdateMealTime;
  final void Function(String logId, String notes) onUpdateMealNotes;
  final void Function(String logId, {String? moodBefore, String? moodAfter, int? energyLevel}) onUpdateMealMood;
  final void Function(FoodLog meal) onSaveFoodToFavorites;
  final void Function(String? mealType) onLogMeal;
  final ApiClient? apiClient;
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
    required this.onMoveMeal,
    required this.onUpdateMeal,
    required this.onUpdateMealTime,
    required this.onUpdateMealNotes,
    required this.onUpdateMealMood,
    required this.onSaveFoodToFavorites,
    required this.onLogMeal,
    this.apiClient,
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
      final type = meal.mealType;
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
      direction: DismissDirection.horizontal,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16),
        color: teal.withValues(alpha: 0.9),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit, color: Colors.white, size: 18),
            SizedBox(width: 4),
            Text(
              'Edit',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
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
        if (direction == DismissDirection.startToEnd) {
          // Swipe right = Edit
          _showEditPortionSheet(context, meal);
          return false;
        }
        // Swipe left = Delete
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
        onLongPress: () {
          HapticFeedback.mediumImpact();
          _showQuickActionsMenu(context, meal);
        },
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

  // ============================================
  // Meal Details Sheet (tap)
  // ============================================

  void _showMealDetails(BuildContext context, FoodLog meal) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDarkTheme ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDarkTheme ? AppColors.textMuted : AppColorsLight.textMuted;
    final accentEnum = AccentColorScope.of(context);
    final teal = accentEnum.getColor(isDarkTheme);
    final cardBorder = isDarkTheme ? AppColors.cardBorder : AppColorsLight.cardBorder;

    showGlassSheet(
      context: context,
      builder: (ctx) => GlassSheet(
        maxHeightFraction: 0.75,
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
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showEditPortionSheet(context, meal);
                    },
                    icon: Icon(Icons.edit_outlined, color: teal, size: 20),
                    tooltip: 'Edit portion',
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _copyMealTo(context, meal);
                    },
                    icon: Icon(Icons.content_copy, color: teal, size: 20),
                    tooltip: 'Copy to...',
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _moveMealTo(context, meal);
                    },
                    icon: Icon(Icons.drive_file_move_outline, color: teal, size: 20),
                    tooltip: 'Move to...',
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
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  // Photo thumbnail (for photo-logged meals)
                  if (meal.imageUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        meal.imageUrl!,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Food items
                  ...meal.foodItems.asMap().entries.map((entry) {
                    final food = entry.value;
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
                          // Per-item inflammation score & UPF tag
                          if (food.inflammationScore != null || food.isUltraProcessed == true) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                if (food.inflammationScore != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _inflammationColor(food.inflammationScore!).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.local_fire_department, size: 12,
                                          color: _inflammationColor(food.inflammationScore!)),
                                        const SizedBox(width: 2),
                                        Text('${food.inflammationScore}',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                                            color: _inflammationColor(food.inflammationScore!))),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                if (food.isUltraProcessed == true)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text('UPF', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.red)),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  }),

                  // Health Score & AI Feedback
                  if (meal.healthScore != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _scoreColor(meal.healthScore!).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _scoreColor(meal.healthScore!).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _scoreColor(meal.healthScore!).withValues(alpha: 0.2),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${meal.healthScore}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _scoreColor(meal.healthScore!),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Health Score',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                  ),
                                ),
                                Text(
                                  _scoreLabel(meal.healthScore!),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _scoreColor(meal.healthScore!),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Meal-level Inflammation Score
                  if (meal.inflammationScore != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _inflammationColor(meal.inflammationScore!).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _inflammationColor(meal.inflammationScore!).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _inflammationColor(meal.inflammationScore!).withValues(alpha: 0.2),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${meal.inflammationScore}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _inflammationColor(meal.inflammationScore!),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text('Inflammation Score',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: () => _showInflammationInfo(context),
                                      child: Icon(Icons.info_outline, size: 16, color: textMuted),
                                    ),
                                  ],
                                ),
                                Text(
                                  _inflammationLabel(meal.inflammationScore!),
                                  style: TextStyle(fontSize: 11, color: _inflammationColor(meal.inflammationScore!)),
                                ),
                              ],
                            ),
                          ),
                          // Progress bar
                          SizedBox(
                            width: 80,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: meal.inflammationScore! / 10.0,
                                backgroundColor: cardBorder.withValues(alpha: 0.3),
                                valueColor: AlwaysStoppedAnimation<Color>(_inflammationColor(meal.inflammationScore!)),
                                minHeight: 6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Ultra-processed meal-level badge
                  if (meal.isUltraProcessed == true) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 18, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('Contains ultra-processed items',
                              style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w500)),
                          ),
                          GestureDetector(
                            onTap: () => _showUltraProcessedInfo(context),
                            child: Icon(Icons.info_outline, size: 16, color: Colors.red.withValues(alpha: 0.7)),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (meal.aiFeedback != null && meal.aiFeedback!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardBorder.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.auto_awesome, size: 16, color: teal),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              meal.aiFeedback!,
                              style: TextStyle(
                                fontSize: 12,
                                color: textMuted,
                                height: 1.4,
                              ),
                              maxLines: 5,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Notes
                  if (meal.notes != null && meal.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardBorder.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.note_outlined, size: 16, color: textMuted),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              meal.notes!,
                              style: TextStyle(fontSize: 12, color: textMuted, fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Mood & Energy
                  if (meal.moodBefore != null || meal.moodAfter != null || meal.energyLevel != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardBorder.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          if (meal.moodBeforeEnum != null) ...[
                            Text(meal.moodBeforeEnum!.emoji, style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_forward, size: 12, color: textMuted),
                            const SizedBox(width: 4),
                          ],
                          if (meal.moodAfterEnum != null)
                            Text(meal.moodAfterEnum!.emoji, style: const TextStyle(fontSize: 16)),
                          if (meal.energyLevel != null) ...[
                            const Spacer(),
                            Icon(Icons.bolt, size: 14, color: teal),
                            const SizedBox(width: 2),
                            Text(
                              '${meal.energyLevel}/5',
                              style: TextStyle(fontSize: 12, color: textMuted, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  // Micronutrients
                  if (meal.hasMicronutrients) ...[
                    const SizedBox(height: 8),
                    _buildMicronutrientsSection(meal, textPrimary, textMuted, teal, cardBorder),
                  ],
                ],
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

  // ============================================
  // Long-Press Quick Actions Menu
  // ============================================

  void _showQuickActionsMenu(BuildContext context, FoodLog meal) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDarkTheme ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDarkTheme ? AppColors.textMuted : AppColorsLight.textMuted;
    final accentEnum = AccentColorScope.of(context);
    final teal = accentEnum.getColor(isDarkTheme);
    final cardBorder = isDarkTheme ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final foodName = meal.foodItems.isNotEmpty
        ? (meal.foodItems.length == 1
            ? meal.foodItems.first.name
            : '${meal.foodItems.first.name} + ${meal.foodItems.length - 1} more')
        : 'Food';

    showGlassSheet(
      context: context,
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
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          foodName,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${meal.totalCalories} kcal',
                          style: TextStyle(fontSize: 12, color: textMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: Icon(Icons.close, color: textMuted, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Edit group
              _ActionTile(
                icon: Icons.edit_outlined,
                label: 'Edit portion',
                iconColor: teal,
                textColor: textPrimary,
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditPortionSheet(context, meal);
                },
              ),
              _ActionTile(
                icon: Icons.schedule,
                label: 'Edit time',
                iconColor: teal,
                textColor: textPrimary,
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditTimeDialog(context, meal);
                },
              ),
              _ActionTile(
                icon: Icons.note_add_outlined,
                label: meal.notes != null ? 'Edit note' : 'Add note',
                iconColor: teal,
                textColor: textPrimary,
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditNotesSheet(context, meal);
                },
              ),

              Divider(height: 16, color: cardBorder),

              // Organize group
              _ActionTile(
                icon: Icons.content_copy,
                label: 'Copy to...',
                iconColor: teal,
                textColor: textPrimary,
                onTap: () {
                  Navigator.pop(ctx);
                  _copyMealTo(context, meal);
                },
              ),
              _ActionTile(
                icon: Icons.drive_file_move_outline,
                label: 'Move to...',
                iconColor: teal,
                textColor: textPrimary,
                onTap: () {
                  Navigator.pop(ctx);
                  _moveMealTo(context, meal);
                },
              ),
              _ActionTile(
                icon: Icons.bookmark_add_outlined,
                label: 'Save to My Foods',
                iconColor: teal,
                textColor: textPrimary,
                onTap: () {
                  Navigator.pop(ctx);
                  onSaveFoodToFavorites(meal);
                },
              ),

              Divider(height: 16, color: cardBorder),

              // Feedback group
              _ActionTile(
                icon: Icons.mood,
                label: 'Log mood & energy',
                iconColor: teal,
                textColor: textPrimary,
                onTap: () {
                  Navigator.pop(ctx);
                  _showMoodEnergySheet(context, meal);
                },
              ),
              _ActionTile(
                icon: Icons.flag_outlined,
                label: 'Report incorrect data',
                iconColor: teal,
                textColor: textPrimary,
                onTap: () {
                  Navigator.pop(ctx);
                  _showReportDialog(context, meal);
                },
              ),

              Divider(height: 16, color: cardBorder),

              // Delete
              _ActionTile(
                icon: Icons.delete_outline,
                label: 'Delete',
                iconColor: AppColors.error,
                textColor: AppColors.error,
                onTap: () {
                  Navigator.pop(ctx);
                  onDeleteMeal(meal.id);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================
  // Edit Portion Sheet
  // ============================================

  void _showEditPortionSheet(BuildContext context, FoodLog meal) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDarkTheme ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDarkTheme ? AppColors.textMuted : AppColorsLight.textMuted;
    final accentEnum = AccentColorScope.of(context);
    final accent = accentEnum.getColor(isDarkTheme);
    final glassSurface = isDarkTheme ? AppColors.glassSurface : AppColorsLight.glassSurface;
    final macroProtein = isDarkTheme ? AppColors.macroProtein : AppColorsLight.macroProtein;
    final macroCarbs = isDarkTheme ? AppColors.macroCarbs : AppColorsLight.macroCarbs;
    final macroFat = isDarkTheme ? AppColors.macroFat : AppColorsLight.macroFat;

    double multiplier = 1.0;

    // Weight unit toggle state
    const weightUnits = ['g', 'oz', 'lb', 'kg', 'ml', 'mg'];
    int selectedUnitIndex = 0;

    // Determine available edit modes
    final hasWeight = meal.hasWeightData;
    final hasCount = meal.hasCountData;
    final firstItemWithWeight = hasWeight ? meal.foodItems.firstWhere((i) => i.hasWeightData) : null;
    final firstItemWithCount = hasCount ? meal.foodItems.firstWhere((i) => i.hasCountData) : null;

    // Initialize unit index from the item's unit
    if (firstItemWithWeight != null) {
      final itemUnit = (firstItemWithWeight.unit ?? 'g').toLowerCase();
      final idx = weightUnits.indexOf(itemUnit);
      if (idx >= 0) selectedUnitIndex = idx;
    }

    // Serving presets with size labels
    const servingPresets = [
      (label: '\u00BD', multiplier: 0.5, size: 'Small'),
      (label: '\u00BE', multiplier: 0.75, size: 'Medium'),
      (label: '1x', multiplier: 1.0, size: 'Standard'),
      (label: '1\u00BC', multiplier: 1.25, size: 'Large'),
      (label: '1\u00BD', multiplier: 1.5, size: 'X-Large'),
      (label: '2x', multiplier: 2.0, size: 'Double'),
      (label: '3x', multiplier: 3.0, size: 'Triple'),
    ];

    // Unit conversion factors from grams
    double convertFromGrams(double grams, String unit) {
      switch (unit) {
        case 'oz': return grams / 28.3495;
        case 'lb': return grams / 453.592;
        case 'kg': return grams / 1000.0;
        case 'ml': return grams; // 1:1 for water-density approximation
        case 'mg': return grams * 1000.0;
        default: return grams;
      }
    }

    double convertToGrams(double value, String unit) {
      switch (unit) {
        case 'oz': return value * 28.3495;
        case 'lb': return value * 453.592;
        case 'kg': return value * 1000.0;
        case 'ml': return value;
        case 'mg': return value / 1000.0;
        default: return value;
      }
    }

    showGlassSheet(
      context: context,
      builder: (ctx) => GlassSheet(
        child: StatefulBuilder(
          builder: (context, setState) {
            final adjCalories = (meal.totalCalories * multiplier).round();
            final adjProtein = (meal.proteinG * multiplier);
            final adjCarbs = (meal.carbsG * multiplier);
            final adjFat = (meal.fatG * multiplier);
            final currentUnit = weightUnits[selectedUnitIndex];

            return Padding(
              padding: EdgeInsets.only(
                left: 16, right: 16, top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(Icons.tune, color: accent, size: 20),
                      const SizedBox(width: 8),
                      Text('Adjust Portion', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${(multiplier * 100).round()}%',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: accent),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Serving presets with size labels
                  Text('Servings', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textMuted)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: servingPresets.map((preset) {
                      final isSelected = (multiplier - preset.multiplier).abs() < 0.01;
                      return GestureDetector(
                        onTap: () => setState(() => multiplier = preset.multiplier),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? accent : glassSurface,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                preset.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? Colors.white : textPrimary,
                                ),
                              ),
                              Text(
                                preset.size,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: isSelected ? Colors.white70 : textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  // Weight + Quantity on same row
                  if (hasWeight || hasCount) ...[
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Weight input with unit toggle
                        if (hasWeight && firstItemWithWeight != null)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Weight', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textMuted)),
                                const SizedBox(height: 8),
                                TextField(
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: TextStyle(color: textPrimary, fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: '${convertFromGrams((firstItemWithWeight.weightG ?? 0) * multiplier, currentUnit).round()}',
                                    hintStyle: TextStyle(color: textMuted),
                                    suffixIcon: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          selectedUnitIndex = (selectedUnitIndex + 1) % weightUnits.length;
                                        });
                                      },
                                      child: Container(
                                        width: 44,
                                        alignment: Alignment.center,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: accent.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            currentUnit,
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: accent),
                                          ),
                                        ),
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: glassSurface,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    isDense: true,
                                  ),
                                  onChanged: (value) {
                                    final newValue = double.tryParse(value);
                                    if (newValue != null && newValue > 0 && firstItemWithWeight.weightG != null && firstItemWithWeight.weightG! > 0) {
                                      final newWeightG = convertToGrams(newValue, currentUnit);
                                      setState(() => multiplier = (newWeightG / firstItemWithWeight.weightG!).clamp(0.1, 10.0));
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),

                        // Spacer between weight and quantity
                        if (hasWeight && firstItemWithWeight != null && hasCount && firstItemWithCount != null)
                          const SizedBox(width: 16),

                        // Quantity input
                        if (hasCount && firstItemWithCount != null)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Quantity', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textMuted)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _AdjustBtn(icon: Icons.remove, color: accent, onTap: () {
                                      final currentCount = (firstItemWithCount.count! * multiplier).round();
                                      if (currentCount > 1) {
                                        setState(() => multiplier = ((currentCount - 1) / firstItemWithCount.count!).clamp(0.1, 10.0));
                                      }
                                    }),
                                    Expanded(
                                      child: Center(
                                        child: Text(
                                          '${(firstItemWithCount.count! * multiplier).round()}',
                                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary),
                                        ),
                                      ),
                                    ),
                                    _AdjustBtn(icon: Icons.add, color: accent, onTap: () {
                                      final currentCount = (firstItemWithCount.count! * multiplier).round();
                                      setState(() => multiplier = ((currentCount + 1) / firstItemWithCount.count!).clamp(0.1, 10.0));
                                    }),
                                  ],
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Macro preview
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: glassSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _NutrientPreviewItem(label: 'Cal', value: '$adjCalories', isDark: isDarkTheme),
                        _NutrientPreviewItem(label: 'P', value: '${adjProtein.round()}g', isDark: isDarkTheme, color: macroProtein),
                        _NutrientPreviewItem(label: 'C', value: '${adjCarbs.round()}g', isDark: isDarkTheme, color: macroCarbs),
                        _NutrientPreviewItem(label: 'F', value: '${adjFat.round()}g', isDark: isDarkTheme, color: macroFat),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onUpdateMeal(
                          meal.id,
                          adjCalories,
                          adjProtein,
                          adjCarbs,
                          adjFat,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Save', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================
  // Copy / Move Meal Pickers
  // ============================================

  void _copyMealTo(BuildContext parentContext, FoodLog meal) {
    _showMealTypePicker(parentContext, meal, 'Copy to...', (type) {
      onCopyMeal(meal.id, type);
    });
  }

  void _moveMealTo(BuildContext parentContext, FoodLog meal) {
    _showMealTypePicker(parentContext, meal, 'Move to...', (type) {
      onMoveMeal(meal.id, type);
    });
  }

  void _showMealTypePicker(BuildContext parentContext, FoodLog meal, String title, void Function(String type) onSelect) {
    final isDarkTheme = Theme.of(parentContext).brightness == Brightness.dark;
    final textPrimary = isDarkTheme ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final accentEnum = AccentColorScope.of(parentContext);
    final accent = accentEnum.getColor(isDarkTheme);

    final mealTypes = [
      {'id': 'breakfast', 'label': 'Breakfast', 'emoji': '\u{1F373}'},
      {'id': 'lunch', 'label': 'Lunch', 'emoji': '\u{2600}\u{FE0F}'},
      {'id': 'dinner', 'label': 'Dinner', 'emoji': '\u{1F319}'},
      {'id': 'snack', 'label': 'Snack', 'emoji': '\u{1F34E}'},
    ];

    showGlassSheet(
      context: parentContext,
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
                title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
              ),
              const SizedBox(height: 12),
              ...mealTypes.map((type) => ListTile(
                leading: Text(type['emoji']!, style: const TextStyle(fontSize: 20)),
                title: Text(
                  type['label']!,
                  style: TextStyle(color: textPrimary, fontWeight: FontWeight.w500),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                tileColor: meal.mealType == type['id'] ? accent.withValues(alpha: 0.1) : null,
                trailing: meal.mealType == type['id']
                    ? Text('Current', style: TextStyle(fontSize: 12, color: accent))
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  onSelect(type['id']!);
                },
              )),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================
  // Edit Time Dialog
  // ============================================

  void _showEditTimeDialog(BuildContext context, FoodLog meal) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(meal.loggedAt),
    );
    if (time != null) {
      final newDateTime = DateTime(
        meal.loggedAt.year,
        meal.loggedAt.month,
        meal.loggedAt.day,
        time.hour,
        time.minute,
      );
      onUpdateMealTime(meal.id, newDateTime);
    }
  }

  // ============================================
  // Edit Notes Sheet
  // ============================================

  void _showEditNotesSheet(BuildContext context, FoodLog meal) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDarkTheme ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDarkTheme ? AppColors.textMuted : AppColorsLight.textMuted;
    final accentEnum = AccentColorScope.of(context);
    final accent = accentEnum.getColor(isDarkTheme);
    final glassSurface = isDarkTheme ? AppColors.glassSurface : AppColorsLight.glassSurface;

    final controller = TextEditingController(text: meal.notes ?? '');

    showGlassSheet(
      context: context,
      builder: (ctx) => GlassSheet(
        child: Padding(
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.of(ctx).padding.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add Note', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary)),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 3,
                maxLength: 500,
                autofocus: true,
                style: TextStyle(color: textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'e.g. ate at restaurant, homemade...',
                  hintStyle: TextStyle(color: textMuted),
                  filled: true,
                  fillColor: glassSurface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    onUpdateMealNotes(meal.id, controller.text.trim());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) => controller.dispose());
  }

  // ============================================
  // Mood & Energy Sheet
  // ============================================

  void _showMoodEnergySheet(BuildContext context, FoodLog meal) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDarkTheme ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDarkTheme ? AppColors.textMuted : AppColorsLight.textMuted;
    final accentEnum = AccentColorScope.of(context);
    final accent = accentEnum.getColor(isDarkTheme);
    final glassSurface = isDarkTheme ? AppColors.glassSurface : AppColorsLight.glassSurface;

    FoodMood? moodBefore = meal.moodBeforeEnum;
    FoodMood? moodAfter = meal.moodAfterEnum;
    int energyLevel = meal.energyLevel ?? 3;

    showGlassSheet(
      context: context,
      builder: (ctx) => GlassSheet(
        child: StatefulBuilder(
          builder: (_, setState) => Padding(
            padding: EdgeInsets.only(
              left: 16, right: 16, top: 16,
              bottom: MediaQuery.of(ctx).padding.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('How did you feel?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary)),
                const SizedBox(height: 16),

                // Before eating
                Text('Before eating', style: TextStyle(fontSize: 13, color: textMuted)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: FoodMood.values.map((mood) {
                    final isSelected = moodBefore == mood;
                    return GestureDetector(
                      onTap: () => setState(() => moodBefore = isSelected ? null : mood),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? accent : glassSurface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${mood.emoji} ${mood.displayName}',
                          style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : textPrimary),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // After eating
                Text('After eating', style: TextStyle(fontSize: 13, color: textMuted)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: FoodMood.values.map((mood) {
                    final isSelected = moodAfter == mood;
                    return GestureDetector(
                      onTap: () => setState(() => moodAfter = isSelected ? null : mood),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? accent : glassSurface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${mood.emoji} ${mood.displayName}',
                          style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : textPrimary),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Energy level
                Row(
                  children: [
                    Text('Energy level', style: TextStyle(fontSize: 13, color: textMuted)),
                    const Spacer(),
                    Text('$energyLevel/5', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: accent)),
                  ],
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: accent,
                    inactiveTrackColor: glassSurface,
                    thumbColor: accent,
                    overlayColor: accent.withValues(alpha: 0.2),
                  ),
                  child: Slider(
                    value: energyLevel.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    onChanged: (v) => setState(() => energyLevel = v.round()),
                  ),
                ),
                const SizedBox(height: 16),

                // Save
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      onUpdateMealMood(
                        meal.id,
                        moodBefore: moodBefore?.value,
                        moodAfter: moodAfter?.value,
                        energyLevel: energyLevel,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Save', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================
  // Report Dialog
  // ============================================

  void _showReportDialog(BuildContext context, FoodLog meal) {
    if (apiClient == null) return;
    showFoodReportDialog(
      context,
      apiClient: apiClient!,
      foodName: meal.foodItems.isNotEmpty ? meal.foodItems.first.name : 'Food',
      originalCalories: meal.totalCalories,
      originalProtein: meal.proteinG,
      originalCarbs: meal.carbsG,
      originalFat: meal.fatG,
      foodLogId: meal.id,
      dataSource: 'food_log',
    );
  }

  // ============================================
  // Micronutrients Section
  // ============================================

  Widget _buildMicronutrientsSection(FoodLog meal, Color textPrimary, Color textMuted, Color teal, Color cardBorder) {
    final nutrients = <MapEntry<String, String>>[];
    if (meal.sodiumMg != null) nutrients.add(MapEntry('Sodium', '${meal.sodiumMg!.round()}mg'));
    if (meal.sugarG != null) nutrients.add(MapEntry('Sugar', '${meal.sugarG!.toStringAsFixed(1)}g'));
    if (meal.saturatedFatG != null) nutrients.add(MapEntry('Sat. Fat', '${meal.saturatedFatG!.toStringAsFixed(1)}g'));
    if (meal.cholesterolMg != null) nutrients.add(MapEntry('Cholesterol', '${meal.cholesterolMg!.round()}mg'));
    if (meal.potassiumMg != null) nutrients.add(MapEntry('Potassium', '${meal.potassiumMg!.round()}mg'));
    if (meal.calciumMg != null) nutrients.add(MapEntry('Calcium', '${meal.calciumMg!.round()}mg'));
    if (meal.ironMg != null) nutrients.add(MapEntry('Iron', '${meal.ironMg!.toStringAsFixed(1)}mg'));
    if (meal.vitaminAUg != null) nutrients.add(MapEntry('Vitamin A', '${meal.vitaminAUg!.round()}\u00B5g'));
    if (meal.vitaminCMg != null) nutrients.add(MapEntry('Vitamin C', '${meal.vitaminCMg!.toStringAsFixed(1)}mg'));
    if (meal.vitaminDIu != null) nutrients.add(MapEntry('Vitamin D', '${meal.vitaminDIu!.round()}IU'));

    if (nutrients.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBorder.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.science_outlined, size: 14, color: teal),
              const SizedBox(width: 6),
              Text('Micronutrients', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: nutrients.map((e) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${e.key}: ', style: TextStyle(fontSize: 11, color: textMuted)),
                Text(e.value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textPrimary)),
              ],
            )).toList(),
          ),
        ],
      ),
    );
  }

  // ============================================
  // Helpers
  // ============================================

  String _getMealEmoji(String mealType) {
    switch (mealType) {
      case 'breakfast': return '\u{1F373}';
      case 'lunch': return '\u{1F957}';
      case 'dinner': return '\u{1F37D}\u{FE0F}';
      case 'snack': return '\u{1F34E}';
      default: return '\u{1F374}';
    }
  }

  Color _scoreColor(int score) {
    if (score >= 7) return Colors.green;
    if (score >= 4) return Colors.orange;
    return AppColors.error;
  }

  String _scoreLabel(int score) {
    if (score >= 8) return 'Excellent';
    if (score >= 7) return 'Good';
    if (score >= 5) return 'Average';
    if (score >= 3) return 'Below average';
    return 'Poor';
  }

  Color _inflammationColor(int score) {
    if (score <= 3) return Colors.green;
    if (score <= 5) return Colors.teal;
    if (score <= 7) return Colors.orange;
    return Colors.red;
  }

  String _inflammationLabel(int score) {
    if (score <= 2) return 'Anti-inflammatory';
    if (score <= 4) return 'Mildly anti-inflammatory';
    if (score == 5) return 'Neutral';
    if (score <= 7) return 'Mildly inflammatory';
    if (score <= 9) return 'Inflammatory';
    return 'Highly inflammatory';
  }

  void _showInflammationInfo(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_fire_department, color: Colors.orange),
                const SizedBox(width: 8),
                Text('Inflammation Score', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black)),
              ],
            ),
            const SizedBox(height: 16),
            Text('Rates how inflammatory a food is based on processing level, fat profile, sugar content, fiber, and antioxidant properties.',
              style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87, height: 1.5)),
            const SizedBox(height: 16),
            _buildInfoRow('1-3', 'Anti-inflammatory', Colors.green),
            _buildInfoRow('4-5', 'Neutral', Colors.teal),
            _buildInfoRow('6-7', 'Mildly inflammatory', Colors.orange),
            _buildInfoRow('8-10', 'Inflammatory', Colors.red),
            const SizedBox(height: 16),
            Text('Lower is better for reducing body inflammation and gut health.',
              style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.black54, fontStyle: FontStyle.italic)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String range, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 40,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(range, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
              textAlign: TextAlign.center),
          ),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 14, color: color)),
        ],
      ),
    );
  }

  void _showUltraProcessedInfo(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red),
                const SizedBox(width: 8),
                Text('Ultra-Processed Foods', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black)),
              ],
            ),
            const SizedBox(height: 16),
            Text('Ultra-processed foods (NOVA Group 4) contain industrial additives like emulsifiers, hydrogenated oils, artificial sweeteners, and protein isolates — substances not found in home cooking.',
              style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87, height: 1.5)),
            const SizedBox(height: 12),
            Text('Research links regular consumption to increased inflammation, obesity, heart disease, and digestive issues.',
              style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87, height: 1.5)),
            const SizedBox(height: 12),
            Text('Examples: soft drinks, instant noodles, packaged snacks, chicken nuggets, most breakfast cereals.',
              style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.black54, fontStyle: FontStyle.italic)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ============================================
// Helper Widgets
// ============================================

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color textColor;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 14),
            Text(label, style: TextStyle(fontSize: 14, color: textColor)),
          ],
        ),
      ),
    );
  }
}

class _AdjustBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AdjustBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }
}

class _NutrientPreviewItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final Color? color;

  const _NutrientPreviewItem({required this.label, required this.value, required this.isDark, this.color});

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color ?? textPrimary)),
        Text(label, style: TextStyle(fontSize: 11, color: color?.withValues(alpha: 0.7) ?? textMuted)),
      ],
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MacroChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _MacroSummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _MacroSummaryItem({required this.label, required this.value, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 11, color: textMuted)),
      ],
    );
  }
}
