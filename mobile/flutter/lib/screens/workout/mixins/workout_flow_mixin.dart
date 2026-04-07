import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/set_progression.dart';
import '../../../core/providers/weight_increments_provider.dart';
import '../../../core/providers/workout_mini_player_provider.dart';
import '../../../core/services/posthog_service.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/workout.dart';
import '../../../data/providers/xp_provider.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/services/api_client.dart';
import '../../../core/providers/ble_heart_rate_provider.dart';
import '../../../core/providers/heart_rate_provider.dart';
import '../../../core/providers/warmup_duration_provider.dart';
import '../../../data/services/ble_heart_rate_service.dart';
import '../../../data/services/workout_notification_service.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/app_tour/app_tour_controller.dart';
import '../../ai_settings/ai_settings_screen.dart';
import '../controllers/workout_timer_controller.dart';
import '../models/workout_state.dart';
import '../widgets/quit_workout_dialog.dart';

/// Mixin providing workout flow control: pause, quit, minimize,
/// warmup/stretch phases, and workout completion/finalization.
mixin WorkoutFlowMixin<T extends StatefulWidget> on State<T> {
  // ── State access (implemented by main class) ──

  WidgetRef get ref;
  List<WorkoutExercise> get exercises;
  int get currentExerciseIndex;
  Map<int, List<SetLog>> get completedSets;
  Map<int, int> get totalSetsPerExercise;
  Map<int, SetProgressionPattern> get exerciseProgressionPattern;
  WorkoutTimerController get timerController;
  List<Map<String, dynamic>> get restIntervals;
  int get totalDrinkIntakeMl;
  List<Map<String, dynamic>> get drinkEvents;
  bool get isPaused;
  set isPaused(bool value);
  bool get isResting;
  int get viewingExerciseIndex;
  WorkoutPhase get currentPhase;
  set currentPhase(WorkoutPhase value);
  List<WarmupExerciseData>? get warmupExercises;
  List<StretchExerciseData>? get stretchExercises;
  Set<int> get skippedExercises;

  // AI/UI interaction counters (for metadata)
  int get aiCoachOpened;
  int get aiChatMessagesSent;
  int get aiWeightSuggestionsShown;
  int get aiWeightSuggestionsAccepted;
  int get fatigueAlertsTriggered;
  int get coachTipsShown;
  int get coachTipsDismissed;
  int get restSuggestionsShown;
  int get exerciseInfoOpened;
  int get breathingGuideOpened;
  int get exerciseSwapsRequested;
  int get videoViews;

  // Widget access
  dynamic get workoutWidget; // The StatefulWidget with workout property

  // Cross-mixin method access
  String buildSetsJson();
  Future<void> fetchMediaForExercise(WorkoutExercise exercise);
  void showCoachTipIfNeeded();

  // ── Workout Flow Methods ──

  /// Toggle pause state
  void togglePause() {
    setState(() {
      isPaused = !isPaused;
    });
    timerController.setPaused(isPaused);
    updateWorkoutNotification();
  }

  /// Handle warmup phase completion
  void handleWarmupComplete() {
    HapticFeedback.heavyImpact();

    ref.read(posthogServiceProvider).capture(
      eventName: 'warmup_completed',
      properties: {
        'workout_id': (workoutWidget as dynamic).workout.id ?? '',
      },
    );

    setState(() {
      currentPhase = WorkoutPhase.active;
    });
    fetchMediaForExercise(exercises[0]);
    showCoachTipIfNeeded();
  }

  /// Handle warmup skip
  void handleSkipWarmup() {
    ref.read(posthogServiceProvider).capture(
      eventName: 'warmup_skipped',
      properties: {
        'workout_id': (workoutWidget as dynamic).workout.id ?? '',
      },
    );
    handleWarmupComplete();
  }

  /// Handle stretch phase completion
  void handleStretchComplete() {
    ref.read(posthogServiceProvider).capture(
      eventName: 'stretch_completed',
      properties: {
        'workout_id': (workoutWidget as dynamic).workout.id ?? '',
      },
    );

    timerController.stopWorkoutTimer();
    cancelWorkoutNotification();
    finalizeWorkoutCompletion();
  }

  /// Handle stretch skip
  void handleSkipStretch() {
    ref.read(posthogServiceProvider).capture(
      eventName: 'stretch_skipped',
      properties: {
        'workout_id': (workoutWidget as dynamic).workout.id ?? '',
      },
    );
    handleStretchComplete();
  }

  /// Finalize workout: save to backend, get PRs, and navigate to complete screen
  Future<void> finalizeWorkoutCompletion() async {
    // Clear mini player state so reopening this workout starts fresh
    ref.read(workoutMiniPlayerProvider.notifier).close();

    setState(() => currentPhase = WorkoutPhase.complete);

    final workout = (workoutWidget as dynamic).workout as Workout;
    final challengeId = (workoutWidget as dynamic).challengeId as String?;
    final challengeData = (workoutWidget as dynamic).challengeData as Map<String, dynamic>?;

    final phTotalSets = completedSets.values.fold<int>(0, (sum, list) => sum + list.length);
    int phTotalReps = 0;
    double phTotalVolumeKg = 0.0;
    for (final sets in completedSets.values) {
      for (final setLog in sets) {
        phTotalReps += setLog.reps;
        phTotalVolumeKg += setLog.reps * setLog.weight;
      }
    }

    ref.read(posthogServiceProvider).capture(
      eventName: 'workout_completed',
      properties: {
        'workout_id': workout.id ?? '',
        'workout_name': workout.name ?? '',
        'duration_seconds': timerController.workoutSeconds,
        'total_sets': phTotalSets,
        'total_reps': phTotalReps,
        'volume_kg': phTotalVolumeKg,
      },
    );

    String? workoutLogId;
    int totalCompletedSets = 0;
    int totalReps = 0;
    double totalVolumeKg = 0.0;
    int totalRestSeconds = 0;
    double avgRestSeconds = 0.0;
    List<PersonalRecordInfo>? personalRecords;
    PerformanceComparisonInfo? performanceComparison;
    WorkoutCompletionResponse? completionResponse;

    try {
      final workoutRepo = ref.read(workoutRepositoryProvider);
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      debugPrint('🔍 [Complete] workout.id: ${workout.id}');
      debugPrint('🔍 [Complete] userId: $userId');

      if (workout.id != null && userId != null) {
        debugPrint('🏋️ Saving workout log to backend...');
        final setsJson = buildSetsJson();
        final metadata = _buildWorkoutMetadata(workout);
        debugPrint('🔍 [Complete] setsJson length: ${setsJson.length}');

        final workoutLog = await workoutRepo.createWorkoutLog(
          workoutId: workout.id!,
          userId: userId,
          setsJson: setsJson,
          totalTimeSeconds: timerController.workoutSeconds,
          metadata: jsonEncode(metadata),
        );

        if (workoutLog != null) {
          debugPrint('✅ Workout log created: ${workoutLog['id']}');
          workoutLogId = workoutLog['id'] as String;
          await logAllSetPerformances(workoutLogId, userId);
        } else {
          debugPrint('❌ [Complete] createWorkoutLog returned null - workoutLogId will be null');
        }

        totalCompletedSets = completedSets.values.fold<int>(
          0, (sum, list) => sum + list.length,
        );
        final exercisesWithSets = completedSets.values.where((l) => l.isNotEmpty).length;

        for (final sets in completedSets.values) {
          for (final setLog in sets) {
            totalReps += setLog.reps;
            totalVolumeKg += setLog.reps * setLog.weight;
          }
        }

        if (restIntervals.isNotEmpty) {
          for (final interval in restIntervals) {
            totalRestSeconds += (interval['rest_seconds'] as int?) ?? 0;
          }
          avgRestSeconds = totalRestSeconds / restIntervals.length;
        }

        // Run independent API calls in parallel for faster navigation
        final futures = <Future>[];

        if (totalDrinkIntakeMl > 0) {
          futures.add(workoutRepo.logDrinkIntake(
            workoutId: workout.id!,
            userId: userId,
            amountMl: totalDrinkIntakeMl,
            drinkType: 'water',
          ).then((_) => debugPrint('💧 Logged drink intake: ${totalDrinkIntakeMl}ml')));
        }

        futures.add(workoutRepo.logWorkoutExit(
          workoutId: workout.id!,
          userId: userId,
          exitReason: 'completed',
          exercisesCompleted: exercisesWithSets,
          totalExercises: exercises.length,
          setsCompleted: totalCompletedSets,
          timeSpentSeconds: timerController.workoutSeconds,
          progressPercentage: exercises.isNotEmpty
              ? (exercisesWithSets / exercises.length * 100)
              : 100.0,
        ).then((_) => debugPrint('✅ Workout exit logged as completed')));

        futures.add(logSupersetUsage(userId));

        // completeWorkout returns PRs/comparison data - run in parallel but capture result
        final completionFuture = workoutRepo.completeWorkout(workout.id!);
        futures.add(completionFuture);

        await Future.wait(futures);
        // Future already resolved by Future.wait, so this returns immediately
        completionResponse = await completionFuture;
        debugPrint('✅ Workout marked as complete');

        ref.read(xpProvider.notifier).markWorkoutCompleted(workoutId: workout.id);

        if (completionResponse != null && completionResponse.hasPRs) {
          personalRecords = completionResponse.personalRecords;
          debugPrint('🏆 Got ${personalRecords.length} PRs from completion API');
        }

        if (completionResponse != null && completionResponse.performanceComparison != null) {
          performanceComparison = completionResponse.performanceComparison;
          debugPrint('📊 Got performance comparison');
        }
      } else {
        debugPrint('❌ [Complete] Skipping workout log creation: workout.id=${workout.id}, userId=$userId');
      }
    } catch (e) {
      debugPrint('❌ Failed to complete workout: $e');
    }

    final exercisesPerformance = <Map<String, dynamic>>[];
    for (int i = 0; i < exercises.length; i++) {
      final exercise = exercises[i];
      final sets = completedSets[i] ?? [];
      if (sets.isNotEmpty) {
        final avgWeight = sets.fold<double>(0, (sum, s) => sum + s.weight) / sets.length;
        final totalExReps = sets.fold<int>(0, (sum, s) => sum + s.reps);
        exercisesPerformance.add({
          'name': exercise.name,
          'sets': sets.length,
          'reps': totalExReps,
          'weight_kg': avgWeight,
        });
      }
    }

    int completionCalories = 0;
    if (completionResponse != null) {
      completionCalories = completionResponse.performanceComparison
          ?.workoutComparison.currentCalories ?? 0;
      if (completionCalories <= 0) {
        completionCalories = completionResponse.workout.estimatedCalories;
      }
    }
    if (completionCalories <= 0) {
      completionCalories = workout.estimatedCalories;
    }

    if (mounted) {
      debugPrint('🏋️ [Complete] Navigating to workout-complete with workoutLogId: $workoutLogId, calories: $completionCalories');
      context.go('/workout-complete', extra: {
        'workout': workout,
        'duration': timerController.workoutSeconds,
        'calories': completionCalories,
        'drinkIntakeMl': totalDrinkIntakeMl,
        'restIntervals': restIntervals.length,
        'workoutLogId': workoutLogId,
        'exercisesPerformance': exercisesPerformance,
        'totalRestSeconds': totalRestSeconds,
        'avgRestSeconds': avgRestSeconds,
        'totalSets': totalCompletedSets,
        'totalReps': totalReps,
        'totalVolumeKg': totalVolumeKg,
        'challengeId': challengeId,
        'challengeData': challengeData,
        'personalRecords': personalRecords,
        'performanceComparison': performanceComparison,
      });
    }
  }

  /// Build comprehensive workout metadata JSON
  Map<String, dynamic> _buildWorkoutMetadata(Workout workout) {
    final exerciseOrder = exercises.asMap().entries.map((e) => {
      'index': e.key,
      'exercise_id': e.value.exerciseId ?? e.value.libraryId,
      'exercise_name': e.value.name,
      'time_spent_seconds': 0, // Exercise time tracking is in main class
      if (e.value.supersetGroup != null) 'superset_group': e.value.supersetGroup,
      if (e.value.supersetOrder != null) 'superset_order': e.value.supersetOrder,
    }).toList();

    final supersetGroups = <int, List<Map<String, dynamic>>>{};
    for (final exercise in exercises) {
      if (exercise.supersetGroup != null) {
        supersetGroups[exercise.supersetGroup!] ??= [];
        supersetGroups[exercise.supersetGroup!]!.add({
          'name': exercise.name,
          'muscle_group': exercise.muscleGroup,
          'order': exercise.supersetOrder,
        });
      }
    }

    final progressionModels = <String, String>{};
    for (int i = 0; i < exercises.length; i++) {
      final pattern = exerciseProgressionPattern[i] ?? SetProgressionPattern.pyramidUp;
      progressionModels[exercises[i].name] = pattern.storageKey;
    }

    final incrementState = ref.read(weightIncrementsProvider);

    return {
      'exercise_order': exerciseOrder,
      'rest_intervals': restIntervals,
      'drink_intake_ml': totalDrinkIntakeMl,
      'drink_events': drinkEvents,
      'progression_models': progressionModels,
      'increment_settings': {
        'dumbbell': incrementState.dumbbell,
        'barbell': incrementState.barbell,
        'machine': incrementState.machine,
        'kettlebell': incrementState.kettlebell,
        'cable': incrementState.cable,
        'unit': incrementState.unit,
      },
      if (supersetGroups.isNotEmpty) 'supersets': supersetGroups.entries.map((e) => {
        'group_id': e.key,
        'exercises': e.value,
      }).toList(),
      // Warmup/stretch exercises
      'warmup_exercises': warmupExercises?.map((e) => {
        'name': e.name,
        'duration_seconds': e.duration,
        'equipment': e.equipment,
        'is_staple': e.isStaple,
        if (e.inclinePercent != null) 'incline_percent': e.inclinePercent,
        if (e.speedMph != null) 'speed_mph': e.speedMph,
        if (e.rpm != null) 'rpm': e.rpm,
        if (e.resistanceLevel != null) 'resistance_level': e.resistanceLevel,
        if (e.strokeRateSpm != null) 'stroke_rate_spm': e.strokeRateSpm,
      }).toList() ?? [],
      'stretch_exercises': stretchExercises?.map((e) => {
        'name': e.name,
        'duration_seconds': e.duration,
        'equipment': e.equipment,
        if (e.inclinePercent != null) 'incline_percent': e.inclinePercent,
        if (e.speedMph != null) 'speed_mph': e.speedMph,
        if (e.rpm != null) 'rpm': e.rpm,
        if (e.resistanceLevel != null) 'resistance_level': e.resistanceLevel,
        if (e.strokeRateSpm != null) 'stroke_rate_spm': e.strokeRateSpm,
      }).toList() ?? [],
      'warmup_completed': currentPhase != WorkoutPhase.warmup,
      'stretch_completed': currentPhase == WorkoutPhase.complete,
      'skipped_exercise_indices': skippedExercises.toList(),
      'ai_interactions': {
        'coach_opened': aiCoachOpened,
        'chat_messages_sent': aiChatMessagesSent,
        'weight_suggestions_shown': aiWeightSuggestionsShown,
        'weight_suggestions_accepted': aiWeightSuggestionsAccepted,
        'fatigue_alerts_triggered': fatigueAlertsTriggered,
        'coach_tips_shown': coachTipsShown,
        'coach_tips_dismissed': coachTipsDismissed,
        'rest_suggestions_shown': restSuggestionsShown,
        'exercise_info_opened': exerciseInfoOpened,
        'breathing_guide_opened': breathingGuideOpened,
        'exercise_swaps_requested': exerciseSwapsRequested,
        'video_views': videoViews,
      },
      // Heart rate data (if watch/BLE connected)
      if (ref.read(workoutHeartRateHistoryProvider).isNotEmpty) 'heart_rate': () {
        final stats = ref.read(workoutHeartRateHistoryProvider.notifier).getStats();
        final readings = ref.read(workoutHeartRateHistoryProvider);
        return {
          'avg_bpm': stats?.avg,
          'max_bpm': stats?.max,
          'min_bpm': stats?.min,
          'readings': readings
              .map((r) => {'bpm': r.bpm, 'timestamp': r.timestamp.toIso8601String()})
              .toList(),
        };
      }(),
    };
  }

  /// Log all set performances to backend
  Future<void> logAllSetPerformances(String workoutLogId, String userId) async {
    final workoutRepo = ref.read(workoutRepositoryProvider);

    for (int i = 0; i < exercises.length; i++) {
      final exercise = exercises[i];
      final sets = completedSets[i] ?? [];
      final pattern = exerciseProgressionPattern[i] ?? SetProgressionPattern.pyramidUp;

      for (int j = 0; j < sets.length; j++) {
        final setLog = sets[j];
        final setTarget = exercise.getTargetForSet(j + 1);
        try {
          await workoutRepo.logSetPerformance(
            workoutLogId: workoutLogId,
            exerciseId: exercise.exerciseId ?? exercise.libraryId ?? exercise.name,
            exerciseName: exercise.name,
            setNumber: j + 1,
            repsCompleted: setLog.reps,
            weightKg: setLog.weight,
            userId: userId,
            rpe: setLog.rpe?.toDouble(),
            rir: setLog.rir,
            notes: setLog.notes,
            aiInputSource: setLog.aiInputSource,
            targetWeightKg: setTarget?.targetWeightKg ?? exercise.weight?.toDouble(),
            targetReps: setTarget?.targetReps ?? exercise.reps,
            progressionModel: pattern.storageKey,
            setDurationSeconds: setLog.durationSeconds,
            restDurationSeconds: setLog.restDurationSeconds,
          );
        } catch (e) {
          debugPrint('⚠️ Failed to log set performance: $e');
        }
      }
    }
    debugPrint('💪 Logged ${completedSets.values.fold<int>(0, (s, l) => s + l.length)} set performances');
  }

  /// Log superset usage to backend for analytics
  Future<void> logSupersetUsage(String userId) async {
    final supersetGroups = <int, List<WorkoutExercise>>{};
    for (final exercise in exercises) {
      if (exercise.supersetGroup != null) {
        supersetGroups[exercise.supersetGroup!] ??= [];
        supersetGroups[exercise.supersetGroup!]!.add(exercise);
      }
    }

    if (supersetGroups.isEmpty) {
      debugPrint('🔗 No supersets to log');
      return;
    }

    final apiClient = ref.read(apiClientProvider);
    final workout = (workoutWidget as dynamic).workout as Workout;

    for (final entry in supersetGroups.entries) {
      final groupId = entry.key;
      final groupExercises = entry.value;

      if (groupExercises.length >= 2) {
        groupExercises.sort((a, b) => (a.supersetOrder ?? 0).compareTo(b.supersetOrder ?? 0));

        try {
          await apiClient.post(
            '/supersets/logs',
            data: {
              'user_id': userId,
              'workout_id': workout.id,
              'exercise_1_name': groupExercises[0].name,
              'exercise_2_name': groupExercises[1].name,
              'exercise_1_muscle': groupExercises[0].muscleGroup,
              'exercise_2_muscle': groupExercises[1].muscleGroup,
              'superset_group': groupId,
            },
          );
          debugPrint('🔗 Logged superset group $groupId: ${groupExercises[0].name} + ${groupExercises[1].name}');

          for (int i = 2; i < groupExercises.length; i++) {
            await apiClient.post(
              '/supersets/logs',
              data: {
                'user_id': userId,
                'workout_id': workout.id,
                'exercise_1_name': groupExercises[i - 1].name,
                'exercise_2_name': groupExercises[i].name,
                'exercise_1_muscle': groupExercises[i - 1].muscleGroup,
                'exercise_2_muscle': groupExercises[i].muscleGroup,
                'superset_group': groupId,
              },
            );
            debugPrint('🔗 Logged superset continuation: ${groupExercises[i - 1].name} + ${groupExercises[i].name}');
          }
        } catch (e) {
          debugPrint('⚠️ Failed to log superset: $e');
        }
      }
    }
  }

  /// Show quit workout dialog
  void showQuitDialog() async {
    final workout = (workoutWidget as dynamic).workout as Workout;

    final totalSetsExpected = totalSetsPerExercise.values.fold<int>(0, (sum, sets) => sum + sets);
    final totalCompletedSets = completedSets.values.fold<int>(0, (sum, sets) => sum + sets.length);
    final exercisesWithCompletedSets = completedSets.values.where((sets) => sets.isNotEmpty).length;

    final progressPercent = totalSetsExpected > 0
        ? ((totalCompletedSets / totalSetsExpected) * 100).round()
        : 0;

    final result = await showQuitWorkoutDialog(
      context: context,
      progressPercent: progressPercent,
      totalCompletedSets: totalCompletedSets,
      exercisesWithCompletedSets: exercisesWithCompletedSets,
      timeSpentSeconds: timerController.workoutSeconds,
      coachPersona: ref.read(aiSettingsProvider).getCurrentCoach(),
      workoutName: workout.name,
    );

    if (result != null && mounted) {
      cancelWorkoutNotification();
      ref.read(workoutMiniPlayerProvider.notifier).close();
      logWorkoutExit(result.reason, result.notes);
      if (mounted) {
        context.pop();
        if (result.reason == 'injury') {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              AppSnackBar.info(context, 'Take it easy! Chat with your AI coach for injury advice.');
            }
          });
        }
      }
    }
  }

  /// Log workout exit when user quits early
  Future<void> logWorkoutExit(String reason, String? notes) async {
    final workout = (workoutWidget as dynamic).workout as Workout;
    final workoutRepo = ref.read(workoutRepositoryProvider);
    final apiClient = ref.read(apiClientProvider);
    final posthog = ref.read(posthogServiceProvider);

    try {
      final userId = await apiClient.getUserId();

      if (workout.id != null && userId != null) {
        final totalCompletedSets = completedSets.values.fold<int>(0, (sum, sets) => sum + sets.length);
        final exercisesWithSets = completedSets.values.where((sets) => sets.isNotEmpty).length;
        final progressPercentage = exercises.isNotEmpty
            ? (exercisesWithSets / exercises.length * 100)
            : 0.0;

        await workoutRepo.logWorkoutExit(
          workoutId: workout.id!,
          userId: userId,
          exitReason: reason,
          exercisesCompleted: exercisesWithSets,
          totalExercises: exercises.length,
          setsCompleted: totalCompletedSets,
          timeSpentSeconds: timerController.workoutSeconds,
          progressPercentage: progressPercentage,
          exitNotes: notes,
        );
        debugPrint('✅ [Quit] Logged workout exit: $reason');

        posthog.capture(
          eventName: 'workout_abandoned',
          properties: {
            'workout_id': workout.id ?? '',
            'exit_reason': reason,
            'sets_completed': totalCompletedSets,
            'exercises_completed': exercisesWithSets,
            'total_exercises': exercises.length,
            'progress_percent': progressPercentage,
            'duration_seconds': timerController.workoutSeconds,
          },
        );
      }
    } catch (e) {
      debugPrint('❌ [Quit] Failed to log workout exit: $e');
    }
  }

  /// Minimize workout to mini player (YouTube-style)
  void minimizeWorkout() {
    debugPrint('🎬 [Workout] Minimizing to mini player...');

    final workout = (workoutWidget as dynamic).workout as Workout;

    final completedSetsMap = <int, List<Map<String, dynamic>>>{};
    for (final entry in completedSets.entries) {
      completedSetsMap[entry.key] = entry.value.map((set) => {
        'reps': set.reps,
        'weight': set.weight,
        'setType': set.setType,
        'rpe': set.rpe,
        'rir': set.rir,
        'aiInputSource': set.aiInputSource,
      }).toList();
    }

    final currentExercise = currentExerciseIndex < exercises.length
        ? exercises[currentExerciseIndex]
        : null;
    final currentExerciseName = currentExercise?.name;
    final currentExerciseImageUrl = currentExercise?.gifUrl;

    ref.read(workoutMiniPlayerProvider.notifier).minimize(
      workout: workout,
      workoutSeconds: timerController.workoutSeconds,
      currentExerciseName: currentExerciseName,
      currentExerciseImageUrl: currentExerciseImageUrl,
      currentExerciseIndex: currentExerciseIndex,
      totalExercises: exercises.length,
      completedSets: completedSetsMap,
      isResting: isResting,
      restSecondsRemaining: timerController.restSecondsRemaining,
      isPaused: isPaused,
    );

    timerController.dispose();

    if (mounted) {
      context.pop();
    }
  }

  /// Push the latest workout state to the persistent notification.
  void updateWorkoutNotification() {
    if (exercises.isEmpty) return;
    final exerciseName = currentExerciseIndex < exercises.length
        ? exercises[currentExerciseIndex].name
        : 'Exercise';
    final progress = '${currentExerciseIndex + 1}/${exercises.length}';
    final timerText = WorkoutTimerController.formatTime(timerController.workoutSeconds);
    final workout = (workoutWidget as dynamic).workout as Workout;
    WorkoutNotificationService.instance.show(
      workoutName: workout.name ?? 'Workout',
      currentExerciseName: exerciseName,
      timerText: timerText,
      exerciseProgress: progress,
      isPaused: isPaused,
    );
  }

  /// Cancel the persistent notification and clear callbacks.
  void cancelWorkoutNotification() {
    WorkoutNotificationService.instance.cancel();
    WorkoutNotificationService.instance.clearCallbacks();
  }

  /// Trigger the workout onboarding tour.
  void triggerWorkoutTour() {
    final steps = [
      AppTourStep(
        id: 'workout_step_exercise',
        targetKey: AppTourKeys.exerciseCardKey,
        title: 'Current Exercise',
        description: 'Follow along with the video. Tap Info for full details and instructions.',
        position: TooltipPosition.below,
      ),
      AppTourStep(
        id: 'workout_step_sets',
        targetKey: AppTourKeys.setLoggingKey,
        title: 'Log Your Sets',
        description: 'Enter weight and reps, then check the box to complete each set. Your history saves automatically.',
        position: TooltipPosition.below,
      ),
      AppTourStep(
        id: 'workout_step_rir',
        targetKey: AppTourKeys.rirBarKey,
        title: 'Rate Your Effort (RIR)',
        description: 'RIR = Reps In Reserve. How many more reps could you do? 0 means failure, 5+ means easy. This helps the AI adjust your future weights.',
        position: TooltipPosition.below,
      ),
      AppTourStep(
        id: 'workout_step_swap',
        targetKey: AppTourKeys.swapExerciseKey,
        title: "Can't Do This?",
        description: 'Swap any exercise for a suitable alternative, create a superset, or switch sides with L/R.',
        position: TooltipPosition.above,
      ),
      AppTourStep(
        id: 'workout_step_rest',
        targetKey: AppTourKeys.restTimerKey,
        title: 'Rest Timer',
        description: 'Starts automatically between sets. Skip it whenever you\'re ready to go again.',
        position: TooltipPosition.below,
      ),
      AppTourStep(
        id: 'workout_step_ai',
        targetKey: AppTourKeys.workoutAiKey,
        title: 'Your AI Coach',
        description: 'Ask your coach anything mid-workout — form check, exercise alternatives, weight suggestions, or just how many sets you have left.',
        position: TooltipPosition.above,
        cornerRadius: 999,
        highlightColors: const [
          Color(0xFF9B59B6),
          Color(0xFF00BCD4),
          Color(0xFF3B82F6),
          Color(0xFF9B59B6),
        ],
      ),
    ];
    ref.read(appTourControllerProvider.notifier).checkAndShow('workout_tour', steps);
  }

  /// Attempt BLE HR auto-reconnect if enabled.
  void initBleHrAutoReconnect() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bleEnabled = ref.read(bleHrEnabledProvider);
      if (bleEnabled) {
        BleHeartRateService.instance.autoReconnect();
      }
    });
  }

  /// Check if warmup is enabled and skip to active phase if not.
  void checkWarmupEnabled() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final warmupState = ref.read(warmupDurationProvider);
      if (!warmupState.warmupEnabled) {
        setState(() {
          currentPhase = WorkoutPhase.active;
        });
        debugPrint('🏋️ [ActiveWorkout] Warmup disabled, skipping to active phase');
      }
    });
  }
}
