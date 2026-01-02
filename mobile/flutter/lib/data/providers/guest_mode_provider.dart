import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/analytics_service.dart';

/// Guest mode session state
class GuestModeState {
  final bool isGuestMode;
  final DateTime? sessionStart;
  final Duration sessionDuration;
  final bool hasShownSessionWarning;
  final int featuresAttempted;
  final List<String> attemptedFeatures;
  final DateTime? firstAppOpenDate;
  final bool isDemoDay;
  final Map<String, Duration> featureEngagement;

  const GuestModeState({
    this.isGuestMode = false,
    this.sessionStart,
    this.sessionDuration = Duration.zero,
    this.hasShownSessionWarning = false,
    this.featuresAttempted = 0,
    this.attemptedFeatures = const [],
    this.firstAppOpenDate,
    this.isDemoDay = false,
    this.featureEngagement = const {},
  });

  /// Maximum session duration for guest mode (1 hour - was 10 minutes)
  /// Extended to give users real time to experience the app
  static const Duration maxSessionDuration = Duration(minutes: 60);

  /// Warning threshold (55 minutes - 5 minutes before expiry)
  static const Duration warningThreshold = Duration(minutes: 55);

  /// Demo Day duration - full 24 hours of unlimited access on first install
  static const Duration demoDayDuration = Duration(hours: 24);

  /// Check if Demo Day is still active (24 hours from first app open)
  bool get isDemoDayActive {
    if (firstAppOpenDate == null) return false;
    final elapsed = DateTime.now().difference(firstAppOpenDate!);
    return elapsed < demoDayDuration;
  }

  /// Get remaining Demo Day time
  Duration get demoDayRemaining {
    if (firstAppOpenDate == null) return Duration.zero;
    final elapsed = DateTime.now().difference(firstAppOpenDate!);
    final remaining = demoDayDuration - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Check if session is expired
  /// Demo Day users get unlimited session time
  bool get isSessionExpired {
    if (!isGuestMode || sessionStart == null) return false;
    // Demo Day users never expire during guest sessions
    if (isDemoDayActive) return false;
    return sessionDuration >= maxSessionDuration;
  }

  /// Check if session warning should be shown
  bool get shouldShowSessionWarning {
    if (!isGuestMode || sessionStart == null || hasShownSessionWarning) {
      return false;
    }
    return sessionDuration >= warningThreshold;
  }

  /// Get remaining session time
  Duration get remainingTime {
    if (!isGuestMode || sessionStart == null) return Duration.zero;
    final remaining = maxSessionDuration - sessionDuration;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Get session progress (0.0 to 1.0)
  double get sessionProgress {
    if (!isGuestMode || sessionStart == null) return 0.0;
    return (sessionDuration.inSeconds / maxSessionDuration.inSeconds)
        .clamp(0.0, 1.0);
  }

  GuestModeState copyWith({
    bool? isGuestMode,
    DateTime? sessionStart,
    Duration? sessionDuration,
    bool? hasShownSessionWarning,
    int? featuresAttempted,
    List<String>? attemptedFeatures,
    DateTime? firstAppOpenDate,
    bool? isDemoDay,
    Map<String, Duration>? featureEngagement,
  }) {
    return GuestModeState(
      isGuestMode: isGuestMode ?? this.isGuestMode,
      sessionStart: sessionStart ?? this.sessionStart,
      sessionDuration: sessionDuration ?? this.sessionDuration,
      hasShownSessionWarning:
          hasShownSessionWarning ?? this.hasShownSessionWarning,
      featuresAttempted: featuresAttempted ?? this.featuresAttempted,
      attemptedFeatures: attemptedFeatures ?? this.attemptedFeatures,
      firstAppOpenDate: firstAppOpenDate ?? this.firstAppOpenDate,
      isDemoDay: isDemoDay ?? this.isDemoDay,
      featureEngagement: featureEngagement ?? this.featureEngagement,
    );
  }
}

/// Guest mode notifier for managing guest state
class GuestModeNotifier extends StateNotifier<GuestModeState> {
  final AnalyticsService? _analytics;
  Timer? _sessionTimer;
  Timer? _durationUpdateTimer;

  GuestModeNotifier(this._analytics) : super(const GuestModeState()) {
    _loadGuestState();
  }

  /// Load any persisted guest state
  Future<void> _loadGuestState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final wasGuest = prefs.getBool('is_guest_mode') ?? false;
      final sessionStartMs = prefs.getInt('guest_session_start');
      final firstOpenMs = prefs.getInt('first_app_open');

      // Check for Demo Day (first app open within 24 hours)
      DateTime? firstAppOpenDate;
      bool isDemoDay = false;

      if (firstOpenMs != null) {
        firstAppOpenDate = DateTime.fromMillisecondsSinceEpoch(firstOpenMs);
        final elapsed = DateTime.now().difference(firstAppOpenDate);
        isDemoDay = elapsed < GuestModeState.demoDayDuration;
      } else {
        // First time opening the app - start Demo Day!
        firstAppOpenDate = DateTime.now();
        isDemoDay = true;
        await prefs.setInt('first_app_open', firstAppOpenDate.millisecondsSinceEpoch);
        debugPrint('[GuestMode] Demo Day started! 24 hours of full access.');
      }

      if (wasGuest && sessionStartMs != null) {
        final sessionStart = DateTime.fromMillisecondsSinceEpoch(sessionStartMs);
        final elapsed = DateTime.now().difference(sessionStart);

        // Demo Day users don't expire, regular guests expire after 1 hour
        final sessionExpired = !isDemoDay && elapsed >= GuestModeState.maxSessionDuration;

        if (!sessionExpired) {
          state = state.copyWith(
            isGuestMode: true,
            sessionStart: sessionStart,
            sessionDuration: elapsed,
            firstAppOpenDate: firstAppOpenDate,
            isDemoDay: isDemoDay,
          );
          _startTimers();
        } else {
          // Session expired - clear guest state
          await _clearPersistedState();
          // Keep first_app_open for Demo Day tracking
          state = state.copyWith(
            firstAppOpenDate: firstAppOpenDate,
            isDemoDay: isDemoDay,
          );
        }
      } else {
        // Not in guest mode but track Demo Day status
        state = state.copyWith(
          firstAppOpenDate: firstAppOpenDate,
          isDemoDay: isDemoDay,
        );
      }
    } catch (e) {
      debugPrint('Failed to load guest state: $e');
    }
  }

