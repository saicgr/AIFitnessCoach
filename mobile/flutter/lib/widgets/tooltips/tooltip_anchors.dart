import 'package:flutter/widgets.dart';

/// Centralized GlobalKey registry for every onboarding-tour anchor in
/// the app. Each tour step references one of these keys; the screen
/// rendering the tour wraps the relevant widget in
/// `KeyedSubtree(key: TooltipAnchors.<x>, child: …)`.
///
/// Keys are static-final so they survive provider invalidation and
/// remain stable across rebuilds. They must each be attached to AT MOST
/// ONE widget at a time — Flutter throws "duplicate global key" if two
/// instances of the same screen mount simultaneously.
///
/// `AppTourKeys` (in `widgets/app_tour/app_tour_controller.dart`) is now
/// a thin re-export of these anchors for back-compat.
class TooltipAnchors {
  TooltipAnchors._();

  // ─── Menu Analysis sheet (EmptyStateTipTour: menu_analysis_v1) ──
  static final menuAnalysisSortRow =
      GlobalKey(debugLabel: 'tip.menuAnalysis.sortRow');
  static final menuAnalysisFilter =
      GlobalKey(debugLabel: 'tip.menuAnalysis.filter');
  static final menuAnalysisRecommended =
      GlobalKey(debugLabel: 'tip.menuAnalysis.recommended');
  static final menuAnalysisSelectFooter =
      GlobalKey(debugLabel: 'tip.menuAnalysis.selectFooter');

  // ─── Discover screen (EmptyStateTipTour: discover_v1) ────────────
  static final discoverRisingStars =
      GlobalKey(debugLabel: 'tip.discover.risingStars');
  static final discoverNearYou = GlobalKey(debugLabel: 'tip.discover.nearYou');
  static final discoverBoardTabs =
      GlobalKey(debugLabel: 'tip.discover.boardTabs');

  // ─── Nutrition screen (EmptyStateTipTour: nutrition_v1) ──────────
  static final nutritionDateNav =
      GlobalKey(debugLabel: 'tip.nutrition.dateNav');
  static final nutritionMyFoods =
      GlobalKey(debugLabel: 'tip.nutrition.myFoods');
  static final nutritionLogMeal =
      GlobalKey(debugLabel: 'tip.nutrition.logMeal');

  // ─── Nav tour (AppTour: nav_tour) ────────────────────────────────
  static final topBar = GlobalKey(debugLabel: 'tour_topBar');
  static final heroCarousel = GlobalKey(debugLabel: 'tour_heroCarousel');
  static final quickLog = GlobalKey(debugLabel: 'tour_quickLog');
  static final workoutNav = GlobalKey(debugLabel: 'tour_workoutNav');
  static final aiChat = GlobalKey(debugLabel: 'tour_aiChat');
  static final nutritionNav = GlobalKey(debugLabel: 'tour_nutritionNav');
  static final profileNav = GlobalKey(debugLabel: 'tour_profileNav');

  // ─── Active Workout (AppTour: advanced/easy/simple tier tours) ───
  static final exerciseCard = GlobalKey(debugLabel: 'tour_exerciseCard');
  static final setLogging = GlobalKey(debugLabel: 'tour_setLogging');
  static final rirBar = GlobalKey(debugLabel: 'tour_rirBar');
  static final restTimer = GlobalKey(debugLabel: 'tour_restTimer');
  static final swapExercise = GlobalKey(debugLabel: 'tour_swapExercise');
  static final workoutAi = GlobalKey(debugLabel: 'tour_workoutAi');

  // Tier-aware extras. Attached when the Easy/Simple tier screens ship.
  // Until then the tier-aware trigger reuses the keys above.
  static final easyExerciseHeader =
      GlobalKey(debugLabel: 'tour_easyExerciseHeader');
  static final easyStepper = GlobalKey(debugLabel: 'tour_easyStepper');
  static final easyLogSetButton = GlobalKey(debugLabel: 'tour_easyLogSetButton');
  static final simpleRail = GlobalKey(debugLabel: 'tour_simpleRail');
  static final simplePrevLine = GlobalKey(debugLabel: 'tour_simplePrevLine');
  static final simpleRestBar = GlobalKey(debugLabel: 'tour_simpleRestBar');
  static final simpleChatBar = GlobalKey(debugLabel: 'tour_simpleChatBar');
  static final tierToggle = GlobalKey(debugLabel: 'tour_tierToggle');

  // ─── Nutrition tab (AppTour: nutrition_tour) ─────────────────────
  static final macroGoals = GlobalKey(debugLabel: 'tour_macroGoals');
  static final addMeal = GlobalKey(debugLabel: 'tour_addMeal');
  static final nutritionTabs = GlobalKey(debugLabel: 'tour_nutritionTabs');
  static final nutritionHistory = GlobalKey(debugLabel: 'tour_nutritionHistory');

  // ─── Log meal sheet (AppTour: nutrition_log_tour) ────────────────
  static final logMealButton = GlobalKey(debugLabel: 'tour_logMealButton');

  // ─── Schedule screen (AppTour: schedule_tour) ────────────────────
  static final weeklyCalendar = GlobalKey(debugLabel: 'tour_weeklyCalendar');
  static final scheduleWorkoutCard =
      GlobalKey(debugLabel: 'tour_scheduleWorkoutCard');
  static final viewModeToggle = GlobalKey(debugLabel: 'tour_viewModeToggle');

  // ─── Profile (AppTour: profile_tour) ─────────────────────────────
  static final viewStats = GlobalKey(debugLabel: 'tour_viewStats');
  static final syncedWorkouts = GlobalKey(debugLabel: 'tour_syncedWorkouts');
  static final wrapped = GlobalKey(debugLabel: 'tour_wrapped');

  // ─── Workouts tab — shared by both `workouts_v1` (EmptyStateTipTour)
  // and the future `workouts_tab_tour` (AppTour) ────────────────────
  static final workoutsQuickActions =
      GlobalKey(debugLabel: 'tour_workoutsQuickActions');
  static final workoutsToday = GlobalKey(debugLabel: 'tour_workoutsToday');
  static final workoutsWeekly = GlobalKey(debugLabel: 'tour_workoutsWeekly');
  static final workoutsLibrary = GlobalKey(debugLabel: 'tour_workoutsLibrary');
  static final workoutsExercisePrefs =
      GlobalKey(debugLabel: 'tip.workouts.exercisePrefs');
}
