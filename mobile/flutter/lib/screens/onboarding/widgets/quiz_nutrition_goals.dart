import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

/// Nutrition goals and dietary restrictions for the pre-auth quiz.
/// Collects both nutrition goals and any dietary restrictions.
class QuizNutritionGoals extends StatelessWidget {
  final Set<String> selectedGoals;
  final Set<String>? selectedRestrictions;
  final ValueChanged<String> onToggle;
  final ValueChanged<String>? onRestrictionToggle;

  const QuizNutritionGoals({
    super.key,
    required this.selectedGoals,
    this.selectedRestrictions,
    required this.onToggle,
    this.onRestrictionToggle,
  });

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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
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
                final isSelected = selectedGoals.contains(id);
                final color = goal['color'] as Color;

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onToggle(id);
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
            if (onRestrictionToggle != null) ...[
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
                  final isSelected = selectedRestrictions?.contains(id) ?? false;

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onRestrictionToggle!(id);
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
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
