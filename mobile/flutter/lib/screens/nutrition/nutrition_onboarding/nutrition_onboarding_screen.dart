import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/nutrition_preferences.dart';
import '../../../data/providers/nutrition_preferences_provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/haptic_service.dart';

/// Onboarding screen for nutrition preferences
class NutritionOnboardingScreen extends ConsumerStatefulWidget {
  const NutritionOnboardingScreen({super.key});

  @override
  ConsumerState<NutritionOnboardingScreen> createState() =>
      _NutritionOnboardingScreenState();
}

class _NutritionOnboardingScreenState
    extends ConsumerState<NutritionOnboardingScreen> {
  int _currentStep = 0;
  bool _isSubmitting = false;

  // User selections
  NutritionGoal _selectedGoal = NutritionGoal.maintain;
  RateOfChange _selectedRate = RateOfChange.moderate;
  DietType _selectedDietType = DietType.balanced;
  final List<FoodAllergen> _selectedAllergies = [];
  final List<DietaryRestriction> _selectedRestrictions = [];
  MealPattern _selectedMealPattern = MealPattern.threeMeals;
  CookingSkill _selectedCookingSkill = CookingSkill.intermediate;
  final int _cookingTimeMinutes = 30;
  BudgetLevel _selectedBudgetLevel = BudgetLevel.moderate;

  // Custom macros (if DietType.custom)
  int _customCarbPercent = 45;
  int _customProteinPercent = 25;
  int _customFatPercent = 30;

  // Calculated targets for preview
  NutritionPreferences? _calculatedTargets;

  static const int _totalSteps = 6;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final green = isDark ? AppColors.green : AppColorsLight.success;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: List.generate(_totalSteps, (index) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin:
                          EdgeInsets.only(right: index < _totalSteps - 1 ? 8 : 0),
                      decoration: BoxDecoration(
                        color: index <= _currentStep
                            ? green
                            : textMuted.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildStep(
                      _currentStep, isDark, textPrimary, textMuted, green),
                ),
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousStep,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: green),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Back',
                          style: TextStyle(color: green),
                        ),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 16),
                  Expanded(
                    flex: _currentStep == 0 ? 1 : 1,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              _currentStep == _totalSteps - 1
                                  ? 'Get Started'
                                  : 'Continue',
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(
    int step,
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color accentColor,
  ) {
    switch (step) {
      case 0:
        return _buildGoalStep(isDark, textPrimary, textMuted, accentColor);
      case 1:
        return _buildRateStep(isDark, textPrimary, textMuted, accentColor);
      case 2:
        return _buildDietTypeStep(isDark, textPrimary, textMuted, accentColor);
      case 3:
        return _buildAllergiesStep(isDark, textPrimary, textMuted, accentColor);
      case 4:
        return _buildMealPatternStep(isDark, textPrimary, textMuted, accentColor);
      case 5:
        return _buildSummaryStep(isDark, textPrimary, textMuted, accentColor);
      default:
        return const SizedBox.shrink();
    }
  }

  // Step 0: Nutrition Goal
  Widget _buildGoalStep(
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color accentColor,
  ) {
    return Column(
      key: const ValueKey('goal'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          'What\'s your nutrition goal?',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'We\'ll personalize your targets based on your goal',
          style: TextStyle(fontSize: 16, color: textMuted),
        ),
        const SizedBox(height: 32),
        ...NutritionGoal.values.map((goal) => _buildGoalOption(
              goal: goal,
              isSelected: _selectedGoal == goal,
              isDark: isDark,
              textPrimary: textPrimary,
              accentColor: accentColor,
            )),
      ],
    );
  }

  Widget _buildGoalOption({
    required NutritionGoal goal,
    required bool isSelected,
    required bool isDark,
    required Color textPrimary,
    required Color accentColor,
  }) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    String description;
    IconData icon;
    switch (goal) {
      case NutritionGoal.loseFat:
        description = 'Lose body fat while preserving muscle';
        icon = Icons.trending_down;
      case NutritionGoal.buildMuscle:
        description = 'Build muscle with a slight calorie surplus';
        icon = Icons.fitness_center;
      case NutritionGoal.maintain:
        description = 'Maintain your current weight';
        icon = Icons.balance;
      case NutritionGoal.improveEnergy:
        description = 'Optimize nutrition for better energy levels';
        icon = Icons.bolt;
      case NutritionGoal.eatHealthier:
        description = 'Focus on whole foods and nutrient density';
        icon = Icons.eco;
      case NutritionGoal.recomposition:
        description = 'Lose fat and build muscle simultaneously';
        icon = Icons.swap_vert;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          HapticService.light();
          setState(() => _selectedGoal = goal);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: elevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? accentColor : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? accentColor.withValues(alpha: 0.15)
                      : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isSelected ? accentColor : textPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.displayName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: accentColor, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  // Step 1: Rate of Change (only for weight-related goals)
  Widget _buildRateStep(
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color accentColor,
  ) {
    final showRateStep = _selectedGoal == NutritionGoal.loseFat ||
        _selectedGoal == NutritionGoal.buildMuscle;

    if (!showRateStep) {
      // Auto-skip to next step if not applicable
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_currentStep == 1) {
          setState(() => _currentStep = 2);
        }
      });
      return const SizedBox.shrink();
    }

    final isLosing = _selectedGoal == NutritionGoal.loseFat;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Column(
      key: const ValueKey('rate'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          'How quickly do you want to ${isLosing ? 'lose weight' : 'gain muscle'}?',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isLosing
              ? 'Slower rates are more sustainable and preserve muscle'
              : 'Slower rates minimize fat gain',
          style: TextStyle(fontSize: 16, color: textMuted),
        ),
        const SizedBox(height: 32),
        ...RateOfChange.values.map((rate) {
          final isSelected = _selectedRate == rate;
          String description;
          if (isLosing) {
            description = '~${rate.kgPerWeek} kg/week (${(rate.kgPerWeek * 2.2).toStringAsFixed(1)} lbs)';
          } else {
            description = '~${(rate.kgPerWeek / 2).toStringAsFixed(2)} kg/week (slower = leaner gains)';
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () {
                HapticService.light();
                setState(() => _selectedRate = rate);
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: elevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? accentColor : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                rate.displayName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                              ),
                              if (rate == RateOfChange.moderate)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: accentColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Recommended',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: accentColor,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: TextStyle(fontSize: 14, color: textMuted),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle, color: accentColor, size: 24),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // Step 2: Diet Type
  Widget _buildDietTypeStep(
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color accentColor,
  ) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Column(
      key: const ValueKey('diet'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          'Do you follow a specific diet?',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This affects your macro distribution',
          style: TextStyle(fontSize: 16, color: textMuted),
        ),
        const SizedBox(height: 32),
        ...DietType.values.map((diet) {
          final isSelected = _selectedDietType == diet;
          String macroInfo = diet == DietType.custom
              ? 'Set your own ratios'
              : 'C: ${diet.carbPercent}% | P: ${diet.proteinPercent}% | F: ${diet.fatPercent}%';

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () {
                HapticService.light();
                setState(() => _selectedDietType = diet);
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: elevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? accentColor : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            diet.displayName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            macroInfo,
                            style: TextStyle(fontSize: 13, color: textMuted),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle, color: accentColor, size: 24),
                  ],
                ),
              ),
            ),
          );
        }),

        // Custom macro sliders if custom diet selected
        if (_selectedDietType == DietType.custom) ...[
          const SizedBox(height: 24),
          _buildCustomMacroSliders(isDark, textPrimary, textMuted, accentColor),
        ],
      ],
    );
  }

  Widget _buildCustomMacroSliders(
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color accentColor,
  ) {
    final total = _customCarbPercent + _customProteinPercent + _customFatPercent;
    final isValid = total == 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Custom Macros',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isValid ? AppColors.success.withValues(alpha: 0.15) : AppColors.coral.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Total: $total%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isValid ? AppColors.success : AppColors.coral,
                ),
              ),
            ),
          ],
        ),
        if (!isValid)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Macros must add up to 100%',
              style: TextStyle(fontSize: 12, color: AppColors.coral),
            ),
          ),
        const SizedBox(height: 16),
        _buildMacroSlider('Carbs', _customCarbPercent, AppColors.cyan, (v) {
          setState(() => _customCarbPercent = v);
        }),
        _buildMacroSlider('Protein', _customProteinPercent, AppColors.green, (v) {
          setState(() => _customProteinPercent = v);
        }),
        _buildMacroSlider('Fat', _customFatPercent, AppColors.orange, (v) {
          setState(() => _customFatPercent = v);
        }),
      ],
    );
  }

  Widget _buildMacroSlider(
    String label,
    int value,
    Color color,
    ValueChanged<int> onChanged,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 14)),
            Text('$value%', style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: 5,
          max: 70,
          divisions: 13,
          activeColor: color,
          inactiveColor: color.withValues(alpha: 0.2),
          onChanged: (v) => onChanged(v.round()),
        ),
      ],
    );
  }

  // Step 3: Allergies & Restrictions
  Widget _buildAllergiesStep(
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color accentColor,
  ) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Column(
      key: const ValueKey('allergies'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          'Any food allergies?',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select all that apply (or skip if none)',
          style: TextStyle(fontSize: 16, color: textMuted),
        ),
        const SizedBox(height: 24),

        // Allergens
        Text(
          'Allergens (FDA Big 9)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textMuted,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: FoodAllergen.values.map((allergen) {
            final isSelected = _selectedAllergies.contains(allergen);
            return FilterChip(
              label: Text(allergen.displayName),
              selected: isSelected,
              onSelected: (selected) {
                HapticService.light();
                setState(() {
                  if (selected) {
                    _selectedAllergies.add(allergen);
                  } else {
                    _selectedAllergies.remove(allergen);
                  }
                });
              },
              selectedColor: accentColor.withValues(alpha: 0.2),
              checkmarkColor: accentColor,
              backgroundColor: elevated,
              labelStyle: TextStyle(
                color: isSelected ? accentColor : textPrimary,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? accentColor : Colors.transparent,
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 24),

        // Dietary restrictions
        Text(
          'Dietary Restrictions',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textMuted,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: DietaryRestriction.values.map((restriction) {
            final isSelected = _selectedRestrictions.contains(restriction);
            return FilterChip(
              label: Text(restriction.displayName),
              selected: isSelected,
              onSelected: (selected) {
                HapticService.light();
                setState(() {
                  if (selected) {
                    _selectedRestrictions.add(restriction);
                  } else {
                    _selectedRestrictions.remove(restriction);
                  }
                });
              },
              selectedColor: accentColor.withValues(alpha: 0.2),
              checkmarkColor: accentColor,
              backgroundColor: elevated,
              labelStyle: TextStyle(
                color: isSelected ? accentColor : textPrimary,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? accentColor : Colors.transparent,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Step 4: Meal Pattern
  Widget _buildMealPatternStep(
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color accentColor,
  ) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Column(
      key: const ValueKey('meal_pattern'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          'How do you prefer to eat?',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This helps us structure your meal suggestions',
          style: TextStyle(fontSize: 16, color: textMuted),
        ),
        const SizedBox(height: 32),
        ...MealPattern.values.map((pattern) {
          final isSelected = _selectedMealPattern == pattern;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () {
                HapticService.light();
                setState(() => _selectedMealPattern = pattern);
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: elevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? accentColor : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        pattern.displayName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle, color: accentColor, size: 24),
                  ],
                ),
              ),
            ),
          );
        }),

        // Lifestyle preferences
        const SizedBox(height: 32),
        Text(
          'Lifestyle',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 16),

        // Cooking skill
        Text('Cooking Skill', style: TextStyle(color: textMuted, fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          children: CookingSkill.values.map((skill) {
            final isSelected = _selectedCookingSkill == skill;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                    right: skill != CookingSkill.advanced ? 8 : 0),
                child: InkWell(
                  onTap: () {
                    HapticService.light();
                    setState(() => _selectedCookingSkill = skill);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accentColor.withValues(alpha: 0.15)
                          : elevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? accentColor : Colors.transparent,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        skill.displayName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? accentColor : textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        // Budget
        Text('Budget', style: TextStyle(color: textMuted, fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          children: BudgetLevel.values.map((budget) {
            final isSelected = _selectedBudgetLevel == budget;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                    right: budget != BudgetLevel.noConstraints ? 8 : 0),
                child: InkWell(
                  onTap: () {
                    HapticService.light();
                    setState(() => _selectedBudgetLevel = budget);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accentColor.withValues(alpha: 0.15)
                          : elevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? accentColor : Colors.transparent,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        budget.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? accentColor : textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Step 5: Summary with calculated targets
  Widget _buildSummaryStep(
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color accentColor,
  ) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return FutureBuilder<NutritionPreferences?>(
      future: _calculateTargets(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: accentColor),
          );
        }

        final targets = snapshot.data;
        if (targets == null) {
          return Center(
            child: Text('Could not calculate targets', style: TextStyle(color: textMuted)),
          );
        }

        return Column(
          key: const ValueKey('summary'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              'Your Personalized Plan',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Based on your profile and goals',
              style: TextStyle(fontSize: 16, color: textMuted),
            ),
            const SizedBox(height: 32),

            // Daily Calories
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accentColor.withValues(alpha: 0.2),
                    accentColor.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    'Daily Calorie Target',
                    style: TextStyle(
                      fontSize: 14,
                      color: textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${targets.targetCalories ?? 2000}',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                  Text(
                    'calories',
                    style: TextStyle(
                      fontSize: 16,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Macros
            Row(
              children: [
                _buildMacroCard(
                  'Protein',
                  '${targets.targetProteinG ?? 150}g',
                  AppColors.green,
                  elevated,
                  textPrimary,
                ),
                const SizedBox(width: 12),
                _buildMacroCard(
                  'Carbs',
                  '${targets.targetCarbsG ?? 200}g',
                  AppColors.cyan,
                  elevated,
                  textPrimary,
                ),
                const SizedBox(width: 12),
                _buildMacroCard(
                  'Fat',
                  '${targets.targetFatG ?? 65}g',
                  AppColors.orange,
                  elevated,
                  textPrimary,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // BMR & TDEE info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: elevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('BMR', style: TextStyle(color: textMuted)),
                      Text('${targets.calculatedBmr ?? 0} cal',
                          style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('TDEE', style: TextStyle(color: textMuted)),
                      Text('${targets.calculatedTdee ?? 0} cal',
                          style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Goal', style: TextStyle(color: textMuted)),
                      Text(_selectedGoal.displayName,
                          style: TextStyle(color: accentColor, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.cyan, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your targets will adapt weekly based on your progress.',
                      style: TextStyle(fontSize: 13, color: textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMacroCard(
    String label,
    String value,
    Color color,
    Color bgColor,
    Color textColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: textColor.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<NutritionPreferences?> _calculateTargets() async {
    if (_calculatedTargets != null) return _calculatedTargets;

    try {
      final user = await ref.read(authRepositoryProvider).getCurrentUser();
      if (user == null) return null;

      // Extract user data from User model
      final weightKg = user.weightKg ?? 70.0;
      final heightCm = user.heightCm ?? 170.0;
      final age = user.age ?? 30;
      final gender = user.gender ?? 'male';
      final activityLevel = user.activityLevel ?? 'moderately_active';

      _calculatedTargets = NutritionCalculator.calculateTargets(
        userId: user.id,
        weightKg: weightKg,
        heightCm: heightCm,
        age: age,
        gender: gender,
        activityLevel: activityLevel,
        goal: _selectedGoal,
        rate: _selectedRate,
        dietType: _selectedDietType,
        customCarbPercent: _selectedDietType == DietType.custom ? _customCarbPercent : null,
        customProteinPercent: _selectedDietType == DietType.custom ? _customProteinPercent : null,
        customFatPercent: _selectedDietType == DietType.custom ? _customFatPercent : null,
      );

      return _calculatedTargets;
    } catch (e) {
      debugPrint('Error calculating targets: $e');
      return null;
    }
  }

  void _previousStep() {
    HapticService.light();

    // Handle skipping rate step when going back
    if (_currentStep == 2) {
      final showRateStep = _selectedGoal == NutritionGoal.loseFat ||
          _selectedGoal == NutritionGoal.buildMuscle;
      if (!showRateStep) {
        setState(() => _currentStep = 0);
        return;
      }
    }

    setState(() {
      _currentStep--;
      _calculatedTargets = null; // Reset cached targets
    });
  }

  void _nextStep() async {
    HapticService.medium();

    // Handle skipping rate step
    if (_currentStep == 0) {
      final showRateStep = _selectedGoal == NutritionGoal.loseFat ||
          _selectedGoal == NutritionGoal.buildMuscle;
      if (!showRateStep) {
        setState(() => _currentStep = 2);
        return;
      }
    }

    // Validate custom macros if applicable
    if (_currentStep == 2 && _selectedDietType == DietType.custom) {
      final total = _customCarbPercent + _customProteinPercent + _customFatPercent;
      if (total != 100) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Macros must add up to 100%'),
            backgroundColor: AppColors.coral,
          ),
        );
        return;
      }
    }

    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
        _calculatedTargets = null;
      });
    } else {
      await _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    setState(() => _isSubmitting = true);

    try {
      final user = await ref.read(authRepositoryProvider).getCurrentUser();
      if (user == null) throw Exception('Not authenticated');

      await ref.read(nutritionPreferencesProvider.notifier).completeOnboarding(
        userId: user.id,
        goal: _selectedGoal,
        rateOfChange: (_selectedGoal == NutritionGoal.loseFat ||
                _selectedGoal == NutritionGoal.buildMuscle)
            ? _selectedRate
            : null,
        dietType: _selectedDietType,
        allergies: _selectedAllergies,
        restrictions: _selectedRestrictions,
        mealPattern: _selectedMealPattern,
        cookingSkill: _selectedCookingSkill,
        cookingTimeMinutes: _cookingTimeMinutes,
        budgetLevel: _selectedBudgetLevel,
        customCarbPercent: _selectedDietType == DietType.custom ? _customCarbPercent : null,
        customProteinPercent: _selectedDietType == DietType.custom ? _customProteinPercent : null,
        customFatPercent: _selectedDietType == DietType.custom ? _customFatPercent : null,
      );

      if (!mounted) return;

      HapticService.heavy();

      // Navigate back or to nutrition screen
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save preferences: $e'),
          backgroundColor: AppColors.coral,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
