import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers/window_mode_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'data/providers/admin_provider.dart';
import 'data/repositories/auth_repository.dart';
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
        // 1. WindowModeObserver - Tracks split screen / multi-window mode changes
        // 2. FloatingChatOverlay - Messenger-style chat bubble on all screens
        return WindowModeObserver(
          child: FloatingChatOverlay(
            key: const ValueKey('floating_chat_overlay'),
            child: child ?? const SizedBox.shrink(),
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

    debugPrint('🔔 [App] Notification preferences sync callback configured');
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

    debugPrint('🔔 [App] Notification storage callback configured');
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
