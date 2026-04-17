import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/default_weights.dart';
import '../../../core/services/rest_tip_service.dart';
import '../../../core/services/achievement_prompt_service.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/rest_suggestion.dart';
import '../../../data/rest_messages.dart';
import '../../../core/providers/sound_preferences_provider.dart';
import '../../../core/providers/tts_provider.dart';
import '../../../core/services/posthog_service.dart';
import '../../../data/services/api_client.dart';
import '../../../utils/tz.dart';
import '../../../widgets/glass_sheet.dart';
import '../controllers/workout_timer_controller.dart';
import '../models/workout_state.dart';
import '../../../core/models/set_progression.dart';
import '../widgets/inline_rest_row.dart';
import '../../ai_settings/ai_settings_screen.dart';
import '../../../services/intra_workout_autoregulator.dart';
import 'package:dio/dio.dart';

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

  // ── Timer/Rest Methods ──

  /// Handle rest timer completion
  void handleRestComplete() {
    final currentExercise = exercises[currentExerciseIndex];
    final groupId = currentExercise.supersetGroup;

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

    // Mark start time for the next set
    currentSetStartTime = DateTime.now();

    setState(() {
      isResting = false;
      isRestingBetweenExercises = false;
      showInlineRest = false;
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
        margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: suggestion.action != AutoregAction.swapExercise
            ? SnackBarAction(
                label: 'Accept',
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

  /// Handle inline rest note added
  void handleInlineRestNote(String note) {
    final exerciseSets = completedSets[currentExerciseIndex];
    if (exerciseSets != null && exerciseSets.isNotEmpty) {
      final lastIndex = exerciseSets.length - 1;
      exerciseSets[lastIndex] = exerciseSets[lastIndex].copyWith(notes: note);
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
    return InlineRestRow(
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
              'What is RPE?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Rate of Perceived Exertion measures how hard a set felt:',
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
                child: const Text(
                  'Got it',
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
    final exercise = exercises[currentExerciseIndex];
    final completedSetsList = completedSets[currentExerciseIndex] ?? [];

    if (completedSetsList.isEmpty) return;

    setState(() => isLoadingRestSuggestion = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();
      if (userId == null) {
        setState(() => isLoadingRestSuggestion = false);
        return;
      }

      final muscleGroup = (exercise.muscleGroup ?? exercise.primaryMuscle ?? '').toLowerCase();
      final isCompound = muscleGroup.contains('chest') ||
          muscleGroup.contains('back') ||
          muscleGroup.contains('legs') ||
          muscleGroup.contains('quads') ||
          muscleGroup.contains('hamstrings') ||
          muscleGroup.contains('glutes') ||
          muscleGroup.contains('shoulders');

      final totalSets = totalSetsPerExercise[currentExerciseIndex] ?? 3;
      final setsRemaining = totalSets - completedSetsList.length;

      final response = await apiClient.dio.post(
        '/workouts/rest-suggestion',
        data: {
          'rpe': lastSetRpe ?? 7,
          'exercise_type': 'strength',
          'exercise_name': exercise.name,
          'sets_remaining': setsRemaining > 0 ? setsRemaining : 0,
          'sets_completed': completedSetsList.length,
          'is_compound': isCompound,
          'muscle_group': exercise.muscleGroup ?? exercise.primaryMuscle,
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
        setState(() => isLoadingRestSuggestion = false);
      }
    } on DioException catch (e) {
      debugPrint('❌ [Rest] DioException: ${e.message}');
      debugPrint('❌ [Rest] Response: ${e.response?.statusCode} ${e.response?.data}');
      if (mounted) {
        setState(() => isLoadingRestSuggestion = false);
      }
    } catch (e) {
      debugPrint('❌ [Rest] Error fetching suggestion: $e');
      if (mounted) {
        setState(() => isLoadingRestSuggestion = false);
      }
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
