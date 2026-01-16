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

  /// Callback to open workout plan drawer (hamburger menu)
  final VoidCallback onMenuTap;

  /// Callback for back button (when showBackButton is true)
  final VoidCallback? onBackTap;

  /// Callback to close/quit workout
  final VoidCallback onCloseTap;

  /// Callback to toggle pause
  final VoidCallback? onTimerTap;

  const WorkoutTopBarV2({
    super.key,
    required this.workoutSeconds,
    this.restSecondsRemaining,
    this.totalRestSeconds,
    required this.isPaused,
    this.showBackButton = false,
    required this.onMenuTap,
    this.onBackTap,
    required this.onCloseTap,
    this.onTimerTap,
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
              // Back button or hamburger menu button
              _TopBarButton(
                icon: showBackButton ? Icons.arrow_back_rounded : Icons.menu,
                onTap: showBackButton ? (onBackTap ?? onMenuTap) : onMenuTap,
                isDark: isDark,
              ),

              const Spacer(),

              // Workout timer (centered)
              GestureDetector(
                onTap: onTimerTap,
                child: Text(
                  WorkoutTimerController.formatTime(workoutSeconds),
                  style: WorkoutDesign.timerStyle.copyWith(
                    color: isPaused
                        ? WorkoutDesign.warning
                        : (isDark ? WorkoutDesign.textPrimary : Colors.grey.shade800),
                  ),
                ),
              ),

              const Spacer(),

              // Rest timer or close button
              if (restSecondsRemaining != null && restSecondsRemaining! > 0)
                _RestTimerChip(
                  seconds: restSecondsRemaining!,
                  totalSeconds: totalRestSeconds ?? restSecondsRemaining!,
                  isDark: isDark,
                )
              else
                _TopBarButton(
                  icon: Icons.close,
                  onTap: onCloseTap,
                  isSubdued: true,
                  isDark: isDark,
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

  const _TopBarButton({
    required this.icon,
    required this.onTap,
    this.isSubdued = false,
    this.isDark = true,
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
          color: isSubdued
              ? (isDark ? WorkoutDesign.textMuted : Colors.grey.shade500)
              : (isDark ? WorkoutDesign.textPrimary : Colors.grey.shade800),
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
