import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../core/theme/theme_colors.dart';
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
    if (_isComplete) return AppColors.success;  // accent-allowlist: success/positive state — must stay green regardless of accent
    if (_progress > 0.75) return context.accentColor;
    return context.accentColor;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeColors.of(context).glassSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isComplete
              ? AppColors.success  // accent-allowlist: success/positive state — must stay green regardless of accent
              : _isPaused
                  ? ThemeColors.of(context).cardBorder
                  : context.accentColor,
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
                AppLocalizations.of(context)!.timedExerciseTimerSetOf(widget.setNumber, widget.totalSets),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ThemeColors.of(context).textSecondary,
                ),
              ),
              if (_isComplete)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.2),  // accent-allowlist: success/positive state — must stay green regardless of accent
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 16, color: AppColors.success),  // accent-allowlist: success/positive state — must stay green regardless of accent
                      SizedBox(width: 4),
                      Text(
                        AppLocalizations.of(context).timedExerciseTimerComplete,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,  // accent-allowlist: success/positive state — must stay green regardless of accent
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
                    color: context.accentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pause_circle, size: 16, color: context.accentColor),
                      SizedBox(width: 4),
                      Text(
                        AppLocalizations.of(context).workoutTopOverlayPaused,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: context.accentColor,
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
                    backgroundColor: ThemeColors.of(context).surface,
                    color: ThemeColors.of(context).surface,
                  ),
                ),
                // Progress circle
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CircularProgressIndicator(
                    value: _progress,
                    strokeWidth: 8,
                    backgroundColor: ThemeColors.of(context).cardBorder,
                    color: _progressColor,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                // Time display. E2E #134 — a Stack gives its non-positioned
                // children LOOSE (not bounded) constraints and sizes ITSELF
                // to the union of their natural sizes — so this Column,
                // unconstrained, was free to grow past 140px at a large
                // textScaler and dragged the whole ring+Stack taller with
                // it, blowing out the fixed-height budget the timer sits in
                // (the reported "clipped from the bottom" — the overflow
                // actually surfaced one level up, wherever this widget is
                // embedded with a bounded height). A bare FittedBox doesn't
                // fix this alone — with nothing bounding IT either, it has
                // no target box to fit into and passes the natural size
                // straight through. The SizedBox(140,140) gives FittedBox an
                // actual target matching the two ring circles, so the
                // countdown scales down to fit at any text scale instead of
                // inflating the Stack.
                SizedBox(
                  width: 140,
                  height: 140,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(_remainingSeconds),
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: _isComplete
                                ? AppColors.success  // accent-allowlist: success/positive state — must stay green regardless of accent
                                : ThemeColors.of(context).textPrimary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        Text(
                          _remainingSeconds == 1 ? 'second' : 'seconds',
                          style: TextStyle(
                            fontSize: 14,
                            color: ThemeColors.of(context).textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
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
                  label: AppLocalizations.of(context).trophyFilterReset,
                  onTap: _resetTimer,
                  color: ThemeColors.of(context).textSecondary,
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
                          ? context.accentColor
                          : context.accentColor.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_isPaused ? context.accentColor : context.accentColor)
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
                      color: AppColors.success,  // accent-allowlist: success/positive state — must stay green regardless of accent
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.success.withOpacity(0.3),  // accent-allowlist: success/positive state — must stay green regardless of accent
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
                  label: AppLocalizations.of(context).onboardingSkip,
                  onTap: _completeTimer,
                  color: ThemeColors.of(context).textSecondary,
                ),
              ],
            ],
          ),

          // Pause hint text
          if (!_isComplete && !_isPaused)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                AppLocalizations.of(context).timedExerciseTimerTapPauseToRest,
                style: TextStyle(
                  fontSize: 12,
                  color: ThemeColors.of(context).textMuted.withOpacity(0.7),
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
            ? context.accentColor.withOpacity(0.1)
            : widget.isCompleted
                ? AppColors.success.withOpacity(0.1)  // accent-allowlist: success/positive state — must stay green regardless of accent
                : ThemeColors.of(context).glassSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isCurrentSet && !widget.isCompleted
              ? context.accentColor
              : widget.isCompleted
                  ? AppColors.success  // accent-allowlist: success/positive state — must stay green regardless of accent
                  : ThemeColors.of(context).cardBorder,
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
                  ? AppColors.success  // accent-allowlist: success/positive state — must stay green regardless of accent
                  : context.accentColor.withOpacity(0.2),
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
                            : context.accentColor,
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
                            ? AppColors.success  // accent-allowlist: success/positive state — must stay green regardless of accent
                            : ThemeColors.of(context).textPrimary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (_hasStarted && !widget.isCompleted)
                      Text(
                        _isPaused ? AppLocalizations.of(context).workoutTopOverlayPaused : AppLocalizations.of(context).timedExerciseTimerRunning,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _isPaused
                              ? context.accentColor
                              : AppColors.success,  // accent-allowlist: success/positive state — must stay green regardless of accent
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
                    backgroundColor: ThemeColors.of(context).cardBorder,
                    color: widget.isCompleted
                        ? AppColors.success  // accent-allowlist: success/positive state — must stay green regardless of accent
                        : context.accentColor,
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
                      ? context.accentColor
                      : context.accentColor,
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
                color: AppColors.success,  // accent-allowlist: success/positive state — must stay green regardless of accent
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
