import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/observers/modal_route_observer.dart';
import '../core/services/posthog_service.dart';
import '../core/services/sentry_service.dart';
import 'posthog_route_observer.dart';
import 'sentry_screen_tag_observer.dart';
import '../shareables/widgets/share_plan_period_sheet.dart';
import '../data/models/workout.dart';
import '../data/models/user.dart' as app_user;
import '../data/repositories/auth_repository.dart';
import '../data/services/bootstrap_prefetch_service.dart';
import '../screens/achievements/achievements_screen.dart';
import '../screens/challenges/challenge_compare_screen.dart';
import '../screens/auth/sign_in_screen.dart';
import '../screens/auth/email_sign_in_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/cycle/cycle_screen.dart';
import '../screens/features/feature_voting_screen.dart';
import '../screens/coming_soon/coming_soon_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/library/library_screen.dart';
import '../screens/library/screens/all_splits_screen.dart';
import '../screens/mindfulness/mindfulness_session_screen.dart';
import '../screens/nutrition/nutrition_screen.dart';
import '../screens/nutrition/nutrition_settings_screen.dart';
import '../screens/fasting/fasting_screen_redesigned.dart';
import '../screens/fasting/fasting_body_status_screen.dart';
import '../screens/fasting/fasting_guide_screen.dart';
import '../screens/stats/comprehensive_stats_screen.dart';
import '../screens/onboarding/pre_auth_quiz_screen.dart';
import '../screens/onboarding/notification_prime_screen.dart';
import '../screens/onboarding/permissions_primer_screen.dart';
import '../screens/onboarding/health_connect_onboarding_screen.dart';
import '../screens/onboarding/coach_selection_screen.dart';
import '../screens/onboarding/personal_info_screen.dart';
import '../screens/onboarding/fitness_assessment_screen.dart';
import '../screens/onboarding/weight_projection_screen.dart';
import '../screens/onboarding/workout_generation_screen.dart';
// ── Onboarding v5 screens
import '../screens/onboarding/plan_analyzing_screen.dart';
// ── Onboarding v5.1: merged trust + expectations screen
import '../screens/onboarding/trust_and_expectations_screen.dart';
import '../screens/onboarding/demo_tasks_screen.dart';
import '../screens/onboarding/workout_showcase_screen.dart';
import '../screens/onboarding/nutrition_showcase_screen.dart';
import '../screens/onboarding/founder_note_sheet.dart';
import '../screens/onboarding/capability_and_community_screen.dart';
import '../screens/onboarding/commitment_pact_screen.dart';
import '../screens/onboarding/onboarding_why_screen.dart';
import '../screens/onboarding/onboarding_reflect_screen.dart';
import '../screens/onboarding/onboarding_blocker_screen.dart';
import '../screens/onboarding/onboarding_confidence_screen.dart';
import '../screens/onboarding/onboarding_value_screen.dart';
import '../screens/you/you_hub_screen.dart';
import '../screens/reports/reports_hub_screen.dart';
import '../screens/summaries/insights_screen.dart';
import '../screens/summaries/insights_detail_screen.dart';
import '../data/models/weekly_summary.dart';
import '../data/services/saved_workouts_service.dart';
import '../screens/social/social_screen.dart';
import '../screens/social/shared_workout_detail_screen.dart';
import '../screens/workouts/workouts_screen.dart';
import '../screens/metrics/metrics_dashboard_screen.dart';
import '../screens/workout/active_workout_entry.dart';
import '../screens/workout/workout_complete_screen.dart';
import '../screens/workout/workout_detail_screen.dart';
import '../screens/workout/mood_workout_pre_start_screen.dart';
import '../screens/workout/workout_summary_screen_v2.dart';
import '../screens/workout/exercise_detail_screen.dart';
import '../screens/workout/custom_workout_builder_screen.dart';
import '../screens/workout/exercise_progressions_screen.dart';
import '../screens/workout/program_library_screen.dart';
import '../screens/workout/program_template_builder_screen.dart';
import '../screens/workout/template_list_screen.dart';
import '../data/models/program_template.dart';
import '../screens/schedule/schedule_screen.dart';
import '../screens/auth/intro_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/pages/pages.dart';
import '../screens/settings/ai_data_usage_screen.dart';
import '../screens/profile/imports_screen.dart';
import '../screens/settings/ai_integrations_screen.dart';
import '../screens/settings/medical_disclaimer_screen.dart';
import '../screens/settings/exercise_preferences/my_exercises_screen.dart';
import '../screens/settings/training_methods_screen.dart';
import '../screens/settings/workout_history_import_screen.dart';
import '../screens/settings/export_data_screen.dart';
import '../screens/settings/training/my_1rms_screen.dart';
import '../screens/home/home_my_space_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/ai_settings/ai_settings_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/measurements/measurements_screen.dart';
import '../screens/measurements/measurement_detail_screen.dart';
import '../screens/body_analyzer/body_analyzer_screen.dart';
import '../screens/health/sleep_detail_screen.dart';
import '../screens/health/combined_health_screen.dart';
import '../screens/pillar/pillar_detail_screen.dart';
import '../screens/pillar/full_screen_chart_screen.dart';
import '../data/providers/pillar_history_provider.dart';
import '../data/providers/demo_tasks_seen_provider.dart';
import '../data/providers/lapsed_paywall_gate_provider.dart';
import '../core/providers/subscription_provider.dart';
import '../screens/settings/cycle_settings_screen.dart';
import '../screens/measurements/derived_metric_detail_screen.dart';
import '../screens/trends/custom_trend_screen.dart';
import '../data/providers/trend_series_provider.dart';
import '../screens/glossary/glossary_screen.dart';
import '../screens/personal_goals/personal_goals_screen.dart';
import '../screens/paywall/hard_paywall_screen.dart';
import '../screens/paywall/paywall_features_screen.dart';
import '../screens/paywall/paywall_timeline_screen.dart';
import '../screens/paywall/paywall_pricing_screen.dart';
import '../screens/loading/workout_loading_screen.dart';
import '../screens/profile/workout_gallery_screen.dart';
import '../screens/profile/synced_workouts_history_screen.dart';
// Progress screen removed - functionality merged into Stats screen
// import '../screens/progress/progress_screen.dart';
import '../screens/progress/milestones_screen.dart';
import '../screens/progress/charts/progress_charts_screen.dart';
import '../screens/progress/consistency_screen.dart';
import '../screens/progress/exercise_history/exercise_history_screen.dart';
import '../screens/stats/personal_records_screen.dart';
import '../screens/progress/exercise_history/exercise_progress_detail_screen.dart';
import '../screens/progress/muscle_analytics/muscle_analytics_screen.dart';
import '../screens/progress/muscle_analytics/muscle_detail_screen.dart';
import '../data/models/exercise.dart';
import '../widgets/main_shell.dart';
import '../core/providers/language_provider.dart';
import '../core/accessibility/accessibility_provider.dart';
import '../screens/nutrition/widget_log_trigger_screen.dart';
import '../screens/nutrition/recipe_suggestions_screen.dart';
import '../screens/nutrition/menu_analysis_history_screen.dart';
import '../screens/nutrition/saved_hub_screen.dart';
import '../data/services/api_client.dart';
import '../screens/mood/mood_history_screen.dart';
import '../screens/scores/scoring_screen.dart';
import '../screens/custom_exercises/custom_exercises_screen.dart';
// Avoided screens now accessed via unified MyExercisesScreen
// import '../screens/settings/exercise_preferences/avoided_exercises_screen.dart';
// import '../screens/settings/exercise_preferences/avoided_muscles_screen.dart';
import '../screens/settings/subscription/request_refund_screen.dart';
import '../screens/settings/subscription/subscription_management_screen.dart';
import '../screens/skills/skill_progressions_screen.dart';
import '../screens/skills/chain_detail_screen.dart';
import '../screens/demo/demo_workout_screen.dart';
import '../screens/demo/demo_active_workout_screen.dart';
import '../screens/demo/plan_preview_screen.dart';
// Guest mode is disabled - screens kept but not routed
// import '../screens/guest/guest_home_screen.dart';
// import '../screens/guest/guest_library_screen.dart';
import '../screens/cardio/log_cardio_screen.dart';
import '../screens/cardio/race_predictor_detail_screen.dart';
import '../screens/cardio/training_load_screen.dart';
import '../screens/cardio/vo2max_detail_screen.dart';
import '../screens/settings/manage_duplicate_imports_screen.dart';
import '../screens/neat/neat_dashboard_screen.dart';
import '../screens/live_chat/live_chat_screen.dart';
import '../screens/trophies/trophy_room_screen.dart';
import '../screens/trophies/badge_hub_screen.dart';
import '../screens/leaderboard/xp_leaderboard_screen.dart';
import '../screens/rewards/rewards_screen.dart';
import '../screens/inventory/inventory_screen.dart';
import '../screens/merch/merch_claims_screen.dart';
import '../screens/referrals/referrals_screen.dart';
import '../screens/cosmetics/cosmetics_gallery_screen.dart';
import '../screens/discover/discover_screen.dart';
import '../screens/xp_goals/xp_goals_screen.dart';
// Guest mode provider import kept for potential future re-enablement
// import '../data/providers/guest_mode_provider.dart';
import '../data/providers/xp_provider.dart';
import '../data/providers/today_workout_provider.dart';
import '../screens/injuries/injuries_list_screen.dart';
import '../screens/injuries/report_injury_screen.dart';
import '../screens/injuries/injury_detail_screen.dart';
import '../screens/strain_prevention/strain_dashboard_screen.dart';
import '../screens/strain_prevention/volume_history_screen.dart';
import '../screens/strain_prevention/report_strain_screen.dart';
import '../screens/diabetes/diabetes_dashboard_screen.dart';
import '../screens/plateau/plateau_dashboard_screen.dart';
import '../screens/settings/senior_fitness_screen.dart';
import '../screens/settings/progression_pace_screen.dart';
import '../screens/settings/training_focus_screen.dart';
import '../screens/settings/beast_mode/beast_mode_screen.dart';
import '../screens/settings/exercise_science_research_screen.dart';
import '../screens/weekly_plan/weekly_plan_screen.dart';
import '../screens/hormonal_health/hormonal_health_screen.dart';
import '../screens/hormonal_health/hormonal_health_settings_screen.dart';
import '../screens/kegel/kegel_session_screen.dart';
import '../screens/habits/habits_screen.dart';
import '../screens/habits/habit_detail_screen.dart';
import '../screens/wrapped/wrapped_viewer_screen.dart';
import '../screens/wrapped/my_wrapped_screen.dart';
import '../screens/wrapped/weekly_wrapped_screen.dart';
import '../screens/dashboard/coach_dashboard_screen.dart';
import '../screens/nutrition/recipes/public_recipe_screen.dart';

