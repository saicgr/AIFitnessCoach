part of 'nutrition_settings_screen.dart';

/// Methods extracted from _NutritionSettingsScreenState
extension __NutritionSettingsScreenStateExt on _NutritionSettingsScreenState {

  void _showCalorieBiasSheet(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color elevated,
    NutritionPreferences preferences,
    String? userId,
  ) {
    if (userId == null) return;

    final nearBlack = isDark ? AppColors.nearBlack : AppColorsLight.nearWhite;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;
    int currentBias = preferences.calorieEstimateBias;

    showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        child: StatefulBuilder(
          builder: (context, setSheetState) {
            final label = _biasLabel(currentBias);
            final multiplier = _NutritionSettingsScreenState._biasMultipliers[currentBias] ?? 1.0;
            final exampleCal = (600 * multiplier).round();

            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 8,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Calorie Estimate Bias',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'If AI calorie estimates feel too high or too low for your meals, '
                    'adjust the bias so future estimates better match reality.',
                    style: TextStyle(fontSize: 14, color: textMuted),
                  ),
                  const SizedBox(height: 20),

                  // Current selection card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: elevated,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: currentBias == 0
                                ? textMuted
                                : (currentBias > 0 ? teal : Colors.orange),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          '${multiplier.toStringAsFixed(2)}x',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Slider
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: teal,
                      inactiveTrackColor: textMuted.withValues(alpha: 0.2),
                      thumbColor: teal,
                      overlayColor: teal.withValues(alpha: 0.15),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: currentBias.toDouble(),
                      min: -2,
                      max: 2,
                      divisions: 4,
                      onChanged: (value) {
                        setSheetState(() {
                          currentBias = value.round();
                        });
                      },
                    ),
                  ),
                  // Slider labels
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Under More',
                            style: TextStyle(fontSize: 11, color: textMuted)),
                        Text('No Bias',
                            style: TextStyle(fontSize: 11, color: textMuted)),
                        Text('Over More',
                            style: TextStyle(fontSize: 11, color: textMuted)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Example section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: textPrimary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lightbulb_outline,
                            size: 18, color: textMuted),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Example: A 600 cal meal would be logged as $exampleCal cal',
                            style: TextStyle(fontSize: 13, color: textMuted),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        HapticService.light();
                        Navigator.pop(context);
                        _updatePreference(
                          userId,
                          preferences,
                          calorieEstimateBias: currentBias,
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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


  void _showEditFoodPrefsSheet(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color elevated,
    NutritionPreferences preferences,
    String? userId,
  ) {
    if (userId == null) return;

    String selectedMealPattern = preferences.mealPattern;
    String selectedCookingSkill = preferences.cookingSkill;
    int selectedCookingTime = preferences.cookingTimeMinutes;
    String selectedBudget = preferences.budgetLevel;
    List<String> selectedAllergens = List.from(preferences.allergies);
    List<String> selectedRestrictions = List.from(preferences.dietaryRestrictions);
    bool isSaving = false;

    final mealPatterns = [
      ('3_meals', '3 Meals'), ('3_meals_snacks', '3 Meals + Snacks'), ('2_meals', '2 Meals'),
      ('omad', 'OMAD'), ('if_16_8', 'IF 16:8'), ('if_18_6', 'IF 18:6'), ('if_20_4', 'IF 20:4'),
      ('5_6_small_meals', '5-6 Small Meals'), ('religious_fasting', 'Religious Fast'), ('custom', 'Custom'),
    ];
    const cookingTimes = [15, 20, 30, 45, 60, 90];

    showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        child: StatefulBuilder(
          builder: (context, setSheetState) => SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 24, right: 24, top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Food Preferences', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary)),
                    IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close, color: textMuted)),
                  ],
                ),
                const SizedBox(height: 16),

                // Meal Pattern
                Text('Meal Pattern', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: mealPatterns.map((mp) {
                    final selected = selectedMealPattern == mp.$1;
                    return GestureDetector(
                      onTap: () => setSheetState(() => selectedMealPattern = mp.$1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? textPrimary.withValues(alpha: 0.15) : elevated,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: selected ? textPrimary.withValues(alpha: 0.4) : Colors.transparent),
                        ),
                        child: Text(mp.$2, style: TextStyle(fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.w500, color: selected ? textPrimary : textMuted)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Cooking Skill
                Text('Cooking Skill', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
                const SizedBox(height: 8),
                Row(
                  children: CookingSkill.values.map((skill) {
                    final selected = selectedCookingSkill == skill.value;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setSheetState(() => selectedCookingSkill = skill.value),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selected ? textPrimary.withValues(alpha: 0.15) : elevated,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: selected ? textPrimary.withValues(alpha: 0.4) : Colors.transparent),
                          ),
                          child: Text(skill.displayName.split(' ').first, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.w500, color: selected ? textPrimary : textMuted)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Cooking Time
                Text('Cooking Time (minutes)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: cookingTimes.map((t) {
                    final selected = selectedCookingTime == t;
                    return GestureDetector(
                      onTap: () => setSheetState(() => selectedCookingTime = t),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? textPrimary.withValues(alpha: 0.15) : elevated,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: selected ? textPrimary.withValues(alpha: 0.4) : Colors.transparent),
                        ),
                        child: Text('$t min', style: TextStyle(fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.w500, color: selected ? textPrimary : textMuted)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Budget
                Text('Budget', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
                const SizedBox(height: 8),
                Row(
                  children: BudgetLevel.values.map((b) {
                    final selected = selectedBudget == b.value;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setSheetState(() => selectedBudget = b.value),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selected ? textPrimary.withValues(alpha: 0.15) : elevated,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: selected ? textPrimary.withValues(alpha: 0.4) : Colors.transparent),
                          ),
                          child: Text(b.displayName.split('-').first.trim(), textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: selected ? FontWeight.w600 : FontWeight.w500, color: selected ? textPrimary : textMuted)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Allergens
                Text('Allergens', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: FoodAllergen.values.map((a) {
                    final selected = selectedAllergens.contains(a.value);
                    return GestureDetector(
                      onTap: () => setSheetState(() => selected ? selectedAllergens.remove(a.value) : selectedAllergens.add(a.value)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.orange.withValues(alpha: 0.15) : elevated,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: selected ? AppColors.orange.withValues(alpha: 0.5) : Colors.transparent),
                        ),
                        child: Text(a.displayName, style: TextStyle(fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.w500, color: selected ? AppColors.orange : textMuted)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Dietary Restrictions
                Text('Dietary Restrictions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: DietaryRestriction.values.map((r) {
                    final selected = selectedRestrictions.contains(r.value);
                    return GestureDetector(
                      onTap: () => setSheetState(() => selected ? selectedRestrictions.remove(r.value) : selectedRestrictions.add(r.value)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.purple.withValues(alpha: 0.15) : elevated,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: selected ? AppColors.purple.withValues(alpha: 0.5) : Colors.transparent),
                        ),
                        child: Text(r.displayName, style: TextStyle(fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.w500, color: selected ? AppColors.purple : textMuted)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : () async {
                      setSheetState(() => isSaving = true);
                      try {
                        final updated = preferences.copyWith(
                          mealPattern: selectedMealPattern,
                          cookingSkill: selectedCookingSkill,
                          cookingTimeMinutes: selectedCookingTime,
                          budgetLevel: selectedBudget,
                          allergies: selectedAllergens,
                          dietaryRestrictions: selectedRestrictions,
                        );
                        await ref.read(nutritionPreferencesProvider.notifier).savePreferences(userId: userId, preferences: updated);
                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        setSheetState(() => isSaving = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: textPrimary,
                      foregroundColor: isDark ? AppColors.pureBlack : AppColorsLight.pureWhite,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isSaving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  /// Show bottom sheet to edit nutrition goals
  void _showEditGoalsSheet(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color elevated,
    NutritionPreferences preferences,
    String? userId,
  ) {
    if (userId == null) return;

    final nearBlack = isDark ? AppColors.nearBlack : AppColorsLight.nearWhite;
    final green = textPrimary;

    // Available goals
    final allGoals = [
      {'id': 'lose_fat', 'name': 'Lose Fat', 'icon': Icons.local_fire_department},
      {'id': 'build_muscle', 'name': 'Build Muscle', 'icon': Icons.fitness_center},
      {'id': 'maintain', 'name': 'Maintain Weight', 'icon': Icons.balance},
      {'id': 'improve_energy', 'name': 'Improve Energy', 'icon': Icons.bolt},
      {'id': 'eat_healthier', 'name': 'Eat Healthier', 'icon': Icons.eco},
      {'id': 'recomposition', 'name': 'Body Recomposition', 'icon': Icons.swap_vert},
    ];

    // Rate of change options
    final rateOptions = ['slow', 'moderate', 'fast', 'aggressive'];

    // Local state for selections
    List<String> selectedGoals = List.from(preferences.nutritionGoals);
    String selectedRate = preferences.rateOfChange ?? 'moderate';
    bool isSaving = false;

    showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        child: StatefulBuilder(
          builder: (context, setSheetState) => Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Edit Nutrition Goals',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Select your goals (first selected = primary)',
                  style: TextStyle(fontSize: 14, color: textMuted),
                ),
                const SizedBox(height: 16),
                // Goals multi-select
                ...allGoals.map((goal) {
                  final isSelected = selectedGoals.contains(goal['id']);
                  final isPrimary = selectedGoals.isNotEmpty && selectedGoals.first == goal['id'];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: () {
                        setSheetState(() {
                          if (isSelected) {
                            selectedGoals.remove(goal['id']);
                          } else {
                            selectedGoals.add(goal['id'] as String);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? green.withValues(alpha: 0.15)
                              : elevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? green.withValues(alpha: 0.5)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              goal['icon'] as IconData,
                              color: isSelected ? green : textMuted,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                goal['name'] as String,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  color: isSelected ? green : textPrimary,
                                ),
                              ),
                            ),
                            if (isPrimary)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: green.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Primary',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: green,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 8),
                            Icon(
                              isSelected
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              color: isSelected ? green : textMuted,
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                // Rate of change
                Text(
                  'Rate of Change',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: rateOptions.map((rate) {
                    final isSelected = selectedRate == rate;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: rate != 'aggressive' ? 8 : 0),
                        child: GestureDetector(
                          onTap: () => setSheetState(() => selectedRate = rate),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? green.withValues(alpha: 0.15)
                                  : elevated,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? green.withValues(alpha: 0.5)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                rate[0].toUpperCase() + rate.substring(1),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  color: isSelected ? green : textMuted,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                // Save button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: isSaving || selectedGoals.isEmpty
                        ? null
                        : () async {
                            setSheetState(() => isSaving = true);
                            HapticService.light();

                            try {
                              // Call recalculate endpoint with new goals
                              final authState = ref.read(authStateProvider);
                              final user = authState.user;
                              final apiClient = ref.read(apiClientProvider);

                              await apiClient.post(
                                '${ApiConstants.users}/$userId/calculate-nutrition-targets',
                                data: {
                                  'weight_kg': user?.weightKg ?? 70,
                                  'height_cm': user?.heightCm ?? 170,
                                  'age': user?.age ?? 30,
                                  'gender': user?.gender ?? 'male',
                                  'activity_level': user?.activityLevel ?? 'moderately_active',
                                  'weight_direction': selectedGoals.contains('lose_fat') ? 'lose' : (selectedGoals.contains('build_muscle') ? 'gain' : 'maintain'),
                                  'weight_change_rate': selectedRate,
                                  'goal_weight_kg': user?.targetWeightKg,
                                  'nutrition_goals': selectedGoals,
                                  'workout_days_per_week': user?.workoutsPerWeek ?? 3,
                                },
                              );

                              // Refresh preferences
                              await ref.read(nutritionPreferencesProvider.notifier).initialize(userId);

                              Navigator.pop(context);

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Goals updated and targets recalculated!'),
                                    backgroundColor: green,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            } catch (e) {
                              debugPrint('❌ Error updating goals: $e');
                              setSheetState(() => isSaving = false);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: textMuted,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save & Recalculate',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
