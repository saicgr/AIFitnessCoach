/// Warmup phase screen widget
///
/// Displays the warmup exercises before the main workout begins.
/// Supports interval logging for cardio exercises (treadmill, bike, etc.)
library;

import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/repositories/workout_repository.dart';
import '../controllers/workout_timer_controller.dart';
import '../models/workout_state.dart';

import '../../../l10n/generated/app_localizations.dart';
/// Warmup phase screen displayed before the main workout
class WarmupPhaseScreen extends ConsumerStatefulWidget {
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

  /// E2E #125 — optional. `WarmupExerciseData` carries no exercise_id/media
  /// fields (see the model in `models/workout_state.dart`, not owned by
  /// this change), so a duration customization can only be persisted
  /// (`PUT .../warmup/exercises` + the saved-template endpoint) when the
  /// caller supplies the workout it belongs to. Null (the mounting screen,
  /// `active_workout_screen_refactored.dart`, does not currently pass this)
  /// means edits stay session-local — never silently dropped data, just an
  /// honest capability gap until that call site is updated to wire it.
  final String? workoutId;

  /// Paired with [workoutId] — scopes the saved template so a leg day and a
  /// mobility day don't share one warm-up. Null saves the generic default.
  final String? workoutType;

  const WarmupPhaseScreen({
    super.key,
    required this.workoutSeconds,
    required this.onSkipWarmup,
    required this.onWarmupComplete,
    required this.onQuitRequested,
    required this.exercises,
    this.onIntervalsLogged,
    this.workoutId,
    this.workoutType,
  });

  @override
  ConsumerState<WarmupPhaseScreen> createState() => _WarmupPhaseScreenState();
}

class _WarmupPhaseScreenState extends ConsumerState<WarmupPhaseScreen> {
  int _currentExerciseIndex = 0;
  late PhaseTimerController _timerController;

