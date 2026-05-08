// Mid-workout entry point for editing the active gym profile's equipment
// without losing the active workout route. Three steps:
//
//   1. Open `GymEquipmentSheet` as a modal *over* the active workout
//      (showGlassSheet, NOT Navigator.push) so the underlying screen stays
//      mounted and any in-flight set logging keeps its state.
//
//   2. On save, write through to the active gym profile via
//      `gymProfilesProvider.notifier.updateProfile(...)`. That call also
//      invalidates the today / all-workouts caches so the *next* workout
//      reflects the new equipment regardless of the user's choice in step 3.
//
//   3. Show the regenerate-vs-continue dialog. The dialog handles its own
//      streaming regenerate flow and returns the new workout (or null).
//
// Returns the new Workout if the user regenerated and approved it; null if
// they kept the current workout, cancelled the equipment edit, or hit an
// error (a SnackBar is shown for errors so the caller can stay silent).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/gym_profile.dart';
import '../../../data/models/workout.dart';
import '../../../data/providers/gym_profile_provider.dart';
import '../../../models/equipment_item.dart';
import '../../../widgets/glass_sheet.dart';
import '../../home/widgets/gym_equipment_sheet.dart';
import 'regenerate_with_new_equipment_dialog.dart';

/// Opens the equipment editor modally over the active workout, persists the
/// change to the active gym profile, then prompts regenerate-or-continue.
Future<Workout?> showChangeEquipmentForActiveWorkout(
  BuildContext context,
  WidgetRef ref, {
  required Workout activeWorkout,
}) async {
  final activeProfile = ref.read(activeGymProfileProvider);
  if (activeProfile == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No active gym profile — open Settings → Gyms first.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return null;
  }

  // Pre-seed the sheet with the profile's current equipment + details so the
  // user's existing weight inventory survives the round-trip.
  final initialEquipment = List<String>.from(activeProfile.equipment);
  final initialDetails = (activeProfile.equipmentDetails ?? const [])
      .map((m) => EquipmentItem.fromJson(m))
      .toList();

  // Step 1: collect the new selection. The sheet completes via Navigator.pop
  // after it calls onSave, so we capture both via a closure.
  List<String>? savedNames;
  List<Map<String, dynamic>>? savedDetails;
  await showGlassSheet<void>(
    context: context,
    builder: (sheetCtx) => GlassSheet(
      child: GymEquipmentSheet(
        selectedEquipment: initialEquipment,
        equipmentDetails: initialDetails,
        title: 'Equipment',
        gymProfileId: activeProfile.id,
        workoutEnvironment: activeProfile.workoutEnvironment,
        onSave: (names, details) {
          savedNames = names;
          savedDetails = details;
        },
      ),
    ),
  );

  // User dismissed the sheet without tapping Save → bail.
  if (savedNames == null) return null;
  if (!context.mounted) return null;

  // Step 2: persist to the active gym profile. The provider invalidation
  // logic (gym_profile_provider._invalidateWorkoutCaches) takes care of
  // refreshing today/upcoming caches downstream.
  try {
    await ref.read(gymProfilesProvider.notifier).updateProfile(
          activeProfile.id,
          GymProfileUpdate(
            equipment: savedNames,
            equipmentDetails: savedDetails,
          ),
        );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save equipment: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return null;
  }

  if (!context.mounted) return null;

  // Step 3: ask the user whether to regenerate the *current* workout. The
  // dialog returns the new workout if they regenerated AND approved it.
  return RegenerateWithNewEquipmentDialog.show(
    context,
    ref,
    activeWorkout: activeWorkout,
  );
}
