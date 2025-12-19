import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/models/workout.dart';
import '../data/repositories/auth_repository.dart';
import '../screens/achievements/achievements_screen.dart';
import '../screens/auth/stats_welcome_screen.dart';
import '../screens/auth/sign_in_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/home/senior_home_screen.dart';
import '../screens/hydration/hydration_screen.dart';
import '../screens/library/library_screen.dart';
import '../screens/nutrition/nutrition_screen.dart';
import '../screens/onboarding/conversational_onboarding_screen.dart';
import '../screens/onboarding/pre_auth_quiz_screen.dart';
import '../screens/onboarding/personalized_preview_screen.dart';
import '../screens/onboarding/senior_onboarding_screen.dart';
import '../screens/onboarding/mode_selection_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/summaries/weekly_summary_screen.dart';
import '../screens/social/social_screen.dart';
import '../screens/metrics/metrics_dashboard_screen.dart';
import '../screens/workout/active_workout_screen.dart';
import '../screens/workout/workout_complete_screen.dart';
import '../screens/workout/workout_detail_screen.dart';
import '../screens/workout/exercise_detail_screen.dart';
import '../screens/schedule/schedule_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/ai_settings/ai_settings_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/measurements/measurements_screen.dart';
import '../screens/glossary/glossary_screen.dart';
import '../screens/paywall/paywall_features_screen.dart';
import '../screens/paywall/paywall_timeline_screen.dart';
import '../screens/paywall/paywall_pricing_screen.dart';
import '../data/models/exercise.dart';
import '../widgets/main_shell.dart';
import '../core/providers/language_provider.dart';
import '../core/accessibility/accessibility_provider.dart';

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

      final isLoggedIn = authState.status == AuthStatus.authenticated;
      final isOnSplash = state.matchedLocation == '/splash';
      final isOnboarding = state.matchedLocation == '/onboarding';
      final isOnSeniorOnboarding = state.matchedLocation == '/senior-onboarding';
      final isOnModeSelection = state.matchedLocation == '/mode-selection';
      final isOnStatsWelcome = state.matchedLocation == '/stats-welcome';

      // Helper to get the appropriate home route based on accessibility mode
      String getHomeRoute() {
        if (accessibilitySettings.mode == AccessibilityMode.senior) {
          return '/senior-home';
        }
        return '/home';
      }

      // Still loading auth or language - stay on splash (or go to splash if starting)
      if (authState.status == AuthStatus.initial ||
          authState.status == AuthStatus.loading ||
          languageState.isLoading) {
        // If we're on splash, stay there
        if (isOnSplash) return null;
        // Otherwise redirect to splash
        return '/splash';
      }

      // Check if on new onboarding flow screens
      final isOnPreAuthQuiz = state.matchedLocation == '/pre-auth-quiz';
      final isOnPreview = state.matchedLocation == '/preview';
      final isOnSignIn = state.matchedLocation == '/sign-in';

      // Auth is resolved - redirect from splash to appropriate destination
      if (isOnSplash) {
        if (isLoggedIn) {
          final user = authState.user;
          if (user != null && !user.isOnboardingComplete) {
            // Go to conversational onboarding for logged-in users with incomplete onboarding
            return '/onboarding';
          }
          return getHomeRoute();
        } else {
          // New users go directly to stats welcome screen (entry point for new flow)
          return '/stats-welcome';
        }
      }

      // On stats-welcome - allow it if not logged in, redirect to home if logged in
      if (isOnStatsWelcome) {
        if (isLoggedIn) {
          final user = authState.user;
          if (user != null && !user.isOnboardingComplete) {
            // Go to conversational onboarding for logged-in users with incomplete onboarding
            return '/onboarding';
          }
          return getHomeRoute();
        }
        return null; // Stay on stats welcome
      }

      // Allow pre-auth quiz, preview, and sign-in screens for logged-in users with incomplete onboarding
      if (isOnPreAuthQuiz || isOnPreview || isOnSignIn) {
        if (isLoggedIn) {
          final user = authState.user;
          if (user != null && !user.isOnboardingComplete) {
            // After sign-in, go to conversational onboarding
            return '/onboarding';
          }
          return getHomeRoute();
        }
        return null; // Allow these screens for non-logged-in users
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
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/library',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: LibraryScreen(),
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
        ],
      ),

      // Chat (full screen overlay)
      GoRoute(
        path: '/chat',
        builder: (context, state) => const ChatScreen(),
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
          );
        },
      ),

      // Achievements
      GoRoute(
        path: '/achievements',
        builder: (context, state) => const AchievementsScreen(),
      ),

      // Hydration
      GoRoute(
        path: '/hydration',
        builder: (context, state) => const HydrationScreen(),
      ),

      // Nutrition
      GoRoute(
        path: '/nutrition',
        builder: (context, state) => const NutritionScreen(),
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
