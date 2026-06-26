import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/exercise.dart';

/// Open the modern full-screen [ExerciseDetailScreen] in READ-ONLY browse mode
/// for a library / program exercise.
///
/// This replaces the old `ExerciseDetailSheet` bottom sheet on the browse
/// surfaces (Exercise Library, custom exercises, program schedule). Browse mode
/// shows media (image/video toggle, speed, mute), the Anton title, body-part /
/// equipment pills, the Favorite/Staple/Queue/Avoid row, and the
/// INFO/STATS/HISTORY/FORM tabs — but hides the rest timer and set-logging
/// table (those assume an active workout).
///
/// Navigates via the SAME `/exercise-detail` go_router route the active-workout
/// flow uses, passing `browse: true` through `extra` so the route can flip the
/// screen into browse mode. [exerciseId] / [libraryId] are threaded through so
/// the media lookup hits the exact library row and STATS/HISTORY resolve
/// correctly; both are optional (custom exercises may have neither).
void openExerciseBrowse(
  BuildContext context, {
  required String name,
  String? exerciseId,
  String? libraryId,
}) {
  HapticFeedback.selectionClick();

  // Minimal WorkoutExercise — most fields are null. Browse mode never touches
  // sets / targets / previous data, so leaving them null is intentional and the
  // detail screen guards every read path.
  final exercise = WorkoutExercise(
    exerciseId: exerciseId,
    libraryId: libraryId,
    nameValue: name,
  );

  context.push('/exercise-detail', extra: {
    'exercise': exercise,
    'browse': true,
  });
}