part 'app_router_workout_routes.dart';
part 'app_router_pre_auth_routes.dart';
part 'app_router_main_shell_routes.dart';
part 'app_router_settings_routes.dart';
part 'app_router_utility_routes.dart';


/// Listenable for auth, language, and accessibility state changes to trigger router refresh
class _AuthStateNotifier extends ChangeNotifier {
  _AuthStateNotifier(this._ref) {
    _ref.listen<AuthState>(authStateProvider, (_, __) {
      notifyListeners();
    });
    _ref.listen<LanguageState>(languageProvider, (_, __) {
      notifyListeners();
    });
    _ref.listen<AccessibilitySettings>(accessibilityProvider, (_, __) {
      notifyListeners();
    });
    // Onboarding v5.1: aiConsentProvider listener removed — consent is now
    // captured as an inline checkbox on the sign-in screen, not a separate
    // gated screen, so we no longer need a redirect-driving listener.
  }

  final Ref _ref;
}

/// Provider that tracks the current route location
/// This allows widgets to rebuild when navigation happens
final currentRouteProvider = StateProvider<String>((ref) => '/splash');

// ---------------------------------------------------------------------------
// Redirect helper functions
// ---------------------------------------------------------------------------

/// Handle widget deep link redirects (fitwiz:// scheme)
String? _handleDeepLinkRedirect(GoRouterState state, {PosthogService? posthog}) {
  final matched = state.matchedLocation;
  String? redirect;
  if (matched == '/add') {
    debugPrint('Router: Widget deep link /add -> /nutrition?tab=2');
    redirect = '/nutrition?tab=2';
  } else if (matched == '/share') {
    debugPrint('Router: Widget deep link /share -> /social');
    redirect = '/social';
  } else if (matched == '/start') {
    debugPrint('Router: Widget deep link /start -> /home');
    redirect = '/home';
  }
  if (redirect != null) {
    posthog?.capture(
      eventName: 'deep_link_opened',
      properties: <String, Object>{
        'deep_link_path': state.uri.toString(),
      },
    );
  }
  return redirect;
}

