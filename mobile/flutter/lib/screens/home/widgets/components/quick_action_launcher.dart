import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/models/quick_action.dart';
import '../../../../data/providers/content_catalogs_provider.dart';
import '../../../../data/providers/gym_profile_provider.dart';
import '../../../../data/providers/today_workout_provider.dart';
import '../../../../data/repositories/workout_repository.dart';
import '../../../../data/services/haptic_service.dart';
import '../../../nutrition/log_meal_sheet.dart';
import '../../../workout/widgets/equipment_snap_flow.dart';
import '../../../workout/widgets/form_analysis_sheet.dart';
import '../../../workout/widgets/quick_workout_sheet.dart';

/// SharedPreferences key storing the gym profile id that was active BEFORE the
/// user entered Travel Mode, so a future "back to my gym" affordance can restore
/// it. Written by the travel_mode quick action (Feature 3B).
const String kPreTravelActiveGymIdPrefKey = 'pre_travel_active_gym_id';

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
      await showEquipmentSnapFlow(context, ref, mode: SnapMode.identify);
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
    case 'travel_mode':
      HapticService.medium();
      try {
        // Remember the pre-travel active gym so the user can return to it later.
        final priorGymId = ref.read(activeGymProfileIdProvider);
        if (priorGymId != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(kPreTravelActiveGymIdPrefKey, priorGymId);
        }

        final travel = await ref
            .read(gymProfilesProvider.notifier)
            .activateTravelMode();

        // Mirror the gym switcher's post-activate refresh so Today/Workouts
        // regenerate against bodyweight immediately.
        TodayWorkoutNotifier.resetGenerationState();
        clearScreenSummaryCache();
        ref.invalidate(todayWorkoutProvider);
        ref.invalidate(workoutsProvider);
        ref.invalidate(workoutScreenSummaryProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${travel.name} on. Bodyweight workouts ready.'),
            ),
          );
        }
      } catch (e) {
        debugPrint('❌ [QuickActionLauncher] Travel Mode failed: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Couldn't switch to Travel Mode. Please try again.",
              ),
            ),
          );
        }
      }
      return true;
    case 'workout':
      HapticService.light();
      context.push(quickActionRegistry['workout']?.route ?? '/workouts');
      return true;
    case 'form_check':
      // AI Form Analysis with NO exercise name — the analyzer auto-detects the
      // movement from the clip. Record/upload from anywhere (home row, More
      // sheet, customize grid) through this one path.
      HapticService.light();
      await showFormAnalysisSheet(context);
      return true;
    case 'meditate':
      // INSTANT: never block on the /meditation/today network call (that was
      // the "takes so long to start" lag). Open the guided session screen
      // immediately. If today's curated pick is already cached, pass its
      // slug/title/duration/audio; otherwise open a generic guided meditation
      // right away and warm the pick in the background so a retry is instant.
      HapticService.light();
      final cached = ref.read(dailyMeditationProvider).valueOrNull;
      if (cached != null) {
        final params = <String, String>{
          'source': 'meditation',
          'slug': cached.slug,
          'title': cached.title,
          'duration': '${cached.durationMin}',
          if (cached.audioUrl.isNotEmpty) 'audio': cached.audioUrl,
        };
        final qs = params.entries
            .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
            .join('&');
        context.push('/mindfulness/session?$qs');
      } else {
        // Kick off the fetch (non-blocking) so it's cached next time, and
        // open a generic guided meditation session instantly.
        ref.read(dailyMeditationProvider);
        context.push('/mindfulness/session?source=meditation');
      }
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
  // F3 — coach surfaces a recommended-meal card with a "Log this" button.
  // Rendered as a rich card (not a launcher chip); allowlisted so the
  // backend can emit it and the bubble renders it (it has no nav side effect).
  'meal_recommended',
  // F5 — deep-link to the micronutrient detail view for a logged food.
  'view_micros',
};
