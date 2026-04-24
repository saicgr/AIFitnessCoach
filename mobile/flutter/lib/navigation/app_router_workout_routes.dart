part of 'app_router.dart';

/// Workout-related routes extracted from app_router.dart
List<RouteBase> _workoutRoutes() => [
  // === Workout Routes ===

      // Mood workout pre-start — runs a breath or grounding prompt appropriate
      // to the mood (Anxious gets 5-4-3-2-1; Angry / Stressed get breathwork)
      // then replaces itself with the regular workout detail screen.
      // Declared BEFORE `/workout/:id` so GoRouter treats it as a static
      // path rather than a workoutId param.
      GoRoute(
        path: '/workout/mood-pre-start',
        builder: (context, state) {
          final workout = state.extra is Workout ? state.extra as Workout : null;
          if (workout == null) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text('No workout data'),
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
          return MoodWorkoutPreStartScreen(workout: workout);
        },
      ),

      GoRoute(
        path: '/workout/:id',
        builder: (context, state) {
          final workoutId = state.pathParameters['id'] ?? '';
          final initialWorkout = state.extra is Workout ? state.extra as Workout : null;
          return WorkoutDetailScreen(workoutId: workoutId, initialWorkout: initialWorkout);
        },
      ),

      // Workout completion summary. `?tab=(detail|summary|advanced)` selects
      // the initial pill — defaults to detail so nothing changes for existing
      // entry points. Used by the workout-complete screen's "Summary" button
      // to deep-link straight to the Summary pane.
      GoRoute(
        path: '/workout-summary/:id',
        builder: (context, state) {
          final workoutId = state.pathParameters['id'] ?? '';
          final tab = state.uri.queryParameters['tab'];
          return WorkoutSummaryScreenV2(
            workoutId: workoutId,
            initialTab: WorkoutSummaryTab.fromQuery(tab),
          );
        },
      ),

      // Exercise detail (full screen with autoplay video).
      // `extra` accepts either a raw `WorkoutExercise`, a plain JSON map for
      // the exercise, OR `{exercise: <WorkoutExercise|Map>, initialTab: int}`
      // for deep-linking into a specific tab (0=Info, 1=Stats, 2=History).
      GoRoute(
        path: '/exercise-detail',
        builder: (context, state) {
          WorkoutExercise? exercise;
          int initialTab = 0;

          final extra = state.extra;
          if (extra is WorkoutExercise) {
            exercise = extra;
          } else if (extra is Map<String, dynamic>) {
            final inner = extra['exercise'];
            if (inner is WorkoutExercise) {
              exercise = inner;
              final t = extra['initialTab'];
              if (t is int) initialTab = t;
            } else if (inner is Map<String, dynamic>) {
              exercise = WorkoutExercise.fromJson(inner);
              final t = extra['initialTab'];
              if (t is int) initialTab = t;
            } else {
              // Legacy shape: the whole map IS the exercise JSON.
              exercise = WorkoutExercise.fromJson(extra);
            }
          }
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
          return ExerciseDetailScreen(exercise: exercise, initialTab: initialTab);
        },
      ),

      // Active workout
      GoRoute(
        path: '/active-workout',
        builder: (context, state) {
          // Handle Workout object, Map with challenge data, or Map<String, dynamic> (from serialization)
          Workout? workout;
          String? challengeId;
          Map<String, dynamic>? challengeData;

          if (state.extra is Workout) {
            workout = state.extra as Workout;
          } else if (state.extra is Map<String, dynamic>) {
            final map = state.extra as Map<String, dynamic>;
            // Check if it's a challenge map with embedded Workout object
            if (map.containsKey('workout') && map['workout'] is Workout) {
              workout = map['workout'] as Workout;
              challengeId = map['challengeId'] as String?;
              challengeData = map['challengeData'] as Map<String, dynamic>?;
            } else {
              // Legacy: try parsing as Workout JSON
              try {
                workout = Workout.fromJson(map);
              } catch (e) {
                debugPrint('❌ [Router] Failed to parse workout from Map: $e');
              }
            }
          }
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
          // Check for empty exercises list
          if (workout.exercises.isEmpty) {
            debugPrint('❌ [Router] Workout has no exercises: ${workout.id}');
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 48, color: Colors.orange),
                    const SizedBox(height: 16),
                    const Text(
                      'Workout has no exercises',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'This workout is missing exercise data. Please try regenerating it.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.go('/home'),
                      child: const Text('Go Home'),
                    ),
                  ],
                ),
              ),
            );
          }
          // Gate picks the active-workout tier (Easy/Simple/Advanced) from
          // workoutUiModeProvider so all three tiers share one route.
          return ActiveWorkoutEntry(
            workout: workout,
            challengeId: challengeId,
            challengeData: challengeData,
          );
        },
      ),

      // Challenge compare screen (side-by-side results)
      GoRoute(
        path: '/challenge-compare',
        builder: (context, state) {
          final challengeId = state.extra as String? ?? '';
          return ChallengeCompareScreen(challengeId: challengeId);
        },
      ),

      // Shared workout detail (from social feed)
      GoRoute(
        path: '/shared-workout',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>? ?? {};
          return SharedWorkoutDetailScreen(
            activityId: data['activityId'] as String? ?? '',
            currentUserId: data['currentUserId'] as String? ?? '',
            posterName: data['posterName'] as String? ?? '',
            posterAvatar: data['posterAvatar'] as String?,
            activityType: data['activityType'] as String? ?? 'workout_shared',
            activityData: data['activityData'] as Map<String, dynamic>? ?? {},
            savedWorkoutsService: data['savedWorkoutsService'] as SavedWorkoutsService?,
          );
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
            duration: (data['duration'] as num).toInt(),
            calories: (data['calories'] as num).toInt(),
            workoutLogId: data['workoutLogId'] as String?,
            exercisesPerformance: data['exercisesPerformance'] as List<Map<String, dynamic>>?,
            totalRestSeconds: data['totalRestSeconds'] as int?,
            avgRestSeconds: data['avgRestSeconds'] as double?,
            totalSets: data['totalSets'] as int?,
            totalReps: data['totalReps'] as int?,
            totalVolumeKg: data['totalVolumeKg'] as double?,
            challengeId: data['challengeId'] as String?,
            challengeData: data['challengeData'] as Map<String, dynamic>?,
            personalRecords: data['personalRecords'] as List<PersonalRecordInfo>?,
            performanceComparison: data['performanceComparison'] as PerformanceComparisonInfo?,
            plannedExercises: data['plannedExercises'] as List<Map<String, dynamic>>?,
            exerciseTimeSeconds: data['exerciseTimeSeconds'] as Map<int, int>?,
            // Heart rate data from watch (if available)
            heartRateReadings: data['heartRateReadings'] as List<HeartRateReadingData>?,
            avgHeartRate: data['avgHeartRate'] as int?,
            maxHeartRate: data['maxHeartRate'] as int?,
            minHeartRate: data['minHeartRate'] as int?,
            // W1: triggers First Workout Forecast sheet
            isFirstWorkout: data['isFirstWorkout'] as bool? ?? false,
          );
        },
      ),

      // Custom Workout Builder - Create your own workout from scratch
      GoRoute(
        path: '/workout/build',
        builder: (context, state) => const CustomWorkoutBuilderScreen(),
      ),

      // Achievements
      GoRoute(
        path: '/achievements',
        builder: (context, state) => const AchievementsScreen(),
      ),

      // Stats sub-routes (formerly under /progress)
      GoRoute(
        path: '/stats/milestones',
        builder: (context, state) => const MilestonesScreen(),
      ),
      GoRoute(
        path: '/stats/personal-records',
        builder: (context, state) => const PersonalRecordsScreen(),
      ),
      GoRoute(
        path: '/stats/exercise-history',
        builder: (context, state) => const ExerciseHistoryScreen(),
      ),
      GoRoute(
        path: '/stats/exercise-history/:exerciseName',
        builder: (context, state) {
          final exerciseName = Uri.decodeComponent(state.pathParameters['exerciseName'] ?? '');
          return ExerciseProgressDetailScreen(exerciseName: exerciseName);
        },
      ),
      GoRoute(
        path: '/stats/muscle-analytics',
        builder: (context, state) => const MuscleAnalyticsScreen(),
      ),
      GoRoute(
        path: '/stats/muscle-analytics/:muscleGroup',
        builder: (context, state) {
          final muscleGroup = Uri.decodeComponent(state.pathParameters['muscleGroup'] ?? '');
          return MuscleDetailScreen(muscleGroup: muscleGroup);
        },
      ),
      GoRoute(
        path: '/stats/readiness',
        builder: (context, state) => const ComprehensiveStatsScreen(initialTab: 2),
      ),

      // Redirects from old /progress/* routes to /stats/*
      GoRoute(
        path: '/progress/milestones',
        redirect: (context, state) => '/stats/milestones',
      ),
      GoRoute(
        path: '/progress/exercise-history',
        redirect: (context, state) => '/stats/exercise-history',
      ),
      GoRoute(
        path: '/progress/exercise-history/:exerciseName',
        redirect: (context, state) {
          final exerciseName = state.pathParameters['exerciseName'] ?? '';
          return '/stats/exercise-history/$exerciseName';
        },
      ),
      GoRoute(
        path: '/progress/muscle-analytics',
        redirect: (context, state) => '/stats/muscle-analytics',
      ),
      GoRoute(
        path: '/progress/muscle-analytics/:muscleGroup',
        redirect: (context, state) {
          final muscleGroup = state.pathParameters['muscleGroup'] ?? '';
          return '/stats/muscle-analytics/$muscleGroup';
        },
      ),

      // Trophy Room - Flat catalogue of all trophies (legacy grid view).
      // New entry point is /badge-hub, but /trophy-room stays as the
      // "all available badges" footer link so deep links from older
      // notifications / share URLs don't 404.
      GoRoute(
        path: '/trophy-room',
        builder: (context, state) => const TrophyRoomScreen(),
      ),

      // Badge Hub — Garmin-style gallery (MY BADGES / IN PROGRESS /
      // CHALLENGES / PERSONAL BESTS / MASTERIES / ALL AVAILABLE).
      GoRoute(
        path: '/badge-hub',
        builder: (context, state) => const BadgeHubScreen(),
      ),

      // XP Leaderboard
      GoRoute(
        path: '/xp-leaderboard',
        builder: (context, state) => const XPLeaderboardScreen(),
      ),

      // Rewards - Claim gifts and rewards
      GoRoute(
        path: '/rewards',
        builder: (context, state) => const RewardsScreen(),
      ),

      // Inventory - Consumables and items
      GoRoute(
        path: '/inventory',
        builder: (context, state) => const InventoryScreen(),
      ),

      // Merch Claims - Physical rewards earned at milestone levels
      GoRoute(
        path: '/merch-claims',
        builder: (context, state) => const MerchClaimsScreen(),
      ),

      // Referrals - Share code + view progress + all merch tiers
      GoRoute(
        path: '/referrals',
        builder: (context, state) => const ReferralsScreen(),
      ),

      // Cosmetics Gallery - Browse, equip badges and frames earned by leveling up
      GoRoute(
        path: '/cosmetics',
        builder: (context, state) => const CosmeticsGalleryScreen(),
      ),

      // XP Goals - Full screen XP goals, daily/weekly/monthly tabs
      GoRoute(
        path: '/xp-goals',
        builder: (context, state) => const XPGoalsScreen(),
      ),

      // Feature Voting (Robinhood-style)
      GoRoute(
        path: '/features',
        builder: (context, state) => const FeatureVotingScreen(),
      ),

      // Coming Soon
      GoRoute(
        path: '/coming-soon',
        builder: (context, state) => const ComingSoonScreen(),
      ),

      // Library (Exercise database, programs) - Full screen outside shell
      // Supports ?tab=0 (Exercises), ?tab=1 (Programs), ?tab=2 (Skills)
      GoRoute(
        path: '/library',
        builder: (context, state) {
          final tabParam = state.uri.queryParameters['tab'];
          final initialTab = tabParam != null ? int.tryParse(tabParam) ?? 0 : 0;
          return LibraryScreen(initialTab: initialTab);
        },
      ),

      // All Training Splits - grid view with category filters
      GoRoute(
        path: '/library/splits',
        builder: (context, state) {
          final category = state.uri.queryParameters['category'];
          return AllSplitsScreen(initialCategory: category);
        },
      ),

      // Hydration — redirect to Nutrition screen's Water tab
      GoRoute(
        path: '/hydration',
        redirect: (context, state) => '/nutrition?tab=2',
      ),

      // Habit Detail - View habit detail with yearly heatmap and stats
      GoRoute(
        path: '/habit/:id',
        pageBuilder: (context, state) {
          final habitId = state.pathParameters['id'] ?? '';
          return CustomTransitionPage(
            key: state.pageKey,
            child: HabitDetailScreen(habitId: habitId),
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
          );
        },
      ),

      // NEAT Dashboard - Daily Activity & Step Goals
      GoRoute(
        path: '/neat',
        builder: (context, state) => const NeatDashboardScreen(),
      ),

      // Reports Hub — catalog of every shareable report type
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportsHubScreen(),
      ),

      // Insights (formerly Weekly Summaries) — still lives at /summaries so
      // deep-links, notifications, and existing pushes keep working. The
      // hub's "Period Insights" card points here.
      GoRoute(
        path: '/summaries',
        builder: (context, state) => const InsightsScreen(),
      ),
      GoRoute(
        path: '/insights/detail',
        builder: (context, state) {
          final summary = state.extra as WeeklySummary;
          return InsightsDetailScreen(summary: summary);
        },
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

];
