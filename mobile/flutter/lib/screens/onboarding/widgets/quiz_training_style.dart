import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

/// Training style selection widget (Screen 8: Phase 2 personalization).
///
/// Allows user to select:
/// - Training split (AI Decide, PPL, Full Body, Upper/Lower, etc.)
/// - Workout type preference (Strength, Cardio, Mixed)
///
/// Shows compatibility warnings if split doesn't match days per week.
class QuizTrainingStyle extends StatelessWidget {
  final String? selectedSplit;
  final String? selectedWorkoutType;
  final int daysPerWeek;
  final ValueChanged<String> onSplitChanged;
  final ValueChanged<String> onWorkoutTypeChanged;

  const QuizTrainingStyle({
    super.key,
    required this.selectedSplit,
    required this.selectedWorkoutType,
    required this.daysPerWeek,
    required this.onSplitChanged,
    required this.onWorkoutTypeChanged,
  });

  /// Get recommended split based on days per week
  String get _recommendedSplit {
    if (daysPerWeek <= 2) return 'full_body';
    if (daysPerWeek == 3) return 'full_body';
    if (daysPerWeek == 4) return 'upper_lower';
    return 'push_pull_legs'; // 5-6 days
  }

  /// Check if selected split is compatible with days per week
  bool get _isCompatible {
    if (selectedSplit == null || selectedSplit == 'ai_decide') return true;

    switch (selectedSplit) {
      case 'full_body':
        return daysPerWeek <= 3;
      case 'upper_lower':
      case 'phul':
        return daysPerWeek >= 4 && daysPerWeek <= 5;
      case 'push_pull_legs':
        return daysPerWeek >= 3 && daysPerWeek <= 6;
      case 'body_part':
        return daysPerWeek >= 5;
      default:
        return true;
    }
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
            'Training Style',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 6),
          Text(
            'Choose how you want to structure your workouts',
            style: TextStyle(
              fontSize: 15,
              color: textSecondary,
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 24),

          // Section A: Training Split
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Text(
                  'Training Split',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                // Split options
                _buildSplitOption(
                  id: 'ai_decide',
                  title: 'Let AI Decide',
                  description: 'Automatically optimized for your schedule (Recommended)',
                  recommended: true,
                  isDark: isDark,
                  delay: 300.ms,
                ),
                const SizedBox(height: 12),
                _buildSplitOption(
                  id: 'push_pull_legs',
                  title: 'Push / Pull / Legs',
                  description: 'Best for 5-6 days/week',
                  isDark: isDark,
                  delay: 350.ms,
                ),
                const SizedBox(height: 12),
                _buildSplitOption(
                  id: 'full_body',
                  title: 'Full Body',
                  description: 'Train all muscles each workout (1-3 days)',
                  isDark: isDark,
                  delay: 400.ms,
                ),
                const SizedBox(height: 12),
                _buildSplitOption(
                  id: 'upper_lower',
                  title: 'Upper / Lower',
                  description: 'Split between upper and lower body (4 days)',
                  isDark: isDark,
                  delay: 450.ms,
                ),
                const SizedBox(height: 12),
                _buildSplitOption(
                  id: 'phul',
                  title: 'PHUL',
                  description: 'Power + Hypertrophy, Upper + Lower',
                  isDark: isDark,
                  delay: 500.ms,
                ),
                const SizedBox(height: 12),
                _buildSplitOption(
                  id: 'body_part',
                  title: 'Body Part Split',
                  description: 'One muscle group per day (5+ days)',
                  isDark: isDark,
                  delay: 550.ms,
                ),

                // Compatibility warning
                if (!_isCompatible) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'This split works better with $_recommendedSplit for $daysPerWeek days/week',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().shake(delay: 600.ms),
                ],

                const SizedBox(height: 32),

                // Section B: Workout Type
                Text(
                  'Workout Type',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                // Workout type chips
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildTypeChip('strength', 'Strength', isDark, 650.ms),
                    _buildTypeChip('cardio', 'Cardio', isDark, 700.ms),
                    _buildTypeChip('mixed', 'Mixed', isDark, 750.ms),
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

  Widget _buildSplitOption({
    required String id,
    required String title,
    required String description,
    bool recommended = false,
    required bool isDark,
    required Duration delay,
  }) {
    final isSelected = selectedSplit == id;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final textSecondary = isDark ? const Color(0xFFD4D4D8) : const Color(0xFF52525B);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onSplitChanged(id);
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
            // Radio indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.orange : textSecondary,
                  width: 2,
                ),
                color: isSelected ? AppColors.orange : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
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
                            'BEST',
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
          ],
        ),
      ),
    ).animate().fadeIn(delay: delay).slideX(begin: -0.05);
  }

  Widget _buildTypeChip(String id, String label, bool isDark, Duration delay) {
    final isSelected = selectedWorkoutType == id;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onWorkoutTypeChanged(id);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
