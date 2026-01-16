import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers/window_mode_provider.dart';
import 'core/theme/accent_color_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'data/providers/admin_provider.dart';
import 'data/repositories/auth_repository.dart';
import 'data/services/api_client.dart';
import 'data/services/notification_service.dart';
import 'navigation/app_router.dart';
import 'screens/notifications/notifications_screen.dart';
import 'widgets/floating_chat/floating_chat_overlay.dart';

class FitWizApp extends ConsumerStatefulWidget {
  const FitWizApp({super.key});

  @override
  ConsumerState<FitWizApp> createState() => _FitWizAppState();
}

class _FitWizAppState extends ConsumerState<FitWizApp> {
  bool _syncCallbackSet = false;
  bool _notificationCallbackSet = false;

  @override
  void initState() {
    super.initState();
    // Set up notification storage callback right away
    _setupNotificationStorageCallback();
    // Request notification permission now that Activity is ready
    _requestNotificationPermission();
  }

  /// Request notification permission after Activity is available
  /// This is deferred from main.dart to avoid "Unable to detect current Android Activity" error
  Future<void> _requestNotificationPermission() async {
    final notificationService = ref.read(notificationServiceProvider);
    await notificationService.requestPermissionWhenReady();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final authState = ref.watch(authStateProvider);

    // Set up notification preferences sync when user is authenticated
    if (authState.status == AuthStatus.authenticated && !_syncCallbackSet) {
      _setupNotificationPreferencesSync();
    } else if (authState.status == AuthStatus.unauthenticated) {
      _syncCallbackSet = false; // Reset when logged out
    }

    return MaterialApp.router(
      // Use a key that changes with theme to force a clean rebuild
      // This prevents GlobalKey conflicts when theme changes
      key: ValueKey('app_${themeMode.name}'),
      title: 'FitWiz',
      debugShowCheckedModeBanner: false,
      theme: AppThemeLight.theme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        // Wrap the entire app with:
        // 1. MediaQuery - Constrain text scaling to prevent layout overflow on devices with large system fonts
        // 2. WindowModeObserver - Tracks split screen / multi-window mode changes
        // 3. FloatingChatOverlay - Messenger-style chat bubble on all screens

        final mediaQuery = MediaQuery.of(context);

        // Debug logging to diagnose overflow issues
        debugPrint('📱 [MediaQuery] Size: ${mediaQuery.size.width}x${mediaQuery.size.height}');
        debugPrint('📱 [MediaQuery] DevicePixelRatio: ${mediaQuery.devicePixelRatio}');
        debugPrint('📱 [MediaQuery] TextScaler: ${mediaQuery.textScaler}');
        debugPrint('📱 [MediaQuery] Padding: ${mediaQuery.padding}');
        debugPrint('📱 [MediaQuery] BoldText: ${mediaQuery.boldText}');

        debugPrint('📱 [MediaQuery] OVERRIDE: Forcing textScaler to 1.0 and boldText to false');

        return MediaQuery(
          data: MediaQueryData(
            size: mediaQuery.size,
            devicePixelRatio: mediaQuery.devicePixelRatio,
            // Force text scaling to 1.0 to prevent overflow
            textScaler: const TextScaler.linear(1.0),
            padding: mediaQuery.padding,
            viewPadding: mediaQuery.viewPadding,
            viewInsets: mediaQuery.viewInsets,
            systemGestureInsets: mediaQuery.systemGestureInsets,
            alwaysUse24HourFormat: mediaQuery.alwaysUse24HourFormat,
            accessibleNavigation: mediaQuery.accessibleNavigation,
            invertColors: mediaQuery.invertColors,
            highContrast: mediaQuery.highContrast,
            onOffSwitchLabels: mediaQuery.onOffSwitchLabels,
            disableAnimations: mediaQuery.disableAnimations,
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
                child: child ?? const SizedBox.shrink(),
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

    // Register FCM token with backend now that user is authenticated
    _registerFcmToken();

    debugPrint('🔔 [App] Notification preferences sync callback configured');
  }

  /// Register FCM token with backend when user authenticates
  Future<void> _registerFcmToken() async {
    try {
      final authState = ref.read(authStateProvider);
      if (authState.user == null) return;

      final notificationService = ref.read(notificationServiceProvider);
      final apiClient = ref.read(apiClientProvider);
      final userId = authState.user!.id;

      final success = await notificationService.registerTokenWithBackend(apiClient, userId);
      if (success) {
        debugPrint('🔔 [App] FCM token registered with backend on login');
      } else {
        debugPrint('⚠️ [App] Failed to register FCM token (may not be available yet)');
      }
    } catch (e) {
      debugPrint('❌ [App] Error registering FCM token: $e');
    }
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
    final router = ref.read(routerProvider);

    debugPrint('🔔 [App] Navigating for notification type: $notificationType');

    switch (notificationType) {
      case 'ai_coach':
        router.push('/chat');
        break;
      case 'workout_reminder':
        router.push('/home');
        break;
      case 'nutrition_reminder':
        router.push('/nutrition');
        break;
      case 'hydration_reminder':
        router.push('/hydration');
        break;
      case 'streak_alert':
        router.push('/achievements');
        break;
      case 'weekly_summary':
        router.push('/summaries');
        break;
      case 'achievement':
        router.push('/achievements');
        break;
      case 'test':
        router.push('/notifications');
        break;
      case 'live_chat_message':
      case 'live_chat_connected':
      case 'live_chat_ended':
        // Check if user is admin - route to admin support, otherwise live chat
        final isAdmin = ref.read(isAdminProvider);
        if (isAdmin) {
          router.push('/admin-support');
        } else {
          router.push('/live-chat');
        }
        break;
      case 'admin_new_chat':
      case 'admin_new_message':
        // Admin-specific notifications - route to admin support
        router.push('/admin-support');
        break;
      default:
        // Default to notifications inbox
        router.push('/notifications');
        break;
    }
  }
}
