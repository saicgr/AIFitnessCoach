import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../../core/constants/multi_screen_tour_steps.dart';
import '../models/multi_screen_tour_step.dart';

/// Keys for multi-screen tour local storage
class MultiScreenTourKeys {
  MultiScreenTourKeys._();

  static const String completed = 'multi_screen_tour_completed';
  static const String skipped = 'multi_screen_tour_skipped';
  static const String currentStep = 'multi_screen_tour_current_step';
  static const String completedAt = 'multi_screen_tour_completed_at';
}

/// State for the multi-screen interactive tour
class MultiScreenTourState {
  /// Whether the tour is currently active (in progress)
  final bool isActive;

  /// Whether the tour has been completed
  final bool hasCompleted;

  /// Whether the tour was skipped
  final bool wasSkipped;

  /// Current step index (0-based)
  final int currentStepIndex;

  /// Whether a tooltip is currently being displayed
  final bool isShowingTooltip;

  /// Whether the state is loading
  final bool isLoading;

  const MultiScreenTourState({
    this.isActive = false,
    this.hasCompleted = false,
    this.wasSkipped = false,
    this.currentStepIndex = 0,
    this.isShowingTooltip = false,
    this.isLoading = true,
  });

  /// Get the current step definition
  MultiScreenTourStep? get currentStep => getTourStep(currentStepIndex);

  /// Get progress as a fraction (0.0 to 1.0)
  double get progress =>
      totalTourSteps > 0 ? (currentStepIndex + 1) / totalTourSteps : 0.0;

  /// Whether the tour should be shown to this user
  bool get shouldShowTour => !hasCompleted && !wasSkipped;

  /// Check if current step matches a specific screen route
  bool isStepForScreen(String route) => currentStep?.screenRoute == route;

