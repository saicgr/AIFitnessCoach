/// Exercise Preview Overlay Widget
///
/// An auto-show overlay that displays before each exercise with:
/// - Form video/GIF
/// - Exercise name and target muscles
/// - Countdown progress bar (5s for new exercises, 3s for familiar)
/// - Tap to dismiss early
///
/// Smart logic:
/// - First time doing exercise: Show 5s preview
/// - Done <3 times: Show 3s preview
/// - Done 3+ times: Skip (go straight to set tracking)
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/exercise.dart';

/// Shows the exercise preview overlay before starting an exercise
/// Returns true if dismissed naturally (countdown finished), false if tapped early
Future<bool> showExercisePreview({
  required BuildContext context,
  required WorkoutExercise exercise,
  int timesPerformed = 0,
}) async {
  // Smart logic: Skip if user has done this exercise 3+ times
  if (timesPerformed >= 3) {
    return true; // Skip preview
  }

  // Determine countdown duration based on familiarity
  final countdownSeconds = timesPerformed == 0 ? 5 : 3;

  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.85),
        builder: (context) => ExercisePreviewOverlay(
          exercise: exercise,
          countdownSeconds: countdownSeconds,
          timesPerformed: timesPerformed,
        ),
      ) ??
      true;
}

/// Exercise preview overlay widget
class ExercisePreviewOverlay extends StatefulWidget {
  final WorkoutExercise exercise;
  final int countdownSeconds;
  final int timesPerformed;

  const ExercisePreviewOverlay({
    super.key,
    required this.exercise,
    required this.countdownSeconds,
    required this.timesPerformed,
  });

  @override
  State<ExercisePreviewOverlay> createState() => _ExercisePreviewOverlayState();
}

class _ExercisePreviewOverlayState extends State<ExercisePreviewOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late int _remainingSeconds;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.countdownSeconds;

    // Setup animation controller for smooth progress bar
    _progressController = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.countdownSeconds),
    );

    // Start countdown
    _startCountdown();
  }

  void _startCountdown() {
    _progressController.forward();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 1) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _countdownTimer?.cancel();
        // Auto-dismiss when countdown finishes
        Navigator.of(context).pop(true);
      }
    });
  }

  void _dismiss() {
    HapticFeedback.mediumImpact();
    _countdownTimer?.cancel();
    Navigator.of(context).pop(false);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasVideo =
        widget.exercise.gifUrl != null && widget.exercise.gifUrl!.isNotEmpty;

    return GestureDetector(
      onTap: _dismiss,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surface : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 24,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Video/GIF section
              _buildVideoSection(isDark, hasVideo),

              // Exercise info
              _buildExerciseInfo(isDark),

              // Progress bar with countdown
              _buildProgressSection(isDark),

              // Tap to start hint
              _buildTapHint(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoSection(bool isDark, bool hasVideo) {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.03),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasVideo
          ? CachedNetworkImage(
              imageUrl: widget.exercise.gifUrl!,
              fit: BoxFit.contain,
              placeholder: (context, url) => Center(
                child: CircularProgressIndicator(
                  color: AppColors.electricBlue,
                  strokeWidth: 2,
                ),
              ),
              errorWidget: (context, url, error) => _buildPlaceholderIcon(isDark),
            )
          : _buildPlaceholderIcon(isDark),
    );
  }

  Widget _buildPlaceholderIcon(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.electricBlue.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.fitness_center_rounded,
              size: 40,
              color: AppColors.electricBlue,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Form Demo',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseInfo(bool isDark) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    // Get target muscles
    String muscles = 'Full Body';
    if (widget.exercise.primaryMuscle != null &&
        widget.exercise.primaryMuscle!.isNotEmpty) {
      muscles = widget.exercise.primaryMuscle!;
    } else if (widget.exercise.muscleGroup != null &&
        widget.exercise.muscleGroup!.isNotEmpty) {
      muscles = widget.exercise.muscleGroup!;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Column(
        children: [
          // Exercise name
          Text(
            widget.exercise.name,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 8),

          // Target muscles
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sports_mma,
                size: 16,
                color: AppColors.purple,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Target: $muscles',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),

          // Familiarity indicator
          if (widget.timesPerformed > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 14,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Done ${widget.timesPerformed} time${widget.timesPerformed > 1 ? 's' : ''} before',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressSection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Progress bar
          AnimatedBuilder(
            animation: _progressController,
            builder: (context, child) {
              return Container(
                height: 6,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 1 - _progressController.value,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.electricBlue,
                          AppColors.purple,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          // Countdown text
          Text(
            '${_remainingSeconds}s',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.electricBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTapHint(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.electricBlue.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.electricBlue.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.touch_app_rounded,
              size: 20,
              color: AppColors.electricBlue,
            ),
            const SizedBox(width: 8),
            Text(
              'Tap anywhere to start',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.electricBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
