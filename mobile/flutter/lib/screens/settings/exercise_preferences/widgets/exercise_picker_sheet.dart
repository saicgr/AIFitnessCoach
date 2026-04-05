import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/custom_exercises_provider.dart';
import '../../../../data/local/database.dart';
import '../../../../data/local/database_provider.dart';
import '../../../../data/models/custom_exercise.dart';
import '../../../../data/services/api_client.dart';
import '../../../../data/services/image_url_cache.dart';
import '../../../../data/models/exercise.dart';
import '../../../../data/repositories/library_repository.dart';
import '../../../../widgets/exercise_image.dart';
import '../../../../widgets/glass_sheet.dart';
import '../../../custom_exercises/widgets/create_exercise_sheet.dart';
import '../../../library/components/exercise_detail_sheet.dart';

part 'exercise_picker_sheet_part_exercise_picker_sheet.dart';
part 'exercise_picker_sheet_part_exercise_picker_sheet_state.dart';
part 'exercise_picker_sheet_part_exercise_card.dart';


/// The type of exercise preference being selected
enum ExercisePickerType {
  favorite,
  staple,
  queue,
  avoided,
}

/// Result from the exercise picker
class ExercisePickerResult {
  final String exerciseName;
  final String? exerciseId;
  final String? muscleGroup;
  final String? reason; // For staples or avoided
  final bool isTemporary; // For avoided
  final DateTime? endDate; // For avoided
  final String? targetMuscleGroup; // For queue

  const ExercisePickerResult({
    required this.exerciseName,
    this.exerciseId,
    this.muscleGroup,
    this.reason,
    this.isTemporary = false,
    this.endDate,
    this.targetMuscleGroup,
  });
}

/// Shows exercise picker sheet and returns the selected exercise with options
Future<ExercisePickerResult?> showExercisePickerSheet(
  BuildContext context,
  WidgetRef ref, {
  required ExercisePickerType type,
  Set<String>? excludeExercises,
}) async {
  return await showGlassSheet<ExercisePickerResult>(
    context: context,
    builder: (context) => GlassSheet(child: _ExercisePickerSheet(
      type: type,
      excludeExercises: excludeExercises ?? {},
    )),
  );
}
