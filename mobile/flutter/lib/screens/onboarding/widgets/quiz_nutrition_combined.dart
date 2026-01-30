import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

/// Combined nutrition goals and fasting widget for Screen 11
///
/// Shows:
/// - Nutrition goals (always visible)
/// - Dietary restrictions (always visible, empty array if none)
/// - Meals per day slider (always visible)
/// - Advanced section (collapsed): Fasting interest, protocol, wake/sleep times
class QuizNutritionCombined extends StatefulWidget {
  final Set<String> selectedGoals;
  final Set<String> selectedRestrictions;
  final int? mealsPerDay;
  final bool? interestedInFasting;
  final String? selectedProtocol;
  final TimeOfDay wakeTime;
  final TimeOfDay sleepTime;
  final Function(String) onGoalToggle;
  final Function(String) onRestrictionToggle;
  final ValueChanged<int> onMealsChanged;
  final ValueChanged<bool> onFastingInterestChanged;
  final ValueChanged<String> onProtocolChanged;
  final ValueChanged<TimeOfDay> onWakeTimeChanged;
  final ValueChanged<TimeOfDay> onSleepTimeChanged;

  const QuizNutritionCombined({
    super.key,
    required this.selectedGoals,
    required this.selectedRestrictions,
    this.mealsPerDay,
    this.interestedInFasting,
    this.selectedProtocol,
    required this.wakeTime,
    required this.sleepTime,
    required this.onGoalToggle,
    required this.onRestrictionToggle,
    required this.onMealsChanged,
    required this.onFastingInterestChanged,
    required this.onProtocolChanged,
    required this.onWakeTimeChanged,
    required this.onSleepTimeChanged,
  });

  @override
  State<QuizNutritionCombined> createState() => _QuizNutritionCombinedState();
}

