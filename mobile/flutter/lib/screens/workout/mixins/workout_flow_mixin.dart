import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/cache/offline_write_queue.dart';
import '../../../core/models/set_progression.dart';
import '../../../core/providers/active_workout_phase_provider.dart';
import '../../../core/providers/weight_increments_provider.dart';
import '../../../core/providers/workout_mini_player_provider.dart';
import '../../../core/providers/workout_mutation_coordinator.dart';
import '../../../core/providers/workout_ui_mode_provider.dart';
import '../../../core/services/posthog_service.dart';
import '../../../core/services/workout_tour_steps.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/workout.dart';
import '../../../data/providers/gym_profile_provider.dart';
import '../../../data/providers/xp_provider.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/workout_completion_prewarmer.dart';
import '../../../core/providers/ble_heart_rate_provider.dart';
import '../../../core/providers/heart_rate_provider.dart';
import '../../../core/providers/warmup_duration_provider.dart';
import '../../../data/services/ble_heart_rate_service.dart';
import '../../../data/services/live_activity_service.dart';
import '../../../data/services/set_note_media_service.dart';
import '../../../data/services/workout_notification_service.dart';
import '../../../widgets/app_snackbar.dart';
import '../../ai_settings/ai_settings_screen.dart';
import '../controllers/workout_timer_controller.dart';
import '../models/workout_state.dart';
import '../providers/active_workout_session_provider.dart';
import '../widgets/quit_workout_dialog.dart';

