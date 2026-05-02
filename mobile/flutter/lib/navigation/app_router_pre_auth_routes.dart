part of 'app_router.dart';

/// Pre-auth routes extracted from app_router.dart
List<RouteBase> _preAuthRoutes() => [
  // === Pre-Auth Routes ===

      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),

      GoRoute(
        path: '/intro',
        builder: (context, state) => const IntroScreen(),
      ),

      // Demo Workout - sample workout preview before sign-up (no auth required)
      GoRoute(
        path: '/demo-workout',
        pageBuilder: (context, state) {
          // Optional workout type can be passed as query parameter
          final workoutType = state.uri.queryParameters['type'];
          return CustomTransitionPage(
            key: state.pageKey,
            child: DemoWorkoutScreen(workoutType: workoutType),
            transitionDuration: const Duration(milliseconds: 400),
            reverseTransitionDuration: const Duration(milliseconds: 300),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.1),
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

      // Demo Active Workout - actually do the sample workout (no auth required)
      GoRoute(
        path: '/demo-active-workout',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final workout = extra?['workout'] as Map<String, dynamic>? ?? {};
          final exercises = extra?['exercises'] as List<Map<String, dynamic>>? ?? [];
          return CustomTransitionPage(
            key: state.pageKey,
            child: DemoActiveWorkoutScreen(
              workout: workout,
              exercises: exercises,
            ),
            transitionDuration: const Duration(milliseconds: 400),
            reverseTransitionDuration: const Duration(milliseconds: 300),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.1),
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

      // Plan Preview - Show full 4-week personalized workout plan BEFORE subscription
      // This addresses user complaint: "After giving all personal info, it requires subscription to see the personal plan"
      GoRoute(
        path: '/plan-preview',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PlanPreviewScreen(),
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
        ),
      ),

      // Pre-Auth Quiz - 5 questions before sign-in
      GoRoute(
        path: '/pre-auth-quiz',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PreAuthQuizScreen(),
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

      // Sign-In Screen - after quiz
      GoRoute(
        path: '/sign-in',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: SignInScreen(
            forceReturning: state.uri.queryParameters['returning'] == 'true',
          ),
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.05),
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

      // Email Sign-In Screen - alternative to Google sign-in
      GoRoute(
        path: '/email-sign-in',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const EmailSignInScreen(),
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.05),
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

      // Weight Projection Screen - show goal timeline graph
      GoRoute(
        path: '/weight-projection',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const WeightProjectionScreen(),
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

      // Coach Selection - pick your AI coach personality before onboarding
      // Also used for changing coach from AI settings (with ?fromSettings=true)
      GoRoute(
        path: '/coach-selection',
        pageBuilder: (context, state) {
          // Check if coming from AI settings (changing coach, not initial selection)
          final fromSettings = state.uri.queryParameters['fromSettings'] == 'true';
          return CustomTransitionPage(
            key: state.pageKey,
            child: CoachSelectionScreen(fromSettings: fromSettings),
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

      // Fitness Assessment - quick fitness check after coach selection
      GoRoute(
        path: '/fitness-assessment',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const FitnessAssessmentScreen(),
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

      // Workout Generation - full screen progress while generating workouts
      GoRoute(
        path: '/workout-generation',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const WorkoutGenerationScreen(),
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      ),

      // Hard paywall — shown after trial/subscription expires
      GoRoute(
        path: '/hard-paywall',
        builder: (context, state) => const HardPaywallScreen(),
      ),

      // Paywall Screen 1: Feature highlights
      GoRoute(
        path: '/paywall-features',
        builder: (context, state) => const PaywallFeaturesScreen(),
      ),

      // Paywall Screen 2: Trial timeline
      GoRoute(
        path: '/paywall-timeline',
        builder: (context, state) => const PaywallTimelineScreen(),
      ),

      // Paywall Screen 3: Pricing selection
      GoRoute(
        path: '/paywall-pricing',
        builder: (context, state) => const PaywallPricingScreen(),
      ),

      GoRoute(
        path: '/workout-loading',
        builder: (context, state) => const WorkoutLoadingScreen(),
      ),

      // Permissions primer (camera/photos/microphone). Shown once before
      // notifications-prime so the user understands *why* the OS is about
      // to ask for access. Skipping is allowed; features re-prompt at use site.
      GoRoute(
        path: PermissionsPrimerScreen.routePath,
        builder: (context, state) => const PermissionsPrimerScreen(),
      ),

      // Notification pre-permission screen — shown once after onboarding/paywall
      // before the user lands on /home. The OS notification prompt only fires
      // if the user opts in here (soft prompt → hard prompt pattern).
      GoRoute(
        path: '/notifications-prime',
        builder: (context, state) => const NotificationPrimeScreen(),
      ),

      // Commitment Pact — post-paywall psychological commitment screen.
      // The screen file existed and was imported but the route was never
      // registered, so paywall_pricing_screen.dart's `context.go('/commitment-pact')`
      // (line 574) was hitting the GoRouter 404 page. Side-effect of fixing
      // this: FounderNoteSheet now displays correctly because
      // CommitmentPactScreen._commit() is its only post-conversion trigger.
      GoRoute(
        path: '/commitment-pact',
        builder: (context, state) => const CommitmentPactScreen(),
      ),

      // Onboarding v5.1 — merged trust + expectations (replaces /honest-expectations + /privacy-trust)
      GoRoute(
        path: '/trust-and-expectations',
        builder: (context, state) => const TrustAndExpectationsScreen(),
      ),

      // Onboarding v5 — analyzing screen between trust-and-expectations and
      // weight-projection. Was referenced in the auth-redirect whitelist
      // but the GoRoute itself was missing → "Page not found".
      GoRoute(
        path: '/plan-analyzing',
        builder: (context, state) => const PlanAnalyzingScreen(),
      ),

      // Onboarding v5 — demo tasks (workout + nutrition apptaste) between
      // weight-projection and sign-in. Same omitted-route bug as above.
      GoRoute(
        path: '/demo-tasks',
        builder: (context, state) => const DemoTasksScreen(),
      ),

      // Demo showcase screens pushed from /demo-tasks tiles. Imports
      // existed in app_router.dart but routes were never registered →
      // tapping a demo tile crashed with "Page not found".
      GoRoute(
        path: '/demo-workout-showcase',
        builder: (context, state) => const WorkoutShowcaseScreen(),
      ),
      GoRoute(
        path: '/demo-nutrition-showcase',
        builder: (context, state) => const NutritionShowcaseScreen(),
      ),

      // Onboarding v5 — capability + social-proof page navigated from
      // fitness-assessment. Import existed, GoRoute didn't.
      GoRoute(
        path: '/capability-and-community',
        builder: (context, state) => const CapabilityAndCommunityScreen(),
      ),

];
