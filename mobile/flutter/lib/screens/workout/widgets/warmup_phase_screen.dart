/// Warmup phase screen widget
///
/// Displays the warmup exercises before the main workout begins.
/// Supports interval logging for cardio exercises (treadmill, bike, etc.)
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

  /// Callback with logged interval data per exercise (exerciseName -> intervals)
  final void Function(Map<String, List<WarmupInterval>> logs)? onIntervalsLogged;

  const WarmupPhaseScreen({
    super.key,
    required this.workoutSeconds,
    required this.onSkipWarmup,
    required this.onWarmupComplete,
    required this.onQuitRequested,
    required this.exercises,
    this.onIntervalsLogged,
  });

  @override
  State<WarmupPhaseScreen> createState() => _WarmupPhaseScreenState();
}

class _WarmupPhaseScreenState extends State<WarmupPhaseScreen> {
  int _currentExerciseIndex = 0;
  late PhaseTimerController _timerController;

  // Interval logging state
  final Map<String, List<WarmupInterval>> _allIntervalLogs = {};
  List<WarmupInterval> _currentIntervals = [];
  final _speedController = TextEditingController();
  final _inclineController = TextEditingController();
  int _exerciseElapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _timerController = PhaseTimerController();
    _timerController.onTick = (_) {
      _exerciseElapsedSeconds++;
      setState(() {});
    };
    _timerController.onComplete = _handleTimerComplete;

