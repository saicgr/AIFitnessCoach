import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

/// Lifestyle & Habits quiz widget for pre-auth quiz.
/// Collects Sleep Quality and Biggest Obstacles information.
class QuizLifestyle extends StatelessWidget {
  final String? selectedSleepQuality;
  final Set<String> selectedObstacles;
  final ValueChanged<String> onSleepQualityChanged;
  final ValueChanged<String> onObstacleToggle;

  const QuizLifestyle({
    super.key,
    required this.selectedSleepQuality,
    required this.selectedObstacles,
    required this.onSleepQualityChanged,
    required this.onObstacleToggle,
  });

  static const List<Map<String, dynamic>> sleepQualityOptions = [
    {
      'id': 'poor',
      'emoji': '😴',
      'label': 'Poor',
      'description': '<5 hrs or restless',
      'color': AppColors.accent,
    },
    {
      'id': 'fair',
      'emoji': '😐',
      'label': 'Fair',
      'description': '5-6 hrs',
      'color': AppColors.accent,
    },
    {
      'id': 'good',
      'emoji': '😊',
      'label': 'Good',
      'description': '7-8 hrs',
      'color': AppColors.success,
    },
    {
      'id': 'excellent',
      'emoji': '🌟',
      'label': 'Excellent',
      'description': '8+ hrs, well-rested',
      'color': AppColors.accent,
    },
  ];

  static const List<Map<String, dynamic>> obstacleOptions = [
    {
      'id': 'time',
      'emoji': '⏰',
      'label': 'Time',
      'description': 'Too busy, no schedule',
    },
    {
      'id': 'energy',
      'emoji': '💤',
      'label': 'Energy',
      'description': 'Too tired after work',
    },
    {
      'id': 'motivation',
      'emoji': '🎯',
      'label': 'Motivation',
      'description': 'Hard to stay consistent',
    },
    {
      'id': 'knowledge',
      'emoji': '📚',
      'label': 'Knowledge',
      'description': "Don't know what to do",
    },
    {
      'id': 'diet',
      'emoji': '🍔',
      'label': 'Diet',
      'description': "Can't control eating",
    },
    {
      'id': 'access',
      'emoji': '🏠',
      'label': 'Access',
      'description': 'Limited gym/equipment',
    },
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
            // Title
            Text(
              'Lifestyle & Habits',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textPrimary,
                height: 1.3,
              ),
            ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.05),
            const SizedBox(height: 4),
            Text(
              'Helps personalize your plan for better results',
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
              ),
            ).animate().fadeIn(delay: 150.ms),
            const SizedBox(height: 24),

            // Sleep Quality Section
            _buildSleepQualitySection(isDark, textPrimary, textSecondary),

            const SizedBox(height: 28),

            // Obstacles Section
            _buildObstaclesSection(isDark, textPrimary, textSecondary),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSleepQualitySection(bool isDark, Color textPrimary, Color textSecondary) {
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "How's your sleep?",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 4),
        Text(
          'Affects recovery and workout recommendations',
          style: TextStyle(
            fontSize: 12,
            color: textSecondary,
          ),
        ).animate().fadeIn(delay: 250.ms),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: sleepQualityOptions.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final id = option['id'] as String;
            final isSelected = selectedSleepQuality == id;
            final color = option['color'] as Color;

            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onSleepQualityChanged(id);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [color.withValues(alpha: 0.8), color],
                        )
                      : null,
                  color: isSelected
                      ? null
                      : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? color : cardBorder,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.3),
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
                      option['emoji'] as String,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      option['label'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected ? Colors.white : textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      option['description'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected ? Colors.white70 : textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ).animate(delay: (300 + index * 50).ms).fadeIn().scale(begin: const Offset(0.9, 0.9));
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildObstaclesSection(bool isDark, Color textPrimary, Color textSecondary) {
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final maxSelections = 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What holds you back most?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ).animate().fadeIn(delay: 500.ms),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              'Select up to $maxSelections',
              style: TextStyle(
                fontSize: 12,
                color: textSecondary,
              ),
            ),
            const SizedBox(width: 8),
            if (selectedObstacles.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${selectedObstacles.length}/$maxSelections',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
              ),
          ],
        ).animate().fadeIn(delay: 550.ms),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: obstacleOptions.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final id = option['id'] as String;
            final isSelected = selectedObstacles.contains(id);
            final isDisabled = !isSelected && selectedObstacles.length >= maxSelections;

            return GestureDetector(
              onTap: isDisabled
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      onObstacleToggle(id);
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.accentGradient : null,
                  color: isSelected
                      ? null
                      : isDisabled
                          ? (isDark
                              ? AppColors.glassSurface.withValues(alpha: 0.3)
                              : AppColorsLight.glassSurface.withValues(alpha: 0.3))
                          : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.accent
                        : isDisabled
                            ? cardBorder.withValues(alpha: 0.3)
                            : cardBorder,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      option['emoji'] as String,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDisabled ? Colors.grey : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          option['label'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : isDisabled
                                    ? textSecondary.withValues(alpha: 0.5)
                                    : textPrimary,
                          ),
                        ),
                        Text(
                          option['description'] as String,
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected
                                ? Colors.white70
                                : isDisabled
                                    ? textSecondary.withValues(alpha: 0.3)
                                    : textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ).animate(delay: (600 + index * 40).ms).fadeIn().scale(begin: const Offset(0.9, 0.9));
          }).toList(),
        ),
      ],
    );
  }
}
