import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/models/workout.dart';
import '../data/models/user.dart' as app_user;
import '../data/repositories/auth_repository.dart';
import '../screens/achievements/achievements_screen.dart';
import '../screens/challenges/challenge_compare_screen.dart';
import '../screens/auth/stats_welcome_screen.dart';
import '../screens/auth/sign_in_screen.dart';
import '../screens/auth/email_sign_in_screen.dart';
import '../screens/auth/pricing_preview_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/features/feature_voting_screen.dart';
import '../screens/coming_soon/coming_soon_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/home/senior_home_screen.dart';
import '../screens/hydration/hydration_screen.dart';
import '../screens/library/library_screen.dart';
import '../screens/nutrition/nutrition_screen.dart';
import '../screens/nutrition/nutrition_settings_screen.dart';
import '../screens/fasting/fasting_screen_redesigned.dart';
import '../screens/stats/comprehensive_stats_screen.dart';
import '../screens/onboarding/pre_auth_quiz_screen.dart';
import '../screens/onboarding/senior_onboarding_screen.dart';
import '../screens/onboarding/mode_selection_screen.dart';
import '../screens/onboarding/coach_selection_screen.dart';
import '../screens/onboarding/fitness_assessment_screen.dart';
import '../screens/onboarding/how_it_works_screen.dart';
import '../screens/onboarding/personal_info_screen.dart';
import '../screens/onboarding/ai_consent_screen.dart';
import '../screens/onboarding/weight_projection_screen.dart';
import '../screens/onboarding/workout_generation_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/summaries/weekly_summary_screen.dart';
import '../data/services/saved_workouts_service.dart';
import '../screens/social/social_screen.dart';
import '../screens/social/shared_workout_detail_screen.dart';
import '../screens/workouts/workouts_screen.dart';
import '../screens/metrics/metrics_dashboard_screen.dart';
import '../screens/workout/active_workout_screen_refactored.dart';
import '../screens/workout/workout_complete_screen.dart';
import '../screens/workout/workout_detail_screen.dart';
import '../screens/workout/workout_summary_screen.dart';
import '../screens/workout/exercise_detail_screen.dart';
import '../screens/workout/custom_workout_builder_screen.dart';
import '../screens/schedule/schedule_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/pages/pages.dart';
import '../screens/settings/ai_data_usage_screen.dart';
import '../screens/settings/medical_disclaimer_screen.dart';
import '../screens/settings/help_screen.dart';
import '../screens/settings/exercise_preferences/my_exercises_screen.dart';
import '../screens/settings/workout_history_import_screen.dart';
import '../screens/settings/training/my_1rms_screen.dart';
import '../screens/settings/layout_editor_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/ai_settings/ai_settings_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/measurements/measurements_screen.dart';
import '../screens/measurements/measurement_detail_screen.dart';
import '../screens/glossary/glossary_screen.dart';
import '../screens/personal_goals/personal_goals_screen.dart';
import '../screens/paywall/paywall_features_screen.dart';
import '../screens/paywall/paywall_timeline_screen.dart';
import '../screens/paywall/paywall_pricing_screen.dart';
import '../screens/loading/workout_loading_screen.dart';
import '../screens/profile/workout_gallery_screen.dart';
// Progress screen removed - functionality merged into Stats screen
// import '../screens/progress/progress_screen.dart';
import '../screens/progress/milestones_screen.dart';
import '../screens/progress/charts/progress_charts_screen.dart';
import '../screens/progress/consistency_screen.dart';
import '../screens/progress/exercise_history/exercise_history_screen.dart';
import '../screens/progress/exercise_history/exercise_progress_detail_screen.dart';
import '../screens/progress/muscle_analytics/muscle_analytics_screen.dart';
import '../screens/progress/muscle_analytics/muscle_detail_screen.dart';
import '../data/models/exercise.dart';
import '../widgets/main_shell.dart';
import '../core/providers/language_provider.dart';
import '../core/accessibility/accessibility_provider.dart';
import '../screens/nutrition/widget_log_trigger_screen.dart';
import '../screens/nutrition/recipe_suggestions_screen.dart';
import '../screens/mood/mood_history_screen.dart';
import '../screens/scores/scoring_screen.dart';
import '../screens/custom_exercises/custom_exercises_screen.dart';
// Avoided screens now accessed via unified MyExercisesScreen
// import '../screens/settings/exercise_preferences/avoided_exercises_screen.dart';
// import '../screens/settings/exercise_preferences/avoided_muscles_screen.dart';
import '../screens/settings/support/support_tickets_screen.dart';
import '../screens/settings/support/create_ticket_screen.dart';
import '../screens/settings/support/ticket_detail_screen.dart';
import '../screens/settings/subscription/subscription_history_screen.dart';
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
import '../screens/neat/neat_dashboard_screen.dart';
import '../screens/live_chat/live_chat_screen.dart';
import '../screens/admin_support/admin_support_list_screen.dart';
import '../screens/admin_support/admin_chat_screen.dart';
import '../screens/trophies/trophy_room_screen.dart';
import '../screens/leaderboard/xp_leaderboard_screen.dart';
import '../screens/rewards/rewards_screen.dart';
import '../screens/inventory/inventory_screen.dart';
import '../screens/xp_goals/xp_goals_screen.dart';
// Guest mode provider import kept for potential future re-enablement
// import '../data/providers/guest_mode_provider.dart';
import '../data/providers/xp_provider.dart';
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
String? _handleDeepLinkRedirect(GoRouterState state) {
  if (state.matchedLocation == '/add') {
    debugPrint('Router: Widget deep link /add -> /hydration');
    return '/hydration';
  }
  if (state.matchedLocation == '/share') {
    debugPrint('Router: Widget deep link /share -> /social');
    return '/social';
  }
  if (state.matchedLocation == '/start') {
    debugPrint('Router: Widget deep link /start -> /home');
    return '/home';
  }
  return null;
}

