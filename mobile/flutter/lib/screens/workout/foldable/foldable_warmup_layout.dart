/// Foldable Warmup Layout
///
/// Warmup phase variant for foldable/tablet devices.
/// Left pane: exercise animation (icon + name + countdown timer).
/// Right pane: progress through warmup exercises, controls, upcoming list.
///
/// Uses the same hinge calculation pattern as FoldableQuizScaffold and
/// reuses PhaseTimerController from WarmupPhaseScreen.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/window_mode_provider.dart';
import '../controllers/workout_timer_controller.dart';
import '../models/workout_state.dart';

/// Foldable-optimized warmup screen that splits content across the hinge.
class FoldableWarmupLayout extends StatefulWidget {
  /// Window mode state for hinge bounds calculation
  final WindowModeState windowState;

  /// Total workout time in seconds (continues counting during warmup)
  final int workoutSeconds;

  /// Warmup exercises to display
  final List<WarmupExerciseData> exercises;

  /// Callback when warmup is skipped
  final VoidCallback onSkipWarmup;

  /// Callback when warmup is completed
  final VoidCallback onWarmupComplete;

  /// Callback when quit is requested
  final VoidCallback onQuitRequested;

  const FoldableWarmupLayout({
    super.key,
    required this.windowState,
    required this.workoutSeconds,
    required this.exercises,
    required this.onSkipWarmup,
    required this.onWarmupComplete,
    required this.onQuitRequested,
  });

  @override
  State<FoldableWarmupLayout> createState() => _FoldableWarmupLayoutState();
}

class _FoldableWarmupLayoutState extends State<FoldableWarmupLayout> {
  int _currentExerciseIndex = 0;
  late PhaseTimerController _timerController;
  bool _isSwapped = false;

