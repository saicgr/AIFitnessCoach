import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/injury.dart';

class RehabExerciseCard extends StatelessWidget {
  final RehabExercise exercise;
  final VoidCallback? onToggleComplete;
  final VoidCallback? onTap;

  const RehabExerciseCard({
    super.key,
    required this.exercise,
    this.onToggleComplete,
    this.onTap,
  });

  IconData _getExerciseTypeIcon() {
    switch (exercise.exerciseType.toLowerCase()) {
      case 'stretch':
        return Icons.self_improvement;
      case 'mobility':
        return Icons.accessibility_new;
      case 'strength':
        return Icons.fitness_center;
      case 'foam_roll':
        return Icons.sports_tennis;
      case 'ice':
        return Icons.ac_unit;
      case 'heat':
        return Icons.whatshot;
      case 'massage':
        return Icons.spa;
      default:
        return Icons.healing;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final accentColor = exercise.isCompleted ? AppColors.success : AppColors.teal;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: exercise.isCompleted
                ? AppColors.success.withValues(alpha: 0.5)
                : cardBorder,
            width: exercise.isCompleted ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Completion checkbox
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                onToggleComplete?.call();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: exercise.isCompleted
                      ? AppColors.success
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: exercise.isCompleted
                        ? AppColors.success
                        : textMuted,
                    width: 2,
                  ),
                ),
                child: exercise.isCompleted
                    ? const Icon(
                        Icons.check,
                        size: 18,
                        color: Colors.white,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 14),
            // Exercise type icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getExerciseTypeIcon(),
                color: accentColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            // Exercise details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.exerciseName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: exercise.isCompleted
                          ? textMuted
                          : textPrimary,
                      decoration: exercise.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Prescription
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          exercise.prescriptionText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: accentColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Frequency
                      Icon(
                        Icons.repeat,
                        size: 12,
                        color: textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        exercise.frequencyText,
                        style: TextStyle(
                          fontSize: 11,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                  if (exercise.notes != null && exercise.notes!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      exercise.notes!,
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // Video link indicator
            if (exercise.videoUrl != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.play_circle_outline,
                  color: AppColors.cyan,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A compact version of the rehab exercise card for lists
class CompactRehabExerciseCard extends StatelessWidget {
  final RehabExercise exercise;
  final VoidCallback? onToggleComplete;

  const CompactRehabExerciseCard({
    super.key,
    required this.exercise,
    this.onToggleComplete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Checkbox
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onToggleComplete?.call();
            },
            child: Icon(
              exercise.isCompleted
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: exercise.isCompleted ? AppColors.success : textMuted,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          // Exercise name and prescription
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.exerciseName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: exercise.isCompleted ? textMuted : textPrimary,
                    decoration: exercise.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                Text(
                  '${exercise.prescriptionText} - ${exercise.frequencyText}',
                  style: TextStyle(
                    fontSize: 12,
                    color: textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
