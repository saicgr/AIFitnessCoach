/// Single source of truth for every onboarding-tour identifier in the
/// app. The two underlying tour systems read these:
///
/// - `EmptyStateTipTour` persists dismissal under
///   `has_seen_empty_tour_<id>` (see `widgets/empty_state_tip_tour.dart`).
/// - `AppTour` (Riverpod-driven) keys server-side + SharedPrefs state by
///   the same id (see `widgets/app_tour/app_tour_controller.dart`).
///
/// Use these constants instead of hardcoding strings so a rename never
/// silently desynchronizes Reset-Tips, Settings, and analytics.
class TooltipIds {
  TooltipIds._();

  // ── EmptyStateTipTour-driven first-run hints ──────────────────────
  /// Discover screen: Find peers / Tap user / Switch boards.
  static const discover = 'discover_v1';

  /// Nutrition screen: Log a meal / Swipe dates / My Foods.
  static const nutrition = 'nutrition_v1';

  /// Workouts tab: Start workout / Customize / Set preferences.
  static const workouts = 'workouts_v1';

  /// Menu Analysis sheet: Sort / Filter / Recommended / Log.
  static const menuAnalysis = 'menu_analysis_v1';

  // ── AppTour-driven multi-screen flows ─────────────────────────────
  /// First-run navigation tour from the Home screen (7 stops).
  static const nav = 'nav_tour';

  /// Single-step Log Meal sheet hint (analyze button).
  static const logMeal = 'nutrition_log_tour';

  /// Schedule screen tour (calendar / workout card / view-mode toggle).
  static const schedule = 'schedule_tour';

  /// Profile screen tour (stats / synced workouts / wrapped).
  static const profile = 'profile_tour';

  /// Workouts-tab walkthrough (quick actions / today / weekly / library).
  static const workoutsTab = 'workouts_tab_tour';

  // ── Tier-aware active-workout tours ───────────────────────────────
  static const workoutActiveAdvanced = 'workout_tour_advanced';
  static const workoutActiveEasy = 'workout_tour_easy';
  static const workoutActiveSimple = 'workout_tour_simple';

  /// Every tour-id the app ships. Used by `Tooltips.resetAll()` to clear
  /// state across both underlying systems in one shot.
  static const all = <String>[
    discover,
    nutrition,
    workouts,
    menuAnalysis,
    nav,
    logMeal,
    schedule,
    profile,
    workoutsTab,
    workoutActiveAdvanced,
    workoutActiveEasy,
    workoutActiveSimple,
  ];
}
