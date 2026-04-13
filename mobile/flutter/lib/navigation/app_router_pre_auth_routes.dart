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

      // How It Works - explains the 3-step onboarding journey before quiz
      GoRoute(
        path: '/how-it-works',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const HowItWorksScreen(),
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

      // Pricing Preview - see pricing before creating account (pre-auth)
      GoRoute(
        path: '/pricing-preview',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PricingPreviewScreen(),
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
        ),
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

      // Guest routes removed - guest mode is disabled
      // /guest-home and /guest-library redirected to /intro for any stale links
      GoRoute(
        path: '/guest-home',
        redirect: (context, state) => '/intro',
      ),
      GoRoute(
        path: '/guest-library',
        redirect: (context, state) => '/intro',
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

      // Personal Info Screen - collect name, DOB, gender, height, weight after sign-in
      GoRoute(
        path: '/personal-info',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PersonalInfoScreen(),
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

      // Training Split - choose training split after weight projection, before AI consent
      GoRoute(
        path: '/training-split',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const TrainingSplitScreen(),
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

      // AI Consent - privacy and data usage consent before coach selection
      GoRoute(
        path: '/ai-consent',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AiConsentScreen(),
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

      // Health Disclaimer - health & safety acknowledgment before coach selection
      GoRoute(
        path: '/health-disclaimer',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const HealthDisclaimerScreen(),
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

      // Accuracy Intro - shows vague vs specific food logging comparison
      GoRoute(
        path: '/accuracy-intro',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AccuracyIntroScreen(),
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

      // Health Connect Setup - connect Google Health Connect / Apple HealthKit
      GoRoute(
        path: '/health-connect-setup',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const HealthConnectScreen(),
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

      // Feature Showcase - swipeable cards highlighting key features
      GoRoute(
        path: '/feature-showcase',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const FeatureShowcaseScreen(),
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

      // Mode Selection (shown during onboarding after name/age)
      GoRoute(
        path: '/mode-selection',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ModeSelectionScreen(
            userAge: extra?['userAge'] as int?,
            onNormalSelected: extra?['onNormalSelected'] as VoidCallback?,
            onSeniorSelected: extra?['onSeniorSelected'] as VoidCallback?,
          );
        },
      ),

      // Senior Onboarding (Visual, simplified - NOT AI chat)
      GoRoute(
        path: '/senior-onboarding',
        builder: (context, state) => const SeniorOnboardingScreen(),
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
        path: '/senior-home',
        builder: (context, state) => const SeniorHomeScreen(),
      ),

      GoRoute(
        path: '/subscription-success',
        builder: (context, state) => const SubscriptionSuccessScreen(),
      ),

      GoRoute(
        path: '/workout-loading',
        builder: (context, state) => const WorkoutLoadingScreen(),
      ),

      // Notification pre-permission screen — shown once after onboarding/paywall
      // before the user lands on /home. The OS notification prompt only fires
      // if the user opts in here (soft prompt → hard prompt pattern).
      GoRoute(
        path: '/notifications-prime',
        builder: (context, state) => const NotificationPrimeScreen(),
      ),

];
