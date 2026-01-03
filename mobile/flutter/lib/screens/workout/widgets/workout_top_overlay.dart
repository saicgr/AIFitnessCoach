/// Top overlay widget for active workout screen
///
/// Displays workout timer with progress bar, minimal and clean design.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../controllers/workout_timer_controller.dart';

/// Top overlay with workout controls - simplified design
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

  double get progress => totalExercises > 0
      ? (currentExerciseIndex + 1) / totalExercises
      : 0.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            children: [
              // Main controls row
              Row(
                children: [
                  // Pause/Play button
                  _GlassButton(
                    icon: isPaused ? Icons.play_arrow : Icons.pause,
                    onTap: onTogglePause,
                    isHighlighted: isPaused,
                    size: 44 * scaleFactor,
                  ),

                  const Spacer(),

                  // Timer - centered and prominent
                  _buildTimer(isDark),

                  const Spacer(),

                  // Close button
                  _GlassButton(
                    icon: Icons.close,
                    onTap: onQuit,
                    isSubdued: true,
                    size: 44 * scaleFactor,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Progress bar
              _buildProgressBar(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimer(bool isDark) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTogglePause();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.pureBlack.withOpacity(0.6)
              : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPaused
                ? AppColors.orange.withOpacity(0.5)
                : (isDark
                    ? Colors.white.withOpacity(0.15)
                    : Colors.black.withOpacity(0.08)),
            width: isPaused ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPaused ? Icons.pause : Icons.timer_outlined,
              size: 20,
              color: isPaused
                  ? AppColors.orange
                  : (isDark ? Colors.white : AppColorsLight.textPrimary),
            ),
            const SizedBox(width: 10),
            Text(
              WorkoutTimerController.formatTime(workoutSeconds),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                letterSpacing: 1,
                color: isPaused
                    ? AppColors.orange
                    : (isDark ? Colors.white : AppColorsLight.textPrimary),
              ),
            ),
            if (isPaused) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'PAUSED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.orange,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(bool isDark) {
    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.1)
            : Colors.black.withOpacity(0.08),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Stack(
        children: [
          AnimatedFractionallySizedBox(
            duration: const Duration(milliseconds: 300),
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.electricBlue,
                    AppColors.electricBlue.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(3),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.electricBlue.withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ],
              ),
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
        ? AppColors.orange.withOpacity(0.2)
        : isSubdued
            ? (isDark
                ? AppColors.pureBlack.withOpacity(0.4)
                : Colors.white.withOpacity(0.8))
            : (isDark
                ? AppColors.pureBlack.withOpacity(0.5)
                : Colors.white.withOpacity(0.9));

    final borderColor = isHighlighted
        ? AppColors.orange.withOpacity(0.5)
        : isSubdued
            ? (isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.08))
            : (isDark
                ? Colors.white.withOpacity(0.15)
                : Colors.black.withOpacity(0.1));

    final iconColor = isHighlighted
        ? AppColors.orange
        : isSubdued
            ? (isDark ? Colors.white.withOpacity(0.6) : AppColorsLight.textMuted)
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
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: isHighlighted ? 2 : 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.08),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final horizontalPadding = (10 * scaleFactor).clamp(6.0, 14.0);
    final verticalPadding = (6 * scaleFactor).clamp(4.0, 8.0);
    final iconSize = (16 * scaleFactor).clamp(12.0, 20.0);
    final valueFontSize = (14 * scaleFactor).clamp(10.0, 18.0);
    final suffixFontSize = (10 * scaleFactor).clamp(8.0, 13.0);
    final innerSpacing = (4 * scaleFactor).clamp(2.0, 6.0);
    final borderRadius = (12 * scaleFactor).clamp(8.0, 16.0);

    final widget = Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.pureBlack.withOpacity(0.5)
            : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isTappable ? color.withOpacity(0.5) : color.withOpacity(0.3),
          width: isTappable ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: color),
          SizedBox(width: innerSpacing),
          Text(
            label ?? value,
            style: TextStyle(
              fontSize: valueFontSize,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              color: color,
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
