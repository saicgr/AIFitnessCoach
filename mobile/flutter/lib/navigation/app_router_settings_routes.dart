part of 'app_router.dart';

/// Settings-related routes extracted from app_router.dart
List<RouteBase> _settingsRoutes() => [
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
        path: '/settings/vacation-mode',
        builder: (context, state) => const VacationModePage(),
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
        path: '/settings/leaderboard-privacy',
        builder: (context, state) => const LeaderboardPrivacyPage(),
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

      // Legacy routes redirect to unified screen.
      // Tab mapping: 0=Favorites, 1=Staples, 2=Avoided, 3=Queue, 4=Custom
      GoRoute(
        path: '/settings/favorite-exercises',
        redirect: (context, state) => '/settings/my-exercises?tab=0',
      ),
      GoRoute(
        path: '/settings/exercise-queue',
        redirect: (context, state) => '/settings/my-exercises?tab=3',
      ),

      // Training Methods (Set Progression reference)
      GoRoute(
        path: '/settings/training-methods',
        builder: (context, state) => const TrainingMethodsScreen(),
      ),

      // Workout History Import (Settings sub-screen) - stays separate
      GoRoute(
        path: '/settings/workout-history-import',
        builder: (context, state) => const WorkoutHistoryImportScreen(),
      ),

      // Workout Export (reverse-direction: Zealova → Hevy/Strong/Fitbod/PDF/GPX).
      // Accepts an optional {'format': '<key>'} via GoRouter `extra` so the
      // chat bot's `export_data` action_data can deep-link with a prefilled
      // format choice. Anything unrecognized falls back to the default (hevy).
      GoRoute(
        path: '/settings/export-workouts',
        builder: (context, state) {
          String? formatHint;
          final extra = state.extra;
          if (extra is Map && extra['format'] is String) {
            formatHint = extra['format'] as String;
          }
          return ExportDataScreen(initialFormatKey: formatHint);
        },
      ),

      // Legacy routes redirect to unified screen
      GoRoute(
        path: '/settings/staple-exercises',
        redirect: (context, state) => '/settings/my-exercises?tab=1',
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
        redirect: (context, state) => '/settings/my-exercises?tab=2',
      ),
      GoRoute(
        path: '/settings/avoided-muscles',
        redirect: (context, state) => '/settings/my-exercises?tab=2',
      ),

      // Help & Support

      // AI Settings
      GoRoute(
        path: '/ai-settings',
        builder: (context, state) => const AISettingsScreen(),
      ),

      // AI Integrations — connected external MCP clients (Claude, ChatGPT, Cursor)
      GoRoute(
        path: '/settings/ai-integrations',
        builder: (context, state) => const AiIntegrationsScreen(),
      ),

];
