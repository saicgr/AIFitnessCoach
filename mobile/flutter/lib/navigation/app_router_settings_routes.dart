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

      // AI Settings
      GoRoute(
        path: '/ai-settings',
        builder: (context, state) => const AISettingsScreen(),
      ),

];
