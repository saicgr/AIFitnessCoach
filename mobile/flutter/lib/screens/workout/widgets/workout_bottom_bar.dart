/// Workout bottom bar widget
///
/// Bottom navigation bar for the active workout screen.
/// Action button bar design for quick workout actions.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/exercise.dart';

/// Bottom bar for workout actions - 6 action buttons for quick access
class WorkoutBottomBar extends StatelessWidget {
  /// Current exercise
  final WorkoutExercise currentExercise;

  /// Next exercise (null if last)
  final WorkoutExercise? nextExercise;

  /// All exercises in workout
  final List<WorkoutExercise> allExercises;

  /// Current exercise index
  final int currentExerciseIndex;

  /// Completed sets per exercise (for showing progress)
  final Map<int, int> completedSetsPerExercise;

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

  /// Callback when exercise is tapped in strip
  final void Function(int exerciseIndex)? onExerciseTap;

  /// Callback to add a set
  final VoidCallback? onAddSet;

  /// Callback to delete the last set
  final VoidCallback? onDeleteSet;

  /// Callback to open water/hydration dialog
  final VoidCallback? onAddWater;

  /// Callback to open breathing guide
  final VoidCallback? onOpenBreathingGuide;

  /// Callback to open AI coach chat
  final VoidCallback? onOpenAICoach;

  /// Number of completed sets for current exercise (for delete button state)
  final int currentCompletedSets;

  const WorkoutBottomBar({
    super.key,
    required this.currentExercise,
    this.nextExercise,
    required this.allExercises,
    required this.currentExerciseIndex,
    this.completedSetsPerExercise = const {},
    required this.showInstructions,
    required this.isResting,
    required this.onToggleInstructions,
    required this.onSkip,
    this.onShowExerciseDetails,
    this.onExerciseTap,
    this.onAddSet,
    this.onDeleteSet,
    this.onAddWater,
    this.onOpenBreathingGuide,
    this.onOpenAICoach,
    this.currentCompletedSets = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Container(
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Action buttons bar (replaces exercise strip)
            _buildActionButtonsBar(context, isDark),
          ],
        ),
      ),
    );
  }

  /// Build the 6-button action bar
  Widget _buildActionButtonsBar(BuildContext context, bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Compact mode for smaller screens (< 360px width)
    final isCompact = screenWidth < 360;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 12,
        vertical: isCompact ? 8 : 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Add Set button (blue)
          _ActionButton(
            icon: Icons.add_circle_outline,
            label: 'Add Set',
            color: AppColors.electricBlue,
            isDark: isDark,
            isCompact: isCompact,
            onTap: () {
              HapticFeedback.mediumImpact();
              onAddSet?.call();
            },
          ),

          // Delete Set button (red, disabled if 0 sets)
          _ActionButton(
            icon: Icons.remove_circle_outline,
            label: 'Del Set',
            color: AppColors.error,
            isDark: isDark,
            isCompact: isCompact,
            isDisabled: currentCompletedSets <= 0,
            onTap: currentCompletedSets > 0
                ? () {
                    HapticFeedback.mediumImpact();
                    onDeleteSet?.call();
                  }
                : null,
          ),

          // Skip button (orange)
          _ActionButton(
            icon: Icons.skip_next_rounded,
            label: 'Skip',
            color: AppColors.orange,
            isDark: isDark,
            isCompact: isCompact,
            onTap: () {
              HapticFeedback.mediumImpact();
              onSkip();
            },
          ),

          // Water button (teal)
          _ActionButton(
            icon: Icons.water_drop_outlined,
            label: 'Water',
            color: AppColors.teal,
            isDark: isDark,
            isCompact: isCompact,
            onTap: () {
              HapticFeedback.selectionClick();
              onAddWater?.call();
            },
          ),

          // Breathe button (purple)
          _ActionButton(
            icon: Icons.air_rounded,
            label: 'Breathe',
            color: AppColors.purple,
            isDark: isDark,
            isCompact: isCompact,
            onTap: () {
              HapticFeedback.selectionClick();
              onOpenBreathingGuide?.call();
            },
          ),

          // AI Coach button (cyan)
          _ActionButton(
            icon: Icons.auto_awesome,
            label: 'AI',
            color: AppColors.cyan,
            isDark: isDark,
            isCompact: isCompact,
            onTap: () {
              HapticFeedback.selectionClick();
              onOpenAICoach?.call();
            },
          ),
        ],
      ),
    );
  }
}

