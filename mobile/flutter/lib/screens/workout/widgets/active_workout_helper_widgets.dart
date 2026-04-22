import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/workout_design.dart';
import '../../../core/models/set_progression.dart';
import '../../../core/services/exercise_info_service.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/models/exercise.dart';
import '../../settings/equipment/environment_list_screen.dart';
import 'breathing_guide_sheet.dart';
import 'exercise_info_sheet.dart';


part 'active_workout_helper_widgets_part_exercise_details_sheet_content_state.dart';
part 'active_workout_helper_widgets_part_progression_selector_sheet_state.dart';
part 'active_workout_helper_widgets_part_drag_action_zone.dart';


/// Exercise Details Sheet Content - Hybrid approach
/// Shows static data immediately, then loads AI insights in the background
class ExerciseDetailsSheetContent extends ConsumerStatefulWidget {
  final WorkoutExercise exercise;

  const ExerciseDetailsSheetContent({
    required this.exercise,
  });

  @override
  ConsumerState<ExerciseDetailsSheetContent> createState() =>
      ExerciseDetailsSheetContentState();
}
