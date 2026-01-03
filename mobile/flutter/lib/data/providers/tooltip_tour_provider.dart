import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keys for tooltip tour local storage
class TooltipTourKeys {
  TooltipTourKeys._();

  /// Whether the tooltip tour has been completed
  static const String completed = 'tooltip_tour_completed';

  /// Whether the tooltip tour was skipped
  static const String skipped = 'tooltip_tour_skipped';

  /// Timestamp when the tour was completed/skipped
  static const String completedAt = 'tooltip_tour_completed_at';
}

/// State for the tooltip-based app tour
class TooltipTourState {
  /// Whether the tour should be shown to this user
  final bool shouldShowTour;

  /// Whether the tour is currently showing
  final bool isShowing;

  /// Whether the tour is loading (checking status)
  final bool isLoading;

  /// Current step index (0-based)
  final int currentStep;

  /// Total number of steps in the tour
  final int totalSteps;

  const TooltipTourState({
    this.shouldShowTour = false,
    this.isShowing = false,
    this.isLoading = true,
    this.currentStep = 0,
    this.totalSteps = 6,
  });

  TooltipTourState copyWith({
    bool? shouldShowTour,
    bool? isShowing,
    bool? isLoading,
    int? currentStep,
    int? totalSteps,
  }) {
    return TooltipTourState(
      shouldShowTour: shouldShowTour ?? this.shouldShowTour,
      isShowing: isShowing ?? this.isShowing,
      isLoading: isLoading ?? this.isLoading,
      currentStep: currentStep ?? this.currentStep,
      totalSteps: totalSteps ?? this.totalSteps,
    );
  }

  /// Get progress as a fraction (0.0 to 1.0)
  double get progress => totalSteps > 0 ? (currentStep + 1) / totalSteps : 0.0;
}

/// Notifier for managing the tooltip tour state
class TooltipTourNotifier extends StateNotifier<TooltipTourState> {
  TooltipTourNotifier() : super(const TooltipTourState());

  /// Check if the tour should be shown to this user
  Future<bool> checkShouldShowTour() async {
    try {
      debugPrint('[TooltipTour] Checking if tour should be shown');
      state = state.copyWith(isLoading: true);

      final prefs = await SharedPreferences.getInstance();

      // Check if tour was already completed or skipped
      final completed = prefs.getBool(TooltipTourKeys.completed) ?? false;
      final skipped = prefs.getBool(TooltipTourKeys.skipped) ?? false;

      final shouldShow = !completed && !skipped;

      state = state.copyWith(
        shouldShowTour: shouldShow,
        isLoading: false,
      );

      debugPrint('[TooltipTour] Should show tour: $shouldShow (completed: $completed, skipped: $skipped)');
      return shouldShow;
    } catch (e) {
      debugPrint('[TooltipTour] Error checking tour status: $e');
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  /// Mark the tour as started (showing)
  void startTour() {
    debugPrint('[TooltipTour] Starting tour');
    state = state.copyWith(
      isShowing: true,
      currentStep: 0,
    );
  }

  /// Update the current step
  void setCurrentStep(int step) {
    state = state.copyWith(currentStep: step);
    debugPrint('[TooltipTour] Current step: ${step + 1}/${state.totalSteps}');
  }

  /// Complete the tour
  Future<void> completeTour() async {
    try {
      debugPrint('[TooltipTour] Completing tour');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(TooltipTourKeys.completed, true);
      await prefs.setString(
        TooltipTourKeys.completedAt,
        DateTime.now().toIso8601String(),
      );

      state = state.copyWith(
        shouldShowTour: false,
        isShowing: false,
      );

      debugPrint('[TooltipTour] Tour completed successfully');
    } catch (e) {
      debugPrint('[TooltipTour] Error completing tour: $e');
    }
  }

  /// Skip the tour
  Future<void> skipTour() async {
    try {
      debugPrint('[TooltipTour] Skipping tour at step ${state.currentStep + 1}');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(TooltipTourKeys.skipped, true);
      await prefs.setString(
        TooltipTourKeys.completedAt,
        DateTime.now().toIso8601String(),
      );

      state = state.copyWith(
        shouldShowTour: false,
        isShowing: false,
      );

      debugPrint('[TooltipTour] Tour skipped');
    } catch (e) {
      debugPrint('[TooltipTour] Error skipping tour: $e');
    }
  }

  /// Reset the tour (for "restart tour" from settings)
  Future<void> resetTour() async {
    try {
      debugPrint('[TooltipTour] Resetting tour');

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(TooltipTourKeys.completed);
      await prefs.remove(TooltipTourKeys.skipped);
      await prefs.remove(TooltipTourKeys.completedAt);

      state = state.copyWith(
        shouldShowTour: true,
        isShowing: false,
        currentStep: 0,
      );

      debugPrint('[TooltipTour] Tour reset successfully');
    } catch (e) {
      debugPrint('[TooltipTour] Error resetting tour: $e');
    }
  }

  /// Stop showing the tour without saving (e.g., navigating away)
  void hideTour() {
    state = state.copyWith(isShowing: false);
  }
}

/// Main tooltip tour provider
final tooltipTourProvider = StateNotifierProvider<TooltipTourNotifier, TooltipTourState>((ref) {
  return TooltipTourNotifier();
});

/// Whether the tooltip tour should be shown (convenience provider)
final shouldShowTooltipTourProvider = Provider<bool>((ref) {
  return ref.watch(tooltipTourProvider).shouldShowTour;
});

/// Whether the tooltip tour is currently showing (convenience provider)
final isTooltipTourShowingProvider = Provider<bool>((ref) {
  return ref.watch(tooltipTourProvider).isShowing;
});

/// Whether the tooltip tour is loading (convenience provider)
final isTooltipTourLoadingProvider = Provider<bool>((ref) {
  return ref.watch(tooltipTourProvider).isLoading;
});
