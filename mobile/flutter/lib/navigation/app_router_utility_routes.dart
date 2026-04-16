part of 'app_router.dart';

/// Utility routes extracted from app_router.dart
List<RouteBase> _utilityRoutes() => [
  // === Utility Routes ===

      // Public shared recipe deep link: fitwiz.app/r/{slug} → PublicRecipeScreen.
      // Auth not required; user is prompted to sign in on "Save to my recipes" tap.
      GoRoute(
        path: '/r/:slug',
        builder: (context, state) {
          final slug = state.pathParameters['slug'] ?? '';
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return PublicRecipeScreen(slug: slug, isDark: isDark);
        },
      ),

      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),

      // Body Measurements
      GoRoute(
        path: '/measurements',
        builder: (context, state) => const MeasurementsScreen(),
      ),
      GoRoute(
        path: '/measurements/derived/:type',
        builder: (context, state) {
          final type = state.pathParameters['type'] ?? 'bmi';
          return DerivedMetricDetailScreen(derivedType: type);
        },
      ),
      GoRoute(
        path: '/measurements/:type',
        builder: (context, state) {
          final type = state.pathParameters['type'] ?? 'weight';
          return MeasurementDetailScreen(measurementType: type);
        },
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

      // Nutrition Settings - Edit nutrition preferences and targets
      GoRoute(
        path: '/nutrition-settings',
        builder: (context, state) => const NutritionSettingsScreen(),
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

      // Settings > Subscription (deep link from renewal reminder banner)
      GoRoute(
        path: '/settings/subscription',
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
          final chainId = state.pathParameters['chainId'] ?? '';
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

      // Diabetes Dashboard
      GoRoute(
        path: '/diabetes',
        builder: (context, state) => const DiabetesDashboardScreen(),
      ),

      // Injuries
      GoRoute(
        path: '/injuries',
        builder: (context, state) => const InjuriesListScreen(),
      ),
      GoRoute(
        path: '/injuries/report',
        builder: (context, state) => const ReportInjuryScreen(),
      ),
      GoRoute(
        path: '/injuries/:id',
        builder: (context, state) => InjuryDetailScreen(
          injuryId: state.pathParameters['id'] ?? '',
        ),
      ),

      // Strain Prevention
      GoRoute(
        path: '/strain-prevention',
        builder: (context, state) => const StrainDashboardScreen(),
      ),
      GoRoute(
        path: '/strain-prevention/volume-history',
        builder: (context, state) => const VolumeHistoryScreen(),
      ),
      GoRoute(
        path: '/strain-prevention/report',
        builder: (context, state) => const ReportStrainScreen(),
      ),

      // Plateau Detection Dashboard
      GoRoute(
        path: '/plateau',
        builder: (context, state) => const PlateauDashboardScreen(),
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

      // Training Focus Settings - Primary goal and muscle focus points
      GoRoute(
        path: '/settings/training-focus',
        builder: (context, state) => const TrainingFocusScreen(),
      ),

      // Exercise Science Research
      GoRoute(
        path: '/settings/research',
        builder: (context, state) => const ExerciseScienceResearchScreen(),
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
          child: HabitsScreen(
            autoOpenAddSheet: state.uri.queryParameters['addHabit'] == 'true',
          ),
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
      // My Wrapped - All wraps, personalities, current month progress
      GoRoute(
        path: '/my-wrapped',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const MyWrappedScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                child: child,
              );
            },
          );
        },
      ),
      // Fitness Wrapped - Monthly recap story viewer
      GoRoute(
        path: '/wrapped/:periodKey',
        pageBuilder: (context, state) {
          final periodKey = state.pathParameters['periodKey'] ?? '';
          return CustomTransitionPage(
            key: state.pageKey,
            child: WrappedViewerScreen(periodKey: periodKey),
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
      // Coach Dashboard - Weekly overview with compliance, readiness, and goals
      GoRoute(
        path: '/dashboard',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CoachDashboardScreen(),
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
];
