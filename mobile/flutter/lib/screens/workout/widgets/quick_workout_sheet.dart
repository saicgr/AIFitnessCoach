import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/dup_rotation.dart';
import '../../../services/hrv_recovery_service.dart';
import '../../../services/mesocycle_planner.dart';
import '../../../services/muscle_recovery_tracker.dart';
import '../../../services/quick_workout_preset_service.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/utils/difficulty_utils.dart';
import '../../../data/local/database_provider.dart';
import '../../../data/models/workout.dart';
import '../../../data/providers/quick_workout_provider.dart';
import '../../../data/providers/today_workout_provider.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/services/api_client.dart';
import '../../../core/services/posthog_service.dart';
import '../../../data/services/haptic_service.dart';
import '../../../models/equipment_item.dart';
import '../../../models/quick_workout_preset.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../widgets/main_shell.dart';

part 'quick_workout_sheet_part_quick_workout_sheet.dart';
part 'quick_workout_sheet_part_quick_workout_sheet_state.dart';
part 'quick_workout_sheet_part_focus_chip.dart';
part 'quick_workout_sheet_part_quick_workout_sheet_state_ext_1.dart';
part 'quick_workout_sheet_part_quick_workout_sheet_state_ext_2.dart';


/// Actions for quick workout conflict resolution
enum _ConflictAction { noConflict, replace, addAnyway, changeDate, cancelled }

/// Shows the Quick Workout bottom sheet for busy users
/// who want 5-30 minute workouts.
Future<Workout?> showQuickWorkoutSheet(BuildContext context, WidgetRef ref) async {
  // Hide nav bar while sheet is open
  ref.read(floatingNavBarVisibleProvider.notifier).state = false;

  final result = await showGlassSheet<Workout>(
    context: context,
    builder: (context) => const GlassSheet(
      showHandle: false,
      child: _QuickWorkoutSheet(),
    ),
  );

  // Show nav bar when sheet is closed
  ref.read(floatingNavBarVisibleProvider.notifier).state = true;

  return result;
}
