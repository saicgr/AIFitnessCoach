import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

/// Controller for warmup phase logic
class WarmupController {
  Timer? _timer;
  int _currentIndex = 0;
  int _secondsRemaining = 0;
  bool _isRunning = false;
  final VoidCallback onStateChanged;
  final VoidCallback onComplete;
  final List<Map<String, dynamic>> exercises;

  WarmupController({
    required this.exercises,
    required this.onStateChanged,
    required this.onComplete,
  });

  int get currentIndex => _currentIndex;
  int get secondsRemaining => _secondsRemaining;
  bool get isRunning => _isRunning;
  Map<String, dynamic> get currentExercise => exercises[_currentIndex];
  double get progress => (_currentIndex + 1) / exercises.length;
  bool get isLastExercise => _currentIndex >= exercises.length - 1;

  void startTimer() {
    final duration = exercises[_currentIndex]['duration'] as int;
    _secondsRemaining = duration;
    _isRunning = true;
    onStateChanged();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        _secondsRemaining--;
        onStateChanged();

        if (_secondsRemaining <= 3 && _secondsRemaining > 0) {
          HapticFeedback.lightImpact();
        }
      } else {
        nextExercise();
      }
    });
  }

  void pauseTimer() {
    _timer?.cancel();
    _isRunning = false;
    onStateChanged();
  }

  void resumeTimer() {
    if (_secondsRemaining > 0) {
      _isRunning = true;
      onStateChanged();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
          onStateChanged();
        } else {
          nextExercise();
        }
      });
    }
  }

  void nextExercise() {
    _timer?.cancel();
    HapticFeedback.mediumImpact();

    if (_currentIndex < exercises.length - 1) {
      _currentIndex++;
      _isRunning = false;
      _secondsRemaining = 0;
      onStateChanged();

      // Auto-start timer for next exercise
      Future.delayed(const Duration(milliseconds: 300), () {
        startTimer();
      });
    } else {
      finish();
    }
  }

  void skip() {
    _timer?.cancel();
    finish();
  }

  void finish() {
    HapticFeedback.heavyImpact();
    _isRunning = false;
    onComplete();
  }

  void dispose() {
    _timer?.cancel();
  }
}

/// Warmup phase screen widget
class WarmupPhaseScreen extends StatelessWidget {
  final WarmupController controller;
  final int workoutSeconds;
  final VoidCallback onQuit;
  final String Function(int) formatTime;

  const WarmupPhaseScreen({
    super.key,
    required this.controller,
    required this.workoutSeconds,
    required this.onQuit,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.background;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final currentWarmup = controller.currentExercise;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) onQuit();
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top bar
                _buildTopBar(textPrimary, elevatedColor),
                const SizedBox(height: 24),

                // Header
                _buildHeader(textSecondary),
                const SizedBox(height: 16),

                // Progress bar
                _buildProgressBar(elevatedColor),
                const Spacer(),

                // Current exercise
                _buildCurrentExercise(currentWarmup, textPrimary, textSecondary),
                const Spacer(),

                // Upcoming exercises
                if (!controller.isLastExercise)
                  _buildUpcoming(textSecondary, elevatedColor),

                // Action buttons
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(Color textPrimary, Color elevatedColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: onQuit,
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
                formatTime(workoutSeconds),
                style: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: controller.skip,
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

  Widget _buildHeader(Color textSecondary) {
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
              '${controller.currentIndex + 1} of ${controller.exercises.length}',
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

  Widget _buildProgressBar(Color elevatedColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: controller.progress,
        backgroundColor: elevatedColor,
        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.orange),
        minHeight: 6,
      ),
    );
  }

  Widget _buildCurrentExercise(
    Map<String, dynamic> currentWarmup,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.orange.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              currentWarmup['icon'] as IconData,
              size: 64,
              color: AppColors.orange,
            ),
          ).animate()
            .fadeIn(duration: 300.ms)
            .scale(begin: const Offset(0.8, 0.8)),
          const SizedBox(height: 32),
          Text(
            currentWarmup['name'] as String,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
            textAlign: TextAlign.center,
          ).animate()
            .fadeIn(duration: 300.ms, delay: 100.ms),
          const SizedBox(height: 16),
          if (controller.isRunning || controller.secondsRemaining > 0)
            Text(
              formatTime(controller.secondsRemaining),
              style: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.w300,
                color: AppColors.orange,
              ),
            ).animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 2000.ms, color: AppColors.orange.withOpacity(0.3))
          else
            Text(
              '${currentWarmup['duration']} sec',
              style: TextStyle(
                fontSize: 24,
                color: textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUpcoming(Color textSecondary, Color elevatedColor) {
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
            itemCount: controller.exercises.length - controller.currentIndex - 1,
            itemBuilder: (context, index) {
              final warmup = controller.exercises[controller.currentIndex + 1 + index];
              return Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: elevatedColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      warmup['icon'] as IconData,
                      size: 20,
                      color: textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      warmup['name'] as String,
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
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              if (controller.isRunning) {
                controller.pauseTimer();
              } else if (controller.secondsRemaining > 0) {
                controller.resumeTimer();
              } else {
                controller.startTimer();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: controller.isRunning
                  ? AppColors.orange.withOpacity(0.3)
                  : AppColors.orange,
              foregroundColor: controller.isRunning
                  ? AppColors.orange
                  : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: Icon(
              controller.isRunning
                  ? Icons.pause
                  : (controller.secondsRemaining > 0 ? Icons.play_arrow : Icons.timer),
            ),
            label: Text(
              controller.isRunning
                  ? 'Pause'
                  : (controller.secondsRemaining > 0 ? 'Resume' : 'Start Timer'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: controller.nextExercise,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cyan,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: Icon(
              controller.isLastExercise ? Icons.check : Icons.skip_next,
            ),
            label: Text(
              controller.isLastExercise ? 'Start Workout' : 'Next',
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
