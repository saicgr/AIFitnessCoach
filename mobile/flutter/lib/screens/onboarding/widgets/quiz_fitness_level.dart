import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

/// Combined fitness level, training experience, and activity level question widget.
class QuizFitnessLevel extends StatelessWidget {
  final String? selectedLevel;
  final String? selectedExperience;
  final String? selectedActivityLevel;
  final ValueChanged<String> onLevelChanged;
  final ValueChanged<String> onExperienceChanged;
  final ValueChanged<String>? onActivityLevelChanged;

  const QuizFitnessLevel({
    super.key,
    required this.selectedLevel,
    required this.selectedExperience,
    this.selectedActivityLevel,
    required this.onLevelChanged,
    required this.onExperienceChanged,
    this.onActivityLevelChanged,
  });

  static const _levels = [
    {
      'id': 'beginner',
      'label': 'Beginner',
      'icon': Icons.eco_outlined,
      'color': AppColors.success,
      'description': 'New to fitness or returning after a break',
    },
    {
      'id': 'intermediate',
      'label': 'Intermediate',
      'icon': Icons.trending_up,
      'color': AppColors.warning,
      'description': 'Workout regularly, familiar with exercises',
    },
    {
      'id': 'advanced',
      'label': 'Advanced',
      'icon': Icons.rocket_launch_outlined,
      'color': AppColors.coral,
      'description': 'Experienced athlete, seeking new challenges',
    },
  ];

  static const _experienceOptions = [
    {'id': 'never', 'label': 'Never', 'description': 'Brand new to lifting'},
    {'id': 'less_than_6_months', 'label': '< 6 months', 'description': 'Just getting started'},
    {'id': '6_months_to_2_years', 'label': '6mo - 2yrs', 'description': 'Building consistency'},
    {'id': '2_to_5_years', 'label': '2 - 5 years', 'description': 'Solid foundation'},
    {'id': '5_plus_years', 'label': '5+ years', 'description': 'Veteran lifter'},
  ];

  static const _activityLevelOptions = [
    {'id': 'sedentary', 'emoji': '🪑', 'label': 'Sedentary', 'description': 'Desk job, minimal movement'},
    {'id': 'lightly_active', 'emoji': '🚶', 'label': 'Light', 'description': 'Some walking, light activity'},
    {'id': 'moderately_active', 'emoji': '🏃', 'label': 'Moderate', 'description': 'On feet often, regular activity'},
    {'id': 'very_active', 'emoji': '⚡', 'label': 'Very Active', 'description': 'Physical job, always moving'},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitle(textPrimary),
            const SizedBox(height: 6),
            _buildSubtitle(textSecondary),
            const SizedBox(height: 16),
            ..._buildLevelCards(isDark, textPrimary, textSecondary),
            if (selectedLevel != null) ...[
              const SizedBox(height: 20),
              _buildExperienceSection(isDark, textPrimary, textSecondary),
            ],
            if (selectedExperience != null && onActivityLevelChanged != null) ...[
              const SizedBox(height: 20),
              _buildActivityLevelSection(isDark, textPrimary, textSecondary),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(Color textPrimary) {
    return Text(
      "What's your current fitness level?",
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textPrimary,
        height: 1.3,
      ),
    ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.05);
  }

  Widget _buildSubtitle(Color textSecondary) {
    return Text(
      "Be honest - we'll adjust as you progress",
      style: TextStyle(
        fontSize: 14,
        color: textSecondary,
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  List<Widget> _buildLevelCards(bool isDark, Color textPrimary, Color textSecondary) {
    return _levels.asMap().entries.map((entry) {
      final index = entry.key;
      final level = entry.value;
      final isSelected = selectedLevel == level['id'];
      final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onLevelChanged(level['id'] as String);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
              children: [
                Icon(
                  level['icon'] as IconData,
                  color: isSelected ? Colors.white : (level['color'] as Color),
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        level['label'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : textPrimary,
                        ),
                      ),
                      Text(
                        level['description'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected ? Colors.white70 : textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? null
                        : Border.all(color: cardBorder, width: 2),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : null,
                ),
              ],
            ),
          ),
        ).animate(delay: (100 + index * 50).ms).fadeIn().slideX(begin: 0.05),
      );
    }).toList();
  }

  Widget _buildExperienceSection(bool isDark, Color textPrimary, Color textSecondary) {
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How long have you been lifting weights?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 4),
        Text(
          'This helps us pick the right exercises',
          style: TextStyle(
            fontSize: 12,
            color: textSecondary,
          ),
        ).animate().fadeIn(delay: 150.ms),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _experienceOptions.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final isSelected = selectedExperience == option['id'];

            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onExperienceChanged(option['id'] as String);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.cyanGradient : null,
                  color: isSelected
                      ? null
                      : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.cyan : cardBorder,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Text(
                  option['label'] as String,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : textPrimary,
                  ),
                ),
              ),
            ).animate(delay: (200 + index * 40).ms).fadeIn().scale(begin: const Offset(0.9, 0.9));
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActivityLevelSection(bool isDark, Color textPrimary, Color textSecondary) {
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily activity level (outside gym)?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 4),
        Text(
          'Helps calculate your calorie needs',
          style: TextStyle(
            fontSize: 12,
            color: textSecondary,
          ),
        ).animate().fadeIn(delay: 150.ms),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _activityLevelOptions.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final isSelected = selectedActivityLevel == option['id'];

            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onActivityLevelChanged?.call(option['id'] as String);
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      option['emoji'] as String,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      option['label'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ).animate(delay: (200 + index * 40).ms).fadeIn().scale(begin: const Offset(0.9, 0.9));
          }).toList(),
        ),
      ],
    );
  }
}
