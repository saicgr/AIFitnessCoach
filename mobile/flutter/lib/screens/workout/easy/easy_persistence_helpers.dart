// Easy tier — backend persistence + PR detection helpers.
//
// Extracted from easy_active_workout_state.dart so the state class stays
// under the 300-line budget. These are pure functions + repo wrappers —
// no Widget / context lookups, no setState calls.
//
// Every SetLog posted through this path is stamped `loggingMode: 'easy'`.
// Legacy rows stay NULL → analytics treats NULL as Advanced (plan §5).

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/cache/offline_write_queue.dart';
import '../../../core/providers/workout_mutation_coordinator.dart';
import '../../../core/utils/default_weights.dart';
import '../../../core/utils/exercise_tracking_metric.dart';

import '../../../data/models/exercise.dart';
import '../../../data/services/rating_prompt_service.dart';
import '../../../data/models/workout.dart';
import '../../../data/providers/gym_profile_provider.dart';
import '../../../data/providers/xp_provider.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/pr_detection_service.dart';
import '../../../data/services/set_note_media_service.dart';
import '../models/workout_state.dart';
import 'easy_active_workout_state_models.dart';

/// Persist a single Easy-tier set to the backend. Returns the workout-log
/// id that it either created or reused. Caller is expected to hold the id
/// between sets so subsequent posts reuse the same workout log.
///
/// Returns the workoutLogId (either passed-in or newly created). Returns
/// `null` if userId is unavailable (offline / logged-out edge case) — the
/// in-memory set is preserved either way, and the user only loses the
/// server-side audit trail.
Future<String?> persistEasySet({
  required WidgetRef ref,
  required WorkoutExercise exercise,
  required SetLog log,
  required EasyExerciseState state,
  required String workoutId,
  required int totalTimeSeconds,
  String? cachedWorkoutLogId,
}) async {
  try {
    final repo = ref.read(workoutRepositoryProvider);
    final userId = await repo.getCurrentUserId();
    if (userId == null) return cachedWorkoutLogId;

    // Per-gym progress tracking: attribute this Easy-tier set + its parent
    // workout-log to the currently-active gym. The Easy path only holds a
    // workoutId (not the Workout), so we resolve from the active gym; the
    // server still re-derives the authoritative value from the workout row.
    // NULL → combined/unassigned bucket.
    final String? gymProfileId = ref.read(activeGymProfileIdProvider);

    var logId = cachedWorkoutLogId;
    logId ??= await _createWorkoutLog(
      repo: repo,
      workoutId: workoutId,
      userId: userId,
      totalTimeSeconds: totalTimeSeconds,
      gymProfileId: gymProfileId,
    );
    if (logId == null) return null;

    // Upload any local note media to S3 before persisting the set so the
    // server-side audit trail carries canonical URLs (never local paths).
    String? audioUrl = log.notesAudioPath;
    List<String> photoUrls = log.notesPhotoPaths;
    if ((audioUrl != null && audioUrl.isNotEmpty) || photoUrls.isNotEmpty) {
      final mediaSvc = SetNoteMediaService(ref.read(apiClientProvider));
      if (photoUrls.isNotEmpty) {
        photoUrls = await mediaSvc.uploadPhotos(
            localPaths: photoUrls, userId: userId);
      }
      if (audioUrl != null && audioUrl.isNotEmpty) {
        audioUrl =
            await mediaSvc.uploadAudio(localPath: audioUrl, userId: userId);
      }
    }

    // A set with a distance, a DURATION (a pure timed hold — plank, wall
    // sit — legitimately has reps<=0 && weight<=0), or an extra metric
    // (SkiErg, a logged box-jump height, etc.) is REAL even with zero
    // reps/weight — only the truly empty "Complete workout now" padding
    // rows are placeholders. Missing `durationSeconds` from this predicate
    // meant a genuine timed hold matched every clause and `is_completed`
    // ended up true only by accident (neighbour of E2E #75).
    final isPlaceholder = log.reps <= 0 &&
        log.weight <= 0 &&
        (log.distanceMeters == null || log.distanceMeters! <= 0) &&
        (log.durationSeconds == null || log.durationSeconds! <= 0) &&
        log.extraMetrics.isEmpty;
    await repo.logSetPerformance(
      workoutLogId: logId,
      userId: userId,
      exerciseId:
          exercise.exerciseId ?? exercise.libraryId ?? exercise.id ?? '',
      exerciseName: exercise.name,
      setNumber: state.completed.length,
      repsCompleted: log.reps,
      weightKg: log.weight,
      targetWeightKg: state.targetWeightKg > 0 ? state.targetWeightKg : null,
      targetReps: state.targetReps,
      setDurationSeconds: log.durationSeconds,
      distanceMeters: log.distanceMeters,
      // SetLog.extraMetrics is ALREADY keyed by canonical bagKey (box_height_cm,
      // …) — same convention as Advanced — so it's sent as-is, no re-mapping.
      metrics: log.extraMetrics.isEmpty
          ? null
          : Map<String, num>.from(log.extraMetrics),
      loggingMode: 'easy',
      notes: log.notes,
      notesAudioUrl: audioUrl,
      notesPhotoUrls: photoUrls,
      gymProfileId: gymProfileId,
      // Zero-stamped padding rows from "Complete workout now" must NOT
      // count as completed sets in analytics / streaks / PR detection.
      isCompleted: !isPlaceholder,
    );
    return logId;
  } catch (e) {
    debugPrint('❌ [EasyWorkout] Persist set error: $e');
    return cachedWorkoutLogId;
  }
}

