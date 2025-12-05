import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/workout.dart';
import '../../data/models/exercise.dart';
import '../../data/repositories/workout_repository.dart';

class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  final Workout workout;

  const ActiveWorkoutScreen({super.key, required this.workout});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  // Workout state
  int _currentExerciseIndex = 0;
  int _currentSet = 1;
  bool _isResting = false;
  bool _isPaused = false;
  bool _isComplete = false;

  // Timers
  Timer? _workoutTimer;
  Timer? _restTimer;
  int _workoutSeconds = 0;
  int _restSecondsRemaining = 0;

  // Tracking
  final Map<int, List<bool>> _completedSets = {};
  int _totalCaloriesBurned = 0;

  @override
  void initState() {
    super.initState();
    _startWorkoutTimer();
    // Initialize completed sets tracking
    for (int i = 0; i < widget.workout.exercises.length; i++) {
      _completedSets[i] = [];
    }
  }

  @override
  void dispose() {
    _workoutTimer?.cancel();
    _restTimer?.cancel();
    super.dispose();
  }

  void _startWorkoutTimer() {
    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          _workoutSeconds++;
          // Estimate calories: ~6 cal per minute for moderate workout
          _totalCaloriesBurned = (_workoutSeconds / 60 * 6).round();
        });
      }
    });
  }

  void _startRestTimer(int seconds) {
    setState(() {
      _isResting = true;
      _restSecondsRemaining = seconds;
    });

    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused && _restSecondsRemaining > 0) {
        setState(() {
          _restSecondsRemaining--;
        });
        if (_restSecondsRemaining == 0) {
          _endRest();
        }
      }
    });

    // Haptic feedback
    HapticFeedback.mediumImpact();
  }

  void _endRest() {
    _restTimer?.cancel();
    setState(() {
      _isResting = false;
      _restSecondsRemaining = 0;
    });
    HapticFeedback.lightImpact();
  }

  void _completeSet() {
    final exercise = widget.workout.exercises[_currentExerciseIndex];
    final totalSets = exercise.sets ?? 3;

    setState(() {
      _completedSets[_currentExerciseIndex]!.add(true);
    });

    HapticFeedback.mediumImpact();

    if (_currentSet < totalSets) {
      // More sets remaining - start rest timer
      setState(() {
        _currentSet++;
      });
      final restTime = exercise.restSeconds ?? 90;
      _startRestTimer(restTime);
    } else {
      // All sets complete - move to next exercise
      _moveToNextExercise();
    }
  }

  void _moveToNextExercise() {
    if (_currentExerciseIndex < widget.workout.exercises.length - 1) {
      setState(() {
        _currentExerciseIndex++;
        _currentSet = 1;
        _isResting = false;
      });
      HapticFeedback.heavyImpact();
    } else {
      // Workout complete!
      _completeWorkout();
    }
  }

  void _skipExercise() {
    _moveToNextExercise();
  }

  Future<void> _completeWorkout() async {
    _workoutTimer?.cancel();
    _restTimer?.cancel();

    setState(() {
      _isComplete = true;
    });

    try {
      final workoutRepo = ref.read(workoutRepositoryProvider);
      if (widget.workout.id != null) {
        await workoutRepo.completeWorkout(widget.workout.id!);
      }
    } catch (e) {
      debugPrint('Failed to complete workout: $e');
    }

    // Navigate to completion screen
    if (mounted) {
      context.go('/workout-complete', extra: {
        'workout': widget.workout,
        'duration': _workoutSeconds,
        'calories': _totalCaloriesBurned,
      });
    }
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
    HapticFeedback.selectionClick();
  }

  void _showQuitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.elevated,
        title: const Text('Quit Workout?'),
        content: const Text(
          'Your progress will not be saved. Are you sure you want to quit?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/home');
            },
            child: const Text(
              'Quit',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final exercises = widget.workout.exercises;
    final currentExercise = exercises[_currentExerciseIndex];
    final progress = (_currentExerciseIndex + 1) / exercises.length;

    return WillPopScope(
      onWillPop: () async {
        _showQuitDialog();
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.pureBlack,
        body: SafeArea(
          child: Column(
            children: [
              // Top bar
              _TopBar(
                workoutName: widget.workout.name ?? 'Workout',
                currentExercise: _currentExerciseIndex + 1,
                totalExercises: exercises.length,
                progress: progress,
                isPaused: _isPaused,
                onPause: _togglePause,
                onQuit: _showQuitDialog,
              ),

              // Timer bar
              _TimerBar(
                workoutTime: _formatTime(_workoutSeconds),
                calories: _totalCaloriesBurned,
                isPaused: _isPaused,
              ),

              // Rest timer overlay
              if (_isResting)
                _RestTimerBanner(
                  secondsRemaining: _restSecondsRemaining,
                  onSkip: _endRest,
                ).animate().fadeIn().slideY(begin: -0.1),

              // Main exercise content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Exercise GIF
                      _ExerciseDisplay(exercise: currentExercise),

                      // Exercise info
                      _ExerciseInfo(
                        exercise: currentExercise,
                        currentSet: _currentSet,
                      ),

                      // Set indicators
                      _SetIndicators(
                        totalSets: currentExercise.sets ?? 3,
                        currentSet: _currentSet,
                        completedSets: _completedSets[_currentExerciseIndex]!.length,
                      ),

                      // Instructions
                      if (currentExercise.notes != null &&
                          currentExercise.notes!.isNotEmpty)
                        _InstructionCard(notes: currentExercise.notes!),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),

              // Bottom action buttons
              _BottomActions(
                isResting: _isResting,
                onComplete: _isResting ? _endRest : _completeSet,
                onSkip: _skipExercise,
                currentSet: _currentSet,
                totalSets: currentExercise.sets ?? 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Top Bar
// ─────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final String workoutName;
  final int currentExercise;
  final int totalExercises;
  final double progress;
  final bool isPaused;
  final VoidCallback onPause;
  final VoidCallback onQuit;

  const _TopBar({
    required this.workoutName,
    required this.currentExercise,
    required this.totalExercises,
    required this.progress,
    required this.isPaused,
    required this.onPause,
    required this.onQuit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onQuit,
                icon: const Icon(Icons.close),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.glassSurface,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workoutName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Exercise $currentExercise of $totalExercises',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onPause,
                icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
                style: IconButton.styleFrom(
                  backgroundColor: isPaused
                      ? AppColors.cyan.withOpacity(0.2)
                      : AppColors.glassSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.glassSurface,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.cyan),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Timer Bar
// ─────────────────────────────────────────────────────────────────

class _TimerBar extends StatelessWidget {
  final String workoutTime;
  final int calories;
  final bool isPaused;

  const _TimerBar({
    required this.workoutTime,
    required this.calories,
    required this.isPaused,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.elevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Row(
            children: [
              Icon(
                Icons.timer_outlined,
                size: 20,
                color: isPaused ? AppColors.textMuted : AppColors.cyan,
              ),
              const SizedBox(width: 8),
              Text(
                workoutTime,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: isPaused ? AppColors.textMuted : AppColors.textPrimary,
                ),
              ),
              if (isPaused)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Text(
                    'PAUSED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.orange,
                    ),
                  ),
                ),
            ],
          ),
          Container(
            width: 1,
            height: 24,
            color: AppColors.cardBorder,
          ),
          Row(
            children: [
              const Icon(
                Icons.local_fire_department,
                size: 20,
                color: AppColors.orange,
              ),
              const SizedBox(width: 8),
              Text(
                '$calories',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                ' cal',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Rest Timer Banner
// ─────────────────────────────────────────────────────────────────

class _RestTimerBanner extends StatelessWidget {
  final int secondsRemaining;
  final VoidCallback onSkip;

  const _RestTimerBanner({
    required this.secondsRemaining,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.purple.withOpacity(0.3),
            AppColors.purple.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.purple.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          const Text(
            'REST TIME',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.purple,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${secondsRemaining}s',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onSkip,
            icon: const Icon(Icons.skip_next),
            label: const Text('Skip Rest'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.purple,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Exercise Display
// ─────────────────────────────────────────────────────────────────

class _ExerciseDisplay extends StatelessWidget {
  final WorkoutExercise exercise;

  const _ExerciseDisplay({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 250,
      decoration: BoxDecoration(
        color: AppColors.elevated,
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.hardEdge,
      child: exercise.gifUrl != null && exercise.gifUrl!.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: exercise.gifUrl!,
              fit: BoxFit.contain,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(color: AppColors.cyan),
              ),
              errorWidget: (context, url, error) => const Center(
                child: Icon(
                  Icons.fitness_center,
                  size: 64,
                  color: AppColors.textMuted,
                ),
              ),
            )
          : const Center(
              child: Icon(
                Icons.fitness_center,
                size: 64,
                color: AppColors.textMuted,
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Exercise Info
// ─────────────────────────────────────────────────────────────────

class _ExerciseInfo extends StatelessWidget {
  final WorkoutExercise exercise;
  final int currentSet;

  const _ExerciseInfo({
    required this.exercise,
    required this.currentSet,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Text(
            exercise.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _InfoPill(
                label: 'Set',
                value: '$currentSet/${exercise.sets}',
                color: AppColors.cyan,
              ),
              const SizedBox(width: 12),
              _InfoPill(
                label: exercise.reps != null ? 'Reps' : 'Time',
                value: exercise.reps != null
                    ? '${exercise.reps}'
                    : '${exercise.durationSeconds}s',
                color: AppColors.purple,
              ),
              if (exercise.weight != null) ...[
                const SizedBox(width: 12),
                _InfoPill(
                  label: 'Weight',
                  value: '${exercise.weight} kg',
                  color: AppColors.orange,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Set Indicators
// ─────────────────────────────────────────────────────────────────

class _SetIndicators extends StatelessWidget {
  final int totalSets;
  final int currentSet;
  final int completedSets;

  const _SetIndicators({
    required this.totalSets,
    required this.currentSet,
    required this.completedSets,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(totalSets, (index) {
          final isCompleted = index < completedSets;
          final isCurrent = index == completedSets;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isCurrent ? 24 : 12,
            height: 12,
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppColors.success
                  : isCurrent
                      ? AppColors.cyan
                      : AppColors.glassSurface,
              borderRadius: BorderRadius.circular(6),
            ),
            child: isCompleted
                ? const Icon(Icons.check, size: 10, color: Colors.white)
                : null,
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Instruction Card
// ─────────────────────────────────────────────────────────────────

class _InstructionCard extends StatelessWidget {
  final String notes;

  const _InstructionCard({required this.notes});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.elevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline,
            size: 20,
            color: AppColors.orange,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              notes,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Bottom Actions
// ─────────────────────────────────────────────────────────────────

class _BottomActions extends StatelessWidget {
  final bool isResting;
  final VoidCallback onComplete;
  final VoidCallback onSkip;
  final int currentSet;
  final int totalSets;

  const _BottomActions({
    required this.isResting,
    required this.onComplete,
    required this.onSkip,
    required this.currentSet,
    required this.totalSets,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.nearBlack,
        border: Border(
          top: BorderSide(color: AppColors.cardBorder.withOpacity(0.5)),
        ),
      ),
      child: Row(
        children: [
          // Skip button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onSkip,
              icon: const Icon(Icons.skip_next),
              label: const Text('Skip'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: AppColors.cardBorder),
                foregroundColor: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Complete set button
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: onComplete,
              icon: Icon(
                isResting ? Icons.skip_next : Icons.check,
              ),
              label: Text(
                isResting
                    ? 'Skip Rest'
                    : currentSet == totalSets
                        ? 'Complete Exercise'
                        : 'Complete Set',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: isResting ? AppColors.purple : AppColors.cyan,
                foregroundColor: isResting ? Colors.white : AppColors.pureBlack,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