import '../../../l10n/generated/app_localizations.dart';
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
    // Active phase is now on screen — fire the tier tour that
    // `triggerWorkoutTour()` deferred while warmup was up. No-op if the
    // tour was already seen or another tour is visible (both handled
    // inside WorkoutTourService.maybeShowForTier).
    triggerWorkoutTour();
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
    // Clear the shared tier-swap session so the next workout starts clean.
    ref.read(activeWorkoutSessionProvider.notifier).clear();

    setState(() => currentPhase = WorkoutPhase.complete);

    // WF7 — belt-and-suspenders prewarm. The 2nd-to-last-set heuristic in
    // set_logging_mixin.dart already fires this for normal workouts; this
    // unconditional call covers the edge cases that heuristic misses
    // (single-set workouts, supersets, "Complete workout now"). Idempotent —
    // a recent warm is a no-op, and concurrent callers share one in-flight
    // future.
    unawaited(WorkoutCompletionPrewarmer.warm(ref));

    // The completion-phase Scaffold (`buildCompletionScreen`) already shows
    // a centered trophy + "Saving workout..." label + spinner — adding a
    // glass loading overlay on top duplicates the affordance and the trophy
    // bleeds out from behind the overlay's translucent scrim. The Scaffold
    // alone is enough.
    await _runFinalizeWorkoutCompletion();
  }

  /// WF9 — disk-persisted offline queue for workout-completion writes. If
  /// `/complete` fails (offline / 5xx) the completion POST is enqueued here
  /// and replayed when connectivity returns, so a finished workout is never
  /// silently lost. Idempotency-keyed so a replay can't double-complete.
  static final OfflineWriteQueue _completionQueue =
      OfflineWriteQueue(feature: 'workout_complete');

  Future<void> _runFinalizeWorkoutCompletion() async {

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

    // Locally-computed totals. PRs / performance comparison / workoutLogId
    // are no longer resolved on the navigation path (WF8) — they land via
    // the background save, so the completion screen receives null for them.
    int totalCompletedSets = 0;
    int totalReps = 0;
    double totalVolumeKg = 0.0;
    int totalRestSeconds = 0;
    double avgRestSeconds = 0.0;

    // Pure-Dart totals — computed up-front so the completion screen can
    // render immediately from locally-known data with NO awaited network.
    totalCompletedSets = completedSets.values.fold<int>(
      0, (sum, list) => sum + list.length,
    );
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

    // WF8 — kick off ALL backend writes WITHOUT awaiting them. The user
    // sees the completion screen on the next frame; `/complete` + the
    // Wave-2 set-performance POST + ancillary logs all drain in the
    // background. WF9: a failed `/complete` is enqueued to the offline
    // queue and replayed on reconnect, so a finished workout is never lost.
    unawaited(_runBackgroundCompletionSave(workout));

    final exercisesPerformance = <Map<String, dynamic>>[];
    // Per-set breakdown for the completion screen's tap-to-expand rows
    // (each set's reps + weight, so the user can see exactly what they did and
    // which set landed the PR). Aggregates live in `exercisesPerformance`.
    final exerciseSets = <Map<String, dynamic>>[];
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
        // Skip warmups — show the working/failure/amrap sets that count.
        final working =
            sets.where((s) => s.setType != 'warmup').toList(growable: false);
        if (working.isNotEmpty) {
          exerciseSets.add({
            'name': exercise.name,
            'sets': [
              for (int j = 0; j < working.length; j++)
                {
                  'set_number': j + 1,
                  'reps': working[j].reps,
                  'weight_kg': working[j].weight,
                  'set_type': working[j].setType,
                },
            ],
          });
        }
      }
    }

    // WF8 — calories from the locally-stored estimate. The server-computed
    // value (and PRs / performance comparison) resolve in the background
    // save; the completion screen renders its calm "Saved" state immediately
    // and silently upgrades these when the `/complete` response lands.
    final completionCalories = workout.estimatedCalories;

    if (mounted) {
      debugPrint('🏋️ [Complete] Navigating to workout-complete (background save in flight)');
      context.go('/workout-complete', extra: {
        'workout': workout,
        'duration': timerController.workoutSeconds,
        'calories': completionCalories,
        'drinkIntakeMl': totalDrinkIntakeMl,
        'restIntervals': restIntervals.length,
        // workoutLogId resolves inside the background save; null here is
        // expected — the completion screen handles a deferred id.
        'workoutLogId': null,
        'exercisesPerformance': exercisesPerformance,
        'exerciseSets': exerciseSets,
        'totalRestSeconds': totalRestSeconds,
        'avgRestSeconds': avgRestSeconds,
        'totalSets': totalCompletedSets,
        'totalReps': totalReps,
        'totalVolumeKg': totalVolumeKg,
        'challengeId': challengeId,
        'challengeData': challengeData,
        // PRs / comparison arrive via the background `/complete` call.
        'personalRecords': null,
        'performanceComparison': null,
        'isFirstWorkout': false,
      });
    }
  }

  /// WF8/WF9 — runs the full workout-completion save pipeline OFF the
  /// navigation path. Called fire-and-forget from
  /// [_runFinalizeWorkoutCompletion] so tapping Finish never awaits
  /// `/complete`. All errors are caught; a failed/offline `/complete` is
  /// persisted to [_completionQueue] and replayed when connectivity returns.
  Future<void> _runBackgroundCompletionSave(Workout workout) async {
    try {
      final workoutRepo = ref.read(workoutRepositoryProvider);
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (workout.id == null || userId == null) {
        debugPrint('❌ [Complete] Skipping save: workout.id=${workout.id}, userId=$userId');
        return;
      }

      debugPrint('🏋️ [Complete] Background save starting...');
      final setsJson = buildSetsJson();
      final metadata = _buildWorkoutMetadata(workout);

      // Per-gym progress tracking: attribute this workout-log (and its bulk
      // set-performance rows) to the gym the workout was generated for.
      // Prefer the workout's own gym_profile_id (stable provenance), fall
      // back to the active gym for legacy workouts. NULL → combined bucket.
      // The server is still authoritative (it re-derives from the workout
      // row); this is a fallback.
      final String? gymProfileId =
          workout.gymProfileId ?? ref.read(activeGymProfileIdProvider);

      final totalCompletedSets = completedSets.values
          .fold<int>(0, (sum, list) => sum + list.length);
      final exercisesWithSets =
          completedSets.values.where((l) => l.isNotEmpty).length;

      // Wave 1: completion + workout-log creation + ancillary logs, all
      // parallel. The completion call's own optimistic in-memory mark
      // already flipped the workout to complete (see WorkoutRepository
      // .completeWorkout), so the home/today UI is correct regardless of
      // when this network call resolves.
      String? workoutLogId;
      final createLogFuture = workoutRepo.createWorkoutLog(
        workoutId: workout.id!,
        userId: userId,
        setsJson: setsJson,
        totalTimeSeconds: timerController.workoutSeconds,
        metadata: jsonEncode(metadata),
        gymProfileId: gymProfileId,
      );

      final ancillaryFutures = <Future>[];
      if (totalDrinkIntakeMl > 0) {
        ancillaryFutures.add(workoutRepo.logDrinkIntake(
          workoutId: workout.id!,
          userId: userId,
          amountMl: totalDrinkIntakeMl,
          drinkType: 'water',
        ));
      }
      ancillaryFutures.add(workoutRepo.logWorkoutExit(
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
      ));
      ancillaryFutures.add(logSupersetUsage(userId));

      // Wave 2: once the workout-log row exists, bulk-POST set performances.
      final setPerfsFuture = createLogFuture.then((workoutLog) async {
        if (workoutLog != null) {
          workoutLogId = workoutLog['id'] as String;
          debugPrint('✅ [Complete] Workout log created: $workoutLogId');
          await logAllSetPerformances(workoutLogId!, userId,
              gymProfileId: gymProfileId);
        } else {
          debugPrint('❌ [Complete] createWorkoutLog returned null');
        }
      });

      // Fire the `/complete` call. On any failure (offline / 5xx) enqueue it
      // to the offline queue so it replays on reconnect — never silently
      // lost. The completion screen has already rendered a calm "Saved"
      // state from local data, so the user sees no error.
      unawaited(_completeWorkoutWithOfflineFallback(
        workoutRepo: workoutRepo,
        userId: userId,
        workout: workout,
      ));

      // Drain wave 2 + ancillary writes in the background.
      unawaited(setPerfsFuture.catchError((e) {
        debugPrint('⚠️ [Complete] Background set-performances POST failed: $e');
      }));
      for (final f in ancillaryFutures) {
        unawaited(f.catchError((e) {
          debugPrint('⚠️ [Complete] Background ancillary write failed: $e');
        }));
      }

      // Post-completion refresh is fired from _completeWorkoutWithOfflineFallback
      // AFTER /complete confirms server-side (and from the offline replay sender
      // when a queued completion lands later) via refreshAfterWorkoutMutation —
      // it runs on the root container so the active screen being disposed by
      // context.go('/workout-complete') can't strand it (the old
      // _scheduleCompletionRefresh timer was gated on `mounted` and never fired).

      // XP refresh — the server awards workout_complete XP inline, so just
      // reload local XP state. The legacy client-driven mark stays as a
      // fallback for older backends and is also harmless (server de-dupes).
      ref.read(xpProvider.notifier).markWorkoutCompleted(workoutId: workout.id);
      unawaited(
          ref.read(xpProvider.notifier).loadUserXP(showLoading: false));
    } catch (e) {
      debugPrint('❌ [Complete] Background save failed: $e');
    }
  }

  /// Fire `POST /workouts/{id}/complete`; on failure persist it to the
  /// offline queue keyed by an idempotency key so a reconnect replay can't
  /// double-complete. The connectivity-restored flush is bound the first
  /// time we enqueue.
  Future<void> _completeWorkoutWithOfflineFallback({
    required WorkoutRepository workoutRepo,
    required String userId,
    required Workout workout,
  }) async {
    try {
      final response = await workoutRepo.completeWorkout(workout.id!);
      if (response != null) {
        debugPrint('✅ [Complete] Workout marked complete on server');
        // Server confirmed → refresh Home + Workout tab + analytics from the
        // root container (dispose-proof; the originating screen is gone).
        unawaited(refreshAfterWorkoutMutation(
            source: 'complete_advanced', workoutId: workout.id));
        return;
      }
      // Null response = non-200 the repo already rolled back. Treat as a
      // transient failure and queue for retry.
      debugPrint('⚠️ [Complete] /complete returned null — enqueueing for retry');
    } catch (e) {
      debugPrint('⚠️ [Complete] /complete failed ($e) — enqueueing for retry');
    }

    // WF9 — persist the completion so it survives an app kill and replays
    // when the device is back online.
    final apiClient = ref.read(apiClientProvider);
    final body = {
      'workout_id': workout.id,
      'idempotency_key': OfflineWriteQueue.idempotencyKey('wkout_complete'),
    };
    await _completionQueue.enqueue(userId: userId, body: body);
    _completionQueue.bindConnectivity(
      userId: userId,
      sender: (queuedBody) async {
        try {
          final wid = queuedBody['workout_id'] as String?;
          if (wid == null) return true; // poison item — drop it
          final resp = await apiClient.post(
            '/workouts/$wid/complete',
            data: {'idempotency_key': queuedBody['idempotency_key']},
          );
          final ok = resp.statusCode != null &&
              resp.statusCode! >= 200 &&
              resp.statusCode! < 300;
          // A queued completion that lands minutes later must STILL refresh the
          // UI — previously offline replays updated the server silently and the
          // Home/Workout tabs stayed stale until an app restart.
          if (ok) {
            unawaited(refreshAfterWorkoutMutation(
                source: 'offline_replay', workoutId: wid));
          }
          return ok; // 2xx delivered; the server de-dupes a replay via the key.
        } catch (_) {
          return false; // transient — keep queued, stop the flush
        }
      },
    );
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
  ///
  /// Per-set note media (audio + photos) is uploaded to S3 via
  /// [SetNoteMediaService] BEFORE the bulk POST so the persisted record
  /// holds canonical S3 URLs, never local file paths. All uploads across
  /// all sets fire in parallel via `Future.wait` — wall time is bounded
  /// by the slowest single upload, not the sum. Upload failures drop the
  /// missing media but never block the workout — the rest of the set
  /// still saves.
  Future<void> logAllSetPerformances(String workoutLogId, String userId,
      {String? gymProfileId}) async {
    final workoutRepo = ref.read(workoutRepositoryProvider);
    final mediaSvc = SetNoteMediaService(ref.read(apiClientProvider));

    // Phase 1: kick off every media upload in parallel BEFORE we start
    // building set rows. Each set with audio gets one Future, each set
    // with photos gets one Future. Sets without media are skipped — no
    // wasted Future allocation. The (i, j) -> (audioUrl, photoUrls) map
    // is consumed in phase 2 below to fill in the bulk POST payload.
    final audioFutures = <(int, int), Future<String?>>{};
    final photoFutures = <(int, int), Future<List<String>>>{};
    for (int i = 0; i < exercises.length; i++) {
      final sets = completedSets[i] ?? [];
      for (int j = 0; j < sets.length; j++) {
        final setLog = sets[j];
        final audio = setLog.notesAudioPath;
        if (audio != null && audio.isNotEmpty) {
          audioFutures[(i, j)] =
              mediaSvc.uploadAudio(localPath: audio, userId: userId);
        }
        if (setLog.notesPhotoPaths.isNotEmpty) {
          photoFutures[(i, j)] = mediaSvc.uploadPhotos(
            localPaths: setLog.notesPhotoPaths,
            userId: userId,
          );
        }
      }
    }
    // Block once on the slowest upload across the entire workout.
    await Future.wait<void>([
      ...audioFutures.values.map((f) => f.then((_) {})),
      ...photoFutures.values.map((f) => f.then((_) {})),
    ]);

    // Phase 2: build the bulk payload, reading resolved URLs out of the
    // already-finished Futures. The `await` here returns immediately.
    final records = <Map<String, dynamic>>[];
    for (int i = 0; i < exercises.length; i++) {
      final exercise = exercises[i];
      final sets = completedSets[i] ?? [];
      final pattern =
          exerciseProgressionPattern[i] ?? SetProgressionPattern.pyramidUp;

      for (int j = 0; j < sets.length; j++) {
        final setLog = sets[j];
        final setTarget = exercise.getTargetForSet(j + 1);

        final audioFut = audioFutures[(i, j)];
        final photoFut = photoFutures[(i, j)];
        final String? audioUrl = audioFut == null ? null : await audioFut;
        final List<String> photoUrls =
            photoFut == null ? const [] : await photoFut;

        // Zero-stamped placeholder rows from "Complete workout now"
        // (weight 0 + reps 0) must be marked is_completed: false so
        // they don't pollute streaks / PR detection / volume averages.
        final isPlaceholder = setLog.reps <= 0 && setLog.weight <= 0;
        records.add({
          'workout_log_id': workoutLogId,
          'user_id': userId,
          'exercise_id':
              exercise.exerciseId ?? exercise.libraryId ?? exercise.name,
          'exercise_name': exercise.name,
          'set_number': j + 1,
          'reps_completed': setLog.reps,
          'weight_kg': setLog.weight,
          'is_completed': !isPlaceholder,
          'set_type': setLog.setType,
          // Per-gym progress tracking — attribute every set row to the gym
          // the workout was performed at (server re-derives authoritatively).
          if (gymProfileId != null) 'gym_profile_id': gymProfileId,
          if (setLog.rpe != null) 'rpe': setLog.rpe!.toDouble(),
          if (setLog.rir != null) 'rir': setLog.rir,
          // Always emit `notes` as a list (possibly empty) so the TEXT[]
          // column gets a stable shape across client versions.
          if (setLog.notes.isNotEmpty) 'notes': setLog.notes,
          if (audioUrl != null && audioUrl.isNotEmpty)
            'notes_audio_url': audioUrl,
          if (photoUrls.isNotEmpty) 'notes_photo_urls': photoUrls,
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
          if (setLog.startedAt != null)
            'started_at': setLog.startedAt!.toIso8601String(),
          // 'advanced' is the default tier when this mixin's bulk path
          // runs (Easy / Simple paths log via their own helpers).
          'logging_mode': setLog.loggingMode ?? 'advanced',
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

  /// "Complete workout now" — overflow-menu action. Confirms with the
  /// user, pads every unlogged set across every exercise with a zero
  /// SetLog (weight 0, reps 0, marked is_completed:false in sets_json
  /// + the bulk performance-log POST), then routes through the same
  /// `finalizeWorkoutCompletion` pipeline a fully-logged session uses.
  ///
  /// Net effect: the workout reaches `/workout-complete`, the backend
  /// builds workout_performance_summary + exercise_performance_summary,
  /// PRs are detected from real sets only, and the session shows up in
  /// history identically to a normal completion — placeholder rows are
  /// excluded from streak / PR / volume math by their `is_completed`
  /// flag.
  Future<void> completeWorkoutNow() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context).workoutFlowMixinCompleteWorkoutNow),
        content: const Text(
          'Any sets you haven’t logged will be saved as zero (0 weight, '
          '0 reps). You’ll go straight to the workout summary.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppLocalizations.of(context).workoutFlowMixinKeepGoing),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(AppLocalizations.of(context).workoutFlowMixinComplete),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    // Pad every unlogged set with a zero placeholder. The host class's
    // `completedSets` getter returns the live mutable map (same one
    // setLogged writes to), so this in-place pad is visible to the
    // finalize flow that reads it next.
    for (int i = 0; i < exercises.length; i++) {
      final target = totalSetsPerExercise[i] ?? exercises[i].sets ?? 0;
      final existing = completedSets[i] ?? <SetLog>[];
      while (existing.length < target) {
        existing.add(SetLog(
          reps: 0,
          weight: 0,
          setType: 'working',
          loggingMode: 'advanced',
        ));
      }
      // Some host implementations may have lazy-initialised buckets; re-set
      // to make sure the bucket exists.
      completedSets[i] = existing;
    }

    timerController.stopWorkoutTimer();
    cancelWorkoutNotification();
    await finalizeWorkoutCompletion();
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
      ref.read(activeWorkoutSessionProvider.notifier).clear();
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
    // The tier tour spotlights active-phase controls (exercise card, set
    // table, RIR bar, rest timer, swap/AI chips) — none of which exist
    // during the warmup or stretch phases. Firing it then would render
    // the tour against the warmup screen, find no targets, and burn the
    // one-time `tour_seen_<tier>` flag without the user ever seeing the
    // real tour. Only fire once the active phase is on screen;
    // `handleWarmupComplete()` re-invokes this the moment warmup ends.
    if (currentPhase != WorkoutPhase.active) {
      debugPrint(
          '🔍 [WorkoutTour] Deferring tour — phase is $currentPhase, not active');
      return;
    }
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
