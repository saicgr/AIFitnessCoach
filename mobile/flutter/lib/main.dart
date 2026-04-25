import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/config/environment_config.dart';
import 'core/constants/api_constants.dart';
import 'core/accessibility/accessibility_provider.dart';
import 'core/providers/subscription_provider.dart';
import 'data/services/data_cache_service.dart';
import 'data/services/haptic_service.dart';
import 'data/services/image_url_cache.dart';
import 'data/services/incoming_link_service.dart';
import 'data/services/live_activity_service.dart';
import 'data/services/notification_service.dart';
import 'data/services/widget_action_headless_service.dart';
import 'data/services/background_sync_service.dart';
import 'data/local/database_provider.dart';
// Meal-suggestion widget (see coming_soon_screen.dart) — code is staged
// but not yet wired. When bringing live, uncomment these imports and the
// init block further down in _initNonCriticalServices.
// import 'data/services/api_client.dart';
// import 'data/services/widget_service.dart';
// import 'services/meal_suggestion_widget_service.dart';
// import 'package:home_widget/home_widget.dart';
// FlutterGemma import removed -- initialization deferred to OnDeviceGemmaService.ensureInitialized()
// to avoid ANR from heavy native ML runtime setup during app startup.
import 'core/services/analytics_service.dart';
import 'core/services/posthog_service.dart';
import 'core/services/sentry_service.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kDebugMode) {
    debugPrint('🔧 [Environment] ENV=${EnvironmentConfig.isDev ? "dev" : "prod"}');
    debugPrint('🔧 [Environment] Backend URL: ${ApiConstants.baseUrl}');
  }

  // --- Critical blocking initializations (must complete before runApp) ---
  // Run all three in parallel since they're independent of each other.
  // This saves ~500-1000ms vs sequential awaits on slow devices/emulators.

  late final SharedPreferences sharedPreferences;
  var firebaseReady = false;
  await Future.wait([
    Firebase.initializeApp().then<void>((_) {
      firebaseReady = true;
    }).catchError((e) {
      debugPrint('⚠️ Firebase initialization failed: $e');
    }),
    SharedPreferences.getInstance().then((prefs) => sharedPreferences = prefs),
    Supabase.initialize(
      url: ApiConstants.supabaseUrl,
      anonKey: ApiConstants.supabaseAnonKey,
    ),
  ]);

  // Wire up Crashlytics + Sentry error handlers.
  // Only report truly fatal errors as fatal; rendering/layout errors are non-fatal.
  FlutterError.onError = (FlutterErrorDetails details) {
    final message = details.exceptionAsString();
    final isRenderingError = message.contains('RenderFlex overflowed') ||
        message.contains('Failed to interpolate TextStyles') ||
        message.contains('Error thrown resolving an image codec') ||
        details.library == 'rendering library';
    // Dump FULL stack + widget trace for semantics noise so we can see
    // the exact render object triggering it (`!semantics.parentDataDirty`
    // usually truncates in release). Only in debug mode.
    if (message.contains('parentDataDirty')) {
      debugPrint('=== parentDataDirty ===');
      debugPrint(details.toStringShort());
      debugPrint(details.stack?.toString() ?? '(no stack)');
      debugPrint(details.context?.toDescription() ?? '(no context)');
      debugPrint('========================');
    }
    if (isRenderingError) {
      // Non-fatal: log but don't crash
      if (firebaseReady) FirebaseCrashlytics.instance.recordFlutterError(details);
    } else {
      if (firebaseReady) FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      // Also capture in PostHog for product analytics
      PosthogService().captureError(
        errorType: 'flutter_fatal',
        message: message,
        screenName: details.library,
      );
    }
    // Always forward to Sentry with a real stack trace. We do this here
    // (not via Sentry's auto-handler chaining) because we override
    // FlutterError.onError BEFORE Sentry.init runs, and chaining behavior
    // varies across sentry_flutter versions. Calling Sentry directly
    // guarantees the exception object + stack reach Sentry every time.
    if (SentryService.isEnabled) {
      Sentry.captureException(
        details.exception,
        stackTrace: details.stack ?? StackTrace.current,
        withScope: (scope) {
          scope.level = isRenderingError
              ? SentryLevel.warning
              : SentryLevel.error;
          scope.setTag(
              'error.kind', isRenderingError ? 'rendering' : 'flutter_fatal');
          if (details.library != null) {
            scope.setTag('flutter.library', details.library!);
          }
          if (details.context != null) {
            scope.setContexts(
                'flutter_error_context', {'description': details.context.toString()});
          }
        },
      );
    }
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    if (firebaseReady) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    }
    PosthogService().captureError(
      errorType: 'platform_error',
      message: error.toString(),
    );
    if (SentryService.isEnabled) {
      Sentry.captureException(
        error,
        stackTrace: stack,
        withScope: (scope) {
          scope.level = SentryLevel.fatal;
          scope.setTag('error.kind', 'platform_dispatcher');
        },
      );
    }
    return true;
  };

  // NotificationService instance (constructor is synchronous; initialize() is deferred below)
  final notificationService = NotificationService();

  // Set system UI overlay style for dark theme (synchronous, non-blocking)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Enable edge-to-edge (synchronous, non-blocking)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Create ProviderContainer for widget actions
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      notificationServiceProvider.overrideWithValue(notificationService),
      notificationPreferencesProvider.overrideWith(
        (ref) => NotificationPreferencesNotifier(sharedPreferences, notificationService),
      ),
    ],
  );

  // Wire onboarding analytics stub to PostHog
  AnalyticsService.init(container.read(posthogServiceProvider));

  // --- Launch the app immediately to start rendering UI ---
  // Sentry wraps runApp so it can capture zone errors. No-op when DSN unset.
  await SentryService.init(
    appRunner: () async {
      runApp(
        UncontrolledProviderScope(
          container: container,
          child: const FitWizApp(),
        ),
      );
    },
  );

  // --- Non-critical initializations deferred AFTER first frame renders ---
  // ANR fix: Use addPostFrameCallback to ensure these heavy platform-channel
  // operations don't block the main thread before the first frame.
  // The old approach used `await Future.wait(...)` which, while async, still
  // serialized platform channel calls on Android's main thread and prevented
  // the UI from rendering smoothly.
  SchedulerBinding.instance.addPostFrameCallback((_) {
    _initNonCriticalServices(container, notificationService);
  });
}