  /// Enter guest mode
  Future<void> enterGuestMode() async {
    debugPrint('[GuestMode] Entering guest mode');

    final now = DateTime.now();
    state = GuestModeState(
      isGuestMode: true,
      sessionStart: now,
      sessionDuration: Duration.zero,
    );

    // Persist guest state
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_guest_mode', true);
      await prefs.setInt('guest_session_start', now.millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Failed to persist guest state: $e');
    }

    // Track analytics
    _analytics?.trackEvent(
      eventName: 'guest_mode_started',
      category: 'onboarding',
      properties: {
        'timestamp': now.toIso8601String(),
      },
    );

    _startTimers();
  }

  /// Start session timers
  void _startTimers() {
    _stopTimers();

    // Update duration every second
    _durationUpdateTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateDuration(),
    );

    // Check session expiry every 10 seconds
    _sessionTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _checkSession(),
    );
  }

  /// Stop all timers
  void _stopTimers() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
    _durationUpdateTimer?.cancel();
    _durationUpdateTimer = null;
  }

  /// Update session duration
  void _updateDuration() {
    if (!state.isGuestMode || state.sessionStart == null) return;

    final elapsed = DateTime.now().difference(state.sessionStart!);
    state = state.copyWith(sessionDuration: elapsed);
  }

  /// Check session status
  void _checkSession() {
    if (!state.isGuestMode) return;

    // Check for expiry
    if (state.isSessionExpired) {
      debugPrint('[GuestMode] Session expired');
      _analytics?.trackEvent(
        eventName: 'guest_session_expired',
        category: 'onboarding',
        properties: {
          'features_attempted': state.featuresAttempted,
          'attempted_features': state.attemptedFeatures,
        },
      );
    }
  }

  /// Mark session warning as shown
  void markWarningShown() {
    state = state.copyWith(hasShownSessionWarning: true);
  }

  /// Track when a locked feature is attempted
  void trackFeatureAttempt(String featureName) {
    if (!state.isGuestMode) return;

    final updatedFeatures = [...state.attemptedFeatures];
    if (!updatedFeatures.contains(featureName)) {
      updatedFeatures.add(featureName);
    }

    state = state.copyWith(
      featuresAttempted: state.featuresAttempted + 1,
      attemptedFeatures: updatedFeatures,
    );

    _analytics?.trackEvent(
      eventName: 'guest_feature_attempted',
      category: 'onboarding',
      properties: {
        'feature': featureName,
        'attempt_count': state.featuresAttempted,
        'session_duration_seconds': state.sessionDuration.inSeconds,
      },
    );
  }

  /// Exit guest mode and clear state
  Future<void> exitGuestMode({bool convertedToSignup = false}) async {
    debugPrint('[GuestMode] Exiting guest mode, converted: $convertedToSignup');

    // Track conversion analytics
    if (convertedToSignup) {
      _analytics?.trackEvent(
        eventName: 'guest_to_signup_conversion',
        category: 'onboarding',
        properties: {
          'session_duration_seconds': state.sessionDuration.inSeconds,
          'features_attempted': state.featuresAttempted,
          'attempted_features': state.attemptedFeatures,
        },
      );
    }

    _stopTimers();
    await _clearPersistedState();

    state = const GuestModeState();
  }

  /// Clear persisted guest state
  Future<void> _clearPersistedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('is_guest_mode');
      await prefs.remove('guest_session_start');
    } catch (e) {
      debugPrint('Failed to clear persisted guest state: $e');
    }
  }

  @override
  void dispose() {
    _stopTimers();
    super.dispose();
  }
}

