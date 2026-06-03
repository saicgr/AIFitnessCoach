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
                final fuelSectionParam = state.uri.queryParameters['fuelSection'];
                // Water lives inline on the Daily tab now (the Fuel sub-tab
                // was retired), so a hydration deep-link (?fuelSection=water)
                // with no explicit tab lands on Daily (0); the Daily tab then
                // auto-scrolls to the hydration card. The old default (tab=3
                // Fuel) clamped to Patterns and stranded the user there.
                final initialTab = tabParam != null
                    ? int.tryParse(tabParam) ?? 0
                    : 0;
                final autoOpenCamera = state.uri.queryParameters['camera'] == 'true';
                final autoOpenBarcode = state.uri.queryParameters['barcode'] == 'true';
                // AI-coach launcher-chip deep links (chat route gets popped on
                // navigation, so the destination screen must own the sheet).
                final autoOpenMenuScan = state.uri.queryParameters['scanMenu'] == 'true';
                final autoOpenMultiImage = state.uri.queryParameters['multiImage'] == 'true';
                final autoOpenLog = state.uri.queryParameters['openLog'] == 'true';
                final openCheckinLogId = state.uri.queryParameters['openCheckin'];
                // Hydration-reminder deep-link carries ?fuelSection=water so we
                // land on the Water pill inside the Fuel tab, not the default
                // Nutrients view. Only 'water' | 'nutrients' are meaningful.
                final initialFuelSection =
                    (fuelSectionParam == 'water' || fuelSectionParam == 'nutrients')
                        ? fuelSectionParam
                        : null;
                return NoTransitionPage(
                  key: state.pageKey,
                  child: NutritionScreen(
                    initialMeal: initialMeal,
                    initialTab: initialTab,
                    autoOpenCamera: autoOpenCamera,
                    autoOpenBarcode: autoOpenBarcode,
                    autoOpenMenuScan: autoOpenMenuScan,
                    autoOpenMultiImage: autoOpenMultiImage,
                    autoOpenLog: autoOpenLog,
                    openCheckinLogId: openCheckinLogId,
                    initialFuelSection: initialFuelSection,
                  ),
                );
              },
            ),
            // NOTE: `/fasting` lived here as a Nutrition-branch route, which
            // meant the StatefulShellBranch remembered it as the branch's
            // "current" page. After visiting `/fasting`, tapping the
            // Nutrition tab restored Branch 2 to `/fasting` instead of
            // `/nutrition` — the user-reported "I have to tap Nutrition
            // twice" bug. Moved out to a top-level route below (sibling to
            // `/fasting/guide` and `/fasting/body-status`), which means
            // pushing /fasting is a normal navigator push and pop returns to
            // the actual referrer (Home or Nutrition) rather than corrupting
            // the branch state.
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
                // Default to Overview (0). Deep links with ?tab=profile still land on Profile.
                int initialTab = 0;
                if (tabParam == 'profile') {
                  initialTab = 1;
                } else if (tabParam == 'rewards') {
                  initialTab = 2;
                }
                // Push the tab intent through the nonce request so a deep link
                // that arrives while the You branch is ALREADY mounted (kept
                // alive in the shell IndexedStack) still switches tabs —
                // initState alone only handles a cold first build. Done in a
                // post-frame callback so we never mutate a provider mid-build.
                // Restricted to the two tabs the hub actually maps; other
                // legacy `?tab=` values (measurements/stats/…) are vestigial
                // and keep their prior Overview-default behaviour untouched.
                if (tabParam == 'profile' || tabParam == 'rewards') {
                  final container =
                      ProviderScope.containerOf(context, listen: false);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    container
                        .read(youHubTabRequestProvider.notifier)
                        .requestTab(initialTab);
                  });
                }
                return NoTransitionPage(
                  key: state.pageKey,
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
      //
      // Plan §1c.5 additional query params:
      //   ?source=coach_hero|workout_card|pillar_stat
      //   ?insight_id=<uuid>      // seeded coach turn key — dedupe per day
      //   ?mode=<workout-card-mode> // drives the chip set under the turn
      //   ?workout_id=<uuid>      // scopes action_data payloads
      //   ?context=<urlencoded label> (pillar_stat only)
      GoRoute(
        path: '/chat',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final qp = state.uri.queryParameters;
          // Support both extra data and query parameters (deep links)
          final initialMessage = extra?['initialMessage'] as String?
              ?? qp['prompt'];
          return ChatScreen(
            initialMessage: initialMessage,
            source: qp['source'],
            insightId: qp['insight_id'],
            cardMode: qp['mode'],
            workoutId: qp['workout_id'],
            contextLabel: qp['context'],
          );
        },
      ),

      // Chat sessions history — "Ask Coach" conversation list (full screen).
      // NB: must be registered BEFORE '/chat' is NOT required (distinct path),
      // but kept adjacent for discoverability.
      GoRoute(
        path: '/chat/sessions',
        builder: (context, state) => const ChatSessionsScreen(),
      ),

      // Live Chat - Human support
      GoRoute(
        path: '/live-chat',
        builder: (context, state) => const LiveChatScreen(),
      ),

      // Fasting main screen (full screen, no bottom nav). Moved out of the
      // Nutrition StatefulShellBranch so visiting fasting doesn't corrupt
      // that branch's last-route memory — see comment above the Nutrition
      // branch where it used to live.
      GoRoute(
        path: '/fasting',
        builder: (context, state) => const FastingScreenRedesigned(),
      ),
      // Fasting → Body Status stage journey (full screen, no bottom nav).
      GoRoute(
        path: '/fasting/body-status',
        builder: (context, state) => const FastingBodyStatusScreen(),
      ),
      // Fasting → educational Guide (full screen, no bottom nav).
      GoRoute(
        path: '/fasting/guide',
        builder: (context, state) => const FastingGuideScreen(),
      ),

      // ── Per-pillar detail screens (Home redesign §6) ──────────────────
      // /pillar/<train|nourish|move|sleep>. Invalid kinds fall back to
      // a 404-style notice rather than crashing the router.
      GoRoute(
        path: '/pillar/:kind',
        builder: (context, state) {
          final raw = state.pathParameters['kind'];
          final kind = _pillarKindFromPath(raw);
          if (kind == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Not found')),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Unknown pillar "$raw" — valid values are train, nourish, move, sleep.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }
          return PillarDetailScreen(kind: kind);
        },
      ),

      // Full-screen interactive chart. Accepts:
      //   :id              — chart identity (echoed in Ask-Coach context)
      //   ?pillar=         — train | nourish | move | sleep (required)
      //   ?days=           — initial range in days (default 30)
      //   ?title=          — display title (URL-encoded)
      GoRoute(
        path: '/chart/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? 'chart';
          final pillarRaw = state.uri.queryParameters['pillar'];
          final kind = _pillarKindFromPath(pillarRaw);
          final title = state.uri.queryParameters['title'] ?? 'Chart';
          if (kind == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Not found')),
              body: const Center(child: Text('Missing or invalid ?pillar=…')),
            );
          }
          return Consumer(
            builder: (context, ref, _) => FullScreenChartScreen(
              chartId: id,
              title: title,
              pillarKind: kind,
              loadData: (days) async => await ref.read(pillarHistoryProvider(
                PillarHistoryKey(kind: kind, days: days),
              ).future),
            ),
          );
        },
      ),
];

/// Maps a `/pillar/:kind` path segment to the typed enum. Returns null when
/// the segment is missing or doesn't match a known pillar — the route then
/// renders a 404-style fallback instead of crashing.
PillarKind? _pillarKindFromPath(String? raw) {
  switch (raw) {
    case 'train':
      return PillarKind.train;
    case 'nourish':
      return PillarKind.nourish;
    case 'move':
      return PillarKind.move;
    case 'sleep':
      return PillarKind.sleep;
    default:
      return null;
  }
}
