import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/post_meal_checkin_reminder.dart';
import 'core/providers/subscription_provider.dart';
import 'core/providers/window_mode_provider.dart';
import 'core/providers/workout_mini_player_provider.dart';
import 'core/theme/accent_color_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'data/providers/admin_provider.dart';
import 'data/providers/gym_profile_provider.dart';
import 'core/accessibility/accessibility_provider.dart';
import 'core/services/posthog_service.dart';
import 'data/repositories/auth_repository.dart';
import 'data/services/api_client.dart';
import 'data/services/deep_link_service.dart';
import 'data/services/notification_service.dart';
import 'data/services/pre_auth_quiz_backup_service.dart';
import 'data/services/workout_notification_service.dart';
// Meal-suggestion widget — staged under Settings → Coming Soon. Re-enable
// the import when the feature goes live (see main.dart for the checklist).
// import 'services/meal_suggestion_widget_service.dart';
import 'navigation/app_router.dart';
import 'screens/ai_settings/ai_settings_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/workout/widgets/workout_mini_player.dart';
import 'widgets/floating_chat/floating_chat_overlay.dart';
import 'package:fitwiz/core/constants/branding.dart';

class AppRoot extends ConsumerStatefulWidget {
  const AppRoot({super.key});

  @override
  ConsumerState<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends ConsumerState<AppRoot> {
  // Note: WidgetsBindingObserver + didChangeAppLifecycleState were added
  // to support the meal-suggestion widget's "refresh on resume" hook.
  // The hook is staged (see Settings → Coming Soon); re-add the mixin,
  // observer registration, and override when that feature ships.
  bool _syncCallbackSet = false;
  bool _notificationCallbackSet = false;
  bool _posthogListenerSet = false;

  @override
  void initState() {
    super.initState();
    // Set up notification storage callback right away
    _setupNotificationStorageCallback();
    // Notification permission is NOT requested here. Cold-prompting on first
    // launch (before the user knows what the app does) tanks opt-in rates.
    // It now fires from NotificationPrimeScreen, gated to run once after
    // onboarding/paywall via HomeScreen's initState.

    // Initialize the post-meal check-in reminder plugin + route taps into
    // the nutrition screen with the check-in pre-bound to the log.
    unawaited(
      PostMealCheckinReminderService.instance.initialize(
        onOpenCheckinCallback: (foodLogId) {
          // Deferred so we don't try to navigate before a MaterialApp.router
          // context exists on first-launch cold-start taps.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            try {
              final router = ref.read(routerProvider);
              router.go('/nutrition?tab=0&openCheckin=$foodLogId');
            } catch (e) {
              debugPrint('⚠️ [PostMealReminder] Router not ready: $e');
            }
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    // Clear notification callbacks to prevent memory leaks (perf fix 1.3)
    final notificationService = ref.read(notificationServiceProvider);
    notificationService.onNotificationReceived = null;
    notificationService.onNotificationTapped = null;
    notificationService.onTokenRefresh = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Eagerly construct the pre-auth quiz auto-backup service so its internal
    // ref.listen subscription is alive for the entire session. The service
    // POSTs quiz mutations to /users/{id}/preferences with a 2s debounce,
    // protecting users from data loss if they uninstall/reinstall mid-onboarding.
    ref.read(preAuthQuizBackupServiceProvider);

    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final accent = ref.watch(accentColorProvider);
    final gymOverride = ref.watch(gymAccentColorProvider);
    final isDark = themeMode == ThemeMode.dark || (themeMode == ThemeMode.system && MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    // Gym profile color takes priority over coach/settings accent
    final effectivePrimary = gymOverride ?? accent.getColor(isDark);
    // Only watch the status field to avoid unnecessary rebuilds when other
    // AuthState fields change (e.g., user object reference updates).
    // Performance fix M5: use .select() to minimize rebuilds.
    final authStatus = ref.watch(authStateProvider.select((s) => s.status));

    // Set up notification preferences sync when user is authenticated
    if (authStatus == AuthStatus.authenticated && !_syncCallbackSet) {
      _setupNotificationPreferencesSync();
    } else if (authStatus == AuthStatus.unauthenticated) {
      _syncCallbackSet = false; // Reset when logged out
    }

    // PostHog user identification + RevenueCat/subscription hydration on
    // auth state changes. Both must fire together so that if a brand-new
    // signed-in user skips identification, neither analytics nor billing
    // state gets re-linked to a stale identity.
    if (!_posthogListenerSet) {
      _posthogListenerSet = true;
      ref.listen(authStateProvider, (previous, next) {
        final posthog = ref.read(posthogServiceProvider);
        if (next.status == AuthStatus.authenticated && next.user != null) {
          posthog.identify(
            userId: next.user!.id,
            userProperties: {
              'email': next.user!.email ?? '',
            },
            userPropertiesSetOnce: {
              'created_at': next.user!.createdAt ?? '',
            },
          );
          // Kick off RevenueCat + backend subscription hydration. Fire-and-
          // forget — initialize() is idempotent so redundant auth-state
          // transitions (e.g. token refresh triggering 'authenticated' again)
          // cost nothing. Without this call Purchases.logIn(userId) never
          // runs and all purchases are attributed to an anonymous RC user.
          unawaited(
            ref
                .read(subscriptionProvider.notifier)
                .initialize(next.user!.id),
          );
          // Replay any deep link that arrived before sign-in (e.g. an
          // invite link tapped from email while logged out). 24h TTL
          // applied inside the drain. Only fire on the unauth → auth edge
          // so we don't spam the queue replay on every token refresh.
          if (previous?.status != AuthStatus.authenticated) {
            unawaited(DeepLinkService.drainPendingDeepLink(ref));
          }
        } else if (next.status == AuthStatus.unauthenticated &&
            previous?.status == AuthStatus.authenticated) {
          posthog.reset();
          // Reset subscription state and log out of RevenueCat so the next
          // user signing in on this device doesn't inherit the previous
          // user's customer ID / cached tier.
          unawaited(
            ref.read(subscriptionProvider.notifier).resetOnSignOut(),
          );
        }
      });
    }

    return MaterialApp.router(
      // Use a key that changes with theme/accent/gym-profile to force a clean rebuild
      // This prevents GlobalKey conflicts when theme changes
      key: ValueKey('app_${themeMode.name}_${accent.name}_${gymOverride?.value ?? "none"}'),
      title: '${Branding.appName}',
      debugShowCheckedModeBanner: false,
      theme: AppThemeLight.buildTheme(effectivePrimary),
      darkTheme: AppTheme.buildDarkTheme(effectivePrimary),
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        // Wrap the entire app with:
        // 1. MediaQuery - Constrain text scaling to prevent layout overflow on devices with large system fonts
        // 2. WindowModeObserver - Tracks split screen / multi-window mode changes
        // 3. FloatingChatOverlay - Messenger-style chat bubble on all screens

        final mediaQuery = MediaQuery.of(context);
        final a11y = ref.watch(accessibilityProvider);

        return MediaQuery(
          data: MediaQueryData(
            size: mediaQuery.size,
            devicePixelRatio: mediaQuery.devicePixelRatio,
            // Apply user font scale from accessibility settings
            textScaler: TextScaler.linear(a11y.fontScale),
            padding: mediaQuery.padding,
            viewPadding: mediaQuery.viewPadding,
            viewInsets: mediaQuery.viewInsets,
            systemGestureInsets: mediaQuery.systemGestureInsets,
            alwaysUse24HourFormat: mediaQuery.alwaysUse24HourFormat,
            accessibleNavigation: mediaQuery.accessibleNavigation,
            invertColors: mediaQuery.invertColors,
            highContrast: a11y.highContrast || mediaQuery.highContrast,
            onOffSwitchLabels: mediaQuery.onOffSwitchLabels,
            disableAnimations: a11y.reduceAnimations || mediaQuery.disableAnimations,
            // Disable bold text to prevent layout changes
            boldText: false,
            navigationMode: mediaQuery.navigationMode,
            gestureSettings: mediaQuery.gestureSettings,
            displayFeatures: mediaQuery.displayFeatures,
            platformBrightness: mediaQuery.platformBrightness,
          ),
          // AccentColorScopeWrapper provides dynamic accent color to all widgets
          // via AccentColorScope InheritedWidget. context.colors.accent now
          // automatically uses the user's selected accent color.
          child: AccentColorScopeWrapper(
            child: WindowModeObserver(
              child: FloatingChatOverlay(
                key: const ValueKey('floating_chat_overlay'),
                child: _WorkoutMiniPlayerOverlay(
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _setupNotificationPreferencesSync() {
    _syncCallbackSet = true;

    // Get the sync helper and set the callback on the preferences notifier
    final prefsSync = ref.read(notificationPrefsSyncProvider);
    final prefsNotifier = ref.read(notificationPreferencesProvider.notifier);

    prefsNotifier.setSyncCallback((prefs) async {
      await prefsSync.syncPreferences(prefs);
    });

    // Restore onboarding_completed and paywall_completed flags from user model
    // to SharedPreferences. These flags are cleared on logout but the notification
    // scheduler needs them to be present in SharedPreferences to schedule local notifications.
    final authState = ref.read(authStateProvider);
    final sharedPrefs = ref.read(sharedPreferencesProvider);
    bool flagsRestored = false;

    if (authState.user?.onboardingCompleted == true) {
      final alreadySet = sharedPrefs.getBool('onboarding_completed') ?? false;
      if (!alreadySet) {
        sharedPrefs.setBool('onboarding_completed', true);
        debugPrint('🔔 [App] Restored onboarding_completed flag to SharedPreferences');
        flagsRestored = true;
      }
    }

    if (authState.user?.paywallCompleted == true) {
      final alreadySet = sharedPrefs.getBool('paywall_completed') ?? false;
      if (!alreadySet) {
        sharedPrefs.setBool('paywall_completed', true);
        debugPrint('🔔 [App] Restored paywall_completed flag to SharedPreferences');
        flagsRestored = true;
      }
    }

    if (flagsRestored) {
      // Reschedule notifications now that flags are restored
      prefsNotifier.rescheduleNotifications();
    }

    // Cache coach ID for personalized notifications
    final aiSettings = ref.read(aiSettingsProvider);
    if (aiSettings.coachPersonaId != null) {
      NotificationServiceScheduled.cacheCoachId(
        aiSettings.coachPersonaId,
        coachingStyle: aiSettings.coachingStyle,
      );
    }

    // Register FCM token with backend now that user is authenticated
    _registerFcmToken();

    debugPrint('🔔 [App] Notification preferences sync callback configured');
  }

  /// Register FCM token with backend when user authenticates.
  /// Retries up to 3 times with exponential backoff (2s, 4s, 8s)
  /// to handle cases where the token isn't ready yet.
  Future<void> _registerFcmToken() async {
    final authState = ref.read(authStateProvider);
    if (authState.user == null) return;

    final notificationService = ref.read(notificationServiceProvider);
    final apiClient = ref.read(apiClientProvider);
    final userId = authState.user!.id;

    const maxAttempts = 3;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final success = await notificationService.registerTokenWithBackend(apiClient, userId);
        if (success) {
          debugPrint('🔔 [App] FCM token registered with backend on login (attempt $attempt)');
          return;
        }
        debugPrint('⚠️ [App] FCM token not available yet (attempt $attempt/$maxAttempts)');
      } catch (e) {
        debugPrint('❌ [App] Error registering FCM token (attempt $attempt/$maxAttempts): $e');
      }
      if (attempt < maxAttempts) {
        await Future.delayed(Duration(seconds: 1 << attempt)); // 2s, 4s
      }
    }
    debugPrint('❌ [App] FCM token registration failed after $maxAttempts attempts');
  }

  void _setupNotificationStorageCallback() {
    if (_notificationCallbackSet) return;
    _notificationCallbackSet = true;

    // Get notification service and set callback to store incoming notifications
    final notificationService = ref.read(notificationServiceProvider);
    notificationService.onNotificationReceived = ({
      required String title,
      required String body,
      String? type,
      Map<String, dynamic>? data,
    }) {
      // Store notification in local storage
      ref.read(notificationsProvider.notifier).addFromPushMessage(
        title: title,
        body: body,
        type: type,
        data: data,
      );
      debugPrint('🔔 [App] Notification stored in inbox: $title');
    };

    // Set up callback for notification taps (navigation)
    notificationService.onNotificationTapped = (notificationType) {
      _navigateToScreenForNotificationType(notificationType);
    };

    // Wire the active-workout notification's body-tap → restore mini player
    // AND navigate to /active-workout. Tapping the sticky foreground
    // notification while the app is backgrounded/killed used to just flip
    // isMinimized=false and land the user on home — the workout session was
    // still live in state but invisible. We push the active-workout route
    // here with the stored Workout object so the in-app UI matches the
    // ongoing session.
    WorkoutNotificationService.instance.onNotificationTapped = () {
      final miniPlayerState = ref.read(workoutMiniPlayerProvider);
      final workout = miniPlayerState.workout;
      if (workout == null) return;
      ref.read(workoutMiniPlayerProvider.notifier).restore();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final router = ref.read(routerProvider);
        router.push('/active-workout', extra: workout);
      });
    };

    // Set up callback for FCM token refresh - sync to backend
    notificationService.onTokenRefresh = (newToken) async {
      final authState = ref.read(authStateProvider);
      if (authState.status == AuthStatus.authenticated && authState.user != null) {
        final apiClient = ref.read(apiClientProvider);
        final userId = authState.user!.id;
        await notificationService.registerTokenWithBackend(apiClient, userId);
        debugPrint('🔔 [App] FCM token refreshed and synced to backend');
      }
    };

    debugPrint('🔔 [App] Notification callbacks configured');
  }

  void _navigateToScreenForNotificationType(String? notificationType) {
    debugPrint('🔔 [App] Navigating for notification type: $notificationType');

    // Defer navigation to next frame to ensure router is ready (cold-start safety)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final router = ref.read(routerProvider);

      switch (notificationType) {
        case 'ai_coach':
        case 'ai_coach_accountability':
          // Accountability nudges open chat — coach message is already in chat_messages DB.
          // When chat screen loads, it fetches history and the proactive message appears.
          router.push('/chat');
          break;
        case 'workout_reminder':
          router.go('/home');
          break;
        case 'movement_reminder':
          router.push('/neat');
          break;
        case 'nutrition_reminder':
          router.go('/nutrition');
          break;
        case 'hydration_reminder':
          // tab=3 is Fuel; fuelSection=water opens the Water pill directly
          // so the user lands on the log-water affordance, not Patterns.
          router.go('/nutrition?tab=3&fuelSection=water');
          break;
        case 'streak_alert':
          router.push('/achievements');
          break;
        case 'daily_crate':
          // Route to home so the crate banner is visible; tapping it
          // triggers the auto-claim path in stacked_banner_panel.dart.
          router.go('/home');
          break;
        case 'weekly_summary':
          router.push('/summaries');
          break;
        case 'achievement':
          router.push('/achievements');
          break;
        case 'friend_request':
          router.push('/notifications');
          break;
        case 'test':
          router.push('/notifications');
          break;
        case 'trial_reminder':
          router.push('/paywall-pricing');
          break;
        case 'live_chat_message':
        case 'live_chat_connected':
        case 'live_chat_ended':
          router.push('/live-chat');
          break;
        default:
          // Handle schedule_reminder:$itemId payload format
          if (notificationType != null && notificationType.startsWith('schedule_reminder')) {
            router.go('/home');
          } else {
            router.push('/notifications');
          }
          break;
      }
    });
  }
}

/// Global overlay that shows the workout mini player on all screens
class _WorkoutMiniPlayerOverlay extends ConsumerWidget {
  final Widget child;

  const _WorkoutMiniPlayerOverlay({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final miniPlayerState = ref.watch(workoutMiniPlayerProvider);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Main content — must be Positioned so hit-testing works
        // correctly with the Positioned mini player sibling.
        Positioned.fill(child: child),

        // Workout mini player (when minimized).
        // IMPORTANT: Must be a direct Positioned child of this Stack,
        // otherwise it blocks all touch events on the content underneath.
        //
        // Hidden while a modal route (bottom sheet / dialog) is on top —
        // the overlay is mounted above the Navigator, so without this gate
        // the pill would float above every sheet (see #4 in plans).
        if (miniPlayerState.isMinimized && !miniPlayerState.suppressedForModal)
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 62,
            child: WorkoutMiniPlayer(
              onTap: () {
                final state = ref.read(workoutMiniPlayerProvider);
                if (state.workout != null) {
                  ref.read(workoutMiniPlayerProvider.notifier).restore();
                  final router = ref.read(routerProvider);
                  router.push('/active-workout', extra: state.workout);
                }
              },
              onClose: () {
                ref.read(workoutMiniPlayerProvider.notifier).close();
              },
            ),
          ),
      ],
    );
  }
}