/// Handle loading/initial auth states - keep user on splash or pre-auth screens
String? _handleLoadingState(GoRouterState state, AuthState authState, LanguageState languageState) {
  if (authState.status != AuthStatus.initial &&
      authState.status != AuthStatus.loading &&
      !languageState.isLoading) {
    return null; // Not in loading state, skip
  }

  // Startup instrumentation — record how long the router keeps the user on
  // splash waiting for auth. This is the most likely culprit for the
  // "loads again" perception on cold-open.
  if (kDebugMode) {
    debugPrint(
      '⏱️ [startup] auth gate · status=${authState.status} '
      'lang_loading=${languageState.isLoading} loc=${state.matchedLocation}',
    );
  }

  final loc = state.matchedLocation;
  if (loc == '/splash') return null; // Stay on splash

  // Allow pre-auth screens to stay during loading (don't interrupt sign-in flow)
  const preAuthScreens = {
    '/onboarding-why',
    '/pre-auth-quiz', '/sign-in', '/email-sign-in',
    '/demo-workout', '/plan-preview', '/intro',
    // Onboarding v5.1 pre-signup screens
    '/onboarding-reflect', '/onboarding-blocker',
    '/trust-and-expectations', '/plan-analyzing',
    '/weight-projection', '/demo-tasks',
    '/demo-workout-showcase', '/demo-nutrition-showcase',
  };
  if (preAuthScreens.contains(loc)) return null;

  return '/splash'; // Everything else -> splash while loading
}