/// Individual action button for the bottom bar
class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final bool isDisabled;
  final bool isCompact;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    this.isDisabled = false,
    this.isCompact = false,
    this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (!widget.isDisabled) {
      setState(() => _isPressed = true);
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.isDisabled) {
      setState(() => _isPressed = false);
      widget.onTap?.call();
    }
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        widget.isDisabled ? widget.color.withOpacity(0.3) : widget.color;
    final bgOpacity = widget.isDisabled ? 0.05 : (_isPressed ? 0.25 : 0.12);

    // Responsive sizing
    final buttonSize = widget.isCompact ? 40.0 : 48.0;
    final iconSize = widget.isCompact ? 20.0 : 24.0;
    final fontSize = widget.isCompact ? 9.0 : 10.0;
    final borderRadius = widget.isCompact ? 10.0 : 14.0;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon container
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                color: effectiveColor.withOpacity(bgOpacity),
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: effectiveColor.withOpacity(widget.isDisabled ? 0.1 : 0.3),
                  width: 1.5,
                ),
                boxShadow: _isPressed && !widget.isDisabled
                    ? [
                        BoxShadow(
                          color: widget.color.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 0,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                widget.icon,
                size: iconSize,
                color: effectiveColor,
              ),
            ),
            const SizedBox(height: 4),
            // Label - hide on very compact screens
            if (!widget.isCompact)
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: effectiveColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }
}

/// Individual exercise item in the strip
class _ExerciseStripItem extends StatelessWidget {
  final WorkoutExercise exercise;
  final int index;
  final bool isCurrent;
  final bool isCompleted;
  final int completedSets;
  final int totalSets;
  final bool isDark;
  final VoidCallback onTap;

  const _ExerciseStripItem({
    required this.exercise,
    required this.index,
    required this.isCurrent,
    required this.isCompleted,
    required this.completedSets,
    required this.totalSets,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = exercise.gifUrl != null && exercise.gifUrl!.isNotEmpty;
    final allSetsComplete = completedSets >= totalSets;

    // Determine colors based on state
    Color borderColor;
    Color bgColor;
    if (isCurrent) {
      borderColor = AppColors.electricBlue;
      bgColor = AppColors.electricBlue.withOpacity(0.15);
    } else if (isCompleted || allSetsComplete) {
      borderColor = AppColors.success.withOpacity(0.6);
      bgColor = AppColors.success.withOpacity(0.1);
    } else {
      borderColor = isDark
          ? Colors.white.withOpacity(0.15)
          : Colors.black.withOpacity(0.1);
      bgColor = isDark
          ? Colors.white.withOpacity(0.05)
          : Colors.black.withOpacity(0.03);
    }

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Thumbnail with progress ring
          Stack(
            children: [
              // Progress ring background
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: borderColor,
                    width: isCurrent ? 3 : 2,
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: bgColor,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: hasImage
                      ? CachedNetworkImage(
                          imageUrl: exercise.gifUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => _buildPlaceholder(),
                          errorWidget: (context, url, error) => _buildPlaceholder(),
                        )
                      : _buildPlaceholder(),
                ),
              ),

              // Completed checkmark overlay
              if (isCompleted || allSetsComplete)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? AppColors.nearBlack : Colors.white,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),

              // Current indicator dot
              if (isCurrent && !allSetsComplete)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.electricBlue,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? AppColors.nearBlack : Colors.white,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${completedSets + 1}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 4),

          // Exercise number
          Text(
            '${index + 1}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
              color: isCurrent
                  ? AppColors.electricBlue
                  : (isCompleted
                      ? AppColors.success
                      : (isDark ? AppColors.textMuted : AppColorsLight.textMuted)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Icon(
        Icons.fitness_center_rounded,
        size: 22,
        color: isCurrent
            ? AppColors.electricBlue
            : (isCompleted
                ? AppColors.success
                : AppColors.textMuted.withOpacity(0.5)),
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
