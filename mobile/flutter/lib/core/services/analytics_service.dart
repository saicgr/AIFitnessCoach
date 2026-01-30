import 'package:flutter/foundation.dart';

/// Analytics service for tracking onboarding events and user behavior.
///
/// STUB IMPLEMENTATION: This class currently logs to debug console only.
/// TODO: Wire up to Firebase Analytics, Mixpanel, or other analytics platform.
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
  // ===== SCREEN TRACKING =====

  /// Logs a screen view event.
  ///
  /// Call this whenever a new onboarding screen is displayed.
  /// Use descriptive screen names like "onboarding_screen_0", "plan_preview", etc.
  static void logScreenView(String screenName) {
    if (kDebugMode) {
      print('📊 [Analytics] Screen View: $screenName');
    }
    // TODO: Implement Firebase Analytics logScreenView
    // FirebaseAnalytics.instance.logScreenView(screenName: screenName);
  }

  // ===== ONBOARDING EVENTS =====

  /// Logs onboarding completion with detailed metrics.
  ///
  /// Call this when the user finishes the entire onboarding flow.
  ///
  /// Parameters:
  /// - [totalScreens]: Total number of screens shown (including skipped)
  /// - [skippedScreens]: Number of screens skipped (Phase 2/3 gates)
  /// - [nutritionOptedIn]: Whether user opted into nutrition guidance
  /// - [personalizationCompleted]: Whether user completed Phase 2 personalization
  static void logOnboardingCompleted({
    required int totalScreens,
    required int skippedScreens,
    required bool nutritionOptedIn,
    required bool personalizationCompleted,
  }) {
    if (kDebugMode) {
      print('📊 [Analytics] Onboarding Completed:');
      print('  Total Screens: $totalScreens');
      print('  Skipped: $skippedScreens');
      print('  Nutrition Opted In: $nutritionOptedIn');
      print('  Personalization: $personalizationCompleted');
    }
    // TODO: Implement Firebase Analytics logEvent
    // FirebaseAnalytics.instance.logEvent(
    //   name: 'onboarding_completed',
    //   parameters: {
    //     'total_screens': totalScreens,
    //     'skipped_screens': skippedScreens,
    //     'nutrition_opted_in': nutritionOptedIn,
    //     'personalization_completed': personalizationCompleted,
    //   },
    // );
  }

  /// Logs nutrition opt-in decision.
  ///
  /// Call this when user interacts with the nutrition gate (Screen 10).
  static void logNutritionOptIn(bool optedIn) {
    if (kDebugMode) {
      print('📊 [Analytics] Nutrition Opt-In: $optedIn');
    }
    // TODO: Implement Firebase Analytics logEvent
    // FirebaseAnalytics.instance.logEvent(
    //   name: 'nutrition_opt_in',
    //   parameters: {
    //     'opted_in': optedIn,
    //   },
    // );
  }

  /// Logs when user skips personalization (Phase 2).
  ///
  /// Call this when user taps "Skip for Now" on the personalization gate (Screen 6).
  static void logPersonalizationSkipped() {
    if (kDebugMode) {
      print('📊 [Analytics] Personalization Skipped');
    }
    // TODO: Implement Firebase Analytics logEvent
    // FirebaseAnalytics.instance.logEvent(
    //   name: 'personalization_skipped',
    // );
  }

  // ===== WORKOUT GENERATION EVENTS =====

  /// Logs successful workout generation.
  ///
  /// Call this when a workout is successfully generated from Gemini API.
  ///
  /// Parameters:
  /// - [primaryGoal]: The user's selected primary goal (e.g., "muscle_hypertrophy")
  /// - [duration]: Workout duration in minutes
  /// - [equipment]: List of equipment available
  static void logWorkoutGenerated({
    required String primaryGoal,
    required int duration,
    required List<String> equipment,
  }) {
    if (kDebugMode) {
      print('📊 [Analytics] Workout Generated:');
      print('  Primary Goal: $primaryGoal');
      print('  Duration: $duration min');
      print('  Equipment: $equipment');
    }
    // TODO: Implement Firebase Analytics logEvent
    // FirebaseAnalytics.instance.logEvent(
    //   name: 'workout_generated',
    //   parameters: {
    //     'primary_goal': primaryGoal,
    //     'duration': duration,
    //     'equipment': equipment.join(', '),
    //     'equipment_count': equipment.length,
    //   },
    // );
  }

  // ===== USER PROPERTY TRACKING =====

  /// Sets user properties for segmentation and analytics.
  ///
  /// Call this after onboarding completion to tag user with relevant properties.
  ///
  /// Parameters:
  /// - [fitnessLevel]: User's fitness level (beginner, intermediate, advanced)
  /// - [goals]: List of user goals
  /// - [workoutsPerWeek]: Number of workouts per week
  static void setUserProperties({
    required String fitnessLevel,
    required List<String> goals,
    required int workoutsPerWeek,
  }) {
    if (kDebugMode) {
      print('📊 [Analytics] User Properties Set:');
      print('  Fitness Level: $fitnessLevel');
      print('  Goals: $goals');
      print('  Workouts/Week: $workoutsPerWeek');
    }
    // TODO: Implement Firebase Analytics setUserProperty
    // FirebaseAnalytics.instance.setUserProperty(
    //   name: 'fitness_level',
    //   value: fitnessLevel,
    // );
    // FirebaseAnalytics.instance.setUserProperty(
    //   name: 'primary_goal',
    //   value: goals.isNotEmpty ? goals.first : 'none',
    // );
    // FirebaseAnalytics.instance.setUserProperty(
    //   name: 'workouts_per_week',
    //   value: workoutsPerWeek.toString(),
    // );
  }

  // ===== DROP-OFF TRACKING =====

  /// Logs when a user exits onboarding without completing.
  ///
  /// Call this when user navigates away from onboarding before finishing.
  ///
  /// Parameters:
  /// - [lastScreen]: The last screen the user was on before exiting
  /// - [screenIndex]: The index of the last screen (0-11)
  static void logOnboardingDropOff({
    required String lastScreen,
    required int screenIndex,
  }) {
    if (kDebugMode) {
      print('📊 [Analytics] Onboarding Drop-Off:');
      print('  Last Screen: $lastScreen');
      print('  Screen Index: $screenIndex');
    }
    // TODO: Implement Firebase Analytics logEvent
    // FirebaseAnalytics.instance.logEvent(
    //   name: 'onboarding_drop_off',
    //   parameters: {
    //     'last_screen': lastScreen,
    //     'screen_index': screenIndex,
    //   },
    // );
  }

  // ===== TIMING EVENTS =====

  /// Logs time taken to complete onboarding.
  ///
  /// Call this with the elapsed time when onboarding is completed.
  ///
  /// Parameters:
  /// - [durationSeconds]: Total time spent in onboarding (seconds)
  static void logOnboardingDuration(int durationSeconds) {
    if (kDebugMode) {
      print('📊 [Analytics] Onboarding Duration: ${durationSeconds}s (${durationSeconds ~/ 60}m ${durationSeconds % 60}s)');
    }
    // TODO: Implement Firebase Analytics logEvent
    // FirebaseAnalytics.instance.logEvent(
    //   name: 'onboarding_duration',
    //   parameters: {
    //     'duration_seconds': durationSeconds,
    //     'duration_minutes': (durationSeconds / 60).round(),
    //   },
    // );
  }
}