/// Handle auth error state
String? _handleAuthError(GoRouterState state, AuthState authState) {
  if (authState.status != AuthStatus.error) return null;

  final loc = state.matchedLocation;
  // Allow sign-in pages to show errors
  if (loc == '/sign-in' || loc == '/email-sign-in') return null;
  // Allow other pre-auth pages to stay
  const preAuthScreens = {
    '/onboarding-why',
    '/pre-auth-quiz', '/demo-workout', '/plan-preview', '/intro',
    // Onboarding v5.1 pre-signup screens
    '/onboarding-reflect', '/onboarding-blocker',
    '/trust-and-expectations', '/plan-analyzing',
    '/weight-projection', '/demo-tasks',
    '/demo-workout-showcase', '/demo-nutrition-showcase',
  };
  if (preAuthScreens.contains(loc)) return null;

  // For non-pre-auth screens during error, don't redirect (original behavior)
  return null;
}

/// Get the next onboarding step for a logged-in user
String? _getNextOnboardingStep(app_user.User user, Ref ref) {
  // Step 0: Check if pre-auth quiz is complete
  // SKIP this check if user has already completed later steps (coach selection or paywall)
  // This prevents race condition where SharedPreferences hasn't loaded yet on app reopen
  // and also handles users who signed up before the pre-auth quiz existed
  if (!user.isCoachSelected && !user.isPaywallComplete) {
    final quizData = ref.read(preAuthQuizProvider);
    if (!quizData.isComplete) {
      return '/pre-auth-quiz';
    }
  }

  // Onboarding v5.1.1 (May 2026): name moved BACK to /personal-info post
  // sign-in per ONBOARDING_FLOW.md. The quiz body-metrics gate captures
  // gender/height/weight only; /personal-info collects name + DOB and
  // re-confirms body metrics so the user record is complete before we
  // route to coach-selection.
  // AI consent is captured as an inline checkbox on the sign-in screen.

  // Step 0.5: Demo tasks (workout + nutrition app-taste) for users who
  // signed up via the "Sign In" shortcut on /intro and never passed through
  // the Build-My-Plan funnel. Funnel users have already had `markSeen()`
  // fire when they landed on /demo-tasks pre-auth, so they skip this branch.
  // Gate only fires before personal info is collected — once a user has
  // started filling in their profile we never re-route them back here.
  if (!user.isPersonalInfoComplete && !ref.read(demoTasksSeenProvider)) {
    debugPrint('🧭 [Router] _getNextOnboardingStep → /demo-tasks '
        '(new user, demo not yet seen)');
    return '/demo-tasks';
  }

  // Step 1: Personal info (name, DOB) — gate exists at user.dart:194 and
  // requires name + dateOfBirth + gender + heightCm + weightKg.
  if (!user.isPersonalInfoComplete) {
    debugPrint('🧭 [Router] _getNextOnboardingStep → /personal-info '
        '(name=${user.name != null}, dob=${user.dateOfBirth != null}, '
        'gender=${user.gender != null}, h=${user.heightCm != null}, '
        'w=${user.weightKg != null})');
    return '/personal-info';
  }

  // Step 2: Coach selection
  if (!user.isCoachSelected) {
    return '/coach-selection';
  }

  // Step 3: Conversational onboarding is SKIPPED
  // Coach selection now marks onboarding complete and goes directly to paywall/home

  // Step 4: Paywall (after coach selection)
  if (!user.isPaywallComplete) {
    return '/paywall-pricing';
  }

  // All steps complete
  return null;
}