/// Provider for guest mode state
final guestModeProvider =
    StateNotifierProvider<GuestModeNotifier, GuestModeState>((ref) {
  final analytics = ref.watch(analyticsServiceProvider);
  return GuestModeNotifier(analytics);
});

/// Quick check if currently in guest mode
final isGuestModeProvider = Provider<bool>((ref) {
  return ref.watch(guestModeProvider).isGuestMode;
});

/// Provider for remaining session time
final guestSessionRemainingProvider = Provider<Duration>((ref) {
  return ref.watch(guestModeProvider).remainingTime;
});

/// Provider for session progress (for progress indicators)
final guestSessionProgressProvider = Provider<double>((ref) {
  return ref.watch(guestModeProvider).sessionProgress;
});

/// Provider to check if session is expired
final isGuestSessionExpiredProvider = Provider<bool>((ref) {
  return ref.watch(guestModeProvider).isSessionExpired;
});

/// Provider to check if warning should be shown
final shouldShowGuestWarningProvider = Provider<bool>((ref) {
  return ref.watch(guestModeProvider).shouldShowSessionWarning;
});

/// List of features that are locked in guest mode
class GuestModeFeatures {
  GuestModeFeatures._();

  /// Features that guests CAN access (expanded for better preview experience)
  static const Set<String> allowedFeatures = {
    'exercise_library_preview',
    'exercise_library_full', // Now show 50+ exercises instead of 20
    'sample_workout_view',
    'guest_home',
    'personalized_workout_preview', // Show their actual personalized plan
    'demo_workout_start', // Let them try ONE workout
    'sample_ai_chat', // Show sample AI conversation
    'pricing_preview', // View pricing without account
    'quiz_completion', // Complete the fitness quiz
  };

  /// Features that are LOCKED in guest mode
  static const Set<String> lockedFeatures = {
    'ai_coach_chat',
    'nutrition_tracking',
    'progress_analytics',
    'workout_generation',
    'workout_history',
    'custom_workouts',
    'meal_logging',
    'body_measurements',
    'personal_records',
    'social_features',
    'achievements',
  };

  /// Human-readable names for locked features
  static const Map<String, String> featureDisplayNames = {
    'ai_coach_chat': 'AI Coach Chat',
    'nutrition_tracking': 'Nutrition Tracking',
    'progress_analytics': 'Progress Analytics',
    'workout_generation': 'Personalized Workouts',
    'workout_history': 'Workout History',
    'custom_workouts': 'Custom Workouts',
    'meal_logging': 'Meal Logging',
    'body_measurements': 'Body Measurements',
    'personal_records': 'Personal Records',
    'social_features': 'Social Features',
    'achievements': 'Achievements',
  };

  /// Icons for locked features
  static const Map<String, String> featureIcons = {
    'ai_coach_chat': 'chat',
    'nutrition_tracking': 'restaurant',
    'progress_analytics': 'insights',
    'workout_generation': 'fitness_center',
    'workout_history': 'history',
    'custom_workouts': 'edit',
    'meal_logging': 'fastfood',
    'body_measurements': 'straighten',
    'personal_records': 'emoji_events',
    'social_features': 'people',
    'achievements': 'military_tech',
  };

  /// Check if a feature is allowed in guest mode
  static bool isFeatureAllowed(String feature) {
    return allowedFeatures.contains(feature);
  }

  /// Check if a feature is locked in guest mode
  static bool isFeatureLocked(String feature) {
    return lockedFeatures.contains(feature);
  }
}

/// Provider to check if Demo Day is active
final isDemoDayActiveProvider = Provider<bool>((ref) {
  return ref.watch(guestModeProvider).isDemoDayActive;
});

/// Provider for remaining Demo Day time
final demoDayRemainingProvider = Provider<Duration>((ref) {
  return ref.watch(guestModeProvider).demoDayRemaining;
});

/// Provider for formatted Demo Day remaining time (e.g., "23h 45m")
final demoDayRemainingFormattedProvider = Provider<String>((ref) {
  final remaining = ref.watch(demoDayRemainingProvider);
  if (remaining == Duration.zero) return 'Expired';

  final hours = remaining.inHours;
  final minutes = remaining.inMinutes % 60;

  if (hours > 0) {
    return '${hours}h ${minutes}m';
  } else {
    return '${minutes}m';
  }
});