/// Handle loading/initial auth states - keep user on splash or pre-auth screens
String? _handleLoadingState(GoRouterState state, AuthState authState, LanguageState languageState) {
  if (authState.status != AuthStatus.initial &&
      authState.status != AuthStatus.loading &&
      !languageState.isLoading) {
    return null; // Not in loading state, skip
  }

  final loc = state.matchedLocation;
  if (loc == '/splash') return null; // Stay on splash

  // Allow pre-auth screens to stay during loading (don't interrupt sign-in flow)
  const preAuthScreens = {
    '/how-it-works', '/pre-auth-quiz', '/sign-in', '/email-sign-in',
    '/pricing-preview', '/demo-workout', '/plan-preview', '/stats-welcome',
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
    '/how-it-works', '/pre-auth-quiz', '/pricing-preview',
    '/demo-workout', '/plan-preview', '/stats-welcome',
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

  // Step 1: Personal info (name, DOB, gender, height, weight)
  if (!user.isPersonalInfoComplete) {
    return '/personal-info';
  }

  // Step 1.5: AI consent (after personal info, before coach selection)
  // Skip if user already selected a coach (existing users before this feature)
  if (!user.isCoachSelected) {
    final hasAiConsent = ref.read(aiConsentProvider);
    if (!hasAiConsent) {
      return '/ai-consent';
    }
  }

  // Step 2: Coach selection
  if (!user.isCoachSelected) {
    return '/coach-selection';
  }

  // Step 3: Conversational onboarding is SKIPPED
  // Coach selection now marks onboarding complete and goes directly to paywall/home

  // Step 4: Paywall (after coach selection)
  if (!user.isPaywallComplete) {
    return '/paywall-features';
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
      }
      return homeRoute;
    } else {
      return '/stats-welcome';
    }
  }

  // Stats welcome - allow if not logged in, redirect if logged in
  if (loc == '/stats-welcome') {
    if (isLoggedIn) {
      final user = authState.user;
      if (user != null) {
        final nextStep = _getNextOnboardingStep(user, ref);
        if (nextStep != null) return nextStep;
      }
      return homeRoute;
    }
    return null;
  }

  // Demo and plan preview screens - allow for anyone (no auth required)
  if (loc == '/demo-workout' || loc == '/plan-preview') {
    return null;
  }

  // Pre-auth flow screens (how-it-works, quiz, sign-in, pricing)
  const preAuthFlowScreens = {
    '/how-it-works', '/pre-auth-quiz', '/sign-in', '/email-sign-in', '/pricing-preview',
  };
  if (preAuthFlowScreens.contains(loc)) {
    if (isLoggedIn) {
      final user = authState.user;
      // Allow quiz/how-it-works if user is starting over (no coach selected)
      if ((loc == '/how-it-works' || loc == '/pre-auth-quiz') &&
          user != null && !user.isCoachSelected) {
        return null;
      }
      // Allow pricing preview for logged-in users
      if (loc == '/pricing-preview') return null;

      if (user != null) {
        final nextStep = _getNextOnboardingStep(user, ref);
        if (nextStep != null) return nextStep;
      }
      return homeRoute;
    }
    return null; // Allow for non-logged-in users
  }

  // Personal info - auth required
  if (loc == '/personal-info') {
    return isLoggedIn ? null : '/stats-welcome';
  }

  // Weight projection - auth required
  if (loc == '/weight-projection') {
    return isLoggedIn ? null : '/stats-welcome';
  }

  // AI consent - auth required
  if (loc == '/ai-consent') {
    return isLoggedIn ? null : '/stats-welcome';
  }

  // Coach selection - auth required (also used for changing coach from settings)
  if (loc == '/coach-selection') {
    return isLoggedIn ? null : '/stats-welcome';
  }

  // Paywall screens - allow if user hasn't completed paywall yet
  const paywallScreens = {'/paywall-features', '/paywall-timeline', '/paywall-pricing'};
  if (paywallScreens.contains(loc)) {
    if (isLoggedIn) {
      final user = authState.user;
      if (user != null && !user.isPaywallComplete) return null;
      return homeRoute;
    }
    return '/stats-welcome';
  }

  // Allow onboarding-related routes
  if (loc == '/senior-onboarding' || loc == '/mode-selection') {
    return null;
  }

  // Not logged in -> redirect to stats-welcome
  if (!isLoggedIn) {
    return '/stats-welcome';
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

/// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthStateNotifier(ref);

  final router = GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final languageState = ref.read(languageProvider);
      final accessibilitySettings = ref.read(accessibilityProvider);

      debugPrint('Router redirect - uri: ${state.uri}, matchedLocation: ${state.matchedLocation}');

      // 1. Handle widget deep links
      final deepLink = _handleDeepLinkRedirect(state);
      if (deepLink != null) return deepLink;

      // 2. Process daily login XP for authenticated users (fire-and-forget)
      if (authState.status == AuthStatus.authenticated) {
        Future.microtask(() {
          ref.read(xpProvider.notifier).processDailyLogin();
        });
      }

      // 3. Handle loading/initial state
      final loadingRedirect = _handleLoadingState(state, authState, languageState);
      if (loadingRedirect != null) return loadingRedirect;
      // If loading state returned null but we ARE loading, stay put
      if (authState.status == AuthStatus.initial ||
          authState.status == AuthStatus.loading ||
          languageState.isLoading) {
        return null;
      }

      // 4. Handle auth error state
      _handleAuthError(state, authState);

      // 5. Handle auth-based redirects (onboarding, login gates, accessibility)
      return _handleAuthRedirect(state, ref, authState, accessibilitySettings);
    },
    routes: [
      // === Pre-Auth Routes ===

      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),

      GoRoute(
        path: '/stats-welcome',
        builder: (context, state) => const StatsWelcomeScreen(),
      ),

      // How It Works - explains the 3-step onboarding journey before quiz
      GoRoute(
        path: '/how-it-works',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const HowItWorksScreen(),
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.05, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            );
          },
        ),
      ),

      // Pricing Preview - see pricing before creating account (pre-auth)
      GoRoute(
        path: '/pricing-preview',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PricingPreviewScreen(),
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            );
          },
        ),
      ),

      // Demo Workout - sample workout preview before sign-up (no auth required)
      GoRoute(
        path: '/demo-workout',
        pageBuilder: (context, state) {
          // Optional workout type can be passed as query parameter
          final workoutType = state.uri.queryParameters['type'];
          return CustomTransitionPage(
            key: state.pageKey,
            child: DemoWorkoutScreen(workoutType: workoutType),
            transitionDuration: const Duration(milliseconds: 400),
            reverseTransitionDuration: const Duration(milliseconds: 300),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                ),
              );
            },
          );
        },
      ),

      // Demo Active Workout - actually do the sample workout (no auth required)
      GoRoute(
        path: '/demo-active-workout',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final workout = extra?['workout'] as Map<String, dynamic>? ?? {};
          final exercises = extra?['exercises'] as List<Map<String, dynamic>>? ?? [];
          return CustomTransitionPage(
            key: state.pageKey,
            child: DemoActiveWorkoutScreen(
              workout: workout,
              exercises: exercises,
            ),
            transitionDuration: const Duration(milliseconds: 400),
            reverseTransitionDuration: const Duration(milliseconds: 300),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                ),
              );
            },
          );
        },
      ),

      // Plan Preview - Show full 4-week personalized workout plan BEFORE subscription
      // This addresses user complaint: "After giving all personal info, it requires subscription to see the personal plan"
      GoRoute(
        path: '/plan-preview',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PlanPreviewScreen(),
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                ),
                child: child,
              ),
            );
          },
        ),
      ),

      // Guest routes removed - guest mode is disabled
      // /guest-home and /guest-library redirected to /stats-welcome for any stale links
      GoRoute(
        path: '/guest-home',
        redirect: (context, state) => '/stats-welcome',
      ),
      GoRoute(
        path: '/guest-library',
        redirect: (context, state) => '/stats-welcome',
      ),

      // Pre-Auth Quiz - 5 questions before sign-in
      GoRoute(
        path: '/pre-auth-quiz',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PreAuthQuizScreen(),
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.05, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            );
          },
        ),
      ),

      // Sign-In Screen - after quiz
      GoRoute(
        path: '/sign-in',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SignInScreen(),
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.05),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            );
          },
        ),
      ),

      // Email Sign-In Screen - alternative to Google sign-in
      GoRoute(
        path: '/email-sign-in',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const EmailSignInScreen(),
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.05),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            );
          },
        ),
      ),

      // Personal Info Screen - collect name, DOB, gender, height, weight after sign-in
      GoRoute(
        path: '/personal-info',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PersonalInfoScreen(),
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.05, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            );
          },
        ),
      ),

      // Weight Projection Screen - show goal timeline graph
      GoRoute(
        path: '/weight-projection',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const WeightProjectionScreen(),
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.05, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            );
          },
        ),
      ),

      // AI Consent - privacy and data usage consent before coach selection
      GoRoute(
        path: '/ai-consent',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AiConsentScreen(),
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.05, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            );
          },
        ),
      ),

      // Coach Selection - pick your AI coach personality before onboarding
      // Also used for changing coach from AI settings (with ?fromSettings=true)
      GoRoute(
        path: '/coach-selection',
        pageBuilder: (context, state) {
          // Check if coming from AI settings (changing coach, not initial selection)
          final fromSettings = state.uri.queryParameters['fromSettings'] == 'true';
          return CustomTransitionPage(
            key: state.pageKey,
            child: CoachSelectionScreen(fromSettings: fromSettings),
            transitionDuration: const Duration(milliseconds: 400),
            reverseTransitionDuration: const Duration(milliseconds: 300),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.05, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                ),
              );
            },
          );
        },
      ),

      // Fitness Assessment - quick fitness check after coach selection
      GoRoute(
        path: '/fitness-assessment',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const FitnessAssessmentScreen(),
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.05, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            );
          },
        ),
      ),

      // Workout Generation - full screen progress while generating workouts
      GoRoute(
        path: '/workout-generation',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const WorkoutGenerationScreen(),
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      ),

      // Mode Selection (shown during onboarding after name/age)
      GoRoute(
        path: '/mode-selection',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ModeSelectionScreen(
            userAge: extra?['userAge'] as int?,
            onNormalSelected: extra?['onNormalSelected'] as VoidCallback?,
            onSeniorSelected: extra?['onSeniorSelected'] as VoidCallback?,
          );
        },
      ),

      // Senior Onboarding (Visual, simplified - NOT AI chat)
      GoRoute(
        path: '/senior-onboarding',
        builder: (context, state) => const SeniorOnboardingScreen(),
      ),

      // Paywall Screen 1: Feature highlights
      GoRoute(
        path: '/paywall-features',
        builder: (context, state) => const PaywallFeaturesScreen(),
      ),

      // Paywall Screen 2: Trial timeline
      GoRoute(
        path: '/paywall-timeline',
        builder: (context, state) => const PaywallTimelineScreen(),
      ),

      // Paywall Screen 3: Pricing selection
      GoRoute(
        path: '/paywall-pricing',
        builder: (context, state) => const PaywallPricingScreen(),
      ),

      GoRoute(
        path: '/senior-home',
        builder: (context, state) => const SeniorHomeScreen(),
      ),

      GoRoute(
        path: '/workout-loading',
        builder: (context, state) => const WorkoutLoadingScreen(),
      ),

      // === Main App Shell ===

      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) {
              // Check if edit mode is requested via query parameter
              final startEditMode = state.uri.queryParameters['edit'] == 'true';
              return NoTransitionPage(
                child: HomeScreen(startEditMode: startEditMode),
              );
            },
          ),
          GoRoute(
            path: '/nutrition',
            pageBuilder: (context, state) {
              // Support deep link: fitwiz://nutrition?meal=lunch
              final initialMeal = state.uri.queryParameters['meal'];
              return NoTransitionPage(
                child: NutritionScreen(initialMeal: initialMeal),
              );
            },
          ),
          GoRoute(
            path: '/fasting',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: FastingScreenRedesigned(),
            ),
          ),
          GoRoute(
            path: '/social',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SocialScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) {
              final scrollTo = state.uri.queryParameters['scrollTo'];
              return NoTransitionPage(
                child: ProfileScreen(scrollTo: scrollTo),
              );
            },
          ),
          GoRoute(
            path: '/workouts',
            pageBuilder: (context, state) {
              final scrollTo = state.uri.queryParameters['scrollTo'];
              return NoTransitionPage(
                child: WorkoutsScreen(scrollTo: scrollTo),
              );
            },
          ),
        ],
      ),

      // Stats (full screen, no bottom nav)
      GoRoute(
        path: '/stats',
        builder: (context, state) {
          final openPhoto = state.uri.queryParameters['openPhoto'] == 'true';
          final initialTab = int.tryParse(state.uri.queryParameters['tab'] ?? '');
          return ComprehensiveStatsScreen(openPhotoSheet: openPhoto, initialTab: initialTab);
        },
      ),
      // Redirect /progress to /stats
      GoRoute(
        path: '/progress',
        redirect: (context, state) => '/stats',
      ),

      // Chat (full screen overlay)
      // Supports deep link: fitwiz://chat?prompt=X
      GoRoute(
        path: '/chat',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          // Support both extra data and query parameters (deep links)
          final initialMessage = extra?['initialMessage'] as String?
              ?? state.uri.queryParameters['prompt'];
          return ChatScreen(
            initialMessage: initialMessage,
          );
        },
      ),

      // Live Chat - Human support
      GoRoute(
        path: '/live-chat',
        builder: (context, state) => const LiveChatScreen(),
      ),

      // Admin Support - List of support chats (admin only)
      GoRoute(
        path: '/admin-support',
        builder: (context, state) => const AdminSupportListScreen(),
      ),

      // Admin Support - Chat detail (admin only)
      GoRoute(
        path: '/admin-support/chat/:ticketId',
        builder: (context, state) {
          final ticketId = state.pathParameters['ticketId']!;
          return AdminChatScreen(ticketId: ticketId);
        },
      ),

      // === Workout Routes ===

      GoRoute(
        path: '/workout/:id',
        builder: (context, state) {
          final workoutId = state.pathParameters['id']!;
          return WorkoutDetailScreen(workoutId: workoutId);
        },
      ),

      // Workout completion summary
      GoRoute(
        path: '/workout-summary/:id',
        builder: (context, state) {
          final workoutId = state.pathParameters['id']!;
          return WorkoutSummaryScreen(workoutId: workoutId);
        },
      ),

      // Exercise detail (full screen with autoplay video)
      GoRoute(
        path: '/exercise-detail',
        builder: (context, state) {
          WorkoutExercise? exercise;
          if (state.extra is WorkoutExercise) {
            exercise = state.extra as WorkoutExercise;
          } else if (state.extra is Map<String, dynamic>) {
            exercise = WorkoutExercise.fromJson(state.extra as Map<String, dynamic>);
          }
          if (exercise == null) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text('No exercise data'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            );
          }
          return ExerciseDetailScreen(exercise: exercise);
        },
      ),

      // Active workout
      GoRoute(
        path: '/active-workout',
        builder: (context, state) {
          // Handle Workout object, Map with challenge data, or Map<String, dynamic> (from serialization)
          Workout? workout;
          String? challengeId;
          Map<String, dynamic>? challengeData;

          if (state.extra is Workout) {
            workout = state.extra as Workout;
          } else if (state.extra is Map<String, dynamic>) {
            final map = state.extra as Map<String, dynamic>;
            // Check if it's a challenge map with embedded Workout object
            if (map.containsKey('workout') && map['workout'] is Workout) {
              workout = map['workout'] as Workout;
              challengeId = map['challengeId'] as String?;
              challengeData = map['challengeData'] as Map<String, dynamic>?;
            } else {
              // Legacy: try parsing as Workout JSON
              try {
                workout = Workout.fromJson(map);
              } catch (e) {
                debugPrint('❌ [Router] Failed to parse workout from Map: $e');
              }
            }
          }
          if (workout == null) {
            // Fallback if no workout data
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text('No workout data available'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.go('/home'),
                      child: const Text('Go Home'),
                    ),
                  ],
                ),
              ),
            );
          }
          // Check for empty exercises list
          if (workout.exercises.isEmpty) {
            debugPrint('❌ [Router] Workout has no exercises: ${workout.id}');
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 48, color: Colors.orange),
                    const SizedBox(height: 16),
                    const Text(
                      'Workout has no exercises',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'This workout is missing exercise data. Please try regenerating it.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.go('/home'),
                      child: const Text('Go Home'),
                    ),
                  ],
                ),
              ),
            );
          }
          // Use video-based workout screen with set tracking overlay
          return ActiveWorkoutScreen(
            workout: workout,
            challengeId: challengeId,
            challengeData: challengeData,
          );
        },
      ),

      // Challenge compare screen (side-by-side results)
      GoRoute(
        path: '/challenge-compare',
        builder: (context, state) {
          final challengeId = state.extra as String;
          return ChallengeCompareScreen(challengeId: challengeId);
        },
      ),

      // Shared workout detail (from social feed)
      GoRoute(
        path: '/shared-workout',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>? ?? {};
          return SharedWorkoutDetailScreen(
            activityId: data['activityId'] as String? ?? '',
            currentUserId: data['currentUserId'] as String? ?? '',
            posterName: data['posterName'] as String? ?? '',
            posterAvatar: data['posterAvatar'] as String?,
            activityType: data['activityType'] as String? ?? 'workout_shared',
            activityData: data['activityData'] as Map<String, dynamic>? ?? {},
            savedWorkoutsService: data['savedWorkoutsService'] as SavedWorkoutsService,
          );
        },
      ),

      // Workout complete
      GoRoute(
        path: '/workout-complete',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>?;
          if (data == null) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, size: 48, color: Colors.green),
                    const SizedBox(height: 16),
                    const Text('Workout Complete!'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.go('/home'),
                      child: const Text('Go Home'),
                    ),
                  ],
                ),
              ),
            );
          }
          return WorkoutCompleteScreen(
            workout: data['workout'] as Workout,
            duration: data['duration'] as int,
            calories: data['calories'] as int,
            workoutLogId: data['workoutLogId'] as String?,
            exercisesPerformance: data['exercisesPerformance'] as List<Map<String, dynamic>>?,
            totalRestSeconds: data['totalRestSeconds'] as int?,
            avgRestSeconds: data['avgRestSeconds'] as double?,
            totalSets: data['totalSets'] as int?,
            totalReps: data['totalReps'] as int?,
            totalVolumeKg: data['totalVolumeKg'] as double?,
            challengeId: data['challengeId'] as String?,
            challengeData: data['challengeData'] as Map<String, dynamic>?,
            personalRecords: data['personalRecords'] as List<PersonalRecordInfo>?,
            performanceComparison: data['performanceComparison'] as PerformanceComparisonInfo?,
            plannedExercises: data['plannedExercises'] as List<Map<String, dynamic>>?,
            exerciseTimeSeconds: data['exerciseTimeSeconds'] as Map<int, int>?,
            // Heart rate data from watch (if available)
            heartRateReadings: data['heartRateReadings'] as List<HeartRateReadingData>?,
            avgHeartRate: data['avgHeartRate'] as int?,
            maxHeartRate: data['maxHeartRate'] as int?,
            minHeartRate: data['minHeartRate'] as int?,
          );
        },
      ),

      // Custom Workout Builder - Create your own workout from scratch
      GoRoute(
        path: '/workout/build',
        builder: (context, state) => const CustomWorkoutBuilderScreen(),
      ),

      // Achievements
      GoRoute(
        path: '/achievements',
        builder: (context, state) => const AchievementsScreen(),
      ),

      // Stats sub-routes (formerly under /progress)
      GoRoute(
        path: '/stats/milestones',
        builder: (context, state) => const MilestonesScreen(),
      ),
      GoRoute(
        path: '/stats/exercise-history',
        builder: (context, state) => const ExerciseHistoryScreen(),
      ),
      GoRoute(
        path: '/stats/exercise-history/:exerciseName',
        builder: (context, state) {
          final exerciseName = Uri.decodeComponent(state.pathParameters['exerciseName'] ?? '');
          return ExerciseProgressDetailScreen(exerciseName: exerciseName);
        },
      ),
      GoRoute(
        path: '/stats/muscle-analytics',
        builder: (context, state) => const MuscleAnalyticsScreen(),
      ),
      GoRoute(
        path: '/stats/muscle-analytics/:muscleGroup',
        builder: (context, state) {
          final muscleGroup = Uri.decodeComponent(state.pathParameters['muscleGroup'] ?? '');
          return MuscleDetailScreen(muscleGroup: muscleGroup);
        },
      ),

      // Redirects from old /progress/* routes to /stats/*
      GoRoute(
        path: '/progress/milestones',
        redirect: (context, state) => '/stats/milestones',
      ),
      GoRoute(
        path: '/progress/exercise-history',
        redirect: (context, state) => '/stats/exercise-history',
      ),
      GoRoute(
        path: '/progress/exercise-history/:exerciseName',
        redirect: (context, state) {
          final exerciseName = state.pathParameters['exerciseName'] ?? '';
          return '/stats/exercise-history/$exerciseName';
        },
      ),
      GoRoute(
        path: '/progress/muscle-analytics',
        redirect: (context, state) => '/stats/muscle-analytics',
      ),
      GoRoute(
        path: '/progress/muscle-analytics/:muscleGroup',
        redirect: (context, state) {
          final muscleGroup = state.pathParameters['muscleGroup'] ?? '';
          return '/stats/muscle-analytics/$muscleGroup';
        },
      ),

      // Trophy Room - View all trophies with XP/Level progress
      GoRoute(
        path: '/trophy-room',
        builder: (context, state) => const TrophyRoomScreen(),
      ),

      // XP Leaderboard
      GoRoute(
        path: '/xp-leaderboard',
        builder: (context, state) => const XPLeaderboardScreen(),
      ),

      // Rewards - Claim gifts and rewards
      GoRoute(
        path: '/rewards',
        builder: (context, state) => const RewardsScreen(),
      ),

      // Inventory - Consumables and items
      GoRoute(
        path: '/inventory',
        builder: (context, state) => const InventoryScreen(),
      ),

      // XP Goals - Full screen XP goals, daily/weekly/monthly tabs
      GoRoute(
        path: '/xp-goals',
        builder: (context, state) => const XPGoalsScreen(),
      ),

      // Feature Voting (Robinhood-style)
      GoRoute(
        path: '/features',
        builder: (context, state) => const FeatureVotingScreen(),
      ),

      // Coming Soon
      GoRoute(
        path: '/coming-soon',
        builder: (context, state) => const ComingSoonScreen(),
      ),

      // Library (Exercise database, programs) - Full screen outside shell
      // Supports ?tab=0 (Exercises), ?tab=1 (Programs), ?tab=2 (Skills)
      GoRoute(
        path: '/library',
        builder: (context, state) {
          final tabParam = state.uri.queryParameters['tab'];
          final initialTab = tabParam != null ? int.tryParse(tabParam) ?? 0 : 0;
          return LibraryScreen(initialTab: initialTab);
        },
      ),

      // Hydration
      GoRoute(
        path: '/hydration',
        builder: (context, state) => const HydrationScreen(),
      ),

      // Habit Detail - View habit detail with yearly heatmap and stats
      GoRoute(
        path: '/habit/:id',
        pageBuilder: (context, state) {
          final habitId = state.pathParameters['id']!;
          return CustomTransitionPage(
            key: state.pageKey,
            child: HabitDetailScreen(habitId: habitId),
            transitionDuration: const Duration(milliseconds: 400),
            reverseTransitionDuration: const Duration(milliseconds: 300),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.05, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                ),
              );
            },
          );
        },
      ),

      // NEAT Dashboard - Daily Activity & Step Goals
      GoRoute(
        path: '/neat',
        builder: (context, state) => const NeatDashboardScreen(),
      ),

      // Weekly Summaries
      GoRoute(
        path: '/summaries',
        builder: (context, state) => const WeeklySummaryScreen(),
      ),

      // Health Metrics Dashboard
      GoRoute(
        path: '/metrics',
        builder: (context, state) => const MetricsDashboardScreen(),
      ),

      // Schedule (full screen with drag & drop)
      GoRoute(
        path: '/schedule',
        builder: (context, state) => const ScheduleScreen(),
      ),

      // === Settings Routes ===

      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),

      // Settings sub-pages (flat navigation)
      GoRoute(
        path: '/settings/workout-settings',
        builder: (context, state) => const WorkoutSettingsPage(),
      ),
      GoRoute(
        path: '/settings/ai-coach',
        builder: (context, state) => const AiCoachPage(),
      ),
      GoRoute(
        path: '/settings/appearance',
        builder: (context, state) => const AppearancePage(),
      ),
      GoRoute(
        path: '/settings/sound-notifications',
        builder: (context, state) => const SoundNotificationsPage(),
      ),
      GoRoute(
        path: '/settings/equipment',
        builder: (context, state) => const EquipmentPage(),
      ),
      GoRoute(
        path: '/settings/offline-mode',
        builder: (context, state) => const OfflineModePage(),
      ),
      GoRoute(
        path: '/settings/health-devices',
        builder: (context, state) => const HealthDevicesPage(),
      ),
      GoRoute(
        path: '/settings/privacy-data',
        builder: (context, state) => const PrivacyDataPage(),
      ),
      GoRoute(
        path: '/settings/about-support',
        builder: (context, state) => const AboutSupportPage(),
      ),

      // Beast Mode - Power user tools (hidden easter egg)
      GoRoute(
        path: '/settings/beast-mode',
        builder: (context, state) => const BeastModeScreen(),
      ),

      // AI Data Usage (Settings sub-screen)
      GoRoute(
        path: '/settings/ai-data-usage',
        builder: (context, state) => const AIDataUsageScreen(),
      ),

      // Medical Disclaimer (Settings sub-screen)
      GoRoute(
        path: '/settings/medical-disclaimer',
        builder: (context, state) => const MedicalDisclaimerScreen(),
      ),

      // My Exercises - Unified exercise preferences (Favorites, Avoided, Queue)
      GoRoute(
        path: '/settings/my-exercises',
        builder: (context, state) {
          final tabParam = state.uri.queryParameters['tab'];
          final initialTab = tabParam != null ? int.tryParse(tabParam) ?? 0 : 0;
          return MyExercisesScreen(initialTab: initialTab);
        },
      ),

      // Legacy routes redirect to unified screen
      GoRoute(
        path: '/settings/favorite-exercises',
        redirect: (context, state) => '/settings/my-exercises?tab=0',
      ),
      GoRoute(
        path: '/settings/exercise-queue',
        redirect: (context, state) => '/settings/my-exercises?tab=2',
      ),

      // Workout History Import (Settings sub-screen) - stays separate
      GoRoute(
        path: '/settings/workout-history-import',
        builder: (context, state) => const WorkoutHistoryImportScreen(),
      ),

      // Legacy routes redirect to unified screen
      GoRoute(
        path: '/settings/staple-exercises',
        redirect: (context, state) => '/settings/my-exercises?tab=0',
      ),

      // My 1RMs (Settings sub-screen for percentage-based training)
      GoRoute(
        path: '/settings/my-1rms',
        builder: (context, state) => const My1RMsScreen(),
      ),

      // Layout Editor (My Space) - Home screen layout customization
      GoRoute(
        path: '/settings/homescreen',
        builder: (context, state) => const LayoutEditorScreen(),
      ),

      // Legacy routes redirect to unified My Exercises screen
      GoRoute(
        path: '/settings/avoided-exercises',
        redirect: (context, state) => '/settings/my-exercises?tab=1',
      ),
      GoRoute(
        path: '/settings/avoided-muscles',
        redirect: (context, state) => '/settings/my-exercises?tab=1',
      ),

      // Help & Support
      GoRoute(
        path: '/help',
        builder: (context, state) => const HelpScreen(),
      ),

      // Support Tickets - List all user tickets
      GoRoute(
        path: '/support-tickets',
        builder: (context, state) => const SupportTicketsScreen(),
      ),

      // Support Tickets - Create new ticket
      GoRoute(
        path: '/support-tickets/create',
        builder: (context, state) => const CreateTicketScreen(),
      ),

      // Support Tickets - View ticket detail
      GoRoute(
        path: '/support-tickets/:id',
        builder: (context, state) {
          final ticketId = state.pathParameters['id']!;
          return TicketDetailScreen(ticketId: ticketId);
        },
      ),

      // AI Settings
      GoRoute(
        path: '/ai-settings',
        builder: (context, state) => const AISettingsScreen(),
      ),

      // === Utility Routes ===

      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),

      // Body Measurements
      GoRoute(
        path: '/measurements',
        builder: (context, state) => const MeasurementsScreen(),
      ),
      GoRoute(
        path: '/measurements/:type',
        builder: (context, state) {
          final type = state.pathParameters['type'] ?? 'weight';
          return MeasurementDetailScreen(measurementType: type);
        },
      ),

      // Glossary
      GoRoute(
        path: '/glossary',
        builder: (context, state) => const GlossaryScreen(),
      ),

      // Personal Goals (Weekly Challenges)
      GoRoute(
        path: '/personal-goals',
        builder: (context, state) => const PersonalGoalsScreen(),
      ),

      // Workout Gallery (Shareable workout recaps)
      GoRoute(
        path: '/workout-gallery',
        builder: (context, state) => const WorkoutGalleryScreen(),
      ),

      // Scoring Screen (Fitness score breakdown)
      GoRoute(
        path: '/scores',
        builder: (context, state) => const ScoringScreen(),
      ),

      // Custom Exercises (My Exercises - user created)
      GoRoute(
        path: '/custom-exercises',
        builder: (context, state) => const CustomExercisesScreen(),
      ),

      // Widget deep link trigger - shows overlay then pops
      GoRoute(
        path: '/log',
        builder: (context, state) => const WidgetLogTriggerScreen(),
      ),

      // Recipe Suggestions (AI-powered based on body type, culture, diet)
      GoRoute(
        path: '/recipe-suggestions',
        builder: (context, state) => const RecipeSuggestionsScreen(),
      ),

      // Nutrition Settings - Edit nutrition preferences and targets
      GoRoute(
        path: '/nutrition-settings',
        builder: (context, state) => const NutritionSettingsScreen(),
      ),

      // Mood History and Analytics
      GoRoute(
        path: '/mood-history',
        builder: (context, state) => const MoodHistoryScreen(),
      ),

      // Subscription History
      GoRoute(
        path: '/subscription-history',
        builder: (context, state) => const SubscriptionHistoryScreen(),
      ),

      // Request Refund
      GoRoute(
        path: '/request-refund',
        builder: (context, state) => const RequestRefundScreen(),
      ),

      // Subscription Management - Cancel, Pause, Resume
      GoRoute(
        path: '/subscription-management',
        builder: (context, state) => const SubscriptionManagementScreen(),
      ),

      // Settings > Subscription (deep link from renewal reminder banner)
      GoRoute(
        path: '/settings/subscription',
        builder: (context, state) => const SubscriptionManagementScreen(),
      ),

      // Skill Progressions - List of all skill chains
      GoRoute(
        path: '/skills',
        builder: (context, state) => const SkillProgressionsScreen(),
      ),

      // Skill Progression Detail - Individual chain with steps
      GoRoute(
        path: '/skills/:chainId',
        builder: (context, state) {
          final chainId = state.pathParameters['chainId']!;
          return ChainDetailScreen(chainId: chainId);
        },
      ),

      // Cardio Logging - Log cardio sessions (running, cycling, swimming, etc.)
      GoRoute(
        path: '/log-cardio',
        builder: (context, state) {
          // Optional workoutId can be passed as extra data
          final workoutId = state.extra as String?;
          return LogCardioScreen(workoutId: workoutId);
        },
      ),

      // Progress Charts - Visual progress charts (strength over time, volume over time)
      GoRoute(
        path: '/progress-charts',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ProgressChartsScreen(),
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.05, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            );
          },
        ),
      ),

      // Consistency Insights - Streak tracking, patterns, and recovery
      GoRoute(
        path: '/consistency',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ConsistencyScreen(),
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.05, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            );
          },
        ),
      ),

      // Diabetes Dashboard
      GoRoute(
        path: '/diabetes',
        builder: (context, state) => const DiabetesDashboardScreen(),
      ),

      // Injuries
      GoRoute(
        path: '/injuries',
        builder: (context, state) => const InjuriesListScreen(),
      ),
      GoRoute(
        path: '/injuries/report',
        builder: (context, state) => const ReportInjuryScreen(),
      ),
      GoRoute(
        path: '/injuries/:id',
        builder: (context, state) => InjuryDetailScreen(
          injuryId: state.pathParameters['id']!,
        ),
      ),

      // Strain Prevention
      GoRoute(
        path: '/strain-prevention',
        builder: (context, state) => const StrainDashboardScreen(),
      ),
      GoRoute(
        path: '/strain-prevention/volume-history',
        builder: (context, state) => const VolumeHistoryScreen(),
      ),
      GoRoute(
        path: '/strain-prevention/report',
        builder: (context, state) => const ReportStrainScreen(),
      ),

      // Plateau Detection Dashboard
      GoRoute(
        path: '/plateau',
        builder: (context, state) => const PlateauDashboardScreen(),
      ),

      // Senior Fitness Settings - Age-adapted workout settings (for users 60+)
      GoRoute(
        path: '/settings/senior-fitness',
        builder: (context, state) => const SeniorFitnessScreen(),
      ),

      // Progression Pace Settings - Control weight progression speed
      GoRoute(
        path: '/settings/progression-pace',
        builder: (context, state) => const ProgressionPaceScreen(),
      ),

      // Training Focus Settings - Primary goal and muscle focus points
      GoRoute(
        path: '/settings/training-focus',
        builder: (context, state) => const TrainingFocusScreen(),
      ),

      // Exercise Science Research
      GoRoute(
        path: '/settings/research',
        builder: (context, state) => const ExerciseScienceResearchScreen(),
      ),

      // Weekly Plan - Holistic planning with workouts, nutrition, and fasting
      GoRoute(
        path: '/weekly-plan',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const WeeklyPlanScreen(),
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.05, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            );
          },
        ),
      ),

      // Hormonal Health - Dashboard and cycle tracking
      GoRoute(
        path: '/hormonal-health',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const HormonalHealthScreen(),
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.05, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            );
          },
        ),
      ),

      // Hormonal Health Settings - Profile and preferences
      GoRoute(
        path: '/hormonal-health/settings',
        builder: (context, state) => const HormonalHealthSettingsScreen(),
      ),

      // Kegel Session - Guided pelvic floor workout with timer
      GoRoute(
        path: '/kegel-session',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return CustomTransitionPage(
            key: state.pageKey,
            child: KegelSessionScreen(
              exerciseId: extra?['exerciseId'] as String?,
              fromWorkout: extra?['fromWorkout'] as bool? ?? false,
              workoutId: extra?['workoutId'] as String?,
            ),
            transitionDuration: const Duration(milliseconds: 500),
            reverseTransitionDuration: const Duration(milliseconds: 300),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                  ),
                  child: child,
                ),
              );
            },
          );
        },
      ),

      // Habit Tracker - Simple daily habit tracking (water, steps, no sugar, etc.)
      GoRoute(
        path: '/habits',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const HabitsScreen(),
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.05, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            );
          },
        ),
      ),
      // Fitness Wrapped - Monthly recap story viewer
      GoRoute(
        path: '/wrapped/:periodKey',
        pageBuilder: (context, state) {
          final periodKey = state.pathParameters['periodKey']!;
          return CustomTransitionPage(
            key: state.pageKey,
            child: WrappedViewerScreen(periodKey: periodKey),
            transitionDuration: const Duration(milliseconds: 500),
            reverseTransitionDuration: const Duration(milliseconds: 300),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                  ),
                  child: child,
                ),
              );
            },
          );
        },
      ),
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
