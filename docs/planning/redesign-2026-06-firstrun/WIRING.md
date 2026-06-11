# WIRING.md — side-effect inventory (pre-redesign baseline)
# Generated from source before any round-2 edit. Re-run the generator after edits and diff.

## lib/screens/splash/splash_screen.dart

## lib/screens/auth/intro_screen.dart
  ROUTE L58: /onboarding-why
  ROUTE L63: /sign-in?returning=true

## lib/screens/auth/sign_in_screen.dart
  API L272: ${ApiConstants.workouts}/today?user_id=$userId
  ROUTE L815: /email-sign-in
  EVENT L108: onboarding_signin_completed
  PROVIDER L87: authStateProvider.notifier
  PROVIDER L96: authStateProvider
  PROVIDER L107: posthogServiceProvider
  PROVIDER L268: apiClientProvider
  PROVIDER L387: preAuthQuizProvider

## lib/screens/auth/email_sign_in_screen.dart
  PROVIDER L53: preAuthQuizProvider
  PROVIDER L117: authStateProvider.notifier
  PROVIDER L127: authStateProvider

## lib/screens/auth/widgets/pre_auth_referral_chip.dart

## lib/screens/onboarding/onboarding_why_screen.dart
  ROUTE L80: /pre-auth-quiz
  ROUTE L115: /intro
  EVENT L94: onboarding_why_answered
  EVENT L105: onboarding_why_skipped
  PROVIDER L68: preAuthQuizProvider
  PROVIDER L76: posthogServiceProvider
  PROVIDER L92: preAuthQuizProvider.notifier

## lib/screens/onboarding/onboarding_reflect_screen.dart
  EVENT L76: onboarding_reflect_completed
  PROVIDER L65: posthogServiceProvider
  PROVIDER L137: preAuthQuizProvider

## lib/screens/onboarding/onboarding_blocker_screen.dart
  EVENT L132: onboarding_blocker_answered
  PROVIDER L100: preAuthQuizProvider
  PROVIDER L106: posthogServiceProvider
  PROVIDER L130: preAuthQuizProvider.notifier

## lib/screens/onboarding/trust_and_expectations_screen.dart
  ROUTE L168: /plan-analyzing
  EVENT L166: onboarding_trust_expectations_completed
  PROVIDER L165: posthogServiceProvider

## lib/screens/onboarding/pre_auth_quiz_screen.dart
  ROUTE L674: /intro
  PREFS L976: full_gym
  PROVIDER L298: preAuthQuizProvider.notifier
  PROVIDER L639: windowModeProvider
  PROVIDER L670: authStateProvider.notifier

## lib/screens/onboarding/pre_auth_quiz_screen_ui.dart

## lib/screens/onboarding/pre_auth_quiz_screen_ext.dart
  ROUTE L306: /onboarding-reflect
  EVENT L292: onboarding_quiz_completed
  PREFS L190: other
  PREFS L741: none
  PROVIDER L153: preAuthQuizProvider.notifier
  PROVIDER L291: posthogServiceProvider
  PROVIDER L567: preAuthQuizProvider

## lib/screens/onboarding/plan_analyzing_screen.dart
  API L80: /onboarding/computed-goal-date
  ROUTE L111: /weight-projection
  EVENT L108: onboarding_plan_analyzing_completed
  PROVIDER L66: preAuthQuizProvider
  PROVIDER L107: posthogServiceProvider

## lib/screens/onboarding/weight_projection_screen.dart
  ROUTE L299: /plan-analyzing
  ROUTE L441: /demo-tasks
  EVENT L431: onboarding_weight_goal_set
  PROVIDER L227: preAuthQuizProvider
  PROVIDER L331: windowModeProvider
  PROVIDER L375: preAuthQuizProvider.notifier
  PROVIDER L430: posthogServiceProvider

## lib/screens/onboarding/weight_projection_screen_ui.dart
  ROUTE L30: /plan-analyzing
  ROUTE L230: /demo-tasks
  EVENT L219: onboarding_weight_goal_set
  PROVIDER L80: windowModeProvider
  PROVIDER L218: posthogServiceProvider

## lib/screens/onboarding/demo_tasks_screen.dart
  ROUTE L72: /sign-in
  ROUTE L153: /demo-workout-showcase
  ROUTE L168: /demo-nutrition-showcase
  EVENT L63: onboarding_demo_tasks_completed
  PROVIDER L45: demoTasksSeenProvider.notifier
  PROVIDER L62: posthogServiceProvider

## lib/screens/onboarding/personal_info_screen.dart
  API L157: ${ApiConstants.users}/$userId
  ROUTE L130: /pre-auth-quiz
  EVENT L173: onboarding_personal_info_completed
  EVENT L264: cycle_onboarding_completed
  PROVIDER L44: preAuthQuizProvider
  PROVIDER L138: preAuthQuizProvider.notifier
  PROVIDER L148: apiClientProvider
  PROVIDER L170: authStateProvider.notifier
  PROVIDER L172: posthogServiceProvider