Future<String?> _createWorkoutLog({
  required WorkoutRepository repo,
  required String workoutId,
  required String userId,
  required int totalTimeSeconds,
  String? gymProfileId,
}) async {
  try {
    final response = await repo.createWorkoutLog(
      workoutId: workoutId,
      userId: userId,
      setsJson: '[]',
      totalTimeSeconds: totalTimeSeconds,
      gymProfileId: gymProfileId,
    );
    return response?['id'] as String?;
  } catch (e) {
    debugPrint('⚠️ [EasyWorkout] createWorkoutLog error: $e');
    return null;
  }
}

/// Run PR detection against the just-logged set. Fires haptics + records
/// the celebration in-memory so the post-workout summary can display it.
///
/// TODO(shared-agent): hook into the shared inline PR celebration overlay
/// when exposed publicly. Easy currently just fires haptics + stores the
/// PR — a visible celebration would be a retention win for beginners.
void detectEasyPRs({
  required PRDetectionService service,
  required SetLog log,
  required WorkoutExercise exercise,
  required EasyExerciseState state,
}) {
  try {
    double totalVolume = 0;
    for (final s in state.completed) {
      totalVolume += s.weight * s.reps;
    }
    final prs = service.checkForPR(
      exerciseName: exercise.name,
      weight: log.weight,
      reps: log.reps,
      totalSets: state.completed.length,
      totalVolume: totalVolume,
    );
    if (prs.isEmpty) return;

    service.triggerHaptics(prs);
    for (final pr in prs) {
      if (service.shouldShowCelebration(pr)) {
        service.recordCelebration();
        service.updateCacheAfterPR(pr);
      }
    }
  } catch (e) {
    debugPrint('⚠️ [EasyWorkout] PR detection error: $e');
  }
}

/// WF8 — locally-computed aggregates for an Easy-tier workout. Pure-Dart, no
/// I/O — so the completion screen can render INSTANTLY from this without
/// awaiting any backend call.
class EasyLocalAggregates {
  final int totalSets;
  final int totalReps;
  final double totalVolumeKg;
  final int calories;
  final List<Map<String, dynamic>> exercisesPerformance;
  /// Per-set breakdown for the completion screen's tap-to-expand rows:
  /// [{name, sets: [{set_number, reps, weight_kg, set_type}]}].
  final List<Map<String, dynamic>> exerciseSets;
  final String setsJson;
  final List<Map<String, dynamic>> setsJsonList;

  const EasyLocalAggregates({
    required this.totalSets,
    required this.totalReps,
    required this.totalVolumeKg,
    required this.calories,
    required this.exercisesPerformance,
    required this.exerciseSets,
    required this.setsJson,
    required this.setsJsonList,
  });
}

