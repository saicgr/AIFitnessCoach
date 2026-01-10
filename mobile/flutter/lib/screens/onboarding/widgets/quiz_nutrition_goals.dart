import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import 'calorie_macro_estimator.dart';
import 'scroll_hint_arrow.dart';

/// Nutrition goals and dietary restrictions for the pre-auth quiz.
/// Collects both nutrition goals and any dietary restrictions.
/// Shows calculated daily targets preview when user data is available.
class QuizNutritionGoals extends StatefulWidget {
  final Set<String> selectedGoals;
  final Set<String>? selectedRestrictions;
  final ValueChanged<String> onToggle;
  final ValueChanged<String>? onRestrictionToggle;

  // Meals per day selection
  final int? mealsPerDay;
  final ValueChanged<int>? onMealsPerDayChanged;

  // User data for calculating nutrition targets
  final int? age;
  final String? gender;
  final double? heightCm;
  final double? weightKg;
  final String? activityLevel;
  final String? weightDirection;
  final String? weightChangeRate;
  final double? goalWeightKg;
  final int? workoutDaysPerWeek;

  const QuizNutritionGoals({
    super.key,
    required this.selectedGoals,
    this.selectedRestrictions,
    required this.onToggle,
    this.onRestrictionToggle,
    // Meals per day
    this.mealsPerDay,
    this.onMealsPerDayChanged,
    // Optional user data for targets preview
    this.age,
    this.gender,
    this.heightCm,
    this.weightKg,
    this.activityLevel,
    this.weightDirection,
    this.weightChangeRate,
    this.goalWeightKg,
    this.workoutDaysPerWeek,
  });

  @override
  State<QuizNutritionGoals> createState() => _QuizNutritionGoalsState();
}