## lib/screens/onboarding/coach_selection_screen.dart
  API L859: ${ApiConstants.users}/$userId/preferences
  API L865: ${ApiConstants.users}/$userId
  API L907: ${ApiConstants.users}/$userId/calculate-nutrition-targets
  API L949: ${ApiConstants.users}/$userId/sync-fasting-preferences
  ROUTE L752: /fitness-assessment
  EVENT L741: onboarding_coach_selected
  PREFS L875: onboarding_completed
  PROVIDER L98: accentColorProvider.notifier
  PROVIDER L696: aiSettingsProvider.notifier
  PROVIDER L723: chatMessagesProvider.notifier
  PROVIDER L736: authStateProvider.notifier
  PROVIDER L740: posthogServiceProvider
  PROVIDER L763: apiClientProvider
  PROVIDER L765: preAuthQuizProvider.notifier
  PROVIDER L935: nutritionPreferencesProvider.notifier
  PROVIDER L959: fastingProvider.notifier
  PROVIDER L963: fastingSettingsProvider.notifier
  PROVIDER L1073: windowModeProvider

## lib/screens/onboarding/coach_selection_screen_ui.dart
  ROUTE L371: /settings
  ROUTE L373: /pre-auth-quiz

## lib/screens/paywall/paywall_pricing_screen.dart
  API L1432: ${ApiConstants.users}/$userId
  ROUTE L1357: /home
  ROUTE L1455: /personal-info
  ROUTE L1459: /commitment-pact
  EVENT L90: paywall_pricing_viewed
  EVENT L386: paywall_plan_selected
  EVENT L1326: paywall_skip_tapped
  EVENT L1340: paywall_discount_shown
  EVENT L1346: paywall_discount_accepted
  EVENT L1374: paywall_skipped_no_purchase
  EVENT L1388: paywall_routed_lapsed_user_dismissed
  EVENT L1474: paywall_cta_tapped
  EVENT L1484: paywall_purchase_initiated
  PREFS L1419: paywall_completed
  PROVIDER L85: posthogServiceProvider
  PROVIDER L88: preAuthQuizProvider
  PROVIDER L271: subscriptionProvider
  PROVIDER L274: windowModeProvider
  PROVIDER L1350: subscriptionProvider.notifier
  PROVIDER L1352: authStateProvider
  PROVIDER L1383: lapsedPaywallGateProvider
  PROVIDER L1416: authStateProvider.notifier
  PROVIDER L1424: notificationPreferencesProvider.notifier
  PROVIDER L1429: apiClientProvider

## lib/screens/onboarding/commitment_pact_screen.dart
  API L49: /users/me
  ROUTE L77: /health-connect-onboarding
  EVENT L62: onboarding_commitment_pact_accepted
  EVENT L96: onboarding_commitment_pact_skip_intent
  EVENT L179: onboarding_commitment_pact_skip_recovered
  EVENT L212: onboarding_commitment_pact_skipped
  PROVIDER L48: apiClientProvider
  PROVIDER L61: posthogServiceProvider
  PROVIDER L210: preAuthQuizProvider

## lib/screens/onboarding/health_connect_onboarding_screen.dart
  ROUTE L102: /permissions-primer
  EVENT L67: onboarding_health_connect_tapped
  EVENT L83: onboarding_health_connect_succeeded
  EVENT L108: onboarding_health_connect_skipped
  PREFSKEY L36: health_connect_onboarding_shown
  PROVIDER L66: posthogServiceProvider
  PROVIDER L71: healthSyncProvider.notifier
  PROVIDER L81: dailyActivityProvider.notifier

## lib/screens/onboarding/permissions_primer_screen.dart
  ROUTE L107: /notifications-prime
  ROUTE L109: /home
  EVENT L64: permissions_primer_grant_tapped
  EVENT L115: permissions_primer_skipped
  PREFS L52: notification_prime_shown
  PREFSKEY L33: permissions_primer_shown
  PROVIDER L63: posthogServiceProvider
  PROVIDER L95: notificationServiceProvider

## lib/screens/onboarding/notification_prime_screen.dart
  ROUTE L60: /home
  EVENT L48: notification_prime_enable_tapped
  EVENT L66: notification_prime_skipped
  PREFSKEY L26: notification_prime_shown
  PROVIDER L47: posthogServiceProvider
  PROVIDER L52: notificationServiceProvider

## lib/screens/onboarding/founder_note_sheet.dart
  EVENT L115: onboarding_founder_note_shown
  EVENT L407: onboarding_founder_note_dismissed
  PROVIDER L92: preAuthQuizProvider
  PROVIDER L97: authStateProvider
  PROVIDER L114: posthogServiceProvider

## lib/screens/onboarding/widgets/quiz_header.dart

## lib/screens/onboarding/widgets/quiz_progress_bar.dart

## lib/screens/onboarding/widgets/quiz_continue_button.dart

## lib/screens/onboarding/widgets/onboarding_theme.dart
