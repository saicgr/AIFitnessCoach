import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

/// Progression and constraints selection widget (Screen 9: Phase 2 personalization).
///
/// Allows user to select:
/// - Progression pace (Slow, Medium, Fast)
/// - Physical limitations (None, Knees, Shoulders, Lower Back, Other)
class QuizProgressionConstraints extends StatelessWidget {
  final String? selectedPace;
  final List<String> selectedLimitations;
  final String fitnessLevel;
  final ValueChanged<String> onPaceChanged;
  final ValueChanged<List<String>> onLimitationsChanged;

  const QuizProgressionConstraints({
    super.key,
    required this.selectedPace,
    required this.selectedLimitations,
    required this.fitnessLevel,
    required this.onPaceChanged,
    required this.onLimitationsChanged,
  });

  /// Get recommended pace based on fitness level
  String get _recommendedPace {
    if (fitnessLevel == 'beginner') return 'slow';
    if (fitnessLevel == 'advanced') return 'fast';
    return 'medium';
  }

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
            'Progression & Safety',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 6),
          Text(
            'Set your pace and tell us about any limitations',
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
                // Section A: Progression Pace
                Text(
                  'How fast do you want to progress?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                _buildPaceCard(
                  id: 'slow',
                  title: 'Slow & Steady',
                  description: 'Build strength gradually, lower injury risk',
                  icon: Icons.trending_flat,
                  recommended: _recommendedPace == 'slow',
                  isDark: isDark,
                  delay: 300.ms,
                ),
                const SizedBox(height: 12),
                _buildPaceCard(
                  id: 'medium',
                  title: 'Balanced',
                  description: 'Steady progress with manageable challenge',
                  icon: Icons.trending_up,
                  recommended: _recommendedPace == 'medium',
                  isDark: isDark,
                  delay: 400.ms,
                ),
                const SizedBox(height: 12),
                _buildPaceCard(
                  id: 'fast',
                  title: 'Fast & Aggressive',
                  description: 'Push hard, faster gains (advanced)',
                  icon: Icons.rocket_launch,
                  recommended: _recommendedPace == 'fast',
                  isDark: isDark,
                  delay: 500.ms,
                ),

                const SizedBox(height: 32),

                // Section B: Physical Limitations
                Text(
                  'Any physical limitations?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'We\'ll avoid exercises that stress these areas',
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 12),

                // Limitation chips
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildLimitationChip('none', 'None', isDark, 600.ms),
                    _buildLimitationChip('knees', 'Knees', isDark, 650.ms),
                    _buildLimitationChip('shoulders', 'Shoulders', isDark, 700.ms),
                    _buildLimitationChip('lower_back', 'Lower Back', isDark, 750.ms),
                    _buildLimitationChip('other', 'Other', isDark, 800.ms),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaceCard({
    required String id,
    required String title,
    required String description,
    required IconData icon,
    bool recommended = false,
    required bool isDark,
    required Duration delay,
  }) {
    final isSelected = selectedPace == id;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final textSecondary = isDark ? const Color(0xFFD4D4D8) : const Color(0xFF52525B);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onPaceChanged(id);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.orange.withValues(alpha: 0.15)
              : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.orange
                : (isDark ? AppColors.glassBorder : AppColorsLight.cardBorder),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.orange.withValues(alpha: 0.2)
                    : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.orange : textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? AppColors.orange : textPrimary,
                        ),
                      ),
                      if (recommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'FOR YOU',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.orange,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Checkmark
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.orange,
                ),
                child: const Icon(Icons.check, size: 16, color: Colors.white),
              ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: delay).slideX(begin: -0.05);
  }

  Widget _buildLimitationChip(String id, String label, bool isDark, Duration delay) {
    final isSelected = selectedLimitations.contains(id);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);

    // If "None" is selected, deselect all others
    // If any other is selected, deselect "None"
    final shouldDisable = id != 'none' && selectedLimitations.contains('none');

    return GestureDetector(
      onTap: shouldDisable
          ? null
          : () {
              HapticFeedback.selectionClick();
              List<String> newLimitations = List.from(selectedLimitations);

              if (id == 'none') {
                // Selecting "None" clears all others
                newLimitations = ['none'];
              } else {
                // Selecting any limitation removes "None"
                newLimitations.remove('none');

                if (isSelected) {
                  newLimitations.remove(id);
                } else {
                  newLimitations.add(id);
                }

                // If all are deselected, default to "None"
                if (newLimitations.isEmpty) {
                  newLimitations = ['none'];
                }
              }

              onLimitationsChanged(newLimitations);
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : textPrimary,
          ),
        ),
      ),
    ).animate().fadeIn(delay: delay).scale(begin: const Offset(0.9, 0.9));
  }
}
