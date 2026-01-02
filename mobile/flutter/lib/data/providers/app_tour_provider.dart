import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/tour_constants.dart';
import '../models/app_tour_session.dart';
import '../repositories/app_tour_repository.dart';

// ============================================
// App Tour State
// ============================================

/// Complete state for the app tour onboarding experience.
///
/// Tracks the current step, session data, and loading/error states.
class AppTourState {
  /// Whether an API operation is in progress
  final bool isLoading;

  /// The current tour session (null if not started)
  final AppTourSession? session;

  /// Current step index (0-based)
  final int currentStepIndex;

  /// Whether the tour should be shown to this user
  final bool shouldShowTour;

  /// Error message if something went wrong
  final String? error;

  /// Timestamp when the current step was started (for duration tracking)
  final DateTime? stepStartTime;

  /// List of deep links clicked during this tour
  final List<String> deepLinksClicked;

  /// Whether a demo workout was started
  final bool demoWorkoutStarted;

  /// Whether a demo workout was completed
  final bool demoWorkoutCompleted;

  const AppTourState({
    this.isLoading = false,
    this.session,
    this.currentStepIndex = 0,
    this.shouldShowTour = false,
    this.error,
    this.stepStartTime,
    this.deepLinksClicked = const [],
    this.demoWorkoutStarted = false,
    this.demoWorkoutCompleted = false,
  });

  /// Create a copy with modified properties
  AppTourState copyWith({
    bool? isLoading,
    AppTourSession? session,
    int? currentStepIndex,
    bool? shouldShowTour,
    String? error,
    DateTime? stepStartTime,
    List<String>? deepLinksClicked,
    bool? demoWorkoutStarted,
    bool? demoWorkoutCompleted,
    bool clearError = false,
    bool clearSession = false,
    bool clearStepStartTime = false,
  }) {
    return AppTourState(
      isLoading: isLoading ?? this.isLoading,
      session: clearSession ? null : (session ?? this.session),
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      shouldShowTour: shouldShowTour ?? this.shouldShowTour,
      error: clearError ? null : (error ?? this.error),
      stepStartTime:
          clearStepStartTime ? null : (stepStartTime ?? this.stepStartTime),
      deepLinksClicked: deepLinksClicked ?? this.deepLinksClicked,
      demoWorkoutStarted: demoWorkoutStarted ?? this.demoWorkoutStarted,
      demoWorkoutCompleted: demoWorkoutCompleted ?? this.demoWorkoutCompleted,
    );
  }

  /// Get the current tour step
  TourStep? get currentStep => TourConstants.getStepByIndex(currentStepIndex);

  /// Get the current step ID
  String get currentStepId =>
      currentStep?.id ?? TourConstants.allSteps.first.id;

  /// Check if on the first step
  bool get isFirstStep => currentStepIndex == 0;

  /// Check if on the last step
  bool get isLastStep => currentStepIndex == TourConstants.totalSteps - 1;

  /// Get progress percentage (0.0 to 1.0)
  double get progress =>
      (currentStepIndex + 1) / TourConstants.totalSteps;

  /// Get time spent on current step in seconds
  int? get currentStepDurationSeconds {
    if (stepStartTime == null) return null;
    return DateTime.now().difference(stepStartTime!).inSeconds;
  }

  /// Check if tour is active (session exists and not completed)
  bool get isActive => session != null && session!.isInProgress;

  /// Total number of steps
  int get totalSteps => TourConstants.totalSteps;
}

// ============================================
// App Tour Notifier
// ============================================

/// State notifier for managing the app tour.
///
/// Handles navigation between steps, API communication,
/// and tracking user interactions during the tour.
class AppTourNotifier extends StateNotifier<AppTourState> {
  final AppTourRepository _repository;
  String? _currentUserId;
  String? _deviceId;
  DateTime? _tourStartTime;

  AppTourNotifier(this._repository) : super(const AppTourState());

  /// Set user ID for authenticated users
  void setUserId(String userId) {
    _currentUserId = userId;
  }

  /// Set device ID for anonymous tracking
  void setDeviceId(String deviceId) {
    _deviceId = deviceId;
  }

  /// Check if the tour should be shown to this user
  Future<bool> checkShouldShowTour() async {
    try {
      debugPrint('[AppTourProvider] Checking if tour should be shown');

      // First check local storage for quick response
      final localShouldShow = await _repository.shouldShowTourLocally();
      if (!localShouldShow) {
        state = state.copyWith(shouldShowTour: false);
        debugPrint('[AppTourProvider] Tour already completed (local)');
        return false;
      }

      // Then check with the API for authoritative answer
      state = state.copyWith(isLoading: true, clearError: true);

      final response = await _repository.shouldShowTour(
        userId: _currentUserId,
        deviceId: _deviceId,
      );

      state = state.copyWith(
        isLoading: false,
        shouldShowTour: response.shouldShowTour,
      );

      debugPrint('[AppTourProvider] Should show tour: ${response.shouldShowTour}');
      return response.shouldShowTour;
    } catch (e) {
      debugPrint('[AppTourProvider] Error checking tour status: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to check tour status',
      );
      // Default to showing tour on error
      return true;
    }
  }