  MultiScreenTourState copyWith({
    bool? isActive,
    bool? hasCompleted,
    bool? wasSkipped,
    int? currentStepIndex,
    bool? isShowingTooltip,
    bool? isLoading,
  }) {
    return MultiScreenTourState(
      isActive: isActive ?? this.isActive,
      hasCompleted: hasCompleted ?? this.hasCompleted,
      wasSkipped: wasSkipped ?? this.wasSkipped,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      isShowingTooltip: isShowingTooltip ?? this.isShowingTooltip,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Notifier for managing the multi-screen tour state
class MultiScreenTourNotifier extends StateNotifier<MultiScreenTourState> {
  MultiScreenTourNotifier() : super(const MultiScreenTourState());

  TutorialCoachMark? _currentTutorial;

  /// Initialize and check tour status from SharedPreferences
  Future<void> initialize() async {
    try {
      debugPrint('[MultiScreenTour] Initializing tour state');
      state = state.copyWith(isLoading: true);

      final prefs = await SharedPreferences.getInstance();
      final completed = prefs.getBool(MultiScreenTourKeys.completed) ?? false;
      final skipped = prefs.getBool(MultiScreenTourKeys.skipped) ?? false;
      final savedStep = prefs.getInt(MultiScreenTourKeys.currentStep) ?? 0;

      state = state.copyWith(
        hasCompleted: completed,
        wasSkipped: skipped,
        currentStepIndex: savedStep,
        isActive: !completed && !skipped,
        isLoading: false,
      );

      debugPrint(
          '[MultiScreenTour] Initialized: completed=$completed, skipped=$skipped, step=$savedStep');
    } catch (e) {
      debugPrint('[MultiScreenTour] Error initializing: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  /// Start the tour from the beginning
  Future<void> startTour() async {
    debugPrint('[MultiScreenTour] Starting tour');
    state = state.copyWith(
      isActive: true,
      currentStepIndex: 0,
      hasCompleted: false,
      wasSkipped: false,
    );
    await _saveCurrentStep(0);
  }

  /// Check if we should show the tour step for a given screen
  bool shouldShowStepForScreen(String screenRoute) {
    if (!state.isActive || state.isLoading) return false;
    final currentStep = state.currentStep;
    if (currentStep == null) return false;
    return currentStep.screenRoute == screenRoute && !state.isShowingTooltip;
  }

  /// Mark that a tooltip is being shown
  void setShowingTooltip(bool showing) {
    state = state.copyWith(isShowingTooltip: showing);
  }

  /// Advance to the next step in the tour
  Future<void> advanceToNextStep() async {
    final nextIndex = state.currentStepIndex + 1;

    if (nextIndex >= totalTourSteps) {
      // Tour complete
      await completeTour();
    } else {
      debugPrint('[MultiScreenTour] Advancing to step ${nextIndex + 1}/$totalTourSteps');
      state = state.copyWith(
        currentStepIndex: nextIndex,
        isShowingTooltip: false,
      );
      await _saveCurrentStep(nextIndex);
    }
  }

  /// Complete the tour
  Future<void> completeTour() async {
    try {
      debugPrint('[MultiScreenTour] Completing tour');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(MultiScreenTourKeys.completed, true);
      await prefs.setString(
        MultiScreenTourKeys.completedAt,
        DateTime.now().toIso8601String(),
      );
      await prefs.remove(MultiScreenTourKeys.currentStep);

      state = state.copyWith(
        isActive: false,
        hasCompleted: true,
        isShowingTooltip: false,
      );

      debugPrint('[MultiScreenTour] Tour completed successfully');
    } catch (e) {
      debugPrint('[MultiScreenTour] Error completing tour: $e');
    }
  }

  /// Skip the tour
  Future<void> skipTour() async {
    try {
      debugPrint('[MultiScreenTour] Skipping tour at step ${state.currentStepIndex + 1}');

      _currentTutorial?.finish();
      _currentTutorial = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(MultiScreenTourKeys.skipped, true);
      await prefs.setString(
        MultiScreenTourKeys.completedAt,
        DateTime.now().toIso8601String(),
      );
      await prefs.remove(MultiScreenTourKeys.currentStep);

      state = state.copyWith(
        isActive: false,
        wasSkipped: true,
        isShowingTooltip: false,
      );

      debugPrint('[MultiScreenTour] Tour skipped');
    } catch (e) {
      debugPrint('[MultiScreenTour] Error skipping tour: $e');
    }
  }

  /// Reset the tour (for "restart tour" from settings)
  Future<void> resetTour() async {
    try {
      debugPrint('[MultiScreenTour] Resetting tour');

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(MultiScreenTourKeys.completed);
      await prefs.remove(MultiScreenTourKeys.skipped);
      await prefs.remove(MultiScreenTourKeys.currentStep);
      await prefs.remove(MultiScreenTourKeys.completedAt);

      state = state.copyWith(
        isActive: true,
        hasCompleted: false,
        wasSkipped: false,
        currentStepIndex: 0,
        isShowingTooltip: false,
      );

      debugPrint('[MultiScreenTour] Tour reset successfully');
    } catch (e) {
      debugPrint('[MultiScreenTour] Error resetting tour: $e');
    }
  }

  /// Hide the current tooltip without advancing
  void hideTooltip() {
    _currentTutorial?.finish();
    _currentTutorial = null;
    state = state.copyWith(isShowingTooltip: false);
  }

  /// Store reference to current tutorial for cleanup
  void setCurrentTutorial(TutorialCoachMark? tutorial) {
    _currentTutorial = tutorial;
  }

  /// Save current step to SharedPreferences
  Future<void> _saveCurrentStep(int step) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(MultiScreenTourKeys.currentStep, step);
    } catch (e) {
      debugPrint('[MultiScreenTour] Error saving step: $e');
    }
  }
}

/// Main multi-screen tour provider
final multiScreenTourProvider =
    StateNotifierProvider<MultiScreenTourNotifier, MultiScreenTourState>((ref) {
  return MultiScreenTourNotifier();
});

/// Convenience provider: Whether tour is active
final isTourActiveProvider = Provider<bool>((ref) {
  return ref.watch(multiScreenTourProvider).isActive;
});

/// Convenience provider: Current tour step
final currentTourStepProvider = Provider<MultiScreenTourStep?>((ref) {
  return ref.watch(multiScreenTourProvider).currentStep;
});

/// Convenience provider: Current step index
final currentTourStepIndexProvider = Provider<int>((ref) {
  return ref.watch(multiScreenTourProvider).currentStepIndex;
});

/// Global registry for tour target keys
/// Each screen registers its GlobalKey here for the tour to use
class TourKeyRegistry {
  static final Map<String, GlobalKey> _keys = {};

  static void register(String keyId, GlobalKey key) {
    _keys[keyId] = key;
    debugPrint('[TourKeyRegistry] Registered key: $keyId');
  }

  static void unregister(String keyId) {
    _keys.remove(keyId);
    debugPrint('[TourKeyRegistry] Unregistered key: $keyId');
  }

  static GlobalKey? get(String keyId) => _keys[keyId];

  static bool hasKey(String keyId) => _keys.containsKey(keyId);

  static void clear() {
    _keys.clear();
    debugPrint('[TourKeyRegistry] Cleared all keys');
  }
}
