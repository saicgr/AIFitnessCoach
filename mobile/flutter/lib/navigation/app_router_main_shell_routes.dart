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
                // Hydration-reminder deep-link carries ?fuelSection=water so we
                // land on the Water pill inside the Fuel tab, not the default
                // Nutrients view. Only 'water' | 'nutrients' are meaningful.
                final rawFuelSection = state.uri.queryParameters['fuelSection'];
                final initialFuelSection =
                    (rawFuelSection == 'water' || rawFuelSection == 'nutrients')
                        ? rawFuelSection
                        : null;
                return NoTransitionPage(
                  key: state.pageKey,
                  child: NutritionScreen(
                    initialMeal: initialMeal,
                    initialTab: initialTab,
                    autoOpenCamera: autoOpenCamera,
                    autoOpenBarcode: autoOpenBarcode,
                    openCheckinLogId: openCheckinLogId,
                    initialFuelSection: initialFuelSection,
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
          // Branch 4: You (formerly Profile) — hub screen wrapping the
          // existing ProfileScreen as one of three top-tabs plus an
          // Overview aggregation and a Stats & Rewards deep-link grid.
          // Old `/profile` URL still works to preserve deep links — they
          // land on the Profile tab inside the You hub.
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/profile',
              pageBuilder: (context, state) {
                final scrollTo = state.uri.queryParameters['scrollTo'];
                final tabParam = state.uri.queryParameters['tab'];
                // Route query ?tab=overview|profile|rewards to the right tab.
                int initialTab = 1; // default to Profile when arriving via /profile
                if (tabParam == 'overview') {
                  initialTab = 0;
                } else if (tabParam == 'rewards') {
                  initialTab = 2;
                }
                return NoTransitionPage(
                  child: YouHubScreen(
                    initialTabIndex: initialTab,
                    profileScrollTo: scrollTo,
                  ),
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
      // Synced workouts history (full screen, no bottom nav)
      GoRoute(
        path: '/profile/synced-workouts',
        builder: (context, state) => const SyncedWorkoutsHistoryScreen(),
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