/// Compute Easy-tier workout aggregates synchronously. Mirrors the math
/// `finalizeEasyWorkout` did, but with NO network — used so the Easy finish
/// flow can navigate to `/workout-complete` on the same frame as the tap.
EasyLocalAggregates computeEasyAggregates({
  required Workout workout,
  required List<WorkoutExercise> exercises,
  required Map<int, EasyExerciseState> perExercise,
}) {
  int totalSets = 0;
  int totalReps = 0;
  double totalVolumeKg = 0;
  final exercisesPerformance = <Map<String, dynamic>>[];
  final exerciseSets = <Map<String, dynamic>>[];
  final setsJsonList = <Map<String, dynamic>>[];

  // Per-gym progress tracking: stamp each set in the persisted sets_json with
  // the workout's gym (stable provenance). This is a pure function with no
  // WidgetRef, so only the workout-level gym is used here; the active-gym
  // fallback is applied on the per-set POST paths (persistEasySet / bulk).
  // The server re-derives the authoritative value either way.
  final String? gymProfileId = workout.gymProfileId;

  for (int i = 0; i < exercises.length; i++) {
    final exercise = exercises[i];
    final st = perExercise[i];
    if (st == null || st.completed.isEmpty) continue;

    int exTotalReps = 0;
    double exTotalWeight = 0;
    int exSetCount = 0;
    final perSetRows = <Map<String, dynamic>>[];

    for (int sIdx = 0; sIdx < st.completed.length; sIdx++) {
      final s = st.completed[sIdx];
      // Distance / extra-metric sets count as real even at zero reps+weight
      // (a SkiErg block, a logged box-jump height) — don't drop them as padding.
      final hasOtherMetric =
          (s.distanceMeters != null && s.distanceMeters! > 0) ||
              s.extraMetrics.isNotEmpty;
      final isPlaceholder = s.reps <= 0 && s.weight <= 0 && !hasOtherMetric;
      if (!isPlaceholder) {
        totalSets++;
        totalReps += s.reps;
        totalVolumeKg += s.reps * s.weight;
        exSetCount++;
        exTotalReps += s.reps;
        exTotalWeight += s.weight;
        if (s.setType != 'warmup') {
          perSetRows.add(<String, dynamic>{
            'set_number': perSetRows.length + 1,
            'reps': s.reps,
            'weight_kg': s.weight,
            'set_type': s.setType,
          });
        }
      }
      // Match the Advanced sets_json contract (buildSetsJson in
      // set_logging_mixin.dart): always emit target_reps/target_weight_kg
      // (per-set AI target, plan-level fallback) and previous_*/rir when
      // known — the summary screen's Previous/Target/RIR columns are
      // adaptive and only appear when this data exists.
      final setTarget = exercise.getTargetForSet(sIdx + 1);
      final targetReps = s.targetReps > 0
          ? s.targetReps
          : (setTarget?.targetReps ?? exercise.reps);
      final targetWeightKg = setTarget?.targetWeightKg ?? exercise.weight;
      setsJsonList.add(<String, dynamic>{
        'exercise_index': i,
        'exercise_name': exercise.name,
        'set_number': sIdx + 1,
        'reps': s.reps,
        'reps_completed': s.reps,
        'weight_kg': s.weight,
        'set_type': s.setType,
        'is_completed': !isPlaceholder,
        'logging_mode': 'easy',
        if (gymProfileId != null) 'gym_profile_id': gymProfileId,
        if (targetReps != null) 'target_reps': targetReps,
        if (targetWeightKg != null) 'target_weight_kg': targetWeightKg,
        if (s.rir != null) 'rir': s.rir,
        if (s.previousWeightKg != null) 'previous_weight_kg': s.previousWeightKg,
        if (s.previousReps != null) 'previous_reps': s.previousReps,
        'completed_at': s.completedAt.toIso8601String(),
        if (s.durationSeconds != null) 'set_duration_seconds': s.durationSeconds,
        if (s.distanceMeters != null && s.distanceMeters! > 0)
          'distance_meters': s.distanceMeters,
        // Generic metric bag (box_height_cm, calories, custom…), already keyed
        // by bagKey at log time — so PR detection + the server bag see them.
        if (s.extraMetrics.isNotEmpty) 'metrics': s.extraMetrics,
        if (s.restDurationSeconds != null)
          'rest_duration_seconds': s.restDurationSeconds,
        if (s.notes.isNotEmpty) 'notes': s.notes,
      });
    }

    exercisesPerformance.add(<String, dynamic>{
      'name': exercise.name,
      'sets': exSetCount,
      'reps': exTotalReps,
      'weight_kg': exSetCount > 0 ? exTotalWeight / exSetCount : 0,
    });
    if (perSetRows.isNotEmpty) {
      exerciseSets.add(<String, dynamic>{
        'name': exercise.name,
        'sets': perSetRows,
      });
    }
  }

  return EasyLocalAggregates(
    totalSets: totalSets,
    totalReps: totalReps,
    totalVolumeKg: totalVolumeKg,
    // No server-computed calories yet — fall back to the stored estimate.
    // The completion screen silently upgrades this if /complete later
    // returns a precise number.
    calories: workout.estimatedCalories,
    exercisesPerformance: exercisesPerformance,
    exerciseSets: exerciseSets,
    setsJson: jsonEncode(setsJsonList),
    setsJsonList: setsJsonList,
  );
}

