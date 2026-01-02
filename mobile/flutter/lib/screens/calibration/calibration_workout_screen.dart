import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/context_logging_service.dart';

/// Calibration Exercise data
class CalibrationExercise {
  final String id;
  final String name;
  final String description;
  final String instructions;
  final IconData icon;
  final bool isTimed;
  final int? targetSeconds; // For timed exercises
  int? repsCompleted;
  int? secondsHeld;

  CalibrationExercise({
    required this.id,
    required this.name,
    required this.description,
    required this.instructions,
    required this.icon,
    this.isTimed = false,
    this.targetSeconds,
    this.repsCompleted,
    this.secondsHeld,
  });
}

/// Calibration Workout Screen
/// Guides user through basic fitness tests to determine starting level
class CalibrationWorkoutScreen extends ConsumerStatefulWidget {
  final bool fromOnboarding;

  const CalibrationWorkoutScreen({
    super.key,
    this.fromOnboarding = false,
  });

  @override
  ConsumerState<CalibrationWorkoutScreen> createState() => _CalibrationWorkoutScreenState();
}

class _CalibrationWorkoutScreenState extends ConsumerState<CalibrationWorkoutScreen> {
  late String _calibrationId;
  late Stopwatch _workoutTimer;
  late List<CalibrationExercise> _exercises;
  int _currentExerciseIndex = 0;
  bool _isResting = false;
  bool _isExerciseActive = false;
  Timer? _restTimer;
  Timer? _exerciseTimer;
  int _restSecondsRemaining = 60;
  int _exerciseSecondsElapsed = 0;

  @override
  void initState() {
    super.initState();
    _calibrationId = const Uuid().v4();
    _workoutTimer = Stopwatch()..start();

    // Log calibration started
    ref.read(contextLoggingServiceProvider).logCalibrationStarted(_calibrationId);

    _exercises = [
      CalibrationExercise(
        id: 'pushups',
        name: 'Push-ups',
        description: 'Max reps with good form',
        instructions: 'Do as many push-ups as you can with proper form. Stop when form breaks down.',
        icon: Icons.fitness_center,
      ),
      CalibrationExercise(
        id: 'squats',
        name: 'Bodyweight Squats',
        description: 'Max reps in 60 seconds',
        instructions: 'Do as many squats as you can in 60 seconds. Full depth, controlled movement.',
        icon: Icons.accessibility_new,
        isTimed: true,
        targetSeconds: 60,
      ),
      CalibrationExercise(
        id: 'plank',
        name: 'Plank Hold',
        description: 'Max time hold',
        instructions: 'Hold a plank position for as long as you can. Keep your body straight.',
        icon: Icons.straighten,
        isTimed: true,
      ),
    ];
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    _exerciseTimer?.cancel();
    _workoutTimer.stop();
    super.dispose();
  }

  CalibrationExercise get _currentExercise => _exercises[_currentExerciseIndex];

