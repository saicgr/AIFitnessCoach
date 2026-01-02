import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';

/// Timer widget for timed exercises (planks, wall sits, holds, etc.)
/// Supports pause/resume functionality to allow users to rest mid-exercise.
class TimedExerciseTimer extends StatefulWidget {
  /// Total duration in seconds for the exercise
  final int durationSeconds;

  /// Called when the timer completes
  final VoidCallback? onComplete;

  /// Called when time remaining changes (for logging)
  final ValueChanged<int>? onTimeUpdate;

  /// Called when pause state changes
  final ValueChanged<bool>? onPauseChanged;

  /// Exercise name for display
  final String exerciseName;

  /// Set number (e.g., "Set 1 of 3")
  final int setNumber;

  /// Total sets
  final int totalSets;

  /// Whether to auto-start the timer
  final bool autoStart;

  const TimedExerciseTimer({
    super.key,
    required this.durationSeconds,
    this.onComplete,
    this.onTimeUpdate,
    this.onPauseChanged,
    this.exerciseName = 'Exercise',
    this.setNumber = 1,
    this.totalSets = 1,
    this.autoStart = false,
  });

  @override
  State<TimedExerciseTimer> createState() => _TimedExerciseTimerState();
}

class _TimedExerciseTimerState extends State<TimedExerciseTimer>
    with TickerProviderStateMixin {
  late int _remainingSeconds;
  Timer? _timer;
  bool _isPaused = true;
  bool _isComplete = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.durationSeconds;

    // Pulse animation for active timer
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.autoStart) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startTimer() {
    if (_isComplete) return;

    setState(() {
      _isPaused = false;
    });
    widget.onPauseChanged?.call(false);

    _pulseController.repeat(reverse: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
        widget.onTimeUpdate?.call(_remainingSeconds);
      } else {
        _completeTimer();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    _pulseController.stop();
    setState(() {
      _isPaused = true;
    });
    widget.onPauseChanged?.call(true);
    HapticFeedback.lightImpact();
  }

  void _resumeTimer() {
    _startTimer();
    HapticFeedback.lightImpact();
  }

  void _completeTimer() {
    _timer?.cancel();
    _pulseController.stop();
    setState(() {
      _isComplete = true;
      _isPaused = true;
    });
    HapticFeedback.heavyImpact();
    widget.onComplete?.call();
  }

  void _resetTimer() {
    _timer?.cancel();
    _pulseController.stop();
    setState(() {
      _remainingSeconds = widget.durationSeconds;
      _isPaused = true;
      _isComplete = false;
    });
    HapticFeedback.mediumImpact();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (minutes > 0) {
      return '$minutes:${secs.toString().padLeft(2, '0')}';
    }
    return '$seconds';
  }

  double get _progress => 1 - (_remainingSeconds / widget.durationSeconds);

  Color get _progressColor {
    if (_isComplete) return AppColors.success;
    if (_progress > 0.75) return AppColors.orange;
    return AppColors.cyan;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.glassSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isComplete
              ? AppColors.success
              : _isPaused
                  ? AppColors.cardBorder
                  : AppColors.cyan,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Set ${widget.setNumber} of ${widget.totalSets}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              if (_isComplete)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 16, color: AppColors.success),
                      SizedBox(width: 4),
                      Text(
                        'COMPLETE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                )
              else if (_isPaused && _remainingSeconds < widget.durationSeconds)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pause_circle, size: 16, color: AppColors.orange),
                      SizedBox(width: 4),
                      Text(
                        'PAUSED',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Circular progress timer
          ScaleTransition(
            scale: _isPaused ? const AlwaysStoppedAnimation(1.0) : _pulseAnimation,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background circle
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 8,
                    backgroundColor: AppColors.surface,
                    color: AppColors.surface,
                  ),
                ),
                // Progress circle
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CircularProgressIndicator(
                    value: _progress,
                    strokeWidth: 8,
                    backgroundColor: AppColors.cardBorder,
                    color: _progressColor,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                // Time display
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(_remainingSeconds),
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: _isComplete
                            ? AppColors.success
                            : AppColors.textPrimary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      _remainingSeconds == 1 ? 'second' : 'seconds',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Reset button
              if (!_isComplete && _remainingSeconds < widget.durationSeconds) ...[
                _buildControlButton(
                  icon: Icons.refresh,
                  label: 'Reset',
                  onTap: _resetTimer,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 16),
              ],

              // Main play/pause button
              if (!_isComplete)
                GestureDetector(
                  onTap: _isPaused ? _resumeTimer : _pauseTimer,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: _isPaused
                          ? AppColors.cyan
                          : AppColors.orange.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_isPaused ? AppColors.cyan : AppColors.orange)
                              .withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isPaused ? Icons.play_arrow : Icons.pause,
                      size: 36,
                      color: Colors.white,
                    ),
                  ),
                )
              else
                // Done button when complete
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    // Could trigger next set or close
                  },
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.success.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 36,
                      color: Colors.white,
                    ),
                  ),
                ),

              // Skip button (only when not started or complete)
              if (!_isComplete) ...[
                const SizedBox(width: 16),
                _buildControlButton(
                  icon: Icons.skip_next,
                  label: 'Skip',
                  onTap: _completeTimer,
                  color: AppColors.textSecondary,
                ),
              ],
            ],
          ),

          // Pause hint text
          if (!_isComplete && !_isPaused)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Tap pause to rest, then resume',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted.withOpacity(0.7),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact inline version for set rows
