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

    final isPlaceholder = log.reps <= 0 && log.weight <= 0;
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
      final isPlaceholder = s.reps <= 0 && s.weight <= 0;
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
    final repo = ref.read(workoutRepositoryProvider);
    final metadata = <String, dynamic>{
      'sets_json': aggregates.setsJsonList,
      'logging_mode': 'easy',
      'rest_intervals': const <Map<String, dynamic>>[],
      'drink_events': const <Map<String, dynamic>>[],
    };

    // 1) Backfill (or create) the workout_log row with the full session.
    if (workoutLogId != null) {
      await repo.updateWorkoutLog(
        logId: workoutLogId,
        setsJson: aggregates.setsJson,
        totalTimeSeconds: totalTimeSeconds,
        metadata: metadata,
      );
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
          setsJson: aggregates.setsJson,
          totalTimeSeconds: totalTimeSeconds,
          metadata: jsonEncode(metadata),
          gymProfileId: gymProfileId,
        );
        workoutLogId = created?['id'] as String?;
      }
    }

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
    final targetWeightKg =
        (firstTarget?.targetWeightKg ?? ex.weight ?? 0).toDouble();
    // Snap kg→lb through the SAME equipment-aware pipeline Advanced uses
    // (barbell bar+plate floor, dumbbell/cable/machine stacks) so Easy shows a
    // plate-friendly number — not a raw 44.0/38.07 conversion, and never a
    // 25 lb prescription that's below the empty bar.
    final displayWeight = useKg
        ? targetWeightKg
        : kgToDisplayLbs(targetWeightKg, ex.equipment, exerciseName: ex.name);
    final total = (ex.setTargets != null && ex.setTargets!.isNotEmpty)
        ? ex.setTargets!.length
        : (ex.sets ?? 3);
    final timed = ex.isTimedExercise;
    final defaultDuration = ex.holdSeconds ??
        (firstTarget?.targetHoldSeconds) ??
        ex.durationSeconds ??
        30;
    out[i] = EasyExerciseState(
      displayWeight: displayWeight,
      reps: targetReps,
      targetReps: targetReps,
      targetWeightKg: targetWeightKg,
      totalSets: total.clamp(1, 20),
      isTimed: timed,
      durationSeconds: defaultDuration.clamp(5, 600),
    );
  }
  return out;
}