/// Initialize non-critical services after the first frame has rendered.
///
/// ANR fix: These are split into two phases to avoid overwhelming the main
/// thread with platform channel calls. Phase 1 contains lightweight services,
/// Phase 2 contains heavy platform SDK initializations that are further
/// staggered to prevent main-thread contention.
Future<void> _initNonCriticalServices(
  ProviderContainer container,
  NotificationService notificationService,
) async {
  // Phase 1: Lightweight Dart-only initializations (minimal platform channels)
  await Future.wait([
    ImageUrlCache.initialize().then<void>((_) {}).catchError((e) {
      debugPrint('⚠️ ImageUrlCache initialization failed: $e');
    }),
    DataCacheService.initialize().then<void>((_) {}).catchError((e) {
      debugPrint('⚠️ DataCacheService initialization failed: $e');
    }),
    HapticService.initialize().then<void>((_) {}).catchError((e) {
      debugPrint('⚠️ HapticService initialization failed: $e');
    }),
  ]);

  // Phase 2: Heavy platform SDK initializations -- staggered to avoid
  // serializing too many platform channel calls on Android's main thread.
  // These run sequentially so each SDK gets dedicated main-thread time
  // without competing with the others.
  await notificationService.initialize().then<void>((_) {}).catchError((e) {
    debugPrint('⚠️ Notification service initialization failed: $e');
  });

  await SubscriptionNotifier.configureRevenueCat().then<void>((_) {}).catchError((e) {
    debugPrint('⚠️ RevenueCat initialization failed: $e');
  });

  await BackgroundSyncService.initialize().then<void>((_) {}).catchError((e) {
    debugPrint('⚠️ BackgroundSyncService initialization failed: $e');
  });

  // Live Activities (iOS) + ongoing workout notification (Android).
  // init() is idempotent and also clears any orphan iOS activities from
  // a previous (possibly crashed) session.
  await LiveActivityService.instance.init().catchError((e) {
    debugPrint('⚠️ LiveActivityService initialization failed: $e');
  });

  // Universal Links / App Links ingress for referral invites. Reads
  // cold-start URI and subscribes to warm-start stream. If the user
  // wasn't signed-in when the link arrived, PendingReferralService
  // holds the code until AuthStateNotifier's post-signin flush picks
  // it up.
  await IncomingLinkService.initialize(container).catchError((e) {
    debugPrint('⚠️ IncomingLinkService initialization failed: $e');
  });

  // Warm the Drift database (non-blocking, lazy open in background)
  try {
    container.read(appDatabaseProvider);
    debugPrint('✅ Drift database provider warmed');
  } catch (e) {
    debugPrint('⚠️ Drift database warm-up failed: $e');
  }

  // Pre-warm headless widget service for native widget actions
  try {
    final headlessService = container.read(widgetActionHeadlessServiceProvider);
    headlessService.initialize();
    debugPrint('✅ Widget action headless service initialized');
  } catch (e) {
    debugPrint('⚠️ Widget action headless service initialization failed: $e');
  }

  // Meal-suggestion widget (one-tap "what should I eat?") — currently
  // listed under Settings → Coming Soon. Implementation is staged but not
  // live because the iOS widget needs an App Group entitlement added to
  // Runner.entitlements + a re-signed provisioning profile, which is a
  // manual Xcode step. To enable: (1) add the capability in Xcode, (2)
  // uncomment the imports at the top of this file, (3) uncomment the
  // block below. See project_widget_infra.md memory note for full details.
  //
  // try {
  //   await WidgetService.initialize();
  //   final apiClient = container.read(apiClientProvider);
  //   MealSuggestionWidgetService.init(apiClient);
  //   HomeWidget.registerInteractivityCallback(
  //     MealSuggestionWidgetService.handleWidgetCallback,
  //   );
  //   Future<void>.delayed(const Duration(seconds: 2), () {
  //     MealSuggestionWidgetService.instance.refreshIfStale();
  //   });
  //   debugPrint('✅ MealSuggestionWidgetService initialized');
  // } catch (e) {
  //   debugPrint('⚠️ MealSuggestionWidgetService initialization failed: $e');
  // }

  // FlutterGemma is deferred to when user accesses on-device AI settings.
  // It performs heavy native library loading and ML runtime setup that can
  // take 2-5s on slower devices. Removing it from startup eliminates the
  // single heaviest contributor to the ANR.
  // See: services/on_device_gemma_service.dart for lazy initialization.
}
