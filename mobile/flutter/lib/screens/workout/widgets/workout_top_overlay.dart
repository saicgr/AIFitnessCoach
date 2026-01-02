/// Top overlay widget for active workout screen
///
/// Displays workout timer, pause/resume controls, and exercise list access.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../controllers/workout_timer_controller.dart';

/// Top overlay with workout controls
class WorkoutTopOverlay extends StatelessWidget {
  /// Total workout seconds
  final int workoutSeconds;

  /// Whether workout is paused
  final bool isPaused;

  /// Total exercises count
  final int totalExercises;

  /// Current exercise index (0-based)
  final int currentExerciseIndex;

  /// Total completed sets count
  final int totalCompletedSets;

  /// Callback to toggle pause
  final VoidCallback onTogglePause;

  /// Callback to show exercise list
  final VoidCallback onShowExerciseList;

  /// Callback to quit workout
  final VoidCallback onQuit;

  /// Optional scale factor for stat chips
  final double scaleFactor;

  const WorkoutTopOverlay({
    super.key,
    required this.workoutSeconds,
    required this.isPaused,
    required this.totalExercises,
    required this.currentExerciseIndex,
    required this.totalCompletedSets,
    required this.onTogglePause,
    required this.onShowExerciseList,
    required this.onQuit,
    this.scaleFactor = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left side stats
              Row(
                children: [
                  // Timer stat
                  _StatChip(
                    icon: isPaused ? Icons.pause : Icons.timer,
                    value: WorkoutTimerController.formatTime(workoutSeconds),
                    color: isPaused ? AppColors.orange : AppColors.cyan,
                    scaleFactor: scaleFactor,
                    isTappable: true,
                    label: isPaused ? 'PAUSED' : null,
                    onTap: onTogglePause,
                  ),
                  SizedBox(width: 8 * scaleFactor),
                  // Exercise progress stat
                  _StatChip(
                    icon: Icons.fitness_center,
                    value: '${currentExerciseIndex + 1}/$totalExercises',
                    color: AppColors.purple,
                    scaleFactor: scaleFactor,
                    isTappable: true,
                    onTap: onShowExerciseList,
                  ),
                  SizedBox(width: 8 * scaleFactor),
                  // Sets completed stat
                  _StatChip(
                    icon: Icons.check_circle_outline,
                    value: '$totalCompletedSets',
                    suffix: ' sets',
                    color: AppColors.success,
                    scaleFactor: scaleFactor,
                  ),
                ],
              ),
              // Right side - close button
              _GlassButton(
                icon: Icons.close,
                onTap: onQuit,
                isSubdued: true,
                size: 40 * scaleFactor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Stat chip widget for displaying workout stats
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String? suffix;
  final String? label;
  final Color color;
  final double scaleFactor;
  final bool isTappable;
  final VoidCallback? onTap;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.color,
    this.suffix,
    this.label,
    this.scaleFactor = 1.0,
    this.isTappable = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Dynamic dimensions based on scale factor
    final horizontalPadding = (10 * scaleFactor).clamp(6.0, 14.0);
    final verticalPadding = (6 * scaleFactor).clamp(4.0, 8.0);
    final iconSize = (16 * scaleFactor).clamp(12.0, 20.0);
    final valueFontSize = (14 * scaleFactor).clamp(10.0, 18.0);
    final suffixFontSize = (10 * scaleFactor).clamp(8.0, 13.0);
    final labelFontSize = (8 * scaleFactor).clamp(6.0, 10.0);
    final innerSpacing = (4 * scaleFactor).clamp(2.0, 6.0);
    final borderRadius = (12 * scaleFactor).clamp(8.0, 16.0);

    final widget = Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: AppColors.pureBlack.withOpacity(0.5),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isTappable ? color.withOpacity(0.5) : color.withOpacity(0.3),
          width: isTappable ? 1.5 : 1.0,
        ),
        boxShadow: isTappable
            ? [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: color),
          SizedBox(width: innerSpacing),
          Text(
            label ?? value,
            style: TextStyle(
              fontSize: label != null ? labelFontSize : valueFontSize,
              fontWeight: FontWeight.bold,
              fontFamily: label != null ? null : 'monospace',
              color: label != null ? AppColors.orange : color,
            ),
          ),
          if (suffix != null && label == null)
            Text(
              suffix!,
              style: TextStyle(
                fontSize: suffixFontSize,
                color: color.withOpacity(0.7),
              ),
            ),
          if (isTappable) ...[
            SizedBox(width: innerSpacing * 0.5),
            Icon(
              Icons.add_circle_outline,
              size: iconSize * 0.7,
              color: color.withOpacity(0.5),
            ),
          ],
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap?.call();
        },
        child: widget,
      );
    }
    return widget;
  }
}

/// Glass button widget
class _GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isHighlighted;
  final bool isSubdued;
  final double size;

  const _GlassButton({
    required this.icon,
    required this.onTap,
    this.isHighlighted = false,
    this.isSubdued = false,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isHighlighted
        ? AppColors.cyan.withOpacity(0.3)
        : isSubdued
            ? (isDark
                ? AppColors.pureBlack.withOpacity(0.3)
                : AppColorsLight.elevated.withOpacity(0.8))
            : (isDark
                ? AppColors.pureBlack.withOpacity(0.5)
                : AppColorsLight.elevated.withOpacity(0.9));

    final borderColor = isHighlighted
        ? AppColors.cyan.withOpacity(0.5)
        : isSubdued
            ? (isDark
                ? Colors.white.withOpacity(0.1)
                : AppColorsLight.cardBorder.withOpacity(0.3))
            : (isDark
                ? Colors.white.withOpacity(0.2)
                : AppColorsLight.cardBorder.withOpacity(0.5));

    final iconColor = isHighlighted
        ? AppColors.cyan
        : isSubdued
            ? (isDark ? Colors.white.withOpacity(0.5) : AppColorsLight.textMuted)
            : (isDark ? Colors.white : AppColorsLight.textPrimary);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
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
          color: iconColor,
          size: size * 0.5,
        ),
      ),
    );
  }
}

/// Standalone stat chip widget for use in other contexts
class WorkoutStatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String? suffix;
  final String? label;
  final Color color;
  final double scaleFactor;
  final bool isTappable;
  final VoidCallback? onTap;

  const WorkoutStatChip({
    super.key,
    required this.icon,
    required this.value,
    required this.color,
    this.suffix,
    this.label,
    this.scaleFactor = 1.0,
    this.isTappable = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _StatChip(
      icon: icon,
      value: value,
      color: color,
      suffix: suffix,
      label: label,
      scaleFactor: scaleFactor,
      isTappable: isTappable,
      onTap: onTap,
    );
  }
}

/// Standalone glass button widget for use in other contexts
class GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isHighlighted;
  final bool isSubdued;
  final double size;

  const GlassButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.isHighlighted = false,
    this.isSubdued = false,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassButton(
      icon: icon,
      onTap: onTap,
      isHighlighted: isHighlighted,
      isSubdued: isSubdued,
      size: size,
    );
  }
}