  @override
  void initState() {
    super.initState();
    _timerController = PhaseTimerController();
    _timerController.onTick = (_) => setState(() {});
    _timerController.onComplete = _handleTimerComplete;

    // Auto-start timer after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _startCurrentExerciseTimer();
      }
    });
  }

  @override
  void dispose() {
    _timerController.dispose();
    super.dispose();
  }

  void _startCurrentExerciseTimer() {
    final duration = widget.exercises[_currentExerciseIndex].duration;
    _timerController.start(duration);
    setState(() {});
  }

  void _handleTimerComplete() {
    _nextExercise();
  }

  void _nextExercise() {
    _timerController.stop();
    HapticFeedback.mediumImpact();

    if (_currentExerciseIndex < widget.exercises.length - 1) {
      setState(() {
        _currentExerciseIndex++;
      });
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _startCurrentExerciseTimer();
        }
      });
    } else {
      HapticFeedback.heavyImpact();
      widget.onWarmupComplete();
    }
  }

  void _toggleTimer() {
    if (_timerController.isRunning) {
      _timerController.pause();
    } else if (_timerController.secondsRemaining > 0) {
      _timerController.resume();
    } else {
      _startCurrentExerciseTimer();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final elevatedColor =
        isDark ? AppColors.elevated : AppColorsLight.elevated;

    final currentExercise = widget.exercises[_currentExerciseIndex];
    final warmupProgress =
        (_currentExerciseIndex + 1) / widget.exercises.length;

    // Hinge calculation (same pattern as FoldableQuizScaffold)
    final hingeBounds = widget.windowState.hingeBounds;
    final safeLeft = MediaQuery.of(context).padding.left;
    final rawHingeLeft =
        hingeBounds?.left ?? MediaQuery.of(context).size.width / 2;
    final hingeLeft =
        (rawHingeLeft - safeLeft).clamp(100.0, double.infinity);
    final hingeWidth = hingeBounds?.width ?? 0;
    final screenWidth = MediaQuery.of(context).size.width;
    final rightPaneWidth = screenWidth - hingeLeft - hingeWidth - safeLeft;

    // Build the two pane widgets
    final leftPaneWidget = _buildLeftPane(
      currentExercise,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
    );
    final rightPaneWidget = _buildRightPane(
      currentExercise,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      elevatedColor: elevatedColor,
    );

    final firstPane = _isSwapped ? rightPaneWidget : leftPaneWidget;
    final secondPane = _isSwapped ? leftPaneWidget : rightPaneWidget;
    final firstWidth = _isSwapped ? rightPaneWidth : hingeLeft;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          widget.onQuitRequested();
        }
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              // Top bar spanning full width
              _buildTopBar(
                textPrimary: textPrimary,
                elevatedColor: elevatedColor,
              ),

              const SizedBox(height: 8),

              // Progress bar spanning full width
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildProgressBar(warmupProgress, elevatedColor),
              ),

              const SizedBox(height: 12),

              // Main content: Pane 1 | Hinge + Swap | Pane 2
              Expanded(
                child: Stack(
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: firstWidth,
                          child: firstPane,
                        ),
                        SizedBox(width: hingeWidth),
                        Expanded(child: secondPane),
                      ],
                    ),

                    // Samsung-style swap button on hinge
                    Positioned(
                      left: hingeLeft + (hingeWidth / 2) - 20,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            setState(() => _isSwapped = !_isSwapped);
                          },
                          child: AnimatedRotation(
                            turns: _isSwapped ? 0.5 : 0.0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.grey.shade800
                                    : Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.15)
                                      : Colors.black.withValues(alpha: 0.08),
                                ),
                              ),
                              child: Icon(
                                Icons.swap_horiz_rounded,
                                size: 22,
                                color: isDark
                                    ? Colors.white
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Top Bar ─────────────────────────────────────────────────────────

  Widget _buildTopBar({
    required Color textPrimary,
    required Color elevatedColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: textPrimary),
            onPressed: widget.onQuitRequested,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: elevatedColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer, size: 16, color: AppColors.cyan),
                const SizedBox(width: 6),
                Text(
                  WorkoutTimerController.formatTime(widget.workoutSeconds),
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: widget.onSkipWarmup,
            child: const Text(
              'Skip Warmup',
              style: TextStyle(
                color: AppColors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(double progress, Color backgroundColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: progress,
        backgroundColor: backgroundColor,
        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.orange),
        minHeight: 6,
      ),
    );
  }

  // ─── Left Pane: Exercise Animation ───────────────────────────────────

  Widget _buildLeftPane(
    WarmupExerciseData exercise, {
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Exercise icon in circle
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.orange.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                exercise.icon,
                size: 56,
                color: AppColors.orange,
              ),
            )
                .animate()
                .fadeIn(duration: 300.ms)
                .scale(begin: const Offset(0.8, 0.8)),

            const SizedBox(height: 24),

            // Exercise name
            Text(
              exercise.name,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(duration: 300.ms, delay: 100.ms),

            const SizedBox(height: 16),

            // Countdown timer or duration
            if (_timerController.isRunning ||
                _timerController.secondsRemaining > 0)
              Text(
                WorkoutTimerController.formatTime(
                    _timerController.secondsRemaining),
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w300,
                  color: AppColors.orange,
                ),
              )
                  .animate(onPlay: (controller) => controller.repeat())
                  .shimmer(
                      duration: 2000.ms,
                      color: AppColors.orange.withOpacity(0.3))
            else
              Text(
                '${exercise.duration} sec',
                style: TextStyle(
                  fontSize: 22,
                  color: textSecondary,
                ),
              ),

            // Cardio equipment params
            if (exercise.isCardioEquipment) ...[
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppColors.orange.withOpacity(0.3)),
                ),
                child: Text(
                  exercise.cardioParamsDisplay,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: textPrimary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Right Pane: Progress + Controls + Upcoming ──────────────────────

  Widget _buildRightPane(
    WarmupExerciseData exercise, {
    required Color textPrimary,
    required Color textSecondary,
    required Color elevatedColor,
  }) {
    final isTimerRunning = _timerController.isRunning;
    final hasTimeRemaining = _timerController.secondsRemaining > 0;
    final isLastExercise =
        _currentExerciseIndex >= widget.exercises.length - 1;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // WARM UP header with exercise counter
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.whatshot,
                  color: AppColors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'WARM UP',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.orange,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_currentExerciseIndex + 1} of ${widget.exercises.length}',
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const Spacer(),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _toggleTimer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isTimerRunning
                        ? AppColors.orange.withOpacity(0.3)
                        : AppColors.orange,
                    foregroundColor:
                        isTimerRunning ? AppColors.orange : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: Icon(
                    isTimerRunning
                        ? Icons.pause
                        : (hasTimeRemaining
                            ? Icons.play_arrow
                            : Icons.timer),
                  ),
                  label: Text(
                    isTimerRunning
                        ? 'Pause'
                        : (hasTimeRemaining ? 'Resume' : 'Start Timer'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _nextExercise,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: Icon(
                      isLastExercise ? Icons.check : Icons.skip_next),
                  label: Text(
                    isLastExercise ? 'Start Workout' : 'Next',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Upcoming exercises
          if (_currentExerciseIndex < widget.exercises.length - 1) ...[
            Text(
              'UP NEXT',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textSecondary,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount:
                    widget.exercises.length - _currentExerciseIndex - 1,
                itemBuilder: (context, index) {
                  final upcomingExercise =
                      widget.exercises[_currentExerciseIndex + 1 + index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: elevatedColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          upcomingExercise.icon,
                          size: 20,
                          color: textSecondary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                upcomingExercise.name,
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                              if (upcomingExercise.isCardioEquipment)
                                Text(
                                  upcomingExercise.cardioParamsDisplay,
                                  style: TextStyle(
                                    color: textSecondary.withOpacity(0.7),
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          '${upcomingExercise.duration}s',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ] else
            const Spacer(),
        ],
      ),
    );
  }
}
