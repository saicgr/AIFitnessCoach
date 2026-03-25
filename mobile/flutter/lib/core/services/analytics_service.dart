import 'package:flutter/foundation.dart';
import 'posthog_service.dart';

/// Analytics service for tracking onboarding events and user behavior.
///
/// Forwards all calls to PostHog via [PosthogService].
/// Falls back to debug logging if PostHog hasn't been initialized.
///
/// Usage:
/// ```dart
/// AnalyticsService.logScreenView('onboarding_screen_0');
/// AnalyticsService.logOnboardingCompleted(
///   totalScreens: 12,
///   skippedScreens: 3,
///   nutritionOptedIn: true,
///   personalizationCompleted: false,
/// );
/// ```
class AnalyticsService {
  static PosthogService? _posthog;

  /// Initialize with the PostHog service instance.
  /// Call this once after the ProviderContainer is created.
  static void init(PosthogService service) {
    _posthog = service;
  }

  // ===== SCREEN TRACKING =====

  /// Logs a screen view event.
  static void logScreenView(String screenName) {
    if (kDebugMode) {
      debugPrint('[Analytics] Screen View: $screenName');
    }
    _posthog?.screen(screenName: screenName);
  }

  // ===== ONBOARDING EVENTS =====

  /// Logs onboarding completion with detailed metrics.
  static void logOnboardingCompleted({
    required int totalScreens,
    required int skippedScreens,
    required bool nutritionOptedIn,
    required bool personalizationCompleted,
  }) {
    if (kDebugMode) {
      debugPrint('[Analytics] Onboarding Completed:');
      debugPrint('  Total Screens: $totalScreens');
      debugPrint('  Skipped: $skippedScreens');
      debugPrint('  Nutrition Opted In: $nutritionOptedIn');
      debugPrint('  Personalization: $personalizationCompleted');
    }
    _posthog?.capture(
      eventName: 'onboarding_completed',
      properties: {
        'total_screens': totalScreens,
        'skipped_screens': skippedScreens,
        'nutrition_opted_in': nutritionOptedIn,
        'personalization_completed': personalizationCompleted,
      },
    );
  }

  /// Logs nutrition opt-in decision.
  static void logNutritionOptIn(bool optedIn) {
    if (kDebugMode) {
      debugPrint('[Analytics] Nutrition Opt-In: $optedIn');
    }
    _posthog?.capture(
      eventName: 'nutrition_opt_in',
      properties: {'opted_in': optedIn},
    );
  }

  /// Logs when user skips personalization (Phase 2).
  static void logPersonalizationSkipped() {
    if (kDebugMode) {
      debugPrint('[Analytics] Personalization Skipped');
    }
    _posthog?.capture(eventName: 'personalization_skipped');
  }

  // ===== WORKOUT GENERATION EVENTS =====

  /// Logs successful workout generation.
  static void logWorkoutGenerated({
    required String primaryGoal,
    required int duration,
    required List<String> equipment,
  }) {
    if (kDebugMode) {
      debugPrint('[Analytics] Workout Generated:');
      debugPrint('  Primary Goal: $primaryGoal');
      debugPrint('  Duration: $duration min');
      debugPrint('  Equipment: $equipment');
    }
    _posthog?.capture(
      eventName: 'workout_generated',
      properties: {
        'primary_goal': primaryGoal,
        'duration': duration,
        'equipment': equipment.join(', '),
        'equipment_count': equipment.length,
      },
    );
  }

  // ===== USER PROPERTY TRACKING =====

  /// Sets user properties for segmentation and analytics.
  static void setUserProperties({
    required String fitnessLevel,
    required List<String> goals,
    required int workoutsPerWeek,
  }) {
    if (kDebugMode) {
      debugPrint('[Analytics] User Properties Set:');
      debugPrint('  Fitness Level: $fitnessLevel');
      debugPrint('  Goals: $goals');
      debugPrint('  Workouts/Week: $workoutsPerWeek');
    }
    _posthog?.capture(
      eventName: 'user_properties_set',
      properties: {
        'fitness_level': fitnessLevel,
        'goals': goals.join(', '),
        'workouts_per_week': workoutsPerWeek,
      },
    );
  }

  // ===== DROP-OFF TRACKING =====

  /// Logs when a user exits onboarding without completing.
  static void logOnboardingDropOff({
    required String lastScreen,
    required int screenIndex,
  }) {
    if (kDebugMode) {
      debugPrint('[Analytics] Onboarding Drop-Off:');
      debugPrint('  Last Screen: $lastScreen');
      debugPrint('  Screen Index: $screenIndex');
    }
    _posthog?.capture(
      eventName: 'onboarding_drop_off',
      properties: {
        'last_screen': lastScreen,
        'screen_index': screenIndex,
      },
    );
  }

  // ===== TIMING EVENTS =====

  /// Logs time taken to complete onboarding.
  static void logOnboardingDuration(int durationSeconds) {
    if (kDebugMode) {
      debugPrint('[Analytics] Onboarding Duration: ${durationSeconds}s (${durationSeconds ~/ 60}m ${durationSeconds % 60}s)');
    }
    _posthog?.capture(
      eventName: 'onboarding_duration',
      properties: {
        'duration_seconds': durationSeconds,
        'duration_minutes': (durationSeconds / 60).round(),
      },
    );
  }
}