/// WF9 — offline queue for Easy-tier workout completion. Same machinery as
/// the Advanced tier; idempotency-keyed so a reconnect replay can't
/// double-complete.
final OfflineWriteQueue _easyCompletionQueue =
    OfflineWriteQueue(feature: 'workout_complete_easy');

/// WF8/WF9 — run the Easy-tier backend save OFF the navigation path.
///
/// Fire-and-forget from `_finishWorkout`: backfills the workout_log row with
/// the full sets_json + metadata, fires `/complete` (PR detection / summary
/// / server XP), invalidates the history providers. A failed/offline
/// `/complete` is enqueued and replayed on reconnect — never silently lost.
Future<void> runEasyBackgroundSave({
  required WidgetRef ref,
  required Workout workout,
  required EasyLocalAggregates aggregates,
  required int totalTimeSeconds,
  String? workoutLogId,
}) async {
  try {
    final metadata = <String, dynamic>{
      'sets_json': aggregates.setsJsonList,
      'logging_mode': 'easy',
      'rest_intervals': const <Map<String, dynamic>>[],
      'drink_events': const <Map<String, dynamic>>[],
    };

    // 1) Backfill (or create) the workout_log row with the full session —
    // routed through the same offline-queue-with-retry pattern step (2)
    // already uses (E2E #1). This is the finalize write that fills
    // sets_json and flips the parent log's derived status; unlike step (2)
    // it used to have NO queue and NO retry, so a failed/offline finalize
    // permanently stranded the log at `sets_json='[]'` (in_progress,
    // post-migration-2390) even though every individual set persisted fine.
    await _easyFinalizeWithOfflineFallback(
      ref: ref,
      workout: workout,
      workoutLogId: workoutLogId,
      setsJson: aggregates.setsJson,
      totalTimeSeconds: totalTimeSeconds,
      metadata: metadata,
    );

    // 2) Fire /complete with offline fallback.
    if (workout.id != null) {
      await _easyCompleteWithOfflineFallback(ref: ref, workout: workout);
    }

    // 3) XP refresh — server awards inline; legacy mark is a harmless
    //    fallback (server de-dupes).
    ref.read(xpProvider.notifier).markWorkoutCompleted(workoutId: workout.id);
    unawaited(ref.read(xpProvider.notifier).loadUserXP(showLoading: false));

    // 4) Refresh Home + Workout tab + analytics through the single durable
    //    chokepoint (root container, dispose-proof). Mirrors the Advanced flow.
    unawaited(refreshAfterWorkoutMutation(
        source: 'complete_easy', workoutId: workout.id));
    try {
      unawaited(
          ref.read(ratingPromptServiceProvider).recordWorkoutCompleted());
    } catch (_) {}
  } catch (e) {
    debugPrint('❌ [EasyWorkout] background save failed: $e');
  }
}

