/// Workout Top Bar V2
///
/// MacroFactor Workouts 2026 inspired top bar.
/// Features:
/// - Hamburger menu on left (opens workout plan drawer)
/// - Workout timer in center
/// - Rest timer with icon and mini progress bar on right
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/workout_design.dart';
import '../controllers/workout_timer_controller.dart';

/// MacroFactor-style workout top bar
class WorkoutTopBarV2 extends StatelessWidget {
  /// Total workout seconds elapsed
  final int workoutSeconds;

  /// Current rest timer seconds remaining (null if not resting)
  final int? restSecondsRemaining;

  /// Total rest duration (for progress calculation)
  final int? totalRestSeconds;

  /// Whether workout is paused
  final bool isPaused;

  /// Whether to show back button instead of hamburger menu (for warmup flow)
  final bool showBackButton;

  /// Label to show next to back button (e.g., "Warmup")
  final String? backButtonLabel;

  /// Callback to open workout plan drawer (hamburger menu)
  final VoidCallback onMenuTap;

  /// Callback for back button (when showBackButton is true)
  final VoidCallback? onBackTap;

  /// Callback to close/quit workout
  final VoidCallback onCloseTap;

  /// Callback to toggle pause
  final VoidCallback? onTimerTap;

  /// Callback to minimize workout to mini player
  final VoidCallback? onMinimize;

  /// Callback to toggle favorite for current exercise
  final VoidCallback? onFavoriteTap;

  /// Whether current exercise is favorited
  final bool isFavorite;

  const WorkoutTopBarV2({
    super.key,
    required this.workoutSeconds,
    this.restSecondsRemaining,
    this.totalRestSeconds,
    required this.isPaused,
    this.showBackButton = false,
    this.backButtonLabel,
    required this.onMenuTap,
    this.onBackTap,
    required this.onCloseTap,
    this.onTimerTap,
    this.onMinimize,
    this.onFavoriteTap,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? WorkoutDesign.background : Colors.white,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: WorkoutDesign.paddingMedium,
            vertical: 8,
          ),
          child: Row(
            children: [
              // Back/close button on left with optional label
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _TopBarButton(
                    icon: showBackButton ? Icons.arrow_back_rounded : Icons.arrow_back_rounded,
                    onTap: showBackButton ? (onBackTap ?? onCloseTap) : onCloseTap,
                    isDark: isDark,
                  ),
                  // Label next to back button (e.g., "Warmup")
                  if (backButtonLabel != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      backButtonLabel!,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: isDark ? WorkoutDesign.textSecondary : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),

              const Spacer(),

              // Favorite + Minimize button + Timer on right
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Favorite button (leftmost in this group)
                  if (onFavoriteTap != null)
                    _TopBarButton(
                      icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                      onTap: onFavoriteTap!,
                      isDark: isDark,
                      iconColor: isFavorite ? Colors.red : null,
                    ),

                  // Minimize button (PiP style)
                  if (onMinimize != null)
                    _TopBarButton(
                      icon: Icons.picture_in_picture_alt,
                      onTap: onMinimize!,
                      isSubdued: true,
                      isDark: isDark,
                    ),

                  // Total time elapsed with timer icon
                  GestureDetector(
                    onTap: onTimerTap,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 18,
                          color: isPaused
                              ? WorkoutDesign.warning
                              : (isDark ? WorkoutDesign.textSecondary : Colors.grey.shade600),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          WorkoutTimerController.formatTime(workoutSeconds),
                          style: WorkoutDesign.timerStyle.copyWith(
                            fontSize: 16,
                            color: isPaused
                                ? WorkoutDesign.warning
                                : (isDark ? WorkoutDesign.textSecondary : Colors.grey.shade600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Top bar icon button
class _TopBarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isSubdued;
  final bool isDark;
  final Color? iconColor;

  const _TopBarButton({
    required this.icon,
    required this.onTap,
    this.isSubdued = false,
    this.isDark = true,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 24,
          color: iconColor ??
              (isSubdued
                  ? (isDark ? WorkoutDesign.textMuted : Colors.grey.shade500)
                  : (isDark ? WorkoutDesign.textPrimary : Colors.grey.shade800)),
        ),
      ),
    );
  }
}

/// Rest timer chip with icon and mini progress bar
class _RestTimerChip extends StatelessWidget {
  final int seconds;
  final int totalSeconds;
  final bool isDark;

  const _RestTimerChip({
    required this.seconds,
    required this.totalSeconds,
    this.isDark = true,
  });

  double get progress => totalSeconds > 0 ? seconds / totalSeconds : 0;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Timer icon
        Icon(
          Icons.timer_outlined,
          size: 18,
          color: isDark ? WorkoutDesign.textSecondary : Colors.grey.shade600,
        ),

        const SizedBox(width: 6),

        // Timer value
        Text(
          _formatRestTime(seconds),
          style: WorkoutDesign.timerStyle.copyWith(
            fontSize: 16,
            color: isDark ? WorkoutDesign.textSecondary : Colors.grey.shade600,
          ),
        ),

        const SizedBox(width: 8),

        // Mini progress bar
        SizedBox(
          width: 60,
          height: 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: Stack(
              children: [
                // Background
                Container(
                  color: isDark ? WorkoutDesign.border : Colors.grey.shade300,
                ),
                // Progress
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? WorkoutDesign.textSecondary : Colors.grey.shade600,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatRestTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }
}
