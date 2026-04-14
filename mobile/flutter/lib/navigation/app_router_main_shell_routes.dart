part of 'app_router.dart';

/// Main app shell routes extracted from app_router.dart
List<RouteBase> _mainShellRoutes() => [
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
              // Support deep link: fitwiz://nutrition?tab=2 (0=Daily, 1=Recipes, 2=Patterns, 3=Fuel)
              final tabParam = state.uri.queryParameters['tab'];
              final initialTab = tabParam != null ? int.tryParse(tabParam) ?? 0 : 0;
              // Support deep link: fitwiz://nutrition?camera=true (auto-open camera for meal photo)
              final autoOpenCamera = state.uri.queryParameters['camera'] == 'true';
              // Support deep link: fitwiz://nutrition?barcode=true (auto-open barcode scanner)
              final autoOpenBarcode = state.uri.queryParameters['barcode'] == 'true';
              // 45-min check-in reminder taps land here: fitwiz://nutrition?openCheckin=<food_log_id>
              final openCheckinLogId = state.uri.queryParameters['openCheckin'];
              return NoTransitionPage(
                // Key on query params so GoRouter rebuilds when params change
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


];
