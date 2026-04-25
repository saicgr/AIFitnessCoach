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

import '../../../data/models/exercise.dart';
import '../../../data/models/workout.dart';
import '../../../data/providers/consistency_provider.dart';
import '../../../data/providers/milestones_provider.dart';
import '../../../data/providers/muscle_analytics_provider.dart';
import '../../../data/providers/scores_provider.dart';
import '../../../data/providers/today_workout_provider.dart';
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

    var logId = cachedWorkoutLogId;
    logId ??= await _createWorkoutLog(
      repo: repo,
      workoutId: workoutId,
      userId: userId,
      totalTimeSeconds: totalTimeSeconds,
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
}) async {
  try {
    final response = await repo.createWorkoutLog(
      workoutId: workoutId,
      userId: userId,
      setsJson: '[]',
      totalTimeSeconds: totalTimeSeconds,
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

/// Result returned by [finalizeEasyWorkout] containing everything the
/// caller needs to navigate to `/workout-complete` (and beyond).
class EasyFinalizeResult {
  final WorkoutCompletionResponse? completionResponse;
  final List<PersonalRecordInfo>? personalRecords;
  final PerformanceComparisonInfo? performanceComparison;
  final int totalSets;
  final int totalReps;
  final double totalVolumeKg;
  final int calories;
  final List<Map<String, dynamic>> exercisesPerformance;

  const EasyFinalizeResult({
    required this.completionResponse,
    required this.personalRecords,
    required this.performanceComparison,
    required this.totalSets,
    required this.totalReps,
    required this.totalVolumeKg,
    required this.calories,
    required this.exercisesPerformance,
  });
}

/// Finalize an Easy-tier workout: backfill the workout_log row with the
/// full sets_json + metadata, fire the /complete endpoint to trigger PR
/// detection + performance comparison + server-side XP, then invalidate
/// the same provider set Advanced does so every history/score screen
/// reflects the new session immediately.
///
/// Caller is responsible for navigating to `/workout-complete` with the
/// returned data.
Future<EasyFinalizeResult> finalizeEasyWorkout({
  required WidgetRef ref,
  required Workout workout,
  required List<WorkoutExercise> exercises,
  required Map<int, EasyExerciseState> perExercise,
  required int totalTimeSeconds,
  String? workoutLogId,
}) async {
  // Build aggregates and the rich sets_json the workout_performance_summary
  // and exercise_performance_summary backend pipelines consume.
  int totalSets = 0;
  int totalReps = 0;
  double totalVolumeKg = 0;
  final exercisesPerformance = <Map<String, dynamic>>[];
  final setsJsonList = <Map<String, dynamic>>[];

  for (int i = 0; i < exercises.length; i++) {
    final exercise = exercises[i];
    final st = perExercise[i];
    if (st == null || st.completed.isEmpty) continue;

    int exTotalReps = 0;
    double exTotalWeight = 0;
    int exSetCount = 0;

    for (int sIdx = 0; sIdx < st.completed.length; sIdx++) {
      final s = st.completed[sIdx];
      // Zero-weight + zero-reps placeholders inserted by the
      // "Complete workout" overflow action are tracked but excluded
      // from working-set totals so the user doesn't see a false 0/0
      // padding the volume calculation.
      final isPlaceholder = s.reps <= 0 && s.weight <= 0;
      if (!isPlaceholder) {
        totalSets++;
        totalReps += s.reps;
        totalVolumeKg += s.reps * s.weight;
        exSetCount++;
        exTotalReps += s.reps;
        exTotalWeight += s.weight;
      }

      setsJsonList.add(<String, dynamic>{
        'exercise_index': i,
        'exercise_name': exercise.name,
        'set_number': sIdx + 1,
        'reps_completed': s.reps,
        'weight_kg': s.weight,
        'set_type': s.setType,
        'is_completed': !isPlaceholder,
        'logging_mode': 'easy',
        if (s.targetReps > 0) 'target_reps': s.targetReps,
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
  }

  final repo = ref.read(workoutRepositoryProvider);
  final setsJsonStr = jsonEncode(setsJsonList);
  final metadata = <String, dynamic>{
    'sets_json': setsJsonList,
    'logging_mode': 'easy',
    'rest_intervals': const <Map<String, dynamic>>[],
    'drink_events': const <Map<String, dynamic>>[],
  };

  // 1) Backfill workout_log row (created at first-set persistence with
  //    sets_json='[]') with the full session data, OR create one now if
  //    the per-set persistence path never ran (offline/error case).
  if (workoutLogId != null) {
    await repo.updateWorkoutLog(
      logId: workoutLogId,
      setsJson: setsJsonStr,
      totalTimeSeconds: totalTimeSeconds,
      metadata: metadata,
    );
  } else if (workout.id != null) {
    final userId = await repo.getCurrentUserId();
    if (userId != null) {
      final created = await repo.createWorkoutLog(
        workoutId: workout.id!,
        userId: userId,
        setsJson: setsJsonStr,
        totalTimeSeconds: totalTimeSeconds,
        metadata: jsonEncode(metadata),
      );
      workoutLogId = created?['id'] as String?;
    }
  }

  // 2) Trigger backend completion: marks workout complete, computes the
  //    workout_performance_summary + exercise_performance_summary rows,
  //    detects PRs, awards server-side XP. This is the SAME endpoint the
  //    Advanced flow calls.
  WorkoutCompletionResponse? completionResponse;
  List<PersonalRecordInfo>? personalRecords;
  PerformanceComparisonInfo? performanceComparison;
  if (workout.id != null) {
    try {
      completionResponse = await repo.completeWorkout(workout.id!);
      if (completionResponse != null) {
        if (completionResponse.hasPRs) {
          personalRecords = completionResponse.personalRecords;
          debugPrint(
              '🏆 [EasyWorkout] Got ${personalRecords.length} PRs from completion API');
        }
        performanceComparison = completionResponse.performanceComparison;
      }
    } catch (e) {
      debugPrint('❌ [EasyWorkout] completeWorkout failed: $e');
    }
  }

  // 3) Calorie estimate — prefer server-computed, fall back to stored.
  int calories = 0;
  if (completionResponse != null) {
    calories =
        completionResponse.performanceComparison?.workoutComparison.currentCalories ?? 0;
    if (calories <= 0) calories = completionResponse.workout.estimatedCalories;
  }
  if (calories <= 0) calories = workout.estimatedCalories;

  // 4) XP: if the server already awarded inline (new behavior), refresh
  //    local state; otherwise fall back to the legacy client-driven mark.
  if (completionResponse?.xpAwarded == true) {
    debugPrint(
        '✅ [EasyWorkout] Server awarded ${completionResponse!.xpAmount} XP — refreshing local state');
    unawaited(ref.read(xpProvider.notifier).loadUserXP(showLoading: false));
  } else {
    ref.read(xpProvider.notifier).markWorkoutCompleted(workoutId: workout.id);
  }

  // 5) Invalidate every provider that summarises workout history so the
  //    user sees the new session reflected immediately. Mirrors the
  //    Advanced flow exactly.
  ref.invalidate(workoutsProvider);
  // /today is the source of truth for hero carousel + week-strip checkmark.
  // Without this refresh the in-memory cache keeps the pre-completion state,
  // so today's card flips back to "scheduled" once the user navigates away
  // from the summary screen.
  ref.read(todayWorkoutProvider.notifier).invalidateAndRefresh();
  ref.invalidate(muscleHeatmapProvider);
  ref.invalidate(muscleFrequencyProvider);
  ref.invalidate(muscleBalanceProvider);
  ref.invalidate(scoresProvider);
  ref.invalidate(milestonesProvider);
  ref.invalidate(consistencyProvider);
  ref.invalidate(consistencyDataProvider);
  ref.invalidate(activityHeatmapProvider);
  ref.invalidate(calendarHeatmapProvider);

  return EasyFinalizeResult(
    completionResponse: completionResponse,
    personalRecords: personalRecords,
    performanceComparison: performanceComparison,
    totalSets: totalSets,
    totalReps: totalReps,
    totalVolumeKg: totalVolumeKg,
    calories: calories,
    exercisesPerformance: exercisesPerformance,
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
    final displayWeight =
        useKg ? targetWeightKg : targetWeightKg * 2.20462;
    final total = (ex.setTargets != null && ex.setTargets!.isNotEmpty)
        ? ex.setTargets!.length
        : (ex.sets ?? 3);
    out[i] = EasyExerciseState(
      displayWeight: displayWeight,
      reps: targetReps,
      targetReps: targetReps,
      targetWeightKg: targetWeightKg,
      totalSets: total.clamp(1, 20),
    );
  }
  return out;
}
