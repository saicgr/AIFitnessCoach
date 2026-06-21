import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/default_weights.dart';
import '../../../core/services/rest_tip_service.dart';
import '../../../core/services/weight_suggestion_service.dart';
import '../../../core/services/achievement_prompt_service.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/rest_suggestion.dart';
import '../../../data/rest_messages.dart';
import '../../../core/providers/sound_preferences_provider.dart';
import '../../../core/providers/tts_provider.dart';
import '../../../core/services/posthog_service.dart';
import '../../../data/services/api_client.dart';
import '../../../data/providers/beast_mode_provider.dart';
import '../../../data/providers/recovery_provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../core/providers/heart_rate_provider.dart';
import '../widgets/hr_recovery_policy.dart';
import '../../../utils/tz.dart';
import '../../../widgets/glass_sheet.dart';
import '../controllers/workout_timer_controller.dart';
import '../models/workout_state.dart';
import '../../../core/models/set_progression.dart';
import '../widgets/inline_rest_row.dart';
import '../../../widgets/tooltips/tooltip_anchors.dart';
import '../../ai_settings/ai_settings_screen.dart';
import '../../../services/intra_workout_autoregulator.dart';
import 'package:dio/dio.dart';

import '../../../l10n/generated/app_localizations.dart';
/// Mixin providing timer/rest functionality for the active workout screen.
mixin TimerRestMixin<T extends StatefulWidget> on State<T> {
  // ── State access (implemented by main class) ──

  WidgetRef get ref;
  WorkoutTimerController get timerController;
  List<WorkoutExercise> get exercises;
  int get currentExerciseIndex;
  Map<int, List<SetLog>> get completedSets;
  Map<int, int> get totalSetsPerExercise;
  Map<String, double> get exerciseMaxWeights;
  List<Map<String, dynamic>> get restIntervals;

  bool get isResting;
  set isResting(bool value);
  bool get isRestingBetweenExercises;
  set isRestingBetweenExercises(bool value);
  String get currentRestMessage;
  set currentRestMessage(String value);
  bool get showInlineRest;
  set showInlineRest(bool value);
  int get inlineRestDuration;
  set inlineRestDuration(int value);
  String? get inlineRestAiTip;
  set inlineRestAiTip(String? value);
  bool get isLoadingAiTip;
  set isLoadingAiTip(bool value);
  String? get inlineRestAchievementPrompt;
  set inlineRestAchievementPrompt(String? value);
  int? get inlineRestCurrentRpe;
  set inlineRestCurrentRpe(int? value);
  AdaptationFeedback? get inlineRestAdaptationFeedback;
  set inlineRestAdaptationFeedback(AdaptationFeedback? value);
  RestSuggestion? get restSuggestion;
  set restSuggestion(RestSuggestion? value);
  bool get isLoadingRestSuggestion;
  set isLoadingRestSuggestion(bool value);
  int? get lastSetRpe;
  set lastSetRpe(int? value);
  int? get lastSetRir;
  bool get useKg;
  double get weightIncrement;
  int get viewingExerciseIndex;
  TextEditingController get weightController;
  DateTime? get currentSetStartTime;
  set currentSetStartTime(DateTime? value);
  Map<int, List<int>> get actualRestDurations;

  // AI interaction counter
  int get restSuggestionsShown;
  set restSuggestionsShown(int value);

  // Cross-mixin method access
  void advanceToSupersetExercise(int nextIndex);
  List<int> getSupersetIndices(int groupId);
  bool isExerciseCompleted(int exerciseIndex);

  // ── HR-aware rest state (owned directly by this mixin) ──
  //
  // Bridges the live in-workout heart-rate stream into the rest timer: when a
  // between-set rest elapses but HR is still elevated, hold (gate) or nudge
  // (suggest) instead of auto-advancing. Active only when a live HR source is
  // connected; a silent no-op otherwise. v1 = between-SET rest only.

  /// Peak BPM captured during the just-finished set — basis for the recovery
  /// target + the recovery progress bar. Null when no HR source.
  int? hrRestPeakBpm;

  /// True while we're holding rest open waiting for HR to settle (drives the
  /// [HrRecoveryBanner] in the UI builder).
  bool isHrGating = false;

  /// How many +30s extensions the lifter has taken this rest — caps the
  /// suggest-mode nudge so it never nags indefinitely.
  int hrGateExtensions = 0;

  /// Effective HR-aware rest mode from Beast Mode config: 'off'|'suggest'|'gate'.
  String get hrRestMode => ref.read(beastModeConfigProvider).hrRestMode;

  /// User age (for max HR), when known.
  int? get userAgeForHr => ref.read(authStateProvider).user?.age;

  /// User resting HR (for the Karvonen target), best-effort — null if the
  /// recovery score hasn't loaded or the metric is unavailable.
  int? get restingHrForHr => ref.read(recoveryProvider).asData?.value?.restingHR;

  /// Capture the set's peak HR at rest start: max BPM in the last ~60s of
  /// session history, falling back to the latest live reading. Resets gate
  /// state for the new rest.
  void captureRestPeakHr() {
    int? peak;
    try {
      final history = ref.read(workoutHeartRateHistoryProvider);
      final now = DateTime.now();
      for (final r in history) {
        if (now.difference(r.timestamp).inSeconds <= 60) {
          if (peak == null || r.bpm > peak) peak = r.bpm;
        }
      }
      peak ??= ref.read(liveHeartRateProvider).value?.bpm;
    } catch (_) {
      peak = null;
    }
    hrRestPeakBpm = peak;
    isHrGating = false;
    hrGateExtensions = 0;
  }

  /// Decide, when a between-set rest hits zero, whether to hold for heart-rate
  /// recovery. Returns true if we entered a hold (caller must NOT advance).
  /// Fails open: any missing/stale data ⇒ false ⇒ today's behavior.
  bool maybeGateForHr() {
    // v1: between SETS only; never re-enter while already gating.
    if (isHrGating || isRestingBetweenExercises) return false;
    final mode = hrRestMode;
    if (mode != 'suggest' && mode != 'gate') return false; // 'off'

    final reading = ref.read(liveHeartRateProvider).value;
    // Need a FRESH reading — stale/absent HR ⇒ behave exactly as today.
    if (reading == null ||
        DateTime.now().difference(reading.timestamp).inSeconds > 12) {
      return false;
    }

    final target = HrRecoveryPolicy.recoveryTarget(
      age: userAgeForHr,
      restingHr: restingHrForHr,
      peakHr: hrRestPeakBpm,
      minHrThisRest: reading.bpm,
    );
    if (target == null) return false; // not computable
    if (HrRecoveryPolicy.isRecovered(reading.bpm, target.targetBpm)) {
      return false; // already settled — advance normally
    }
    // Suggest-mode cap: after enough +30s extensions, stop nudging.
    if (mode == 'suggest' && hrGateExtensions >= 3) return false;

    setState(() {
      isHrGating = true;
      showInlineRest = false; // banner replaces the inline row
    });
    return true;
  }

  /// HrRecoveryBanner → start the next set now (recovered, override, or cap).
  void onHrGateReady() {
    _logHrGateOutcome();
    _advanceAfterRest();
  }

  /// HrRecoveryBanner → rest [seconds] more, then re-check (suggest +30s path).
  void onHrGateExtend(int seconds) {
    hrGateExtensions++;
    setState(() {
      isHrGating = false;
      showInlineRest = true;
      inlineRestDuration = seconds;
    });
    // Restart a short between-set rest; when it elapses, handleRestComplete
    // re-evaluates HR (bounded by hrGateExtensions cap).
    timerController.startRestTimer(seconds);
    restIntervals.add({
      'exercise_id': exercises[currentExerciseIndex].id,
      'exercise_name': exercises[currentExerciseIndex].name,
      'prescribed_rest_seconds': seconds,
      'rest_seconds': seconds,
      'rest_type': 'between_sets',
      'recorded_at': Tz.timestamp(),
    });
  }

  /// Attach HR-recovery telemetry to the last rest interval at advance time.
  void _logHrGateOutcome() {
    if (restIntervals.isEmpty) return;
    final reading = ref.read(liveHeartRateProvider).value;
    final target = HrRecoveryPolicy.recoveryTarget(
      age: userAgeForHr,
      restingHr: restingHrForHr,
      peakHr: hrRestPeakBpm,
      minHrThisRest: reading?.bpm,
    );
    restIntervals.last['peak_hr'] = hrRestPeakBpm;
    restIntervals.last['hr_at_advance'] = reading?.bpm;
    restIntervals.last['recovery_target_hr'] = target?.targetBpm;
    restIntervals.last['recovery_method'] =
        target != null ? HrRecoveryPolicy.methodLabel(target.method) : null;
    restIntervals.last['hr_extensions'] = hrGateExtensions;
  }

  // ── Timer/Rest Methods ──

  /// Handle rest timer completion
  void handleRestComplete() {
    // Track actual rest taken (captured before timer zeroed remaining)
    final actualRest = timerController.actualRestElapsed;
    actualRestDurations[currentExerciseIndex] ??= [];
    actualRestDurations[currentExerciseIndex]!.add(actualRest);

    // Sync the actual rest back into the last `restIntervals` entry so the
    // post-workout "Rest Analysis" widget shows real rest vs prescribed
    // instead of prescribed-vs-prescribed. startRest() pushes the entry with
    // rest_seconds == prescribed; we overwrite it here once we know what the
    // user actually rested (including Skip Rest, which routes through this
    // same callback via timerController.skipRest → _endRest).
    if (restIntervals.isNotEmpty) {
      restIntervals.last['rest_seconds'] = actualRest;
    }

    // HR-aware rest: if enabled and live HR is still elevated, hold instead of
    // advancing. The HrRecoveryBanner then drives the rest of the flow
    // (onHrGateReady / onHrGateExtend). Fails open — no/stale HR ⇒ advance.
    if (maybeGateForHr()) return;

    _advanceAfterRest();
  }

  /// Finish the rest and move on to the next set/exercise. Extracted from
  /// [handleRestComplete] so the HR gate can defer it until the lifter is
  /// recovered (or overrides).
  void _advanceAfterRest() {
    final currentExercise = exercises[currentExerciseIndex];
    final groupId = currentExercise.supersetGroup;

    // Mark start time for the next set
    currentSetStartTime = DateTime.now();

    setState(() {
      isResting = false;
      isRestingBetweenExercises = false;
      showInlineRest = false;
      isHrGating = false;
      inlineRestAiTip = null;
      inlineRestAchievementPrompt = null;
      inlineRestAdaptationFeedback = null;
    });
    HapticFeedback.heavyImpact();

    ref.read(soundPreferencesProvider.notifier).playRestTimerEnd();
    ref.read(voiceAnnouncementsProvider.notifier).announceRestEndIfEnabled();

    if (groupId != null && currentExercise.isInSuperset) {
      final supersetIndices = getSupersetIndices(groupId);
      for (final idx in supersetIndices) {
        if (!isExerciseCompleted(idx)) {
          if (idx != currentExerciseIndex) {
            advanceToSupersetExercise(idx);
          }
          return;
        }
      }
    }
  }

  /// Start a rest timer
  void startRest(bool betweenExercises, {Duration? overrideDuration}) {
    final exercise = exercises[currentExerciseIndex];
    final restSeconds = overrideDuration?.inSeconds
        ?? exercise.restSeconds
        ?? (betweenExercises ? 120 : 90);

    // Snapshot the set's peak HR now (start of rest) for HR-aware rest.
    captureRestPeakHr();

    ref.read(posthogServiceProvider).capture(
      eventName: 'rest_started',
      properties: {
        'rest_duration_seconds': restSeconds,
        'exercise_index': currentExerciseIndex,
      },
    );

    final aiSettings = ref.read(aiSettingsProvider);

    RestContext? context;
    final exerciseSets = completedSets[currentExerciseIndex];
    if (exerciseSets != null && exerciseSets.isNotEmpty) {
      final lastSet = exerciseSets.last;
      final totalSets = totalSetsPerExercise[currentExerciseIndex] ?? 3;

      bool isPR = false;
      final previousMaxWeight = exerciseMaxWeights[exercise.name] ?? 0.0;
      if (lastSet.weight > 0 && lastSet.weight > previousMaxWeight) {
        isPR = true;
      }

      double? previousWeight;
      if (exerciseSets.length > 1) {
        previousWeight = exerciseSets[exerciseSets.length - 2].weight;
      }

      context = RestContext(
        exerciseName: exercise.name,
        muscleGroup: exercise.muscleGroup,
        reps: lastSet.reps,
        weightLifted: lastSet.weight,
        previousWeight: previousWeight,
        isLastSet: exerciseSets.length >= totalSets,
        isLastExercise: currentExerciseIndex >= exercises.length - 1,
        isPR: isPR,
        wasFast: lastSet.reps > 0 &&
            DateTime.now().difference(lastSet.completedAt).inSeconds.abs() < 5,
      );
    } else {
      context = RestContext(
        exerciseName: exercise.name,
        muscleGroup: exercise.muscleGroup,
        reps: 0,
        isLastSet: false,
        isLastExercise: currentExerciseIndex >= exercises.length - 1,
      );
    }

    final message = RestMessages.getMessage(
      aiSettings.coachingStyle,
      aiSettings.encouragementLevel,
      context: context,
    );

    setState(() {
      isResting = true;
      isRestingBetweenExercises = betweenExercises;
      currentRestMessage = message;
      showInlineRest = !betweenExercises;
      inlineRestDuration = restSeconds;
      inlineRestCurrentRpe = null;
    });

    debugPrint('🔴 [StartRest] betweenExercises=$betweenExercises, showInlineRest=$showInlineRest, isResting=$isResting');

    timerController.startRestTimer(restSeconds);

    if (!betweenExercises) {
      debugPrint('🔴 [StartRest] Fetching AI tip and achievement prompt');
      fetchInlineRestAiTip(exercise);
      fetchInlineRestAchievementPrompt(exercise);
    }

    restIntervals.add({
      'exercise_id': exercises[currentExerciseIndex].id,
      'exercise_name': exercises[currentExerciseIndex].name,
      'prescribed_rest_seconds': restSeconds,
      'rest_seconds': restSeconds, // Updated to actual rest in handleRestComplete
      'rest_type': betweenExercises ? 'between_exercises' : 'between_sets',
      'recorded_at': Tz.timestamp(),
    });
  }

  /// Fetch AI tip for inline rest row
  Future<void> fetchInlineRestAiTip(WorkoutExercise exercise) async {
    final exerciseSets = completedSets[currentExerciseIndex];
    if (exerciseSets == null || exerciseSets.isEmpty) return;

    final lastSet = exerciseSets.last;
    final totalSets = totalSetsPerExercise[currentExerciseIndex] ?? 3;
    final setsRemaining = totalSets - exerciseSets.length;

    setState(() => isLoadingAiTip = true);

    try {
      final restTipService = ref.read(restTipServiceProvider);
      final tip = await restTipService.getRestTip(
        exerciseName: exercise.name,
        weightKg: lastSet.weight,
        reps: lastSet.reps,
        rpe: lastSet.rpe,
        setsRemaining: setsRemaining,
        exerciseInstructions: exercise.instructions,
      );

      if (mounted) {
        setState(() {
          inlineRestAiTip = tip;
          isLoadingAiTip = false;
        });
      }
    } catch (e) {
      debugPrint('❌ [ActiveWorkout] Error fetching AI tip: $e');
      if (mounted) {
        setState(() => isLoadingAiTip = false);
      }
    }
  }

  /// Fetch achievement prompt for inline rest row
  Future<void> fetchInlineRestAchievementPrompt(WorkoutExercise exercise) async {
    final exerciseSets = completedSets[currentExerciseIndex];
    if (exerciseSets == null || exerciseSets.isEmpty) return;

    final lastSet = exerciseSets.last;
    final totalSets = totalSetsPerExercise[currentExerciseIndex] ?? 3;

    try {
      final achievementService = ref.read(achievementPromptServiceProvider);
      final coachSettings = ref.read(aiSettingsProvider);
      // Get previous set data for timing comparisons
      final previousSet = exerciseSets.length > 1 ? exerciseSets[exerciseSets.length - 2] : null;
      final rests = actualRestDurations[currentExerciseIndex];
      final latestRest = (rests != null && rests.isNotEmpty) ? rests.last : null;

      final prompt = await achievementService.getPromptForSet(
        exerciseName: exercise.name,
        currentWeight: lastSet.weight,
        currentReps: lastSet.reps,
        setNumber: exerciseSets.length,
        totalSets: totalSets,
        coachingStyle: coachSettings.coachingStyle,
        communicationTone: coachSettings.communicationTone,
        encouragementLevel: coachSettings.encouragementLevel,
        useEmojis: coachSettings.useEmojis,
        coachName: coachSettings.coachName,
        // Timing comparison data
        previousSetWeight: previousSet?.weight,
        previousSetReps: previousSet?.reps,
        currentDurationSeconds: lastSet.durationSeconds,
        previousDurationSeconds: previousSet?.durationSeconds,
        restDurationSeconds: latestRest,
        prescribedRestSeconds: exercise.restSeconds ?? 90,
      );

      if (mounted) {
        setState(() {
          inlineRestAchievementPrompt = prompt;
        });
      }
    } catch (e) {
      debugPrint('❌ [ActiveWorkout] Error fetching achievement prompt: $e');
    }
  }

  /// Handle inline rest RPE rating
  void handleInlineRestRpeRating(int rpe) {
    setState(() {
      inlineRestCurrentRpe = rpe;
      lastSetRpe = rpe;
    });

    final exerciseSets = completedSets[currentExerciseIndex];
    if (exerciseSets != null && exerciseSets.isNotEmpty) {
      final lastIndex = exerciseSets.length - 1;
      exerciseSets[lastIndex] = exerciseSets[lastIndex].copyWith(rpe: rpe);

      evaluateAutoregulation(exerciseSets[lastIndex], lastIndex + 1);
    }

    HapticFeedback.selectionClick();
  }

  /// Evaluate autoregulation after RPE is recorded for a set.
  void evaluateAutoregulation(SetLog setLog, int setNumber) {
    final exercise = exercises[currentExerciseIndex];
    final totalSets = totalSetsPerExercise[currentExerciseIndex] ?? 3;
    final targetReps = setLog.targetReps > 0 ? setLog.targetReps : (exercise.reps ?? 10);
    final isWarmup = setLog.setType == 'warmup';
    final reportedRpe = (setLog.rpe ?? 7).toDouble();
    final workingWeight = setLog.weight;

    final suggestion = IntraWorkoutAutoregulator.evaluateSet(
      setNumber: setNumber,
      totalPlannedSets: totalSets,
      completedReps: setLog.reps,
      targetReps: targetReps,
      reportedRpe: reportedRpe,
      targetRpe: null,
      workingWeight: workingWeight > 0 ? workingWeight : null,
      isWarmup: isWarmup,
    );

    if (suggestion != null && mounted) {
      showAutoregSuggestion(suggestion);
    }
  }

  /// Show a non-intrusive SnackBar with the autoregulation suggestion.
  void showAutoregSuggestion(AutoregSuggestion suggestion) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    final Color snackColor;
    final IconData snackIcon;
    switch (suggestion.action) {
      case AutoregAction.reduceWeight:
        snackColor = suggestion.adjustedWeight != null &&
                suggestion.adjustedWeight! > (double.tryParse(weightController.text) ?? 0)
            ? AppColors.success
            : AppColors.warning;
        snackIcon = suggestion.adjustedWeight != null &&
                suggestion.adjustedWeight! > (double.tryParse(weightController.text) ?? 0)
            ? Icons.trending_up
            : Icons.trending_down;
      case AutoregAction.reduceSets:
        snackColor = AppColors.warning;
        snackIcon = Icons.remove_circle_outline;
      case AutoregAction.swapExercise:
        snackColor = AppColors.error;
        snackIcon = Icons.swap_horiz;
      case AutoregAction.proceed:
        return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(snackIcon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                suggestion.message,
                style: const TextStyle(fontSize: 13, color: Colors.white),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: snackColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 8),
        margin: const EdgeInsetsDirectional.only(bottom: 80, start: 16, end: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: suggestion.action != AutoregAction.swapExercise
            ? SnackBarAction(
                label: AppLocalizations.of(context).timerRestMixinAccept,
                textColor: Colors.white,
                onPressed: () => acceptAutoregSuggestion(suggestion),
              )
            : null,
      ),
    );
  }

  /// Apply the accepted autoregulation suggestion.
  void acceptAutoregSuggestion(AutoregSuggestion suggestion) {
    switch (suggestion.action) {
      case AutoregAction.reduceWeight:
        if (suggestion.adjustedWeight != null) {
          final exercise = exercises[currentExerciseIndex];
          final displayWeight = useKg
              ? suggestion.adjustedWeight!
              : kgToDisplayLbs(suggestion.adjustedWeight!, exercise.equipment,
                exerciseName: exercise.name,);
          weightController.text = displayWeight.toStringAsFixed(1);
        }
        if (suggestion.adjustedSets != null) {
          setState(() {
            totalSetsPerExercise[currentExerciseIndex] = suggestion.adjustedSets!;
          });
        }
      case AutoregAction.reduceSets:
        if (suggestion.adjustedSets != null) {
          setState(() {
            totalSetsPerExercise[currentExerciseIndex] = suggestion.adjustedSets!;
          });
        }
      case AutoregAction.swapExercise:
        break;
      case AutoregAction.proceed:
        break;
    }

    HapticFeedback.mediumImpact();
  }

  /// Handle inline rest note added. Multiple sends append into the set's
  /// notes list — never replace, so users who tap send 3 times keep all 3.
  void handleInlineRestNote(String note) {
    final exerciseSets = completedSets[currentExerciseIndex];
    if (exerciseSets != null && exerciseSets.isNotEmpty) {
      final lastIndex = exerciseSets.length - 1;
      exerciseSets[lastIndex] = exerciseSets[lastIndex].appendNote(note);
    }
    HapticFeedback.mediumImpact();
  }

  /// Handle inline rest skip
  void handleInlineRestSkip() {
    ref.read(posthogServiceProvider).capture(
      eventName: 'rest_skipped',
      properties: {
        'exercise_index': currentExerciseIndex,
      },
    );
    timerController.skipRest();
  }

  /// Handle inline rest complete
  void handleInlineRestComplete() {
    setState(() {
      showInlineRest = false;
      inlineRestAiTip = null;
      inlineRestAchievementPrompt = null;
      inlineRestAdaptationFeedback = null;
    });
  }

  /// Handle inline rest time adjustment
  void handleInlineRestTimeAdjust(int adjustment) {
    setState(() {
      inlineRestDuration = (inlineRestDuration + adjustment).clamp(0, 600);
    });
    timerController.adjustRestTime(adjustment);
  }

  /// Build inline rest row for V2 design
  Widget buildInlineRestRowV2() {
    return KeyedSubtree(
      // Tour anchor: the inline (between-set) rest row is the real,
      // correctly-sized "Rest Timer" target. The key used to live on the
      // full-screen between-exercise RestTimerOverlay, which the tour treats as
      // "oversized" and never spotlights — so the Rest Timer step showed a
      // dimmed screen with no highlight. Keyed here so it highlights the actual
      // rest timer whenever it's on screen. (Single holder — removed from the
      // overlay to avoid a duplicate GlobalKey.)
      key: TooltipAnchors.restTimer,
      child: InlineRestRow(
      restDurationSeconds: inlineRestDuration,
      onRestComplete: handleInlineRestComplete,
      onSkipRest: handleInlineRestSkip,
      onAdjustTime: handleInlineRestTimeAdjust,
      onRateSet: handleInlineRestRpeRating,
      onAddNote: handleInlineRestNote,
      onShowRpeInfo: showRpeInfoSheet,
      achievementPrompt: inlineRestAchievementPrompt,
      aiTip: inlineRestAiTip,
      isLoadingAiTip: isLoadingAiTip,
      currentRpe: inlineRestCurrentRpe,
      adaptationFeedback: inlineRestAdaptationFeedback,
      weightUnit: useKg ? 'kg' : 'lb',
      ),
    );
  }

  /// Show RPE info sheet (for inline rest row)
  void showRpeInfoSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showGlassSheet(
      context: context,
      builder: (ctx) => GlassSheet(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(
              AppLocalizations.of(context).timerRestMixinWhatIsRpe,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              AppLocalizations.of(context).timerRestMixinRateOfPerceivedExertion,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
              ),
            ),
            const SizedBox(height: 16),

            buildRpeScaleRowV2('1-4', 'Very easy, lots left in tank', AppColors.success, isDark),
            buildRpeScaleRowV2('5-6', 'Moderate effort', AppColors.cyan, isDark),
            buildRpeScaleRowV2('7-8', 'Hard, could do 2-3 more reps', AppColors.orange, isDark),
            buildRpeScaleRowV2('9', 'Very hard, maybe 1 more rep', AppColors.orange, isDark),
            buildRpeScaleRowV2('10', 'Maximum effort, couldn\'t do more', AppColors.error, isDark),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.electricBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context).weightIncrementsGotIt,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      ),
    );
  }

  Widget buildRpeScaleRowV2(String range, String description, Color color, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 50,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              range,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Fetch AI-powered rest suggestion
  Future<void> fetchRestSuggestion() async {
    // Guard against duplicate concurrent fetches (a rebuild / re-entry would
    // otherwise refire and burn requests against the rate limit).
    if (isLoadingRestSuggestion) return;

    final exercise = exercises[currentExerciseIndex];
    final completedSetsList = completedSets[currentExerciseIndex] ?? [];

    if (completedSetsList.isEmpty) return;

    // Computed up front so the fallback can use them in any failure branch.
    final muscleGroup =
        (exercise.muscleGroup ?? exercise.primaryMuscle ?? '').toLowerCase();
    final isCompound = muscleGroup.contains('chest') ||
        muscleGroup.contains('back') ||
        muscleGroup.contains('legs') ||
        muscleGroup.contains('quads') ||
        muscleGroup.contains('hamstrings') ||
        muscleGroup.contains('glutes') ||
        muscleGroup.contains('shoulders');
    final totalSets = totalSetsPerExercise[currentExerciseIndex] ?? 3;
    final setsRemaining = totalSets - completedSetsList.length;
    final rpe = lastSetRpe ?? 7;

    // Deterministic fallback so a rate-limited / failed AI call still shows
    // real rest guidance instead of nothing (mirrors the weight-suggestion
    // fallback). Never blank.
    void applyFallback() {
      if (!mounted) return;
      setState(() {
        restSuggestion = WeightSuggestionService.generateRestSuggestion(
          rpe: rpe,
          isCompound: isCompound,
          setsCompleted: completedSetsList.length,
          setsRemaining: setsRemaining > 0 ? setsRemaining : 0,
        );
        isLoadingRestSuggestion = false;
      });
    }

    setState(() => isLoadingRestSuggestion = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();
      if (userId == null) {
        applyFallback();
        return;
      }

      // HR context (optional) so the backend can nudge the suggestion when the
      // lifter's heart rate is still elevated. All fields optional + fail-open.
      final hrReading = ref.read(liveHeartRateProvider).value;
      final currentHr = (hrReading != null &&
              DateTime.now().difference(hrReading.timestamp).inSeconds <= 12)
          ? hrReading.bpm
          : null;
      final age = userAgeForHr;
      final maxHr =
          (age != null && age > 0) ? HrRecoveryPolicy.maxHrForAge(age) : null;
      final hrTarget = HrRecoveryPolicy.recoveryTarget(
        age: age,
        restingHr: restingHrForHr,
        peakHr: hrRestPeakBpm,
        minHrThisRest: currentHr,
      );
      final hrRecovered = (currentHr != null && hrTarget != null)
          ? HrRecoveryPolicy.isRecovered(currentHr, hrTarget.targetBpm)
          : null;

      final response = await apiClient.dio.post(
        '/workouts/rest-suggestion',
        data: {
          'rpe': rpe,
          'exercise_type': 'strength',
          'exercise_name': exercise.name,
          'sets_remaining': setsRemaining > 0 ? setsRemaining : 0,
          'sets_completed': completedSetsList.length,
          'is_compound': isCompound,
          'muscle_group': exercise.muscleGroup ?? exercise.primaryMuscle,
          if (currentHr != null) 'current_hr': currentHr,
          if (hrRestPeakBpm != null) 'peak_hr': hrRestPeakBpm,
          if (restingHrForHr != null) 'resting_hr': restingHrForHr,
          if (maxHr != null) 'max_hr': maxHr,
          if (hrRecovered != null) 'hr_recovered': hrRecovered,
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200 && response.data != null) {
        final suggestion = RestSuggestion.fromJson(response.data);
        restSuggestionsShown++;
        setState(() {
          restSuggestion = suggestion;
          isLoadingRestSuggestion = false;
        });
        debugPrint('✅ [Rest] Got suggestion: ${suggestion.suggestedSeconds}s - ${suggestion.reasoning}');
      } else {
        applyFallback();
      }
    } on DioException catch (e) {
      // Includes 429 (rate limited) — degrade to the deterministic suggestion.
      debugPrint('❌ [Rest] DioException: ${e.message} (${e.response?.statusCode})');
      applyFallback();
    } catch (e) {
      debugPrint('❌ [Rest] Error fetching suggestion: $e');
      applyFallback();
    }
  }

  /// Accept AI rest suggestion and restart rest timer
  void acceptRestSuggestion(int seconds) {
    timerController.startRestTimer(seconds);
    setState(() => restSuggestion = null);
    HapticFeedback.mediumImpact();
  }

  /// Dismiss rest suggestion
  void dismissRestSuggestion() {
    setState(() => restSuggestion = null);
  }

  /// Format duration as MM:SS
  String formatDurationTimer(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