class TimedSetRow extends StatefulWidget {
  final int durationSeconds;
  final int setNumber;
  final bool isCurrentSet;
  final bool isCompleted;
  final VoidCallback onComplete;
  final ValueChanged<int>? onTimeUpdate;

  const TimedSetRow({
    super.key,
    required this.durationSeconds,
    required this.setNumber,
    required this.isCurrentSet,
    required this.isCompleted,
    required this.onComplete,
    this.onTimeUpdate,
  });

  @override
  State<TimedSetRow> createState() => _TimedSetRowState();
}

class _TimedSetRowState extends State<TimedSetRow> {
  int _remainingSeconds = 0;
  Timer? _timer;
  bool _isPaused = true;
  bool _hasStarted = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.durationSeconds;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _isPaused = false;
      _hasStarted = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
        widget.onTimeUpdate?.call(_remainingSeconds);
      } else {
        _timer?.cancel();
        widget.onComplete();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isPaused = true;
    });
    HapticFeedback.lightImpact();
  }

  void _toggleTimer() {
    if (_isPaused) {
      _startTimer();
    } else {
      _pauseTimer();
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (minutes > 0) {
      return '$minutes:${secs.toString().padLeft(2, '0')}';
    }
    return '${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final progress = 1 - (_remainingSeconds / widget.durationSeconds);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: widget.isCurrentSet && !widget.isCompleted
            ? AppColors.cyan.withOpacity(0.1)
            : widget.isCompleted
                ? AppColors.success.withOpacity(0.1)
                : AppColors.glassSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isCurrentSet && !widget.isCompleted
              ? AppColors.cyan
              : widget.isCompleted
                  ? AppColors.success
                  : AppColors.cardBorder,
          width: widget.isCurrentSet ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Set number badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: widget.isCompleted
                  ? AppColors.success
                  : AppColors.cyan.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: widget.isCompleted
                  ? const Icon(Icons.check, size: 18, color: Colors.white)
                  : Text(
                      '${widget.setNumber}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: widget.isCompleted
                            ? Colors.white
                            : AppColors.cyan,
                      ),
                    ),
            ),
          ),

          const SizedBox(width: 12),

          // Progress bar and time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _hasStarted
                          ? _formatTime(_remainingSeconds)
                          : _formatTime(widget.durationSeconds),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: widget.isCompleted
                            ? AppColors.success
                            : AppColors.textPrimary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (_hasStarted && !widget.isCompleted)
                      Text(
                        _isPaused ? 'PAUSED' : 'RUNNING',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _isPaused
                              ? AppColors.orange
                              : AppColors.success,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: widget.isCompleted ? 1.0 : progress,
                    backgroundColor: AppColors.cardBorder,
                    color: widget.isCompleted
                        ? AppColors.success
                        : AppColors.cyan,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Play/Pause/Complete button
          if (!widget.isCompleted)
            GestureDetector(
              onTap: _toggleTimer,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _isPaused
                      ? AppColors.cyan
                      : AppColors.orange,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _isPaused ? Icons.play_arrow : Icons.pause,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            )
          else
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 24,
              ),
            ),
        ],
      ),
    );
  }
}