  /// Start a new tour session
  Future<bool> startTour({
    TourSource source = TourSource.firstLaunch,
  }) async {
    try {
      debugPrint('[AppTourProvider] Starting tour');
      state = state.copyWith(isLoading: true, clearError: true);

      final response = await _repository.startTour(
        userId: _currentUserId,
        deviceId: _deviceId,
        source: source,
      );

      _tourStartTime = DateTime.now();

      // Create initial session
      final session = AppTourSession(
        sessionId: response.sessionId,
        userId: _currentUserId,
        deviceId: _deviceId,
        source: source,
        currentStep: TourConstants.allSteps.first.id,
        startedAt: response.startedAt,
      );

      state = state.copyWith(
        isLoading: false,
        session: session,
        currentStepIndex: 0,
        shouldShowTour: true,
        stepStartTime: DateTime.now(),
        deepLinksClicked: [],
        demoWorkoutStarted: false,
        demoWorkoutCompleted: false,
      );

      debugPrint('[AppTourProvider] Tour started: ${response.sessionId}');
      return true;
    } catch (e) {
      debugPrint('[AppTourProvider] Error starting tour: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to start tour',
      );
      return false;
    }
  }

  /// Move to the next step
  Future<bool> nextStep() async {
    if (state.isLastStep) {
      return completeTour();
    }

    try {
      final sessionId = state.session?.sessionId;
      final currentStepId = state.currentStepId;
      final timeSpent = state.currentStepDurationSeconds;

      // Record step completion if we have a session
      if (sessionId != null) {
        await _repository.completeStep(
          sessionId: sessionId,
          stepId: currentStepId,
          timeSpentSeconds: timeSpent,
        );
      }

      final nextIndex = state.currentStepIndex + 1;
      final nextStepId = TourConstants.allSteps[nextIndex].id;

      // Update session with completed step
      final updatedSession = state.session?.copyWith(
        stepsCompleted: [...state.session!.stepsCompleted, currentStepId],
        currentStep: nextStepId,
      );

      state = state.copyWith(
        currentStepIndex: nextIndex,
        session: updatedSession,
        stepStartTime: DateTime.now(),
      );

      debugPrint('[AppTourProvider] Moved to step ${nextIndex + 1}/${state.totalSteps}');
      return true;
    } catch (e) {
      debugPrint('[AppTourProvider] Error moving to next step: $e');
      state = state.copyWith(error: 'Failed to proceed');
      return false;
    }
  }

  /// Move to the previous step
  void previousStep() {
    if (state.isFirstStep) return;

    final prevIndex = state.currentStepIndex - 1;
    final prevStepId = TourConstants.allSteps[prevIndex].id;

    final updatedSession = state.session?.copyWith(
      currentStep: prevStepId,
    );

    state = state.copyWith(
      currentStepIndex: prevIndex,
      session: updatedSession,
      stepStartTime: DateTime.now(),
    );

    debugPrint('[AppTourProvider] Moved back to step ${prevIndex + 1}/${state.totalSteps}');
  }

  /// Go to a specific step by index
  void goToStep(int index) {
    if (index < 0 || index >= state.totalSteps) return;

    final stepId = TourConstants.allSteps[index].id;
    final updatedSession = state.session?.copyWith(
      currentStep: stepId,
    );

    state = state.copyWith(
      currentStepIndex: index,
      session: updatedSession,
      stepStartTime: DateTime.now(),
    );

    debugPrint('[AppTourProvider] Jumped to step ${index + 1}/${state.totalSteps}');
  }

  /// Skip the tour entirely
  Future<bool> skipTour() async {
    try {
      debugPrint('[AppTourProvider] Skipping tour');

      final sessionId = state.session?.sessionId;
      final currentStepId = state.currentStepId;
      final totalDuration = _tourStartTime != null
          ? DateTime.now().difference(_tourStartTime!).inSeconds
          : null;

      if (sessionId != null) {
        await _repository.skipTour(
          sessionId: sessionId,
          skipStep: currentStepId,
          timeSpentSeconds: totalDuration,
        );
      }

      state = state.copyWith(
        shouldShowTour: false,
        clearSession: true,
        clearStepStartTime: true,
      );

      debugPrint('[AppTourProvider] Tour skipped at step: $currentStepId');
      return true;
    } catch (e) {
      debugPrint('[AppTourProvider] Error skipping tour: $e');
      state = state.copyWith(error: 'Failed to skip tour');
      return false;
    }
  }

