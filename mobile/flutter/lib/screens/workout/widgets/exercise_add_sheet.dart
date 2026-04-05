import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/custom_exercises_provider.dart';
import '../../../core/providers/staples_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../data/local/database.dart';
import '../../../data/local/database_provider.dart';
import '../../../data/models/workout.dart';
import '../../../data/models/exercise.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/repositories/exercise_preferences_repository.dart';
import '../../../data/services/api_client.dart';
import '../../../screens/library/providers/muscle_group_images_provider.dart';
import '../../../services/exercise_selector.dart' as selector;
import '../../../data/services/exercise_library_loader.dart';
import '../../../services/offline_workout_generator.dart';
import '../../../services/workout_templates.dart' show muscleAliases;
import '../../../core/algorithms/exercise_search_ranker.dart';
import '../../../core/providers/favorites_provider.dart';
import '../../../widgets/exercise_image.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../widgets/segmented_tab_bar.dart';
import '../../../data/services/image_url_cache.dart';


part 'exercise_add_sheet_part_exercise_add_sheet_state.dart';
part 'exercise_add_sheet_part_exercise_add_sheet_state_ext.dart';


/// Top-level function for converting cached exercises in an isolate via compute().
List<OfflineExercise> _convertCachedExercises(List<Map<String, dynamic>> rows) {
  return rows.map((ce) {
    List<String>? secondaryMuscles;
    final sm = ce['secondaryMuscles'] as String?;
    if (sm != null) {
      try {
        secondaryMuscles = (jsonDecode(sm) as List).cast<String>();
      } catch (_) {}
    }
    return OfflineExercise(
      id: ce['id'] as String?,
      name: ce['name'] as String?,
      bodyPart: ce['bodyPart'] as String?,
      equipment: ce['equipment'] as String?,
      targetMuscle: ce['targetMuscle'] as String?,
      primaryMuscle: ce['primaryMuscle'] as String?,
      secondaryMuscles: secondaryMuscles,
      difficulty: ce['difficulty'] as String?,
      difficultyNum: ce['difficultyNum'] as int?,
    );
  }).toList();
}

/// Shows exercise add sheet with Library tab first, AI Suggestions second
Future<Workout?> showExerciseAddSheet(
  BuildContext context,
  WidgetRef ref, {
  required String workoutId,
  required String workoutType,
  List<String>? currentExerciseNames,
}) async {
  return await showGlassSheet<Workout>(
    context: context,
    builder: (context) => GlassSheet(
      showHandle: false,
      child: _ExerciseAddSheet(
        workoutId: workoutId,
        workoutType: workoutType,
        currentExerciseNames: currentExerciseNames ?? [],
      ),
    ),
  );
}

const _libraryMuscleGroups = [
  'Chest',
  'Back',
  'Shoulders',
  'Legs',
  'Arms',
  'Core',
  'Glutes',
];

class _ExerciseAddSheet extends ConsumerStatefulWidget {
  final String workoutId;
  final String workoutType;
  final List<String> currentExerciseNames;

  const _ExerciseAddSheet({
    required this.workoutId,
    required this.workoutType,
    required this.currentExerciseNames,
  });

  @override
  ConsumerState<_ExerciseAddSheet> createState() => _ExerciseAddSheetState();
}
