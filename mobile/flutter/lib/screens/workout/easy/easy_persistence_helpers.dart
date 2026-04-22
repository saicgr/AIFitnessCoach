// Easy tier — backend persistence + PR detection helpers.
//
// Extracted from easy_active_workout_state.dart so the state class stays
// under the 300-line budget. These are pure functions + repo wrappers —
// no Widget / context lookups, no setState calls.
//
// Every SetLog posted through this path is stamped `loggingMode: 'easy'`.
// Legacy rows stay NULL → analytics treats NULL as Advanced (plan §5).

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/exercise.dart';
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
