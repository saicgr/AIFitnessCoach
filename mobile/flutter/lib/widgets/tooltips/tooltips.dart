// Public entry point for the unified tooltip / coach-mark system.
//
// Screens import this single file to get:
// - `TooltipAnchors`: every GlobalKey anchor across the app.
// - `TooltipIds`: tour-id string constants.
// - Each tour class (DiscoverTour, NutritionTour, …) for invoking or
//   embedding a specific flow.
// - `Tooltips`: a facade with cross-cutting helpers (e.g. `resetAll`).

import 'package:shared_preferences/shared_preferences.dart';

import '../empty_state_tip_tour.dart' show EmptyStateTipTour;
import 'tooltip_ids.dart';

export 'tooltip_anchors.dart';
export 'tooltip_ids.dart';
export 'tours/discover_tour.dart';
export 'tours/nutrition_tour.dart';
export 'tours/workouts_tour.dart';
export 'tours/menu_analysis_tour.dart';

/// Cross-cutting helpers spanning both tooltip systems
/// (`EmptyStateTipTour` and `AppTour`). Use these instead of poking at
/// the underlying systems directly so a future migration to a single
/// engine has one place to change.
class Tooltips {
  Tooltips._();

  /// Reset every onboarding tour the app ships — clears both
  /// `has_seen_empty_tour_*` (EmptyStateTipTour) and `has_seen_<id>`
  /// (AppTour) SharedPreferences entries. Returns total keys cleared.
  ///
  /// Wired into Settings → Reset Tips so the user has a single button
  /// that reliably re-enables every spotlight in the app.
  ///
  /// Note: AppTour also mirrors seen state into Supabase user metadata
  /// under `seen_tours`. That mirror is *not* cleared here — it's
  /// authoritative across devices, and clearing the local cache alone
  /// re-shows tours on this device, which is the user expectation.
  static Future<int> resetAll() async {
    final cleared = await EmptyStateTipTour.resetAll();
    final prefs = await SharedPreferences.getInstance();
    var appTourCleared = 0;
    for (final id in TooltipIds.all) {
      // Mirrors `AppTourController._loadSeen` / `markSeen` which write
      // to `has_seen_<id>` in SharedPreferences.
      final key = 'has_seen_$id';
      if (prefs.containsKey(key)) {
        await prefs.remove(key);
        appTourCleared++;
      }
    }
    return cleared + appTourCleared;
  }
}
