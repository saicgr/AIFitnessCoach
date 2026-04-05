part of 'food_library_screen.dart';


/// Food Library Card Widget
class _FoodLibraryCard extends StatelessWidget {
  final FoodLibraryItem item;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onLog;
  final VoidCallback onDelete;

  const _FoodLibraryCard({
    required this.item,
    required this.isDark,
    required this.onTap,
    required this.onLog,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accentColor = isDark ? AppColors.cyan : AppColorsLight.cyan;

    final isRecipe = item is RecipeLibraryItem;
    final typeColor = isRecipe
        ? AppColors.textSecondary // Purple for recipes
        : AppColors.textPrimary; // Green for saved foods

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.textMuted,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
      confirmDismiss: (direction) async {
        HapticService.swipeThreshold();
        return await AppDialog.destructive(
          context,
          title: 'Delete ${item.name}?',
          message: 'This action cannot be undone.',
          icon: Icons.delete_rounded,
        );
      },
      onDismissed: (direction) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Type indicator
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha:0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(
                        isRecipe
                            ? Icons.menu_book_rounded
                            : Icons.bookmark_rounded,
                        color: typeColor,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (item.calories != null) ...[
                              Text(
                                '${item.calories} cal',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (item.protein != null) ...[
                                Text(
                                  ' | ',
                                  style:
                                      TextStyle(fontSize: 13, color: textMuted),
                                ),
                                Text(
                                  '${item.protein!.round()}g protein',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                            if (item.timesUsed > 0) ...[
                              const Spacer(),
                              Icon(
                                Icons.sync_rounded,
                                size: 12,
                                color: textMuted,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${item.timesUsed}x',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textMuted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Quick log button
                  Material(
                    color: accentColor.withValues(alpha:0.15),
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: onLog,
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_rounded,
                              size: 18,
                              color: accentColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Log',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: accentColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


/// Sort Options Bottom Sheet
class _SortOptionsSheet extends StatelessWidget {
  final FoodLibrarySortOption currentSort;
  final bool isDark;
  final Function(FoodLibrarySortOption) onSelect;

  const _SortOptionsSheet({
    required this.currentSort,
    required this.isDark,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accentColor = isDark ? AppColors.cyan : AppColorsLight.cyan;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: textMuted.withValues(alpha:0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(Icons.sort_rounded, color: textPrimary, size: 22),
                  const SizedBox(width: 12),
                  Text(
                    'Sort By',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...FoodLibrarySortOption.values.map((option) {
              final isSelected = option == currentSort;
              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accentColor.withValues(alpha:0.15)
                        : textMuted.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    option.icon,
                    color: isSelected ? accentColor : textMuted,
                    size: 20,
                  ),
                ),
                title: Text(
                  option.label,
                  style: TextStyle(
                    color: isSelected ? accentColor : textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
                trailing: isSelected
                    ? Icon(Icons.check_rounded, color: accentColor)
                    : null,
                onTap: () => onSelect(option),
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}


/// Meal Type Selector Bottom Sheet
class _MealTypeSelector extends StatelessWidget {
  final bool isDark;

  const _MealTypeSelector({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: textMuted.withValues(alpha:0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Log to which meal?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...MealType.values.map((mealType) {
              return ListTile(
                leading: Text(
                  mealType.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(
                  mealType.label,
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  HapticService.selection();
                  Navigator.pop(context, mealType);
                },
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}


/// Food Detail Bottom Sheet
class _FoodDetailSheet extends StatelessWidget {
  final FoodLibraryItem item;
  final String userId;
  final bool isDark;
  final VoidCallback onLog;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FoodDetailSheet({
    required this.item,
    required this.userId,
    required this.isDark,
    required this.onLog,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final accentColor = isDark ? AppColors.cyan : AppColorsLight.cyan;

    final isRecipe = item is RecipeLibraryItem;
    final typeColor = isRecipe
        ? AppColors.textSecondary
        : AppColors.textPrimary;

    // Extract details based on type
    RecipeSummary? recipe;
    SavedFood? savedFood;
    if (item is RecipeLibraryItem) {
      recipe = (item as RecipeLibraryItem).recipe;
    } else if (item is SavedFoodLibraryItem) {
      savedFood = (item as SavedFoodLibraryItem).savedFood;
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: textMuted.withValues(alpha:0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha:0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      isRecipe
                          ? Icons.menu_book_rounded
                          : Icons.bookmark_rounded,
                      color: typeColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: typeColor.withValues(alpha:0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isRecipe ? 'Recipe' : 'Saved Food',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: typeColor,
                                ),
                              ),
                            ),
                            if (item.timesUsed > 0) ...[
                              const SizedBox(width: 8),
                              Text(
                                'Logged ${item.timesUsed}x',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textMuted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Nutrition Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.glassSurface
                      : AppColorsLight.glassSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nutrition${isRecipe ? ' per serving' : ''}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _NutrientStat(
                          label: 'Calories',
                          value: item.calories?.toString() ?? '-',
                          unit: 'kcal',
                          color: AppColors.textPrimary,
                          isDark: isDark,
                        ),
                        _NutrientStat(
                          label: 'Protein',
                          value: item.protein?.round().toString() ?? '-',
                          unit: 'g',
                          color: AppColors.textPrimary,
                          isDark: isDark,
                        ),
                        if (savedFood != null) ...[
                          _NutrientStat(
                            label: 'Carbs',
                            value: savedFood.totalCarbsG?.round().toString() ?? '-',
                            unit: 'g',
                            color: AppColors.textPrimary,
                            isDark: isDark,
                          ),
                          _NutrientStat(
                            label: 'Fat',
                            value: savedFood.totalFatG?.round().toString() ?? '-',
                            unit: 'g',
                            color: AppColors.textMuted,
                            isDark: isDark,
                          ),
                        ],
                        if (recipe != null) ...[
                          _NutrientStat(
                            label: 'Servings',
                            value: recipe.servings.toString(),
                            unit: '',
                            color: AppColors.textSecondary,
                            isDark: isDark,
                          ),
                          _NutrientStat(
                            label: 'Ingredients',
                            value: recipe.ingredientCount.toString(),
                            unit: '',
                            color: AppColors.textSecondary,
                            isDark: isDark,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Additional info for saved foods
            if (savedFood?.description != null &&
                savedFood!.description!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.glassSurface
                        : AppColorsLight.glassSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        savedFood.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Primary: Log button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: onLog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text(
                        'Log This Food',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Secondary actions row
                  Row(
                    children: [
                      // Edit (only for recipes)
                      if (isRecipe)
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: onEdit,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: textPrimary,
                                side: BorderSide(color: cardBorder),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: Icon(Icons.edit_rounded, size: 18),
                              label: const Text('Edit'),
                            ),
                          ),
                        ),
                      if (isRecipe) const SizedBox(width: 12),

                      // Delete
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: onDelete,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textMuted,
                              side: BorderSide(
                                  color: AppColors.textMuted.withValues(alpha:0.3)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: Icon(Icons.delete_outline_rounded, size: 18),
                            label: const Text('Delete'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}


/// Nutrient Stat Widget
class _NutrientStat extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final bool isDark;

  const _NutrientStat({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha:0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: value.length > 3 ? 11 : 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          unit.isNotEmpty ? '$value$unit' : value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: textMuted,
          ),
        ),
      ],
    );
  }
}

