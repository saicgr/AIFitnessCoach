import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

/// Combined fitness level and training experience question widget.
class QuizFitnessLevel extends StatelessWidget {
  final String? selectedLevel;
  final String? selectedExperience;
  final ValueChanged<String> onLevelChanged;
  final ValueChanged<String> onExperienceChanged;

  const QuizFitnessLevel({
    super.key,
    required this.selectedLevel,
    required this.selectedExperience,
    required this.onLevelChanged,
    required this.onExperienceChanged,
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
            const SizedBox(height: 8),
            _buildSubtitle(textSecondary),
            const SizedBox(height: 20),
            ..._buildLevelCards(isDark, textPrimary, textSecondary),
            if (selectedLevel != null) ...[
              const SizedBox(height: 24),
              _buildExperienceSection(isDark, textPrimary, textSecondary),
            ],
            const SizedBox(height: 20),
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
        padding: const EdgeInsets.only(bottom: 10),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onLevelChanged(level['id'] as String);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        level['label'] as String,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : textPrimary,
                        ),
                      ),
                      Text(
                        level['description'] as String,
                        style: TextStyle(
                          fontSize: 12,
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
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 6),
        Text(
          'This helps us pick the right exercises',
          style: TextStyle(
            fontSize: 13,
            color: textSecondary,
          ),
        ).animate().fadeIn(delay: 150.ms),
        const SizedBox(height: 16),
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
}