  /// Complete the tour successfully
  Future<bool> completeTour() async {
    try {
      debugPrint('[AppTourProvider] Completing tour');

      final sessionId = state.session?.sessionId;
      final currentStepId = state.currentStepId;
      final totalDuration = _tourStartTime != null
          ? DateTime.now().difference(_tourStartTime!).inSeconds
          : null;

      // Complete the last step
      if (sessionId != null) {
        await _repository.completeStep(
          sessionId: sessionId,
          stepId: currentStepId,
          timeSpentSeconds: state.currentStepDurationSeconds,
        );

        // Then complete the tour
        await _repository.completeTour(
          sessionId: sessionId,
          totalDurationSeconds: totalDuration,
          demoWorkoutStarted: state.demoWorkoutStarted,
          demoWorkoutCompleted: state.demoWorkoutCompleted,
          deepLinksClicked: state.deepLinksClicked,
        );
      }

      state = state.copyWith(
        shouldShowTour: false,
        clearSession: true,
        clearStepStartTime: true,
      );

      debugPrint('[AppTourProvider] Tour completed successfully');
      return true;
    } catch (e) {
      debugPrint('[AppTourProvider] Error completing tour: $e');
      state = state.copyWith(error: 'Failed to complete tour');
      return false;
    }
  }

  /// Log a deep link click
  Future<void> logDeepLinkClick(String route) async {
    try {
      final sessionId = state.session?.sessionId;
      final stepId = state.currentStepId;

      // Add to local tracking
      final updatedLinks = [...state.deepLinksClicked, route];
      state = state.copyWith(deepLinksClicked: updatedLinks);

      // Log to server if we have a session
      if (sessionId != null) {
        await _repository.logDeepLinkClick(
          sessionId: sessionId,
          route: route,
          stepId: stepId,
        );
      }

      debugPrint('[AppTourProvider] Deep link clicked: $route');
    } catch (e) {
      debugPrint('[AppTourProvider] Error logging deep link: $e');
    }
  }

  /// Log demo workout started
  Future<void> logDemoWorkoutStarted() async {
    try {
      state = state.copyWith(demoWorkoutStarted: true);

      final sessionId = state.session?.sessionId;
      final stepId = state.currentStepId;

      if (sessionId != null) {
        await _repository.logDemoWorkoutStarted(
          sessionId: sessionId,
          stepId: stepId,
        );
      }

      debugPrint('[AppTourProvider] Demo workout started');
    } catch (e) {
      debugPrint('[AppTourProvider] Error logging demo start: $e');
    }
  }

  /// Mark demo workout as completed
  void logDemoWorkoutCompleted() {
    state = state.copyWith(demoWorkoutCompleted: true);
    debugPrint('[AppTourProvider] Demo workout completed');
  }

  /// Reset the tour (for settings restart)
  Future<void> resetTour() async {
    try {
      debugPrint('[AppTourProvider] Resetting tour');
      await _repository.resetTourCompletion();

      state = const AppTourState(
        shouldShowTour: true,
      );

      debugPrint('[AppTourProvider] Tour reset successfully');
    } catch (e) {
      debugPrint('[AppTourProvider] Error resetting tour: $e');
      state = state.copyWith(error: 'Failed to reset tour');
    }
  }

  /// Clear any error state
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Check if a specific step has a demo available
  bool stepHasDemo(int stepIndex) {
    final step = TourConstants.getStepByIndex(stepIndex);
    return step?.showDemoButton ?? false;
  }

  /// Check if a specific step has a deep link
  bool stepHasDeepLink(int stepIndex) {
    final step = TourConstants.getStepByIndex(stepIndex);
    return step?.deepLinkRoute != null;
  }
}

// ============================================
// Providers
// ============================================

/// Main app tour provider
final appTourProvider =
    StateNotifierProvider<AppTourNotifier, AppTourState>((ref) {
  final repository = ref.watch(appTourRepositoryProvider);
  return AppTourNotifier(repository);
});

/// Whether the tour should be shown (convenience provider)
final shouldShowTourProvider = Provider<bool>((ref) {
  return ref.watch(appTourProvider).shouldShowTour;
});

/// Current tour step (convenience provider)
final currentTourStepProvider = Provider<TourStep?>((ref) {
  return ref.watch(appTourProvider).currentStep;
});

/// Current tour step index (convenience provider)
final currentTourStepIndexProvider = Provider<int>((ref) {
  return ref.watch(appTourProvider).currentStepIndex;
});

/// Tour progress (0.0 to 1.0) (convenience provider)
final tourProgressProvider = Provider<double>((ref) {
  return ref.watch(appTourProvider).progress;
});

/// Whether tour is loading (convenience provider)
final tourLoadingProvider = Provider<bool>((ref) {
  return ref.watch(appTourProvider).isLoading;
});

/// Whether on first step (convenience provider)
final isFirstTourStepProvider = Provider<bool>((ref) {
  return ref.watch(appTourProvider).isFirstStep;
});

/// Whether on last step (convenience provider)
final isLastTourStepProvider = Provider<bool>((ref) {
  return ref.watch(appTourProvider).isLastStep;
});

/// Tour session (convenience provider)
final tourSessionProvider = Provider<AppTourSession?>((ref) {
  return ref.watch(appTourProvider).session;
});

/// Tour error (convenience provider)
final tourErrorProvider = Provider<String?>((ref) {
  return ref.watch(appTourProvider).error;
});

/// Whether tour is active (convenience provider)
final isTourActiveProvider = Provider<bool>((ref) {
  return ref.watch(appTourProvider).isActive;
});

/// Total tour steps (convenience provider)
final totalTourStepsProvider = Provider<int>((ref) {
  return ref.watch(appTourProvider).totalSteps;
});