    // Initialize cardio fields from first exercise
    _initCardioFields(widget.exercises[0]);

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
    _speedController.dispose();
    _inclineController.dispose();
    super.dispose();
  }

  void _initCardioFields(WarmupExerciseData exercise) {
    _speedController.text = exercise.speedMph?.toStringAsFixed(1) ?? '';
    _inclineController.text = exercise.inclinePercent?.toStringAsFixed(0) ?? '';
    _currentIntervals = [];
    _exerciseElapsedSeconds = 0;

    // Auto-create first interval for cardio exercises
    if (exercise.isCardioEquipment && (exercise.speedMph != null || exercise.inclinePercent != null)) {
      _currentIntervals.add(WarmupInterval(
        startSeconds: 0,
        speedMph: exercise.speedMph,
        incline: exercise.inclinePercent,
      ));
    }
  }

  void _startCurrentExerciseTimer() {
    final duration = widget.exercises[_currentExerciseIndex].duration;
    _timerController.start(duration);
    setState(() {});
  }

  void _handleTimerComplete() {
    _finalizeCurrentExerciseIntervals();
    _nextExercise();
  }

  void _finalizeCurrentExerciseIntervals() {
    final exercise = widget.exercises[_currentExerciseIndex];
    if (_currentIntervals.isNotEmpty) {
      // Close the last open interval
      _currentIntervals.last.endSeconds = _exerciseElapsedSeconds;
      _allIntervalLogs[exercise.name] = List.from(_currentIntervals);
    }
  }

  void _logIntervalChange() {
    if (_currentIntervals.isEmpty) return;

    final speed = double.tryParse(_speedController.text);
    final incline = double.tryParse(_inclineController.text);

    HapticFeedback.lightImpact();

    setState(() {
      // Close the current interval
      _currentIntervals.last.endSeconds = _exerciseElapsedSeconds;

      // Start a new interval with same values (user can edit before next +)
      _currentIntervals.add(WarmupInterval(
        startSeconds: _exerciseElapsedSeconds,
        speedMph: speed,
        incline: incline,
      ));
    });
  }

  void _nextExercise() {
    _timerController.stop();
    HapticFeedback.mediumImpact();
    _finalizeCurrentExerciseIntervals();

    if (_currentExerciseIndex < widget.exercises.length - 1) {
      setState(() {
        _currentExerciseIndex++;
      });
      _initCardioFields(widget.exercises[_currentExerciseIndex]);
      // Auto-start timer for next exercise
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _startCurrentExerciseTimer();
        }
      });
    } else {
      // Warmup complete — emit logged intervals
      HapticFeedback.heavyImpact();
      if (_allIntervalLogs.isNotEmpty) {
        widget.onIntervalsLogged?.call(_allIntervalLogs);
      }
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

  String _formatInterval(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
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

                const SizedBox(height: 16),

                // Current warmup exercise (fixed, not scrollable)
                _buildCurrentExercise(
                  currentExercise,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),

                // Cardio speed/incline input fields (fixed)
                if (currentExercise.isCardioEquipment &&
                    (currentExercise.speedMph != null || currentExercise.inclinePercent != null))
                  _buildCardioInputRow(
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    elevatedColor: elevatedColor,
                  ),

                // Intervals list (scrollable, takes remaining space)
                if (currentExercise.isCardioEquipment &&
                    (currentExercise.speedMph != null || currentExercise.inclinePercent != null) &&
                    _currentIntervals.length > 1)
                  Expanded(
                    child: _buildIntervalsList(
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      elevatedColor: elevatedColor,
                    ),
                  )
                else
                  const Spacer(),

                // Upcoming warmup exercises
                if (_currentExerciseIndex < widget.exercises.length - 1)
                  _buildUpcomingExercises(
                    textSecondary: textSecondary,
                    elevatedColor: elevatedColor,
                  ),

                const SizedBox(height: 8),

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

        // Total workout timer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: elevatedColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.timer_outlined,
                  size: 16, color: AppColors.orange),
              const SizedBox(width: 4),
              Text(
                WorkoutTimerController.formatTime(widget.workoutSeconds),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ],
          ),
        ),

        // Skip warmup button
        TextButton(
          onPressed: () {
            // Emit whatever we've logged so far
            _finalizeCurrentExerciseIntervals();
            if (_allIntervalLogs.isNotEmpty) {
              widget.onIntervalsLogged?.call(_allIntervalLogs);
            }
            widget.onSkipWarmup();
          },
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
        // Warmup icon
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.orange.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.local_fire_department,
            color: AppColors.orange,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),

        // Title and count
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'WARM UP',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.orange,
                letterSpacing: 1,
              ),
            ),
            Text(
              '${_currentExerciseIndex + 1} of ${widget.exercises.length}',
              style: TextStyle(
                fontSize: 13,
                color: textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressBar(double progress, Color elevatedColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: progress,
        backgroundColor: elevatedColor,
        color: AppColors.orange,
        minHeight: 4,
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
        mainAxisSize: MainAxisSize.min,
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

          // Cardio params display (non-cardio exercises only - cardio gets the editable fields below)
          if (exercise.isCardioEquipment && exercise.speedMph == null && exercise.inclinePercent == null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.orange.withOpacity(0.3)),
              ),
              child: Text(
                exercise.cardioParamsDisplay,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textPrimary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Speed/incline input row with + button (fixed, not scrollable)
  Widget _buildCardioInputRow({
    required Color textPrimary,
    required Color textSecondary,
    required Color elevatedColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          if (_speedController.text.isNotEmpty || widget.exercises[_currentExerciseIndex].speedMph != null)
            Expanded(
              child: _buildCardioInput(
                label: 'Speed',
                suffix: 'mph',
                controller: _speedController,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                elevatedColor: elevatedColor,
              ),
            ),
          if (_speedController.text.isNotEmpty && _inclineController.text.isNotEmpty)
            const SizedBox(width: 12),
          if (_inclineController.text.isNotEmpty || widget.exercises[_currentExerciseIndex].inclinePercent != null)
            Expanded(
              child: _buildCardioInput(
                label: 'Incline',
                suffix: '',
                controller: _inclineController,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                elevatedColor: elevatedColor,
              ),
            ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _logIntervalChange,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.orange.withOpacity(0.4)),
              ),
              child: const Icon(Icons.add, color: AppColors.orange, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  /// Scrollable intervals list (takes remaining vertical space)
  Widget _buildIntervalsList({
    required Color textPrimary,
    required Color textSecondary,
    required Color elevatedColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'INTERVALS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Text(
                '${_currentIntervals.length}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              child: ListView.builder(
                itemCount: _currentIntervals.length,
                itemBuilder: (context, reverseIndex) {
                // Show newest first
                final i = _currentIntervals.length - 1 - reverseIndex;
                final interval = _currentIntervals[i];
                final isActive = i == _currentIntervals.length - 1;
                final endLabel = isActive ? 'now' : _formatInterval(interval.endSeconds);
                final parts = <String>[];
                if (interval.speedMph != null) parts.add('${interval.speedMph!.toStringAsFixed(1)} mph');
                if (interval.incline != null) parts.add('Inc ${interval.incline!.toStringAsFixed(0)}');

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: Text(
                          '${_formatInterval(interval.startSeconds)} - $endLabel',
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        parts.join('  /  '),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isActive ? AppColors.orange : textPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardioInput({
    required String label,
    required String suffix,
    required TextEditingController controller,
    required Color textPrimary,
    required Color textSecondary,
    required Color elevatedColor,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 13, color: textSecondary),
        suffixText: suffix.isNotEmpty ? suffix : null,
        suffixStyle: TextStyle(fontSize: 13, color: textSecondary),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        filled: true,
        fillColor: elevatedColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: textSecondary.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: textSecondary.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.orange),
        ),
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
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: textSecondary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 32,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.exercises.length - _currentExerciseIndex - 1,
            itemBuilder: (context, index) {
              final exercise =
                  widget.exercises[_currentExerciseIndex + 1 + index];
              return Container(
                margin: const EdgeInsets.only(right: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: elevatedColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      exercise.icon,
                      size: 14,
                      color: textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          exercise.name,
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        if (exercise.isCardioEquipment)
                          Text(
                            exercise.cardioParamsDisplay,
                            style: TextStyle(
                              color: textSecondary.withOpacity(0.7),
                              fontSize: 9,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
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