  // E2E #125 ask #2 — rest between moves (there was previously none; every
  // move ran back-to-back) + per-move editable hold duration.
  late PhaseTimerController _restTimerController;
  bool _isResting = false;
  static const int _kWarmupRestSeconds = 10; // matches the backend's default
  // Exercise index -> user-adjusted hold seconds. `WarmupExerciseData` is
  // `const`/immutable, so overrides live here rather than mutating it.
  final Map<int, int> _durationOverrides = {};

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
    _restTimerController = PhaseTimerController();
    _restTimerController.onTick = (_) {
      setState(() {});
    };
    _restTimerController.onComplete = () {
      if (!mounted) return;
      setState(() => _isResting = false);
      _advanceToNextExercise();
    };

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
    _restTimerController.dispose();
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
    final duration = _durationOverrides[_currentExerciseIndex] ??
        widget.exercises[_currentExerciseIndex].duration;
    _timerController.start(duration);
    setState(() {});
  }

  /// E2E #125 ask #2 — nudge the CURRENT move's hold duration by
  /// [deltaSeconds]. If the timer is already counting down, the remaining
  /// time is shifted by the same delta (restart-with-adjusted-remaining —
  /// `PhaseTimerController` has no in-place adjust) so the change is felt
  /// immediately instead of only applying next time this move runs.
  void _adjustCurrentDuration(int deltaSeconds) {
    final base = _durationOverrides[_currentExerciseIndex] ??
        widget.exercises[_currentExerciseIndex].duration;
    final next = (base + deltaSeconds).clamp(5, 300);
    setState(() => _durationOverrides[_currentExerciseIndex] = next);
    if (_timerController.isRunning || _timerController.secondsRemaining > 0) {
      final newRemaining =
          (_timerController.secondsRemaining + deltaSeconds).clamp(0, next);
      _timerController.start(newRemaining);
    }
    HapticFeedback.lightImpact();
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
      // E2E #125 ask #2 — rest before the NEXT move instead of jumping
      // straight into it.
      if (_kWarmupRestSeconds > 0) {
        setState(() => _isResting = true);
        _restTimerController.start(_kWarmupRestSeconds);
        return;
      }
      _advanceToNextExercise();
    } else {
      // Warmup complete — emit logged intervals + any duration customization.
      HapticFeedback.heavyImpact();
      if (_allIntervalLogs.isNotEmpty) {
        widget.onIntervalsLogged?.call(_allIntervalLogs);
      }
      _persistCustomization();
      widget.onWarmupComplete();
    }
  }

  void _advanceToNextExercise() {
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
  }

  void _skipRest() {
    HapticFeedback.lightImpact();
    _restTimerController.stop();
    setState(() => _isResting = false);
    _advanceToNextExercise();
  }

  /// ±10s during an active rest. Restart-with-adjusted-remaining, same
  /// technique as [_adjustCurrentDuration] (no in-place adjust on
  /// `PhaseTimerController`).
  void _adjustRest(int deltaSeconds) {
    final next = (_restTimerController.secondsRemaining + deltaSeconds);
    if (next <= 0) {
      _skipRest();
      return;
    }
    _restTimerController.start(next.clamp(0, 300));
    HapticFeedback.lightImpact();
  }

  /// E2E #125 ask #3 — best-effort. Fires only when the user actually
  /// changed a duration this run, and only when the (not-owned) mounting
  /// screen has supplied [WarmupPhaseScreen.workoutId] — see that field's
  /// doc for why a fuller, media-aware save isn't possible from here.
  /// Never blocks finishing the warm-up.
  void _persistCustomization() {
    final id = widget.workoutId;
    if (id == null || id.isEmpty || _durationOverrides.isEmpty) return;
    final list = [
      for (int i = 0; i < widget.exercises.length; i++)
        {
          'name': widget.exercises[i].name,
          'duration_seconds':
              _durationOverrides[i] ?? widget.exercises[i].duration,
          'rest_seconds': _kWarmupRestSeconds,
          'equipment': widget.exercises[i].equipment ?? 'none',
          'muscle_group': 'general',
        },
    ];
    unawaited(() async {
      try {
        final repo = ref.read(workoutRepositoryProvider);
        await repo.saveWarmupStretchOrder(id, 'warmup', list);
        await repo.saveWarmupTemplate(
          workoutType: widget.workoutType,
          exercises: list,
        );
      } catch (e) {
        debugPrint('⚠️ [WarmupPhaseScreen] customization persist failed: $e');
      }
    }());
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
                // Scrollable content — keeps the keyboard (speed/incline focus)
                // from overflowing the fixed column; action buttons stay pinned.
                Expanded(
                  child: SingleChildScrollView(
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

                        // Current warmup exercise — or the rest countdown
                        // (E2E #125 ask #2) between moves.
                        _isResting
                            ? _buildRestCard(
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                              )
                            : _buildCurrentExercise(
                                currentExercise,
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                              ),

                        // Cardio speed/incline input fields
                        if (currentExercise.isCardioEquipment &&
                            (currentExercise.speedMph != null || currentExercise.inclinePercent != null))
                          _buildCardioInputRow(
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            elevatedColor: elevatedColor,
                          ),

                        // Intervals list (bounded height inside the scroll view)
                        if (currentExercise.isCardioEquipment &&
                            (currentExercise.speedMph != null || currentExercise.inclinePercent != null) &&
                            _currentIntervals.length > 1)
                          SizedBox(
                            height: 220,
                            child: _buildIntervalsList(
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                              elevatedColor: elevatedColor,
                            ),
                          ),

                        // Upcoming warmup exercises
                        if (_currentExerciseIndex < widget.exercises.length - 1)
                          _buildUpcomingExercises(
                            textSecondary: textSecondary,
                            elevatedColor: elevatedColor,
                          ),

                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),

                // Action buttons (pinned below the scroll) — the rest card
                // owns its own skip/±10s controls, so this row hides while
                // resting instead of offering two competing sets of controls.
                if (!_isResting) _buildActionButtons(),
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
              Icon(Icons.timer_outlined,
                  size: 16, color: context.accentColor),
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
          child: Text(
            AppLocalizations.of(context).warmupPhaseSkipWarmup,
            style: TextStyle(
              color: context.accentColor,
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
            color: context.accentColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.local_fire_department,
            color: context.accentColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),

        // Title and count
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).workoutDetailWarmUp,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: context.accentColor,
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
        color: context.accentColor,
        minHeight: 4,
      ),
    );
  }

  /// E2E #125 ask #2 — the rest countdown shown BETWEEN warm-up moves.
  /// Mirrors `_buildCurrentExercise`'s layout (same icon-circle + big
  /// countdown shape) so swapping between the two doesn't jar, but in cyan
  /// (not orange) so "resting" reads visually distinct from "working".
  Widget _buildRestCard({
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final nextExercise = _currentExerciseIndex + 1 < widget.exercises.length
        ? widget.exercises[_currentExerciseIndex + 1]
        : null;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: context.accentColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.self_improvement_rounded,
              size: 64,
              color: context.accentColor,
            ),
          ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.8, 0.8)),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context).workoutSummaryAdvancedRest.toUpperCase(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: context.accentColor,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            WorkoutTimerController.formatTime(
                _restTimerController.secondsRemaining),
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w300,
              color: context.accentColor,
            ),
          ),
          if (nextExercise != null) ...[
            const SizedBox(height: 16),
            Text(
              'Next: ${nextExercise.name}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DurationAdjustChip(label: '−10s', onTap: () => _adjustRest(-10)),
              const SizedBox(width: 10),
              TextButton(
                onPressed: _skipRest,
                child: Text(
                  AppLocalizations.of(context).easyRestOverlaySkipRest,
                  style: TextStyle(
                    color: context.accentColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _DurationAdjustChip(label: '+10s', onTap: () => _adjustRest(10)),
            ],
          ),
        ],
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
              color: context.accentColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              exercise.icon,
              size: 64,
              color: context.accentColor,
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
              style: TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.w300,
                color: context.accentColor,
              ),
            )
                .animate(onPlay: (controller) => controller.repeat())
                .shimmer(
                    duration: 2000.ms,
                    color: context.accentColor.withOpacity(0.3))
          else
            Text(
              AppLocalizations.of(context)!.warmupPhaseScreenSec(
                _durationOverrides[_currentExerciseIndex] ?? exercise.duration,
              ),
              style: TextStyle(
                fontSize: 24,
                color: textSecondary,
              ),
            ),

          const SizedBox(height: 12),
          // E2E #125 ask #2 — editable hold duration. Works whether the
          // timer is idle or already counting down (see
          // `_adjustCurrentDuration`).
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DurationAdjustChip(
                label: '−10s',
                onTap: () => _adjustCurrentDuration(-10),
              ),
              const SizedBox(width: 10),
              _DurationAdjustChip(
                label: '+10s',
                onTap: () => _adjustCurrentDuration(10),
              ),
            ],
          ),

          // Cardio params display (non-cardio exercises only - cardio gets the editable fields below)
          if (exercise.isCardioEquipment && exercise.speedMph == null && exercise.inclinePercent == null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: context.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.accentColor.withOpacity(0.3)),
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
                label: AppLocalizations.of(context).warmupPhaseSpeed,
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
                label: AppLocalizations.of(context).warmupPhaseIncline,
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
                color: context.accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.accentColor.withOpacity(0.4)),
              ),
              child: Icon(Icons.add, color: context.accentColor, size: 22),
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
                AppLocalizations.of(context).warmupPhaseIntervals,
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
                          color: isActive ? context.accentColor : textPrimary,
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
          borderSide: BorderSide(color: context.accentColor),
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
          AppLocalizations.of(context).warmupPhaseUpNext,
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
                margin: const EdgeInsetsDirectional.only(end: 6),
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
                  ? context.accentColor.withOpacity(0.3)
                  : context.accentColor,
              foregroundColor: isTimerRunning ? context.accentColor : Colors.white,
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
                  ? AppLocalizations.of(context).warmupPhasePause
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
              backgroundColor: context.accentColor,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: Icon(isLastExercise ? Icons.check : Icons.skip_next),
            label: Text(
              isLastExercise ? AppLocalizations.of(context).warmupPhaseStartWorkout : AppLocalizations.of(context).commonNext,
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

/// A small pill button for the ±10s duration/rest nudges (E2E #125 ask #2).
class _DurationAdjustChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _DurationAdjustChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = (isDark ? Colors.white : Colors.black).withOpacity(0.22);
    final fg = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: fg,
          ),
        ),
      ),
    );
  }
}
