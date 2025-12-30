import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/nutrition_preferences.dart';
import '../../../data/providers/nutrition_preferences_provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/haptic_service.dart';

/// Onboarding screen for nutrition preferences
class NutritionOnboardingScreen extends ConsumerStatefulWidget {
  final VoidCallback? onComplete;
  final VoidCallback? onSkip;

  const NutritionOnboardingScreen({
    super.key,
    this.onComplete,
    this.onSkip,
  });

  @override
  ConsumerState<NutritionOnboardingScreen> createState() =>
      _NutritionOnboardingScreenState();
}

class _NutritionOnboardingScreenState
    extends ConsumerState<NutritionOnboardingScreen> {
  int _currentStep = 0;
  bool _isSubmitting = false;

  // User selections
  final Set<NutritionGoal> _selectedGoals = {NutritionGoal.maintain}; // Multi-select
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

  // Custom diet description (for part-time veg, flexitarian, custom)
  final TextEditingController _customDietController = TextEditingController();

  // Custom meal pattern description (for religious/custom)
  final TextEditingController _customMealPatternController = TextEditingController();

  // Calculated targets for preview
  NutritionPreferences? _calculatedTargets;

  static const int _totalSteps = 6;

  @override
  void dispose() {
    _customDietController.dispose();
    _customMealPatternController.dispose();
    super.dispose();
  }

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
            // Header with progress and skip button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
              child: Row(
                children: [
                  // Progress indicator
                  Expanded(
                    child: Row(
                      children: List.generate(_totalSteps, (index) {
                        return Expanded(
                          child: Container(
                            height: 4,
                            margin: EdgeInsets.only(
                                right: index < _totalSteps - 1 ? 8 : 0),
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
                  // Skip button
                  TextButton(
                    onPressed: _handleSkip,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: textMuted,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
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

  // Step 0: Nutrition Goal (Multi-select tiles)
  Widget _buildGoalStep(
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color accentColor,
  ) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final goals = NutritionGoal.values.toList();

    return Column(
      key: const ValueKey('goal'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          'What are your nutrition goals?',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select all that apply',
          style: TextStyle(fontSize: 16, color: textMuted),
        ),
        const SizedBox(height: 24),

        // Grid of goal tiles (2 columns)
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.15,
          ),
          itemCount: goals.length,
          itemBuilder: (context, index) {
            final goal = goals[index];
            final isSelected = _selectedGoals.contains(goal);

            return _buildGoalTile(
              goal: goal,
              isSelected: isSelected,
              elevated: elevated,
              textPrimary: textPrimary,
              textMuted: textMuted,
              accentColor: accentColor,
            );
          },
        ),

        // Selection hint
        if (_selectedGoals.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: accentColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedGoals.length == 1
                        ? 'Your primary goal: ${_selectedGoals.first.displayName}'
                        : '${_selectedGoals.length} goals selected. Primary: ${_selectedGoals.first.displayName}',
                    style: TextStyle(fontSize: 12, color: textPrimary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGoalTile({
    required NutritionGoal goal,
    required bool isSelected,
    required Color elevated,
    required Color textPrimary,
    required Color textMuted,
    required Color accentColor,
  }) {
    // Icons and descriptions for each goal
    IconData icon;
    String subtitle;
    switch (goal) {
      case NutritionGoal.loseFat:
        icon = Icons.trending_down;
        subtitle = 'Cut body fat';
      case NutritionGoal.buildMuscle:
        icon = Icons.fitness_center;
        subtitle = 'Gain muscle mass';
      case NutritionGoal.maintain:
        icon = Icons.balance;
        subtitle = 'Stay where you are';
      case NutritionGoal.improveEnergy:
        icon = Icons.bolt;
        subtitle = 'Feel more energized';
      case NutritionGoal.eatHealthier:
        icon = Icons.eco;
        subtitle = 'Whole foods focus';
      case NutritionGoal.recomposition:
        icon = Icons.swap_vert;
        subtitle = 'Lose fat, gain muscle';
    }

    return InkWell(
      onTap: () {
        HapticService.light();
        setState(() {
          if (isSelected) {
            // Don't allow deselecting the last goal
            if (_selectedGoals.length > 1) {
              _selectedGoals.remove(goal);
            }
          } else {
            _selectedGoals.add(goal);
          }
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withValues(alpha: 0.1) : elevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accentColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with selection indicator
            Stack(
              alignment: Alignment.topRight,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accentColor.withValues(alpha: 0.2)
                        : textMuted.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? accentColor : textMuted,
                    size: 24,
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Goal name
            Text(
              goal.displayName,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? accentColor : textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            // Subtitle
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: textMuted,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Helper to get primary goal (first selected goal)
  NutritionGoal get _primaryGoal => _selectedGoals.first;

  // Check if any weight-related goal is selected
  bool get _hasWeightGoal =>
      _selectedGoals.contains(NutritionGoal.loseFat) ||
      _selectedGoals.contains(NutritionGoal.buildMuscle);

  // Step 1: Rate of Change (only for weight-related goals)
  Widget _buildRateStep(
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color accentColor,
  ) {
    if (!_hasWeightGoal) {
      // Auto-skip to next step if not applicable
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_currentStep == 1) {
          setState(() => _currentStep = 2);
        }
      });
      return const SizedBox.shrink();
    }

    final isLosing = _selectedGoals.contains(NutritionGoal.loseFat);
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

  // Step 2: Diet Type - Compact Grid layout (3 columns)
  Widget _buildDietTypeStep(
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color accentColor,
  ) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final dietTypes = DietType.values.toList();

    return Column(
      key: const ValueKey('diet'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Do you follow a specific diet?',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'This affects your macro distribution',
          style: TextStyle(fontSize: 14, color: textMuted),
        ),
        const SizedBox(height: 16),

        // Grid of diet type tiles (3 columns, more compact)
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.85,
          ),
          itemCount: dietTypes.length,
          itemBuilder: (context, index) {
            final diet = dietTypes[index];
            final isSelected = _selectedDietType == diet;

            return _buildDietTile(
              diet: diet,
              isSelected: isSelected,
              elevated: elevated,
              textPrimary: textPrimary,
              textMuted: textMuted,
              accentColor: accentColor,
            );
          },
        ),

        // Description input for flexible diets (part-time veg, flexitarian)
        if (_selectedDietType == DietType.partTimeVeg ||
            _selectedDietType == DietType.flexitarian) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: elevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accentColor.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedDietType == DietType.partTimeVeg
                      ? 'Which days are you vegetarian?'
                      : 'Describe your eating pattern',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedDietType == DietType.partTimeVeg
                      ? 'e.g., "Tuesdays & Thursdays" or "Weekdays only"'
                      : 'e.g., "Meat only on weekends" or "Fish but no red meat"',
                  style: TextStyle(
                    fontSize: 12,
                    color: textMuted,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _customDietController,
                  style: TextStyle(color: textPrimary),
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Describe your pattern...',
                    hintStyle: TextStyle(color: textMuted),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Custom macro sliders if custom diet selected
        if (_selectedDietType == DietType.custom) ...[
          const SizedBox(height: 24),
          _buildCustomMacroSliders(isDark, textPrimary, textMuted, accentColor),
        ],
      ],
    );
  }

  // Get diet info for the info dialog
  Map<String, String> _getDietInfo(DietType diet) {
    switch (diet) {
      case DietType.noDiet:
        return {
          'title': 'I Eat Everything',
          'description': 'No dietary restrictions. You eat all types of food including meat, fish, dairy, eggs, and plant-based foods.',
        };
      case DietType.balanced:
        return {
          'title': 'Balanced Diet',
          'description': 'A moderate approach with ~45% carbs, 25% protein, 30% fat. Good for general health and sustainable long-term.',
        };
      case DietType.lowCarb:
        return {
          'title': 'Low Carb',
          'description': 'Reduced carbohydrate intake (~25% carbs). Often used for weight loss. Focuses on protein and healthy fats.',
        };
      case DietType.keto:
        return {
          'title': 'Ketogenic (Keto)',
          'description': 'Very low carb (~5%), high fat diet that puts your body into ketosis. Requires strict carb restriction.',
        };
      case DietType.highProtein:
        return {
          'title': 'High Protein',
          'description': 'Emphasizes protein (~40%) for muscle building and satiety. Popular with athletes and bodybuilders.',
        };
      case DietType.mediterranean:
        return {
          'title': 'Mediterranean',
          'description': 'Based on traditional foods from Mediterranean countries. Rich in olive oil, fish, vegetables, and whole grains. Great for heart health.',
        };
      case DietType.vegan:
        return {
          'title': 'Vegan',
          'description': 'No animal products at all. Excludes meat, fish, dairy, eggs, honey, and any animal-derived ingredients.',
        };
      case DietType.vegetarian:
        return {
          'title': 'Vegetarian',
          'description': 'No meat or fish, but includes dairy and eggs. A common plant-based diet that allows animal by-products.',
        };
      case DietType.lactoOvo:
        return {
          'title': 'Lacto-Ovo Vegetarian',
          'description': 'Includes dairy (lacto) and eggs (ovo), but no meat or fish. The most common type of vegetarian diet.',
        };
      case DietType.pescatarian:
        return {
          'title': 'Pescatarian',
          'description': 'Vegetarian diet that includes fish and seafood. No meat from land animals. Good for omega-3 intake.',
        };
      case DietType.flexitarian:
        return {
          'title': 'Flexitarian',
          'description': 'Mostly plant-based but occasionally includes meat or fish. Flexible approach to reduce meat consumption without strict rules.',
        };
      case DietType.partTimeVeg:
        return {
          'title': 'Part-Time Vegetarian',
          'description': 'Vegetarian on specific days (e.g., Tuesdays, Thursdays, weekdays). Common in Indian culture and for religious observances.',
        };
      case DietType.custom:
        return {
          'title': 'Custom Diet',
          'description': 'Set your own macro percentages for carbs, protein, and fat. For those with specific requirements.',
        };
    }
  }

  void _showDietInfoDialog(BuildContext context, DietType diet) {
    final info = _getDietInfo(diet);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          info['title']!,
          style: TextStyle(
            color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          info['description']!,
          style: TextStyle(
            color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it',
              style: TextStyle(
                color: isDark ? AppColors.green : AppColorsLight.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDietTile({
    required DietType diet,
    required bool isSelected,
    required Color elevated,
    required Color textPrimary,
    required Color textMuted,
    required Color accentColor,
  }) {
    // Icons for each diet type (no subtitles in compact mode)
    IconData icon;
    switch (diet) {
      case DietType.noDiet:
        icon = Icons.check_circle_outline;
      case DietType.balanced:
        icon = Icons.balance;
      case DietType.lowCarb:
        icon = Icons.no_food;
      case DietType.keto:
        icon = Icons.local_fire_department;
      case DietType.highProtein:
        icon = Icons.fitness_center;
      case DietType.mediterranean:
        icon = Icons.restaurant;
      case DietType.vegan:
        icon = Icons.grass;
      case DietType.vegetarian:
        icon = Icons.eco;
      case DietType.lactoOvo:
        icon = Icons.egg_alt;
      case DietType.pescatarian:
        icon = Icons.set_meal;
      case DietType.flexitarian:
        icon = Icons.swap_horiz;
      case DietType.partTimeVeg:
        icon = Icons.calendar_today;
      case DietType.custom:
        icon = Icons.tune;
    }

    return Stack(
      children: [
        InkWell(
          onTap: () {
            HapticService.light();
            setState(() => _selectedDietType = diet);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? accentColor.withValues(alpha: 0.1) : elevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? accentColor : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon with selection indicator
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? accentColor.withValues(alpha: 0.2)
                            : textMuted.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: isSelected ? accentColor : textMuted,
                        size: 18,
                      ),
                    ),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 8,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                // Diet name only (no subtitle for compact mode)
                Text(
                  diet.displayName,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? accentColor : textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
        // Info button in top-right corner (smaller)
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: () => _showDietInfoDialog(context, diet),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: textMuted.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.info_outline,
                size: 12,
                color: textMuted,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMealPatternTile({
    required MealPattern pattern,
    required bool isSelected,
    required Color elevated,
    required Color textPrimary,
    required Color textMuted,
    required Color accentColor,
  }) {
    // Icons for each meal pattern
    IconData icon;
    String subtitle;
    switch (pattern) {
      case MealPattern.threeMeals:
        icon = Icons.restaurant_menu;
        subtitle = 'Breakfast, lunch, dinner';
      case MealPattern.threeMealsSnacks:
        icon = Icons.brunch_dining;
        subtitle = 'Meals + snacks';
      case MealPattern.twoMeals:
        icon = Icons.lunch_dining;
        subtitle = 'Skip one meal';
      case MealPattern.omad:
        icon = Icons.dinner_dining;
        subtitle = 'One big meal';
      case MealPattern.if168:
        icon = Icons.schedule;
        subtitle = '8hr eating window';
      case MealPattern.if186:
        icon = Icons.timer;
        subtitle = '6hr eating window';
      case MealPattern.if204:
        icon = Icons.timer_off;
        subtitle = '4hr eating window';
      case MealPattern.smallMeals:
        icon = Icons.grid_view;
        subtitle = 'Graze throughout day';
      case MealPattern.religiousFasting:
        icon = Icons.auto_awesome;
        subtitle = 'Traditional/spiritual';
      case MealPattern.custom:
        icon = Icons.edit_calendar;
        subtitle = 'Your own schedule';
    }

    return InkWell(
      onTap: () {
        HapticService.light();
        setState(() => _selectedMealPattern = pattern);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withValues(alpha: 0.1) : elevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accentColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with selection indicator
            Stack(
              alignment: Alignment.topRight,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accentColor.withValues(alpha: 0.2)
                        : textMuted.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? accentColor : textMuted,
                    size: 22,
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 10,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            // Pattern name
            Text(
              pattern.displayName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? accentColor : textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            // Subtitle
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: textMuted,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
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

  // Step 4: Meal Pattern - Grid layout
  Widget _buildMealPatternStep(
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color accentColor,
  ) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final mealPatterns = MealPattern.values.toList();

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
        const SizedBox(height: 24),

        // Grid of meal pattern tiles (2 columns)
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
          ),
          itemCount: mealPatterns.length,
          itemBuilder: (context, index) {
            final pattern = mealPatterns[index];
            final isSelected = _selectedMealPattern == pattern;

            return _buildMealPatternTile(
              pattern: pattern,
              isSelected: isSelected,
              elevated: elevated,
              textPrimary: textPrimary,
              textMuted: textMuted,
              accentColor: accentColor,
            );
          },
        ),

        // Custom description input for religious/custom patterns
        if (_selectedMealPattern == MealPattern.religiousFasting ||
            _selectedMealPattern == MealPattern.custom) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: elevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accentColor.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedMealPattern == MealPattern.religiousFasting
                      ? 'Describe your fasting practice'
                      : 'Describe your eating schedule',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedMealPattern == MealPattern.religiousFasting
                      ? 'e.g., "I fast on Tuesdays and Thursdays" or "I follow Ramadan fasting"'
                      : 'e.g., "I eat only between 12pm and 6pm" or "I skip breakfast on weekdays"',
                  style: TextStyle(
                    fontSize: 12,
                    color: textMuted,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _customMealPatternController,
                  style: TextStyle(color: textPrimary),
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Describe your eating pattern...',
                    hintStyle: TextStyle(color: textMuted),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
        ],

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
                      Text('Goals', style: TextStyle(color: textMuted)),
                      Flexible(
                        child: Text(
                          _selectedGoals.map((g) => g.displayName).join(', '),
                          style: TextStyle(color: accentColor, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.right,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
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
        goal: _primaryGoal,
        goals: _selectedGoals.toList(),
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

  void _handleSkip() {
    HapticService.light();

    // Use callback if provided, otherwise just pop
    if (widget.onSkip != null) {
      widget.onSkip!();
    } else {
      Navigator.of(context).pop(false);
    }
  }

  void _previousStep() {
    HapticService.light();

    // Handle skipping rate step when going back
    if (_currentStep == 2) {
      if (!_hasWeightGoal) {
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
      if (!_hasWeightGoal) {
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
        goals: _selectedGoals.toList(),
        rateOfChange: _hasWeightGoal ? _selectedRate : null,
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

      // Call onComplete callback if provided, otherwise just pop
      if (widget.onComplete != null) {
        widget.onComplete!();
      } else {
        Navigator.of(context).pop(true);
      }
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
