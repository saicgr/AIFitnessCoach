import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../tooltips/tooltip_anchors.dart';

enum TooltipPosition { above, below, center }

class AppTourStep {
  final String id;
  final GlobalKey targetKey;
  final String title;
  final String description;
  final TooltipPosition position;
  /// Optional gradient colors for an animated spotlight ring.
  /// When set, the ring cycles through these colors.
  final List<Color>? highlightColors;
  /// Override the spotlight corner radius (default 12). Use 999 for circular.
  final double? cornerRadius;

  const AppTourStep({
    required this.id,
    required this.targetKey,
    required this.title,
    required this.description,
    this.position = TooltipPosition.below,
    this.highlightColors,
    this.cornerRadius,
  });
}

class AppTourState {
  final String? tourId;
  final int currentStep;
  final bool isVisible;
  final List<AppTourStep> steps;

  const AppTourState({
    this.tourId,
    this.currentStep = 0,
    this.isVisible = false,
    this.steps = const [],
  });

  AppTourState copyWith({
    String? tourId,
    int? currentStep,
    bool? isVisible,
    List<AppTourStep>? steps,
  }) {
    return AppTourState(
      tourId: tourId ?? this.tourId,
      currentStep: currentStep ?? this.currentStep,
      isVisible: isVisible ?? this.isVisible,
      steps: steps ?? this.steps,
    );
  }

  AppTourStep? get currentTourStep =>
      (isVisible && steps.isNotEmpty && currentStep < steps.length)
          ? steps[currentStep]
          : null;
}

class AppTourController extends StateNotifier<AppTourState> {
  AppTourController() : super(const AppTourState());

  void show(String tourId, List<AppTourStep> steps) {
    if (steps.isEmpty) return;
    state = AppTourState(
      tourId: tourId,
      currentStep: 0,
      isVisible: true,
      steps: steps,
    );
  }

  void next() {
    if (!state.isVisible) return;
    if (state.currentStep < state.steps.length - 1) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    } else {
      dismiss();
    }
  }

  void prev() {
    if (!state.isVisible || state.currentStep <= 0) return;
    state = state.copyWith(currentStep: state.currentStep - 1);
  }

  Future<void> dismiss() async {
    final tourId = state.tourId;
    state = const AppTourState();
    if (tourId != null) {
      // Save locally for fast access on next launch
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_$tourId', true);
      // Also persist to Supabase user metadata so it survives reinstalls
      _markSeenInCloud(tourId);
    }
  }

  /// Aborts the current tour WITHOUT persisting any "seen" flag. Used when
  /// the user swaps workout-UI tiers mid-tour — the new tier's walkthrough
  /// needs to re-fire from step 1 and the previous tier's tour should still
  /// be re-eligible on its next visit.
  ///
  /// Difference vs [dismiss]: dismiss treats the tour as complete and writes
  /// `has_seen_<tourId>`; abort silently resets state so no persistence
  /// side-effects fire. Callers are responsible for starting the new tour
  /// afterwards (if any).
  void abort() {
    if (!state.isVisible) return;
    state = const AppTourState();
  }

  /// Updates Supabase Auth user_metadata with the completed tour ID.
  /// Fire-and-forget — local prefs are the source of truth for speed.
  void _markSeenInCloud(String tourId) {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final existing = List<String>.from(
          user.userMetadata?['seen_tours'] as List<dynamic>? ?? []);
      if (!existing.contains(tourId)) {
        existing.add(tourId);
        Supabase.instance.client.auth
            .updateUser(UserAttributes(data: {'seen_tours': existing}));
      }
    } catch (_) {
      // Non-critical — local prefs still work
    }
  }

  Future<void> checkAndShow(String tourId, List<AppTourStep> steps) async {
    // Don't start a new tour if one is already visible
    if (state.isVisible) return;
    final prefs = await SharedPreferences.getInstance();
    final seenLocally = prefs.getBool('has_seen_$tourId') ?? false;
    if (seenLocally) return;

    // Not seen locally — check Supabase user metadata (survives reinstalls)
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final seenTours = List<String>.from(
            user.userMetadata?['seen_tours'] as List<dynamic>? ?? []);
        if (seenTours.contains(tourId)) {
          // Restore the flag locally so future checks are instant
          await prefs.setBool('has_seen_$tourId', true);
          return;
        }
      }
    } catch (_) {
      // Ignore errors — fall through and show the tour
    }

    if (steps.isNotEmpty) {
      show(tourId, steps);
    }
  }
}

