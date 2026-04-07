import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

/// Motivation multi-select widget for quiz screens.
class QuizMotivation extends StatelessWidget {
  final Set<String> selectedMotivations;
  final ValueChanged<String> onToggle;
  final bool showHeader;

  const QuizMotivation({
    super.key,
    required this.selectedMotivations,
    required this.onToggle,
    this.showHeader = true,
  });

  static const _motivations = [
    {'id': 'look_better', 'label': 'Look better', 'icon': Icons.auto_awesome, 'color': AppColors.orange},
    {'id': 'feel_stronger', 'label': 'Feel stronger', 'icon': Icons.fitness_center, 'color': AppColors.purple},
    {'id': 'more_energy', 'label': 'Have more energy', 'icon': Icons.bolt, 'color': AppColors.electricBlue},
    {'id': 'mental_health', 'label': 'Improve mental health', 'icon': Icons.psychology, 'color': AppColors.green},
    {'id': 'sleep_better', 'label': 'Sleep better', 'icon': Icons.nightlight_round, 'color': AppColors.electricBlue},
    {'id': 'be_healthier', 'label': 'Be healthier overall', 'icon': Icons.favorite, 'color': AppColors.pink},
    {'id': 'sports_performance', 'label': 'Sports performance', 'icon': Icons.sports_basketball, 'color': AppColors.orange},
    {'id': 'confidence', 'label': 'Build confidence', 'icon': Icons.star, 'color': AppColors.orange},
  ];

  @override
  Widget build(BuildContext context) {
    const textPrimary = Colors.white;
    final textSecondary = Colors.white.withValues(alpha: 0.7);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader) ...[
            _buildTitle(textPrimary),
            const SizedBox(height: 8),
            _buildSubtitle(textSecondary),
            const SizedBox(height: 24),
          ],
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
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
  final Color textPrimary;

  const _MotivationCard({
    required this.motivation,
    required this.isSelected,
    required this.onTap,
    required this.index,
    required this.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.28),
                          Colors.white.withValues(alpha: 0.16),
                        ],
                      )
                    : null,
                color: isSelected ? null : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.15),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      motivation['icon'] as IconData,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      motivation['label'] as String,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.3)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? null
                          : Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 14)
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ).animate(delay: (100 + index * 60).ms).fadeIn().slideX(begin: 0.05),
    );
  }
}