/// E2E #1 — offline queue for the Easy-tier FINALIZE write (the
/// create/update of the `workout_log` row that fills `sets_json` +
/// `metadata` + final `total_time_seconds`). Separate feature namespace
/// from [_easyCompletionQueue] (step 2, `/complete`) — the two writes are
/// independent and must not share a queue slot or a partial flush of one
/// could be mistaken for the other.
final OfflineWriteQueue _easyFinalizeQueue =
    OfflineWriteQueue(feature: 'workout_finalize_easy');

/// Backfill (or create) the `workout_log` row; on failure — offline, 5xx,
/// timeout, or any thrown exception — enqueue for replay instead of
/// silently dropping the logged sets. Never throws.
///
/// Before this, `runEasyBackgroundSave` called `updateWorkoutLog`/
/// `createWorkoutLog` directly with no queue and no retry — both swallow
/// every failure and return `null` (see their own `catch` blocks in
/// `workout_repository_performance.dart`). The Easy tier creates the parent
/// log on the FIRST set with `sets_json = '[]'`, so a device offline at
/// Finish permanently stranded that row at `in_progress` (post-migration
/// 2390: empty sets_json ⇒ in_progress) even though every individual set
/// had already persisted via `logSetPerformance`.
/// Test seam for [_easyFinalizeWithOfflineFallback].
///
/// The enqueue path ends in `bindConnectivity`, which opens
/// `Connectivity().onConnectivityChanged` — a real platform EventChannel. Under
/// `flutter test` that stalls the binding on a message that never arrives, so a
/// test of the ENQUEUE (the thing E2E register row 1 is actually about) hangs
/// for the full timeout instead of asserting. Passing `bindReplay: false` skips
/// only the replay subscription; the enqueue itself, which is what must never
/// drop a user's sets, runs exactly as in production.
@visibleForTesting
Future<void> easyFinalizeWithOfflineFallbackForTest({
  required WidgetRef ref,
  required Workout workout,
  required String? workoutLogId,
  required String setsJson,
  required int totalTimeSeconds,
  required Map<String, dynamic> metadata,
  bool bindReplay = false,
}) =>
    _easyFinalizeWithOfflineFallback(
      ref: ref,
      workout: workout,
      workoutLogId: workoutLogId,
      setsJson: setsJson,
      totalTimeSeconds: totalTimeSeconds,
      metadata: metadata,
      bindReplay: bindReplay,
    );

