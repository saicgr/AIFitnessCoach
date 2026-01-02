import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';

/// Difficulty option data
class DifficultyOption {
  final String value;
  final String label;
  final String emoji;
  final String description;
  final Color color;

  const DifficultyOption({
    required this.value,
    required this.label,
    required this.emoji,
    required this.description,
    required this.color,
  });
}

/// A widget for selecting exercise difficulty during calibration
/// Shows how the exercise felt to help calibrate future workouts
class CalibrationDifficultySelector extends StatelessWidget {
  /// Currently selected difficulty value
  final String selectedDifficulty;

  /// Callback when difficulty selection changes
  final ValueChanged<String> onDifficultyChanged;

  /// Whether the selector is disabled
  final bool disabled;

  const CalibrationDifficultySelector({
    super.key,
    required this.selectedDifficulty,
    required this.onDifficultyChanged,
    this.disabled = false,
  });

  static const List<DifficultyOption> _options = [
    DifficultyOption(
      value: 'too_easy',
      label: 'Too Easy',
      emoji: '😊',
      description: 'Could do many more reps',
      color: AppColors.success,
    ),
    DifficultyOption(
      value: 'moderate',
      label: 'Moderate',
      emoji: '😐',
      description: 'Comfortable challenge',
      color: AppColors.cyan,
    ),
    DifficultyOption(
      value: 'challenging',
      label: 'Challenging',
      emoji: '💪',
      description: 'Pushed my limits',
      color: AppColors.orange,
    ),
    DifficultyOption(
      value: 'max_effort',
      label: 'Max Effort',
      emoji: '🔥',
      description: 'Gave everything',
      color: AppColors.error,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.sentiment_satisfied_alt,
                color: AppColors.purple,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'How did this feel?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Your feedback helps us personalize your workouts',
            style: TextStyle(
              fontSize: 12,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          // Difficulty options grid
          LayoutBuilder(
            builder: (context, constraints) {
              // Use 2 columns for narrow screens, 4 for wider screens
              final crossAxisCount = constraints.maxWidth > 400 ? 4 : 2;

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _options.map((option) {
                  final isSelected = selectedDifficulty == option.value;
                  return SizedBox(
                    width: crossAxisCount == 4
                        ? (constraints.maxWidth - 24) / 4
                        : (constraints.maxWidth - 8) / 2,
                    child: _DifficultyOptionCard(
                      option: option,
                      isSelected: isSelected,
                      disabled: disabled,
                      onTap: () {
                        if (!disabled) {
                          HapticFeedback.mediumImpact();
                          onDifficultyChanged(option.value);
                        }
                      },
                      isDark: isDark,
                    ),
                  );
                }).toList(),
              );
            },
          ),

          // Selected difficulty description
          const SizedBox(height: 12),
          _buildSelectedDescription(textSecondary),
        ],
      ),
    );
  }

  Widget _buildSelectedDescription(Color textColor) {
    final selected = _options.firstWhere(
      (o) => o.value == selectedDifficulty,
      orElse: () => _options[1], // Default to moderate
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: selected.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: selected.color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(
            selected.emoji,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selected.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: selected.color,
                  ),
                ),
                Text(
                  selected.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle,
            color: selected.color,
            size: 20,
          ),
        ],
      ),
    );
  }
}

/// Individual difficulty option card
class _DifficultyOptionCard extends StatelessWidget {
  final DifficultyOption option;
  final bool isSelected;
  final bool disabled;
  final VoidCallback onTap;
  final bool isDark;

  const _DifficultyOptionCard({
    required this.option,
    required this.isSelected,
    required this.disabled,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? option.color.withOpacity(0.15)
              : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? option.color
                : (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: option.color.withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              option.emoji,
              style: TextStyle(
                fontSize: 24,
                color: disabled ? Colors.grey : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              option.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? option.color
                    : (isDark ? AppColors.textSecondary : AppColorsLight.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