class _QuizNutritionGoalsState extends State<QuizNutritionGoals> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Check if we have enough data to calculate nutrition estimates
  bool get _canShowTargets =>
      widget.age != null &&
      widget.gender != null &&
      widget.heightCm != null &&
      widget.weightKg != null;

  /// Calculate nutrition estimates using CalorieMacroEstimator
  NutritionEstimate? get _nutritionEstimate {
    if (!_canShowTargets) return null;

    return CalorieMacroEstimator.calculateAll(
      weightKg: widget.weightKg!,
      heightCm: widget.heightCm!,
      age: widget.age!,
      gender: widget.gender!,
      activityLevel: widget.activityLevel,
      weightDirection: widget.weightDirection,
      weightChangeRate: widget.weightChangeRate,
      goalWeightKg: widget.goalWeightKg,
      nutritionGoals: widget.selectedGoals.toList(),
      workoutDaysPerWeek: widget.workoutDaysPerWeek,
    );
  }

  static const List<Map<String, dynamic>> nutritionGoals = [
    {
      'id': 'lose_fat',
      'label': 'Lose Fat',
      'icon': Icons.local_fire_department,
      'color': AppColors.coral,
    },
    {
      'id': 'build_muscle',
      'label': 'Build Muscle',
      'icon': Icons.fitness_center,
      'color': AppColors.purple,
    },
    {
      'id': 'maintain',
      'label': 'Maintain Weight',
      'icon': Icons.balance,
      'color': AppColors.teal,
    },
    {
      'id': 'improve_energy',
      'label': 'Improve Energy',
      'icon': Icons.bolt,
      'color': AppColors.orange,
    },
    {
      'id': 'eat_healthier',
      'label': 'Eat Healthier',
      'icon': Icons.eco,
      'color': AppColors.success,
    },
  ];

  static const List<Map<String, dynamic>> dietaryRestrictions = [
    {'id': 'vegetarian', 'emoji': '🥬', 'label': 'Vegetarian'},
    {'id': 'vegan', 'emoji': '🌱', 'label': 'Vegan'},
    {'id': 'gluten_free', 'emoji': '🍞', 'label': 'Gluten-free'},
    {'id': 'dairy_free', 'emoji': '🥛', 'label': 'Dairy-free'},
    {'id': 'nut_allergy', 'emoji': '🥜', 'label': 'Nut allergy'},
    {'id': 'pescatarian', 'emoji': '🐟', 'label': 'Pescatarian'},
    {'id': 'keto', 'emoji': '🥩', 'label': 'Keto/Low-carb'},
    {'id': 'none', 'emoji': '✨', 'label': 'None'},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final cardBg = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What are your nutrition goals?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                    height: 1.3,
                  ),
                ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.05),
                const SizedBox(height: 8),
                Text(
                  'Select all that apply',
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                  ),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 16),

                // Nutrition goals as Wrap for better small screen support
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: nutritionGoals.asMap().entries.map((entry) {
                    final index = entry.key;
                    final goal = entry.value;
                    final id = goal['id'] as String;
                    final isSelected = widget.selectedGoals.contains(id);
                    final color = goal['color'] as Color;

                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        widget.onToggle(id);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: isSelected ? AppColors.cyanGradient : null,
                          color: isSelected
                              ? null
                              : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppColors.cyan : cardBorder,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              goal['icon'] as IconData,
                              color: isSelected ? Colors.white : color,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              goal['label'] as String,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? Colors.white : textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate(delay: (100 + index * 40).ms).fadeIn().scale(begin: const Offset(0.9, 0.9));
                  }).toList(),
                ),

                // Dietary Restrictions section (only show if callback is provided)
                if (widget.onRestrictionToggle != null) ...[
                  const SizedBox(height: 28),
                  Text(
                    'Any dietary restrictions?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                  const SizedBox(height: 4),
                  Text(
                    'Helps personalize meal suggestions',
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                    ),
                  ).animate().fadeIn(delay: 450.ms),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: dietaryRestrictions.asMap().entries.map((entry) {
                      final index = entry.key;
                      final restriction = entry.value;
                      final id = restriction['id'] as String;
                      final isSelected = widget.selectedRestrictions?.contains(id) ?? false;

                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          widget.onRestrictionToggle!(id);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: isSelected ? AppColors.cyanGradient : null,
                            color: isSelected
                                ? null
                                : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? AppColors.cyan : cardBorder,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                restriction['emoji'] as String,
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                restriction['label'] as String,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? Colors.white : textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate(delay: (500 + index * 40).ms).fadeIn().scale(begin: const Offset(0.9, 0.9));
                    }).toList(),
                  ),
                ],

                // Meals per Day section (only show if callback is provided)
                if (widget.onMealsPerDayChanged != null) ...[
                  const SizedBox(height: 28),
                  Text(
                    'Meals + snacks per day?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ).animate().fadeIn(delay: 550.ms),
                  const SizedBox(height: 4),
                  Text(
                    'Include all meals and snacks',
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                    ),
                  ).animate().fadeIn(delay: 580.ms),
                  const SizedBox(height: 12),
                  Row(
                    children: [1, 2, 3, 4, 5, 6].asMap().entries.map((entry) {
                      final index = entry.key;
                      final mealCount = entry.value;
                      final isSelected = widget.mealsPerDay == mealCount;

                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: index < 5 ? 6 : 0,
                          ),
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              widget.onMealsPerDayChanged!(mealCount);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                gradient: isSelected ? AppColors.cyanGradient : null,
                                color: isSelected
                                    ? null
                                    : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? AppColors.cyan : cardBorder,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '$mealCount',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ).animate(delay: (620 + index * 40).ms).fadeIn().scale(begin: const Offset(0.9, 0.9)),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                // Daily Targets Preview Card (only show if we have user data)
                if (_canShowTargets) ...[
                  const SizedBox(height: 24),
                  _buildTargetsPreviewCard(
                    isDark: isDark,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    cardBg: cardBg,
                    cardBorder: cardBorder,
                  ),
                ],

                const SizedBox(height: 60), // Space for scroll hint
              ],
            ),
          ),
        ),
        ScrollHintArrow(scrollController: _scrollController),
      ],
    );
  }

  Widget _buildTargetsPreviewCard({
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color cardBg,
    required Color cardBorder,
  }) {
    final estimate = _nutritionEstimate;
    if (estimate == null) return const SizedBox.shrink();

    final meals = widget.mealsPerDay ?? 3;
    final calPerMeal = (estimate.calories / meals).round();
    final proteinPerMeal = (estimate.protein / meals).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.cyan.withValues(alpha: 0.1),
            AppColors.purple.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_outlined, color: AppColors.cyan, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your Estimated Daily Targets',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Main macros row
          Row(
            children: [
              _buildMacroItem(
                icon: Icons.local_fire_department,
                value: '${estimate.calories}',
                label: 'kcal',
                color: AppColors.coral,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              _buildMacroItem(
                icon: Icons.fitness_center,
                value: '${estimate.protein}g',
                label: 'protein',
                color: AppColors.purple,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              _buildMacroItem(
                icon: Icons.grain,
                value: '${estimate.carbs}g',
                label: 'carbs',
                color: AppColors.orange,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              _buildMacroItem(
                icon: Icons.water_drop,
                value: '${estimate.fat}g',
                label: 'fat',
                color: AppColors.teal,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
            ],
          ),

          // Per meal breakdown (shows when meals selected)
          if (widget.mealsPerDay != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.cyan.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant, color: AppColors.cyan, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '~$calPerMeal kcal & ${proteinPerMeal}g protein per meal',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.cyan,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Additional insights row
          Row(
            children: [
              Expanded(
                child: _buildInsightChip(
                  icon: Icons.water,
                  text: '${estimate.waterLiters}L water',
                  color: AppColors.electricBlue,
                  textSecondary: textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInsightChip(
                  icon: Icons.psychology,
                  text: 'Metabolic age: ${estimate.metabolicAge}',
                  color: AppColors.purple,
                  textSecondary: textSecondary,
                ),
              ),
            ],
          ),

          // Goal date if applicable
          if (estimate.goalDate != null && estimate.weeksToGoal != null) ...[
            const SizedBox(height: 8),
            _buildInsightChip(
              icon: Icons.flag_outlined,
              text: 'Goal in ~${estimate.weeksToGoal} weeks',
              color: AppColors.success,
              textSecondary: textSecondary,
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1);
  }

  Widget _buildMacroItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightChip({
    required IconData icon,
    required String text,
    required Color color,
    required Color textSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                color: textSecondary,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
