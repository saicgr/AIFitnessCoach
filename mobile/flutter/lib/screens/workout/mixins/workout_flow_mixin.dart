import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/set_progression.dart';
import '../../../core/providers/active_workout_phase_provider.dart';
import '../../../core/providers/weight_increments_provider.dart';
import '../../../core/providers/workout_mini_player_provider.dart';
import '../../../core/providers/workout_ui_mode_provider.dart';
import '../../../core/services/posthog_service.dart';
import '../../../core/services/workout_tour_steps.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/workout.dart';
import '../../../data/providers/xp_provider.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/services/api_client.dart';
import '../../../core/providers/ble_heart_rate_provider.dart';
import '../../../core/providers/heart_rate_provider.dart';
import '../../../core/providers/warmup_duration_provider.dart';
import '../../../data/services/ble_heart_rate_service.dart';
import '../../../data/services/live_activity_service.dart';
import '../../../data/services/workout_notification_service.dart';
import '../../../widgets/app_snackbar.dart';
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
  Map<int, int> get exerciseTimeSeconds;
  DateTime? get currentExerciseStartTime;
  Map<int, int> get totalSetsPerExercise;
  Map<int, SetProgressionPattern> get exerciseProgressionPattern;
  WorkoutTimerController get timerController;
  List<Map<String, dynamic>> get restIntervals;
  int get totalDrinkIntakeMl;
  List<Map<String, dynamic>> get drinkEvents;
  bool get warmupSkipped;
  set warmupSkipped(bool value);
  bool get stretchSkipped;
  set stretchSkipped(bool value);
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

    // Flip the shared phase flag so Easy/Simple/Advanced agree that
    // warmup is done for this workout. Prevents warmup from re-triggering
    // if the user tier-swaps mid-session.
    ref.read(activeWorkoutWarmupDoneProvider.notifier).state = true;

    setState(() {
      currentPhase = WorkoutPhase.active;
    });
    fetchMediaForExercise(exercises[0]);
    showCoachTipIfNeeded();
  }

  /// Handle warmup skip
  void handleSkipWarmup() {
    warmupSkipped = true;
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
    stretchSkipped = true;
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

        // If the server already awarded the workout_complete XP inline
        // (new behavior — see backend/api/v1/workouts/crud_completion.py),
        // we only need to refresh the client XP state from the server.
        // Skip the redundant `/xp/award-goal-xp` POST — the server dedup
        // would treat it as a no-op anyway. Fall back to the legacy
        // client-driven call for older backends that don't set the flag.
        if (completionResponse?.xpAwarded == true) {
          debugPrint('✅ Server already awarded ${completionResponse!.xpAmount} XP — refreshing local state');
          // Refresh XP from backend so UI (level ring, streak) updates.
          unawaited(ref.read(xpProvider.notifier).loadUserXP(showLoading: false));
        } else {
          // Legacy path: client-driven XP award. Safe against older
          // backends that didn't include xp_awarded in the response.
          ref.read(xpProvider.notifier).markWorkoutCompleted(workoutId: workout.id);
        }

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
        // W1: Day 0-7 retention — trigger First Workout Forecast sheet
        'isFirstWorkout': completionResponse?.isFirstWorkout ?? false,
      });
    }
  }

  /// Build comprehensive workout metadata JSON
  Map<String, dynamic> _buildWorkoutMetadata(Workout workout) {
    // Finalize the currently-active exercise's elapsed time so the final
    // exercise (on which the user tapped "Finish Workout" without moving on)
    // doesn't get stuck at whatever was last persisted — usually nothing.
    // exerciseTimeSeconds for earlier exercises is populated in
    // exercise_navigation_mixin.dart:117 / :1037 on transitions.
    if (currentExerciseStartTime != null &&
        !exerciseTimeSeconds.containsKey(currentExerciseIndex)) {
      exerciseTimeSeconds[currentExerciseIndex] = DateTime.now()
          .difference(currentExerciseStartTime!)
          .inSeconds
          .clamp(0, 86400);
    }

    final exerciseOrder = exercises.asMap().entries.map((e) => {
      'index': e.key,
      'exercise_id': e.value.exerciseId ?? e.value.libraryId,
      'exercise_name': e.value.name,
      'time_spent_seconds': exerciseTimeSeconds[e.key] ?? 0,
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
      'warmup_status': warmupSkipped ? 'skipped' : (currentPhase != WorkoutPhase.warmup ? 'completed' : 'not_started'),
      'stretch_status': stretchSkipped ? 'skipped' : (currentPhase == WorkoutPhase.complete ? 'completed' : 'not_started'),
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

  /// Log all set performances to backend.
  ///
  /// Previously this looped per-set with sequential awaits — on a typical
  /// 20-set workout that's 20 round trips (~3–5s on the "Saving workout…"
  /// spinner). We now build the full payload locally and POST it to a bulk
  /// endpoint, so the whole call is one round trip.
  Future<void> logAllSetPerformances(String workoutLogId, String userId) async {
    final workoutRepo = ref.read(workoutRepositoryProvider);

    final records = <Map<String, dynamic>>[];
    for (int i = 0; i < exercises.length; i++) {
      final exercise = exercises[i];
      final sets = completedSets[i] ?? [];
      final pattern =
          exerciseProgressionPattern[i] ?? SetProgressionPattern.pyramidUp;

      for (int j = 0; j < sets.length; j++) {
        final setLog = sets[j];
        final setTarget = exercise.getTargetForSet(j + 1);
        records.add({
          'workout_log_id': workoutLogId,
          'user_id': userId,
          'exercise_id':
              exercise.exerciseId ?? exercise.libraryId ?? exercise.name,
          'exercise_name': exercise.name,
          'set_number': j + 1,
          'reps_completed': setLog.reps,
          'weight_kg': setLog.weight,
          'is_completed': true,
          'set_type': 'working',
          if (setLog.rpe != null) 'rpe': setLog.rpe!.toDouble(),
          if (setLog.rir != null) 'rir': setLog.rir,
          if (setLog.notes != null && setLog.notes!.isNotEmpty)
            'notes': setLog.notes,
          if (setLog.aiInputSource != null && setLog.aiInputSource!.isNotEmpty)
            'ai_input_source': setLog.aiInputSource,
          'target_weight_kg':
              setTarget?.targetWeightKg ?? exercise.weight?.toDouble(),
          if ((setTarget?.targetReps ?? exercise.reps) != null)
            'target_reps': setTarget?.targetReps ?? exercise.reps,
          'progression_model': pattern.storageKey,
          if (setLog.durationSeconds != null)
            'set_duration_seconds': setLog.durationSeconds,
          if (setLog.restDurationSeconds != null)
            'rest_duration_seconds': setLog.restDurationSeconds,
        });
      }
    }

    if (records.isEmpty) {
      debugPrint('💪 No sets to log');
      return;
    }
    final inserted = await workoutRepo.logSetPerformancesBulk(records);
    debugPrint('💪 Bulk-logged $inserted / ${records.length} set performances');
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

    // Build every superset pair POST upfront, then fire all in parallel.
    // Previously these were awaited one-by-one inside a nested loop.
    final futures = <Future<void>>[];
    for (final entry in supersetGroups.entries) {
      final groupId = entry.key;
      final groupExercises = entry.value;
      if (groupExercises.length < 2) continue;

      groupExercises.sort(
          (a, b) => (a.supersetOrder ?? 0).compareTo(b.supersetOrder ?? 0));

      Future<void> postPair(WorkoutExercise a, WorkoutExercise b) async {
        try {
          await apiClient.post(
            '/supersets/logs',
            data: {
              'user_id': userId,
              'workout_id': workout.id,
              'exercise_1_name': a.name,
              'exercise_2_name': b.name,
              'exercise_1_muscle': a.muscleGroup,
              'exercise_2_muscle': b.muscleGroup,
              'superset_group': groupId,
            },
          );
          debugPrint('🔗 Logged superset pair: ${a.name} + ${b.name}');
        } catch (e) {
          debugPrint('⚠️ Failed to log superset: $e');
        }
      }

      futures.add(postPair(groupExercises[0], groupExercises[1]));
      for (int i = 2; i < groupExercises.length; i++) {
        futures.add(postPair(groupExercises[i - 1], groupExercises[i]));
      }
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures);
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

  /// Build the current snapshot for the Live Activity / ongoing notification.
  /// Returns null if we don't have enough state to surface a meaningful view.
  WorkoutActivityState? buildLiveActivityState() {
    if (exercises.isEmpty) return null;
    final started = timerController.startedAt;
    if (started == null) return null;

    final safeIndex = currentExerciseIndex.clamp(0, exercises.length - 1);
    final exercise = exercises[safeIndex];
    final totalSetsForThisExercise = totalSetsPerExercise[safeIndex] ??
        exercise.sets ??
        3;
    final completedThisExercise = (completedSets[safeIndex] ?? const []).length;
    // Next set to log is completed+1 (1-based). Cap at total so we don't
    // flash "Set 5/4" during the transition between exercises.
    final currentSet = (completedThisExercise + 1)
        .clamp(1, totalSetsForThisExercise);

    final workout = (workoutWidget as dynamic).workout as Workout;

    return WorkoutActivityState(
      workoutName: workout.name ?? 'Workout',
      currentExercise: exercise.name,
      currentExerciseIndex: safeIndex + 1,
      totalExercises: exercises.length,
      currentSet: currentSet,
      totalSets: totalSetsForThisExercise,
      isResting: isResting,
      restEndsAt: isResting ? timerController.restEndsAt : null,
      isPaused: isPaused,
      startedAt: started,
      pausedDurationSeconds: timerController.totalPausedSeconds,
    );
  }

  /// Push the latest workout state to the Live Activity / ongoing notification.
  ///
  /// - iOS: always pushes — the Dynamic Island / Lock Screen surface lives
  ///   outside the app viewport, so an update is always visible.
  /// - Android: only pushes when the app is backgrounded. While the user is
  ///   looking at the workout screen, the shade entry is redundant and
  ///   re-firing it on every pause/exercise-change would pop it back into
  ///   view constantly.
  void updateWorkoutNotification() {
    final state = buildLiveActivityState();
    if (state == null) return;

    // Android-only foreground suppression.
    if (!_isIOS) {
      final lifecycle = WidgetsBinding.instance.lifecycleState;
      final isForeground = lifecycle == null ||
          lifecycle == AppLifecycleState.resumed;
      if (isForeground) return;
    }

    LiveActivityService.instance.update(state);
  }

  /// Cancel the persistent notification / Live Activity and clear callbacks.
  void cancelWorkoutNotification() {
    WorkoutNotificationService.instance.cancel();
    WorkoutNotificationService.instance.clearCallbacks();
    // Best-effort end of any live iOS Activity; safe to call multiple times.
    LiveActivityService.instance.end();
  }

  // Cheap platform check that doesn't require importing dart:io at the top
  // (keeps the mixin lean for code that doesn't care about platform).
  bool get _isIOS {
    // Import pulled transitively via live_activity_service.dart.
    return defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Tier-aware active-workout tour trigger.
  ///
  /// Reads [workoutUiModeProvider] and dispatches the correct step list
  /// (Easy = 3 / Simple = 5 / Advanced = 7). Each tier has its own
  /// `tour_seen_<tier>` SharedPreferences flag so graduating users see a
  /// fresh tour at every tier. The mid-tour tier-switch listener lives at
  /// the screen level (see `active_workout_screen_refactored.dart`
  /// `initState` → `WorkoutTourSeenListener.attach` + the
  /// `ref.listen(workoutUiModeProvider, ...)` that calls
  /// [WorkoutTourService.abortIfTierTourRunning] then re-invokes this).
  void triggerWorkoutTour() {
    final tier = ref.read(workoutUiModeProvider).mode;
    WorkoutTourService.maybeShowForTier(ref, tier);
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
