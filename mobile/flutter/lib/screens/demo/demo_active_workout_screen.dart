import 'dart:async';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/analytics_service.dart';

/// Workout phases for demo
enum DemoWorkoutPhase {
  warmup,
  active,
  stretch,
  complete,
}

/// Warmup exercise data for demo
class DemoWarmupExercise {
  final String name;
  final int duration;
  final IconData icon;
  final String tip;

  const DemoWarmupExercise({
    required this.name,
    required this.duration,
    required this.icon,
    required this.tip,
  });
}

/// Stretch exercise data for demo
class DemoStretchExercise {
  final String name;
  final int duration;
  final IconData icon;
  final String benefit;

  const DemoStretchExercise({
    required this.name,
    required this.duration,
    required this.icon,
    required this.benefit,
  });
}

/// Default warmup exercises with AI tips
const List<DemoWarmupExercise> _defaultWarmupExercises = [
  DemoWarmupExercise(
    name: 'Jumping Jacks',
    duration: 45,
    icon: Icons.directions_run,
    tip: 'Get your heart rate up and blood flowing to your muscles.',
  ),
  DemoWarmupExercise(
    name: 'Arm Circles',
    duration: 30,
    icon: Icons.loop,
    tip: 'Loosen up your shoulder joints to prevent injury.',
  ),
  DemoWarmupExercise(
    name: 'Hip Circles',
    duration: 30,
    icon: Icons.refresh,
    tip: 'Mobilize your hips for better range of motion.',
  ),
  DemoWarmupExercise(
    name: 'Leg Swings',
    duration: 30,
    icon: Icons.swap_horiz,
    tip: 'Dynamic stretching activates your leg muscles.',
  ),
];

/// Default stretch exercises with benefits
const List<DemoStretchExercise> _defaultStretchExercises = [
  DemoStretchExercise(
    name: 'Quad Stretch',
    duration: 30,
    icon: Icons.self_improvement,
    benefit: 'Reduces muscle tension and improves flexibility.',
  ),
  DemoStretchExercise(
    name: 'Hamstring Stretch',
    duration: 30,
    icon: Icons.self_improvement,
    benefit: 'Prevents lower back pain and improves posture.',
  ),
  DemoStretchExercise(
    name: 'Shoulder Stretch',
    duration: 30,
    icon: Icons.self_improvement,
    benefit: 'Releases tension from upper body exercises.',
  ),
  DemoStretchExercise(
    name: 'Cat-Cow Stretch',
    duration: 45,
    icon: Icons.self_improvement,
    benefit: 'Improves spine mobility and reduces stiffness.',
  ),
];

/// AI suggestions during rest periods
const List<String> _aiRestSuggestions = [
  'Great form on that last set! Focus on controlled movements.',
  'Remember to breathe steadily - exhale on the exertion.',
  'Stay hydrated! Take a sip of water if you need it.',
  'You\'re doing amazing! Keep up the intensity.',
  'Focus on mind-muscle connection for better results.',
  'Good pace! Rest allows your muscles to recover.',
  'Tip: Squeeze at the top of each rep for maximum engagement.',
  'Your consistency is building strength every session.',
  'Pro tip: Visualize the muscle working during each rep.',
  'Almost there! Push through these final sets.',
];

/// AI workout review messages based on performance
const Map<String, List<String>> _aiReviewMessages = {
  'excellent': [
    'Outstanding workout! You maintained great intensity throughout.',
    'Incredible performance! Your dedication is clearly paying off.',
    'Fantastic job! You crushed every exercise with perfect form.',
  ],
  'good': [
    'Solid workout! You\'re building a strong foundation.',
    'Great effort today! Consistency like this drives results.',
    'Well done! Keep showing up and you\'ll see amazing progress.',
  ],
  'starter': [
    'Great start! Every workout brings you closer to your goals.',
    'Nice work getting through the demo! Full workouts will transform you.',
    'Perfect introduction! You\'re ready for personalized training.',
  ],
};

/// Simplified active workout screen for demo/preview mode
/// Includes warmup, main workout, stretches, and AI features
class DemoActiveWorkoutScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> workout;
  final List<Map<String, dynamic>> exercises;

  const DemoActiveWorkoutScreen({
    super.key,
    required this.workout,
    required this.exercises,
  });

  @override
  ConsumerState<DemoActiveWorkoutScreen> createState() =>
      _DemoActiveWorkoutScreenState();
}

