import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

/// Multi-select question widget for quiz screens.
class QuizMultiSelect extends StatelessWidget {
  final String question;
  final String subtitle;
  final List<Map<String, dynamic>> options;
  final Set<String> selectedValues;
  final ValueChanged<String> onToggle;
  final bool showDescriptions;

  const QuizMultiSelect({
    super.key,
    required this.question,
    required this.subtitle,
    required this.options,
    required this.selectedValues,
    required this.onToggle,
    this.showDescriptions = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textPrimary,
              height: 1.3,
            ),
          ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.05),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: options.length,
              itemBuilder: (context, index) {
                final option = options[index];
                final id = option['id'] as String;
                final isSelected = selectedValues.contains(id);

                return _QuizOptionCard(
                  option: option,
                  isSelected: isSelected,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onToggle(id);
                  },
                  index: index,
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  showDescription: showDescriptions,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizOptionCard extends StatelessWidget {
  final Map<String, dynamic> option;
  final bool isSelected;
  final VoidCallback onTap;
  final int index;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final bool showDescription;

  const _QuizOptionCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
    required this.index,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    this.showDescription = false,
  });

  @override
  Widget build(BuildContext context) {
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final color = option['color'] as Color? ?? AppColors.accent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected ? AppColors.accentGradient : null,
            color: isSelected
                ? null
                : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.accent : cardBorder,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.accent.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.2)
                      : color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  option['icon'] as IconData,
                  color: isSelected ? Colors.white : color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option['label'] as String,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : textPrimary,
                      ),
                    ),
                    if (showDescription && option['description'] != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        option['description'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.white70 : textSecondary,
                        ),
                      ),
                    ],
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
      ).animate(delay: (100 + index * 80).ms).fadeIn().slideX(begin: 0.05),
    );
  }
}