/// Get the appropriate home route based on accessibility mode
String _getHomeRoute(AccessibilitySettings accessibilitySettings) {
  if (accessibilitySettings.mode == AccessibilityMode.senior) {
    return '/senior-home';
  }
  return '/home';
}

/// If the user is an unsubscribed lapser (≥7d since last workout, not on
/// Premium/Premium+/Lifetime) AND we haven't already shown them the winback
/// paywall in the last 24h, return `/paywall-pricing`. Otherwise return null
/// and let the caller fall through to the home route.
///
/// Side-effects on a positive decision:
///   * Marks the [lapsedPaywallGateProvider] timestamp so the next redirect
///     tick observes the 24h suppression window.
///   * Fires `paywall_routed_lapsed_user` PostHog event so the funnel
///     `lifecycle_email_sent → lifecycle_email_clicked → app_open_after_gap
///      → paywall_routed_lapsed_user → subscription_purchased` becomes
///     measurable end-to-end.
///
/// RevenueCat's offering targeting handles whether this user sees the
/// regular paywall or a discounted winback offering — the app-side job is
/// just to get them to the paywall.
String? _maybeRouteLapsedUser(app_user.User user, Ref ref) {
  final daysInactive = user.daysSinceLastWorkout ?? 0;
  if (daysInactive < 7) return null;

  final sub = ref.read(subscriptionProvider);
  if (sub.isPremiumOrHigher) return null;

  final gate = ref.read(lapsedPaywallGateProvider.notifier);
  if (!gate.shouldShowNow()) return null;

  // Mark BEFORE returning so a re-render in the same tick doesn't double-fire
  // the route (GoRouter sometimes re-evaluates redirect for the same loc).
  gate.markShown();

  ref.read(posthogServiceProvider).capture(
        eventName: 'paywall_routed_lapsed_user',
        properties: {
          'days_since_last_workout': daysInactive,
        },
      );
  return '/paywall-pricing';
}

