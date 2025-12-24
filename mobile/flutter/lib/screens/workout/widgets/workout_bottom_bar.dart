/// Workout bottom bar widget
///
/// Bottom navigation bar for the active workout screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/exercise.dart';

/// Bottom bar for workout navigation and controls
class WorkoutBottomBar extends StatelessWidget {
  /// Current exercise
  final WorkoutExercise currentExercise;

  /// Next exercise (null if last)
  final WorkoutExercise? nextExercise;

  /// Whether instructions panel is shown
  final bool showInstructions;

  /// Whether currently resting
  final bool isResting;

  /// Callback to toggle instructions
  final VoidCallback onToggleInstructions;

  /// Callback to skip (rest or exercise)
  final VoidCallback onSkip;

  const WorkoutBottomBar({
    super.key,
    required this.currentExercise,
    this.nextExercise,
    required this.showInstructions,
    required this.isResting,
    required this.onToggleInstructions,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Collapsible instructions panel
          if (showInstructions)
            _buildInstructionsPanel(
              context,
              isDark: isDark,
            ),

          const SizedBox(height: 8),

          // Bottom bar
          _buildBottomBar(context, isDark: isDark),
        ],
      ),
    );
  }

  Widget _buildInstructionsPanel(BuildContext context, {required bool isDark}) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.elevated.withOpacity(0.95)
              : AppColorsLight.elevated.withOpacity(0.98),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.cyan, size: 20),
                SizedBox(width: 8),
                Text(
                  'Instructions',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.cyan,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Exercise details
            _InstructionRow(
              label: 'Reps',
              value: currentExercise.reps != null
                  ? '${currentExercise.reps} reps'
                  : '${currentExercise.durationSeconds ?? 30}s',
            ),
            _InstructionRow(
              label: 'Sets',
              value: '${currentExercise.sets ?? 3} sets',
            ),
            if (currentExercise.weight != null)
              _InstructionRow(
                label: 'Weight',
                value: '${currentExercise.weight} kg',
              ),
            _InstructionRow(
              label: 'Rest',
              value: '${currentExercise.restSeconds ?? 90}s between sets',
            ),
            if (currentExercise.notes != null &&
                currentExercise.notes!.isNotEmpty) ...[
              const Divider(color: AppColors.cardBorder, height: 24),
              Text(
                currentExercise.notes!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ).animate().fadeIn().slideY(begin: 0.1),
    );
  }

  Widget _buildBottomBar(BuildContext context, {required bool isDark}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.nearBlack.withOpacity(0.95)
            : AppColorsLight.elevated.withOpacity(0.98),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: isDark
            ? null
            : Border(
                top: BorderSide(
                    color: AppColorsLight.cardBorder.withOpacity(0.3)),
              ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
      ),
      child: Row(
        children: [
          // Expand/collapse info button
          _GlassButton(
            icon:
                showInstructions ? Icons.expand_more : Icons.expand_less,
            onTap: onToggleInstructions,
            size: 44,
          ),

          const SizedBox(width: 12),

          // Next exercise indicator
          Expanded(
            child: nextExercise != null
                ? _buildNextExerciseIndicator(isDark)
                : _buildLastExerciseIndicator(),
          ),

          const SizedBox(width: 12),

          // Skip button
          OutlinedButton(
            onPressed: onSkip,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              side: BorderSide(
                color: isResting
                    ? AppColors.purple.withOpacity(0.5)
                    : (isDark
                        ? AppColors.cardBorder
                        : AppColorsLight.cardBorder),
              ),
              foregroundColor: isResting
                  ? AppColors.purple
                  : (isDark
                      ? AppColors.textSecondary
                      : AppColorsLight.textSecondary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(isResting ? 'Skip Rest' : 'Skip'),
          ),
        ],
      ),
    );
  }

  Widget _buildNextExerciseIndicator(bool isDark) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.cyan.withOpacity(0.15),
            AppColors.electricBlue.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.cyan.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.cyan.withOpacity(0.2),
            ),
            child: const Icon(Icons.arrow_forward_rounded,
                size: 18, color: AppColors.cyan),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Next',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: AppColors.cyan.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  nextExercise!.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastExerciseIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.success.withOpacity(0.15),
            AppColors.success.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.success.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.success.withOpacity(0.2),
            ),
            child: const Icon(Icons.flag_rounded,
                size: 16, color: AppColors.success),
          ),
          const SizedBox(width: 10),
          const Text(
            'Last Exercise!',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

/// Glass button widget
class _GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  const _GlassButton({
    required this.icon,
    required this.onTap,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.pureBlack.withOpacity(0.5)
              : AppColorsLight.elevated.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.2)
                : AppColorsLight.cardBorder.withOpacity(0.5),
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Icon(
          icon,
          color: isDark ? Colors.white : AppColorsLight.textPrimary,
          size: size * 0.5,
        ),
      ),
    );
  }
}

/// Instruction row widget
class _InstructionRow extends StatelessWidget {
  final String label;
  final String value;

  const _InstructionRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        Text(
          'Set ${completedSets + 1} of $totalSets',
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textMuted,
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
                        ? AppColors.cyan
                        : AppColors.glassSurface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isCurrent ? AppColors.cyan : Colors.transparent,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
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
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color.withOpacity(0.7)),
          ],
        ),
      ),
    );
  }
}