class _DemoActiveWorkoutScreenState
    extends ConsumerState<DemoActiveWorkoutScreen> {
  // Current phase
  DemoWorkoutPhase _phase = DemoWorkoutPhase.warmup;

  // Exercise tracking
  int _currentExerciseIndex = 0;
  int _currentSet = 1;
  bool _isResting = false;

  // Warmup/Stretch tracking
  int _currentWarmupIndex = 0;
  int _currentStretchIndex = 0;

  // Timers
  Timer? _workoutTimer;
  Timer? _phaseTimer;
  int _workoutSeconds = 0;
  int _phaseSecondsRemaining = 0;

  // Tracking
  final Map<int, int> _completedSets = {};
  int _totalSetsCompleted = 0;
  int _totalRepsCompleted = 0;

  // AI suggestion
  String _currentAiSuggestion = '';
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _startWorkoutTimer();
    _startWarmupPhase();
    _trackWorkoutStarted();
  }

  @override
  void dispose() {
    _workoutTimer?.cancel();
    _phaseTimer?.cancel();
    super.dispose();
  }

  void _startWorkoutTimer() {
    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _workoutSeconds++;
        });
      }
    });
  }

  void _trackWorkoutStarted() {
    try {
      final analytics = ref.read(analyticsServiceProvider);
      analytics.trackEvent(
        eventName: 'demo_workout_started',
        category: 'demo',
        properties: {
          'workout_name': widget.workout['name'] ?? 'Sample Workout',
          'exercise_count': widget.exercises.length,
        },
      );
    } catch (_) {}
  }

  void _trackWorkoutCompleted() {
    try {
      final analytics = ref.read(analyticsServiceProvider);
      analytics.trackEvent(
        eventName: 'demo_workout_completed',
        category: 'demo',
        properties: {
          'workout_name': widget.workout['name'] ?? 'Sample Workout',
          'duration_seconds': _workoutSeconds,
          'sets_completed': _totalSetsCompleted,
          'reps_completed': _totalRepsCompleted,
        },
      );
    } catch (_) {}
  }

  // ============ WARMUP PHASE ============

  void _startWarmupPhase() {
    setState(() {
      _phase = DemoWorkoutPhase.warmup;
      _currentWarmupIndex = 0;
    });
    _startWarmupExerciseTimer();
  }

  void _startWarmupExerciseTimer() {
    _phaseTimer?.cancel();
    final duration = _defaultWarmupExercises[_currentWarmupIndex].duration;
    setState(() {
      _phaseSecondsRemaining = duration;
    });

    _phaseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _phaseSecondsRemaining--;
          if (_phaseSecondsRemaining <= 0) {
            _nextWarmupExercise();
          }
        });
      }
    });
  }

  void _nextWarmupExercise() {
    _phaseTimer?.cancel();
    HapticFeedback.mediumImpact();

    if (_currentWarmupIndex < _defaultWarmupExercises.length - 1) {
      setState(() {
        _currentWarmupIndex++;
      });
      _startWarmupExerciseTimer();
    } else {
      // Warmup complete, start active phase
      _startActivePhase();
    }
  }

  void _skipWarmup() {
    _phaseTimer?.cancel();
    _startActivePhase();
  }

  // ============ ACTIVE PHASE ============

  void _startActivePhase() {
    setState(() {
      _phase = DemoWorkoutPhase.active;
      _currentExerciseIndex = 0;
      _currentSet = 1;
      _isResting = false;
    });
  }

  Map<String, dynamic> get _currentExercise =>
      widget.exercises[_currentExerciseIndex];

  int get _currentExerciseSets => _currentExercise['sets'] ?? 3;
  int get _currentExerciseReps => _currentExercise['reps'] ?? 12;
  int get _currentExerciseRestSeconds => _currentExercise['rest_seconds'] ?? 60;

  void _completeSet() {
    HapticFeedback.mediumImpact();

    setState(() {
      _completedSets[_currentExerciseIndex] =
          (_completedSets[_currentExerciseIndex] ?? 0) + 1;
      _totalSetsCompleted++;
      _totalRepsCompleted += _currentExerciseReps;

      if (_currentSet >= _currentExerciseSets) {
        // Exercise complete, move to next
        if (_currentExerciseIndex < widget.exercises.length - 1) {
          _startRest(isExerciseTransition: true);
        } else {
          // Main workout complete, start stretches
          _startStretchPhase();
        }
      } else {
        // More sets remaining
        _currentSet++;
        _startRest(isExerciseTransition: false);
      }
    });
  }

  void _startRest({required bool isExerciseTransition}) {
    // Generate AI suggestion for rest period
    _currentAiSuggestion =
        _aiRestSuggestions[_random.nextInt(_aiRestSuggestions.length)];

    setState(() {
      _isResting = true;
      _phaseSecondsRemaining =
          isExerciseTransition ? 90 : _currentExerciseRestSeconds;
    });

    _phaseTimer?.cancel();
    _phaseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _phaseSecondsRemaining--;
          if (_phaseSecondsRemaining <= 0) {
            _endRest(isExerciseTransition: isExerciseTransition);
          }
        });
      }
    });
  }

  void _endRest({required bool isExerciseTransition}) {
    _phaseTimer?.cancel();
    HapticFeedback.mediumImpact();

    setState(() {
      _isResting = false;
      if (isExerciseTransition) {
        _currentExerciseIndex++;
        _currentSet = 1;
      }
    });
  }

  void _skipRest() {
    _phaseTimer?.cancel();
    final wasExerciseTransition = _currentSet > _currentExerciseSets ||
        (_completedSets[_currentExerciseIndex] ?? 0) >= _currentExerciseSets;

    setState(() {
      _isResting = false;
      if (wasExerciseTransition &&
          _currentExerciseIndex < widget.exercises.length - 1) {
        _currentExerciseIndex++;
        _currentSet = 1;
      }
    });
  }

  // ============ STRETCH PHASE ============

  void _startStretchPhase() {
    _phaseTimer?.cancel();
    setState(() {
      _phase = DemoWorkoutPhase.stretch;
      _currentStretchIndex = 0;
    });
    _startStretchExerciseTimer();
  }

  void _startStretchExerciseTimer() {
    _phaseTimer?.cancel();
    final duration = _defaultStretchExercises[_currentStretchIndex].duration;
    setState(() {
      _phaseSecondsRemaining = duration;
    });

    _phaseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _phaseSecondsRemaining--;
          if (_phaseSecondsRemaining <= 0) {
            _nextStretchExercise();
          }
        });
      }
    });
  }

  void _nextStretchExercise() {
    _phaseTimer?.cancel();
    HapticFeedback.mediumImpact();

    if (_currentStretchIndex < _defaultStretchExercises.length - 1) {
      setState(() {
        _currentStretchIndex++;
      });
      _startStretchExerciseTimer();
    } else {
      // Stretches complete, show completion
      _completeWorkout();
    }
  }

  void _skipStretches() {
    _phaseTimer?.cancel();
    _completeWorkout();
  }

  // ============ COMPLETION ============

  void _completeWorkout() {
    _workoutTimer?.cancel();
    _phaseTimer?.cancel();
    _trackWorkoutCompleted();

    setState(() {
      _phase = DemoWorkoutPhase.complete;
    });
  }

  String _getAiWorkoutReview() {
    final setsPerExercise =
        widget.exercises.isNotEmpty ? _totalSetsCompleted / widget.exercises.length : 0;

    String category;
    if (setsPerExercise >= 3) {
      category = 'excellent';
    } else if (setsPerExercise >= 2) {
      category = 'good';
    } else {
      category = 'starter';
    }

    final messages = _aiReviewMessages[category]!;
    return messages[_random.nextInt(messages.length)];
  }

  void _exitWorkout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            Theme.of(context).brightness == Brightness.dark
                ? AppColors.elevated
                : Colors.white,
        title: const Text('Exit Workout?'),
        content: const Text(
          'Your progress in this demo workout won\'t be saved. Are you sure you want to exit?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            child: Text(
              'Exit',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (_phase) {
      case DemoWorkoutPhase.warmup:
        return _buildWarmupScreen(isDark);
      case DemoWorkoutPhase.active:
        if (_isResting) {
          return _buildRestScreen(isDark);
        }
        return _buildWorkoutScreen(isDark);
      case DemoWorkoutPhase.stretch:
        return _buildStretchScreen(isDark);
      case DemoWorkoutPhase.complete:
        return _buildCompletionScreen(isDark);
    }
  }

  // ============ WARMUP UI ============

  Widget _buildWarmupScreen(bool isDark) {
    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    final currentExercise = _defaultWarmupExercises[_currentWarmupIndex];
    final progress =
        (_currentWarmupIndex + 1) / _defaultWarmupExercises.length;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Top bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.close, color: textPrimary),
                    onPressed: _exitWorkout,
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: elevatedColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer, size: 16, color: AppColors.cyan),
                        const SizedBox(width: 6),
                        Text(
                          _formatDuration(_workoutSeconds),
                          style: TextStyle(
                            color: textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _skipWarmup,
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: AppColors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Warmup header
              Row(
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
                        '${_currentWarmupIndex + 1} of ${_defaultWarmupExercises.length}',
                        style: TextStyle(fontSize: 14, color: textSecondary),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: elevatedColor,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.orange),
                  minHeight: 6,
                ),
              ),

              const Spacer(),

              // Current exercise
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.orange.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  currentExercise.icon,
                  size: 64,
                  color: AppColors.orange,
                ),
              ).animate().scale(duration: 300.ms),

              const SizedBox(height: 24),

              Text(
                currentExercise.name,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Timer
              Text(
                _formatDuration(_phaseSecondsRemaining),
                style: const TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w300,
                  color: AppColors.orange,
                ),
              ),

              const SizedBox(height: 16),

              // AI tip
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: elevatedColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome,
                        color: AppColors.cyan, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        currentExercise.tip,
                        style: TextStyle(
                          fontSize: 14,
                          color: textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms),

              const Spacer(),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _nextWarmupExercise,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cyan,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: Icon(
                        _currentWarmupIndex >= _defaultWarmupExercises.length - 1
                            ? Icons.play_arrow
                            : Icons.skip_next,
                      ),
                      label: Text(
                        _currentWarmupIndex >= _defaultWarmupExercises.length - 1
                            ? 'Start Workout'
                            : 'Next',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

  // ============ WORKOUT UI ============

  Widget _buildWorkoutScreen(bool isDark) {
    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final gifUrl = _currentExercise['gif_url'] as String?;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildWorkoutHeader(isDark, textPrimary, textSecondary),

            // Exercise content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Exercise video/image
                    if (gifUrl != null && gifUrl.isNotEmpty)
                      _buildExerciseMedia(gifUrl, isDark)
                    else
                      _buildPlaceholderMedia(isDark),

                    const SizedBox(height: 20),

                    // Exercise name
                    Text(
                      _currentExercise['name'] ?? 'Exercise',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 8),

                    // Muscle group & equipment
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildChip(
                          _currentExercise['muscle_group'] ??
                              _currentExercise['body_part'] ??
                              'Unknown',
                          AppColors.cyan,
                        ),
                        _buildChip(
                          _currentExercise['equipment'] ?? 'Bodyweight',
                          AppColors.purple,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Set progress
                    _buildSetProgress(isDark, elevatedColor, textPrimary),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom action buttons
            _buildBottomActions(isDark, elevatedColor),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutHeader(bool isDark, Color textPrimary, Color textSecondary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Close button
          GestureDetector(
            onTap: _exitWorkout,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.elevated : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.close, color: textPrimary, size: 20),
            ),
          ),

          const Spacer(),

          // Workout timer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.cyan.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer_outlined, size: 16, color: AppColors.cyan),
                const SizedBox(width: 6),
                Text(
                  _formatDuration(_workoutSeconds),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.cyan,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Exercise counter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.purple.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_currentExerciseIndex + 1}/${widget.exercises.length}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.purple,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseMedia(String gifUrl, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: CachedNetworkImage(
        imageUrl: gifUrl,
        height: 250,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          height: 250,
          color: isDark ? AppColors.elevated : Colors.grey.shade200,
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.cyan),
          ),
        ),
        errorWidget: (context, url, error) => _buildPlaceholderMedia(isDark),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildPlaceholderMedia(bool isDark) {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.cyan.withOpacity(0.3),
            AppColors.teal.withOpacity(0.3)
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fitness_center, size: 60, color: AppColors.cyan),
          const SizedBox(height: 12),
          Text(
            'Exercise Demo',
            style: TextStyle(
              fontSize: 16,
              color: isDark
                  ? AppColors.textSecondary
                  : AppColorsLight.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildSetProgress(
      bool isDark, Color elevatedColor, Color textPrimary) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'Set $_currentSet of $_currentExerciseSets',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),

          const SizedBox(height: 16),

          // Set dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_currentExerciseSets, (index) {
              final isCompleted =
                  index < (_completedSets[_currentExerciseIndex] ?? 0);
              final isCurrent = index == _currentSet - 1;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isCurrent ? 40 : 30,
                height: isCurrent ? 40 : 30,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppColors.success
                      : (isCurrent
                          ? AppColors.cyan
                          : Colors.grey.withOpacity(0.3)),
                  shape: BoxShape.circle,
                  border: isCurrent
                      ? Border.all(color: AppColors.cyan, width: 3)
                      : null,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: isCurrent ? 16 : 12,
                            fontWeight: FontWeight.bold,
                            color: isCurrent ? Colors.black : Colors.grey,
                          ),
                        ),
                ),
              );
            }),
          ),

          const SizedBox(height: 20),

          // Reps target
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.cyan.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.fitness_center, color: AppColors.cyan, size: 20),
                const SizedBox(width: 8),
                Text(
                  '$_currentExerciseReps reps',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.cyan,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(bool isDark, Color elevatedColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevatedColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _completeSet,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Complete Set $_currentSet',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============ REST UI WITH AI SUGGESTIONS ============

  Widget _buildRestScreen(bool isDark) {
    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    final isExerciseTransition = _currentSet > _currentExerciseSets ||
        (_completedSets[_currentExerciseIndex] ?? 0) >= _currentExerciseSets;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Rest icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.orange.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.timer, size: 60, color: AppColors.orange),
              ).animate().scale(duration: 300.ms),

              const SizedBox(height: 32),

              Text(
                isExerciseTransition ? 'Next Exercise Coming Up!' : 'Rest Time',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),

              const SizedBox(height: 16),

              // Timer
              Text(
                _formatDuration(_phaseSecondsRemaining),
                style: TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                  color: AppColors.orange,
                ),
              ).animate().fadeIn(),

              const SizedBox(height: 24),

              // AI Suggestion Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.cyan.withOpacity(0.15),
                      AppColors.purple.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.cyan.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.cyan.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            color: AppColors.cyan,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'AI Coach Tip',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.cyan,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _currentAiSuggestion,
                      style: TextStyle(
                        fontSize: 16,
                        color: textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

              const SizedBox(height: 24),

              // Next exercise preview
              if (isExerciseTransition &&
                  _currentExerciseIndex < widget.exercises.length - 1)
                _buildNextExercisePreview(isDark, elevatedColor, textPrimary, textSecondary),

              const Spacer(),

              // Skip rest button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: _skipRest,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.cyan, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Skip Rest',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.cyan,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNextExercisePreview(
      bool isDark, Color elevatedColor, Color textPrimary, Color textSecondary) {
    final nextExercise = widget.exercises[_currentExerciseIndex + 1];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.cyan, AppColors.teal],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '${_currentExerciseIndex + 2}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Up Next',
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
                Text(
                  nextExercise['name'] ?? 'Exercise',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2);
  }

  // ============ STRETCH UI ============

  Widget _buildStretchScreen(bool isDark) {
    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    final currentStretch = _defaultStretchExercises[_currentStretchIndex];
    final progress =
        (_currentStretchIndex + 1) / _defaultStretchExercises.length;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Top bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: textPrimary),
                    onPressed: _skipStretches,
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: elevatedColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer, size: 16, color: AppColors.cyan),
                        const SizedBox(width: 6),
                        Text(
                          _formatDuration(_workoutSeconds),
                          style: TextStyle(
                            color: textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _skipStretches,
                    child: const Text(
                      'Skip All',
                      style: TextStyle(
                        color: AppColors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Stretch header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.self_improvement,
                      color: AppColors.green,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'COOL DOWN',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.green,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_currentStretchIndex + 1} of ${_defaultStretchExercises.length}',
                        style: TextStyle(fontSize: 14, color: textSecondary),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Workout complete banner
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.cyan.withOpacity(0.2),
                      AppColors.green.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.cyan.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events,
                        color: AppColors.cyan, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Great job! Time to stretch and recover.',
                        style: TextStyle(
                          fontSize: 14,
                          color: textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: elevatedColor,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.green),
                  minHeight: 6,
                ),
              ),

              const Spacer(),

              // Current stretch
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.green.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  currentStretch.icon,
                  size: 64,
                  color: AppColors.green,
                ),
              ).animate().scale(duration: 300.ms),

              const SizedBox(height: 24),

              Text(
                currentStretch.name,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Timer
              Text(
                _formatDuration(_phaseSecondsRemaining),
                style: const TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w300,
                  color: AppColors.green,
                ),
              ),

              const SizedBox(height: 16),

              // Benefit text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: elevatedColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: AppColors.green, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        currentStretch.benefit,
                        style: TextStyle(
                          fontSize: 14,
                          color: textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms),

              const Spacer(),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _nextStretchExercise,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cyan,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: Icon(
                        _currentStretchIndex >=
                                _defaultStretchExercises.length - 1
                            ? Icons.check
                            : Icons.skip_next,
                      ),
                      label: Text(
                        _currentStretchIndex >=
                                _defaultStretchExercises.length - 1
                            ? 'Finish'
                            : 'Next',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

  // ============ COMPLETION UI WITH AI REVIEW ============

  Widget _buildCompletionScreen(bool isDark) {
    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    final aiReview = _getAiWorkoutReview();

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Celebration icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.celebration,
                  size: 60,
                  color: AppColors.success,
                ),
              ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

              const SizedBox(height: 24),

              Text(
                'Workout Complete!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 24),

              // Stats summary
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: elevatedColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildCompletionStat(
                          Icons.timer,
                          _formatDuration(_workoutSeconds),
                          'Duration',
                          AppColors.cyan,
                        ),
                        _buildCompletionStat(
                          Icons.fitness_center,
                          '$_totalSetsCompleted',
                          'Sets',
                          AppColors.purple,
                        ),
                        _buildCompletionStat(
                          Icons.repeat,
                          '$_totalRepsCompleted',
                          'Reps',
                          AppColors.orange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildCompletionStat(
                          Icons.check_circle,
                          '${widget.exercises.length}',
                          'Exercises',
                          AppColors.success,
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),

              const SizedBox(height: 24),

              // AI Workout Review
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.purple.withOpacity(0.15),
                      AppColors.cyan.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.purple.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.purple.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            color: AppColors.purple,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'AI Coach Review',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.purple,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      aiReview,
                      style: TextStyle(
                        fontSize: 16,
                        color: textPrimary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Sign up to get personalized AI coaching, detailed progress tracking, and workouts tailored to your goals.',
                      style: TextStyle(
                        fontSize: 14,
                        color: textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),

              const SizedBox(height: 24),

              // Sign up prompt
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.cyan.withOpacity(0.15),
                      AppColors.teal.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.cyan.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(Icons.rocket_launch, color: AppColors.cyan, size: 32),
                    const SizedBox(height: 12),
                    Text(
                      'Ready for the full experience?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Get AI-generated workout plans, track your progress, and achieve your fitness goals faster.',
                      style: TextStyle(
                        fontSize: 14,
                        color: textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 500.ms),

              const SizedBox(height: 32),

              // Action buttons
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => context.go('/pre-auth-quiz'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cyan,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Get Personalized Workouts',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 600.ms),

              const SizedBox(height: 12),

              TextButton(
                onPressed: () => context.pop(),
                child: Text(
                  'Back to Preview',
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                  ),
                ),
              ).animate().fadeIn(delay: 700.ms),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionStat(
      IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? AppColors.textSecondary
                    : AppColorsLight.textSecondary,
          ),
        ),
      ],
    );
  }
}