/// Handle auth-based redirects (splash, onboarding, login gates)
String? _handleAuthRedirect(
  GoRouterState state,
  Ref ref,
  AuthState authState,
  AccessibilitySettings accessibilitySettings,
) {
  final loc = state.matchedLocation;
  final isLoggedIn = authState.status == AuthStatus.authenticated;
  final homeRoute = _getHomeRoute(accessibilitySettings);

  // Redirect from splash to appropriate destination
  if (loc == '/splash') {
    if (isLoggedIn) {
      final user = authState.user;
      if (user != null) {
        final nextStep = _getNextOnboardingStep(user, ref);
        if (nextStep != null) return nextStep;
        // Onboarding complete — check the lapsed-user gate before falling
        // through to home. A 7+ day silent user on Free should land on the
        // paywall first so RevenueCat can surface the winback offering.
        final lapsedRoute = _maybeRouteLapsedUser(user, ref);
        if (lapsedRoute != null) return lapsedRoute;
      }
      // Fire-and-forget: prefetch ALL home screen data during splash → home transition
      BootstrapPrefetchService.prefetch(ref);
      return homeRoute;
    } else {
      return '/intro';
    }
  }

  // Stats welcome - allow if not logged in, redirect if logged in
  if (loc == '/intro') {
    if (isLoggedIn) {
      final user = authState.user;
      if (user != null) {
        final nextStep = _getNextOnboardingStep(user, ref);
        if (nextStep != null) return nextStep;
        final lapsedRoute = _maybeRouteLapsedUser(user, ref);
        if (lapsedRoute != null) return lapsedRoute;
      }
      return homeRoute;
    }
    return null;
  }

  // Demo and plan preview screens - allow for anyone (no auth required)
  if (loc == '/demo-workout' || loc == '/plan-preview') {
    return null;
  }

  // Pre-auth flow screens — Onboarding v5.1 pre-signup funnel
  const preAuthFlowScreens = {
    '/onboarding-why',
    '/pre-auth-quiz', '/sign-in', '/email-sign-in',
    '/onboarding-reflect', '/onboarding-blocker',
    '/trust-and-expectations', '/plan-analyzing',
    '/weight-projection', '/demo-tasks',
    '/demo-workout-showcase', '/demo-nutrition-showcase',
  };
  if (preAuthFlowScreens.contains(loc)) {
    if (isLoggedIn) {
      final user = authState.user;
      // Allow replay of pre-signup flow for users starting over (no coach selected)
      const replayableForReturningUser = {
        '/onboarding-why',
        '/pre-auth-quiz',
        '/onboarding-reflect', '/onboarding-blocker',
        '/trust-and-expectations', '/plan-analyzing',
        '/weight-projection', '/demo-tasks',
        '/demo-workout-showcase', '/demo-nutrition-showcase',
      };
      if (replayableForReturningUser.contains(loc) &&
          user != null && !user.isCoachSelected) {
        // Edge case: sign_in_screen pushes /sign-in via context.push (not
        // context.go), which stacks the screen on top of /demo-tasks (or
        // wherever the funnel terminates). After Google/Apple sign-in
        // flips authState to authenticated, the redirect listener fires
        // with state.matchedLocation = /demo-tasks (the BASE go-route
        // under the pushed /sign-in modal — not the pushed route itself).
        // Without this guard, the replay path returns null and the user
        // is trapped on /demo-tasks under the lingering /sign-in stack.
        // !isPersonalInfoComplete reliably identifies a fresh sign-up:
        // a returning user replaying the funnel intentionally has name +
        // DOB + body metrics on file from a prior attempt.
        if (!user.isPersonalInfoComplete) {
          final nextStep = _getNextOnboardingStep(user, ref);
          if (nextStep != null) return nextStep;
        }
        return null;
      }

      if (user != null) {
        final nextStep = _getNextOnboardingStep(user, ref);
        if (nextStep != null) return nextStep;
      }
      return homeRoute;
    }
    return null; // Allow for non-logged-in users
  }

  // Onboarding v5.1 removed: /training-split, /ai-consent, /health-disclaimer,
  // /accuracy-intro, /health-connect-setup, /feature-showcase — consolidated
  // into quiz/sign-in/Phase 2 or deferred.
  // /personal-info was REINTRODUCED in v5.1.1 to collect name + DOB
  // post-sign-in (see _getNextOnboardingStep above).

  // Personal info — auth required, post-sign-in only.
  if (loc == '/personal-info') {
    return isLoggedIn ? null : '/intro';
  }

  // Coach selection - auth required (also used for changing coach from settings)
  if (loc == '/coach-selection') {
    return isLoggedIn ? null : '/intro';
  }

  // (deprecated v4 education screens — guard kept for backward-compat redirects)
  if (false) {
    return isLoggedIn ? null : '/intro';
  }

  // Paywall screens - allow if user hasn't completed paywall yet
  // Subscription success screen - always allow for logged-in users
  // (paywall is already marked complete by the time we navigate here)
  if (loc == '/subscription-success') {
    return isLoggedIn ? null : '/intro';
  }

  // Hard paywall — allow for logged-in users with expired trial/sub
  if (loc == '/hard-paywall') {
    return isLoggedIn ? null : '/intro';
  }

  const paywallScreens = {'/paywall-features', '/paywall-timeline', '/paywall-pricing'};
  if (paywallScreens.contains(loc)) {
    if (isLoggedIn) {
      final user = authState.user;
      if (user != null && !user.isPaywallComplete) return null;
      // Allow re-visiting paywall pricing from hard-paywall or settings
      return null;
    }
    return '/intro';
  }

  // Allow onboarding-related routes
  if (loc == '/senior-onboarding' || loc == '/mode-selection') {
    return null;
  }

  // Notification pre-permission — reachable only for logged-in users who
  // completed onboarding. Let it through; the screen writes its own flag
  // so it never loops.
  if (loc == '/notifications-prime') {
    return isLoggedIn ? null : '/intro';
  }

  // Not logged in -> redirect to stats-welcome
  if (!isLoggedIn) {
    return '/intro';
  }

  // Redirect /home <-> /senior-home based on accessibility mode
  if (loc == '/home' && accessibilitySettings.mode == AccessibilityMode.senior) {
    return '/senior-home';
  }
  if (loc == '/senior-home' && accessibilitySettings.mode != AccessibilityMode.senior) {
    return '/home';
  }

  return null;
}

