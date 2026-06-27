import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/exercise.dart';
import '../../data/repositories/library_repository.dart';

/// Open the modern full-screen [ExerciseDetailScreen] in READ-ONLY browse mode
/// for a library / program exercise.
///
/// This is the single exercise-detail UI app-wide — it replaced the former
/// bottom-sheet detail views on every browse surface (Exercise Library, custom
/// exercises, program schedule, staples, exercise picker, workout review). Browse mode
/// shows media (image/video toggle, speed, mute), the Anton title, body-part /
/// equipment pills, the Favorite/Staple/Queue/Avoid row, and the
/// INFO/STATS/HISTORY/FORM tabs — but hides the rest timer and set-logging
/// table (those assume an active workout).
///
/// Navigates via the SAME `/exercise-detail` go_router route the active-workout
/// flow uses, passing `browse: true` through `extra` so the route can flip the
/// screen into browse mode.
///
/// The detail screen's INFO tab + header chips read muscle / equipment /
/// instructions straight off the [WorkoutExercise]. Callers that only know the
/// exercise id (program schedule, staples, queue) therefore must hydrate those
/// fields before navigating, otherwise the INFO tab renders blank. This helper
/// does that hydration for them:
///
///   * If [exercise] is supplied (a caller that already holds a fully-populated
///     [WorkoutExercise] — e.g. an active-workout row), it is pushed verbatim
///     with no fetch.
///   * Else, when [exerciseId] / [libraryId] is present, it fetches the full
///     library row (`GET /library/exercises/{id}` via [LibraryRepository]),
///     maps it onto a populated [WorkoutExercise], and pushes that. A brief
///     blocking spinner covers the fetch.
///   * On fetch failure / empty / no id at all, it falls back to a name-only
///     [WorkoutExercise] so media + title still render (graceful degradation).
Future<void> openExerciseBrowse(
  BuildContext context, {
  required String name,
  String? exerciseId,
  String? libraryId,
  WorkoutExercise? exercise,
}) async {
  HapticFeedback.selectionClick();

  // 1. Caller already holds a fully-populated exercise — push immediately.
  if (exercise != null) {
    _pushDetail(context, exercise);
    return;
  }

  // Name-only minimal exercise — the fallback if we can't enrich.
  final minimal = WorkoutExercise(
    exerciseId: exerciseId,
    libraryId: libraryId,
    nameValue: name,
  );

  // 2. No id to look up — push the minimal exercise (media + title only).
  final lookupId = exerciseId ?? libraryId;
  if (lookupId == null || lookupId.isEmpty) {
    _pushDetail(context, minimal);
    return;
  }

  // 3. Fetch the full library row, mapping it onto a populated WorkoutExercise.
  //    A brief blocking spinner covers the (warm-backend ~100-500ms) fetch.
  final container = ProviderScope.containerOf(context, listen: false);
  final repo = container.read(libraryRepositoryProvider);
  // Capture the root navigator BEFORE the await so we can always dismiss the
  // spinner dialog, even if the originating context unmounts mid-fetch.
  final rootNav = Navigator.of(context, rootNavigator: true);

  _showLoadingOverlay(context);
  WorkoutExercise resolved = minimal;
  try {
    final item = await repo.getExercise(lookupId);
    if (item != null) {
      resolved = _mergeLibraryItem(minimal, item);
    }
  } catch (e) {
    debugPrint('❌ [openExerciseBrowse] enrich fetch failed for $lookupId: $e');
    // resolved stays as `minimal` — graceful fallback.
  }

  // Always tear down the spinner, mounted or not.
  if (rootNav.canPop()) rootNav.pop();

  if (!context.mounted) return;
  _pushDetail(context, resolved);
}

/// Build a populated [WorkoutExercise] from a base (name + ids) and the fetched
/// library row. Only fields the modern INFO tab / header chips read are mapped.
WorkoutExercise _mergeLibraryItem(
  WorkoutExercise base,
  LibraryExerciseItem item,
) {
  // Construct directly rather than copyWith — copyWith doesn't expose
  // `difficulty`, and the modern INFO header reads it.
  return WorkoutExercise(
    exerciseId: base.exerciseId,
    libraryId: base.libraryId,
    nameValue: item.name.isNotEmpty ? item.name : base.name,
    // Header chips read primaryMuscle ?? muscleGroup; body_part is the library's
    // coarse group, target_muscle the precise one.
    primaryMuscle: item.targetMuscle,
    muscleGroup: item.bodyPart,
    bodyPart: item.bodyPart,
    equipment: item.equipment,
    instructions: item.instructions,
    difficulty: item.difficulty,
    gifUrl: item.gifUrl,
    videoUrl: item.videoUrl,
  );
}

void _pushDetail(BuildContext context, WorkoutExercise exercise) {
  context.push('/exercise-detail', extra: {
    'exercise': exercise,
    'browse': true,
  });
}

void _showLoadingOverlay(BuildContext context) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    builder: (_) => const Center(
      child: SizedBox(
        width: 36,
        height: 36,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      ),
    ),
  );
}

