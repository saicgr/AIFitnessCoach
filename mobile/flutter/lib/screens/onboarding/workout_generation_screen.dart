import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/workout.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/services/api_client.dart';
import '../../widgets/glass_back_button.dart';
import '../../widgets/gradient_circular_progress_indicator.dart';
import 'pre_auth_quiz_screen.dart';
import 'program_summary_screen.dart';

/// Full-screen workout generation screen with animated progress steps
/// Similar to the diet plan generation screen
class WorkoutGenerationScreen extends ConsumerStatefulWidget {
  final bool showBackButton;
  final bool returnWorkout; // If true, pops with the generated workout instead of navigating to home

  const WorkoutGenerationScreen({
    super.key,
    this.showBackButton = true,
    this.returnWorkout = false,
  });

  @override
  ConsumerState<WorkoutGenerationScreen> createState() => _WorkoutGenerationScreenState();
}

class _WorkoutGenerationScreenState extends ConsumerState<WorkoutGenerationScreen>
    with SingleTickerProviderStateMixin {
  // Generation state
  bool _isGenerating = true;
  String? _errorMessage;
  int _currentStep = 0;
  double _progress = 0.0;
  Workout? _generatedWorkout; // Store the generated workout

  // Steps with their completion status
  final List<_GenerationStep> _steps = [
    _GenerationStep(
      title: 'Analyzing your fitness profile',
      icon: Icons.person_search,
    ),
    _GenerationStep(
      title: 'Designing your training split',
      icon: Icons.calendar_today,
    ),
    _GenerationStep(
      title: 'Selecting exercises for your goals',
      icon: Icons.fitness_center,
    ),
    _GenerationStep(
      title: 'Optimizing workout structure',
      icon: Icons.auto_awesome,
    ),
    _GenerationStep(
      title: 'Generating your personalized plan',
      icon: Icons.rocket_launch,
    ),
  ];

  late AnimationController _progressController;
  StreamSubscription<WorkoutGenerationProgress>? _generationSubscription;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Check if a background generation is already available
    Future.delayed(const Duration(milliseconds: 500), _checkBackgroundOrGenerate);
  }

  /// Check if background generation from onboarding is already complete.
  /// If so, use the pre-generated workout. Otherwise, start fresh generation.
  Future<void> _checkBackgroundOrGenerate() async {
    final bgCompleter = ref.read(backgroundGenerationProvider);
    if (bgCompleter != null) {
      // Start animating steps while waiting
      _animateSteps();

      try {
        // Wait for the background generation with a timeout
        final workout = await bgCompleter.future.timeout(
          const Duration(seconds: 90),
          onTimeout: () => null,
        );

        // Clear the provider so it's not reused
        ref.read(backgroundGenerationProvider.notifier).state = null;

        if (workout != null && mounted) {
          debugPrint('✅ [WorkoutGeneration] Using pre-generated workout: ${workout.name}');
          setState(() {
            _generatedWorkout = workout;
            _progress = 1.0;
            _currentStep = _steps.length;
            _isGenerating = false;
          });

          // Navigate after showing completion
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) {
              if (widget.returnWorkout) {
                Navigator.of(context).pop(_generatedWorkout);
              } else {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const ProgramSummaryScreen()),
                );
              }
            }
          });
          return;
        }
      } catch (e) {
        debugPrint('⚠️ [WorkoutGeneration] Background generation failed, starting fresh: $e');
        ref.read(backgroundGenerationProvider.notifier).state = null;
      }
    }

    // No background generation or it failed - start fresh
    _startGeneration();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _generationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startGeneration() async {
    try {
      // Get user data
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId == null) {
        setState(() {
          _errorMessage = 'User not found. Please try again.';
          _isGenerating = false;
        });
        return;
      }

      // Get quiz data for workout preferences
      final quizData = ref.read(preAuthQuizProvider);
      final workoutDuration = quizData.workoutDuration ?? 45;

      // Calculate duration range based on selected duration
      // This ensures AI generates workouts within the time constraint
      int? durationMin;
      int? durationMax;

      if (workoutDuration == 30) {
        // <30 min range
        durationMin = null;
        durationMax = 30;
      } else if (workoutDuration == 45) {
        // 30-45 min range
        durationMin = 30;
        durationMax = 45;
      } else if (workoutDuration == 60) {
        // 45-60 min range
        durationMin = 45;
        durationMax = 60;
      } else if (workoutDuration == 75) {
        // 60-75 min range
        durationMin = 60;
        durationMax = 75;
      } else if (workoutDuration == 90) {
        // 75-90 min range
        durationMin = 75;
        durationMax = 90;
      }

      // Simulate step progression while waiting for stream
      _animateSteps();

      // Start streaming single workout generation
      final repository = ref.read(workoutRepositoryProvider);
      // Pass the client's local date so the workout is scheduled for "today"
      // in the user's timezone, not the server's UTC date
      final todayLocal = DateTime.now().toIso8601String().substring(0, 10);
      final stream = repository.generateWorkoutStreaming(
        userId: userId,
        durationMinutes: workoutDuration,
        durationMinutesMin: durationMin,
        durationMinutesMax: durationMax,
        scheduledDate: todayLocal,
      );

      _generationSubscription = stream.listen(
        (progress) {
          if (!mounted) return;

          setState(() {
            // Update progress based on status
            if (progress.status == WorkoutGenerationStatus.completed) {
              _progress = 1.0;
              _currentStep = _steps.length;
              // Store the generated workout
              if (progress.workout != null) {
                _generatedWorkout = progress.workout;
              }
            } else if (progress.status == WorkoutGenerationStatus.progress) {
              _progress = 0.5;
              if (_currentStep < 4) {
                _currentStep = 4;
              }
            }
          });
        },
        onError: (error) {
          debugPrint('❌ [WorkoutGeneration] Error: $error');
          if (mounted) {
            setState(() {
              _errorMessage = 'Failed to generate workout. Please try again.';
              _isGenerating = false;
            });
          }
        },
        onDone: () {
          debugPrint('✅ [WorkoutGeneration] Complete!');
          if (mounted) {
            setState(() {
              _isGenerating = false;
              _currentStep = _steps.length;
              _progress = 1.0;
            });

            // If returnWorkout is true, pop with the generated workout
            // Otherwise, navigate to program summary after showing completion
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (mounted) {
                if (widget.returnWorkout) {
                  Navigator.of(context).pop(_generatedWorkout);
                } else {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const ProgramSummaryScreen()),
                  );
                }
              }
            });
          }
        },
      );
    } catch (e) {
      debugPrint('❌ [WorkoutGeneration] Exception: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Something went wrong. Please try again.';
          _isGenerating = false;
        });
      }
    }
  }

  Future<void> _animateSteps() async {
    // Animate through initial steps
    for (int i = 0; i < 4 && mounted && _isGenerating; i++) {
      await Future.delayed(Duration(milliseconds: 800 + (i * 200)));
      if (mounted && _currentStep < 4) {
        setState(() {
          _currentStep = i + 1;
          _steps[i].isComplete = true;
        });
      }
    }
  }

  void _retry() {
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _currentStep = 0;
      _progress = 0.0;
      for (var step in _steps) {
        step.isComplete = false;
      }
    });
    _startGeneration();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Back button (conditionally shown)
            if (widget.showBackButton)
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GlassBackButton(
                    onTap: () {
                      if (widget.returnWorkout) {
                        Navigator.of(context).pop();
                      } else {
                        context.go('/coach-selection');
                      }
                    },
                  ),
                ),
              ),

            // Main content - centered with max width for wide/foldable displays
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: _errorMessage != null
                      ? _buildErrorState(isDark, textPrimary, textSecondary)
                      : _buildGeneratingState(isDark, textPrimary, textSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneratingState(bool isDark, Color textPrimary, Color textSecondary) {
    final accentColor = isDark ? AppColors.orange : AppColorsLight.orange;
    final accentColorLight = isDark ? AppColors.orangeLight : AppColorsLight.orangeLight;

    // Current step label
    final stepLabel = _currentStep < _steps.length
        ? _steps[_currentStep].title
        : 'Finalizing your plan';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Large animated progress ring with glow
        AnimatedBuilder(
          animation: _progressController,
          builder: (context, child) {
            // Subtle pulsing glow while generating (oscillates 0.1 - 0.25)
            final pulse = _progressController.value < 0.5
                ? _progressController.value * 2
                : 2 - _progressController.value * 2;
            final glowOpacity = _isGenerating ? 0.1 + 0.15 * pulse : 0.0;

            return Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: _isGenerating
                    ? [
                        BoxShadow(
                          color: accentColor.withValues(alpha: glowOpacity),
                          blurRadius: 40,
                          spreadRadius: 8,
                        ),
                      ]
                    : null,
              ),
              child: child,
            );
          },
          child: SizedBox(
            width: 240,
            height: 240,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background track
                GradientCircularProgressIndicator(
                  size: 240,
                  strokeWidth: 12,
                  value: 1.0,
                  gradientColors: [
                    isDark ? AppColors.elevated : AppColorsLight.elevated,
                    isDark ? AppColors.elevated : AppColorsLight.elevated,
                  ],
                  backgroundColor: Colors.transparent,
                ),
                // Progress arc
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: _progress),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return GradientCircularProgressIndicator(
                      size: 240,
                      strokeWidth: 12,
                      value: value > 0 ? value : null,
                      gradientColors: [accentColor, accentColorLight],
                      backgroundColor: Colors.transparent,
                      strokeCap: StrokeCap.round,
                    );
                  },
                ),
                // Center content: percentage + completion icon
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_progress >= 1.0)
                      Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.success,
                        size: 32,
                      )
                    else
                      Icon(
                        _currentStep < _steps.length ? _steps[_currentStep].icon : Icons.auto_awesome,
                        color: accentColor.withValues(alpha: 0.5),
                        size: 28,
                      ),
                    const SizedBox(height: 8),
                    Text(
                      '${(_progress * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Title
        Text(
          _progress >= 1.0 ? 'Workout Ready!' : 'Generating Your Plan',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),

        const SizedBox(height: 12),

        // Current step label
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            stepLabel,
            key: ValueKey(stepLabel),
            style: TextStyle(
              fontSize: 15,
              color: textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(bool isDark, Color textPrimary, Color textSecondary) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                color: AppColors.error,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Generation Failed',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Something went wrong',
              style: TextStyle(
                fontSize: 15,
                color: textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _retry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GenerationStep {
  final String title;
  final IconData icon;
  bool isComplete;

  _GenerationStep({
    required this.title,
    required this.icon,
  }) : isComplete = false;
}