/// Flag to ensure daily login XP is only processed once per app session.
/// ANR fix: Without this, every router redirect (3-5 during startup) queued
/// a microtask to process daily login XP, adding main-thread pressure.
bool _dailyLoginXpProcessed = false;

/// Flag to ensure today's workout is pre-warmed only once per auth session.
/// Reset on logout so a fresh sign-in re-triggers the warm.
bool _todayWorkoutPrewarmed = false;

/// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthStateNotifier(ref);

  final posthog = ref.watch(posthogServiceProvider);

  final router = GoRouter(
    initialLocation: '/splash',
    // ANR fix: GoRouter debug logging generates 50+ print() calls during
    // startup redirect storm. Each print() is a synchronous platform channel
    // call that blocks the main thread. Only enable in debug builds.
    debugLogDiagnostics: kDebugMode,
    refreshListenable: authNotifier,
    observers: [
      PosthogRouteObserver(posthog),
      // Hides the workout mini-player pill whenever a modal route (bottom
      // sheet / dialog / popup) is on top, so it doesn't z-float above sheets.
      WorkoutMiniPlayerRouteObserver(ref),
      // No-op when Sentry is disabled; otherwise adds nav breadcrumbs.
      if (SentryService.isEnabled) SentryService.navigatorObserver(),
      // Pins `screen` + `route` tags onto every Sentry event so framework
      // asserts (RenderFlex overflow / FractionallySizedBox crash) are
      // searchable by screen in the issue list — the default observer only
      // attaches them to transactions, which framework asserts skip.
      if (SentryService.isEnabled) SentryScreenTagObserver(),
    ],
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final languageState = ref.read(languageProvider);
      final accessibilitySettings = ref.read(accessibilityProvider);

      // ANR fix: Gate verbose redirect logging behind kDebugMode
      if (kDebugMode) {
        debugPrint('Router redirect - uri: ${state.uri}, matchedLocation: ${state.matchedLocation}');
      }

      // 1. Handle widget deep links
      final deepLink = _handleDeepLinkRedirect(state, posthog: posthog);
      if (deepLink != null) return deepLink;

      // 2. Reset daily-login flag on logout so re-login processes it again
      if (authState.status == AuthStatus.unauthenticated) {
        _dailyLoginXpProcessed = false;
        _todayWorkoutPrewarmed = false;
      }

      // 3. Process daily login XP for authenticated users (fire-and-forget, once per auth session)
      if (authState.status == AuthStatus.authenticated && !_dailyLoginXpProcessed) {
        _dailyLoginXpProcessed = true;
        Future.microtask(() {
          ref.read(xpProvider.notifier).processDailyLogin();
        });
      }

      // 4. Pre-warm today's workout the moment auth completes — before
      // paywall / commitment-pact / notifications-prime — so by the time
      // a brand-new user lands on home/workouts the personalized plan is
      // already in cache and the "Preparing your workout…" placeholder
      // never renders. Backend reads quiz answers from user_metadata
      // attached at signUp, so the JIT generation can run immediately.
      if (authState.status == AuthStatus.authenticated && !_todayWorkoutPrewarmed) {
        _todayWorkoutPrewarmed = true;
        Future.microtask(() {
          try {
            ref.read(todayWorkoutProvider);
          } catch (e) {
            debugPrint('Router: today workout pre-warm failed (non-fatal): $e');
          }
        });
      }

      // 4. Handle loading/initial state
      final loadingRedirect = _handleLoadingState(state, authState, languageState);
      if (loadingRedirect != null) return loadingRedirect;
      // If loading state returned null but we ARE loading, stay put
      if (authState.status == AuthStatus.initial ||
          authState.status == AuthStatus.loading ||
          languageState.isLoading) {
        return null;
      }

      // 5. Handle auth error state
      _handleAuthError(state, authState);

      // 6. Handle auth-based redirects (onboarding, login gates, accessibility)
      return _handleAuthRedirect(state, ref, authState, accessibilitySettings);
    },
    routes: [
      // Pre-auth routes (extracted)
      ..._preAuthRoutes(),

      // Main app shell routes (extracted)
      ..._mainShellRoutes(),

      // Workout routes (extracted)
      ..._workoutRoutes(),

      // Settings routes (extracted)
      ..._settingsRoutes(),

      // Utility routes (extracted)
      ..._utilityRoutes(),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page not found: ${state.matchedLocation}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );

  // Listen to route changes and update the currentRouteProvider
  router.routerDelegate.addListener(() {
    // Get the full location including the actual matched path (not just parent shell)
    final config = router.routerDelegate.currentConfiguration;
    // Use fullPath which includes the complete route path
    final location = config.fullPath.isNotEmpty ? config.fullPath : config.uri.path;
    debugPrint('GoRouter listener: Route changed to $location (fullPath: ${config.fullPath}, uri: ${config.uri})');
    // Use Future.microtask to avoid modifying provider during build
    Future.microtask(() {
      ref.read(currentRouteProvider.notifier).state = location;
    });
  });

  return router;
});