class _QuizNutritionCombinedState extends State<QuizNutritionCombined> {
  bool _showAdvanced = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final textSecondary = isDark ? const Color(0xFFD4D4D8) : const Color(0xFF52525B);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'Nutrition Preferences',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 6),
          Text(
            'Help us personalize your nutrition guidance',
            style: TextStyle(
              fontSize: 15,
              color: textSecondary,
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 24),

          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Section: Nutrition Goals
                Text(
                  'What are your nutrition goals?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildGoalsGrid(isDark, textPrimary),
                const SizedBox(height: 24),

                // Section: Dietary Restrictions
                Text(
                  'Any dietary restrictions?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select all that apply (or none)',
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildRestrictionsGrid(isDark, textPrimary),
                const SizedBox(height: 24),

                // Section: Meals Per Day
                Text(
                  'How many meals per day?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildMealsSlider(isDark, textPrimary, textSecondary),
                const SizedBox(height: 24),

                // Advanced Section Toggle
                _buildAdvancedToggle(isDark, textPrimary),
                if (_showAdvanced) ...[
                  const SizedBox(height: 16),
                  _buildFastingSection(isDark, textPrimary, textSecondary),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsGrid(bool isDark, Color textPrimary) {
    final goals = [
      {'id': 'lose_fat', 'label': 'Lose Fat', 'icon': Icons.trending_down},
      {'id': 'build_muscle', 'label': 'Build Muscle', 'icon': Icons.fitness_center},
      {'id': 'maintain', 'label': 'Maintain', 'icon': Icons.balance},
      {'id': 'improve_energy', 'label': 'More Energy', 'icon': Icons.bolt},
      {'id': 'eat_healthier', 'label': 'Eat Healthier', 'icon': Icons.spa},
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: goals.map((goal) {
        final isSelected = widget.selectedGoals.contains(goal['id']);
        return _buildChip(
          label: goal['label'] as String,
          icon: goal['icon'] as IconData,
          isSelected: isSelected,
          onTap: () {
            HapticFeedback.selectionClick();
            widget.onGoalToggle(goal['id'] as String);
          },
          isDark: isDark,
          textPrimary: textPrimary,
        );
      }).toList(),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildRestrictionsGrid(bool isDark, Color textPrimary) {
    final restrictions = [
      {'id': 'none', 'label': 'None'},
      {'id': 'vegetarian', 'label': 'Vegetarian'},
      {'id': 'vegan', 'label': 'Vegan'},
      {'id': 'gluten_free', 'label': 'Gluten-Free'},
      {'id': 'dairy_free', 'label': 'Dairy-Free'},
      {'id': 'nut_allergy', 'label': 'Nut Allergy'},
      {'id': 'keto', 'label': 'Keto'},
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: restrictions.map((restriction) {
        final isSelected = widget.selectedRestrictions.contains(restriction['id']);
        return _buildChip(
          label: restriction['label'] as String,
          isSelected: isSelected,
          onTap: () {
            HapticFeedback.selectionClick();
            widget.onRestrictionToggle(restriction['id'] as String);
          },
          isDark: isDark,
          textPrimary: textPrimary,
        );
      }).toList(),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildChip({
    required String label,
    IconData? icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    required Color textPrimary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.orange
              : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? AppColors.orange
                : (isDark ? AppColors.glassBorder : AppColorsLight.cardBorder),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : AppColors.orange,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealsSlider(bool isDark, Color textPrimary, Color textSecondary) {
    final currentMeals = widget.mealsPerDay ?? 3;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.glassSurface : AppColorsLight.glassSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.glassBorder : AppColorsLight.cardBorder,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Meals',
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                ),
              ),
              Text(
                '$currentMeals per day',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.orange,
              inactiveTrackColor: isDark
                  ? AppColors.glassBorder
                  : AppColorsLight.cardBorder,
              thumbColor: AppColors.orange,
              overlayColor: AppColors.orange.withValues(alpha: 0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: currentMeals.toDouble(),
              min: 1,
              max: 6,
              divisions: 5,
              onChanged: (value) {
                HapticFeedback.selectionClick();
                widget.onMealsChanged(value.round());
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1', style: TextStyle(fontSize: 12, color: textSecondary)),
              Text('2', style: TextStyle(fontSize: 12, color: textSecondary)),
              Text('3', style: TextStyle(fontSize: 12, color: textSecondary)),
              Text('4', style: TextStyle(fontSize: 12, color: textSecondary)),
              Text('5', style: TextStyle(fontSize: 12, color: textSecondary)),
              Text('6', style: TextStyle(fontSize: 12, color: textSecondary)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms);
  }

  Widget _buildAdvancedToggle(bool isDark, Color textPrimary) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _showAdvanced = !_showAdvanced);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.glassSurface.withValues(alpha: 0.5)
              : AppColorsLight.glassSurface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.glassBorder : AppColorsLight.cardBorder,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.restaurant,
              color: AppColors.orange,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Intermittent Fasting (Optional)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ),
            Icon(
              _showAdvanced ? Icons.expand_less : Icons.expand_more,
              color: textPrimary,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 600.ms);
  }

  Widget _buildFastingSection(bool isDark, Color textPrimary, Color textSecondary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Interested in intermittent fasting?',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildFastingToggle('Yes', true, isDark, textPrimary),
            const SizedBox(width: 12),
            _buildFastingToggle('No', false, isDark, textPrimary),
          ],
        ),
        if (widget.interestedInFasting == true) ...[
          const SizedBox(height: 16),
          Text(
            'Fasting Protocol',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildProtocolSelector(isDark, textPrimary, textSecondary),
        ],
      ],
    ).animate().fadeIn().slideY(begin: -0.05);
  }

  Widget _buildFastingToggle(String label, bool value, bool isDark, Color textPrimary) {
    final isSelected = widget.interestedInFasting == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onFastingInterestChanged(value);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.orange
                : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.orange
                  : (isDark ? AppColors.glassBorder : AppColorsLight.cardBorder),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProtocolSelector(bool isDark, Color textPrimary, Color textSecondary) {
    final protocols = [
      {'id': '16:8', 'label': '16:8', 'description': '16h fast, 8h eating'},
      {'id': '18:6', 'label': '18:6', 'description': '18h fast, 6h eating'},
      {'id': '14:10', 'label': '14:10', 'description': '14h fast, 10h eating'},
      {'id': '20:4', 'label': '20:4', 'description': '20h fast, 4h eating'},
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: protocols.map((protocol) {
        final isSelected = widget.selectedProtocol == protocol['id'];
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            widget.onProtocolChanged(protocol['id'] as String);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.orange
                  : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppColors.orange
                    : (isDark ? AppColors.glassBorder : AppColorsLight.cardBorder),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  protocol['label'] as String,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  protocol['description'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.9)
                        : textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
