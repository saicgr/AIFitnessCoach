import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/providers/today_workout_provider.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/services/api_client.dart';
import 'pre_auth_quiz_screen.dart';

/// Full-screen workout generation screen with animated progress steps
/// Similar to the diet plan generation screen
class WorkoutGenerationScreen extends ConsumerStatefulWidget {
  const WorkoutGenerationScreen({super.key});

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
  int _generatedWorkouts = 0;
  int _totalWorkouts = 0;

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
  StreamSubscription<ProgramGenerationProgress>? _generationSubscription;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Start generation after a short delay
    Future.delayed(const Duration(milliseconds: 500), _startGeneration);
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
      final selectedDays = quizData.workoutDays ?? [1, 3, 5]; // Default Mon/Wed/Fri
      final workoutDuration = quizData.workoutDuration ?? 45;

      // Only generate 1 workout (today's or next workout day)
      _totalWorkouts = 1;

      // Simulate step progression while waiting for stream
      _animateSteps();

      // Start streaming workout generation - only generate 1 workout
      final repository = ref.read(workoutRepositoryProvider);
      final stream = repository.generateMonthlyWorkoutsStreaming(
        userId: userId,
        selectedDays: selectedDays,
        durationMinutes: workoutDuration,
        maxWorkouts: 1, // Only generate today's or next workout day
      );

      _generationSubscription = stream.listen(
        (progress) {
          if (!mounted) return;

          setState(() {
            _generatedWorkouts = progress.currentWorkout;
            if (progress.totalWorkouts > 0) {
              _totalWorkouts = progress.totalWorkouts;
            }

            // Update progress based on workouts generated
            if (_totalWorkouts > 0) {
              _progress = _generatedWorkouts / _totalWorkouts;
            }

            // Move to generating step when workouts start appearing
            if (progress.currentWorkout > 0 && _currentStep < 4) {
              _currentStep = 4;
            }
          });
        },
        onError: (error) {
          debugPrint('❌ [WorkoutGeneration] Error: $error');
          if (mounted) {
            setState(() {
              _errorMessage = 'Failed to generate workouts. Please try again.';
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

            // Navigate to home after showing completion
            // Use a 1.5 second delay to:
            // 1. Show the completion UI to the user
            // 2. Allow the database write to fully propagate
            // This prevents a race condition where the home screen's /workouts/today
            // query runs before the workout is visible in the database.
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (mounted) {
                context.go('/home');
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
      _generatedWorkouts = 0;
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
            // Back button
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: IconButton(
                  onPressed: () => context.go('/coach-selection'),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.elevated : AppColorsLight.elevated,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.arrow_back,
                      color: textPrimary,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),

            // Main content
            Expanded(
              child: _errorMessage != null
                  ? _buildErrorState(isDark, textPrimary, textSecondary)
                  : _buildGeneratingState(isDark, textPrimary, textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneratingState(bool isDark, Color textPrimary, Color textSecondary) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Animated circular progress
        SizedBox(
          width: 160,
          height: 160,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background circle
              SizedBox(
                width: 160,
                height: 160,
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 8,
                  backgroundColor: isDark
                      ? AppColors.elevated
                      : AppColorsLight.elevated,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? AppColors.elevated : AppColorsLight.elevated,
                  ),
                ),
              ),
              // Progress circle
              SizedBox(
                width: 160,
                height: 160,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: _progress),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return CircularProgressIndicator(
                      value: value > 0 ? value : null,
                      strokeWidth: 8,
                      strokeCap: StrokeCap.round,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        const Color(0xFF4A5FC1), // Indigo blue like the screenshot
                      ),
                    );
                  },
                ),
              ),
              // Percentage text
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(_progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),

        // Title
        Text(
          'AI Coach is',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        Text(
          'generating',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        Text(
          'your Workout Plan',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 48),

        // Steps list
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            children: _steps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              final isActive = index == _currentStep;
              final isComplete = index < _currentStep || step.isComplete;
              final isPending = index > _currentStep;

              return _buildStepRow(
                step: step,
                isActive: isActive,
                isComplete: isComplete,
                isPending: isPending,
                progress: isActive && _totalWorkouts > 0
                    ? '${(_generatedWorkouts / _totalWorkouts * 100).toInt()}%'
                    : null,
                isDark: isDark,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              );
            }).toList(),
          ),
        ),

        if (_totalWorkouts > 1) ...[
          const SizedBox(height: 24),
          Text(
            '($_generatedWorkouts of $_totalWorkouts workouts)',
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStepRow({
    required _GenerationStep step,
    required bool isActive,
    required bool isComplete,
    required bool isPending,
    String? progress,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final checkColor = AppColors.success;
    final activeColor = const Color(0xFF4A5FC1);
    final pendingColor = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Status indicator
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isComplete
                  ? checkColor.withValues(alpha: 0.15)
                  : isActive
                      ? activeColor.withValues(alpha: 0.15)
                      : Colors.transparent,
              border: Border.all(
                color: isComplete
                    ? checkColor
                    : isActive
                        ? activeColor
                        : pendingColor.withValues(alpha: 0.3),
                width: isComplete || isActive ? 2 : 1,
              ),
            ),
            child: Center(
              child: isComplete
                  ? Icon(Icons.check, color: checkColor, size: 14)
                  : isActive
                      ? SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(activeColor),
                          ),
                        )
                      : null,
            ),
          ),
          const SizedBox(width: 12),

          // Step title
          Expanded(
            child: Text(
              step.title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isComplete || isActive ? textPrimary : pendingColor,
              ),
            ),
          ),

          // Progress percentage (if active)
          if (progress != null)
            Text(
              progress,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: activeColor,
              ),
            ),
        ],
      ),
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
                backgroundColor: AppColors.cyan,
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
