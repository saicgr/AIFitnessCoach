part of 'app_router.dart';

/// Main app shell routes extracted from app_router.dart
List<RouteBase> _mainShellRoutes() => [
  // === Main App Shell ===

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          // Branch 0: Home
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home',
              pageBuilder: (context, state) {
                final startEditMode = state.uri.queryParameters['edit'] == 'true';
                return NoTransitionPage(
                  child: HomeScreen(startEditMode: startEditMode),
                );
              },
            ),
          ]),
          // Branch 1: Workouts
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/workouts',
              pageBuilder: (context, state) {
                final scrollTo = state.uri.queryParameters['scrollTo'];
                return NoTransitionPage(
                  child: WorkoutsScreen(scrollTo: scrollTo),
                );
              },
            ),
          ]),
          // Branch 2: Nutrition (includes Fasting as a secondary page)
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/nutrition',
              pageBuilder: (context, state) {
                final initialMeal = state.uri.queryParameters['meal'];
                final tabParam = state.uri.queryParameters['tab'];
                final initialTab = tabParam != null ? int.tryParse(tabParam) ?? 0 : 0;
                final autoOpenCamera = state.uri.queryParameters['camera'] == 'true';
                final autoOpenBarcode = state.uri.queryParameters['barcode'] == 'true';
                final openCheckinLogId = state.uri.queryParameters['openCheckin'];
                return NoTransitionPage(
                  key: state.pageKey,
                  child: NutritionScreen(
                    initialMeal: initialMeal,
                    initialTab: initialTab,
                    autoOpenCamera: autoOpenCamera,
                    autoOpenBarcode: autoOpenBarcode,
                    openCheckinLogId: openCheckinLogId,
                  ),
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
          ]),
          // Branch 3: Discover (W2) — percentile leaderboard + Rising Stars
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/discover',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: DiscoverScreen(),
              ),
            ),
          ]),
          // Branch 4: Profile
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/profile',
              pageBuilder: (context, state) {
                final scrollTo = state.uri.queryParameters['scrollTo'];
                return NoTransitionPage(
                  child: ProfileScreen(scrollTo: scrollTo),
                );
              },
            ),
          ]),
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


];
