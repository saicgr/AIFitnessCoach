import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/models/workout.dart';
import '../data/repositories/auth_repository.dart';
import '../screens/achievements/achievements_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/hydration/hydration_screen.dart';
import '../screens/library/library_screen.dart';
import '../screens/nutrition/nutrition_screen.dart';
import '../screens/onboarding/conversational_onboarding_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/summaries/weekly_summary_screen.dart';
import '../screens/social/social_screen.dart';
import '../screens/metrics/metrics_dashboard_screen.dart';
import '../screens/workout/active_workout_screen.dart';
import '../screens/workout/list_workout_screen.dart';
import '../screens/workout/workout_complete_screen.dart';
import '../screens/workout/workout_detail_screen.dart';
import '../screens/workout/exercise_detail_screen.dart';
import '../screens/schedule/schedule_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../data/models/exercise.dart';
import '../widgets/main_shell.dart';

/// Listenable for auth state changes to trigger router refresh
class _AuthStateNotifier extends ChangeNotifier {
  _AuthStateNotifier(this._ref) {
    _ref.listen<AuthState>(authStateProvider, (_, __) {
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

      final isLoggedIn = authState.status == AuthStatus.authenticated;
      final isOnSplash = state.matchedLocation == '/splash';
      final isLoggingIn = state.matchedLocation == '/login';
      final isOnboarding = state.matchedLocation == '/onboarding';

      // Still loading - stay on splash (or go to splash if starting)
      if (authState.status == AuthStatus.initial ||
          authState.status == AuthStatus.loading) {
        // If we're on splash, stay there
        if (isOnSplash) return null;
        // Otherwise redirect to splash
        return '/splash';
      }

      // Auth is resolved - redirect from splash to appropriate destination
      if (isOnSplash) {
        if (isLoggedIn) {
          final user = authState.user;
          if (user != null && !user.isOnboardingComplete) {
            return '/onboarding';
          }
          return '/home';
        } else {
          return '/login';
        }
      }

      // Not logged in and not on login page -> go to login
      if (!isLoggedIn && !isLoggingIn && !isOnSplash) {
        return '/login';
      }

      // Logged in and on login page -> check onboarding
      if (isLoggedIn && isLoggingIn) {
        final user = authState.user;
        if (user != null && !user.isOnboardingComplete && !isOnboarding) {
          return '/onboarding';
        }
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

      // Login
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Onboarding (AI Conversational)
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const ConversationalOnboardingScreen(),
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