Future<void> _easyFinalizeWithOfflineFallback({
  required WidgetRef ref,
  required Workout workout,
  required String? workoutLogId,
  required String setsJson,
  required int totalTimeSeconds,
  required Map<String, dynamic> metadata,
  bool bindReplay = true,
}) async {
  final repo = ref.read(workoutRepositoryProvider);
  try {
    if (workoutLogId != null) {
      final result = await repo.updateWorkoutLog(
        logId: workoutLogId,
        setsJson: setsJson,
        totalTimeSeconds: totalTimeSeconds,
        metadata: metadata,
      );
      if (result != null) {
        debugPrint('✅ [EasyWorkout] finalize (update) succeeded');
        return;
      }
    } else if (workout.id != null) {
      final userId = await repo.getCurrentUserId();
      if (userId != null) {
        // Per-gym progress tracking: prefer the workout's own gym (stable
        // provenance), fall back to the active gym. Server re-derives the
        // authoritative value. NULL → combined bucket.
        final String? gymProfileId =
            workout.gymProfileId ?? ref.read(activeGymProfileIdProvider);
        final created = await repo.createWorkoutLog(
          workoutId: workout.id!,
          userId: userId,
          setsJson: setsJson,
          totalTimeSeconds: totalTimeSeconds,
          metadata: jsonEncode(metadata),
          gymProfileId: gymProfileId,
        );
        if (created != null) {
          debugPrint('✅ [EasyWorkout] finalize (create) succeeded');
          return;
        }
      }
    } else {
      return; // no workout id at all — nothing meaningful to queue
    }
    debugPrint('⚠️ [EasyWorkout] finalize returned null — enqueueing');
  } catch (e) {
    debugPrint('⚠️ [EasyWorkout] finalize failed ($e) — enqueueing');
  }

  final userId = await repo.getCurrentUserId();
  if (userId == null || workout.id == null) {
    return; // can't scope the queue — nothing else to do
  }
  final body = <String, dynamic>{
    'mode': workoutLogId != null ? 'update' : 'create',
    'workout_id': workout.id,
    'log_id': workoutLogId,
    'sets_json': setsJson,
    'total_time_seconds': totalTimeSeconds,
    'metadata': metadata,
    'gym_profile_id': workout.gymProfileId,
    // Stable per-workout key — matches createWorkoutLog's own default
    // (`wklog_$workoutId`) so a replay after a partial success (request
    // sent, response lost) can never duplicate the row; the server returns
    // the existing one instead.
    'idempotency_key': workoutLogId == null
        ? 'wklog_${workout.id}'
        : OfflineWriteQueue.idempotencyKey('wkfin'),
  };
  await _easyFinalizeQueue.enqueue(userId: userId, body: body);
  if (!bindReplay) return;
  _easyFinalizeQueue.bindConnectivity(
    userId: userId,
    sender: (queuedBody) async {
      try {
        final mode = queuedBody['mode'] as String?;
        final rawMetadata = queuedBody['metadata'];
        final metaMap = rawMetadata is Map
            ? Map<String, dynamic>.from(rawMetadata)
            : <String, dynamic>{};
        if (mode == 'update') {
          final logId = queuedBody['log_id'] as String?;
          if (logId == null) return true; // poison item — drop
          final r = await repo.updateWorkoutLog(
            logId: logId,
            setsJson: queuedBody['sets_json'] as String?,
            totalTimeSeconds: (queuedBody['total_time_seconds'] as num?)?.toInt(),
            metadata: metaMap,
          );
          return r != null;
        }
        final wid = queuedBody['workout_id'] as String?;
        if (wid == null) return true; // poison item — drop
        final uid = await repo.getCurrentUserId();
        if (uid == null) return false; // transient — logged out momentarily
        final r = await repo.createWorkoutLog(
          workoutId: wid,
          userId: uid,
          setsJson: queuedBody['sets_json'] as String? ?? '[]',
          totalTimeSeconds:
              (queuedBody['total_time_seconds'] as num?)?.toInt() ?? 0,
          metadata: jsonEncode(metaMap),
          gymProfileId: queuedBody['gym_profile_id'] as String?,
          idempotencyKey: queuedBody['idempotency_key'] as String?,
        );
        return r != null;
      } catch (_) {
        return false; // transient — keep queued, stop the flush
      }
    },
  );
}

/// Fire `POST /workouts/{id}/complete`; on failure persist to the offline
/// queue keyed by an idempotency key and bind a connectivity-restored flush.
Future<void> _easyCompleteWithOfflineFallback({
  required WidgetRef ref,
  required Workout workout,
}) async {
  final repo = ref.read(workoutRepositoryProvider);
  try {
    final resp = await repo.completeWorkout(workout.id!);
    if (resp != null) {
      debugPrint('✅ [EasyWorkout] /complete succeeded');
      return;
    }
    debugPrint('⚠️ [EasyWorkout] /complete returned null — enqueueing');
  } catch (e) {
    debugPrint('⚠️ [EasyWorkout] /complete failed ($e) — enqueueing');
  }

  final userId = await repo.getCurrentUserId();
  if (userId == null) return; // can't scope the queue — nothing else to do
  final apiClient = ref.read(apiClientProvider);
  final body = {
    'workout_id': workout.id,
    'idempotency_key': OfflineWriteQueue.idempotencyKey('wkout_complete_easy'),
  };
  await _easyCompletionQueue.enqueue(userId: userId, body: body);
  _easyCompletionQueue.bindConnectivity(
    userId: userId,
    sender: (queuedBody) async {
      try {
        final wid = queuedBody['workout_id'] as String?;
        if (wid == null) return true; // poison item — drop
        final r = await apiClient.post(
          '/workouts/$wid/complete',
          data: {'idempotency_key': queuedBody['idempotency_key']},
        );
        final ok = r.statusCode != null &&
            r.statusCode! >= 200 &&
            r.statusCode! < 300;
        if (ok) {
          unawaited(refreshAfterWorkoutMutation(
              source: 'offline_replay_easy', workoutId: wid));
        }
        return ok;
      } catch (_) {
        return false; // transient — keep queued
      }
    },
  );
}