  void _startExercise() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isExerciseActive = true;
      _exerciseSecondsElapsed = 0;
    });

    // Start timer for timed exercises
    _exerciseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _exerciseSecondsElapsed++;
        });

        // For timed squats, auto-stop at target
        if (_currentExercise.isTimed &&
            _currentExercise.targetSeconds != null &&
            _exerciseSecondsElapsed >= _currentExercise.targetSeconds!) {
          _stopExercise();
        }
      }
    });
  }

  void _stopExercise() {
    HapticFeedback.mediumImpact();
    _exerciseTimer?.cancel();

    if (_currentExercise.isTimed && _currentExercise.targetSeconds == null) {
      // For plank hold, record the time
      _currentExercise.secondsHeld = _exerciseSecondsElapsed;
    }

    setState(() {
      _isExerciseActive = false;
    });

    // Show input for reps if needed
    if (!_currentExercise.isTimed || _currentExercise.targetSeconds != null) {
      _showRepsInputDialog();
    } else {
      _moveToNextExercise();
    }
  }

  void _showRepsInputDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'How many ${_currentExercise.name}?',
            style: TextStyle(
              color: isDark ? Colors.white : AppColorsLight.textPrimary,
            ),
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Enter reps completed',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                final reps = int.tryParse(controller.text) ?? 0;
                _currentExercise.repsCompleted = reps;
                Navigator.pop(context);
                _moveToNextExercise();
              },
              child: Text(
                'Done',
                style: TextStyle(color: AppColors.cyan),
              ),
            ),
          ],
        );
      },
    );
  }

  void _moveToNextExercise() {
    if (_currentExerciseIndex < _exercises.length - 1) {
      // Start rest period
      setState(() {
        _isResting = true;
        _restSecondsRemaining = 60;
      });

      _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _restSecondsRemaining--;
          });

          if (_restSecondsRemaining <= 0) {
            _restTimer?.cancel();
            setState(() {
              _isResting = false;
              _currentExerciseIndex++;
            });
          }
        }
      });
    } else {
      // All exercises complete - go to results
      _completeCalibration();
    }
  }

  void _skipRest() {
    HapticFeedback.lightImpact();
    _restTimer?.cancel();
    setState(() {
      _isResting = false;
      _currentExerciseIndex++;
    });
  }

  void _completeCalibration() {
    _workoutTimer.stop();
    final durationSeconds = _workoutTimer.elapsed.inSeconds;

    // Calculate result based on exercises
    final result = _calculateResult();

    // Log completion
    ref.read(contextLoggingServiceProvider).logCalibrationCompleted(
      _calibrationId,
      durationSeconds,
      result,
    );

    // Navigate to results
    context.go('/calibration/results', extra: {
      'fromOnboarding': widget.fromOnboarding,
      'calibrationId': _calibrationId,
      'exercises': _exercises,
      'result': result,
      'durationSeconds': durationSeconds,
    });
  }

  Map<String, dynamic> _calculateResult() {
    final pushups = _exercises[0].repsCompleted ?? 0;
    final squats = _exercises[1].repsCompleted ?? 0;
    final plankSeconds = _exercises[2].secondsHeld ?? 0;

    // Simple scoring logic
    String level;
    if (pushups >= 30 && squats >= 40 && plankSeconds >= 90) {
      level = 'advanced';
    } else if (pushups >= 15 && squats >= 25 && plankSeconds >= 45) {
      level = 'intermediate';
    } else {
      level = 'beginner';
    }

    return {
      'level': level,
      'pushups': pushups,
      'squats': squats,
      'plank_seconds': plankSeconds,
      'suggested_adjustments': {
        'push_strength': pushups >= 20 ? 'good' : 'needs_work',
        'leg_endurance': squats >= 30 ? 'good' : 'needs_work',
        'core_stability': plankSeconds >= 60 ? 'good' : 'needs_work',
      },
    };
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.elevated
            : AppColorsLight.elevated,
        title: const Text('Exit Calibration?'),
        content: const Text('Your progress will be lost. You can re-calibrate anytime from Settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (widget.fromOnboarding) {
                context.go('/paywall-features');
              } else {
                context.pop();
              }
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: textSecondary),
          onPressed: _showExitDialog,
        ),
        title: Text(
          'Calibration',
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_currentExerciseIndex + 1}/${_exercises.length}',
              style: TextStyle(
                color: AppColors.purple,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: _isResting ? _buildRestScreen(isDark, textPrimary, textSecondary, cardColor, cardBorder) : _buildExerciseScreen(isDark, textPrimary, textSecondary, cardColor, cardBorder),
    );
  }

  Widget _buildRestScreen(bool isDark, Color textPrimary, Color textSecondary, Color cardColor, Color cardBorder) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.self_improvement,
            size: 64,
            color: AppColors.cyan,
          ),
          const SizedBox(height: 24),
          Text(
            'Rest',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$_restSecondsRemaining seconds',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: AppColors.cyan,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Next: ${_exercises[_currentExerciseIndex + 1].name}',
            style: TextStyle(
              fontSize: 16,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          TextButton(
            onPressed: _skipRest,
            child: Text(
              'Skip Rest',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.cyan,
              ),
            ),
          ),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildExerciseScreen(bool isDark, Color textPrimary, Color textSecondary, Color cardColor, Color cardBorder) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (_currentExerciseIndex + 1) / _exercises.length,
                backgroundColor: cardBorder,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.purple),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 32),

            // Exercise icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.purple,
                    AppColors.electricBlue,
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.purple.withOpacity(0.3),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Icon(
                _currentExercise.icon,
                size: 56,
                color: Colors.white,
              ),
            ).animate().scale(begin: const Offset(0.9, 0.9)),
            const SizedBox(height: 32),

            // Exercise name
            Text(
              _currentExercise.name,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              _currentExercise.description,
              style: TextStyle(
                fontSize: 16,
                color: textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Timer display (for active exercise)
            if (_isExerciseActive) ...[
              Text(
                '${(_exerciseSecondsElapsed ~/ 60).toString().padLeft(2, '0')}:${(_exerciseSecondsElapsed % 60).toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  color: AppColors.cyan,
                ),
              ).animate().fadeIn(),
              const SizedBox(height: 16),
            ],

            // Instructions card
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.cyan, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Instructions',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _currentExercise.instructions,
                      style: TextStyle(
                        fontSize: 14,
                        color: textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isExerciseActive ? _stopExercise : _startExercise,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isExerciseActive ? AppColors.error : AppColors.purple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_isExerciseActive ? Icons.stop : Icons.play_arrow_rounded),
                    const SizedBox(width: 8),
                    Text(
                      _isExerciseActive ? 'Done' : 'Start',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
