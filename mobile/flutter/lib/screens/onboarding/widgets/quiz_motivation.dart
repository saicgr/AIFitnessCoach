import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

/// Motivation multi-select widget for quiz screens.
class QuizMotivation extends StatelessWidget {
  final Set<String> selectedMotivations;
  final ValueChanged<String> onToggle;

  const QuizMotivation({
    super.key,
    required this.selectedMotivations,
    required this.onToggle,
  });

  static const _motivations = [
    {'id': 'look_better', 'label': 'Look better', 'icon': Icons.auto_awesome, 'color': AppColors.purple},
    {'id': 'feel_stronger', 'label': 'Feel stronger', 'icon': Icons.fitness_center, 'color': AppColors.cyan},
    {'id': 'more_energy', 'label': 'Have more energy', 'icon': Icons.bolt, 'color': AppColors.orange},
    {'id': 'mental_health', 'label': 'Improve mental health', 'icon': Icons.psychology, 'color': AppColors.success},
    {'id': 'sleep_better', 'label': 'Sleep better', 'icon': Icons.nightlight_round, 'color': AppColors.electricBlue},
    {'id': 'be_healthier', 'label': 'Be healthier overall', 'icon': Icons.favorite, 'color': AppColors.coral},
    {'id': 'sports_performance', 'label': 'Sports performance', 'icon': Icons.sports_basketball, 'color': AppColors.warning},
    {'id': 'confidence', 'label': 'Build confidence', 'icon': Icons.star, 'color': AppColors.purple},
  ];

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
          _buildTitle(textPrimary),
          const SizedBox(height: 8),
          _buildSubtitle(textSecondary),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: _motivations.length,
              itemBuilder: (context, index) {
                final motivation = _motivations[index];
                return _MotivationCard(
                  motivation: motivation,
                  isSelected: selectedMotivations.contains(motivation['id'] as String),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onToggle(motivation['id'] as String);
                  },
                  index: index,
                  isDark: isDark,
                  textPrimary: textPrimary,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(Color textPrimary) {
    return Text(
      "What's driving you to work out?",
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
      'Select all that resonate with you',
      style: TextStyle(
        fontSize: 14,
        color: textSecondary,
      ),
    ).animate().fadeIn(delay: 200.ms);
  }
}

class _MotivationCard extends StatelessWidget {
  final Map<String, dynamic> motivation;
  final bool isSelected;
  final VoidCallback onTap;
  final int index;
  final bool isDark;
  final Color textPrimary;

  const _MotivationCard({
    required this.motivation,
    required this.isSelected,
    required this.onTap,
    required this.index,
    required this.isDark,
    required this.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final color = motivation['color'] as Color;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color.withOpacity(0.8), color],
                  )
                : null,
            color: isSelected
                ? null
                : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : cardBorder,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.2)
                      : color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  motivation['icon'] as IconData,
                  color: isSelected ? Colors.white : color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  motivation['label'] as String,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : textPrimary,
                  ),
                ),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? null
                      : Border.all(color: cardBorder, width: 2),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
            ],
          ),
        ),
      ).animate(delay: (100 + index * 60).ms).fadeIn().slideX(begin: 0.05),
    );
  }
}
