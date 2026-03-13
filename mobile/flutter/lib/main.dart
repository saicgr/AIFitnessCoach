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
import 'core/constants/api_constants.dart';
import 'core/accessibility/accessibility_provider.dart';
import 'core/providers/subscription_provider.dart';
import 'data/services/data_cache_service.dart';
import 'data/services/haptic_service.dart';
import 'data/services/image_url_cache.dart';
import 'data/services/notification_service.dart';
import 'data/services/widget_action_headless_service.dart';
import 'data/services/background_sync_service.dart';
import 'data/local/database_provider.dart';
// FlutterGemma import removed -- initialization deferred to OnDeviceGemmaService.ensureInitialized()
// to avoid ANR from heavy native ML runtime setup during app startup.
import 'core/services/analytics_service.dart';
import 'data/services/analytics_service.dart' as prod_analytics;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- Critical blocking initializations (must complete before runApp) ---
  // Run all three in parallel since they're independent of each other.
  // This saves ~500-1000ms vs sequential awaits on slow devices/emulators.

  late final SharedPreferences sharedPreferences;
  await Future.wait([
    Firebase.initializeApp().catchError((e) {
      debugPrint('⚠️ Firebase initialization failed: $e');
    }),
    SharedPreferences.getInstance().then((prefs) => sharedPreferences = prefs),
    Supabase.initialize(
      url: ApiConstants.supabaseUrl,
      anonKey: ApiConstants.supabaseAnonKey,
    ),
  ]);

  // Wire up Crashlytics error handlers
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
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

  // Wire onboarding analytics stub to production Supabase analytics service
  AnalyticsService.init(container.read(prod_analytics.analyticsServiceProvider));

  // --- Launch the app immediately to start rendering UI ---
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const FitWizApp(),
    ),
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
    ImageUrlCache.initialize().catchError((e) {
      debugPrint('⚠️ ImageUrlCache initialization failed: $e');
    }),
    DataCacheService.initialize().catchError((e) {
      debugPrint('⚠️ DataCacheService initialization failed: $e');
    }),
    HapticService.initialize().catchError((e) {
      debugPrint('⚠️ HapticService initialization failed: $e');
    }),
  ]);

  // Phase 2: Heavy platform SDK initializations -- staggered to avoid
  // serializing too many platform channel calls on Android's main thread.
  // These run sequentially so each SDK gets dedicated main-thread time
  // without competing with the others.
  await notificationService.initialize().catchError((e) {
    debugPrint('⚠️ Notification service initialization failed: $e');
  });

  await SubscriptionNotifier.configureRevenueCat().catchError((e) {
    debugPrint('⚠️ RevenueCat initialization failed: $e');
  });

  await BackgroundSyncService.initialize().catchError((e) {
    debugPrint('⚠️ BackgroundSyncService initialization failed: $e');
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

  // FlutterGemma is deferred to when user accesses on-device AI settings.
  // It performs heavy native library loading and ML runtime setup that can
  // take 2-5s on slower devices. Removing it from startup eliminates the
  // single heaviest contributor to the ANR.
  // See: services/on_device_gemma_service.dart for lazy initialization.
}
