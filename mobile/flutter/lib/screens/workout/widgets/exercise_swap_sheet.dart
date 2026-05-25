import 'dart:async';
import 'package:flutter/material.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/custom_exercises_provider.dart';
import '../../../core/providers/environment_equipment_provider.dart';
import '../../../core/utils/exercise_name_format.dart';
import '../../../data/models/custom_exercise.dart';
import '../../../data/models/workout.dart';
import '../../../data/models/exercise.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/repositories/library_repository.dart';
import '../../../data/repositories/exercise_preferences_repository.dart';
import '../../../data/services/api_client.dart';
import '../../../core/services/posthog_service.dart';
import '../../../widgets/exercise_image.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../widgets/segmented_tab_bar.dart';
import '../../../data/services/image_url_cache.dart';
import '../../exercises/import_exercise_screen.dart';
import 'equipment_snap_flow.dart';
import 'snapped_equipment_section.dart';


part 'exercise_swap_sheet_part_exercise_swap_sheet_state.dart';
part 'exercise_swap_sheet_part_exercise_swap_sheet_state_ext.dart';
part 'exercise_swap_sheet_part_exercise_option_card.dart';


/// Shows exercise swap sheet with fast DB suggestions and optional AI picks.
///
/// When [previewId] is non-null the confirmed swap is routed to
/// `POST /api/v1/workouts/preview/swap-exercise` so that only the short-lived
/// preview cache is mutated, not the committed workout in the database. Pass
/// this from [showWorkoutReviewSheet] when the sheet is open for an unapproved
/// regeneration preview.
Future<Workout?> showExerciseSwapSheet(
  BuildContext context,
  WidgetRef ref, {
  required String workoutId,
  required WorkoutExercise exercise,
  String? previewId,
  /// When non-null, the sheet jumps to the AI Picks tab on mount and
  /// briefly highlights the row matching this id/name so the user can
  /// confirm with one tap. Used by the chat-side equipment-match deeplink.
  String? preselectedExerciseId,
  String? preselectedExerciseName,
}) async {
  return await showGlassSheet<Workout>(
    context: context,
    isDismissible: true,
    enableDrag: true,
    builder: (context) => GlassSheet(
      // Fix #3: drag handle visible for swipe-to-resize/dismiss affordance.
      // Other workout sheets (workout_ai_coach_sheet) get the same treatment.
      showHandle: true,
      child: _ExerciseSwapSheet(
        workoutId: workoutId,
        exercise: exercise,
        previewId: previewId,
        preselectedExerciseId: preselectedExerciseId,
        preselectedExerciseName: preselectedExerciseName,
      ),
    ),
  );
}

class _ExerciseSwapSheet extends ConsumerStatefulWidget {
  final String workoutId;
  final WorkoutExercise exercise;
  /// When non-null, swaps are applied to the preview cache instead of the
  /// committed workout. Forwarded to [WorkoutRepository.swapExercise].
  final String? previewId;
  /// Optional preselect target — see [showExerciseSwapSheet].
  final String? preselectedExerciseId;
  final String? preselectedExerciseName;

  const _ExerciseSwapSheet({
    required this.workoutId,
    required this.exercise,
    this.previewId,
    this.preselectedExerciseId,
    this.preselectedExerciseName,
  });

  @override
  ConsumerState<_ExerciseSwapSheet> createState() => _ExerciseSwapSheetState();
}