/// Build an EasyExerciseState seeded from an exercise's set-targets /
/// previous-session data. Returns one state per exercise index.
Map<int, EasyExerciseState> seedEasyExerciseStates(
  List<WorkoutExercise> exercises, {
  required bool useKg,
}) {
  final out = <int, EasyExerciseState>{};
  for (int i = 0; i < exercises.length; i++) {
    final ex = exercises[i];
    final firstTarget = ex.getTargetForSet(1);
    final targetReps = firstTarget?.targetReps ?? ex.reps ?? 10;
    // Classify the log metric so cardio / functional / timed / bodyweight moves
    // never seed a phantom load — this is the Easy-mode counterpart to the
    // Advanced fix and is what kills "10 kg × 1" on SkiErg / Plank / Burpees.
    final metric = ex.trackingMetric;
    // Loaded carries (sled push, prowler, yoke, farmer's carry) track a LOAD
    // even though their primary metric is distance/time — seed the load so Easy
    // captures + persists it alongside the distance, matching Advanced.
    final tracksWeight = ex.trackingProfile.tracksWeight;
    final isWeighted = metric == TrackingMetric.weight || tracksWeight;
    final targetWeightKg = isWeighted
        ? (firstTarget?.targetWeightKg ?? ex.weight ?? 0).toDouble()
        : 0.0; // bodyweight / time / distance → no load (renders "BW")
    // Snap kg→lb through the SAME equipment-aware pipeline Advanced uses
    // (barbell bar+plate floor, dumbbell/cable/machine stacks) so Easy shows a
    // plate-friendly number — not a raw 44.0/38.07 conversion, and never a
    // 25 lb prescription that's below the empty bar.
    final displayWeight = (!isWeighted || useKg)
        ? targetWeightKg
        : kgToDisplayLbs(targetWeightKg, ex.equipment, exerciseName: ex.name);
    final total = (ex.setTargets != null && ex.setTargets!.isNotEmpty)
        ? ex.setTargets!.length
        : (ex.sets ?? 3);
    // Trust the classifier ALONE. `ex.isTimedExercise` is a raw-flag OR
    // (`isTimed` / `durationSeconds>0` / `holdSeconds>0`) that used to be
    // OR'd in here too — that bypassed the classifier's rep-count precedence
    // entirely: a LIBRARY `is_timed=true` (e.g. Bird Dog) still forced a
    // timer even after the classifier correctly said "this has an authored
    // rep count, it's not timed" (E2E #133 — 5 reps rendered as a 5s timer
    // and logged reps_completed=0).
    final timed = metric.isTime;
    final defaultDuration = ex.holdSeconds ??
        (firstTarget?.targetHoldSeconds) ??
        ex.durationSeconds ??
        30;
    // Distance target (m): backend `distance_meters` → parsed from the raw
    // unit-bearing target string ("1000 m") as a fallback.
    final isDistance = metric.isDistance;
    final double targetDistanceM = isDistance
        ? (ex.distanceMeters?.toDouble() ??
            (() {
              final spec = ex.repsSpec;
              if (spec == null) return 0.0;
              final parsed = ExerciseTrackingMetric.parseTarget(spec);
              return parsed.metric == TrackingMetric.distance
                  ? (parsed.value?.toDouble() ?? 0.0)
                  : 0.0;
            })())
        : 0.0;
    out[i] = EasyExerciseState(
      displayWeight: displayWeight,
      reps: targetReps,
      targetReps: targetReps,
      targetWeightKg: targetWeightKg,
      totalSets: total.clamp(1, 20),
      isTimed: timed,
      durationSeconds: defaultDuration.clamp(5, 600),
      isDistance: isDistance,
      distanceMeters: targetDistanceM,
      // Genuine bodyweight rep move: the classifier says "no external load"
      // AND it isn't a timed/distance move. Drives the focal column's plain-
      // language "bodyweight" render instead of the "BW" token + a 0 in a
      // WEIGHT field.
      isBodyweight: !isWeighted && !timed && !isDistance,
    );
  }
  return out;
}
