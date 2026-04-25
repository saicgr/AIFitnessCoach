import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/posthog_service.dart';
import '../../../data/models/workout.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/providers/today_workout_provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/last_used_service.dart';
import '../../../widgets/common/last_used_badge.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../widgets/replace_or_add_workout_dialog.dart';
import '../../../widgets/segmented_tab_bar.dart';
import '../../../widgets/main_shell.dart';
import 'components/components.dart';
import 'workout_review_sheet.dart';

part 'regenerate_workout_sheet_part_regenerate_workout_sheet.dart';
part 'regenerate_workout_sheet_part_regenerate_workout_sheet_state.dart';
part 'regenerate_workout_sheet_part_regenerate_workout_sheet_state_ext.dart';

// SharedPreferences keys for the regen sheet's per-pick last-used values.
// Saved on submit; consumed in initState to pre-fill chips after the
// programPreferences load resolves.
const String _kRegenDifficultyKey = 'regen_difficulty';
const String _kRegenWorkoutTypeKey = 'regen_workout_type';
const String _kRegenFocusAreasKey = 'regen_focus_areas';
const String _kRegenEquipmentKey = 'regen_equipment';


/// Shows a bottom sheet for regenerating workout with customization options
Future<Workout?> showRegenerateWorkoutSheet(
  BuildContext context,
  WidgetRef ref,
  Workout workout,
) async {
  final parentTheme = Theme.of(context);

  // Hide nav bar while sheet is open
  ref.read(floatingNavBarVisibleProvider.notifier).state = false;

  return showGlassSheet<Workout>(
    context: context,
    builder: (sheetContext) => Theme(
      data: parentTheme,
      child: _RegenerateWorkoutSheet(workout: workout),
    ),
  ).whenComplete(() {
    // Show nav bar when sheet is closed
    ref.read(floatingNavBarVisibleProvider.notifier).state = true;
  });
}

/// String extension for capitalize
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}
