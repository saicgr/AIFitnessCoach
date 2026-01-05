import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/models/workout.dart';
import '../data/models/user.dart' as app_user;
import '../data/repositories/auth_repository.dart';
import '../screens/achievements/achievements_screen.dart';
import '../screens/auth/stats_welcome_screen.dart';
import '../screens/auth/sign_in_screen.dart';
import '../screens/auth/pricing_preview_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/features/feature_voting_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/home/senior_home_screen.dart';
import '../screens/hydration/hydration_screen.dart';
import '../screens/library/library_screen.dart';
import '../screens/nutrition/nutrition_screen.dart';
import '../screens/fasting/fasting_screen.dart';
import '../screens/stats/comprehensive_stats_screen.dart';
import '../screens/onboarding/conversational_onboarding_screen.dart';
import '../screens/onboarding/pre_auth_quiz_screen.dart';
import '../screens/onboarding/personalized_preview_screen.dart';
import '../screens/onboarding/weight_projection_screen.dart';
import '../screens/onboarding/senior_onboarding_screen.dart';
import '../screens/onboarding/mode_selection_screen.dart';
import '../screens/onboarding/coach_selection_screen.dart';
import '../screens/onboarding/workout_generation_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/summaries/weekly_summary_screen.dart';
import '../screens/social/social_screen.dart';
import '../screens/workouts/workouts_screen.dart';
import '../screens/metrics/metrics_dashboard_screen.dart';
import '../screens/workout/active_workout_screen_refactored.dart';
import '../screens/workout/workout_complete_screen.dart';
import '../screens/workout/workout_detail_screen.dart';
import '../screens/workout/exercise_detail_screen.dart';
import '../screens/workout/custom_workout_builder_screen.dart';
import '../screens/schedule/schedule_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/help_screen.dart';
import '../screens/settings/exercise_preferences/favorite_exercises_screen.dart';
import '../screens/settings/exercise_preferences/exercise_queue_screen.dart';
import '../screens/settings/exercise_preferences/staple_exercises_screen.dart';
import '../screens/settings/workout_history_import_screen.dart';
import '../screens/settings/training/my_1rms_screen.dart';
import '../screens/settings/training/strength_baselines_screen.dart';
import '../screens/settings/layout_editor_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/ai_settings/ai_settings_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/measurements/measurements_screen.dart';
import '../screens/glossary/glossary_screen.dart';
import '../screens/personal_goals/personal_goals_screen.dart';
import '../screens/paywall/paywall_features_screen.dart';
import '../screens/paywall/paywall_timeline_screen.dart';
import '../screens/paywall/paywall_pricing_screen.dart';
import '../screens/profile/workout_gallery_screen.dart';
import '../screens/progress/progress_screen.dart';
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
import '../screens/settings/exercise_preferences/avoided_exercises_screen.dart';
import '../screens/settings/exercise_preferences/avoided_muscles_screen.dart';
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
import '../screens/tour/app_tour_screen.dart';
import '../screens/guest/guest_home_screen.dart';
import '../screens/guest/guest_library_screen.dart';
import '../screens/programs/program_selection_screen.dart';
import '../screens/cardio/log_cardio_screen.dart';
import '../screens/neat/neat_dashboard_screen.dart';
import '../screens/live_chat/live_chat_screen.dart';
import '../screens/admin_support/admin_support_list_screen.dart';
import '../screens/admin_support/admin_chat_screen.dart';
import '../screens/calibration/calibration_intro_screen.dart';
import '../screens/calibration/calibration_workout_screen.dart';
import '../screens/calibration/calibration_results_screen.dart';
import '../data/providers/guest_mode_provider.dart';
import '../screens/injuries/injuries_list_screen.dart';
import '../screens/injuries/report_injury_screen.dart';
import '../screens/injuries/injury_detail_screen.dart';
import '../screens/strain_prevention/strain_dashboard_screen.dart';
import '../screens/strain_prevention/volume_history_screen.dart';
import '../screens/strain_prevention/report_strain_screen.dart';
import '../screens/settings/senior_fitness_screen.dart';
import '../screens/settings/progression_pace_screen.dart';
import '../screens/weekly_plan/weekly_plan_screen.dart';
import '../screens/hormonal_health/hormonal_health_screen.dart';
import '../screens/hormonal_health/hormonal_health_settings_screen.dart';
import '../screens/kegel/kegel_session_screen.dart';
import '../screens/habits/habit_tracker_screen.dart';

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

/// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthStateNotifier(ref);

  final router = GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      // Read auth state fresh each time redirect is called
      final authState = ref.read(authStateProvider);
      final languageState = ref.read(languageProvider);
      final accessibilitySettings = ref.read(accessibilityProvider);

      // Handle widget deep links (fitwiz://) that come through as path only
      // The full URI gets parsed and only the path portion reaches go_router
      final fullUri = state.uri;
      debugPrint('Router redirect - uri: $fullUri, matchedLocation: ${state.matchedLocation}');

      // Handle other widget deep links that need simple redirects
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

      final isLoggedIn = authState.status == AuthStatus.authenticated;
      final isOnSplash = state.matchedLocation == '/splash';
      final isOnboarding = state.matchedLocation == '/onboarding';
      final isOnSeniorOnboarding = state.matchedLocation == '/senior-onboarding';
      final isOnModeSelection = state.matchedLocation == '/mode-selection';
      final isOnStatsWelcome = state.matchedLocation == '/stats-welcome';

      // Check if on new onboarding flow screens (declare early for use in loading/error checks)
      final isOnPreAuthQuiz = state.matchedLocation == '/pre-auth-quiz';
      final isOnWeightProjection = state.matchedLocation == '/weight-projection';
      final isOnPreview = state.matchedLocation == '/preview';
      final isOnSignIn = state.matchedLocation == '/sign-in';
      final isOnPricingPreview = state.matchedLocation == '/pricing-preview';
      final isOnCoachSelection = state.matchedLocation == '/coach-selection';
      final isOnPaywallFeatures = state.matchedLocation == '/paywall-features';
      final isOnPaywallTimeline = state.matchedLocation == '/paywall-timeline';
      final isOnPaywallPricing = state.matchedLocation == '/paywall-pricing';
      final isOnPaywall = isOnPaywallFeatures || isOnPaywallTimeline || isOnPaywallPricing;
      final isOnDemoWorkout = state.matchedLocation == '/demo-workout';
      final isOnPlanPreview = state.matchedLocation == '/plan-preview';
      final isOnGuestHome = state.matchedLocation == '/guest-home';
      final isOnGuestLibrary = state.matchedLocation == '/guest-library';
      final isGuestRoute = isOnGuestHome || isOnGuestLibrary;

      // Helper to get the appropriate home route based on accessibility mode
      String getHomeRoute() {
        if (accessibilitySettings.mode == AccessibilityMode.senior) {
          return '/senior-home';
        }
        return '/home';
      }

      // Still loading auth or language - stay on splash (or go to splash if starting)
      // But allow pre-auth screens to stay as-is during loading (don't interrupt sign-in flow)
      if (authState.status == AuthStatus.initial ||
          authState.status == AuthStatus.loading ||
          languageState.isLoading) {
        // If we're on splash, stay there
        if (isOnSplash) return null;
        // Allow pre-auth screens to stay during loading (sign-in process shouldn't redirect)
        if (isOnPreAuthQuiz || isOnWeightProjection || isOnPreview || isOnSignIn || isOnPricingPreview ||
            isOnDemoWorkout || isOnPlanPreview || isGuestRoute || isOnStatsWelcome) {
          return null;
        }
        // Otherwise redirect to splash
        return '/splash';
      }

      // Handle error state - allow sign-in screen to show errors
      if (authState.status == AuthStatus.error) {
        // If on sign-in page, stay there to show the error
        if (isOnSignIn) return null;
        // If on other pre-auth pages, stay there
        if (isOnPreAuthQuiz || isOnWeightProjection || isOnPreview || isOnPricingPreview ||
            isOnDemoWorkout || isOnPlanPreview || isGuestRoute || isOnStatsWelcome) {
          return null;
        }
      }

      // Check if user is in guest mode
      final isGuestMode = ref.read(guestModeProvider).isGuestMode;

      // Helper to get the next step in onboarding flow for logged-in users
      // NOTE: Conversational onboarding is now SKIPPED - pre-auth quiz collects all data
      String? getNextOnboardingStep(app_user.User user) {
        // Step 1: Coach selection
        if (!user.isCoachSelected) {
          return '/coach-selection';
        }
        // Step 2: Conversational onboarding is SKIPPED
        // Coach selection now marks onboarding complete and goes directly to paywall/home
        // if (!user.isOnboardingComplete) {
        //   return '/onboarding';
        // }
        // Step 3: Paywall (after coach selection)
        if (!user.isPaywallComplete) {
          return '/paywall-features';
        }
        // All steps complete - go home
        return null;
      }

      // Auth is resolved - redirect from splash to appropriate destination
      if (isOnSplash) {
        if (isLoggedIn) {
          final user = authState.user;
          if (user != null) {
            final nextStep = getNextOnboardingStep(user);
            if (nextStep != null) return nextStep;
          }
          return getHomeRoute();
        } else {
          // New users go directly to stats welcome screen (entry point for new flow)
          return '/stats-welcome';
        }
      }

      // On stats-welcome - allow it if not logged in, redirect appropriately if logged in
      if (isOnStatsWelcome) {
        if (isLoggedIn) {
          final user = authState.user;
          if (user != null) {
            final nextStep = getNextOnboardingStep(user);
            if (nextStep != null) return nextStep;
          }
          return getHomeRoute();
        }
        return null; // Stay on stats welcome
      }

      // Allow demo workout and plan preview screens for anyone (no auth required)
      // This lets users preview workouts and their personalized plan before signing up
      // Addressing user complaint: "After giving all personal info, it requires subscription to see the personal plan"
      if (isOnDemoWorkout || isOnPlanPreview) {
        return null; // Allow demo/preview screens for all users
      }

      // Guest Mode disabled - Coming Soon based on user feedback
      // Guest routes now redirect to sign-up flow instead
      if (isGuestRoute) {
        // Guest mode disabled - redirect all guest routes to sign-up
        // if (isGuestMode) {
        //   return null; // Allow - user is in guest mode
        // }
        // Not in guest mode, redirect to appropriate location
        if (isLoggedIn) {
          return getHomeRoute();
        }
        return '/stats-welcome';
      }

      // Guest Mode disabled - Coming Soon based on user feedback
      // Guests now must sign up to access the app (email required)
      // Keeping code commented for easy re-enable when ready
      //
      // if (isGuestMode && !isLoggedIn) {
      //   // Allow main app routes for guests
      //   final mainAppRoutes = ['/home', '/chat', '/nutrition', '/progress', '/library', '/settings'];
      //   final isMainAppRoute = mainAppRoutes.any((route) => state.matchedLocation.startsWith(route));
      //
      //   if (isMainAppRoute || isGuestRoute || isOnDemoWorkout || isOnPlanPreview ||
      //       isOnPreAuthQuiz || isOnPreview || isOnSignIn || isOnPricingPreview) {
      //     return null; // Allow - guests can access full app UI
      //   }
      //
      //   // For other routes, redirect to home (main app shell)
      //   if (!isOnSplash && !isOnStatsWelcome) {
      //     return '/home';
      //   }
      // }

      // Allow pre-auth quiz, weight projection, preview, sign-in, and pricing preview screens for non-logged-in users
      // Also allow pre-auth quiz for logged-in users who are starting over (no coach selected)
      if (isOnPreAuthQuiz || isOnWeightProjection || isOnPreview || isOnSignIn || isOnPricingPreview) {
        if (isLoggedIn) {
          final user = authState.user;
          // Allow pre-auth quiz if user is starting over (coach not selected)
          if (isOnPreAuthQuiz && user != null && !user.isCoachSelected) {
            return null; // Allow - user is starting over
          }
          // Allow pricing preview for logged-in users too (they might want to see pricing)
          if (isOnPricingPreview) {
            return null; // Allow - user wants to see pricing
          }
          if (user != null) {
            final nextStep = getNextOnboardingStep(user);
            if (nextStep != null) return nextStep;
          }
          return getHomeRoute();
        }
        return null; // Allow these screens for non-logged-in users
      }

      // Coach selection screen - allow if user hasn't selected coach yet
      if (isOnCoachSelection) {
        if (isLoggedIn) {
          final user = authState.user;
          if (user != null && !user.isCoachSelected) {
            return null; // Allow - user is selecting coach
          }
          // Coach already selected, go to next step
          // NOTE: Conversational onboarding is SKIPPED - go directly to paywall
          if (user != null) {
            // if (!user.isOnboardingComplete) return '/onboarding';
            if (!user.isPaywallComplete) return '/paywall-features';
          }
          return getHomeRoute();
        }
        return '/stats-welcome'; // Not logged in, go to start
      }

      // Paywall screens - allow if user hasn't completed paywall yet
      if (isOnPaywall) {
        if (isLoggedIn) {
          final user = authState.user;
          if (user != null && !user.isPaywallComplete) {
            return null; // Allow - user is going through paywall
          }
          return getHomeRoute();
        }
        return '/stats-welcome'; // Not logged in, go to start
      }

      // Allow onboarding-related routes
      if (isOnboarding || isOnSeniorOnboarding || isOnModeSelection) {
        return null; // Allow these routes
      }

      // Not logged in and not on stats-welcome -> redirect to stats-welcome
      if (!isLoggedIn && !isOnSplash && !isOnStatsWelcome) {
        return '/stats-welcome';
      }

      // Redirect /home to /senior-home if in senior mode
      if (state.matchedLocation == '/home' && accessibilitySettings.mode == AccessibilityMode.senior) {
        return '/senior-home';
      }

      // Redirect /senior-home to /home if not in senior mode
      if (state.matchedLocation == '/senior-home' && accessibilitySettings.mode != AccessibilityMode.senior) {
        return '/home';
      }

      return null;
    },
    routes: [
      // Splash - shown while auth is loading
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Stats welcome - entry point with "Get Started" button
      GoRoute(
        path: '/stats-welcome',
        builder: (context, state) => const StatsWelcomeScreen(),
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

      // App Tour - Interactive walkthrough of app features for new users
      // Can be restarted from Settings > App Tour & Demo
      GoRoute(
        path: '/app-tour',
        pageBuilder: (context, state) {
          // Source can be passed as extra data (new_user, settings, deep_link)
          final extra = state.extra as Map<String, dynamic>?;
          final source = extra?['source'] as String? ?? 'new_user';
          return CustomTransitionPage(
            key: state.pageKey,
            child: AppTourScreen(source: source),
            transitionDuration: const Duration(milliseconds: 500),
            reverseTransitionDuration: const Duration(milliseconds: 300),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.1),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                  ),
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

      // Guest Home - limited preview for non-authenticated users
      GoRoute(
        path: '/guest-home',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const GuestHomeScreen(),
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

      // Guest Library - limited exercise library for non-authenticated users
      GoRoute(
        path: '/guest-library',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const GuestLibraryScreen(),
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

      // Weight Projection - shows goal timeline before preview
      GoRoute(
        path: '/weight-projection',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const WeightProjectionScreen(),
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.1, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                child: child,
              ),
            );
          },
        ),
      ),

      // Personalized Preview - shows value before sign-in
      GoRoute(
        path: '/preview',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PersonalizedPreviewScreen(),
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

      // Sign-In Screen - after quiz and preview
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

      // Coach Selection - pick your AI coach personality before onboarding
      GoRoute(
        path: '/coach-selection',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CoachSelectionScreen(),
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

      // Onboarding (AI Conversational) - with playful entrance animation
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ConversationalOnboardingScreen(),
          transitionDuration: const Duration(milliseconds: 600),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Playful scale + fade + slide up animation
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            );

            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.15),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
                  ),
                ),
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.92, end: 1.0).animate(curvedAnimation),
                  child: child,
                ),
              ),
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

      // Senior Home (has its own SeniorScaffold with 3-tab nav)
      GoRoute(
        path: '/senior-home',
        builder: (context, state) => const SeniorHomeScreen(),
      ),

      // Main app shell with bottom nav
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
            pageBuilder: (context, state) => const NoTransitionPage(
              child: NutritionScreen(),
            ),
          ),
          GoRoute(
            path: '/fasting',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: FastingScreen(),
            ),
          ),
          GoRoute(
            path: '/stats',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ComprehensiveStatsScreen(),
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
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
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
          GoRoute(
            path: '/progress',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProgressScreen(),
            ),
          ),
        ],
      ),

      // Chat (full screen overlay)
      GoRoute(
        path: '/chat',
        builder: (context, state) => const ChatScreen(),
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

      // Workout detail
      GoRoute(
        path: '/workout/:id',
        builder: (context, state) {
          final workoutId = state.pathParameters['id']!;
          return WorkoutDetailScreen(workoutId: workoutId);
        },
      ),

      // Exercise detail (full screen with autoplay video)
      GoRoute(
        path: '/exercise-detail',
        builder: (context, state) {
          final exercise = state.extra as WorkoutExercise?;
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
          final workout = state.extra as Workout?;
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
          // Use video-based workout screen with set tracking overlay
          return ActiveWorkoutScreen(workout: workout);
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

      // Progress Milestones & ROI
      GoRoute(
        path: '/progress/milestones',
        builder: (context, state) => const MilestonesScreen(),
      ),

      // Exercise History - Per-exercise workout history
      GoRoute(
        path: '/progress/exercise-history',
        builder: (context, state) => const ExerciseHistoryScreen(),
      ),

      // Exercise Detail - Specific exercise progression
      GoRoute(
        path: '/progress/exercise-history/:exerciseName',
        builder: (context, state) {
          final exerciseName = Uri.decodeComponent(state.pathParameters['exerciseName'] ?? '');
          return ExerciseProgressDetailScreen(exerciseName: exerciseName);
        },
      ),

      // Muscle Analytics Dashboard - Heatmap, frequency, balance
      GoRoute(
        path: '/progress/muscle-analytics',
        builder: (context, state) => const MuscleAnalyticsScreen(),
      ),

      // Muscle Detail - Specific muscle group analytics
      GoRoute(
        path: '/progress/muscle-analytics/:muscleGroup',
        builder: (context, state) {
          final muscleGroup = Uri.decodeComponent(state.pathParameters['muscleGroup'] ?? '');
          return MuscleDetailScreen(muscleGroup: muscleGroup);
        },
      ),

      // Feature Voting (Robinhood-style)
      GoRoute(
        path: '/features',
        builder: (context, state) => const FeatureVotingScreen(),
      ),

      // Library (Exercise database, programs) - Full screen outside shell
      GoRoute(
        path: '/library',
        builder: (context, state) => const LibraryScreen(),
      ),

      // Branded Programs Selection Screen
      GoRoute(
        path: '/programs',
        builder: (context, state) => const ProgramSelectionScreen(),
      ),

      // Hydration
      GoRoute(
        path: '/hydration',
        builder: (context, state) => const HydrationScreen(),
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

      // Settings
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),

      // Favorite Exercises (Settings sub-screen)
      GoRoute(
        path: '/settings/favorite-exercises',
        builder: (context, state) => const FavoriteExercisesScreen(),
      ),

      // Exercise Queue (Settings sub-screen)
      GoRoute(
        path: '/settings/exercise-queue',
        builder: (context, state) => const ExerciseQueueScreen(),
      ),

      // Workout History Import (Settings sub-screen)
      GoRoute(
        path: '/settings/workout-history-import',
        builder: (context, state) => const WorkoutHistoryImportScreen(),
      ),

      // Staple Exercises (Settings sub-screen)
      GoRoute(
        path: '/settings/staple-exercises',
        builder: (context, state) => const StapleExercisesScreen(),
      ),

      // My 1RMs (Settings sub-screen for percentage-based training)
      GoRoute(
        path: '/settings/my-1rms',
        builder: (context, state) => const My1RMsScreen(),
      ),

      // Strength Baselines (from calibration)
      GoRoute(
        path: '/settings/training/baselines',
        builder: (context, state) => const StrengthBaselinesScreen(),
      ),

      // Layout Editor (My Space) - Home screen layout customization
      GoRoute(
        path: '/settings/homescreen',
        builder: (context, state) => const LayoutEditorScreen(),
      ),

      // Avoided Exercises (Settings sub-screen)
      GoRoute(
        path: '/settings/avoided-exercises',
        builder: (context, state) => const AvoidedExercisesScreen(),
      ),

      // Avoided Muscles (Settings sub-screen)
      GoRoute(
        path: '/settings/avoided-muscles',
        builder: (context, state) => const AvoidedMusclesScreen(),
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

      // Notifications
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),

      // Body Measurements
      GoRoute(
        path: '/measurements',
        builder: (context, state) => const MeasurementsScreen(),
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

      // Calibration Intro - Introduction screen before calibration workout
      GoRoute(
        path: '/calibration/intro',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final fromOnboarding = extra?['fromOnboarding'] as bool? ?? false;
          return CustomTransitionPage(
            key: state.pageKey,
            child: CalibrationIntroScreen(fromOnboarding: fromOnboarding),
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

      // Calibration Workout - The actual calibration exercises
      GoRoute(
        path: '/calibration/workout',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final fromOnboarding = extra?['fromOnboarding'] as bool? ?? false;
          return CustomTransitionPage(
            key: state.pageKey,
            child: CalibrationWorkoutScreen(fromOnboarding: fromOnboarding),
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

      // Calibration Results - Shows calibration results and suggested adjustments
      GoRoute(
        path: '/calibration/results',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          if (extra == null) {
            // Fallback if no data
            return const NoTransitionPage(
              child: Scaffold(
                body: Center(child: Text('No calibration data')),
              ),
            );
          }
          return CustomTransitionPage(
            key: state.pageKey,
            child: CalibrationResultsScreen(
              fromOnboarding: extra['fromOnboarding'] as bool? ?? false,
              calibrationId: extra['calibrationId'] as String,
              exercises: extra['exercises'] as List<CalibrationExercise>,
              result: extra['result'] as Map<String, dynamic>,
              durationSeconds: extra['durationSeconds'] as int,
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

      // Injuries List - View and manage all injuries
      GoRoute(
        path: '/injuries',
        builder: (context, state) => const InjuriesListScreen(),
      ),

      // Report Injury - Report a new injury
      GoRoute(
        path: '/injuries/report',
        builder: (context, state) => const ReportInjuryScreen(),
      ),

      // Injury Detail - View details of a specific injury
      GoRoute(
        path: '/injuries/:id',
        builder: (context, state) {
          final injuryId = state.pathParameters['id']!;
          return InjuryDetailScreen(injuryId: injuryId);
        },
      ),

      // Strain Prevention Dashboard - Volume tracking and strain prevention
      GoRoute(
        path: '/strain-prevention',
        builder: (context, state) => const StrainDashboardScreen(),
      ),

      // Volume History - Historical volume data
      GoRoute(
        path: '/strain-prevention/history',
        builder: (context, state) => const VolumeHistoryScreen(),
      ),

      // Report Strain - Report muscle strain or fatigue
      GoRoute(
        path: '/strain-prevention/report',
        builder: (context, state) => const ReportStrainScreen(),
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
          child: const HabitTrackerScreen(),
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
