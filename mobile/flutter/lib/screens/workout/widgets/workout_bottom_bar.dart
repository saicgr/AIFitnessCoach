/// Workout bottom bar widget
///
/// Bottom navigation bar for the active workout screen.
/// Simplified design showing only next exercise preview.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/exercise.dart';

/// Bottom bar for workout navigation - simplified to next exercise preview
class WorkoutBottomBar extends StatelessWidget {
  /// Current exercise
  final WorkoutExercise currentExercise;

  /// Next exercise (null if last)
  final WorkoutExercise? nextExercise;

  /// Whether instructions panel is shown (kept for compatibility)
  final bool showInstructions;

  /// Whether currently resting
  final bool isResting;

  /// Callback to toggle instructions (kept for compatibility)
  final VoidCallback onToggleInstructions;

  /// Callback to skip (rest or exercise)
  final VoidCallback onSkip;

  /// Optional callback to show exercise details
  final VoidCallback? onShowExerciseDetails;

  const WorkoutBottomBar({
    super.key,
    required this.currentExercise,
    this.nextExercise,
    required this.showInstructions,
    required this.isResting,
    required this.onToggleInstructions,
    required this.onSkip,
    this.onShowExerciseDetails,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.nearBlack.withOpacity(0.95)
              : Colors.white.withOpacity(0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: nextExercise != null
            ? _buildNextExercisePreview(isDark)
            : _buildLastExerciseIndicator(isDark),
      ),
    );
  }

  Widget _buildNextExercisePreview(bool isDark) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onShowExerciseDetails?.call();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.05),
          ),
        ),
        child: Row(
          children: [
            // Next icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.electricBlue.withOpacity(0.12),
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                size: 20,
                color: AppColors.electricBlue,
              ),
            ),
            const SizedBox(width: 14),

            // Exercise info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'UP NEXT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                      color: textMuted,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    nextExercise!.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _buildExerciseDetails(nextExercise!),
                    style: TextStyle(
                      fontSize: 12,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
            ),

            // Chevron
            Icon(
              Icons.chevron_right,
              size: 24,
              color: textMuted,
            ),
          ],
        ),
      ),
    );
  }

  String _buildExerciseDetails(WorkoutExercise exercise) {
    final parts = <String>[];

    if (exercise.sets != null) {
      parts.add('${exercise.sets} sets');
    }
    if (exercise.reps != null) {
      parts.add('${exercise.reps} reps');
    } else if (exercise.durationSeconds != null) {
      parts.add('${exercise.durationSeconds}s');
    }
    if (exercise.weight != null) {
      parts.add('${exercise.weight}kg');
    }

    return parts.join(' • ');
  }

  Widget _buildLastExerciseIndicator(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.success.withOpacity(0.12),
            AppColors.success.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.success.withOpacity(0.25),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.success.withOpacity(0.15),
            ),
            child: const Icon(
              Icons.flag_rounded,
              size: 20,
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: 14),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FINAL EXERCISE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                  color: AppColors.success,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'You\'re almost there!',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Set dots progress indicator
class SetDotsIndicator extends StatelessWidget {
  final int totalSets;
  final int completedSets;

  const SetDotsIndicator({
    super.key,
    required this.totalSets,
    required this.completedSets,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        Text(
          'Set ${completedSets + 1} of $totalSets',
          style: TextStyle(
            fontSize: 11,
            color: textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        // Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(totalSets, (index) {
            final isCompleted = index < completedSets;
            final isCurrent = index == completedSets;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isCurrent ? 24 : 12,
              height: 12,
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.success
                    : isCurrent
                        ? AppColors.electricBlue
                        : (isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.08)),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isCurrent ? AppColors.electricBlue : Colors.transparent,
                  width: 2,
                ),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 8, color: Colors.white)
                  : null,
            );
          }),
        ),
      ],
    );
  }
}

/// Exercise option tile for action sheets
class ExerciseOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const ExerciseOptionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textMuted
                          : AppColorsLight.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color.withOpacity(0.6)),
          ],
        ),
      ),
    );
  }
}
