import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Controller for warmup phase logic
///
/// NOTE (E2E #125 audit): this class is not currently instantiated anywhere
/// in the app — the live legacy/Advanced warm-up path is
/// `widgets/warmup_phase_screen.dart`'s own `_WarmupPhaseScreenState`
/// (mounted from `active_workout_screen_refactored.dart:1870`), which has
/// its own `PhaseTimerController`-based rest/duration handling, not this
/// class. Kept in parity with the ask anyway (grep found zero call sites for
/// `WarmupController(`, so this can't regress anything live).
class WarmupController {
  Timer? _timer;
  int _currentIndex = 0;
  int _secondsRemaining = 0;
  bool _isRunning = false;
  final VoidCallback onStateChanged;
  final VoidCallback onComplete;
  final List<Map<String, dynamic>> exercises;

  /// E2E #125 ask #2 — rest between moves. True while a rest countdown (not
  /// an exercise hold) is running; `onStateChanged` fires for both so a
  /// single listener can drive one UI.
  bool _isResting = false;
  static const int _defaultRestSeconds = 10; // matches the backend default

  WarmupController({
    required this.exercises,
    required this.onStateChanged,
    required this.onComplete,
  });

  int get currentIndex => _currentIndex;
  int get secondsRemaining => _secondsRemaining;
  bool get isRunning => _isRunning;
  bool get isResting => _isResting;
  Map<String, dynamic> get currentExercise => exercises[_currentIndex];
  double get progress => (_currentIndex + 1) / exercises.length;
  bool get isLastExercise => _currentIndex >= exercises.length - 1;

  int _durationOf(int index) {
    final v = exercises[index]['duration'];
    return v is num ? v.toInt() : 30;
  }

  int _restOf(int index) {
    final v = exercises[index]['rest_seconds'];
    return v is num ? v.toInt() : _defaultRestSeconds;
  }

  /// E2E #125 ask #2 — nudge the CURRENT move's hold duration. Mutates the
  /// exercise map in place (the list is a mutable `List<Map>`, so this is
  /// the whole warm-up's own source of truth — no separate override store
  /// needed). If the timer is already counting down, the remaining time
  /// shifts by the same delta so the change is felt immediately.
  void adjustCurrentDuration(int deltaSeconds) {
    final base = _durationOf(_currentIndex);
    final next = (base + deltaSeconds).clamp(5, 300);
    exercises[_currentIndex]['duration'] = next;
    if (_isRunning || (_secondsRemaining > 0 && !_isResting)) {
      _secondsRemaining = (_secondsRemaining + deltaSeconds).clamp(0, next);
    }
    onStateChanged();
  }

  void startTimer() {
    final duration = (exercises[_currentIndex]['duration'] as num).toInt();
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

  /// E2E #125 ask #2 — rest before the NEXT move (there was previously no
  /// rest concept at all; every move ran back-to-back). Reads
  /// `rest_seconds` off the move JUST FINISHED (index BEFORE the increment
  /// below), falling back to the backend's own default.
  void _startRest(int seconds) {
    _timer?.cancel();
    _isRunning = false;
    _isResting = true;
    _secondsRemaining = seconds;
    onStateChanged();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        _secondsRemaining--;
        onStateChanged();
      } else {
        skipRest();
      }
    });
  }

  /// Skip the active rest and move straight to the next exercise.
  void skipRest() {
    _timer?.cancel();
    _isResting = false;
    HapticFeedback.mediumImpact();
    _advanceIndex();
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
      final restSeconds = _restOf(_currentIndex);
      if (restSeconds > 0) {
        _startRest(restSeconds);
        return;
      }
      _advanceIndex();
    } else {
      finish();
    }
  }

  /// Bump `_currentIndex` and auto-start the next move's timer. Split out
  /// of [nextExercise] so both the rest-complete path ([skipRest]) and the
  /// no-rest-configured path converge here.
  void _advanceIndex() {
    _currentIndex++;
    _isRunning = false;
    _secondsRemaining = 0;
    onStateChanged();

    // Auto-start timer for next exercise
    Future.delayed(const Duration(milliseconds: 300), () {
      startTimer();
    });
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
                _buildTopBar(context, textPrimary, elevatedColor),
                const SizedBox(height: 24),

                // Header
                _buildHeader(context, textSecondary),
                const SizedBox(height: 16),

                // Progress bar
                _buildProgressBar(context, elevatedColor),
                const Spacer(),

                // Current exercise
                _buildCurrentExercise(context, currentWarmup, textPrimary, textSecondary),
                const Spacer(),

                // Upcoming exercises
                if (!controller.isLastExercise)
                  _buildUpcoming(context, textSecondary, elevatedColor),

                // Action buttons
                _buildActionButtons(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, Color textPrimary, Color elevatedColor) {
    final l = AppLocalizations.of(context)!;
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
              Icon(Icons.timer, size: 16, color: context.accentColor),
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
          child: Text(
            l.warmupControllerSkipWarmup,
            style: TextStyle(
              color: context.accentColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, Color textSecondary) {
    final l = AppLocalizations.of(context)!;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.accentColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.whatshot,
            color: context.accentColor,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.warmupControllerWarmUp,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.accentColor,
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

  Widget _buildProgressBar(BuildContext context, Color elevatedColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: controller.progress,
        backgroundColor: elevatedColor,
        valueColor: AlwaysStoppedAnimation<Color>(context.accentColor),
        minHeight: 6,
      ),
    );
  }

  Widget _buildCurrentExercise(
    BuildContext context,
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
              color: context.accentColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              currentWarmup['icon'] as IconData,
              size: 64,
              color: context.accentColor,
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
              style: TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.w300,
                color: context.accentColor,
              ),
            ).animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 2000.ms, color: context.accentColor.withOpacity(0.3))
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

  Widget _buildUpcoming(BuildContext context, Color textSecondary, Color elevatedColor) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.warmupControllerUpNext,
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
                margin: const EdgeInsetsDirectional.only(end: 8),
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

  Widget _buildActionButtons(BuildContext context) {
    final l = AppLocalizations.of(context)!;
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
                  ? context.accentColor.withOpacity(0.3)
                  : context.accentColor,
              foregroundColor: controller.isRunning
                  ? context.accentColor
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
                  ? l.stretchControllerPause
                  : (controller.secondsRemaining > 0 ? l.stretchControllerResume : l.stretchControllerStartTimer),
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
              backgroundColor: context.accentColor,
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
              controller.isLastExercise ? l.warmupControllerStartWorkout : l.commonNext,
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