final appTourControllerProvider =
    StateNotifierProvider<AppTourController, AppTourState>(
  (ref) => AppTourController(),
);

/// Legacy registry — keys now live in `TooltipAnchors`. This class
/// remains as a thin alias so existing call sites
/// (`AppTourKeys.topBarKey`, etc.) keep compiling. New code should
/// reference `TooltipAnchors` directly.
///
/// Each `*Key` getter forwards to the corresponding `TooltipAnchors`
/// field (note the dropped `Key` suffix on the new names).
class AppTourKeys {
  AppTourKeys._();

  // Nav tour
  static GlobalKey get topBarKey => TooltipAnchors.topBar;
  static GlobalKey get heroCarouselKey => TooltipAnchors.heroCarousel;
  static GlobalKey get quickLogKey => TooltipAnchors.quickLog;
  static GlobalKey get workoutNavKey => TooltipAnchors.workoutNav;
  static GlobalKey get aiChatKey => TooltipAnchors.aiChat;
  static GlobalKey get nutritionNavKey => TooltipAnchors.nutritionNav;
  static GlobalKey get profileNavKey => TooltipAnchors.profileNav;

  // Active Workout tour
  static GlobalKey get exerciseCardKey => TooltipAnchors.exerciseCard;
  static GlobalKey get setLoggingKey => TooltipAnchors.setLogging;
  static GlobalKey get rirBarKey => TooltipAnchors.rirBar;
  static GlobalKey get restTimerKey => TooltipAnchors.restTimer;
  static GlobalKey get swapExerciseKey => TooltipAnchors.swapExercise;
  static GlobalKey get workoutAiKey => TooltipAnchors.workoutAi;

  // Nutrition tour
  static GlobalKey get macroGoalsKey => TooltipAnchors.macroGoals;
  static GlobalKey get addMealKey => TooltipAnchors.addMeal;
  static GlobalKey get nutritionTabsKey => TooltipAnchors.nutritionTabs;
  static GlobalKey get nutritionHistoryKey => TooltipAnchors.nutritionHistory;

  // Log Meal sheet
  static GlobalKey get logMealButtonKey => TooltipAnchors.logMealButton;

  // Schedule tour
  static GlobalKey get weeklyCalendarKey => TooltipAnchors.weeklyCalendar;
  static GlobalKey get scheduleWorkoutCardKey =>
      TooltipAnchors.scheduleWorkoutCard;
  static GlobalKey get viewModeToggleKey => TooltipAnchors.viewModeToggle;

  // Profile tour
  static GlobalKey get viewStatsKey => TooltipAnchors.viewStats;
  static GlobalKey get syncedWorkoutsKey => TooltipAnchors.syncedWorkouts;
  static GlobalKey get wrappedKey => TooltipAnchors.wrapped;

  // Workouts tab tour
  static GlobalKey get workoutsQuickActionsKey =>
      TooltipAnchors.workoutsQuickActions;
  static GlobalKey get workoutsTodayKey => TooltipAnchors.workoutsToday;
  static GlobalKey get workoutsWeeklyKey => TooltipAnchors.workoutsWeekly;
  static GlobalKey get workoutsLibraryKey => TooltipAnchors.workoutsLibrary;

  // Tier-aware Active-Workout extras
  static GlobalKey get easyExerciseHeaderKey =>
      TooltipAnchors.easyExerciseHeader;
  static GlobalKey get easyStepperKey => TooltipAnchors.easyStepper;
  static GlobalKey get easyLogSetButtonKey => TooltipAnchors.easyLogSetButton;
  static GlobalKey get simpleRailKey => TooltipAnchors.simpleRail;
  static GlobalKey get simplePrevLineKey => TooltipAnchors.simplePrevLine;
  static GlobalKey get simpleRestBarKey => TooltipAnchors.simpleRestBar;
  static GlobalKey get simpleChatBarKey => TooltipAnchors.simpleChatBar;
  static GlobalKey get tierToggleKey => TooltipAnchors.tierToggle;
}
