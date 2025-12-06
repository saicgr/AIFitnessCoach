import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/models/workout.dart';
import '../data/repositories/auth_repository.dart';
import '../screens/auth/login_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/library/library_screen.dart';
import '../screens/onboarding/conversational_onboarding_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/workout/active_workout_screen.dart';
import '../screens/workout/workout_complete_screen.dart';
import '../screens/workout/workout_detail_screen.dart';
import '../widgets/main_shell.dart';

/// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggedIn = authState.status == AuthStatus.authenticated;
      final isLoggingIn = state.matchedLocation == '/login';
      final isOnboarding = state.matchedLocation == '/onboarding';

      // Still loading - don't redirect
      if (authState.status == AuthStatus.initial ||
          authState.status == AuthStatus.loading) {
        return null;
      }

      // Not logged in and not on login page -> go to login
      if (!isLoggedIn && !isLoggingIn) {
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
            path: '/metrics',
            pageBuilder: (context, state) => NoTransitionPage(
              child: Scaffold(
                backgroundColor: const Color(0xFF000000),
                body: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Metrics',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Track your progress',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey,
                              ),
                        ),
                        const Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.bar_chart,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Coming Soon',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Detailed stats and progress charts',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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
          );
        },
      ),

      // Achievements
      GoRoute(
        path: '/achievements',
        builder: (context, state) => Scaffold(
          backgroundColor: const Color(0xFF000000),
          appBar: AppBar(
            backgroundColor: const Color(0xFF000000),
            title: const Text('Achievements'),
          ),
          body: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.emoji_events,
                  size: 64,
                  color: Colors.amber,
                ),
                SizedBox(height: 16),
                Text(
                  'Coming Soon',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Badges and achievements',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
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
});
