import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

/// Centralized GlobalKey registry for all tour target widgets.
/// These keys are attached to real widgets by the screens/shell.
class AppTourKeys {
  AppTourKeys._();

  // Tour 1: Nav Tour (home screen + nav bar)
  static final topBarKey = GlobalKey(debugLabel: 'tour_topBar');
  static final heroCarouselKey = GlobalKey(debugLabel: 'tour_heroCarousel');
  static final quickLogKey = GlobalKey(debugLabel: 'tour_quickLog');
  static final workoutNavKey = GlobalKey(debugLabel: 'tour_workoutNav');
  static final aiChatKey = GlobalKey(debugLabel: 'tour_aiChat');
  static final nutritionNavKey = GlobalKey(debugLabel: 'tour_nutritionNav');
  static final profileNavKey = GlobalKey(debugLabel: 'tour_profileNav');

  // Tour 2: Active Workout Tour
  static final exerciseCardKey = GlobalKey(debugLabel: 'tour_exerciseCard');
  static final setLoggingKey = GlobalKey(debugLabel: 'tour_setLogging');
  static final rirBarKey = GlobalKey(debugLabel: 'tour_rirBar');
  static final restTimerKey = GlobalKey(debugLabel: 'tour_restTimer');
  static final swapExerciseKey = GlobalKey(debugLabel: 'tour_swapExercise');
  static final workoutAiKey = GlobalKey(debugLabel: 'tour_workoutAi');

  // Tour 3: Nutrition Tour
  static final macroGoalsKey = GlobalKey(debugLabel: 'tour_macroGoals');
  static final addMealKey = GlobalKey(debugLabel: 'tour_addMeal');
  static final nutritionTabsKey = GlobalKey(debugLabel: 'tour_nutritionTabs');
  static final nutritionHistoryKey = GlobalKey(debugLabel: 'tour_nutritionHistory');

  // Tour 7: Nutrition Log Tour (inside log meal sheet)
  static final logMealButtonKey = GlobalKey(debugLabel: 'tour_logMealButton');

  // Tour 4: Schedule Tour
  static final weeklyCalendarKey = GlobalKey(debugLabel: 'tour_weeklyCalendar');
  static final scheduleWorkoutCardKey = GlobalKey(debugLabel: 'tour_scheduleWorkoutCard');
  static final viewModeToggleKey = GlobalKey(debugLabel: 'tour_viewModeToggle');

  // Tour 5: Profile Tour
  static final viewStatsKey = GlobalKey(debugLabel: 'tour_viewStats');
  static final syncedWorkoutsKey = GlobalKey(debugLabel: 'tour_syncedWorkouts');
  static final wrappedKey = GlobalKey(debugLabel: 'tour_wrapped');

  // Tour 6: Workouts Tab Tour
  static final workoutsQuickActionsKey = GlobalKey(debugLabel: 'tour_workoutsQuickActions');
  static final workoutsTodayKey = GlobalKey(debugLabel: 'tour_workoutsToday');
  static final workoutsWeeklyKey = GlobalKey(debugLabel: 'tour_workoutsWeekly');
  static final workoutsLibraryKey = GlobalKey(debugLabel: 'tour_workoutsLibrary');
}
