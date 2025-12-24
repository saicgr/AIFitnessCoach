/// Warmup phase screen widget
///
/// Displays the warmup exercises before the main workout begins.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../controllers/workout_timer_controller.dart';
import '../models/workout_state.dart';

/// Warmup phase screen displayed before the main workout
class WarmupPhaseScreen extends StatefulWidget {
  /// Total workout time in seconds (continues counting during warmup)
  final int workoutSeconds;

  /// Callback when warmup is skipped
  final VoidCallback onSkipWarmup;

  /// Callback when warmup is completed
  final VoidCallback onWarmupComplete;

  /// Callback when quit is requested
  final VoidCallback onQuitRequested;

  /// Warmup exercises to display
  final List<WarmupExerciseData> exercises;

  const WarmupPhaseScreen({
    super.key,
    required this.workoutSeconds,
    required this.onSkipWarmup,
    required this.onWarmupComplete,
    required this.onQuitRequested,
    this.exercises = defaultWarmupExercises,
  });

  @override
  State<WarmupPhaseScreen> createState() => _WarmupPhaseScreenState();
}

class _WarmupPhaseScreenState extends State<WarmupPhaseScreen> {
  int _currentExerciseIndex = 0;
  late PhaseTimerController _timerController;

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
      // Auto-start timer for next exercise
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _startCurrentExerciseTimer();
        }
      });
    } else {
      // Warmup complete
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

    final currentExercise = widget.exercises[_currentExerciseIndex];
    final warmupProgress =
        (_currentExerciseIndex + 1) / widget.exercises.length;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final elevatedColor =
        isDark ? AppColors.elevated : AppColorsLight.elevated;

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
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top bar with timer and skip
                _buildTopBar(
                  context,
                  textPrimary: textPrimary,
                  elevatedColor: elevatedColor,
                ),

                const SizedBox(height: 24),

                // Warmup header
                _buildHeader(textSecondary: textSecondary),

                const SizedBox(height: 16),

                // Progress bar
                _buildProgressBar(warmupProgress, elevatedColor),

                const Spacer(),

                // Current warmup exercise
                _buildCurrentExercise(
                  currentExercise,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),

                const Spacer(),

                // Upcoming warmup exercises
                if (_currentExerciseIndex < widget.exercises.length - 1)
                  _buildUpcomingExercises(
                    textSecondary: textSecondary,
                    elevatedColor: elevatedColor,
                  ),

                // Action buttons
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context, {
    required Color textPrimary,
    required Color elevatedColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Back button
        IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: widget.onQuitRequested,
        ),
        // Workout timer
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
        // Skip warmup button
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
    );
  }

  Widget _buildHeader({required Color textSecondary}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.orange.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.whatshot,
            color: AppColors.orange,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
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
            const SizedBox(height: 4),
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

  Widget _buildCurrentExercise(
    WarmupExerciseData exercise, {
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Center(
      child: Column(
        children: [
          // Exercise icon
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.orange.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              exercise.icon,
              size: 64,
              color: AppColors.orange,
            ),
          )
              .animate()
              .fadeIn(duration: 300.ms)
              .scale(begin: const Offset(0.8, 0.8)),

          const SizedBox(height: 32),

          // Exercise name
          Text(
            exercise.name,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 300.ms, delay: 100.ms),

          const SizedBox(height: 16),

          // Duration or timer
          if (_timerController.isRunning ||
              _timerController.secondsRemaining > 0)
            Text(
              WorkoutTimerController.formatTime(
                  _timerController.secondsRemaining),
              style: const TextStyle(
                fontSize: 64,
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
                fontSize: 24,
                color: textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUpcomingExercises({
    required Color textSecondary,
    required Color elevatedColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.exercises.length - _currentExerciseIndex - 1,
            itemBuilder: (context, index) {
              final exercise =
                  widget.exercises[_currentExerciseIndex + 1 + index];
              return Container(
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: elevatedColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      exercise.icon,
                      size: 20,
                      color: textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      exercise.name,
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildActionButtons() {
    final isTimerRunning = _timerController.isRunning;
    final hasTimeRemaining = _timerController.secondsRemaining > 0;
    final isLastExercise =
        _currentExerciseIndex >= widget.exercises.length - 1;

    return Row(
      children: [
        // Start/Pause timer button
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _toggleTimer,
            style: ElevatedButton.styleFrom(
              backgroundColor: isTimerRunning
                  ? AppColors.orange.withOpacity(0.3)
                  : AppColors.orange,
              foregroundColor: isTimerRunning ? AppColors.orange : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: Icon(
              isTimerRunning
                  ? Icons.pause
                  : (hasTimeRemaining ? Icons.play_arrow : Icons.timer),
            ),
            label: Text(
              isTimerRunning
                  ? 'Pause'
                  : (hasTimeRemaining ? 'Resume' : 'Start Timer'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Next/Done button
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _nextExercise,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cyan,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: Icon(isLastExercise ? Icons.check : Icons.skip_next),
            label: Text(
              isLastExercise ? 'Start Workout' : 'Next',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
