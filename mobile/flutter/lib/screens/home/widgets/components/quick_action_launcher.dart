import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/quick_action.dart';
import '../../../../data/services/haptic_service.dart';
import '../../../nutrition/log_meal_sheet.dart';
import '../../../workout/widgets/equipment_snap_flow.dart';
import '../../../workout/widgets/quick_workout_sheet.dart';

/// Shared launch dispatch for quick-action IDs.
///
/// Extracted out of `buildQuickActionWidget` so the home quick-actions row AND
/// the in-chat [SuggestedActionsCard] launch every feature through the EXACT
/// same code path — there is no second copy of "what does tapping Scan Menu
/// do" to drift. The home grid's `onTap` closures call straight into here, so
/// behaviour there is unchanged.
///
/// Returns `true` when the ID was handled. The four custom stateful tiles
/// (water / weight / fasting / mood) are NOT launches — they build their own
/// widgets in `buildQuickActionWidget` — so this returns `false` for them.
///
/// ## Virtual IDs (chat only)
/// A few IDs are not in [quickActionRegistry] because they have no home-grid
/// tile, but the coach can still surface them as launcher chips:
///   * `scan_nutrition_label` / `scan_app_screenshot` → open the multi-image
///     scan (the backend classifier sorts label vs screenshot vs plate).
/// `attach_form_video` is intentionally NOT handled here — it needs the chat
/// screen's own video picker, so the card bridges it via a callback.
Future<bool> launchQuickAction(
  BuildContext context,
  WidgetRef ref,
  String actionId,
) async {
  switch (actionId) {
    case 'food':
      HapticService.light();
      // Switch to Nutrition branch BEFORE showing the log sheet so the user
      // lands on the Nutrition tab when they dismiss it (matches home grid).
      context.go('/nutrition');
      Future.microtask(() {
        if (context.mounted) showLogMealSheet(context, ref);
      });
      return true;
    case 'quick_workout':
      HapticService.light();
      final workout = await showQuickWorkoutSheet(context, ref);
      if (workout != null && context.mounted) {
        context.push('/workout/${workout.id}', extra: workout);
      }
      return true;
    case 'chat':
      HapticService.light();
      context.push('/chat');
      return true;
    case 'photo_food':
      HapticService.light();
      context.go('/nutrition');
      Future.microtask(() {
        if (context.mounted) {
          showLogMealSheet(context, ref, autoOpenCamera: true);
        }
      });
      return true;
    case 'barcode_food':
      HapticService.light();
      context.go('/nutrition');
      Future.microtask(() {
        if (context.mounted) {
          showLogMealSheet(context, ref, autoOpenBarcode: true);
        }
      });
      return true;
    case 'scan_food':
    // Virtual chat-only IDs: nutrition-label / app-screenshot both ride the
    // multi-image scan path (the backend classifier resolves the content
    // type). Mapped here so the launcher card can offer them as chips.
    case 'scan_nutrition_label':
    case 'scan_app_screenshot':
      HapticService.light();
      context.go('/nutrition');
      Future.microtask(() {
        if (context.mounted) {
          showLogMealSheet(context, ref, autoOpenMultiImage: true);
        }
      });
      return true;
    case 'identify_equipment':
      HapticService.light();
      await showEquipmentSnapFlow(
        context,
        ref,
        mode: SnapMode.identify,
      );
      if (context.mounted) {
        // After identification, drop the user into chat so the
        // identify_equipment result + EquipmentMatchCard renders there.
        context.push('/chat');
      }
      return true;
    case 'scan_menu':
      HapticService.light();
      context.go('/nutrition');
      Future.microtask(() {
        if (context.mounted) {
          showLogMealSheet(context, ref, autoOpenMenuScan: true);
        }
      });
      return true;
    case 'workout':
      HapticService.light();
      context.push(quickActionRegistry['workout']?.route ?? '/workouts');
      return true;
    default:
      // Plain-route registry entries (history, library, programs, progress…).
      final action = quickActionRegistry[actionId];
      final route = action?.route;
      if (route == null || route.isEmpty) {
        debugPrint(
          '⚠️ [QuickActionLauncher] No launch handler / route for "$actionId" — ignored',
        );
        return false;
      }
      HapticService.light();
      context.push(route);
      return true;
  }
}

/// The curated subset of action IDs the AI coach is allowed to surface as
/// launcher chips inside a chat message. This is deliberately a SUBSET of
/// [quickActionRegistry] (plus a few virtual scan IDs) — it is the security
/// gate that keeps the model from ever opening Settings, Schedule, account, or
/// any destructive surface from a chat suggestion. The frontend filters every
/// suggested ID against this set; the backend validates against a mirror of it.
const Set<String> kChatLaunchableActionIds = {
  // Nutrition scans / logging
  'scan_menu',
  'photo_food',
  'scan_food',
  'barcode_food',
  'scan_nutrition_label',
  'scan_app_screenshot',
  'food',
  // Workout entry points (the "workout menu")
  'quick_workout',
  'workout',
  'library',
  'programs',
  'history',
  // Equipment + form
  'identify_equipment',
  'attach_form_video',
  // Progress
  'photo',
  'progress',
};
